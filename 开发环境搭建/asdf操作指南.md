# asdf 操作指南

当前安装版本：

```bash
asdf version
# 0.20.0
```

安装位置：

```text
/home/xs/.local/bin/asdf
```

数据目录：

```text
/home/xs/.asdf
```

Shell 配置：

```text
/home/xs/.bashrc
```

## 当前状态

asdf 已安装并加入 `~/.bashrc`：

```bash
export ASDF_DATA_DIR="${ASDF_DATA_DIR:-$HOME/.asdf}"
export PATH="$HOME/.local/bin:$ASDF_DATA_DIR/shims:$PATH"
if command -v asdf >/dev/null 2>&1; then
  . <(asdf completion bash)
fi
```

当前没有安装 asdf 插件。你现有的 Java / PHP / Node / Go 主环境已经用 apt、Sury、nvm、系统 Go 搭好了，所以 asdf 只建议给“项目特殊版本”使用。

## 最常用命令

查看 asdf 信息：

```bash
asdf version
asdf info
```

查看已安装插件：

```bash
asdf plugin list
asdf plugin list --urls
```

查看插件市场：

```bash
asdf plugin list all
```

添加插件：

```bash
asdf plugin add nodejs
asdf plugin add golang
asdf plugin add python
```

如果短名安装失败，可以直接指定插件 Git 地址，例如：

```bash
asdf plugin add nodejs https://github.com/asdf-vm/asdf-nodejs.git
asdf plugin add golang https://github.com/asdf-community/asdf-golang.git
asdf plugin add python https://github.com/asdf-community/asdf-python.git
```

查看某个工具可安装版本：

```bash
asdf list all nodejs
asdf list all python
asdf list all golang
```

安装版本：

```bash
asdf install nodejs 26.3.0
asdf install python 3.14.4
asdf install golang 1.26.0
```

设置当前目录项目版本：

```bash
asdf set nodejs 26.3.0
asdf set python 3.14.4
```

设置上级目录版本：

```bash
asdf set -p nodejs 26.3.0
```

设置用户级默认版本：

```bash
asdf set -u nodejs 26.3.0
```

安装当前项目 `.tool-versions` 里声明的所有版本：

```bash
asdf install
```

查看当前生效版本：

```bash
asdf current
asdf current nodejs
```

查看命令由哪个 asdf 版本提供：

```bash
asdf which node
asdf shimversions node
```

重建 shim：

```bash
asdf reshim nodejs
```

## 项目用法

进入项目目录：

```bash
cd /path/to/project
```

添加 `.tool-versions`：

```bash
asdf set nodejs 26.3.0
asdf set python 3.14.4
cat .tool-versions
```

别人拉项目后只需要：

```bash
asdf install
```

## 和当前环境的关系

你现在已经有这些主链路：

- Java：apt 安装，多版本用 `java-switch`
- PHP：Sury apt 安装，多版本用 `php-switch`
- Node：nvm 安装，多版本用 `node-switch`
- Go：apt 安装

所以不要为了“统一”强行把已经跑通的 Java / PHP 全迁到 asdf。比较稳的用法是：

- 老项目有特殊 Node/Python/Go 版本要求时，用 asdf。
- 当前宿主机 Java/PHP 多版本继续用现有 `java-switch`、`php-switch`。
- 项目里如果出现 `.tool-versions`，再用 asdf 安装对应版本。

## 网络慢时

asdf 插件大多从 GitHub 下载。GitHub 慢时，优先重试：

```bash
asdf plugin add nodejs
```

Go 安装 asdf 本体时可用国内 Go proxy：

```bash
GOBIN="$HOME/.local/bin" GOPROXY=https://goproxy.cn,direct \
  go install github.com/asdf-vm/asdf/cmd/asdf@v0.20.0
```

## 升级 asdf

当前 asdf 是 Go 二进制安装，升级时运行新版官方命令即可：

```bash
GOBIN="$HOME/.local/bin" GOPROXY=https://goproxy.cn,direct \
  go install github.com/asdf-vm/asdf/cmd/asdf@v0.20.0
```

以后官方出新版本，把 `v0.20.0` 改成新版本号。
