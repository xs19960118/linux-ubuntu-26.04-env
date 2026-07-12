#!/usr/bin/env bash
set -euo pipefail

if [ "${CONFIRM:-}" != "YES" ]; then
  echo "Refusing to restore without CONFIRM=YES."
  exit 1
fi

if [ $# -ne 1 ]; then
  echo "Usage: CONFIRM=YES $0 <backup.sql.gz|backup.sql>"
  exit 1
fi

BACKUP_FILE="$1"

if [ ! -f "$BACKUP_FILE" ]; then
  echo "Backup file not found: $BACKUP_FILE"
  exit 1
fi

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SERVICE_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"

if [ ! -f "$SERVICE_DIR/.env" ]; then
  echo "Missing .env. Run: cp .env.example .env"
  exit 1
fi

set -a
source "$SERVICE_DIR/.env"
set +a

case "$BACKUP_FILE" in
  *.gz)
    gzip -dc "$BACKUP_FILE" | docker exec -i "$MYSQL_CONTAINER_NAME" mysql -uroot -p"$MYSQL_ROOT_PASSWORD"
    ;;
  *)
    docker exec -i "$MYSQL_CONTAINER_NAME" mysql -uroot -p"$MYSQL_ROOT_PASSWORD" < "$BACKUP_FILE"
    ;;
esac

echo "Restore completed from: $BACKUP_FILE"
