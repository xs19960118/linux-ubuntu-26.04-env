# Ubuntu 26.04 开发环境实施计划

本文档是可多次执行的实施计划。当前阶段先修正文档，不调整 Docker 目录结构，不创建 Docker Compose，不启动容器。

文档分工：

- `plan.md`：实施计划、目录规范、端口规范、账号规范、挂载规范、自启动规范。
- `desc.md`：完整说明文档，记录本地语言环境和 Docker 服务规划。

## 1. 总体目标

- 本地语言运行时安装在 Linux 宿主机。
- Docker 基础设施统一放在 `/home/xs/workplace/docker`。
- Docker 数据库不占用宿主机默认端口，默认端口留给本地安装的 MySQL、Redis、MongoDB。
- Docker local 和 cluster 服务允许同时启动，因此 Docker 端口必须全局唯一，不能复用。
- Docker 端口默认只绑定 `127.0.0.1`，不默认暴露到局域网。
- 所有 Docker 服务支持重复执行、重复启动、重复初始化。
- 数据库类服务必须映射本地配置、数据、日志目录，避免容器删除后数据丢失。
- 每个服务提交 `.env.example`，本地 `.env` 不提交。
- Docker 镜像必须锁定具体版本，不使用 `latest`。

统一账号密码：

```text
username: xs
password: xsailxma
```

需要 root、admin、默认管理账号的服务，密码统一使用：

```text
xsailxma
```

## 2. 本地环境范围

本地安装：

- Java：JDK 8、17、21、25，默认 JDK 17。
- Maven：多版本，默认新稳定版本。
- Gradle：多版本，默认新稳定版本。
- PHP：5.6、7.1、7.4、8.1、8.4.x，默认 8.1。
- Node.js：沿用已有 nvm，当前已有 20、24、26。
- Go：多版本。
- TypeScript：按项目安装。
- Python：补充本地多版本和虚拟环境管理。
- MySQL、Redis、MongoDB：可以本地安装，默认端口保留给本地服务。

本地默认端口保留：

```text
MySQL: 3306
Redis: 6379
MongoDB: 27017
PostgreSQL: 5432
Nginx: 80, 443
```

## 3. Docker 根目录

Docker 根目录固定为：

```text
/home/xs/workplace/docker
```

根目录后续应包含：

```text
/home/xs/workplace/docker/
  Makefile
  .gitignore
  scripts/
  mysql-local/
  redis-local/
  mongo-local/
  mysql-8-replication/
  redis-cluster-6/
  redis-sentinel-6/
  mongo-replica/
  postgres-local/
  kafka-local/
  kafka-cluster/
  rabbitmq-local/
  rabbitmq-cluster/
  apisix/
  nginx/
  minio/
  elasticsearch/
  prometheus-grafana/
  metabase/
  nacos/
  consul/
```

当前只先修正文档。Docker 目录结构后续再按本计划调整。

每个服务目录的标准结构：

```text
service-name/
  .env.example
  docker-compose.yml
  conf/
  data/
  logs/
  runtime/
  backup/
  scripts/
  README.md
```

例外：

- Nginx 额外包含 `html/`。
- Metabase 可以没有 `conf/`，但必须有 `data/`、`logs/`、`runtime/`。
- Grafana/Prometheus 配置放在 `conf/`。
- 本地 `.env` 从 `.env.example` 复制生成，不提交 git。
- 根目录 `scripts/` 存放全局辅助脚本，例如端口检查、目录检查、批量状态检查。
- 已存在的旧目录 `kafka/`、`rabbitmq/` 后续目录调整阶段删除，不再作为目标目录。

## 4. 幂等执行规范

所有脚本和 compose 初始化必须可多次执行。

要求：

- 目录创建使用 `mkdir -p`。
- 初始化 SQL 使用 `CREATE DATABASE IF NOT EXISTS`。
- 初始化用户使用可重复执行写法。
- 初始化 bucket、topic、vhost、route 时先检查是否存在。
- `docker compose up -d` 可重复执行。
- `docker compose down` 不删除本地数据。
- 只有明确执行 `docker compose down -v` 或手动删除 `data/` 才清理数据。
- 所有清理脚本必须要求显式确认，例如 `CONFIRM=YES`。
- 所有服务必须有 `healthcheck`。
- 有依赖关系的服务必须等待依赖健康后再初始化。

禁止：

