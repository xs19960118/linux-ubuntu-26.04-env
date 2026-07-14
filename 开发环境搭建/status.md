# 开发环境搭建状态

更新时间：2026-07-14

## 已完成

- Docker 已安装：`Docker version 29.6.1`
- Docker Compose 已安装：`Docker Compose version v5.1.4`
- Docker daemon 正在运行，当前用户 `xs` 已在 `docker` 组，可直接执行 `docker` 命令。
- `docker.service`、`containerd.service` 均已启用开机自启动。
- `/home/xs/workplace/docker` 下 20 个服务目录已存在。
- 20 个服务目录均已从 `.env.example` 生成本地 `.env`。
- 20 个 `docker-compose.yml` 均通过 `docker compose config` 静态校验。
- 每个服务目录均包含 `conf/`、`data/`、`logs/`、`runtime/`、`backup/`、`scripts/`。
- `docker/.gitignore` 已忽略 `data/`、`logs/`、`runtime/`、`backup/`、`.env`。
- `docker/scripts/check-structure.sh` 已从占位脚本补成实际结构检查，并通过：`structure check ok: 20 service(s)`。
- `docker/scripts/check-ports.sh` 已从占位脚本补成实际端口检查，并通过：`port check ok`。
- 已修复 Docker 端口冲突：`kafka-local` 的 Kafka UI 从 `18080` 调整为 `18082`，保留 `nginx` 使用 `18080/18443`。
- Docker daemon 已配置国内镜像源：`docker.1ms.run`、`docker.xuanyuan.me`、`hub.rat.dev`。
- Docker Compose 全量开发环境已一次性启动：20 组 Compose 项目均为 `running`，共 46 个容器。
- 所有 Docker 开发容器均为 `restart: unless-stopped`，Docker daemon 启动后会自动恢复。
- 已新增 Docker 全量脚本：
  - `/home/xs/workplace/docker/scripts/pull-all-images-cn.sh`：通过国内镜像源拉取并标记所需镜像。
  - `/home/xs/workplace/docker/scripts/up-all.sh`：一次性启动全部服务，并初始化 Nacos 数据库、Redis Cluster。
  - `/home/xs/workplace/docker/scripts/ps-all.sh`：按服务目录查看所有容器状态。
- 已新增中文服务说明：`/home/xs/workplace/docker/服务说明.md`。
- 已新增 Docker 操作指南：`/home/xs/workplace/docker/Docker操作指南.md`，覆盖全量启动、状态查看、日志、进入容器、备份恢复、清理和排障命令。
- 已补齐 Docker 中原本占位的备份/恢复脚本：
  - `minio/scripts/backup.sh`、`minio/scripts/restore.sh`
  - `mongo-replica/scripts/backup.sh`、`mongo-replica/scripts/restore.sh`
  - `mysql-8-replication/scripts/backup.sh`、`mysql-8-replication/scripts/restore.sh`
  - `redis-cluster-6/scripts/backup.sh`、`redis-cluster-6/scripts/restore.sh`
  - `redis-sentinel-6/scripts/backup.sh`、`redis-sentinel-6/scripts/restore.sh`
- 已实际验证新补的备份脚本可生成备份：MinIO、MongoDB 副本集、MySQL 主从主库、Redis Cluster、Redis Sentinel。
- Docker 本地基础服务已启动并验证：
  - Redis：`dev-redis-local`，`127.0.0.1:16379`，healthy。
  - MySQL：`dev-mysql-local`，`127.0.0.1:13306`，healthy。
  - PostgreSQL：`dev-postgres-local`，`127.0.0.1:15432`，healthy。
  - MongoDB：`dev-mongo-local`，`127.0.0.1:37017`，healthy。
- Docker Kafka 已启动并验证：
  - Kafka broker：`dev-kafka-local`，宿主机连接 `127.0.0.1:19092`，healthy。
  - Kafka UI：`http://127.0.0.1:18082`，`/actuator/health` 返回 `UP`。
- Docker APISIX 已启动并验证：
  - APISIX gateway：`http://127.0.0.1:19080`，无路由时返回 `404 Route Not Found`，说明网关正常。
  - APISIX Admin API：`http://127.0.0.1:19180`，`X-API-KEY: xsailxma` 可访问。
  - APISIX HTTPS：`127.0.0.1:19443`。
  - etcd：`dev-apisix-etcd`，healthy。
