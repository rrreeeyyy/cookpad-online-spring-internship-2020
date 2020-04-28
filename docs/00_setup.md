# セットアップ

今回のインターンシップでは、[Amazon Web Service](https://aws.amazon.com/jp/) 上に用意した、[EC2](https://aws.amazon.com/jp/ec2/) インスタンスの上で作業をしてもらいます。
まず、EC2 インスタンスに SSH ができるか確認してみましょう。利用する秘密鍵は GitHub で利用しているもの（あるいは配布されたもの）を利用し、ユーザ名は `ubuntu` を利用してください。

コマンド例)

```sh
ssh -i ~/.ssh/id_rsa -l ubuntu ec2-xx-xx-xx-xxx.ap-northeast-1.compute.amazonaws.com
```

次に、今回利用するアプリケーションを用意します。まず https://github.com/rrreeeyyy/cookpad-online-spring-internship-2020 を fork してください。
fork した後、EC2 インスタンスから ssh を用いて clone できるように、Settings から Deploy keys として EC2 インスタンスで生成した公開鍵を登録します。

コマンド例)

```sh
ssh-keygen
cat ~/.ssh/id_rsa.pub

# 自分のリポジトリを clone する
git clone git@github.com:rrreeeyyy/cookpad-online-spring-internship-2020.git
```

## VSCode Remote

VSCode Remote を用いる場合は、`~/.ssh/config` に、インスタンスにログインするための設定を追加します。

```
Host cookpad-spring-internship-2020
  User ubuntu
  HostName ec2-xx-xx-xx-xxx.ap-northeast-1.compute.amazonaws.com
  Port 22
  IdentityFile ~/.ssh/id_rsa
```

では、VS Code から接続してみましょう。まず Remote Development の Extension を入れます。
その後、画面端の remote development のアイコンを探し、SSH TARGETS から、さきほど ~/.ssh/config に追加した cookpad-spring-internship-2020 を探し、
右クリックして「Connect to Host in Current Window」を選択します。もしくは、右の + マークのついた窓のアイコンをクリックすると、別ウィンドウで開くこともできます。

インスタンス上で Vim を使いたい、エディタは VSCode でいいけれどターミナルは手に馴染んだものを使いたいといったように、ターミナルからログインしたい場合は、

```
$ ssh cookpad-spring-internship-2020
```

のようにしてください。

うまくログインが成功すればセットアップは完了です。

# アプリケーション構成

リポジトリを clone できたらアプリケーション構成を見てみましょう。今回のアプリケーションは `bff` や `main` といった Rails で書かれた複数のサービスを持つアプリケーションです。
`bff` と `main` などのサービスは、詳しくは後述しますが、[gRPC](https://grpc.io) を用いて通信を行っており、gRPC に用いている[Protocol Buffers](https://developers.google.com/protocol-buffers) の定義が `protobuf-definitions` 以下に置かれています。

それぞれのアプリケーションは、[Docker](https://www.docker.com) を用いて動かすことができるようになっており、複数のサービスを同時に起動させるため、[docker-compose](https://docs.docker.com/compose/) の設定も用意してあります。
まずはアプリケーションを動かしてみましょう。

コマンド例)

```
sudo docker-compose up -d --build
```

`docker-compose.yml` にも書かれている通り、起動に成功すると 3000 番ポートで listen を行うようになります。
アクセスできることを確認しましょう。

コマンド・出力例)

```
$ curl localhost:3000/hello -vvv
*   Trying 127.0.0.1...
* TCP_NODELAY set
* Connected to localhost (127.0.0.1) port 3000 (#0)
> GET /hello HTTP/1.1
> Host: localhost:3000
> User-Agent: curl/7.54.0
> Accept: */*
>
< HTTP/1.1 200 OK
< X-Frame-Options: SAMEORIGIN
< X-XSS-Protection: 1; mode=block
< X-Content-Type-Options: nosniff
< X-Download-Options: noopen
< X-Permitted-Cross-Domain-Policies: none
< Referrer-Policy: strict-origin-when-cross-origin
< Content-Type: application/json; charset=utf-8
< ETag: W/"93a23971a914e5eacbf0a8d25154cda3"
< Cache-Control: max-age=0, private, must-revalidate
< X-Request-Id: 59284d59-0395-46dd-b59c-d56649f7e5ba
< X-Runtime: 0.018132
< Transfer-Encoding: chunked
<
* Connection #0 to host localhost left intact
{"hello":"world"}
```
