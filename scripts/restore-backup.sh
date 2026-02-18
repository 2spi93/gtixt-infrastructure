#!/bin/bash
# Disaster Recovery - Restauration complète
# Usage: ./restore-backup.sh TIMESTAMP (ex: 20260202_020000)

set -e

if [ $# -eq 0 ]; then
    echo "Usage: $0 TIMESTAMP"
    echo "Example: $0 20260202_020000"
    exit 1
fi

TIMESTAMP=$1
BACKUP_DIR="/opt/gpti/backups"

echo "[$(date)] Starting restore from backup $TIMESTAMP..."

# Arrêter les containers
echo "Stopping containers..."
cd /opt/gpti/gpti-data-bot/infra
sudo docker-compose down

# Restaurer PostgreSQL
if [ -f "$BACKUP_DIR/postgres/gpti_${TIMESTAMP}.sql.gz" ]; then
    echo "Restoring PostgreSQL..."
    sudo docker-compose up -d postgres
    sleep 5
    gunzip < "$BACKUP_DIR/postgres/gpti_${TIMESTAMP}.sql.gz" | \
        sudo docker exec -i infra-postgres-1 psql -U gpti
else
    echo "ERROR: PostgreSQL backup not found!"
    exit 1
fi

# Restaurer MinIO
if [ -f "$BACKUP_DIR/minio/minio_${TIMESTAMP}.tar.gz" ]; then
    echo "Restoring MinIO data..."
    sudo docker run --rm \
        -v infra_minio_data:/data \
        -v "$BACKUP_DIR/minio":/backup \
        alpine sh -c "cd / && tar xzf /backup/minio_${TIMESTAMP}.tar.gz"
else
    echo "ERROR: MinIO backup not found!"
    exit 1
fi

# Restaurer configuration
if [ -f "$BACKUP_DIR/config_${TIMESTAMP}.tar.gz" ]; then
    echo "Restoring configuration..."
    sudo tar xzf "$BACKUP_DIR/config_${TIMESTAMP}.tar.gz" -C /
else
    echo "WARNING: Config backup not found, skipping..."
fi

# Redémarrer tous les services
echo "Starting all containers..."
sudo docker-compose up -d

echo "[$(date)] Restore completed successfully!"
echo "Verify services:"
echo "  - Prefect UI: http://localhost:4200"
echo "  - MinIO: http://localhost:9000"
echo "  - PostgreSQL: localhost:5432"