- Docker Nginx 已启动并验证：`http://127.0.0.1:18080` 返回正常。
- Docker Nacos 已启动并验证：`http://127.0.0.1:18848/nacos/` 可访问；内置 MySQL 已导入 Nacos schema，控制台账号 `xs / xsailxma` 登录成功且为 `globalAdmin`。
- Docker Consul 已启动并验证：`http://127.0.0.1:18500` 可访问，leader 正常。
- Docker Redis Cluster 已启动并初始化：6 节点，3 主 3 从，`cluster_state:ok`，`16384` slots 全覆盖。
- Docker Redis Sentinel 已启动：1 主 2 从 + 3 Sentinel。
- Docker MongoDB 副本集已启动并初始化：`mongo-1:PRIMARY`，`mongo-2/mongo-3:SECONDARY`。
- Docker MySQL 一主两从复制环境已启动：`13310/13311/13312`。
- Docker RabbitMQ 单机和三节点集群已启动，管理端分别为 `15673` 和 `25673`。
- Docker Kafka 三节点 KRaft 集群已修复固定 `KAFKA_KRAFT_CLUSTER_ID`，宿主机端口 `19093/19094/19095` 验证可用，Kafka UI 为 `http://127.0.0.1:18081`。
- Docker Elasticsearch + Kibana 已启动：ES `19200`，Kibana `15601`。
- Docker MinIO 已启动并验证：API `19000`，Console `19001`，账号 `xsminio / xsailxma`。
- Docker Prometheus + Grafana + node-exporter 已启动并验证：Prometheus `19090`，Grafana `13000`。
- Docker Metabase 已启动：`http://127.0.0.1:13001`。
- Docker Compose 已针对当前镜像源和镜像差异修正：
  - `kafka-local` 从 `bitnami/kafka:3.7.1` 改为 `apache/kafka:3.7.1`，并配置内外双 listener。
  - `apisix` 的 etcd 从 `bitnami/etcd:3.5.15` 改为 `quay.io/coreos/etcd:v3.5.15`。
  - Postgres / Mongo / Redis / APISIX 均修正了容器日志目录权限导致的启动问题。
- `~/.bashrc` 已加入 Java/Gradle 用户级初始化、PHP 用户级 shim、asdf、nvm、Go、Composer、pnpm、`~/.local/bin` 初始化。
- Java 已改为不使用 SDKMAN：通过 Ubuntu 清华源安装 `openjdk-8-jdk`、`openjdk-17-jdk`、`openjdk-21-jdk`、`openjdk-25-jdk`。
- 默认 Java / javac 已切到 JDK 17：`java 17.0.19`、`javac 17.0.19`。
- Maven 已通过 apt 安装：`Apache Maven 3.9.12`。
- Gradle 已改为不使用 SDKMAN：通过阿里云 Gradle 镜像安装到 `~/.local/opt/gradle-8.14.3`，当前 `gradle -version` 为 `8.14.3`。
- `~/.bashrc` 已设置 `JAVA_HOME=/usr/lib/jvm/java-17-openjdk-amd64`、`GRADLE_HOME=~/.local/opt/gradle-8.14.3`。
- `~/.bashrc` 已加入用户级语言切换函数：
  - `use-java 8|17|21|25`：只修改当前用户的 shim 和 `JAVA_HOME`，不需要 sudo，不改系统 alternatives。
  - `use-php 8.5`：只修改当前用户的 PHP shim，不需要 sudo。
  - `java-switch`：菜单式选择 Java 版本；别名 `jdk-switch`、`jswitch`。
  - `php-switch`：菜单式选择 PHP 版本；别名 `pswitch`。
  - `node-switch`：菜单式选择 Node.js 版本；别名 `nswitch`。
  - `dev-switch`：总入口，先选择 Java / PHP / Node.js；别名 `switch-dev`。
  - `show-dev-versions`：快速查看当前宿主机语言版本。
