#!/usr/bin/env bash
set -euo pipefail

if [ "${CONFIRM:-}" != "YES" ]; then
  echo "Refusing to restore without CONFIRM=YES."
  exit 1
fi

if [ $# -ne 1 ]; then
  echo "Usage: CONFIRM=YES $0 <backup.dump>"
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

docker exec -i "$POSTGRES_CONTAINER_NAME" psql -U "$POSTGRES_USER" -d postgres < "$BACKUP_FILE"

echo "Restore completed from: $BACKUP_FILE"
