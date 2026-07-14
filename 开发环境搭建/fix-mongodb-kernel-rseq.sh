#!/usr/bin/env bash
set -euo pipefail

if [[ "${EUID}" -ne 0 ]]; then
  echo "Run with sudo: sudo bash $0"
  exit 1
fi

install -d -m 0755 /etc/systemd/system/mongod.service.d
cat >/etc/systemd/system/mongod.service.d/kernel-rseq.conf <<'EOF'
[Service]
Environment="GLIBC_TUNABLES=glibc.pthread.rseq=1"
EOF

systemctl daemon-reload
systemctl restart mongod

for _ in $(seq 1 30); do
  if mongosh --quiet --eval 'db.adminCommand({ ping: 1 }).ok' >/dev/null 2>&1; then
    break
  fi
  sleep 1
done

systemctl status mongod --no-pager
mongosh --quiet --eval 'db.adminCommand({ ping: 1 })'
