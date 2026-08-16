# kafka-cluster

Service directory: `/home/xs/docker-env/docker/kafka-cluster`

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

Host clients can use `127.0.0.1:19093`, `127.0.0.1:19094`, or
`127.0.0.1:19095`. Containers on `dev_kafka_cluster_net` use
`kafka-1:9092`, `kafka-2:9092`, and `kafka-3:9092`. Kafka UI is available at
`http://127.0.0.1:18081`.

## Rules

- Ports must bind to `127.0.0.1` by default.
- Images must use exact versions, not `latest`.
- Compose services must define `restart: unless-stopped`.
- Compose services must define `healthcheck`.
- `data/`, `logs/`, `runtime/`, `backup/`, and local `.env` are not committed.
- Directory permissions must follow the image user requirements.