- Node.js 已通过 nvm 安装：`20.20.2`、`24.16.0`、`26.3.0`，默认 `26.3.0`。
- pnpm 已通过当前 nvm Node.js 安装：`11.12.0`。
- TypeScript 已通过当前 nvm Node.js 全局安装：`tsc 7.0.2`。项目内仍建议按项目安装 `typescript` 并提交锁文件。
- Python 已安装：`Python 3.14.4`，`venv` 可用。
- Go 已通过 apt 安装：`go1.26.0 linux/amd64`。
- `yq`、`sqlite3`、`python3-pip`、`pipx` 已通过 apt 安装。
- 宿主机 PHP 已安装：`PHP 8.5.4`、`Composer 2.9.5`、`phpize 8.5`、`php-config 8.5.4`。
- 宿主机 PHP 8.5 已安装扩展包含：`curl`、`intl`、`mbstring`、`mongodb`、`mysqli`、`pdo_mysql`、`pdo_pgsql`、`pgsql`、`redis`、`xml`、`zip`、`opcache`。
- 宿主机 PHP 多版本已安装：`5.6`、`7.1`、`7.4`、`8.1`、`8.4`、`8.5` 的 CLI / FPM / dev 均可用。
- `~/.bashrc` 的 `php-switch` 已改为动态检测已安装 PHP 版本，当前可切换 `5.6`、`7.1`、`7.4`、`8.1`、`8.4`、`8.5`。
- `~/.bashrc` 已加入 `php-list` 和 `php-info-current`，用于查看每个 PHP 版本的 CLI / FPM / dev / PEAR 状态和当前 PHP 配置。
- 已确认 `https://packages.sury.org/php/` 存在 Ubuntu 26.04 `resolute` 仓库，并提供 `php5.6`、`php7.1`、`php7.4`、`php8.1`、`php8.4`、`php8.5` 的 CLI / FPM / dev / 常用扩展包。
- 已生成宿主机 PHP 多版本安装脚本：`/home/xs/workplace/开发环境搭建/install-php-multiversion.sh`。
- PHP 多版本安装脚本已包含 Kafka 扩展 `phpX.Y-rdkafka`，并安装系统依赖 `librdkafka-dev`。AMQP 扩展同时安装 `librabbitmq-dev`。
- 已生成 PHP 扩展版本审计脚本：`/home/xs/workplace/开发环境搭建/audit-php-extensions.sh`，用于逐版本检查 `redis`、`mongodb`、`rdkafka`、`amqp`、`memcached`、`imagick`、`xdebug`、`yaml` 等扩展启用状态和版本。
- PHP 多版本已安装后当前审计结果：
  - CLI / FPM / dev：`5.6`、`7.1`、`7.4`、`8.1`、`8.4`、`8.5` 均已安装，且对应 FPM 均为 `active`。
  - Kafka `rdkafka`：`7.1`、`7.4`、`8.1`、`8.4`、`8.5` 已启用，运行时 `librdkafka 2.13.0`；`5.6` 当前缺失，Sury `resolute` 源未提供 `php5.6-rdkafka` 包。
  - AMQP `amqp`：`5.6`、`7.1`、`7.4`、`8.1`、`8.4`、`8.5` 均已启用。
  - `php7.4-mongodb` 当前缺失；Sury `resolute` 源未提供 `php7.4-mongodb` 包。
  - Composer / PEAR / PECL shim 已修正：`use-php X.Y` 会生成包装脚本，使 `composer` 使用当前 `phpX.Y` 执行，并通过 `PHP_PEAR_PHP_BIN` 让 `pear` / `pecl` 绑定当前 PHP CLI。
- 宿主机 MySQL 已安装并运行：`8.4.10`，`mysql.service` 为 `active`。
- 宿主机 Redis 已安装并运行：`8.0.5`，`redis-server.service` 为 `active`。
- 宿主机 PostgreSQL 已安装并运行：`18.4`，`postgresql.service` 为 `active`。
- PostgreSQL 即常说的“大象”数据库，本机集群 `18/main` 已在线，监听 `127.0.0.1:5432`。
- 宿主机 PHP-FPM 已安装并运行：`php8.5-fpm.service` 为 `active`。

## 当前受限

