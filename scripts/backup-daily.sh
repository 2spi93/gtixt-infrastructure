#!/bin/bash
# Backup automatique PostgreSQL + MinIO
# À exécuter via cron quotidien : 0 2 * * * /opt/gpti/scripts/backup-daily.sh

set -e

BACKUP_DIR="/opt/gpti/backups"
TIMESTAMP=$(date +%Y%m%d_%H%M%S)
RETENTION_DAYS=30

# Créer dossier backup
mkdir -p "$BACKUP_DIR/postgres" "$BACKUP_DIR/minio"

echo "[$(date)] Starting backup..."

# 1. Backup PostgreSQL
echo "Backing up PostgreSQL..."
sudo docker exec infra-postgres-1 pg_dumpall -U gpti | gzip > "$BACKUP_DIR/postgres/gpti_${TIMESTAMP}.sql.gz"

# 2. Backup MinIO volumes
echo "Backing up MinIO data..."
sudo docker run --rm \
  -v infra_minio_data:/data \
  -v "$BACKUP_DIR/minio":/backup \
  alpine tar czf "/backup/minio_${TIMESTAMP}.tar.gz" /data

# 3. Backup .env files
echo "Backing up configuration..."
tar czf "$BACKUP_DIR/config_${TIMESTAMP}.tar.gz" \
  /opt/gpti/gpti-data-bot/infra/.env \
  /opt/gpti/gpti-site/.env.local

# 4. Nettoyer anciens backups
echo "Cleaning old backups (>${RETENTION_DAYS} days)..."
find "$BACKUP_DIR" -name "*.gz" -type f -mtime +$RETENTION_DAYS -delete

# 5. Vérifier espace disque
echo "Disk space:"
df -h "$BACKUP_DIR"

echo "[$(date)] Backup completed successfully!"

# Optional: Sync to remote storage
# aws s3 sync "$BACKUP_DIR" s3://my-bucket/gpti-backups/ --exclude "*" --include "*.gz"
