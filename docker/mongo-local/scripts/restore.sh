#!/usr/bin/env bash
set -euo pipefail

if [ "${CONFIRM:-}" != "YES" ]; then
  echo "Refusing to restore without CONFIRM=YES."
  exit 1
fi

if [ $# -ne 1 ]; then
  echo "Usage: CONFIRM=YES $0 <backup.archive.gz>"
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

TMP_ARCHIVE="/tmp/restore.archive.gz"
docker cp "$BACKUP_FILE" "$MONGO_CONTAINER_NAME:$TMP_ARCHIVE"
docker exec "$MONGO_CONTAINER_NAME" mongorestore \
  --username "$MONGO_INITDB_ROOT_USERNAME" \
  --password "$MONGO_INITDB_ROOT_PASSWORD" \
  --authenticationDatabase admin \
  --archive="$TMP_ARCHIVE" \
  --gzip \
  --drop
docker exec "$MONGO_CONTAINER_NAME" rm -f "$TMP_ARCHIVE"

echo "Restore completed from: $BACKUP_FILE"
