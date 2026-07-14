#!/usr/bin/env bash
set -euo pipefail

command -v mongod >/dev/null
command -v mongosh >/dev/null

mongod --version | head -1
mongosh --version
if ! systemctl is-active mongod; then
  echo
  echo "mongod is not active. Recent logs:"
  journalctl -u mongod -n 40 --no-pager
  exit 1
fi
ss -ltnp | awk 'NR == 1 || /:27017 /'

mongosh --quiet --eval 'db.adminCommand({ ping: 1 })'
mongosh "mongodb://xs:xsailxma@127.0.0.1:27017/admin" --quiet --eval 'db.runCommand({ connectionStatus: 1 }).authInfo.authenticatedUsers'
