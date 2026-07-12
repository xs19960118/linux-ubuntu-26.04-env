#!/usr/bin/env bash
set -euo pipefail

if [ "${CONFIRM:-}" != "YES" ]; then
  echo "Refusing to restore without CONFIRM=YES."
  exit 1
fi

echo "TODO: implement restore for mongo-replica."
exit 1
