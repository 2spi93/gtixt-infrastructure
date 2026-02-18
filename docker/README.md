# GPTI Docker Stack

Unified docker-compose for PostgreSQL, MinIO, Prefect, and gpti-data-bot.

## Start

sudo docker compose up -d

## Stop

sudo docker compose down

## Ports

- PostgreSQL: localhost:5434
- MinIO API: localhost:9002
- MinIO Console: localhost:9003
- Prefect UI/API: localhost:4201
- Next.js dev: localhost:3001 (if running)

## Data Collection

Run the automated collection with limits:

./run-collection.sh

Override limits (example):

GPTI_MAX_RUNTIME_S=14400 GPTI_MAX_REQUESTS=500000 CRAWL_LIMIT=2000 ./run-collection.sh

## Environment

Edit .env in this directory for credentials and settings.
