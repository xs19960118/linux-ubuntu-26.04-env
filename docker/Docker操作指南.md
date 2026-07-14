# Docker 操作指南

本文只记录日常开发最常用的 Docker 命令。你的 Docker 开发环境根目录是：

```bash
cd /home/xs/workplace/docker
```

## 最常用

全量启动所有开发服务：

```bash
cd /home/xs/workplace/docker
./scripts/up-all.sh
```

查看所有服务状态：

```bash
cd /home/xs/workplace/docker
./scripts/ps-all.sh
docker compose ls --all
docker ps
```

查看有没有异常容器：

```bash
docker ps -a --format 'table {{.Names}}\t{{.Status}}\t{{.Ports}}' | grep -E 'Restarting|Exited|Created|Dead' || echo ok
```

先拉镜像，网络慢时用这个：

```bash
cd /home/xs/workplace/docker
./scripts/pull-all-images-cn.sh
```

## 操作单个服务

进入某个服务目录，例如单机 MySQL：

```bash
cd /home/xs/workplace/docker/mysql-local
```

启动：

```bash
docker compose up -d
```

停止，但保留数据：

```bash
docker compose down
```

重启：

```bash
docker compose restart
```

查看当前服务容器：

```bash
docker compose ps
```

查看日志：

```bash
docker compose logs -f
```

只看最近 100 行日志：

```bash
docker compose logs --tail=100
```

检查 compose 配置有没有语法问题：

```bash
docker compose config
```

## 用 Makefile 操作

在 `/home/xs/workplace/docker` 根目录可以这样操作单个服务：

```bash
cd /home/xs/workplace/docker
make ps SERVICE=mysql-local
make logs SERVICE=nacos
make restart SERVICE=redis-local
make config SERVICE=kafka-cluster
```

## 进入容器

进入容器 shell：

```bash
docker exec -it dev-mysql-local bash
docker exec -it dev-redis-local sh
```

直接在容器里执行命令：

```bash
docker exec dev-redis-local redis-cli -a xsailxma ping
docker exec dev-mysql-local mysql -uroot -pxsailxma -e 'SHOW DATABASES;'
```

## 常用连接

| 服务 | 地址 |
| --- | --- |
| Redis 单机 | `127.0.0.1:16379`，密码 `xsailxma` |
| MySQL 单机 | `127.0.0.1:13306`，`root / xsailxma` 或 `xs / xsailxma` |
| PostgreSQL 单机 | `127.0.0.1:15432`，`xs / xsailxma`，库 `app_db` |
| MongoDB 单机 | `127.0.0.1:37017`，`xs / xsailxma`，认证库 `admin` |
| Kafka 单机 | `127.0.0.1:19092`，UI `http://127.0.0.1:18082` |
| Kafka 三节点 | `127.0.0.1:19093/19094/19095`，UI `http://127.0.0.1:18081` |
| APISIX | 网关 `http://127.0.0.1:19080`，Admin `http://127.0.0.1:19180` |
| Nginx | `http://127.0.0.1:18080` |
| Nacos | `http://127.0.0.1:18848/nacos/`，`xs / xsailxma` |
| Consul | `http://127.0.0.1:18500` |
| RabbitMQ 单机 | 管理端 `http://127.0.0.1:15673`，`xs / xsailxma` |
| RabbitMQ 集群 | 管理端 `http://127.0.0.1:25673`，`xs / xsailxma` |
| MinIO | Console `http://127.0.0.1:19001`，`xsminio / xsailxma` |
| Prometheus | `http://127.0.0.1:19090` |
| Grafana | `http://127.0.0.1:13000`，`xs / xsailxma` |
| Elasticsearch | `http://127.0.0.1:19200` |
| Kibana | `http://127.0.0.1:15601` |
| Metabase | `http://127.0.0.1:13001` |

更完整的中文服务说明见：

```bash
/home/xs/workplace/docker/服务说明.md
```

## 常用验证

```bash
curl http://127.0.0.1:18080/
curl http://127.0.0.1:18848/nacos/
curl http://127.0.0.1:19090/-/healthy
curl http://127.0.0.1:19000/minio/health/live
```

Redis Cluster：

```bash
docker exec dev-redis-cluster-1 redis-cli -a xsailxma cluster info
```

MongoDB 副本集：

```bash
docker exec dev-mongo-replica-1 mongosh --quiet --eval 'rs.status().members.map(m => m.name + ":" + m.stateStr).join("\n")'
```

Kafka 三节点，从宿主机网络验证：

```bash
docker run --rm --network host \
  --entrypoint /opt/bitnami/kafka/bin/kafka-topics.sh \
  bitnami/kafka:3.7.1 \
  --bootstrap-server 127.0.0.1:19093 --list
```

## 备份

进入服务目录后执行：

```bash
cd /home/xs/workplace/docker/mysql-local
./scripts/backup.sh
```

已补齐备份脚本的服务：

```text
mysql-local
postgres-local
mongo-local
redis-local
mysql-8-replication
mongo-replica
redis-cluster-6
redis-sentinel-6
minio
```

备份文件默认放在对应服务的 `backup/` 目录。

## 恢复

恢复会覆盖数据，所以必须显式加 `CONFIRM=YES`：

```bash
cd /home/xs/workplace/docker/mysql-local
CONFIRM=YES ./scripts/restore.sh ./backup/xxx.sql.gz
```

Redis / MinIO 这类目录型备份也是同样方式：

```bash
cd /home/xs/workplace/docker/minio
CONFIRM=YES ./scripts/restore.sh ./backup/minio-YYYYMMDD-HHMMSS.tar.gz
```

## 清理

查看镜像：

```bash
docker images
```

查看磁盘占用：

```bash
docker system df
```

清理没被使用的容器、网络、镜像缓存：

```bash
docker system prune
```

只清理没用的镜像：

```bash
docker image prune
```

## 别随便执行

下面这些命令会删除数据或大量清理，执行前先确认你真的要这么做：

```bash
docker compose down -v
docker volume prune
docker system prune -a --volumes
rm -rf /home/xs/workplace/docker/*/data
```

日常停止服务用 `docker compose down`，不要加 `-v`。

## 出问题时先看这几个

看异常容器：

```bash
docker ps -a --format 'table {{.Names}}\t{{.Status}}\t{{.Ports}}' | grep -E 'Restarting|Exited|Created|Dead'
```

看某个容器日志：

```bash
docker logs --tail=200 dev-nacos
docker logs -f dev-mysql-local
```

重启某一组服务：

```bash
cd /home/xs/workplace/docker/nacos
docker compose restart
```

配置改过后重建：

```bash
cd /home/xs/workplace/docker/nacos
docker compose up -d --force-recreate --remove-orphans
```

端口占用检查：

```bash
ss -lntp | grep 18848
```
