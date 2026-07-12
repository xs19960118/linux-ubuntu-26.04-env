# Linux Ubuntu 26.04 开发环境搭建

本文档用于规划 Ubuntu 26.04 本地开发环境。

目标：

- Linux 本机负责开发工具和多版本语言运行时。
- Docker 负责数据库、中间件、网关、Web 服务器等基础设施集群。
- 当前阶段只整理文档和 Docker 目录骨架，不实际安装、不创建 compose、不启动服务。
- Docker 根目录固定为 `/home/xs/workplace/docker`。
- 详细实施计划见 `plan.md`。

推荐原则：

- Java、PHP、Node、Go 这类开发语言使用本机版本管理器，方便 IDE、调试、命令行切换。
- 本地可以安装 MySQL、Redis、MongoDB，因此 Docker 里的数据库不占用默认端口。
- Docker local 和 cluster 服务允许同时启动，因此 Docker 端口必须全局唯一。
- Docker 端口默认只绑定 `127.0.0.1`，不默认暴露到局域网。
- MySQL、Redis、MongoDB、Kafka、RabbitMQ、APISIX、Nginx 等服务使用 Docker Compose 管理。
- 某些旧项目如果依赖很老的 PHP/JDK，也可以单独使用项目级 Docker 容器兜底。

文档目录：

- `desc.md`：总说明、环境规划、目录规划。
- `plan.md`：可多次执行的实施计划、端口规范、账号规范、挂载规范、自启动规范。
- `/home/xs/workplace/docker`：后续所有 Docker Compose 服务目录。

统一账号密码：

```text
username: xs
password: xsailxma
```

说明：

- 需要账号密码的开发服务统一使用 `xs / xsailxma`。
- root、admin、默认管理账号的密码也统一使用 `xsailxma`。
- 生产环境不能使用本文档中的开发账号密码。

---

## 1. Linux 本地开发环境搭建

### 1.1 基础工具

建议先安装常用工具和开发包：

```bash
sudo apt update
sudo apt install -y \
  build-essential gcc g++ make cmake pkg-config autoconf automake libtool \
  ca-certificates gnupg lsb-release software-properties-common apt-transport-https \
  git git-lfs curl wget aria2 rsync unzip zip tar xz-utils p7zip-full \
  vim nano less tree jq yq htop btop lsof strace file locales \
  net-tools iproute2 iputils-ping dnsutils telnet netcat-openbsd traceroute nmap \
  openssl openssh-client openssh-server \
  python3 python3-pip python3-venv pipx \
  sqlite3 libsqlite3-dev \
  libssl-dev zlib1g-dev libbz2-dev libreadline-dev libffi-dev \
  libxml2-dev libxslt1-dev libcurl4-openssl-dev \
  libjpeg-dev libpng-dev libwebp-dev libfreetype6-dev \
  libzip-dev libonig-dev libicu-dev
```

验证：

```bash
git --version
curl --version
gcc --version
make --version
cmake --version
openssl version
python3 --version
ssh -V
```

工具分类：

| 类型 | 工具 |
| --- | --- |
| 编译构建 | `build-essential`、`gcc`、`g++`、`make`、`cmake`、`pkg-config`、`autoconf`、`automake`、`libtool` |
| 下载传输 | `curl`、`wget`、`aria2`、`rsync`、`openssh-client` |
| 压缩解压 | `unzip`、`zip`、`tar`、`xz-utils`、`p7zip-full` |
| 代码工具 | `git`、`git-lfs` |
| 文本处理 | `vim`、`nano`、`less`、`jq`、`yq`、`file` |
| 系统排查 | `htop`、`btop`、`lsof`、`strace`、`tree` |
| 网络排查 | `net-tools`、`iproute2`、`ping`、`dig`、`telnet`、`nc`、`traceroute`、`nmap` |
| Python 辅助 | `python3`、`python3-pip`、`python3-venv`、`pipx` |
| 常见开发库 | `openssl`、`sqlite3`、`zlib`、`libxml2`、`libcurl`、`libjpeg`、`libpng`、`libzip`、`icu` |

---

### 1.2 Shell 环境变量与切换命令

多版本开发环境需要在 `~/.bashrc` 中初始化版本管理器，否则新开 shell 后可能找不到 `sdk`、`asdf`、`nvm`。

建议统一追加到 `~/.bashrc`：

```bash
# ===== Dev Environment =====

# SDKMAN: Java / Maven / Gradle
export SDKMAN_DIR="$HOME/.sdkman"
[[ -s "$SDKMAN_DIR/bin/sdkman-init.sh" ]] && source "$SDKMAN_DIR/bin/sdkman-init.sh"

# asdf: PHP / Go
if [ -f "$HOME/.asdf/asdf.sh" ]; then
  . "$HOME/.asdf/asdf.sh"
fi

if [ -f "$HOME/.asdf/completions/asdf.bash" ]; then
  . "$HOME/.asdf/completions/asdf.bash"
fi

# nvm: Node.js
export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && . "$NVM_DIR/nvm.sh"
[ -s "$NVM_DIR/bash_completion" ] && . "$NVM_DIR/bash_completion"

# Go
export GOPATH="$HOME/go"
export GOBIN="$GOPATH/bin"
export PATH="$GOBIN:$PATH"

# Composer
export COMPOSER_HOME="$HOME/.composer"
export PATH="$COMPOSER_HOME/vendor/bin:$PATH"

# npm / pnpm
export PNPM_HOME="$HOME/.local/share/pnpm"
export PATH="$PNPM_HOME:$PATH"

# Local bin
export PATH="$HOME/.local/bin:$PATH"

# Common aliases
alias ll='ls -alF'
alias la='ls -A'
alias l='ls -CF'
alias grep='grep --color=auto'
alias cls='clear'
alias dk='docker'
alias dkc='docker compose'
```

