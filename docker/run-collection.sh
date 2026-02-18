#!/usr/bin/env bash
set -euo pipefail

SEED_PATH="/app/data/seeds/firm-international.json"
CRAWL_LIMIT="${CRAWL_LIMIT:-200}"
RUN_OVERRIDES="${GPTI_RUN_OVERRIDES:-1}"

# Time + volume budgets
export GPTI_MAX_RUNTIME_S="${GPTI_MAX_RUNTIME_S:-10800}"
export GPTI_MAX_REQUESTS="${GPTI_MAX_REQUESTS:-90000}"
export GPTI_MAX_DOMAIN_S="${GPTI_MAX_DOMAIN_S:-2400}"
export GPTI_MAX_PAGES_PER_FIRM="${GPTI_MAX_PAGES_PER_FIRM:-800}"
export GPTI_SITEMAP_MAX_URLS="${GPTI_SITEMAP_MAX_URLS:-400}"
export GPTI_MAX_RULE_PAGES="${GPTI_MAX_RULE_PAGES:-80}"
export GPTI_MAX_PRICING_PAGES="${GPTI_MAX_PRICING_PAGES:-80}"
export GPTI_MAX_HTML_BYTES="${GPTI_MAX_HTML_BYTES:-5000000}"
export GPTI_RULES_MODEL="${GPTI_RULES_MODEL:-llama3.1}"
export GPTI_PRICING_MODEL="${GPTI_PRICING_MODEL:-llama3.1}"
export GPTI_MAX_PDF_CHARS="${GPTI_MAX_PDF_CHARS:-40000}"
export GPTI_CRAWL_DEPTH="${GPTI_CRAWL_DEPTH:-2}"
export GPTI_MAX_DEEP_LINKS="${GPTI_MAX_DEEP_LINKS:-30}"
export GPTI_ENABLE_JS_RENDER="${GPTI_ENABLE_JS_RENDER:-1}"
export GPTI_ENABLE_PDF="${GPTI_ENABLE_PDF:-1}"
export GPTI_MAX_JS_PAGES="${GPTI_MAX_JS_PAGES:-8}"
export GPTI_MIN_TEXT_CHARS="${GPTI_MIN_TEXT_CHARS:-800}"

# Crawl throttling
export GPTI_CRAWL_WORKERS="${GPTI_CRAWL_WORKERS:-6}"
export GPTI_CRAWL_SLEEP_S="${GPTI_CRAWL_SLEEP_S:-0.8}"
export GPTI_HTTP_TIMEOUT_S="${GPTI_HTTP_TIMEOUT_S:-10}"
export GPTI_MAX_LINKS="${GPTI_MAX_LINKS:-80}"
export GPTI_SLOW_DOMAIN_S="${GPTI_SLOW_DOMAIN_S:-8}"
export GPTI_AGENT_C_MODE="${GPTI_AGENT_C_MODE:-soft}"

# Discover -> crawl -> snapshot -> score -> gate -> public snapshot
sudo docker exec -i gpti-data-bot python -m gpti_bot.cli discover "$SEED_PATH"
sudo docker exec -i \
  -e GPTI_MAX_RUNTIME_S="$GPTI_MAX_RUNTIME_S" \
  -e GPTI_MAX_REQUESTS="$GPTI_MAX_REQUESTS" \
  -e GPTI_MAX_DOMAIN_S="$GPTI_MAX_DOMAIN_S" \
  -e GPTI_MAX_PAGES_PER_FIRM="$GPTI_MAX_PAGES_PER_FIRM" \
  -e GPTI_SITEMAP_MAX_URLS="$GPTI_SITEMAP_MAX_URLS" \
  -e GPTI_CRAWL_WORKERS="$GPTI_CRAWL_WORKERS" \
  -e GPTI_CRAWL_SLEEP_S="$GPTI_CRAWL_SLEEP_S" \
  -e GPTI_HTTP_TIMEOUT_S="$GPTI_HTTP_TIMEOUT_S" \
  -e GPTI_MAX_LINKS="$GPTI_MAX_LINKS" \
  -e GPTI_MAX_HTML_BYTES="$GPTI_MAX_HTML_BYTES" \
  -e GPTI_MAX_PDF_CHARS="$GPTI_MAX_PDF_CHARS" \
  -e GPTI_CRAWL_DEPTH="$GPTI_CRAWL_DEPTH" \
  -e GPTI_MAX_DEEP_LINKS="$GPTI_MAX_DEEP_LINKS" \
  -e GPTI_ENABLE_JS_RENDER="$GPTI_ENABLE_JS_RENDER" \
  -e GPTI_ENABLE_PDF="$GPTI_ENABLE_PDF" \
  -e GPTI_MAX_JS_PAGES="$GPTI_MAX_JS_PAGES" \
  -e GPTI_MIN_TEXT_CHARS="$GPTI_MIN_TEXT_CHARS" \
  -e GPTI_MAX_RULE_PAGES="$GPTI_MAX_RULE_PAGES" \
  -e GPTI_MAX_PRICING_PAGES="$GPTI_MAX_PRICING_PAGES" \
  -e GPTI_SLOW_DOMAIN_S="$GPTI_SLOW_DOMAIN_S" \
  gpti-data-bot python -m gpti_bot.cli crawl "$CRAWL_LIMIT"

