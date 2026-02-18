#!/bin/bash
# Setup Docker Secrets pour production
# À exécuter une seule fois lors de l'initialisation

set -e

echo "Initializing Docker Secrets..."

# Créer secrets depuis variables d'environnement ou saisie interactive
read -sp "PostgreSQL Password: " POSTGRES_PASSWORD
echo
echo "$POSTGRES_PASSWORD" | docker secret create postgres_password -

read -sp "MinIO Root Password: " MINIO_PASSWORD
echo
echo "$MINIO_PASSWORD" | docker secret create minio_root_password -

read -sp "Prefect API Key: " PREFECT_KEY
echo
echo "$PREFECT_KEY" | docker secret create prefect_api_key -

read -sp "Slack Webhook URL: " SLACK_WEBHOOK
echo
echo "$SLACK_WEBHOOK" | docker secret create slack_webhook -

echo "Docker secrets created successfully!"
echo "Update docker-compose.yml to use secrets:"
echo "  secrets:"
echo "    - postgres_password"
echo "    - minio_root_password"
