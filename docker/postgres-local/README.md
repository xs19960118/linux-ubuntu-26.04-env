# postgres-local

Service directory: `/home/xs/workplace/docker/postgres-local`

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

Connection:

```text
host: 127.0.0.1
port: 15432
database: app_db
username: xs
password: xsailxma
```

CLI:

```bash
psql -h 127.0.0.1 -p 15432 -U xs -d app_db
```

## Rules

- Ports must bind to `127.0.0.1` by default.
- Images must use exact versions, not `latest`.
- Compose services must define `restart: unless-stopped`.
- Compose services must define `healthcheck`.
- `data/`, `logs/`, `runtime/`, `backup/`, and local `.env` are not committed.
- Directory permissions must follow the image user requirements.
