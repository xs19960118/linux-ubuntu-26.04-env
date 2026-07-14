#!/usr/bin/env bash
set -euo pipefail

if [[ "${EUID}" -ne 0 ]]; then
  echo "Run with sudo: sudo bash $0"
  exit 1
fi

export DEBIAN_FRONTEND=noninteractive

PHP_VERSIONS=(5.6 7.1 7.4 8.1 8.4 8.5)
PHP_EXTENSIONS=(
  bcmath
  curl
  dev
  fpm
  gd
  imagick
  intl
  mbstring
  memcached
  mongodb
  mysql
  pgsql
  rdkafka
  redis
  soap
  sqlite3
  xdebug
  xml
  yaml
  zip
  amqp
)

apt-get update
apt-get install -y ca-certificates curl gnupg lsb-release apt-transport-https librdkafka-dev librabbitmq-dev

install -d -m 0755 /etc/apt/keyrings
curl -fsSL https://packages.sury.org/php/apt.gpg \
  | gpg --dearmor -o /etc/apt/keyrings/sury-php.gpg

cat >/etc/apt/sources.list.d/sury-php.sources <<'EOF'
Types: deb
URIs: https://packages.sury.org/php/
Suites: resolute
Components: main
Signed-By: /etc/apt/keyrings/sury-php.gpg
EOF

apt-get update

packages=(php-pear composer)
for version in "${PHP_VERSIONS[@]}"; do
  packages+=("php${version}-cli" "php${version}-common")
  for extension in "${PHP_EXTENSIONS[@]}"; do
    package="php${version}-${extension}"
    if apt-cache show "$package" >/dev/null 2>&1; then
      packages+=("$package")
    else
      echo "skip unavailable package: $package"
    fi
  done
done

apt-get install -y "${packages[@]}"

for version in "${PHP_VERSIONS[@]}"; do
  if systemctl list-unit-files "php${version}-fpm.service" --no-legend 2>/dev/null | grep -q "php${version}-fpm.service"; then
    systemctl enable "php${version}-fpm"
    systemctl restart "php${version}-fpm"
  fi
done

echo
echo "PHP multi-version install result:"
for version in "${PHP_VERSIONS[@]}"; do
  echo "== PHP ${version} =="
  if command -v "php${version}" >/dev/null 2>&1; then
    "php${version}" -v | head -1
    echo "cli ini: $("php${version}" --ini | awk -F': *' '/Loaded Configuration File/ {print $2}')"
  else
    echo "cli: missing"
  fi
  if command -v "phpize${version}" >/dev/null 2>&1; then
    "phpize${version}" -v | head -2
  else
    echo "phpize: missing"
  fi
  if command -v "php-config${version}" >/dev/null 2>&1; then
    echo "php-config: $("php-config${version}" --version)"
  else
    echo "php-config: missing"
  fi
  systemctl is-active "php${version}-fpm" 2>/dev/null || true
done
