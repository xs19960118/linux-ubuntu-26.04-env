#!/usr/bin/env bash
set -Eeuo pipefail

DOCKER_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
NEW_ROOT="$(dirname "$DOCKER_ROOT")"
OLD_ROOT="/home/xs/workplace"
START_ALL=0
ASSUME_YES=0
DRY_RUN=0

usage() {
  cat <<'EOF'
用法：
  ./docker/scripts/migrate-workplace-binds.sh [选项]

把仍绑定 /home/xs/workplace 的 Docker Compose 容器重建到当前仓库。
默认只重新启动迁移前处于 running、restarting 或 paused 状态的项目，
但会删除所有引用旧目录的容器残留和旧目录本身。

选项：
  --all              从当前仓库启动所有 Compose 项目
  --old-root PATH    指定旧根目录（默认：/home/xs/workplace）
  --yes, -y          跳过删除确认
  --dry-run          只显示迁移计划，不执行修改
  --help, -h         显示帮助

示例：
  ./docker/scripts/migrate-workplace-binds.sh --dry-run
  ./docker/scripts/migrate-workplace-binds.sh
  ./docker/scripts/migrate-workplace-binds.sh --all
EOF
}

log() {
  printf '\n==> %s\n' "$*"
}

warn() {
  printf '警告：%s\n' "$*" >&2
}

die() {
  printf '错误：%s\n' "$*" >&2
  exit 1
}

join_by_space() {
  local item
  for item in "$@"; do
    printf '%s ' "$item"
  done
  printf '\n'
}

while (($# > 0)); do
  case "$1" in
    --all)
      START_ALL=1
      ;;
    --old-root)
      (($# >= 2)) || die "--old-root 缺少路径参数"
      OLD_ROOT="$2"
      shift
      ;;
    --yes|-y)
      ASSUME_YES=1
      ;;
    --dry-run)
      DRY_RUN=1
      ;;
    --help|-h)
      usage
      exit 0
      ;;
    *)
      die "未知参数：$1"
      ;;
  esac
  shift
done

