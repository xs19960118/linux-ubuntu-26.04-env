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

TMP_ARCHIVE="/tmp/mongo-replica-restore.archive.gz"

docker cp "$BACKUP_FILE" "dev-mongo-replica-1:$TMP_ARCHIVE"
docker exec dev-mongo-replica-1 mongorestore --archive="$TMP_ARCHIVE" --gzip --drop
docker exec dev-mongo-replica-1 rm -f "$TMP_ARCHIVE"

echo "Restore completed from: $BACKUP_FILE"
