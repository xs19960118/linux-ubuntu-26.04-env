#!/usr/bin/env bash
set -euo pipefail

docker exec -i dev-redis-cluster-1 redis-cli -a xsailxma --cluster create \
  dev-redis-cluster-1:6379 dev-redis-cluster-2:6379 dev-redis-cluster-3:6379 \
  dev-redis-cluster-4:6379 dev-redis-cluster-5:6379 dev-redis-cluster-6:6379 \
  --cluster-replicas 1 --cluster-yes
