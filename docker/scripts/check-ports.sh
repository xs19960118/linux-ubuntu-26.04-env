#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

if ! command -v jq >/dev/null 2>&1; then
  echo "missing dependency: jq"
  exit 1
fi

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

tmp_file="$(mktemp)"
trap 'rm -f "$tmp_file"' EXIT

failures=0

for service in "${services[@]}"; do
  service_dir="$ROOT_DIR/$service"

  if [[ ! -d "$service_dir" ]]; then
    echo "missing service directory: $service"
    failures=$((failures + 1))
    continue
  fi

  (
    cd "$service_dir"
    docker compose config --format json
  ) | jq -r --arg service "$service" '
    .services
    | to_entries[]
    | .key as $compose_service
    | (.value.ports // [])[]
    | [
        $service,
        $compose_service,
        (.host_ip // ""),
        (.published | tostring),
        (.target | tostring),
        (.protocol // "tcp")
      ]
    | @tsv
  ' >> "$tmp_file"
done

while IFS=$'\t' read -r service compose_service host_ip published target protocol; do
  if [[ -z "$host_ip" || "$host_ip" != "127.0.0.1" ]]; then
    echo "non-local bind: $service/$compose_service ${host_ip:-<empty>}:$published->$target/$protocol"
    failures=$((failures + 1))
  fi
done < "$tmp_file"

while IFS=$'\t' read -r host_ip published protocol count; do
  if ((count > 1)); then
    echo "duplicate host port: $host_ip:$published/$protocol"
    awk -F '\t' -v host_ip="$host_ip" -v published="$published" -v protocol="$protocol" \
      '$3 == host_ip && $4 == published && $6 == protocol { printf "  - %s/%s -> %s\n", $1, $2, $5 }' \
      "$tmp_file"
    failures=$((failures + 1))
  fi
done < <(awk -F '\t' '{ key = $3 "\t" $4 "\t" $6; count[key]++ } END { for (key in count) print key "\t" count[key] }' "$tmp_file")

reserved_ports=(80 443 3306 5432 6379 9092 27017)
for reserved in "${reserved_ports[@]}"; do
  if awk -F '\t' -v port="$reserved" '$4 == port { found = 1 } END { exit !found }' "$tmp_file"; then
    echo "reserved host port is used: $reserved"
    awk -F '\t' -v port="$reserved" '$4 == port { printf "  - %s/%s %s:%s/%s\n", $1, $2, $3, $4, $6 }' "$tmp_file"
    failures=$((failures + 1))
  fi
done

if ((failures > 0)); then
  echo "port check failed: $failures issue(s)"
  exit 1
fi

sort -t $'\t' -k4,4n -k6,6 "$tmp_file" | awk -F '\t' '{ printf "%-22s %-20s %s:%s->%s/%s\n", $1, $2, $3, $4, $5, $6 }'
echo "port check ok"
