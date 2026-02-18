#!/bin/bash
# Health Check Script for GPTI Infrastructure

set -e

ALERT_EMAIL="${ALERT_EMAIL:-admin@example.com}"
SLACK_WEBHOOK="${SLACK_WEBHOOK:-}"
EXIT_CODE=0

STACK_DIR="${GPTI_STACK_DIR:-}"
if [ -z "$STACK_DIR" ]; then
  if [ -f "/opt/gpti/docker/docker-compose.yml" ]; then
    STACK_DIR="/opt/gpti/docker"
  elif [ -f "/opt/gpti/gpti-data-bot/infra/docker-compose.yml" ]; then
    STACK_DIR="/opt/gpti/gpti-data-bot/infra"
  else
    STACK_DIR="/opt/gpti"
  fi
fi

COMPOSE_FILE="$STACK_DIR/docker-compose.yml"
COMPOSE=(docker compose -f "$COMPOSE_FILE")

if [ "$STACK_DIR" = "/opt/gpti/docker" ]; then
  MINIO_PORT_DEFAULT=9002
else
  MINIO_PORT_DEFAULT=9000
fi

MINIO_PORT="${MINIO_PORT:-$MINIO_PORT_DEFAULT}"
MINIO_HEALTH_URL="${MINIO_HEALTH_URL:-http://localhost:${MINIO_PORT}/minio/health/live}"
SITE_URL="${SITE_URL:-http://localhost:3000}"
API_BASE_URL="${API_BASE_URL:-$SITE_URL}"

log() {
  echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1"
}

alert() {
  local message="$1"
  log "ALERT: $message"
  
  # Send to Slack if configured
  if [ -n "$SLACK_WEBHOOK" ]; then
    curl -X POST "$SLACK_WEBHOOK" \
      -H 'Content-Type: application/json' \
      -d "{\"text\":\"🚨 GPTI Health Alert: $message\"}" \
      > /dev/null 2>&1
  fi
}

# Check Docker containers
log "Checking Docker containers..."
SERVICES=("postgres" "minio" "prefect-server" "bot")

if [ -f "$COMPOSE_FILE" ]; then
  for service in "${SERVICES[@]}"; do
    if ! "${COMPOSE[@]}" ps --status running --services 2>/dev/null | grep -q "^${service}$"; then
      alert "Service ${service} is not running (compose: $COMPOSE_FILE)!"
      EXIT_CODE=1
    else
      log "✓ Service ${service} is running"
    fi
  done
else
  alert "docker-compose.yml not found at $COMPOSE_FILE"
  EXIT_CODE=1
fi

# Check PostgreSQL
log "Checking PostgreSQL..."
POSTGRES_USER_NAME="${POSTGRES_USER:-gpti}"
POSTGRES_DB_NAME="${POSTGRES_DB:-gpti}"
if ! "${COMPOSE[@]}" exec -T postgres pg_isready -U "$POSTGRES_USER_NAME" -d "$POSTGRES_DB_NAME" > /dev/null 2>&1; then
  alert "PostgreSQL is not ready!"
  EXIT_CODE=1
else
  log "✓ PostgreSQL is healthy"
fi

# Check MinIO
log "Checking MinIO..."
if ! curl -sf "$MINIO_HEALTH_URL" > /dev/null 2>&1; then
  alert "MinIO is not responding!"
  EXIT_CODE=1
else
  log "✓ MinIO is healthy"
fi

# Check disk space
log "Checking disk space..."
DISK_USAGE=$(df -h / | awk 'NR==2 {print $5}' | sed 's/%//')
if [ "$DISK_USAGE" -gt 85 ]; then
  alert "Disk usage is at ${DISK_USAGE}%!"
  EXIT_CODE=1
else
  log "✓ Disk usage: ${DISK_USAGE}%"
fi

# Check memory
log "Checking memory..."
MEM_USAGE=$(free | awk 'NR==2 {printf "%.0f", ($3/$2)*100}')
if [ "$MEM_USAGE" -gt 90 ]; then
  alert "Memory usage is at ${MEM_USAGE}%!"
  EXIT_CODE=1
else
  log "✓ Memory usage: ${MEM_USAGE}%"
fi

# Check website
log "Checking website..."
if ! curl -sf "$SITE_URL" > /dev/null 2>&1; then
  alert "Website is not responding!"
  EXIT_CODE=1
else
  log "✓ Website is responding"
fi

# Check API endpoints
log "Checking API endpoints..."
ENDPOINTS=("/api/health" "/api/firms" "/api/snapshots")
for endpoint in "${ENDPOINTS[@]}"; do
  if ! curl -sf "${API_BASE_URL}${endpoint}" > /dev/null 2>&1; then
    alert "API endpoint ${endpoint} is not responding!"
    EXIT_CODE=1
  else
    log "✓ API endpoint ${endpoint} is healthy"
  fi
done

if [ $EXIT_CODE -eq 0 ]; then
  log "✅ All health checks passed!"
else
  log "❌ Some health checks failed!"
fi

exit $EXIT_CODE
