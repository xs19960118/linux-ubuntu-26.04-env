#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SERVICE_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"

if [ ! -f "$SERVICE_DIR/.env" ]; then
  echo "Missing .env. Run: cp .env.example .env"
  exit 1
fi

mkdir -p "$SERVICE_DIR/backup"
BACKUP_FILE="$SERVICE_DIR/backup/minio-$(date +%Y%m%d-%H%M%S).tar.gz"

tar -C "$SERVICE_DIR" -czf "$BACKUP_FILE" data

echo "Backup created: $BACKUP_FILE"