写入后重新加载：

```bash
source ~/.bashrc
```

确认版本管理器可用：

```bash
sdk version
asdf --version
nvm --version
node -v
go version
php -v
```

常用切换命令：

```bash
# Java
sdk use java 8.0.422-tem
sdk use java 17.0.12-tem
sdk use java 21.0.4-tem
sdk use java 25-tem

# Maven
sdk use maven 3.6.3
sdk use maven 3.8.8
sdk use maven 3.9.9

# Gradle
sdk use gradle 6.9.4
sdk use gradle 7.6.4
sdk use gradle 8.10.2

# PHP
asdf shell php 5.6.40
asdf shell php 7.1.33
asdf shell php 7.4.33
asdf shell php 8.1.29
asdf shell php 8.4.0

# Node.js
nvm use 20
nvm use 24
nvm use 26.3.0

# Go
asdf shell golang 1.22.12
asdf shell golang 1.23.6
asdf shell golang 1.24.0
asdf shell golang 1.25.0
```

项目级切换文件：

```text
.sdkmanrc       # Java
.tool-versions # PHP / Go
.nvmrc          # Node.js
```

说明：

- `sdk use`、`asdf shell`、`nvm use` 只影响当前 shell。
- `sdk default`、`asdf global`、`nvm alias default` 会影响默认版本。
- 项目目录中优先使用 `.sdkmanrc`、`.tool-versions`、`.nvmrc` 固定版本。

---

### 1.3 Java 多版本

目标版本：

- JDK 8
- JDK 17
- JDK 21
- JDK 25
- 默认版本：JDK 17
- 支持 shell 命令直接切换

推荐使用 `SDKMAN` 管理 Java 多版本。

安装 SDKMAN：

```bash
curl -s "https://get.sdkman.io" | bash
source "$HOME/.sdkman/bin/sdkman-init.sh"
```

查看可安装 JDK：

```bash
sdk list java
```

安装 JDK：

```bash
sdk install java 8.0.422-tem
sdk install java 17.0.12-tem
sdk install java 21.0.4-tem
sdk install java 25-tem
```

设置默认 JDK 17：

```bash
sdk default java 17.0.12-tem
```

临时切换版本：

```bash
sdk use java 8.0.422-tem
sdk use java 17.0.12-tem
sdk use java 21.0.4-tem
sdk use java 25-tem
```

验证：

```bash
java -version
javac -version
echo $JAVA_HOME
```

项目级版本固定：

```bash
echo "java=17.0.12-tem" > .sdkmanrc
sdk env
```

---

### 1.4 Maven 多版本

目标：

- Linux 本机安装 Maven。
- 支持多个 Maven 版本。
- 支持 shell 命令直接切换。
- 项目优先使用 `mvnw`，没有 wrapper 的项目使用本机 Maven。

推荐使用 `SDKMAN` 管理 Maven。

查看可安装 Maven：

```bash
sdk list maven
```

安装 Maven：

```bash
sdk install maven 3.6.3
sdk install maven 3.8.8
sdk install maven 3.9.9
```

设置默认 Maven：

```bash
sdk default maven 3.9.9
```

临时切换 Maven：

```bash
sdk use maven 3.8.8
mvn -version
```

验证：

```bash
mvn -version
which mvn
```

Maven 本地仓库建议：

```text
~/.m2/repository
```

国内镜像可在 `~/.m2/settings.xml` 中配置，例如阿里云、腾讯云、华为云 Maven 镜像。

项目建议：

- 新项目尽量提交 `mvnw`、`mvnw.cmd`、`.mvn/wrapper/`。
- 老项目没有 wrapper 时，使用本机 `mvn`。
- 多 JDK 项目要确认 `JAVA_HOME` 和 `mvn -version` 输出一致。

---

### 1.5 Gradle 多版本

目标：

- Linux 本机安装 Gradle。
- 支持多个 Gradle 版本。
- 支持 shell 命令直接切换。
- 项目优先使用 `gradlew`，没有 wrapper 的项目使用本机 Gradle。

推荐使用 `SDKMAN` 管理 Gradle。

查看可安装 Gradle：

```bash
sdk list gradle
```

安装 Gradle：

```bash
sdk install gradle 6.9.4
sdk install gradle 7.6.4
sdk install gradle 8.10.2
```

设置默认 Gradle：

```bash
sdk default gradle 8.10.2
```

临时切换 Gradle：

```bash
sdk use gradle 7.6.4
gradle -version
```

验证：

```bash
gradle -version
which gradle
```

Gradle 缓存目录：

```text
~/.gradle/caches
~/.gradle/wrapper
```

项目建议：

- 新项目尽量提交 `gradlew`、`gradlew.bat`、`gradle/wrapper/`。
- 老项目没有 wrapper 时，使用本机 `gradle`。
- 多 JDK 项目要确认 `JAVA_HOME`、`org.gradle.java.home`、IDE Gradle JVM 三者一致。

---

### 1.6 PHP 多版本

目标版本：

- PHP 5.6
- PHP 7.1
- PHP 7.4
- PHP 8.1
- PHP 8.4.x
- 默认版本：PHP 8.1
- 支持 shell 命令直接切换

说明：

- 原草稿中的 `PHP 8.45` 按 `PHP 8.4.x` 处理。
- PHP 5.6、PHP 7.1 已经停止维护，只建议用于历史项目兼容。
- 旧 PHP 在 Ubuntu 26.04 上编译可能需要额外系统依赖；如果本机编译成本太高，旧项目可以使用项目级 PHP 容器。

推荐使用 `asdf` 管理 PHP 多版本。

安装 asdf：

```bash
git clone https://github.com/asdf-vm/asdf.git ~/.asdf --branch v0.14.1
```

