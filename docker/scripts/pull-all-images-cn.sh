#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

images="$(
  for compose in "$ROOT_DIR"/*/docker-compose.yml; do
    [ -f "$compose" ] || continue
    (cd "$(dirname "$compose")" && docker compose config --images)
  done | sort -u
)"

mirror_candidates() {
  local image="$1"
  case "$image" in
    docker.elastic.co/*|quay.io/*)
      printf '%s\n' "$image"
      ;;
    */*)
      printf '%s/%s\n' \
        "docker.m.daocloud.io" \
        "$image"
      printf '%s/%s\n' \
        "docker.1panel.live" \
        "$image"
      printf '%s/%s\n' \
        "dockerproxy.cn" \
        "$image"
      printf '%s/%s\n' \
        "dockerpull.com" \
        "$image"
      printf '%s/%s\n' \
        "hub.rat.dev" \
        "$image"
      printf '%s\n' "$image"
      ;;
    *)
      printf '%s/library/%s\n' \
        "docker.m.daocloud.io" \
        "$image"
      printf '%s/library/%s\n' \
        "docker.1panel.live" \
        "$image"
      printf '%s/library/%s\n' \
        "dockerproxy.cn" \
        "$image"
      printf '%s/library/%s\n' \
        "dockerpull.com" \
        "$image"
      printf '%s/library/%s\n' \
        "hub.rat.dev" \
        "$image"
      printf '%s\n' "$image"
      ;;
  esac
}

failed=0
while IFS= read -r image; do
  [ -n "$image" ] || continue
  if docker image inspect "$image" >/dev/null 2>&1; then
    echo "已存在: $image"
    continue
  fi

  echo "拉取: $image"
  pulled=""
  while IFS= read -r candidate; do
    [ -n "$candidate" ] || continue
    echo "  尝试: $candidate"
    if timeout 240 docker pull "$candidate"; then
      pulled="$candidate"
      break
    fi
  done < <(mirror_candidates "$image")

  if [ -z "$pulled" ]; then
    echo "失败: $image" >&2
    failed=1
    continue
  fi

  if [ "$pulled" != "$image" ]; then
    docker tag "$pulled" "$image"
  fi
  echo "完成: $image"
done <<< "$images"

exit "$failed"
