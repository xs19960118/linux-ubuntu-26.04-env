# 开发环境搭建状态

更新时间：2026-07-12

## 已完成

- Docker 已安装：`Docker version 29.6.1`
- Docker Compose 已安装：`Docker Compose version v5.1.4`
- Docker daemon 正在运行，当前用户 `xs` 已在 `docker` 组，可直接执行 `docker` 命令。
- `/home/xs/workplace/docker` 下 20 个服务目录已存在。
- 20 个服务目录均已从 `.env.example` 生成本地 `.env`。
- 20 个 `docker-compose.yml` 均通过 `docker compose config` 静态校验。
- 每个服务目录均包含 `conf/`、`data/`、`logs/`、`runtime/`、`backup/`、`scripts/`。
- `docker/.gitignore` 已忽略 `data/`、`logs/`、`runtime/`、`backup/`、`.env`。
- `docker/scripts/check-structure.sh` 已从占位脚本补成实际结构检查，并通过：`structure check ok: 20 service(s)`。
- `docker/scripts/check-ports.sh` 已从占位脚本补成实际端口检查，并通过：`port check ok`。
- 已修复 Docker 端口冲突：`kafka-local` 的 Kafka UI 从 `18080` 调整为 `18082`，保留 `nginx` 使用 `18080/18443`。
- `~/.bashrc` 已加入 SDKMAN、asdf、nvm、Go、Composer、pnpm、`~/.local/bin` 初始化。
- SDKMAN CLI 已安装到 `~/.sdkman`，版本标记为 `5.23.0`。
- Node.js 已通过 nvm 安装：`20.20.2`、`24.16.0`、`26.3.0`，默认 `26.3.0`。
- pnpm 已通过当前 nvm Node.js 安装：`11.12.0`。
- Python 已安装：`Python 3.14.4`，`venv` 可用。

## 当前受限

- 当前会话不能输入 sudo 密码，无法执行系统包安装。
- Docker Hub 访问不稳定，`make up SERVICE=mysql-local` 拉取 `mysql:8.0.40` 失败：`registry-1.docker.io` 请求超时。
- GitHub / GitHub release 下载链路不稳定：
  - SDKMAN 下载 `java 17.0.19-tem` 速度过慢，约 2% 时已中断。
  - `git ls-remote https://github.com/asdf-vm/asdf.git` 失败：`GnuTLS recv error (-110)`。
- 本地没有 Docker 镜像，实际启动服务前需要先解决镜像拉取网络或配置可用镜像源。
- Java / Maven / Gradle 尚未通过 SDKMAN 安装完成。
- asdf 尚未安装，因此 PHP / Go 多版本尚未安装。
- 系统 Python 未安装 `pip` / `pipx`。
- `yq`、`sqlite3`、`autoconf`、`bison`、`re2c` 等系统包仍未安装。

## 需要你在终端执行的 sudo 命令

```bash
sudo systemctl enable docker containerd
```

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
make config SERVICE=mysql-local
make up SERVICE=mysql-local
make ps SERVICE=mysql-local
```

## SDKMAN 后续安装命令

网络稳定后执行：

```bash
source ~/.bashrc
sdk install java 8.0.492-tem
sdk install java 17.0.19-tem
sdk install java 21.0.11-tem
sdk install java 25.0.3-tem
sdk default java 17.0.19-tem
sdk install maven 3.9.12
sdk install gradle 8.14.3
```

## asdf 后续安装命令

网络稳定后执行：

```bash
git clone https://github.com/asdf-vm/asdf.git ~/.asdf --branch v0.14.1
source ~/.bashrc
asdf plugin add php https://github.com/asdf-community/asdf-php.git
asdf plugin add golang https://github.com/asdf-community/asdf-golang.git
asdf install golang 1.22.12
asdf install golang 1.23.6
asdf install golang 1.24.0
asdf install golang 1.25.0
asdf global golang 1.24.0
```
