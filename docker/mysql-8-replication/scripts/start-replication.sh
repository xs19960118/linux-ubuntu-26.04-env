#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SERVICE_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"

if [[ ! -f "$SERVICE_DIR/.env" ]]; then
  echo "Missing .env. Run: cp .env.example .env" >&2
  exit 1
fi

set -a
# shellcheck disable=SC1091
source "$SERVICE_DIR/.env"
set +a

: "${MYSQL_ROOT_PASSWORD:?MYSQL_ROOT_PASSWORD is required}"
: "${MYSQL_REPLICATION_USER:?MYSQL_REPLICATION_USER is required}"
: "${MYSQL_REPLICATION_PASSWORD:?MYSQL_REPLICATION_PASSWORD is required}"

replicas=(
  dev-mysql-slave-1
  dev-mysql-slave-2
)

for replica in "${replicas[@]}"; do
  current_status="$(
    docker exec "$replica" sh -ec \
      'MYSQL_PWD="$MYSQL_ROOT_PASSWORD" mysql -uroot -e "SHOW REPLICA STATUS\G"' 2>/dev/null || true
  )"
  if grep -q 'Replica_IO_Running: Yes' <<<"$current_status" \
    && grep -q 'Replica_SQL_Running: Yes' <<<"$current_status"; then
    echo "$replica replication is already running."
    continue
  fi

  if grep -q 'Last_IO_Errno: 2061' <<<"$current_status"; then
    echo "$replica requires the source RSA public key; updating its connection."
    docker exec -i "$replica" sh -ec \
      'MYSQL_PWD="$MYSQL_ROOT_PASSWORD" mysql -uroot' <<SQL
STOP REPLICA;
CHANGE REPLICATION SOURCE TO GET_SOURCE_PUBLIC_KEY=1;
START REPLICA;
SQL
    continue
  fi

  if ! start_output="$(
    docker exec "$replica" sh -ec \
      'MYSQL_PWD="$MYSQL_ROOT_PASSWORD" mysql -uroot -e "START REPLICA"' 2>&1
  )"; then
    if ! grep -q 'ERROR 1872' <<<"$start_output"; then
      printf '%s\n' "$start_output" >&2
      exit 1
    fi

    echo "$replica has invalid applier metadata; rebuilding replication metadata."
    docker exec -i "$replica" sh -ec \
      'MYSQL_PWD="$MYSQL_ROOT_PASSWORD" mysql -uroot' <<SQL
RESET REPLICA ALL;
CHANGE REPLICATION SOURCE TO
  SOURCE_HOST='mysql-master',
  SOURCE_PORT=3306,
  SOURCE_USER='${MYSQL_REPLICATION_USER}',
  SOURCE_PASSWORD='${MYSQL_REPLICATION_PASSWORD}',
  GET_SOURCE_PUBLIC_KEY=1,
  SOURCE_AUTO_POSITION=1;
START REPLICA;
SQL
  fi
done

for replica in "${replicas[@]}"; do
  for _ in {1..30}; do
    status="$(
      docker exec "$replica" sh -ec \
        'MYSQL_PWD="$MYSQL_ROOT_PASSWORD" mysql -uroot -e "SHOW REPLICA STATUS\G"' 2>/dev/null
    )"
    if grep -q 'Replica_IO_Running: Yes' <<<"$status" \
      && grep -q 'Replica_SQL_Running: Yes' <<<"$status"; then
      echo "$replica replication is running."
      break
    fi
    sleep 2
  done

  if ! grep -q 'Replica_IO_Running: Yes' <<<"$status" \
    || ! grep -q 'Replica_SQL_Running: Yes' <<<"$status"; then
    echo "$replica replication failed to start." >&2
    exit 1
  fi
done
