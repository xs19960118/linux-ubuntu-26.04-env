#!/usr/bin/env bash
set -euo pipefail

if [ "${CONFIRM:-}" != "YES" ]; then
  echo "Refusing to restore without CONFIRM=YES."
  exit 1
fi

if [ $# -ne 1 ]; then
  echo "Usage: CONFIRM=YES $0 <minio-backup.tar.gz>"
  exit 1
fi

BACKUP_FILE="$1"

if [ ! -f "$BACKUP_FILE" ]; then
  echo "Backup file not found: $BACKUP_FILE"
  exit 1
fi

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SERVICE_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"

docker compose -f "$SERVICE_DIR/docker-compose.yml" --env-file "$SERVICE_DIR/.env" down
rm -rf "$SERVICE_DIR/data"
tar -C "$SERVICE_DIR" -xzf "$BACKUP_FILE"
docker compose -f "$SERVICE_DIR/docker-compose.yml" --env-file "$SERVICE_DIR/.env" up -d

echo "Restore completed from: $BACKUP_FILE"