- 初始化脚本每次执行都删除数据库。
- 默认执行清空 `data/`。
- 默认占用本地数据库端口。
- 把密码散落写死在多个文件中。
- 使用 `latest` 镜像标签。
- 默认监听 `0.0.0.0`。

## 5. 挂载规范

数据库和中间件必须使用本地目录挂载。

通用挂载：

```text
./conf  -> 容器配置目录
./data  -> 容器数据目录
./logs  -> 容器日志目录
./runtime -> 运行时生成文件目录
./scripts -> 初始化脚本目录
```

要求：

- `conf/` 双向可修改。
- `data/` 双向可持久化。
- `logs/` 双向可查看。
- `runtime/` 用于放运行时生成文件，不提交 git。
- `backup/` 用于放备份文件，不提交 git。
- `data/`、`logs/`、`runtime/`、`backup/` 和 `.env` 必须写入 `/home/xs/workplace/docker/.gitignore`。
- `conf/`、`.env.example`、`docker-compose.yml`、`scripts/` 可以纳入版本管理。
- 挂载目录权限按镜像用户处理，每个服务 README 必须写清需要的 `chown/chmod`。

建议 `.gitignore`：

```gitignore
**/data/
**/logs/
**/runtime/
**/backup/
**/.env
**/.DS_Store
```

## 6. Docker 网络命名规范

每套服务默认使用独立网络。

命名规则：

```text
dev_<service>_net
```

示例：

```text
dev_mysql_local_net
dev_redis_cluster_6_net
dev_kafka_local_net
dev_kafka_cluster_net
```

需要跨服务访问时，额外创建共享网络：

```text
dev_shared_net
```

规则：

- 默认不把所有服务放进同一个网络。
- 单个服务目录内的组件使用该服务自己的 network。
- 只有明确需要互通的服务才加入 `dev_shared_net`。
- network 名称必须写死，避免 Compose 自动生成不稳定名称。

## 7. Docker 自启动规范

所有服务 compose 中必须配置：

```yaml
restart: unless-stopped
```

Docker 服务本身启用开机启动：

```bash
sudo systemctl enable docker
sudo systemctl enable containerd
```

说明：

- `restart: unless-stopped` 表示机器重启后容器自动恢复。
- 如果手动 `docker compose stop`，下次 Docker 重启不会强制启动该容器。
- 本计划选择全部服务支持开机自启动。
- 是否实际启动某个服务，由是否执行过该服务的 `docker compose up -d` 决定。

## 8. 端口规划

Docker 端口必须避开本地默认端口，并且 local 与 cluster 端口不能冲突。

compose 端口格式必须默认绑定本机：

```yaml
ports:
  - "127.0.0.1:13306:3306"
```

| 服务 | 本地默认端口 | Docker 端口 |
| --- | --- | --- |
| mysql-local | `3306` | `13306` |
| mysql-8-replication master | `3306` | `13310` |
| mysql-8-replication slave-1 | `3306` | `13311` |
| mysql-8-replication slave-2 | `3306` | `13312` |
| redis-local | `6379` | `16379` |
| redis-cluster node-1..6 | `6379` | `16400` - `16405` |
| redis-sentinel redis nodes | `6379` | `16410` - `16412` |
| redis-sentinel sentinel nodes | `26379` | `26410` - `26412` |
| mongo-local | `27017` | `37017` |
| mongo-replica node-1..3 | `27017` | `37020` - `37022` |
| postgres-local | `5432` | `15432` |
| kafka-local | `9092` | `19092` |
| kafka-local UI | - | `18082` |
| kafka-cluster broker-1..3 | `9092` | `19093` - `19095` |
| rabbitmq-local amqp | `5672` | `15672` |
| rabbitmq-local ui | `15672` | `15673` |
| rabbitmq-cluster amqp | `5672` | `25672`、`35672`、`45672` |
| rabbitmq-cluster ui | `15672` | `25673` |
| apisix http | `9080` | `19080` |
| apisix https | `9443` | `19443` |
| apisix admin | `9180` | `19180` |
| nginx http | `80` | `18080` |
| nginx https | `443` | `18443` |
| minio api | `9000` | `19000` |
| minio console | `9001` | `19001` |
| elasticsearch | `9200` | `19200` |
| kibana | `5601` | `15601` |
| prometheus | `9090` | `19090` |
| grafana | `3000` | `13000` |
| metabase | `3000` | `13001` |
| nacos | `8848` | `18848` |
| consul | `8500` | `18500` |

