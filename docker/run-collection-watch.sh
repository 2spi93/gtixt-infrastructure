#!/usr/bin/env bash
set -euo pipefail

# Watch mode: repeat automated pipeline until extraction gain stalls.

ROOT_DIR="/opt/gpti"
BOT_DIR="$ROOT_DIR/gpti-data-bot"
SITE_DIR="$ROOT_DIR/gpti-site"
ENV_FILE="$ROOT_DIR/docker/.env"

MAX_RUNS="${GPTI_WATCH_MAX_RUNS:-5}"
SLEEP_S="${GPTI_WATCH_SLEEP_S:-300}"
MIN_GAIN="${GPTI_WATCH_MIN_GAIN:-2}"

if [[ -f "$ENV_FILE" ]]; then
  set -a
  source "$ENV_FILE"
  set +a
fi

export PYTHONPATH="$BOT_DIR/src:${PYTHONPATH:-}"
export MINIO_ENDPOINT="${MINIO_ENDPOINT:-http://localhost:9002}"
export MINIO_ACCESS_KEY="${MINIO_ACCESS_KEY:-${MINIO_ROOT_USER:-}}"
export MINIO_SECRET_KEY="${MINIO_SECRET_KEY:-${MINIO_ROOT_PASSWORD:-}}"

export GPTI_INJECT_MAX_PAGES="${GPTI_INJECT_MAX_PAGES:-25}"
export GPTI_CRAWL_DEPTH="${GPTI_CRAWL_DEPTH:-3}"
export GPTI_MAX_DEEP_LINKS="${GPTI_MAX_DEEP_LINKS:-60}"
export GPTI_MAX_RULE_PAGES="${GPTI_MAX_RULE_PAGES:-120}"
export GPTI_MAX_PRICING_PAGES="${GPTI_MAX_PRICING_PAGES:-120}"
export GPTI_MAX_PAGES_PER_FIRM="${GPTI_MAX_PAGES_PER_FIRM:-1200}"
export GPTI_MAX_JS_PAGES="${GPTI_MAX_JS_PAGES:-12}"
export GPTI_OVERRIDE_USE_LLM="${GPTI_OVERRIDE_USE_LLM:-1}"
export GPTI_OVERRIDE_LLM_MODEL="${GPTI_OVERRIDE_LLM_MODEL:-${GPTI_RULES_MODEL:-llama3.1}}"
export GPTI_OVERRIDE_LIMIT="${GPTI_OVERRIDE_LIMIT:-0}"
export GPTI_OVERRIDE_SCAN_LIMIT="${GPTI_OVERRIDE_SCAN_LIMIT:-0}"

prev_count=0
run=1

while [[ $run -le $MAX_RUNS ]]; do
  echo "[watch] run $run/$MAX_RUNS"

  python3 "$BOT_DIR/scripts/inject_firm_evidence.py"

  GPTI_OVERRIDE_USE_LLM="$GPTI_OVERRIDE_USE_LLM" \
  GPTI_OVERRIDE_SCAN_LIMIT="$GPTI_OVERRIDE_SCAN_LIMIT" \
  GPTI_OVERRIDE_LIMIT="$GPTI_OVERRIDE_LIMIT" \
  /opt/gpti/docker/run-collection.sh

  python3 "$BOT_DIR/scripts/generate_firm_overrides.py"

  if [[ -f "$SITE_DIR/data/firm-overrides.auto.json" ]]; then
    count=$(python3 - <<'PY'
import json
with open('/opt/gpti/gpti-site/data/firm-overrides.auto.json','r') as f:
    data=json.load(f)
print(len([k for k in data.keys() if not k.startswith('_')]))
PY
)
  else
    count=0
  fi

  gain=$((count - prev_count))
  echo "[watch] overrides count=$count gain=$gain"

  if [[ $run -gt 1 && $gain -lt $MIN_GAIN ]]; then
    echo "[watch] stopping: gain $gain < $MIN_GAIN"
    break
  fi

  prev_count=$count
  run=$((run + 1))
  if [[ $run -le $MAX_RUNS ]]; then
    sleep "$SLEEP_S"
  fi

done

echo "[ok] watch mode finished"
