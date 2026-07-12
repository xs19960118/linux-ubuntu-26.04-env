#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

services=(
  mysql-local
  redis-local
  mongo-local
  mysql-8-replication
  redis-cluster-6
  redis-sentinel-6
  mongo-replica
  postgres-local
  kafka-local
  kafka-cluster
  rabbitmq-local
  rabbitmq-cluster
  apisix
  nginx
  minio
  elasticsearch
  prometheus-grafana
  metabase
  nacos
  consul
)

required_files=(
  .env.example
  docker-compose.yml
  README.md
)

required_dirs=(
  conf
  data
  logs
  runtime
  backup
  scripts
)

failures=0

for service in "${services[@]}"; do
  service_dir="$ROOT_DIR/$service"

  if [[ ! -d "$service_dir" ]]; then
    echo "missing service directory: $service"
    failures=$((failures + 1))
    continue
  fi

  for file in "${required_files[@]}"; do
    if [[ ! -f "$service_dir/$file" ]]; then
      echo "missing file: $service/$file"
      failures=$((failures + 1))
    fi
  done

  for dir in "${required_dirs[@]}"; do
    if [[ ! -d "$service_dir/$dir" ]]; then
      echo "missing directory: $service/$dir"
      failures=$((failures + 1))
    fi
  done

  if [[ "$service" == "nginx" && ! -d "$service_dir/html" ]]; then
    echo "missing directory: $service/html"
    failures=$((failures + 1))
  fi
done

if [[ ! -f "$ROOT_DIR/Makefile" ]]; then
  echo "missing file: Makefile"
  failures=$((failures + 1))
fi

if [[ ! -f "$ROOT_DIR/.gitignore" ]]; then
  echo "missing file: .gitignore"
  failures=$((failures + 1))
else
  for pattern in "**/data/" "**/logs/" "**/runtime/" "**/backup/" "**/.env"; do
    if ! grep -Fxq "$pattern" "$ROOT_DIR/.gitignore"; then
      echo "missing .gitignore pattern: $pattern"
      failures=$((failures + 1))
    fi
  done
fi

if ((failures > 0)); then
  echo "structure check failed: $failures issue(s)"
  exit 1
fi

echo "structure check ok: ${#services[@]} service(s)"