## 9. 服务实施顺序

第一批，基础数据库：

1. `mysql-local`
2. `redis-local`
3. `mongo-local`
4. `postgres-local`

第二批，集群数据库：

1. `mysql-8-replication`
2. `redis-cluster-6`
3. `redis-sentinel-6`
4. `mongo-replica`

第三批，中间件和网关：

1. `kafka-local`
2. `kafka-cluster`
3. `rabbitmq-local`
4. `rabbitmq-cluster`
5. `apisix`
6. `nginx`
7. `minio`

第四批，观测和分析：

1. `elasticsearch`
2. `prometheus-grafana`
3. `metabase`

第五批，注册配置中心：

1. `nacos`
2. `consul`

## 10. 每个服务 README 必须包含

每个 `/home/xs/workplace/docker/<service>/README.md` 必须写清：

- 服务用途。
- 组件列表。
- 端口映射。
- 账号密码。
- 目录挂载。
- 启动命令。
- 停止命令。
- 查看日志命令。
- 连接串。
- 初始化说明。
- 重复执行说明。
- 数据清理说明。
- 镜像具体版本。
- 健康检查说明。
- 目录权限说明。

统一命令：

```bash
docker compose up -d
docker compose ps
docker compose logs -f
docker compose down
```

清理数据必须显式说明风险：

```bash
docker compose down -v
rm -rf data logs
```

## 11. Docker 根目录 Makefile

Docker 根目录需要统一 `Makefile`，后续支持：

```bash
make up SERVICE=mysql-local
make down SERVICE=mysql-local
make restart SERVICE=mysql-local
make ps SERVICE=mysql-local
make logs SERVICE=mysql-local
make config SERVICE=mysql-local
```

规则：

- `SERVICE` 必填。
- Makefile 只进入对应服务目录执行 `docker compose`。
- Makefile 不直接删除数据。
- 清理数据必须进入服务目录执行明确的清理脚本。

## 12. 备份恢复规范

数据库和存储类服务必须提供：

```text
scripts/backup.sh
scripts/restore.sh
```

必须覆盖：

- `mysql-local`
- `mysql-8-replication`
- `redis-local`
- `redis-cluster-6`
- `redis-sentinel-6`
- `mongo-local`
- `mongo-replica`
- `postgres-local`
- `minio`

规则：

- 备份文件默认写入 `backup/`。
- `backup/` 不提交 git。
- `restore.sh` 必须要求显式确认。
- 备份恢复脚本必须可重复执行。

## 13. Python 本地环境补充计划

Python 本地建议使用：

- `pyenv` 管理 Python 多版本。
- `venv` 管理项目虚拟环境。
- `pipx` 安装全局 CLI 工具。
- `poetry` 或 `uv` 管理项目依赖。

目标版本建议：

```text
Python 3.10
Python 3.11
Python 3.12
Python 3.13
```

默认版本：

```text
Python 3.12 或当前稳定版本
```

项目级约定：

```text
.python-version
pyproject.toml
requirements.txt
requirements-dev.txt
```

本地开发原则：

- 不把项目依赖安装到系统 Python。
- 每个项目使用自己的虚拟环境。
- CLI 工具使用 `pipx` 安装。

## 14. 阶段边界

Phase 1：文档修正。

- 只修改 `desc.md` 和 `plan.md`。
- 不调整 Docker 目录结构。
- 不创建 compose。

Phase 2：目录骨架调整。

- 调整 `/home/xs/workplace/docker` 子目录。
- 增加 `runtime/`、`backup/`、`.env.example`。
- 增加根目录 `Makefile` 和 `scripts/`。
- 删除旧的 `kafka/`、`rabbitmq/` 目录。
- 不创建真实 compose。

Phase 3：P0 单机服务 compose。

- `mysql-local`
- `redis-local`
- `mongo-local`
- `postgres-local`
- `nginx`

Phase 4：集群和中间件 compose。

- MySQL 主从。
- Redis Cluster / Sentinel。
- Mongo Replica。
- Kafka / RabbitMQ 单机和集群。
- APISIX、MinIO、监控、分析类服务。

## 15. 本阶段不做的事

当前只写文档，不做以下操作：

- 不创建 `/home/xs/workplace/docker` 下的 compose 文件。
- 不调整 `/home/xs/workplace/docker` 目录结构。
- 不启动容器。
- 不安装系统软件。
- 不修改 `~/.bashrc`。
- 不执行 Docker 初始化。