sudo docker exec -i gpti-data-bot python -m gpti_bot.cli export-snapshot
sudo docker exec -i gpti-data-bot python -m gpti_bot.cli score-snapshot
sudo docker exec -i -e GPTI_AGENT_C_MODE="$GPTI_AGENT_C_MODE" gpti-data-bot python -m gpti_bot.cli verify-snapshot
sudo docker exec -i gpti-data-bot python -m gpti_bot.cli export-snapshot --public

# Refresh agent_status from evidence + validation
sudo docker exec -i gpti-postgres psql -U gpti -d gpti -c "WITH evidence_counts AS (SELECT collected_by AS agent_key, COUNT(*)::int AS evidence_count FROM evidence_collection GROUP BY collected_by), validation_counts AS (SELECT COUNT(*)::int AS validation_count FROM validation_metrics) UPDATE agent_status a SET status = CASE WHEN a.agent = 'AGENT_C' AND (SELECT validation_count FROM validation_counts) > 0 THEN 'complete' WHEN a.agent <> 'AGENT_C' AND COALESCE(evidence_counts.evidence_count, 0) > 0 THEN 'complete' ELSE 'testing' END, last_updated = NOW() FROM evidence_counts WHERE a.agent = evidence_counts.agent_key OR a.agent = 'AGENT_C';"

# Upsert validation metrics from latest snapshot scores
sudo docker exec -i gpti-postgres psql -U gpti -d gpti -c "WITH latest_scores AS (SELECT MAX(snapshot_id) AS snapshot_id FROM snapshot_scores), snap AS (SELECT id, snapshot_key FROM snapshot_metadata WHERE id = (SELECT snapshot_id FROM latest_scores)), scores AS (SELECT COUNT(*)::int AS total, AVG(COALESCE(na_rate, 0)) AS avg_na FROM snapshot_scores WHERE snapshot_id = (SELECT snapshot_id FROM latest_scores)), agentc AS (SELECT COUNT(*) FILTER (WHERE verdict = 'pass')::int AS pass_count, COUNT(*)::int AS total FROM agent_c_audit WHERE snapshot_key = (SELECT snapshot_key FROM snap)), events AS (SELECT COUNT(*)::int AS events_in_period FROM ground_truth_events) INSERT INTO validation_metrics (snapshot_id, timestamp, total_firms, coverage_percent, avg_na_rate, agent_c_pass_rate, events_in_period, events_predicted, prediction_precision) VALUES ((SELECT snapshot_key FROM snap), NOW(), (SELECT total FROM scores), ROUND(100 - (SELECT avg_na FROM scores), 2), ROUND((SELECT avg_na FROM scores), 2), CASE WHEN (SELECT total FROM agentc) > 0 THEN ROUND((SELECT pass_count FROM agentc) * 100.0 / (SELECT total FROM agentc), 2) ELSE 0 END, (SELECT events_in_period FROM events), 0, 0) ON CONFLICT (snapshot_id) DO UPDATE SET timestamp = EXCLUDED.timestamp, total_firms = EXCLUDED.total_firms, coverage_percent = EXCLUDED.coverage_percent, avg_na_rate = EXCLUDED.avg_na_rate, agent_c_pass_rate = EXCLUDED.agent_c_pass_rate, events_in_period = EXCLUDED.events_in_period;"

echo "[ok] collection run completed"

if [[ "$RUN_OVERRIDES" == "1" ]]; then
  if [[ -f "/opt/gpti/docker/.env" ]]; then
    set -a
    source /opt/gpti/docker/.env
    set +a
  fi
  export MINIO_ENDPOINT="${MINIO_ENDPOINT:-http://localhost:9002}"
  export MINIO_ACCESS_KEY="${MINIO_ACCESS_KEY:-${MINIO_ROOT_USER:-}}"
  export MINIO_SECRET_KEY="${MINIO_SECRET_KEY:-${MINIO_ROOT_PASSWORD:-}}"
  export GPTI_OVERRIDE_LIMIT="${GPTI_OVERRIDE_LIMIT:-50}"
  export GPTI_OVERRIDE_SCAN_LIMIT="${GPTI_OVERRIDE_SCAN_LIMIT:-500}"
  export GPTI_OVERRIDE_LOG_EVERY="${GPTI_OVERRIDE_LOG_EVERY:-25}"
  export PYTHONPATH="/opt/gpti/gpti-data-bot/src:${PYTHONPATH:-}"
  python3 /opt/gpti/gpti-data-bot/scripts/generate_firm_overrides.py || true
fi