- 当前会话不能输入 sudo 密码，无法执行系统包安装。
- Docker Hub 直连仍可能不稳定；当前已通过国内镜像源和替代上游镜像完成 Redis / MySQL / PostgreSQL / MongoDB / Kafka / APISIX 启动验证。
- GitHub / GitHub release 下载链路可能不稳定；asdf 本体已改用 Go + `goproxy.cn` 安装完成，后续添加 asdf 插件时仍可能受 GitHub 网络影响。
- 当前 Docker 20 组开发服务均已拉取、启动并完成关键验证。
- 不再使用 SDKMAN 安装 Java / Maven / Gradle。
- asdf 已安装：`0.20.0`，二进制位于 `/home/xs/.local/bin/asdf`，数据目录为 `/home/xs/.asdf`。
- `~/.bashrc` 已按 asdf 0.16+ 新方式配置：加入 `${ASDF_DATA_DIR:-$HOME/.asdf}/shims`，并使用 `asdf completion bash`。
- 已新增 asdf 操作指南：`/home/xs/workplace/开发环境搭建/asdf操作指南.md`。
- Go 已先用 apt 满足宿主机开发；PHP 多版本已改用 Sury apt 仓库完成主链路。asdf 当前只作为项目特殊版本管理工具，不迁移已跑通的 Java / PHP 主链路。
- PHP 多版本主链路已完成：`5.6`、`7.1`、`7.4`、`8.1`、`8.4`、`8.5` 的 CLI / FPM / dev 均已安装，FPM 均为 `active`。
- PHP 扩展仍有两个明确缺口：`php5.6-rdkafka` 和 `php7.4-mongodb` 在当前 Sury `resolute` 源未提供包。
- `php8.5-imagick` 包已安装且 CLI / FPM 已启用，审计结果为 enabled。
- 宿主机 MongoDB 已安装并运行：`mongod 8.0.26`、`mongosh 2.9.2`，`mongod.service` 为 `active`，监听 `127.0.0.1:27017`。
- MongoDB 已因当前 Linux 7.x 内核兼容问题配置 systemd override：`GLIBC_TUNABLES=glibc.pthread.rseq=1`。
- MongoDB 已创建开发账号：`xs / xsailxma`，认证库 `admin`。
- 已生成宿主机 MongoDB 8.0 兼容安装脚本：`/home/xs/workplace/开发环境搭建/install-mongodb-local.sh`。说明：MongoDB 官方暂未提供 Ubuntu 26.04 专用仓库，脚本使用官方 Ubuntu 24.04 `noble` 仓库兼容安装。
- 已生成宿主机 MongoDB 验证脚本：`/home/xs/workplace/开发环境搭建/check-mongodb-local.sh`。
- 已生成 MongoDB 账号初始化脚本：`/home/xs/workplace/开发环境搭建/init-mongodb-user.sh`。
- 宿主机 Nginx 已安装：`nginx/1.28.3 (Ubuntu)`，服务为 `active`。
- 已生成宿主机 Nginx + 多 PHP-FPM 测试站点安装脚本：`/home/xs/workplace/开发环境搭建/install-nginx-php-sites.sh`。
- 已生成宿主机 Nginx 多 PHP-FPM 测试脚本：`/home/xs/workplace/开发环境搭建/check-nginx-php-sites.sh`。
- 宿主机 Nginx 已验证 6 个 PHP-FPM 测试站点可访问：`php56.xs.local`、`php71.xs.local`、`php74.xs.local`、`php81.xs.local`、`php84.xs.local`、`php85.xs.local`。
- 宿主机 APISIX 未安装；当前决策为使用 Docker APISIX，已启动并验证通过。
- Kafka 不再做宿主机安装，按当前决策使用 Docker Compose：`/home/xs/workplace/docker/kafka-local` 或 `kafka-cluster`。
- APISIX 不再做宿主机安装，按当前决策使用 Docker Compose：`/home/xs/workplace/docker/apisix`，当前已运行。
- 当前 Ubuntu 26.04 apt 源可直接安装：
  - MySQL：`mysql-server`，候选版本 `8.4.10`。
  - Redis：`redis-server`，候选版本 `8.0.5`。
  - PostgreSQL：`postgresql` / `postgresql-18`。
  - PHP：`php8.5-*`。
- 当前 Ubuntu 26.04 apt 源没有 `mongodb-server` 候选包；MongoDB 官方文档当前列出的 Ubuntu 8.0 支持平台仍是 24.04 / 22.04 / 20.04，不包含 26.04。本机已使用官方 24.04 `noble` 仓库兼容安装。
- PHP 可按需继续补充 `swoole` 等 PECL 扩展；当前通用 apt 扩展已基本覆盖。

## 需要你在终端执行的 sudo 命令

当前 Docker 环境没有必须补执行的 sudo 命令；`docker` 和 `containerd` 已启用自启动。

如需先走系统包完成基础语言链路：

```bash
sudo apt update
sudo apt install -y openjdk-17-jdk maven golang-go yq sqlite3 autoconf bison re2c pkg-config python3-pip pipx
```

## Docker 验证命令

```bash
cd /home/xs/workplace/docker
docker compose ls --all
./scripts/check-structure.sh
./scripts/check-ports.sh
make ps SERVICE=redis-local
make ps SERVICE=mysql-local
make ps SERVICE=postgres-local
make ps SERVICE=mongo-local
make ps SERVICE=kafka-local
make ps SERVICE=apisix
```

当前 Docker 20 组服务均已启动验证。后续改 compose 后仍建议先执行 `docker compose config` 再 `docker compose up -d`。

## 宿主机 MongoDB 安装命令

需要 sudo 密码，在终端执行：

```bash
sudo bash "/home/xs/workplace/开发环境搭建/install-mongodb-local.sh"
"/home/xs/workplace/开发环境搭建/check-mongodb-local.sh"
```

