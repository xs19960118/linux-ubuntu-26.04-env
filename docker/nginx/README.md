# nginx

Service directory: `/home/xs/workplace/docker/nginx`

Current status: implemented.

## Structure

```text
.env.example
docker-compose.yml
conf/
html/
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
http://127.0.0.1:18080
https://127.0.0.1:18443
http://127.0.0.1:18080/health
```

## Rules

- Ports must bind to `127.0.0.1` by default.
- Images must use exact versions, not `latest`.
- Compose services must define `restart: unless-stopped`.
- Compose services must define `healthcheck`.
- `data/`, `logs/`, `runtime/`, `backup/`, and local `.env` are not committed.
- Directory permissions must follow the image user requirements.
