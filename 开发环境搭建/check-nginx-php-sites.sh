#!/usr/bin/env bash
set -euo pipefail

sites=(php56 php71 php74 php81 php84 php85)

for site in "${sites[@]}"; do
  url="http://${site}.xs.local"
  echo "== ${url} =="
  curl -fsS "$url"
  echo
done
