# mysql-8-replication

Service directory: `/home/xs/docker-env/docker/mysql-8-replication`

Current status: implemented.

## Structure

```text
.env.example
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

Start or recover both replication channels after the containers are healthy:

```bash
./scripts/start-replication.sh
```

The script succeeds only when both the I/O and SQL replication threads are
running on both replicas.

## Rules

- Ports must bind to `127.0.0.1` by default.
- Images must use exact versions, not `latest`.
- Compose services must define `restart: unless-stopped`.
- Compose services must define `healthcheck`.
- `data/`, `logs/`, `runtime/`, `backup/`, and local `.env` are not committed.
- Directory permissions must follow the image user requirements.
