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

mkdir -p "$SERVICE_DIR/backup"
BACKUP_DIR="/tmp/mongo-local-$(date +%Y%m%d-%H%M%S)"
ARCHIVE_FILE="$SERVICE_DIR/backup/mongo-local-$(date +%Y%m%d-%H%M%S).archive.gz"

docker exec "$MONGO_CONTAINER_NAME" mongodump \
  --username "$MONGO_INITDB_ROOT_USERNAME" \
  --password "$MONGO_INITDB_ROOT_PASSWORD" \
  --authenticationDatabase admin \
  --archive="$BACKUP_DIR.archive.gz" \
  --gzip

docker cp "$MONGO_CONTAINER_NAME:$BACKUP_DIR.archive.gz" "$ARCHIVE_FILE"
docker exec "$MONGO_CONTAINER_NAME" rm -f "$BACKUP_DIR.archive.gz"

echo "Backup created: $ARCHIVE_FILE"
