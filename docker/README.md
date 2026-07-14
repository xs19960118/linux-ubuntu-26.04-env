# Docker 开发环境

Docker 根目录：

```text
/home/xs/workplace/docker
```

详细实施计划：

```text
/home/xs/workplace/开发环境搭建/plan.md
```

日常 Docker 操作指南：

```text
/home/xs/workplace/docker/Docker操作指南.md
```

中文服务说明和端口表：

```text
/home/xs/workplace/docker/服务说明.md
```

统一账号密码：

```text
username: xs
password: xsailxma
```

启动某个服务：

```bash
cd /home/xs/workplace/docker/<service-name>
docker compose up -d
```

停止某个服务：

```bash
docker compose down
```

查看日志：

```bash
docker compose logs -f
```

当前目录已按规划补齐各服务 `docker-compose.yml`、`.env.example`、基础配置和服务 README。

目标服务目录：

```text
mysql-local
redis-local
mongo-local
mysql-8-replication
redis-cluster-6
redis-sentinel-6
mongo-replica
postgres-local
kafka-local
kafka-cluster
rabbitmq-local
rabbitmq-cluster
apisix
nginx
minio
elasticsearch
prometheus-grafana
metabase
nacos
consul
```

统一规则：

- 每个服务提交 `.env.example`，本地 `.env` 不提交。
- 每个服务保留 `conf/`、`data/`、`logs/`、`runtime/`、`backup/`、`scripts/`。
- `data/`、`logs/`、`runtime/`、`backup/`、`.env` 已加入 `.gitignore`。
- compose 端口默认绑定 `127.0.0.1`。
- compose 镜像必须锁定具体版本。
- compose 必须包含 `restart: unless-stopped` 和 `healthcheck`。

静态校验：

```bash
for d in mysql-local redis-local mongo-local postgres-local nginx mysql-8-replication redis-cluster-6 redis-sentinel-6 mongo-replica kafka-local kafka-cluster rabbitmq-local rabbitmq-cluster apisix minio elasticsearch prometheus-grafana metabase nacos consul; do
  cd "/home/xs/workplace/docker/$d"
  cp .env.example .env
  docker compose config >/dev/null
  rm -f .env
done
```