写入 shell 配置：

```bash
echo '. "$HOME/.asdf/asdf.sh"' >> ~/.bashrc
echo '. "$HOME/.asdf/completions/asdf.bash"' >> ~/.bashrc
source ~/.bashrc
```

安装 PHP 插件：

```bash
asdf plugin add php https://github.com/asdf-community/asdf-php.git
```

安装 PHP 编译依赖：

```bash
sudo apt install -y \
  autoconf bison re2c pkg-config \
  libxml2-dev libsqlite3-dev libssl-dev libcurl4-openssl-dev \
  libjpeg-dev libpng-dev libwebp-dev libonig-dev libzip-dev \
  libreadline-dev libtidy-dev libxslt1-dev \
  libbz2-dev libffi-dev libgmp-dev libldap2-dev libsasl2-dev \
  libpq-dev libicu-dev libkrb5-dev libedit-dev \
  libfreetype6-dev libmagickwand-dev libmemcached-dev \
  librabbitmq-dev librdkafka-dev libmongodb-dev \
  zlib1g-dev libzstd-dev liblz4-dev
```

安装 PHP 版本：

```bash
asdf install php 5.6.40
asdf install php 7.1.33
asdf install php 7.4.33
asdf install php 8.1.29
asdf install php 8.4.0
```

设置默认 PHP 8.1：

```bash
asdf global php 8.1.29
```

临时切换当前 shell：

```bash
asdf shell php 7.4.33
php -v
```

项目级固定 PHP：

```bash
asdf local php 8.1.29
cat .tool-versions
```

验证：

```bash
php -v
php -m
which php
```

Composer 建议：

```bash
php -r "copy('https://getcomposer.org/installer', 'composer-setup.php');"
php composer-setup.php
sudo mv composer.phar /usr/local/bin/composer
composer --version
```

PHP-FPM 建议：

- 本机主要使用 PHP CLI。
- PHP-FPM、Nginx、MySQL、Redis 等运行环境建议按项目写入 Docker Compose。
- 老项目如果强依赖 PHP 5.6/7.1，优先考虑项目级 `php-fpm` 容器。

PHP 常见扩展规划：

| 类型 | 扩展 | 说明 |
| --- | --- | --- |
| 基础 | `openssl` | HTTPS、Composer、加密、JWT 常用 |
| 基础 | `sockets` | Socket 编程、部分 MQ/网络组件依赖 |
| 基础 | `pcntl` | CLI 进程管理，队列 worker 常用 |
| 基础 | `posix` | Linux 用户、进程、权限相关能力 |
| 基础 | `mbstring` | 多字节字符串，Laravel/Symfony 常用 |
| 基础 | `intl` | 国际化、字符格式化 |
| 基础 | `bcmath` | 金额、精度计算 |
| 基础 | `ctype` | 字符类型判断 |
| 基础 | `curl` | HTTP 客户端 |
| 基础 | `fileinfo` | 文件 MIME 识别 |
| 基础 | `tokenizer` | 框架、静态分析、Composer 常用 |
| 基础 | `xml` | XML 解析 |
| 基础 | `simplexml` | XML 简化操作 |
| 基础 | `dom` | DOM 解析 |
| 基础 | `xmlreader` | XML 流式读取 |
| 基础 | `xmlwriter` | XML 写入 |
| 基础 | `zip` | 压缩包处理 |
| 基础 | `gd` | 图片处理 |
| 基础 | `exif` | 图片元数据 |
| 基础 | `readline` | CLI 交互 |
| 数据库 | `pdo` | PDO 基础 |
| 数据库 | `pdo_mysql` | MySQL PDO |
| 数据库 | `mysqli` | MySQL mysqli |
| 数据库 | `pdo_pgsql` | PostgreSQL PDO |
| 数据库 | `pgsql` | PostgreSQL 原生扩展 |
| 数据库 | `sqlite3` | SQLite |
| 数据库 | `pdo_sqlite` | SQLite PDO |
| 缓存 | `redis` | Redis 客户端，PECL 扩展 |
| 缓存 | `memcached` | Memcached 客户端，PECL 扩展 |
| 文档库 | `mongodb` | MongoDB 客户端，PECL 扩展 |
| MQ | `amqp` | RabbitMQ/AMQP 客户端，PECL 扩展 |
| MQ | `rdkafka` | Kafka 客户端，PECL 扩展 |
| 调试 | `xdebug` | 调试、覆盖率 |
| 性能 | `opcache` | PHP 字节码缓存 |
| 图像 | `imagick` | ImageMagick 扩展 |
| 序列化 | `igbinary` | Redis/Memcached 常用序列化 |
| 序列化 | `msgpack` | MessagePack 序列化 |
| 异步 | `event` | 事件循环，PECL 扩展 |
| 异步 | `swoole` | 高性能网络框架，PECL 扩展 |

常见内置扩展检查：

```bash
php -m | sort
php --ri openssl
php --ri sockets
php --ri pdo_mysql
php --ri pcntl
```

常见 PECL 扩展安装：

```bash
pecl install redis
pecl install mongodb
pecl install amqp
pecl install rdkafka
pecl install memcached
pecl install imagick
pecl install xdebug
pecl install igbinary
pecl install msgpack
```

启用 PECL 扩展示例：

```bash
php --ini
echo "extension=redis.so" >> "$(php-config --ini-dir)/redis.ini"
echo "extension=mongodb.so" >> "$(php-config --ini-dir)/mongodb.ini"
echo "extension=amqp.so" >> "$(php-config --ini-dir)/amqp.ini"
echo "extension=rdkafka.so" >> "$(php-config --ini-dir)/rdkafka.ini"
```

验证扩展：

