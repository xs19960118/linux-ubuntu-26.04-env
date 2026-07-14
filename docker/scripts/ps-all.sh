#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

services=(
  apisix
  consul
  elasticsearch
  kafka-local
  kafka-cluster
  metabase
  minio
  mongo-local
  mongo-replica
  mysql-local
  mysql-8-replication
  nacos
  nginx
  postgres-local
  prometheus-grafana
  rabbitmq-local
  rabbitmq-cluster
  redis-local
  redis-cluster-6
  redis-sentinel-6
)

for service in "${services[@]}"; do
  echo
  echo "===== $service ====="
  (cd "$ROOT_DIR/$service" && docker compose ps)
done
