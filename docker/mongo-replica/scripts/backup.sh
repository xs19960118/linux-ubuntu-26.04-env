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
ARCHIVE_FILE="$SERVICE_DIR/backup/mongo-replica-$(date +%Y%m%d-%H%M%S).archive.gz"
TMP_ARCHIVE="/tmp/mongo-replica.archive.gz"

docker exec dev-mongo-replica-1 mongodump --archive="$TMP_ARCHIVE" --gzip
docker cp "dev-mongo-replica-1:$TMP_ARCHIVE" "$ARCHIVE_FILE"
docker exec dev-mongo-replica-1 rm -f "$TMP_ARCHIVE"

echo "Backup created: $ARCHIVE_FILE"
