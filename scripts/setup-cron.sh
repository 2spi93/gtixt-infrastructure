#!/bin/bash
# Setup Cron Jobs for GPTI Automation

SCRIPT_DIR="/opt/gpti/scripts"
CRON_FILE="/tmp/gpti-cron"

echo "Setting up GPTI cron jobs..."

# Create crontab entries
cat > "$CRON_FILE" << 'EOF'
# GPTI Automated Tasks
SHELL=/bin/bash
PATH=/usr/local/sbin:/usr/local/bin:/sbin:/bin:/usr/sbin:/usr/bin

# Daily backup at 2:00 AM
0 2 * * * /opt/gpti/scripts/backup-daily.sh >> /var/log/gpti/backup.log 2>&1

# Weekly backup cleanup (every Sunday at 3:00 AM)
0 3 * * 0 find /opt/gpti/backups -type f -mtime +30 -delete >> /var/log/gpti/cleanup.log 2>&1

# Daily health check at 6:00 AM
0 6 * * * /opt/gpti/scripts/health-check.sh >> /var/log/gpti/health.log 2>&1

# Restart containers weekly (every Monday at 4:00 AM)
0 4 * * 1 cd /opt/gpti/gpti-data-bot/infra && docker compose restart >> /var/log/gpti/restart.log 2>&1

# Clean Docker resources monthly (first day at 5:00 AM)
0 5 1 * * docker system prune -af --volumes >> /var/log/gpti/docker-cleanup.log 2>&1

# Update sitemap daily at 1:00 AM
0 1 * * * cd /opt/gpti/gpti-site && npm run postbuild >> /var/log/gpti/sitemap.log 2>&1

EOF

# Install crontab
crontab "$CRON_FILE"

# Verify installation
echo "Installed cron jobs:"
crontab -l

# Create log directory
mkdir -p /var/log/gpti
chmod 755 /var/log/gpti

echo "Cron jobs successfully configured!"
echo "Logs will be written to /var/log/gpti/"
