#!/usr/bin/env bash
set -euo pipefail

if [[ "${EUID}" -ne 0 ]]; then
  echo "Run with sudo: sudo bash $0"
  exit 1
fi

export DEBIAN_FRONTEND=noninteractive

apt-get update
apt-get install -y ca-certificates curl gnupg

install -d -m 0755 /etc/apt/keyrings
curl -fsSL https://pgp.mongodb.com/server-8.0.asc \
  | gpg --dearmor -o /etc/apt/keyrings/mongodb-server-8.0.gpg

cat >/etc/apt/sources.list.d/mongodb-org-8.0.sources <<'EOF'
Types: deb
URIs: https://repo.mongodb.org/apt/ubuntu
Suites: noble/mongodb-org/8.0
Components: multiverse
Architectures: amd64
Signed-By: /etc/apt/keyrings/mongodb-server-8.0.gpg
EOF

apt-get update
apt-get install -y mongodb-org mongodb-mongosh

install -d -m 0755 /etc/systemd/system/mongod.service.d
cat >/etc/systemd/system/mongod.service.d/kernel-rseq.conf <<'EOF'
[Service]
Environment="GLIBC_TUNABLES=glibc.pthread.rseq=1"
EOF

systemctl daemon-reload
systemctl enable mongod
systemctl restart mongod

for _ in $(seq 1 30); do
  if mongosh --quiet --eval 'db.adminCommand({ ping: 1 }).ok' >/dev/null 2>&1; then
    break
  fi
  sleep 1
done

mongosh --quiet <<'EOF'
use admin
if (db.getUser("xs") === null) {
  db.createUser({
    user: "xs",
    pwd: "xsailxma",
    roles: [
      { role: "root", db: "admin" }
    ]
  })
} else {
  db.updateUser("xs", {
    pwd: "xsailxma",
    roles: [
      { role: "root", db: "admin" }
    ]
  })
}
EOF

echo
mongod --version | head -1
mongosh --version
systemctl status mongod --no-pager