```bash
php -m | grep -E 'redis|mongodb|amqp|rdkafka|sockets|openssl'
php --ri redis
php --ri mongodb
php --ri amqp
php --ri rdkafka
```

不同 PHP 版本的扩展策略：

| PHP 版本 | 建议 |
| --- | --- |
| PHP 5.6 | 只安装旧项目必须扩展；优先使用项目级容器兜底 |
| PHP 7.1 | 只安装旧项目必须扩展；注意 PECL 新版本可能不兼容 |
| PHP 7.4 | 可作为老项目主力版本；扩展需锁定兼容版本 |
| PHP 8.1 | 默认本机 PHP 版本；安装常用扩展 |
| PHP 8.4.x | 新项目验证版本；扩展选择支持 PHP 8.4 的版本 |

PECL 扩展兼容注意：

- `redis`、`mongodb`、`amqp`、`rdkafka`、`xdebug` 在不同 PHP 大版本下可能需要不同扩展版本。
- PHP 5.6/7.1 不一定能安装最新 PECL 扩展，需要指定旧版本。
- 每个 PHP 版本都有自己的扩展目录，切换 PHP 后要重新确认 `php -m`。
- CLI 和 PHP-FPM 可能读取不同 `php.ini`，需要分别检查。

---

### 1.7 Node 多版本

当前机器检测结果：

```text
nvm: 0.40.0
已安装 Node.js:
  v20.20.2
  v24.16.0
  v26.3.0
当前版本: v26.3.0
默认版本: v26.3.0
npm: 11.16.0
node 路径: ~/.nvm/versions/node/v26.3.0/bin/node
```

当前已经安装并使用 `nvm`，因此 Node.js 不再额外安装 `fnm`，避免多个 Node 版本管理器同时修改 `PATH`。

目标版本建议：

- Node.js 20
- Node.js 22
- Node.js 24 LTS
- Node.js 26
- 默认版本：根据项目需要选择，当前机器默认是 Node.js 26.3.0
- 支持 shell 命令直接切换

检测命令：

```bash
command -v node
node -v
npm -v

type nvm
nvm --version
nvm ls
```

如果非交互 shell 中提示 `nvm: command not found`，先加载 nvm：

```bash
export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && . "$NVM_DIR/nvm.sh"
```

安装 Node.js：

```bash
nvm install 20
nvm install 22
nvm install 24
nvm install 26
```

设置默认版本：

```bash
nvm alias default 24
```

如果要保持当前默认版本：

```bash
nvm alias default 26.3.0
```

临时切换：

```bash
nvm use 20
nvm use 24
nvm use 26.3.0
node -v
npm -v
```

项目级固定：

```bash
echo "24" > .nvmrc
nvm use
```

包管理器建议：

```bash
corepack enable
pnpm -v
yarn -v
```

说明：

- 新项目建议优先使用 `pnpm`。
- 项目内应提交 `.nvmrc`、`packageManager` 字段和锁文件，例如 `pnpm-lock.yaml`。
- 如果项目必须使用 Node 20/22/24/26，优先通过 `.nvmrc` 固定。
- 不建议同时启用 `nvm` 和 `fnm`，否则 shell 启动时可能出现 PATH 优先级混乱。

---

### 1.8 Go 多版本

目标版本建议：

- Go 1.22
- Go 1.23
- Go 1.24
- Go 1.25
- 默认版本：当前稳定版本
- 支持 shell 命令直接切换

推荐使用 `asdf` 管理 Go 多版本。

安装 Go 插件：

```bash
asdf plugin add golang https://github.com/asdf-community/asdf-golang.git
```

安装 Go：

```bash
asdf install golang 1.22.12
asdf install golang 1.23.6
asdf install golang 1.24.0
asdf install golang 1.25.0
```

设置默认版本：

```bash
asdf global golang 1.24.0
```

临时切换当前项目：

```bash
asdf local golang 1.24.0
```

验证：

```bash
go version
go env GOPATH
go env GOPROXY
```

国内代理可选：

```bash
go env -w GOPROXY=https://goproxy.cn,direct
go env -w GOSUMDB=sum.golang.google.cn
```

---

### 1.9 TypeScript 多版本

TypeScript 不建议作为系统级全局版本管理。

推荐方式：

- 每个 Node 项目在 `devDependencies` 中固定自己的 TypeScript 版本。
- 使用项目内命令执行 `tsc`。
- 不同项目之间允许 TypeScript 版本不同。

项目内安装：

```bash
pnpm add -D typescript
```

指定版本：

```bash
pnpm add -D typescript@5.4.5
pnpm add -D typescript@5.5.4
```

执行：

```bash
pnpm exec tsc --version
pnpm exec tsc --noEmit
```

不推荐：

```bash
npm install -g typescript
```

原因：

- 全局 TypeScript 容易和项目版本不一致。
- 前端、Node、NestJS、Vue、React、Angular 项目通常需要各自固定 TS 版本。

---

### 1.10 Python 多版本

目标版本建议：

- Python 3.10
- Python 3.11
- Python 3.12
- Python 3.13
- 默认版本：Python 3.12 或当前稳定版本

推荐：

- `pyenv` 管理 Python 多版本。
- `venv` 管理项目虚拟环境。
- `pipx` 安装全局 Python CLI 工具。
- `poetry` 或 `uv` 管理项目依赖。

安装 pyenv 依赖：

```bash
sudo apt install -y \
  make build-essential libssl-dev zlib1g-dev libbz2-dev \
  libreadline-dev libsqlite3-dev wget curl llvm \
  libncursesw5-dev xz-utils tk-dev libxml2-dev libxmlsec1-dev \
  libffi-dev liblzma-dev
```

安装 pyenv：

```bash
curl https://pyenv.run | bash
```

写入 `~/.bashrc`：

