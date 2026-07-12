#!/usr/bin/env bash
set -euo pipefail

docker exec dev-rabbitmq-cluster-2 rabbitmqctl stop_app
docker exec dev-rabbitmq-cluster-2 rabbitmqctl reset
docker exec dev-rabbitmq-cluster-2 rabbitmqctl join_cluster rabbit@rabbitmq-1
docker exec dev-rabbitmq-cluster-2 rabbitmqctl start_app

docker exec dev-rabbitmq-cluster-3 rabbitmqctl stop_app
docker exec dev-rabbitmq-cluster-3 rabbitmqctl reset
docker exec dev-rabbitmq-cluster-3 rabbitmqctl join_cluster rabbit@rabbitmq-1
docker exec dev-rabbitmq-cluster-3 rabbitmqctl start_app

docker exec dev-rabbitmq-cluster-1 rabbitmqctl cluster_status
