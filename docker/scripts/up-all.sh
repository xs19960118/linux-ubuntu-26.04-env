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

failed=0
for service in "${services[@]}"; do
  echo
  echo "===== 启动 $service ====="
  if (cd "$ROOT_DIR/$service" && docker compose up -d --remove-orphans); then
    echo "===== 完成 $service ====="
  else
    echo "===== 失败 $service =====" >&2
    failed=1
  fi
done

echo
echo "===== 启动 mysql-8-replication 复制 ====="
if (cd "$ROOT_DIR/mysql-8-replication" && ./scripts/start-replication.sh); then
  echo "===== 完成 mysql-8-replication 复制启动 ====="
else
  echo "===== 失败 mysql-8-replication 复制启动 =====" >&2
  failed=1
fi

echo
echo "===== 初始化 rabbitmq-cluster 集群 ====="
if (cd "$ROOT_DIR/rabbitmq-cluster" && ./scripts/join-cluster.sh); then
  echo "===== 完成 rabbitmq-cluster 集群初始化 ====="
else
  echo "===== 失败 rabbitmq-cluster 集群初始化 =====" >&2
  failed=1
fi

echo
echo "===== 初始化 nacos 数据库 ====="
if (cd "$ROOT_DIR/nacos" && ./scripts/init-db.sh); then
  echo "===== 完成 nacos 数据库初始化 ====="
else
  echo "===== 失败 nacos 数据库初始化 =====" >&2
  failed=1
fi

echo
echo "===== 初始化 redis-cluster-6 分片集群 ====="
if (cd "$ROOT_DIR/redis-cluster-6" && ./scripts/create-cluster.sh); then
  echo "===== 完成 redis-cluster-6 初始化 ====="
else
  echo "===== 失败 redis-cluster-6 初始化 =====" >&2
  failed=1
fi

exit "$failed"