command -v realpath >/dev/null 2>&1 || die "未找到 realpath 命令"
OLD_ROOT="$(realpath -m -- "${OLD_ROOT%/}")"
[[ -n "$OLD_ROOT" && "$OLD_ROOT" == /* ]] || die "旧根目录必须是绝对路径"
[[ "$OLD_ROOT" != "/" ]] || die "拒绝把根目录作为旧目录"
[[ "$OLD_ROOT" != "$NEW_ROOT" ]] || die "旧目录和当前仓库不能相同：$NEW_ROOT"
[[ "$NEW_ROOT" != "$OLD_ROOT/"* ]] || die "旧目录不能包含当前仓库：$OLD_ROOT"
[[ -d "$DOCKER_ROOT" ]] || die "Compose 根目录不存在：$DOCKER_ROOT"
command -v docker >/dev/null 2>&1 || die "未找到 docker 命令"

DOCKER=(docker)
if ! docker info >/dev/null 2>&1; then
  command -v sudo >/dev/null 2>&1 || die "当前用户无 Docker 权限，且未找到 sudo"
  sudo docker info >/dev/null
  DOCKER=(sudo docker)
fi
"${DOCKER[@]}" compose version >/dev/null 2>&1 || die "Docker Compose 插件不可用"

shopt -s nullglob
compose_files=("$DOCKER_ROOT"/*/docker-compose.yml)
((${#compose_files[@]} > 0)) || die "没有找到 Compose 项目：$DOCKER_ROOT/*/docker-compose.yml"

declare -a all_services=()
declare -A known_services=()
for compose_file in "${compose_files[@]}"; do
  service="$(basename "$(dirname "$compose_file")")"
  all_services+=("$service")
  known_services["$service"]=1
done

declare -a old_container_ids=()
declare -A old_workdirs=()
declare -A old_services=()
declare -A active_services=()

mapfile -t container_ids < <("${DOCKER[@]}" ps -aq)
for id in "${container_ids[@]}"; do
  [[ -n "$id" ]] || continue
  meta="$("${DOCKER[@]}" inspect --format '{{.Name}}|{{.State.Status}}|{{index .Config.Labels "com.docker.compose.project.working_dir"}}' "$id")"
  IFS='|' read -r container_name state workdir <<<"$meta"
  container_name="${container_name#/}"
  references_old=0

  if [[ "$workdir" == "$OLD_ROOT" || "$workdir" == "$OLD_ROOT/"* ]]; then
    references_old=1
  else
    while IFS= read -r source; do
      if [[ "$source" == "$OLD_ROOT" || "$source" == "$OLD_ROOT/"* ]]; then
        references_old=1
        break
      fi
    done < <("${DOCKER[@]}" inspect --format '{{range .Mounts}}{{println .Source}}{{end}}' "$id")
  fi

  ((references_old == 1)) || continue
  old_container_ids+=("$id")

  if [[ "$workdir" == "$OLD_ROOT" || "$workdir" == "$OLD_ROOT/"* ]]; then
    old_workdirs["$workdir"]=1
    service="$(basename "$workdir")"
    old_services["$service"]=1
    case "$state" in
      running|restarting|paused)
        active_services["$service"]=1
        ;;
    esac
  else
    warn "非 Compose 容器 $container_name 的挂载引用旧目录；迁移时也会删除该容器"
  fi
done

declare -A target_services=()
if ((START_ALL == 1)); then
  for service in "${all_services[@]}"; do
    target_services["$service"]=1
  done
else
  for service in "${!active_services[@]}"; do
    target_services["$service"]=1
  done
fi

mapfile -t sorted_old_services < <(printf '%s\n' "${!old_services[@]}" | sed '/^$/d' | sort)
mapfile -t sorted_targets < <(printf '%s\n' "${!target_services[@]}" | sed '/^$/d' | sort)
mapfile -t sorted_workdirs < <(printf '%s\n' "${!old_workdirs[@]}" | sed '/^$/d' | sort)

log "预检当前仓库中的待启动项目"
for service in "${sorted_targets[@]}"; do
  [[ -n "${known_services[$service]:-}" ]] || die "旧项目在当前仓库中没有对应目录：$service"
  (
    cd "$DOCKER_ROOT/$service"
    "${DOCKER[@]}" compose config --quiet
  ) || die "Compose 配置校验失败：$service"
  printf '  OK  %s\n' "$service"
done

printf '\n迁移计划：\n'
printf '  旧目录：%s\n' "$OLD_ROOT"
printf '  新目录：%s\n' "$NEW_ROOT"
printf '  旧容器：%d 个\n' "${#old_container_ids[@]}"
printf '  旧项目：'
if ((${#sorted_old_services[@]} > 0)); then
  join_by_space "${sorted_old_services[@]}"
else
  printf '无\n'
fi
printf '  启动项目：'
if ((${#sorted_targets[@]} > 0)); then
  join_by_space "${sorted_targets[@]}"
else
  printf '无（只清理已停止的旧容器）\n'
fi
printf '  永久删除：%s\n' "$OLD_ROOT"

if ((DRY_RUN == 1)); then
  log "dry-run 完成，未修改容器或文件"
  exit 0
fi

if ((ASSUME_YES == 0)); then
  printf '\n旧目录中的数据不会复制，并将被永久删除。输入 DELETE 继续：'
  read -r answer
  [[ "$answer" == "DELETE" ]] || die "用户取消迁移"
fi

log "停止并移除旧 Compose 项目"
for workdir in "${sorted_workdirs[@]}"; do
  if [[ -f "$workdir/docker-compose.yml" ]]; then
    printf '  DOWN  %s\n' "$workdir"
    if ! (
      cd "$workdir"
      "${DOCKER[@]}" compose down --remove-orphans
    ); then
      warn "Compose down 失败，将按容器 ID 强制清理：$workdir"
    fi
  else
    warn "旧 Compose 文件不存在，将按容器 ID 清理：$workdir"
  fi
done

remaining_ids=()
for id in "${old_container_ids[@]}"; do
  if "${DOCKER[@]}" inspect "$id" >/dev/null 2>&1; then
    remaining_ids+=("$id")
  fi
done
if ((${#remaining_ids[@]} > 0)); then
  printf '  RM    %d 个残留容器\n' "${#remaining_ids[@]}"
  "${DOCKER[@]}" rm -f "${remaining_ids[@]}" >/dev/null
fi

log "删除旧目录"
if [[ -e "$OLD_ROOT" || -L "$OLD_ROOT" ]]; then
  if ((EUID == 0)); then
    rm -rf --one-file-system -- "$OLD_ROOT"
  elif command -v sudo >/dev/null 2>&1 && sudo -n true 2>/dev/null; then
    sudo -n rm -rf --one-file-system -- "$OLD_ROOT"
  else
    helper_image="$(
      cd "$DOCKER_ROOT/nginx"
      "${DOCKER[@]}" compose config --images | head -n 1
    )"
    [[ -n "$helper_image" ]] || die "无法确定用于删除旧目录的辅助镜像"
    old_parent="$(dirname "$OLD_ROOT")"
    old_name="$(basename "$OLD_ROOT")"
    # The positional parameter is expanded by the helper container's shell.
    # shellcheck disable=SC2016
    "${DOCKER[@]}" run --rm --entrypoint sh \
      -v "$old_parent:/migration-parent" \
      "$helper_image" -c 'rm -rf "/migration-parent/$1"' sh "$old_name"
  fi
  printf '  已删除 %s\n' "$OLD_ROOT"
else
  printf '  旧目录本来就不存在：%s\n' "$OLD_ROOT"
fi

start_failed=0
log "从当前仓库启动项目"
for service in "${sorted_targets[@]}"; do
  printf '  UP    %s\n' "$service"
  if ! (
    cd "$DOCKER_ROOT/$service"
    "${DOCKER[@]}" compose up -d --remove-orphans
  ); then
    warn "启动失败：$service"
    start_failed=1
  fi
done

log "验证容器不再引用旧目录"
stale=0
mapfile -t container_ids < <("${DOCKER[@]}" ps -aq)
for id in "${container_ids[@]}"; do
  [[ -n "$id" ]] || continue
  meta="$("${DOCKER[@]}" inspect --format '{{.Name}}|{{index .Config.Labels "com.docker.compose.project.working_dir"}}' "$id")"
  IFS='|' read -r container_name workdir <<<"$meta"
  container_name="${container_name#/}"

  if [[ "$workdir" == "$OLD_ROOT" || "$workdir" == "$OLD_ROOT/"* ]]; then
    warn "$container_name 的 Compose 工作目录仍指向 $workdir"
    stale=1
  fi
  while IFS= read -r source; do
    if [[ "$source" == "$OLD_ROOT" || "$source" == "$OLD_ROOT/"* ]]; then
      warn "$container_name 仍挂载 $source"
      stale=1
    fi
  done < <("${DOCKER[@]}" inspect --format '{{range .Mounts}}{{println .Source}}{{end}}' "$id")
done

if [[ -e "$OLD_ROOT" || -L "$OLD_ROOT" ]]; then
  warn "旧目录仍然存在：$OLD_ROOT"
  stale=1
else
  printf '  OK  旧目录已删除\n'
fi
if ((stale == 0)); then
  printf '  OK  没有容器引用旧目录\n'
fi

printf '\n当前 Compose 容器：\n'
"${DOCKER[@]}" ps --filter label=com.docker.compose.project \
  --format 'table {{.Names}}\t{{.Status}}\t{{.Mounts}}'

if ((start_failed != 0 || stale != 0)); then
  die "迁移完成，但存在启动失败或旧路径残留，请查看上面的警告"
fi

log "迁移完成：容器已改为从 $DOCKER_ROOT 创建"
