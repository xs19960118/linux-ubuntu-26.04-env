#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SERVICE_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"

if [ ! -f "$SERVICE_DIR/.env" ]; then
  echo "Missing .env. Run: cp .env.example .env"
  exit 1
fi

set -a
source "$SERVICE_DIR/.env"
set +a

containers=(
  dev-redis-sentinel-master
  dev-redis-sentinel-slave-1
  dev-redis-sentinel-slave-2
)

for container in "${containers[@]}"; do
  docker exec "$container" redis-cli -a "$REDIS_PASSWORD" BGSAVE >/dev/null
done

sleep 3
mkdir -p "$SERVICE_DIR/backup"
BACKUP_FILE="$SERVICE_DIR/backup/redis-sentinel-6-$(date +%Y%m%d-%H%M%S).tar.gz"
TMP_DIR="$(mktemp -d)"
trap 'rm -rf "$TMP_DIR"' EXIT

nodes=(
  master
  slave-1
  slave-2
)

for index in "${!containers[@]}"; do
  docker cp "${containers[$index]}:/data" "$TMP_DIR/${nodes[$index]}"
done

tar -C "$TMP_DIR" -czf "$BACKUP_FILE" .

echo "Backup created: $BACKUP_FILE"
