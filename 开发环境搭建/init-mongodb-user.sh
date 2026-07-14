#!/usr/bin/env bash
set -euo pipefail

if ! systemctl is-active mongod >/dev/null 2>&1; then
  echo "mongod is not active"
  systemctl status mongod --no-pager || true
  exit 1
fi

mongosh --quiet <<'EOF'
const admin = db.getSiblingDB("admin");
if (admin.getUser("xs") === null) {
  admin.createUser({
    user: "xs",
    pwd: "xsailxma",
    roles: [
      { role: "root", db: "admin" }
    ]
  });
  print("created user xs");
} else {
  admin.updateUser("xs", {
    pwd: "xsailxma",
    roles: [
      { role: "root", db: "admin" }
    ]
  });
  print("updated user xs");
}
printjson(admin.getUser("xs"));
EOF

mongosh "mongodb://xs:xsailxma@127.0.0.1:27017/admin" --quiet --eval 'db.runCommand({ connectionStatus: 1 }).authInfo.authenticatedUsers'