```bash
export PYENV_ROOT="$HOME/.pyenv"
command -v pyenv >/dev/null || export PATH="$PYENV_ROOT/bin:$PATH"
eval "$(pyenv init -)"
```

安装 Python：

```bash
pyenv install 3.10.14
pyenv install 3.11.9
pyenv install 3.12.5
pyenv install 3.13.0
```

设置默认版本：

```bash
pyenv global 3.12.5
```

项目级固定：

```bash
pyenv local 3.12.5
python -m venv .venv
source .venv/bin/activate
python -m pip install -U pip setuptools wheel
```

pipx 安装 CLI：

```bash
python3 -m pip install --user pipx
python3 -m pipx ensurepath
pipx install poetry
pipx install uv
```

验证：

```bash
python --version
pip --version
pyenv versions
pipx list
```

说明：

- 不要把项目依赖直接安装到系统 Python。
- 每个 Python 项目使用自己的 `.venv`。
- `.venv/` 应加入项目 `.gitignore`。

---

## 2. Linux 上 Docker 开发环境搭建

### 2.1 Docker 方案

推荐使用：

- Ubuntu 原生 Docker Engine
- Docker Compose plugin

不建议把 Docker Desktop 作为 Linux 主开发方案。

安装 Docker Engine：

```bash
sudo apt update
sudo apt install -y ca-certificates curl gnupg

sudo install -m 0755 -d /etc/apt/keyrings
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | \
  sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg

echo \
  "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu \
  $(. /etc/os-release && echo "$VERSION_CODENAME") stable" | \
  sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

sudo apt update
sudo apt install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
```

允许当前用户直接执行 docker：

```bash
sudo usermod -aG docker $USER
```

重新登录 shell 后验证：

```bash
docker version
docker compose version
docker run --rm hello-world
```

---

### 2.2 Docker 目录规划

Docker 根目录：

```text
/home/xs/workplace/docker
```

后续建议目录：

```text
docker/
  Makefile
  .gitignore
  scripts/

  mysql-local/
    .env.example
    docker-compose.yml
    conf/
    data/
    logs/
    runtime/
    backup/
    scripts/
    README.md

  redis-local/
    .env.example
    docker-compose.yml
    conf/
    data/
    logs/
    runtime/
    backup/
    scripts/
    README.md

  mongo-local/
    .env.example
    docker-compose.yml
    conf/
    data/
    logs/
    runtime/
    backup/
    scripts/
    README.md

  redis-cluster-6/
    .env.example
    docker-compose.yml
    conf/
    data/
    logs/
    runtime/
    backup/
    scripts/
    README.md

  redis-sentinel-6/
    .env.example
    docker-compose.yml
    conf/
    data/
    logs/
    runtime/
    backup/
    scripts/
    README.md

  mysql-8-replication/
    .env.example
    docker-compose.yml
    conf/
    data/
    logs/
    runtime/
    backup/
    scripts/
    README.md

  postgres-local/
    .env.example
    docker-compose.yml
    conf/
    data/
    logs/
    runtime/
    backup/
    scripts/
    README.md

  mongo-replica/
    .env.example
    docker-compose.yml
    conf/
    data/
    logs/
    runtime/
    backup/
    scripts/
    README.md

  kafka-local/
    .env.example
    docker-compose.yml
    conf/
    data/
    logs/
    runtime/
    scripts/
    README.md

  kafka-cluster/
    .env.example
    docker-compose.yml
    conf/
    data/
    logs/
    runtime/
    scripts/
    README.md

  rabbitmq-local/
    .env.example
    docker-compose.yml
    conf/
    data/
    logs/
    runtime/
    scripts/
    README.md

  rabbitmq-cluster/
    .env.example
    docker-compose.yml
    conf/
    data/
    logs/
    runtime/
    scripts/
    README.md

  apisix/
    .env.example
    docker-compose.yml
    conf/
    data/
    logs/
    runtime/
    scripts/
    README.md

  nginx/
    .env.example
    docker-compose.yml
    conf/
    html/
    logs/
    runtime/
    scripts/
    README.md

  minio/
    .env.example
    docker-compose.yml
    conf/
    data/
    logs/
    runtime/
    scripts/
    README.md

  elasticsearch/
    .env.example
    docker-compose.yml
    conf/
    data/
    logs/
    runtime/
    scripts/
    README.md

  prometheus-grafana/
    .env.example
    docker-compose.yml
    conf/
    data/
    logs/
    runtime/
    scripts/
    README.md

  metabase/
    .env.example
    docker-compose.yml
    data/
    logs/
    runtime/
    scripts/
    README.md

  nacos/
    .env.example
    docker-compose.yml
    conf/
    data/
    logs/
    runtime/
    scripts/
    README.md

  consul/
    .env.example
    docker-compose.yml
    conf/
    data/
    logs/
    runtime/
    scripts/
    README.md
```

统一约定：

- 每套环境独立 `docker compose up -d`。
- 每套环境独立 network，避免互相污染。
- network 命名规则为 `dev_<service>_net`，跨服务共享网络为 `dev_shared_net`。
- 每套环境独立 volume，方便保留或清理数据。
- 每套环境提交 `.env.example`，本地复制为 `.env` 使用，`.env` 不提交 git。
- `conf/` 存放配置，必须映射到容器配置目录，宿主机和容器双向可修改。
- `data/` 存放数据，必须映射到容器数据目录，防止容器删除后数据丢失。
- `logs/` 存放日志，必须映射到容器日志目录，方便本地排查。
- `runtime/` 存放运行时生成文件，不提交 git。
- `backup/` 存放备份文件，不提交 git。
- `scripts/` 存放初始化脚本。
- 根目录 `scripts/` 存放全局辅助脚本，例如端口检查、目录检查、批量状态检查。
- `data/`、`logs/`、`runtime/`、`backup/`、`.env` 必须加入 `.gitignore`。
- 所有 compose 文件必须设置 `restart: unless-stopped`，支持 Docker 开机自启动。
- 所有 compose 端口默认绑定 `127.0.0.1`。
- 所有 compose 镜像必须锁定具体版本，不使用 `latest`。
- 所有服务必须有 `healthcheck`。
- 初始化脚本必须可多次执行，重复执行不能破坏已有数据。
- Docker 数据库服务不能占用宿主机默认端口。

