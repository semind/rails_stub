# コマンド

## ビルド

```
$ DOCKER_BUILDKIT=1 docker build -t rails_stub:tag .
```

## 実行

ローカルmacのmysqlに接続

```
$ docker run -p 3000:3000 --env-file DockerEnv rails_stub:v1.0 bundle exec rails server --binding=0.0
.0.0
```