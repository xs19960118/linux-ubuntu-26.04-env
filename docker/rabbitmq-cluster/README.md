# rabbitmq-cluster

Service directory: `/home/xs/docker-env/docker/rabbitmq-cluster`

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

Join nodes 2 and 3 to node 1 after the containers are healthy:

```bash
./scripts/join-cluster.sh
```

The script is idempotent. It resets a node only when that node has not joined
`rabbit@rabbitmq-1` yet.

## Rules

- Ports must bind to `127.0.0.1` by default.
- Images must use exact versions, not `latest`.
- Compose services must define `restart: unless-stopped`.
- Compose services must define `healthcheck`.
- `data/`, `logs/`, `runtime/`, `backup/`, and local `.env` are not committed.
- Directory permissions must follow the image user requirements.