端口避让规则：

| 服务 | 本地默认端口保留 | Docker 宿主机端口规划 |
| --- | --- | --- |
| MySQL local | `3306` | `13306` |
| MySQL replication | `3306` | `13310`、`13311`、`13312` |
| Redis local | `6379` | `16379` |
| Redis Cluster | `6379` | `16400` - `16405` |
| Redis Sentinel | `6379`、`26379` | Redis `16410` - `16412`，Sentinel `26410` - `26412` |
| MongoDB local | `27017` | `37017` |
| MongoDB replica | `27017` | `37020`、`37021`、`37022` |
| PostgreSQL local | `5432` | `15432` |
| Kafka local | `9092` | `19092` |
| Kafka local UI | - | `18082` |
| Kafka cluster | `9092` | `19093`、`19094`、`19095` |
| RabbitMQ local | `5672`、`15672` | AMQP `15672`，UI `15673` |
| RabbitMQ cluster | `5672`、`15672` | AMQP `25672`、`35672`、`45672`，UI `25673` |
| APISIX | `9080`、`9443`、`9180` | `19080`、`19443`、`19180` |
| Nginx | `80`、`443` | `18080`、`18443` |
| MinIO | `9000`、`9001` | `19000`、`19001` |
| Elasticsearch | `9200`、`9300` | `19200`、`19300` |
| Grafana | `3000` | `13000` |
| Metabase | `3000` | `13001` |

---

### 2.3 Redis Cluster 6.0 集群

目标：

- Redis 版本：6.0
- 三主三从
- 共 6 个 Redis 节点

规划节点：

```text
redis-node-1:6379
redis-node-2:6380
redis-node-3:6381
redis-node-4:6382
redis-node-5:6383
redis-node-6:6384
```

集群规划：

```text
master-1 -> slave-1
master-2 -> slave-2
master-3 -> slave-3
```

后续 compose 需要包含：

- 6 个 Redis 容器。
- 每个节点启用 `cluster-enabled yes`。
- 每个节点配置独立端口和 cluster bus port。
- 初始化脚本执行 `redis-cli --cluster create`。

常用命令规划：

```bash
docker compose up -d
docker compose ps
docker exec -it redis-node-1 redis-cli -c
redis-cli --cluster check 127.0.0.1:6379
```

---

### 2.4 Redis Sentinel 6.0 集群

目标：

- Redis 版本：6.0
- 一主二从
- 三个 Sentinel 节点

规划节点：

```text
redis-master:6379
redis-slave-1:6380
redis-slave-2:6381
redis-sentinel-1:26379
redis-sentinel-2:26380
redis-sentinel-3:26381
```

后续 compose 需要包含：

- 1 个 Redis master。
- 2 个 Redis replica。
- 3 个 Sentinel。
- Sentinel 监控名称统一为 `mymaster`。
- quorum 建议为 `2`。

常用命令规划：

```bash
docker compose up -d
docker exec -it redis-sentinel-1 redis-cli -p 26379
SENTINEL masters
SENTINEL replicas mymaster
```

---

### 2.5 MySQL 8.0 主从

目标：

- MySQL 版本：8.0
- 一主二从
- 开启 binlog
- 从库复制主库数据

规划节点：

```text
mysql-master:3306
mysql-slave-1:3307
mysql-slave-2:3308
```

后续 compose 需要包含：

- 1 个 master。
- 2 个 slave。
- 独立 `server-id`。
- master 开启 `log-bin`。
- slave 配置 `relay-log`。
- 初始化复制账号。
- 初始化主从同步脚本。

账号规划：

```text
root 用户: root
业务用户: app
复制用户: repl
默认数据库: app_db
```

常用命令规划：

```bash
docker compose up -d
docker exec -it mysql-master mysql -uroot -p
SHOW MASTER STATUS;
SHOW REPLICA STATUS\G
```

---

### 2.6 PostgreSQL local

目标：

- PostgreSQL 开发环境。
- 可作为业务数据库。
- 可作为 Metabase 元数据库。

规划节点：

```text
postgres-local:15432
pgadmin:15050
```

后续 compose 需要包含：

- PostgreSQL 容器。
- pgAdmin 可视化管理工具。
- 初始化数据库和用户。
- 本地 volume 持久化数据。

账号规划：

```text
username: xs
password: xsailxma
default database: app_db
metabase database: metabase
```

常用命令规划：

```bash
docker compose up -d
docker exec -it postgres-local psql -U xs
\l
\du
```

管理页面：

```text
http://127.0.0.1:15050
```

---

### 2.7 MongoDB 副本集

目标：

- MongoDB 开发环境。
- 三节点 replica set。
- 支持事务和高可用场景测试。

规划节点：

```text
mongo-1:27017
mongo-2:27018
mongo-3:27019
```

后续 compose 需要包含：

- 3 个 MongoDB 节点。
- replica set 名称，例如 `rs0`。
- 初始化 replica set 脚本。
- 初始化用户和数据库。

账号规划：

```text
username: admin
password: admin
database: admin
replica set: rs0
```

常用命令规划：

```bash
docker compose up -d
docker exec -it mongo-1 mongosh
rs.status()
```

连接串规划：

