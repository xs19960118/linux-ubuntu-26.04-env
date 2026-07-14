#!/usr/bin/env bash
set -euo pipefail

PHP_VERSIONS=(5.6 7.1 7.4 8.1 8.4 8.5)
EXTENSIONS=(redis mongodb rdkafka amqp memcached imagick xdebug yaml curl mbstring intl mysqli pdo_mysql pgsql pdo_pgsql gd bcmath soap sqlite3 zip)

for version in "${PHP_VERSIONS[@]}"; do
  echo "== PHP ${version} =="
  if ! command -v "php${version}" >/dev/null 2>&1; then
    echo "missing cli"
    echo
    continue
  fi

  "php${version}" -v | head -1
  "php${version}" -r 'echo "extension_dir=", ini_get("extension_dir"), PHP_EOL;'
  "php${version}" --ini | awk -F': *' '/Loaded Configuration File|Scan for additional .ini files/ {print}'

  if command -v "phpize${version}" >/dev/null 2>&1; then
    "phpize${version}" -v | awk -F': *' '/PHP Api Version|Zend Module Api No|Zend Extension Api No/ {print}'
  else
    echo "phpize: missing"
  fi

  for extension in "${EXTENSIONS[@]}"; do
    if "php${version}" -m | grep -Fxq "$extension"; then
      ext_version="$("php${version}" --ri "$extension" 2>/dev/null | awk -F'=> *| => ' '
        /Version|extension version|Redis Version|MongoDB extension version|librdkafka version|AMQP protocol version|xdebug support/ {
          gsub(/^[[:space:]]+|[[:space:]]+$/, "", $0)
          print $0
          exit
        }
      ')"
      printf "  %-12s enabled  %s\n" "$extension" "${ext_version:-version: unknown}"
    else
      printf "  %-12s missing\n" "$extension"
    fi
  done

  if systemctl list-unit-files "php${version}-fpm.service" --no-legend 2>/dev/null | grep -q "php${version}-fpm.service"; then
    echo "fpm: $(systemctl is-active "php${version}-fpm" 2>/dev/null || true)"
    echo "fpm ini: /etc/php/${version}/fpm/php.ini"
  else
    echo "fpm: missing"
  fi
  echo
done
