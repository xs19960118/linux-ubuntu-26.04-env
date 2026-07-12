SERVICE ?=

.PHONY: require-service up down restart ps logs config

require-service:
	@test -n "$(SERVICE)" || (echo "Usage: make <target> SERVICE=<service-name>" && exit 1)
	@test -d "$(SERVICE)" || (echo "Service not found: $(SERVICE)" && exit 1)

up: require-service
	cd "$(SERVICE)" && docker compose up -d

down: require-service
	cd "$(SERVICE)" && docker compose down

restart: require-service
	cd "$(SERVICE)" && docker compose restart

ps: require-service
	cd "$(SERVICE)" && docker compose ps

logs: require-service
	cd "$(SERVICE)" && docker compose logs -f

config: require-service
	cd "$(SERVICE)" && docker compose config
