#!/usr/bin/env bash
set -euo pipefail

if [[ "${EUID}" -ne 0 ]]; then
  echo "Run with sudo: sudo bash $0"
  exit 1
fi

export DEBIAN_FRONTEND=noninteractive

apt-get update
apt-get install -y nginx-full

install -d -m 0755 /var/www/php-sites

declare -A PHP_SITES=(
  [php56]=5.6
  [php71]=7.1
  [php74]=7.4
  [php81]=8.1
  [php84]=8.4
  [php85]=8.5
)

for site in "${!PHP_SITES[@]}"; do
  version="${PHP_SITES[$site]}"
  root="/var/www/php-sites/${site}"
  socket="/run/php/php${version}-fpm.sock"
  server_name="${site}.xs.local"

  install -d -m 0755 "$root"
  cat >"${root}/index.php" <<EOF
<?php
echo "site=${site}\\n";
echo "php=" . PHP_VERSION . "\\n";
echo "sapi=" . PHP_SAPI . "\\n";
EOF

  cat >"/etc/nginx/sites-available/${site}.conf" <<EOF
server {
    listen 80;
    server_name ${server_name};

    root ${root};
    index index.php index.html;

    access_log /var/log/nginx/${site}.access.log;
    error_log /var/log/nginx/${site}.error.log;

    location / {
        try_files \$uri \$uri/ /index.php?\$query_string;
    }

    location ~ \.php$ {
        include snippets/fastcgi-php.conf;
        fastcgi_pass unix:${socket};
    }

    location ~ /\. {
        deny all;
    }
}
EOF

  ln -sfn "/etc/nginx/sites-available/${site}.conf" "/etc/nginx/sites-enabled/${site}.conf"

  if ! grep -qE "[[:space:]]${server_name}([[:space:]]|$)" /etc/hosts; then
    printf "127.0.0.1 %s\n" "$server_name" >> /etc/hosts
  fi
done

rm -f /etc/nginx/sites-enabled/default

nginx -t
systemctl enable nginx
systemctl restart nginx

echo
echo "Nginx PHP sites:"
for site in php56 php71 php74 php81 php84 php85; do
  echo "http://${site}.xs.local"
done
