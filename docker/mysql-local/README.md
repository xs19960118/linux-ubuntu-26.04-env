# mysql-local

Service directory: `/home/xs/workplace/docker/mysql-local`

Current status: implemented.

## Structure

```text
.env.example
docker-compose.yml
conf/
data/
logs/
runtime/
backup/
scripts/
README.md
```

## Usage

```bash
cp .env.example .env
docker compose up -d
docker compose ps
docker compose logs -f
docker compose down
```

Root Makefile:

```bash
cd /home/xs/workplace/docker
make up SERVICE=mysql-local
make ps SERVICE=mysql-local
make logs SERVICE=mysql-local
make down SERVICE=mysql-local
```

## Connection

```text
host: 127.0.0.1
port: 13306
root password: xsailxma
database: app_db
username: xs
password: xsailxma
```

CLI:

```bash
mysql -h127.0.0.1 -P13306 -uxs -pxsailxma app_db
```

JDBC:

```text
jdbc:mysql://127.0.0.1:13306/app_db?useUnicode=true&characterEncoding=utf8&serverTimezone=Asia/Shanghai
```

## Files

- `conf/my.cnf` maps to `/etc/mysql/conf.d/my.cnf`.
- `data/` maps to `/var/lib/mysql`.
- `logs/` maps to `/var/log/mysql`.
- `runtime/` maps to `/var/run/mysqld`.
- `scripts/init/` maps to `/docker-entrypoint-initdb.d`.

## Backup And Restore

Backup:

```bash
./scripts/backup.sh
```

Restore:

```bash
CONFIRM=YES ./scripts/restore.sh backup/mysql-local-YYYYmmdd-HHMMSS.sql.gz
```

## Permissions

The official MySQL image runs MySQL with the `mysql` user inside the container. If the container cannot write to mounted directories, fix ownership based on the container user shown by:

```bash
docker run --rm mysql:8.0.40 id mysql
```

## Rules

- Ports must bind to `127.0.0.1` by default.
- Image is pinned by `MYSQL_IMAGE=mysql:8.0.40`.
- Compose uses `restart: unless-stopped`.
- Compose defines `healthcheck`.
- `data/`, `logs/`, `runtime/`, `backup/`, and local `.env` are not committed.
- Directory permissions must follow the image user requirements.
