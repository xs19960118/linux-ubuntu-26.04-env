# kafka-local

Service directory: `/home/xs/workplace/docker/kafka-local`

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

Endpoints:

```text
Kafka: 127.0.0.1:19092
Kafka UI: http://127.0.0.1:18082
```

## Rules

- Ports must bind to `127.0.0.1` by default.
- Images must use exact versions, not `latest`.
- Compose services must define `restart: unless-stopped`.
- Compose services must define `healthcheck`.
- `data/`, `logs/`, `runtime/`, `backup/`, and local `.env` are not committed.
- Directory permissions must follow the image user requirements.