脚本会安装 `mongodb-org`、`mongodb-mongosh`，启动 `mongod`，并创建开发账号：

```text
username: xs
password: xsailxma
auth db: admin
url: mongodb://xs:xsailxma@127.0.0.1:27017/admin
```

## 当前宿主机语言方案

- Java：使用 Ubuntu 清华源 apt 包，不使用 SDKMAN。
- 默认 JDK：17。
- Java 切换：日常使用 `java-switch`，也可直接使用 `use-java 8`、`use-java 17`、`use-java 21`、`use-java 25`。
- Maven：使用 apt 包，当前 `3.9.12`。
- Gradle：apt 源版本过旧，已手动从阿里云 Gradle 镜像安装 `8.14.3` 到 `~/.local/opt/gradle-8.14.3`。
- Go：使用 apt 包，当前 `1.26.0`。
- Node.js：继续使用 nvm。
- pnpm：已通过当前 nvm Node.js 安装。
- TypeScript：全局 CLI 已安装；项目内仍以项目依赖为准。
- PHP：宿主机多版本使用 Sury apt 包，当前 `5.6`、`7.1`、`7.4`、`8.1`、`8.4`、`8.5` 均已安装。
- PHP 切换：日常使用 `php-switch`，也可直接使用 `use-php 5.6|7.1|7.4|8.1|8.4|8.5`。`php-list` 可查看每个版本 CLI / FPM / dev 状态。

## PHP 8.5 可选扩展补充命令

如需要补齐更完整的 PHP 8.5 开发扩展：

```bash
sudo apt install -y \
  php8.5-bcmath php8.5-bz2 php8.5-gd php8.5-gmp \
  php8.5-imagick php8.5-ldap php8.5-soap php8.5-sqlite3 \
  php8.5-amqp php8.5-xdebug php8.5-yaml php8.5-memcached
sudo systemctl restart php8.5-fpm
php -m | sort
```

## PHP 宿主机多版本安装命令

需要 sudo 密码，在终端执行：

```bash
sudo bash "/home/xs/workplace/开发环境搭建/install-php-multiversion.sh"
source ~/.bashrc
php-list
php-switch
php-info-current
```

脚本会安装 PHP `5.6`、`7.1`、`7.4`、`8.1`、`8.4`、`8.5` 的 CLI / FPM / dev 包和常用扩展，并启用对应 `phpX.Y-fpm` 服务。PEAR / PECL 使用系统 `php-pear`，通过 `use-php` 设置 `PHP_PEAR_PHP_BIN` 绑定当前 PHP CLI。

如安装脚本执行前版本较旧，或审计显示 `amqp` 缺失，补装：

```bash
sudo apt install -y php5.6-amqp php7.1-amqp php7.4-amqp php8.1-amqp php8.4-amqp php8.5-amqp
sudo systemctl restart php5.6-fpm php7.1-fpm php7.4-fpm php8.1-fpm php8.4-fpm php8.5-fpm
"/home/xs/workplace/开发环境搭建/audit-php-extensions.sh"
```

当前 `amqp` 已补齐；如果以后重装系统后再次缺失，再执行上面的补装命令。

安装完成后审计每个 PHP 版本的扩展和扩展版本：

```bash
"/home/xs/workplace/开发环境搭建/audit-php-extensions.sh"
```

## 宿主机 Nginx / APISIX 状态

- Nginx：已安装并完成多 PHP-FPM 测试站点。验证：

```bash
nginx -v
systemctl status nginx --no-pager
"/home/xs/workplace/开发环境搭建/check-nginx-php-sites.sh"
```

已创建这些本地域名和站点：

```text
http://php56.xs.local -> /run/php/php5.6-fpm.sock
http://php71.xs.local -> /run/php/php7.1-fpm.sock
http://php74.xs.local -> /run/php/php7.4-fpm.sock
http://php81.xs.local -> /run/php/php8.1-fpm.sock
http://php84.xs.local -> /run/php/php8.4-fpm.sock
http://php85.xs.local -> /run/php/php8.5-fpm.sock
```

- APISIX：宿主机不安装，当前使用 Docker Compose：`/home/xs/workplace/docker/apisix`。

## asdf 状态

asdf 已安装完成。常用命令见：

```bash
/home/xs/workplace/开发环境搭建/asdf操作指南.md
```

注意：PHP 5.6 / 7.1 / 7.4 在 Ubuntu 26.04 上通过 asdf 本机编译成本较高，当前宿主机 PHP 多版本已用 Sury apt 完成，不建议再迁移到 asdf。
