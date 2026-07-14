#!/usr/bin/env bash
set -euo pipefail

mysql_container="${NACOS_MYSQL_CONTAINER:-dev-nacos-mysql}"
nacos_container="${NACOS_CONTAINER:-dev-nacos}"
mysql_root_password="${MYSQL_ROOT_PASSWORD:-xsailxma}"
nacos_image="${NACOS_IMAGE:-nacos/nacos-server:v2.4.3}"
database="${MYSQL_DATABASE:-nacos}"
nacos_user="${NACOS_CONSOLE_USER:-xs}"
nacos_password_hash="${NACOS_CONSOLE_PASSWORD_HASH:-\$2b\$10\$ekNa2.iCyQZ9uuw/CmEGyeDepDHiufwsoS0k0IjIJbfdR319bB0kG}"

until docker exec "$mysql_container" mysqladmin ping -h 127.0.0.1 -uroot -p"$mysql_root_password" --silent >/dev/null 2>&1; do
  sleep 2
done

table_count="$(
  docker exec "$mysql_container" mysql -N -uroot -p"$mysql_root_password" \
    -e "SELECT COUNT(*) FROM information_schema.tables WHERE table_schema='${database}';" 2>/dev/null
)"

if [[ "$table_count" == "0" ]]; then
  echo "导入 Nacos MySQL schema 到 ${database}。"
  docker run --rm --entrypoint cat "$nacos_image" /home/nacos/conf/mysql-schema.sql \
    | docker exec -i "$mysql_container" mysql -uroot -p"$mysql_root_password" "$database"
else
  echo "Nacos MySQL schema 已存在，跳过导入。"
fi

docker exec -i "$mysql_container" mysql -uroot -p"$mysql_root_password" "$database" <<SQL
INSERT INTO users(username, password, enabled)
VALUES ('${nacos_user}', '${nacos_password_hash}', 1)
ON DUPLICATE KEY UPDATE password = VALUES(password), enabled = VALUES(enabled);

INSERT INTO roles(username, role)
VALUES ('${nacos_user}', 'ROLE_ADMIN')
ON DUPLICATE KEY UPDATE role = VALUES(role);
SQL

if docker ps --format '{{.Names}}' | grep -qx "$nacos_container"; then
  docker restart "$nacos_container" >/dev/null
fi
