# ECS と Deployment

ここまでは開発環境で試してきましたが、ベンチマークのために用意した本番環境にデプロイをしてみましょう。

ここでは、AWS にある Amazon ECS という、Docker のマネージドオーケストレーションサービスに対してデプロイを行ってみます。

クックパッドでは、基本的に国内のサービスすべてで ECS を利用しています。
また、イギリスのブリストルを拠点に開発されているグローバルレシピサービスでは AWS のマネージド Kubernetes サービスである EKS も導入されています。

## Amazon EC2 Container Registry (ECR)

ECR は AWS のマネージド Docker イメージレジストリです。手元でビルドした Docker イメージを ECR にプッシュし、ECS がそのイメージをプルすることでデプロイが行われます。
リポジトリは、GitHub ID の lower-case を prefix として作成しています。GitHub ID が `rrr-EEE-yyy` なら、`rrr-eee-yyy-bff` や `rrr-eee-yyy-main` などが用意されています。

全てのリポジトリで docker build と docker push を行うための便利な bash スクリプトとして、`scripts/docker-build.sh` を用意しました。
中身は単に、必要なファイルを生成した後に、ECR のリポジトリの名前で docker build を行い、docker push を行うだけのものです。

このスクリプトが読み取る環境変数として `hako.env` を用意する必要があります。`/home/ubuntu/hako.env` を clone しているリポジトリの `hako/` 以下に移します。

```sh
mv /home/ubuntu/hako.env hako/
```

続いて、`hako.env` の末尾に GitHub ID を書く箇所があるので、そこに GitHub ID を記述します。

```sh
$EDITOR hako/hako.env
```

最後に、ECR にプッシュを行うための docker login を行います。docker login に必要なコマンドは、`awscli` によって生成されるので、次を実行してください。
（`docker-build.sh` を行う際は必ず同じ端末で以下のログインコマンドを実行してください）

```sh
$(aws ecr get-login --no-include-email --region=ap-northeast-1)
```

その後、`docker-build.sh` を実行します。これにより ECR にビルドした docker イメージがプッシュされます。

```sh
sudo scripts/docker-build.sh
```

## ECS / Hako

クックパッドでは、ECS を用いたデプロイを定型化し、コマンドから実行できるようにした [`hako`](https://github.com/eagletmt/hako) というツールを用いてデプロイを行っています。

Hako では、以下のようにロードバランサ、ECS サービスなどをひとまとめにして「Hako アプリケーション」という基本単位でデプロイ・管理します。

![https://github.com/hogelog/tsukuba-ecs-internship から引用](https://raw.githubusercontent.com/hogelog/tsukuba-ecs-internship/master/images/hako-basic.png)

（https://github.com/hogelog/tsukuba-ecs-internship から引用）

hako の設定ファイルの雛形は、`hako/` ディレクトリ配下に置いてあります。
ここでは、あなた専用の設定ファイルを作る必要があるため、次のように実行します。

```sh
mv hako/hako.jsonnet hako/${GITHUB_ID_LOWER_CASE}.jsonnet
```

（`${GITHUB_ID_LOWER_CASE}` の箇所は適宜 GitHub ID を lower case にしたものに読み替えてください）

hako の定義ファイルの中には、ロードバランサの設定やデプロイするコンテナ・サイドカーの設定などが書いてあります。

ここまで準備が整ったらデプロイを行ってみましょう。必要な情報をチェックして `bundle exec hako deploy` を行うだけの `hako-deploy.sh` を用意したのでそれを利用します。

```sh
sudo scripts/hako-deploy.sh
```


hako deploy は初回では Application Load Balancer (ALB) を作成します。
デプロイが成功したら ALB を確認してみましょう。

```sh
aws elbv2 describe-load-balancers --region ap-northeast-1
```

自身の GitHub ID の ALB があったら、`DNSName` に対して curl を実行してみましょう。

```sh
curl hako-rrreeeyyy-916247625.ap-northeast-1.elb.amazonaws.com/site/sha
```

また、アプリケーションのログも確認してみましょう。
まずは ECS 上で起動しているタスクを確認します。

```sh
$ ecs-cli ps --region ap-northeast-1 --cluster cookpad-spring-internship-2020-cluster
Name                                        State    Ports                    TaskDefinition  Health
dca5864b-416e-4263-b827-423eadb05956/main   RUNNING                           rrreeeyyy:23    UNKNOWN
dca5864b-416e-4263-b827-423eadb05956/front  RUNNING  10.15.78.18:80->80/tcp   rrreeeyyy:23    UNKNOWN
dca5864b-416e-4263-b827-423eadb05956/app    RUNNING                           rrreeeyyy:23    UNKNOWN
ed0ab3a0-0c1e-45a3-9e79-bb21d93f5370/main   RUNNING                           rrreeeyyy:23    UNKNOWN
ed0ab3a0-0c1e-45a3-9e79-bb21d93f5370/app    RUNNING                           rrreeeyyy:23    UNKNOWN
ed0ab3a0-0c1e-45a3-9e79-bb21d93f5370/front  RUNNING  10.15.38.160:80->80/tcp  rrreeeyyy:23    UNKNOWN
```

TaskDefinition が GitHub ID のものがあったら、Task ID (Name の `/` の左側)を指定して、
以下のコマンドでログを見ることができます。

```
ecs-cli logs --task-id dca5864b-416e-4263-b827-423eadb05956 --region ap-northeast-1 --cluster cookpad-spring-internship-2020-cluster
```

## hako oneshot

`bundle exec rake ridgepole:apply` などの、データベースに対する変更を本番同等の環境に対して発行したり、バッチなどの用途で使うために、`hako oneshot` というコマンドがあります。

`main` での hako oneshot を行うだけの、`hako-oneshot-main.sh` というスクリプトを用意しました。`hako-oneshot-main.sh` は引数で渡されたコマンドを hako を用いて ECS 環境で 1 度だけ実行します。

そのため、例えばインデックスを追加したので本番のデータベースに対して `ridgepole:apply` したいような場合は次のようにします。

ここでは、あなた専用の設定ファイルを作る必要があるため、次のように実行します。

```sh
mv hako/hako-oneshot-main.jsonnet hako/${GITHUB_ID_LOWER_CASE}-oneshot-main.jsonnet
mv hako/hako-oneshot-tsukurepo_backend.jsonnet hako/${GITHUB_ID_LOWER_CASE}-oneshot-tsukurepo_backend.jsonnet
```

その後、次を実行してください。

```sh
scripts/hako-oneshot-main.sh bundle exec rake ridgepole:apply
scripts/hako-oneshot-tsukurepo.sh bundle exec rake ridgepole:apply
```

ログは、通常の場合と同じく、ecs-cli で task-id を指定することで確認できます。`hako-oneshot-main.sh` の出力にも task-id は含まれているため、それを利用するとよいでしょう。
