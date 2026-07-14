#!/usr/bin/env bash
set -euo pipefail

if [ "${CONFIRM:-}" != "YES" ]; then
  echo "Refusing to restore without CONFIRM=YES."
  exit 1
fi

if [ $# -ne 1 ]; then
  echo "Usage: CONFIRM=YES $0 <redis-sentinel-backup.tar.gz>"
  exit 1
fi

BACKUP_FILE="$1"

if [ ! -f "$BACKUP_FILE" ]; then
  echo "Backup file not found: $BACKUP_FILE"
  exit 1
fi

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SERVICE_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
TMP_DIR="$(mktemp -d)"
trap 'rm -rf "$TMP_DIR"' EXIT

containers=(
  dev-redis-sentinel-master
  dev-redis-sentinel-slave-1
  dev-redis-sentinel-slave-2
)

nodes=(
  master
  slave-1
  slave-2
)

tar -C "$TMP_DIR" -xzf "$BACKUP_FILE"
docker compose -f "$SERVICE_DIR/docker-compose.yml" --env-file "$SERVICE_DIR/.env" up -d
docker compose -f "$SERVICE_DIR/docker-compose.yml" --env-file "$SERVICE_DIR/.env" stop

for index in "${!containers[@]}"; do
  docker cp "$TMP_DIR/${nodes[$index]}/." "${containers[$index]}:/data"
done

docker compose -f "$SERVICE_DIR/docker-compose.yml" --env-file "$SERVICE_DIR/.env" start

echo "Restore completed from: $BACKUP_FILE"