```text
mongodb://admin:admin@localhost:27017,localhost:27018,localhost:27019/app_db?replicaSet=rs0&authSource=admin
```

---

### 2.8 Kafka 集群

目标：

- Kafka 集群开发环境
- 支持本地应用连接
- 提供管理 UI

推荐使用 KRaft 模式，避免额外维护 ZooKeeper。

规划节点：

```text
kafka-1:9092
kafka-2:9093
kafka-3:9094
kafka-ui:8080
```

后续 compose 需要包含：

- 3 个 Kafka broker。
- KRaft controller 配置。
- 内外网 listener 区分。
- Kafka UI。
- 默认 topic 初始化脚本。

常用命令规划：

```bash
docker compose up -d
docker compose ps
docker exec -it kafka-1 kafka-topics.sh --bootstrap-server kafka-1:9092 --list
```

---

### 2.9 RabbitMQ 集群

目标：

- RabbitMQ 三节点集群
- 启用 Management UI
- 支持本地开发测试 exchange、queue、routing key

规划节点：

```text
rabbitmq-1:5672,15672
rabbitmq-2:5673,15673
rabbitmq-3:5674,15674
```

后续 compose 需要包含：

- 3 个 RabbitMQ 节点。
- 统一 Erlang cookie。
- Management 插件。
- 默认用户和密码。
- 集群 join 脚本。

账号规划：

```text
username: admin
password: admin
vhost: /
```

常用命令规划：

```bash
docker compose up -d
docker compose ps
docker exec -it rabbitmq-1 rabbitmqctl cluster_status
```

管理页面：

```text
http://localhost:15672
```

---

### 2.10 APISIX 网关

目标：

- APISIX 网关开发环境
- etcd 作为配置中心
- 可选 APISIX Dashboard

规划节点：

```text
apisix:9080,9443,9180
etcd:2379
apisix-dashboard:9000
```

后续 compose 需要包含：

- APISIX。
- etcd。
- APISIX Dashboard。
- Admin API key。
- 示例 upstream、route 配置。

常用命令规划：

```bash
docker compose up -d
docker compose ps
curl http://localhost:9080
```

管理端口规划：

```text
APISIX HTTP: http://localhost:9080
APISIX HTTPS: https://localhost:9443
APISIX Admin API: http://localhost:9180
APISIX Dashboard: http://localhost:9000
```

---

### 2.11 Nginx 服务器

目标：

- 本地反向代理
- 静态资源服务器
- 可代理本机项目和 Docker 服务

规划端口：

```text
nginx:80
nginx ssl:443
```

后续 compose 需要包含：

- Nginx 容器。
- `conf.d/` 配置目录。
- `html/` 静态资源目录。
- `logs/` 日志目录。
- 可选自签名 SSL 证书目录。

常用命令规划：

```bash
docker compose up -d
docker compose logs -f nginx
docker exec -it nginx nginx -t
docker exec -it nginx nginx -s reload
```

---

### 2.12 MinIO 对象存储

目标：

- 本地 S3 兼容对象存储。
- 用于测试文件上传、头像、附件、日志归档、数据湖等场景。

规划节点：

```text
minio:9000
minio-console:9001
```

后续 compose 需要包含：

- MinIO 服务。
- 默认 bucket 初始化脚本。
- access key 和 secret key。
- 本地 volume 持久化数据。

账号规划：

```text
MINIO_ROOT_USER: minioadmin
MINIO_ROOT_PASSWORD: minioadmin
bucket: app-bucket
```

管理页面：

```text
http://localhost:9001
```

常用命令规划：

```bash
docker compose up -d
docker compose ps
```

---

### 2.13 Elasticsearch / Kibana

目标：

- 本地搜索引擎。
- 用于全文检索、日志检索、商品搜索、订单搜索等场景。
- 提供 Kibana 管理页面。

规划节点：

```text
elasticsearch:9200,9300
kibana:5601
```

后续 compose 需要包含：

- Elasticsearch 单节点开发模式。
- Kibana。
- 内存限制。
- 本地 volume 持久化数据。

常用命令规划：

```bash
docker compose up -d
curl http://localhost:9200
```

管理页面：

```text
http://localhost:5601
```

---

### 2.14 Prometheus / Grafana

目标：

- 本地监控和指标展示。
- 用于服务指标、容器指标、应用指标、APISIX 指标验证。

规划节点：

```text
prometheus:9090
grafana:3000
node-exporter:9100
```

后续 compose 需要包含：

- Prometheus。
- Grafana。
- node-exporter。
- Prometheus scrape 配置。
- Grafana dashboard provisioning。

账号规划：

```text
Grafana username: admin
Grafana password: admin
```

管理页面：

```text
Prometheus: http://localhost:9090
Grafana: http://localhost:3000
```

---

### 2.15 Metabase 数据分析

目标：

- 本地 BI 和数据分析工具。
- 连接 MySQL、PostgreSQL、MongoDB、ClickHouse 等数据源。
- 用于快速查看业务数据、做报表、验证 SQL、临时看板。

规划节点：

```text
metabase:3001
metabase-postgres:5433
```

后续 compose 需要包含：

- Metabase 容器。
- PostgreSQL 作为 Metabase 元数据库。
- 独立 volume 保存 Metabase 配置。
- 数据源连接使用 Docker network 或宿主机端口。

账号规划：

```text
Metabase URL: http://localhost:3001
Metabase metadata database: metabase
metadata username: metabase
metadata password: metabase
```

可连接数据源：

```text
MySQL: mysql-master:3306
PostgreSQL: postgres-local:5432
MongoDB: mongo-1:27017
ClickHouse: clickhouse:8123
```

后续 compose 环境变量规划：

