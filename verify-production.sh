#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="/opt/gpti"
BOT_ENV="$ROOT_DIR/gpti-data-bot/.env.production.local"
SITE_ENV="$ROOT_DIR/gpti-site/.env.local"

if [[ -f "$BOT_ENV" ]]; then
  set -a
  source "$BOT_ENV"
  set +a
fi

if [[ -f "$SITE_ENV" ]]; then
  set -a
  source "$SITE_ENV"
  set +a
fi

LATEST_POINTER_URL="${SNAPSHOT_LATEST_URL:-${NEXT_PUBLIC_LATEST_POINTER_URL:-https://data.gtixt.com/gpti-snapshots/universe_v0.1_public/_public/latest.json}}"
MINIO_ROOT="${MINIO_INTERNAL_ROOT:-${NEXT_PUBLIC_MINIO_PUBLIC_ROOT:-https://data.gtixt.com/gpti-snapshots/}}"
SITE_URL="${SITE_URL:-${NEXT_PUBLIC_SITE_URL:-https://gtixt.com}}"

log() { echo "[$(date '+%Y-%m-%d %H:%M:%S')] $*"; }

log "Production verification"
log "Latest pointer: $LATEST_POINTER_URL"
log "MinIO root: $MINIO_ROOT"
log "Site URL: $SITE_URL"

log "Checking latest pointer..."
latest_json=$(curl -sfL "$LATEST_POINTER_URL")
object=$(echo "$latest_json" | jq -r '.object // empty')
sha=$(echo "$latest_json" | jq -r '.sha256 // empty')
created=$(echo "$latest_json" | jq -r '.created_at // empty')

if [[ -z "$object" ]]; then
  echo "✗ latest.json missing object"
  exit 1
fi

echo "✓ latest.json object=$object"
[[ -n "$sha" ]] && echo "  sha256=$sha"
[[ -n "$created" ]] && echo "  created_at=$created"

snapshot_url="${MINIO_ROOT}${object}"
log "Checking snapshot object..."
if curl -sfI "$snapshot_url" >/dev/null; then
  echo "✓ snapshot accessible"
else
  echo "✗ snapshot not accessible: $snapshot_url"
  exit 1
fi

log "Checking site endpoints..."
for endpoint in "/rankings" "/api/snapshots" "/api/firms/" "/integrity"; do
  status=$(curl -sL -o /dev/null -w "%{http_code}" "${SITE_URL}${endpoint}" || true)
  if [[ -n "$status" ]]; then
    echo "  ${endpoint}: HTTP ${status}"
  else
    echo "  ${endpoint}: unreachable"
  fi
done

log "Checking API payloads..."
api_firms_url="${SITE_URL}/api/firms/"
firms_payload=$(curl -sfL "$api_firms_url")

if echo "$firms_payload" | jq -e '.success == true' >/dev/null; then
  firms_count=$(echo "$firms_payload" | jq -r '.count // 0')
  firms_total=$(echo "$firms_payload" | jq -r '.total // 0')
  echo "  /api/firms: success=true count=${firms_count} total=${firms_total}"
else
  echo "  /api/firms: unexpected payload"
  exit 1
fi

sample_firm_id=$(echo "$firms_payload" | jq -r '.firms[0].firm_id // empty')
if [[ -z "$sample_firm_id" ]]; then
  echo "  /api/firms: missing sample firm_id"
  exit 1
fi

api_firm_url="${SITE_URL}/api/firm/?id=${sample_firm_id}"
firm_payload=$(curl -sfL "$api_firm_url")
firm_id=$(echo "$firm_payload" | jq -r '.firm.firm_id // empty')
if [[ "$firm_id" == "$sample_firm_id" ]]; then
  echo "  /api/firm: firm_id=${firm_id}"
else
  echo "  /api/firm: unexpected payload"
  exit 1
fi

echo "✅ Production verification complete"
