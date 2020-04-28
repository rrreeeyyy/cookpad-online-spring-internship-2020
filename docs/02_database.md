# MySQL と遅いクエリ

アプリケーションのデータを保存するデータストアとして、
よく用いられるのが Relational DataBase Management System (RDBMS) です。

RDBMS は大量のデータを取り扱う特性上ボトルネックになりやすく、
後述するインデックスが貼られていないクエリが発行されたり、1 回のアクセスで大量にクエリが発行されたりすると、
アプリケーションのパフォーマンスが大きく低下する要因となります。

今回のアプリケーションではデータストアとして RDBMS の [MySQL](https://www.mysql.com/) を利用しています。
また、テーブルやアプリケーション内部に意図的に遅くなるクエリや、大量にクエリが発行される箇所を仕込んであります。

ここでは、簡単にどのようなクエリが遅くなりやすいか、どのような箇所でクエリが大量に発行されやすいかと、
それらに対してどのように対処すればよいのかについて説明していきます。

## スロークエリの確認

RDBMS でボトルネックになりやすい箇所の一つは、当然ですが実行に時間の掛かるクエリです。
そういったクエリを特定するため、MySQL を始め一般的な RDBMS では、実行に一定以上時間が掛かったクエリをスロークエリとしてログに出力することができます。

今回は、docker-compose.yml に、実行時間が 0.1 秒以上のクエリを  `/var/log/mysql/slow.log` に出力するような設定を施しています。
`curl http://localhost:3000/v1/users` を実行し、次のコマンドで出力されているスロークエリを確認してみましょう。

```
$ docker-compose exec -T mysql tail /var/log/mysql/slow.log
# Time: 2020-04-28T13:37:49.981180Z
# User@Host: root[main] @ localhost []  Id:     7
# Query_time: 1.35795  Lock_time: 0.000154 Rows_sent: 20  Rows_examined: 1992900
SET timestamp=1535636269;
SELECT `users`.* FROM `users` ORDER BY created_at DESC LIMIT 20;
```

## EXPLAIN 句

クエリのチューニングでは、基本的に EXPLAIN 句を使い、クエリがどのように実行されるかを確認し、その結果に応じて、高速化の手法を考えていきます。
MySQL では `EXPLAIN` の後にクエリを書くことで EXPLAIN を見ることができます。同様に、Rails では、ActiveRecord のメソッドに続けて `.explain` を続けることで EXPLAIN を見ることができます。

実際に、次のコマンドを発行して EXPLAIN を見てみましょう。

```
docker-compose run main bin/rails c
> User.order(created_at: :desc).limit(20).explain # MySQL に EXPLAIN SELECT `users`.* FROM `users` ORDER BY `users`.`created_at` DESC LIMIT 20 を発行するのと同じ
+----+-------------+-------+------------+------+---------------+------+---------+------+---------+----------+----------------+
| id | select_type | table | partitions | type | possible_keys | key  | key_len | ref  | rows    | filtered | Extra          |
+----+-------------+-------+------------+------+---------------+------+---------+------+---------+----------+----------------+
|  1 | SIMPLE      | users | NULL       | ALL  | NULL          | NULL | NULL    | NULL | 1992900 |    100.0 | Using filesort |
+----+-------------+-------+------------+------+---------------+------+---------+------+---------+----------+----------------+
1 row in set (0.03 sec)
```

それぞれのカラムには当然意味がありますが、今回は rows に着目してください。これは、どのくらいの行を取得する予定かを表した値です。
Users テーブルにはたくさん値が入っているので、 条件に合致するようなカラムを探すために、全てのカラムを取得して、その後必要な値を選別する、といった処理をしていると、行数の増加に応じて処理数が増えていってしまいます。

## インデックス

RDBMS では、インデックスという索引を付けることで、より効率的に必要なデータのみを取得できる機能があります。
MySQL の InnoDB におけるインデックスは、B+ Tree というデータ構造で実装されています。

B+ Tree とは、次のような特徴を持った木構造です。

- 次数を d としたとき 各内部ノードは最大 d-1 個のキーと d 個までの子ノードを持つ
- 内部ノードは値を持たない
- 葉ノードの各キーは値(もしくは値へのポインタ)を持つ
- `O(log d n)` で検索できる

InnoDB のインデックスでは、次数が 3 の B+ Tree が使用されています。
B+ Tree のデータ構造は次のページで可視化されています。

https://www.cs.usfca.edu/~galles/visualization/BPlusTree.html

また、MySQL の InnoDB におけるインデックスには、クラスタインデックスとセカンダリインデックスの 2 つの種類があります。

クラスタインデックスとは、テーブルで主キーやユニークキーが定義された時に自動的に追加される、主キーもしくはユニークキーによるによるインデックスです。
クラスタインデックスでは、葉ノードの値として当該のキーの行のすべてのデータを格納しています。そのため、主キーによる検索は非常に高速に行うことが可能になっています。

それ以外のインデックスはセカンダリインデックスと呼ばれます。InnoDB では 0〜複数個のインデックスをテーブルに対して定義することが出来ます。
セカンダリインデックスでは、使用されているカラムの値と主キーの値のペアが葉ノードの値として格納されています。

セカンダリインデックスにおける検索では、葉ノードに到達した段階でも、主キーとカラムのペアしか取得することが出来ないため、
主キーとインデックスに使用しているカラム以外の値を取得しようとした場合、再度クラスタインデックスによる検索を掛ける必要があります。
これはクラスタインデックスのみの検索より、おおよそ倍程度の工程がかかってしまいます。

### どういったカラムにインデックスを作成するか

前項では、インデックスの有用性について説明しましたが、全てのカラムに対してインデックスを貼れば良いというわけではありません。 インデックスを作成した場合には、インデックス分のデータ容量の増大や、更新・削除のオーバヘッドが発生してしまいます。

そのため、インデックスを作成するカラムは正しく見極めなければなりません。 その要素の一つとして、カラムの選択性というものがあります。

例えば、ある事柄が有効になっているかどうかを判別する flag という、0 と 1 のみ偏りなく格納される予定のカラムがあったとします。 このような flag では、インデックスを貼っても大きな効果は得られません。 このようなフラグの取りうる値のバリエーションをカーディナリティと呼んだりします。 基本的には、カーディナリティの高く頻繁に使用されるようなカラムに対してのみ、インデックスを貼ることを推奨します。

また、特にサービスでどのようにクエリを発行するかに着目してインデックスを貼ることが大事です。
例えば、`WHERE` 句で指定するキーに対するインデックス、`ORDER` 句でソートするキーに対するインデックス、
またはそれらを組み合わせた複合的なインデックスを貼ることが有効である場合が多いです。

### セカンダリインデックスの作成

それでは実際にセカンダリインデックスを貼ってみましょう。今回のアプリケーションでは、DB の Schema 管理に [`ridgepoole`](https://github.com/winebarrel/ridgepole) を使っています。
ridgepole の各テーブルの設定は `db/schemata` 配下に入っています。今回は User のテーブルに index を貼ってみましょう。

```sh
$EDITOR main/db/schemata
```

```diff
 create_table "users", id: :bigint, unsigned: true, force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_bin ROW_FORMAT=DYNAMIC" do |t|
   t.string   "name", null: false
   t.timestamps
+
+  t.index ["created_at"]
 end
```

とした後に、ridgepole:apply を行います。このタスクは `main/lib/tasks/ridgepole.rake` の中で定義されています。

```sh
docker-compose up --build -d
docker-compose run main bundle exec rake ridgepole:apply
```

作成できたら先程と同じく、EXPLAIN を確認し、結果を比較してみましょう。

## N+1 クエリ

次に RDBMS でボトルネックになりやすい箇所の一つは、1 度のアクセスで大量に発行されるクエリです。
こういったクエリはスロークエリには表れないものの、確実にアプリケーションのパフォーマンスを低下させるので注意が必要です。

特に一覧系のページで N+1 クエリはよく発生してしまいます。例えば、最新のレシピ 10 件と、それを書いたユーザをそれぞれ取得する処理を考えてみましょう。
愚直に実装すると、

```ruby
recipes = Recipe.order(created_at: :desc).limit(10)
users = recipes.map { |recipe| recipe.user }
```

となってしまいますが、これを実行すると当然次のようなログが流れます。

```
D, [2020-04-27T19:12:34.554545 #1] DEBUG -- :   Recipe Load (1.3ms)  SELECT `recipes`.* FROM `recipes` ORDER BY `recipes`.`created_at` DESC LIMIT 10
D, [2020-04-27T19:12:34.556967 #1] DEBUG -- :   User Load (0.7ms)  SELECT `users`.* FROM `users` WHERE `users`.`id` = 1 LIMIT 1
D, [2020-04-27T19:12:34.559124 #1] DEBUG -- :   User Load (0.8ms)  SELECT `users`.* FROM `users` WHERE `users`.`id` = 2 LIMIT 1
D, [2020-04-27T19:12:34.561380 #1] DEBUG -- :   User Load (0.9ms)  SELECT `users`.* FROM `users` WHERE `users`.`id` = 3 LIMIT 1
D, [2020-04-27T19:12:34.565034 #1] DEBUG -- :   User Load (1.7ms)  SELECT `users`.* FROM `users` WHERE `users`.`id` = 4 LIMIT 1
D, [2020-04-27T19:12:34.569254 #1] DEBUG -- :   User Load (2.5ms)  SELECT `users`.* FROM `users` WHERE `users`.`id` = 5 LIMIT 1
D, [2020-04-27T19:12:34.573996 #1] DEBUG -- :   User Load (3.1ms)  SELECT `users`.* FROM `users` WHERE `users`.`id` = 6 LIMIT 1
D, [2020-04-27T19:12:34.582560 #1] DEBUG -- :   User Load (3.5ms)  SELECT `users`.* FROM `users` WHERE `users`.`id` = 7 LIMIT 1
D, [2020-04-27T19:12:34.585471 #1] DEBUG -- :   User Load (1.2ms)  SELECT `users`.* FROM `users` WHERE `users`.`id` = 8 LIMIT 1
D, [2020-04-27T19:12:34.591061 #1] DEBUG -- :   User Load (2.1ms)  SELECT `users`.* FROM `users` WHERE `users`.`id` = 9 LIMIT 1
D, [2020-04-27T19:12:34.593337 #1] DEBUG -- :   User Load (1.0ms)  SELECT `users`.* FROM `users` WHERE `users`.`id` = 10 LIMIT 1
```

レシピを取得するのに 1 件、10 件分のレシピそれぞれのユーザを取得するために 10 件クエリが発行されていることが分かります。

これを回避するために、Rails には `joins`, `preload`, `eager_load`, `includes` といったメソッドが存在します。
それぞれのメソッドでユースケースが異なるため適切なものを選択する必要がありますが、今回は `preload` について解説します。

```ruby
recipes = Recipe.preload(:user).order(created_at: :desc).limit(10)
users = recipes.map { |recipe| recipe.user }
```

のようにすると、クエリが次のように変化します。

```
D, [2020-04-27T19:17:24.061305 #1] DEBUG -- :   Recipe Load (1.3ms)  SELECT `recipes`.* FROM `recipes` ORDER BY `recipes`.`created_at` DESC LIMIT 10
D, [2020-04-27T19:17:24.063386 #1] DEBUG -- :   User Load (1.0ms)  SELECT `users`.* FROM `users` WHERE `users`.`id` IN (1, 2, 3, 4, 5, 6, 7, 8, 9, 10)
```

これは、Rails が内部で事前に取得したレシピに紐づく `user_id` の一覧を配列として保持しておき、これを IN 句で渡すことでクエリの回数を 2 回まで抑えることができています。

## 参考文献

- http://techlife.cookpad.com/entry/2017/04/18/092524
- https://www.cs.usfca.edu/~galles/visualization/BPlusTree.html
- http://qiita.com/kiyodori/items/f66a545a47dc59dd8839
- http://qiita.com/k0kubun/items/80c5a5494f53bb88dc58
