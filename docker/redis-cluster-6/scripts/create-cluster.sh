#!/usr/bin/env bash
set -euo pipefail

password="${REDIS_PASSWORD:-xsailxma}"
containers=(
  dev-redis-cluster-1
  dev-redis-cluster-2
  dev-redis-cluster-3
  dev-redis-cluster-4
  dev-redis-cluster-5
  dev-redis-cluster-6
)

first="${containers[0]}"
if docker exec "$first" redis-cli -a "$password" cluster info 2>/dev/null | grep -q '^cluster_state:ok'; then
  echo "Redis Cluster 已经是 ok 状态，跳过初始化。"
  exit 0
fi

echo "重置 Redis Cluster 节点上的半初始化状态。"
for container in "${containers[@]}"; do
  docker exec "$container" redis-cli -a "$password" flushall >/dev/null
  docker exec "$container" redis-cli -a "$password" cluster reset hard >/dev/null || true
done

nodes=()
for container in "${containers[@]}"; do
  ip="$(docker inspect -f '{{range .NetworkSettings.Networks}}{{.IPAddress}}{{end}}' "$container")"
  nodes+=("${ip}:6379")
done

docker exec -i "$first" redis-cli -a "$password" --cluster create \
  "${nodes[@]}" \
  --cluster-replicas 1 --cluster-yes
