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
BACKUP_FILE="$SERVICE_DIR/backup/mysql-8-replication-master-$(date +%Y%m%d-%H%M%S).sql.gz"

docker exec dev-mysql-master \
  mysqldump -uroot -p"$MYSQL_ROOT_PASSWORD" \
  --all-databases \
  --single-transaction \
  --routines \
  --triggers \
  --events \
  --source-data=2 | gzip > "$BACKUP_FILE"

echo "Backup created: $BACKUP_FILE"
