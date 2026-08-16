#!/usr/bin/env bash
set -euo pipefail

primary_node="rabbit@rabbitmq-1"

join_node() {
  local container="$1"

  if docker exec "$container" rabbitmqctl cluster_status --formatter json \
    | grep -Fq "\"$primary_node\""; then
    echo "$container is already joined to $primary_node."
    return
  fi

  docker exec "$container" rabbitmqctl stop_app
  docker exec "$container" rabbitmqctl reset
  docker exec "$container" rabbitmqctl join_cluster "$primary_node"
  docker exec "$container" rabbitmqctl start_app
}

join_node dev-rabbitmq-cluster-2
join_node dev-rabbitmq-cluster-3

docker exec dev-rabbitmq-cluster-1 rabbitmqctl cluster_status