```text
MB_DB_TYPE=postgres
MB_DB_DBNAME=metabase
MB_DB_PORT=5432
MB_DB_USER=metabase
MB_DB_PASS=metabase
MB_DB_HOST=metabase-postgres
```

常用命令规划：

```bash
docker compose up -d
docker compose logs -f metabase
```

注意：

- 不建议使用 Metabase 默认 H2 文件数据库作为长期环境。
- 本地开发也建议用 PostgreSQL 存 Metabase 元数据，避免升级或重建后配置丢失。
- 端口 `3001` 用于避开 Grafana 的 `3000`。

---

### 2.16 Nacos 注册配置中心

目标：

- Java 微服务注册中心。
- 配置中心。
- 适配 Spring Cloud Alibaba 项目。

规划节点：

```text
nacos:8848,9848,9849
nacos-mysql:3309
```

后续 compose 需要包含：

- Nacos。
- MySQL 作为 Nacos 数据库。
- 初始化 Nacos 数据库脚本。

管理页面：

```text
http://localhost:8848/nacos
```

账号规划：

```text
username: nacos
password: nacos
```

---

### 2.17 Consul 服务发现

目标：

- 服务发现。
- KV 配置。
- 健康检查。
- 适配 Go、Spring Cloud、微服务网关测试。

规划节点：

```text
consul:8500,8600
```

后续 compose 需要包含：

- Consul server。
- UI。
- DNS 端口。
- 数据 volume。

管理页面：

```text
http://localhost:8500
```

---

### 2.18 其他可选组件

这些不是第一批必须构建，但很多开发环境后面会用到，可以预留目录和端口。

| 组件 | 用途 | 建议端口 |
| --- | --- | --- |
| ClickHouse | OLAP、日志分析、宽表查询 | `8123`、`9000` |
| SonarQube | 代码质量扫描 | `9002` |
| Jenkins | CI/CD 流水线测试 | `8081` |
| GitLab CE | 本地 Git 仓库和 CI 验证 | `8082`、`2222` |
| Vault | 密钥管理、动态凭证 | `8200` |
| MailHog / Mailpit | 本地邮件测试 | `8025`、`1025` |
| Adminer | 轻量数据库管理 | `8088` |
| phpMyAdmin | MySQL 管理 | `8089` |
| RedisInsight | Redis 可视化管理 | `5540` |
| Mongo Express | MongoDB 可视化管理 | `8087` |
| Jaeger | 链路追踪 | `16686` |
| Zipkin | 链路追踪 | `9411` |
| Loki / Promtail | 日志采集和查询 | `3100` |
| Portainer | Docker 可视化管理 | `9444` |

建议：

- 不要一次性全部启动，按项目需要拆分 compose。
- UI 类工具端口容易冲突，统一写入 `.env`。
- 涉及账号密码的组件不要把生产密码写入文档。

---

## 3. 推荐工作流

### 3.1 日常开发

语言运行时在本机切换：

```bash
sdk use java 17.0.12-tem
sdk use maven 3.9.9
sdk use gradle 8.10.2
asdf local php 8.1.29
nvm use 24
asdf local golang 1.24.0
```

基础设施按需启动：

```bash
cd docker/redis-cluster-6
docker compose up -d

cd ../mysql-8-replication
docker compose up -d
```

项目代码在本机运行：

```bash
./mvnw spring-boot:run
pnpm dev
go run ./cmd/server
php artisan serve
```

### 3.2 项目级版本文件

Java：

```text
.sdkmanrc
```

Maven：

```text
mvnw
mvnw.cmd
.mvn/wrapper/
pom.xml
```

Gradle：

```text
gradlew
gradlew.bat
gradle/wrapper/
build.gradle
settings.gradle
```

PHP / Go：

```text
.tool-versions
```

Node：

```text
.node-version
package.json
pnpm-lock.yaml
```

TypeScript：

```text
package.json
tsconfig.json
```

### 3.3 清理容器环境

停止服务：

```bash
docker compose down
```

停止并删除 volume：

```bash
docker compose down -v
```

查看资源：

```bash
docker ps
docker volume ls
docker network ls
docker system df
```

---

## 4. 后续待构建清单

当前文档只完成规划。后续需要逐个补齐：

- `plan.md` 实施计划。
- `/home/xs/workplace/docker/Makefile` Docker 统一启动入口。
- `/home/xs/workplace/docker/scripts/` Docker 全局辅助脚本目录。
- `/home/xs/workplace/docker/.gitignore`，忽略所有 `data/`、`logs/`、`runtime/`、`backup/`、`.env`。
- Docker Engine 安装脚本。
- Java SDKMAN 初始化脚本。
- Maven SDKMAN 初始化脚本。
- Gradle SDKMAN 初始化脚本。
- PHP asdf 初始化脚本。
- PHP 常用扩展安装脚本。
- Node nvm 检测和初始化脚本。
- Go asdf 初始化脚本。
- Python pyenv 初始化脚本。
- MySQL local compose。
- Redis local compose。
- MongoDB local compose。
- Redis Cluster 6.0 compose。
- Redis Sentinel 6.0 compose。
- MySQL 8.0 一主二从 compose。
- Kafka local compose。
- Kafka cluster compose。
- RabbitMQ local compose。
- RabbitMQ cluster compose。
- APISIX compose。
- Nginx compose。
- PostgreSQL local compose。
- MongoDB replica set compose。
- MinIO compose。
- Elasticsearch / Kibana compose。
- Prometheus / Grafana compose。
- Metabase compose。
- Nacos compose。
- Consul compose。
- 可选组件 compose：ClickHouse、SonarQube、Jenkins、Vault、MailHog、Adminer、RedisInsight 等。
- 每个服务的 `.env.example`、`conf/`、`data/`、`logs/`、`runtime/`、`backup/`、`scripts/`、`README.md`。
