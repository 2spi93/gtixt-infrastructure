#!/usr/bin/env bash
set -euo pipefail

export PYTHONPATH=/opt/gpti/gpti-data-bot/src
export DATABASE_URL=postgresql://gpti:superpassword@localhost:5434/gpti
export MINIO_ENDPOINT=http://localhost:9002
export MINIO_ACCESS_KEY=minioadmin
export MINIO_SECRET_KEY=minioadmin123
export MINIO_BUCKET_RAW=gpti-raw
export MINIO_BUCKET_SNAPSHOTS=gpti-snapshots
export MINIO_USE_SSL=false
export OLLAMA_BASE_URL=http://localhost:11434
export OLLAMA_MODEL_RULES=qwen2.5:1.5b
export OLLAMA_DEFAULT_MODEL=qwen2.5:1.5b
export OLLAMA_TIMEOUT_S=30
export GPTI_ENABLE_JS_RENDER=1
export GPTI_ENABLE_PDF=1
export GPTI_OCR_ENABLED=1
export GPTI_XHR_SNIFF=1
export GPTI_AUTO_RESUME=1
export GPTI_PROXY=http://lvqgbkuu-rotate:rytl4mkwbdaf@p.webshare.io:80
export GPTI_FIRM_TIMEOUT_S=240
export GPTI_DOMAIN_DELAY_S=0.4
export GPTI_EXTERNAL_MAX_URLS=10
export GPTI_EXTERNAL_JS_RENDER=1
export GPTI_EXTERNAL_JS_MAX_PAGES=2
export GPTI_EXTERNAL_MIN_HTML_BYTES=400
export GPTI_CAPTCHA_PROVIDER=2captcha
export GPTI_CAPTCHA_2CAPTCHA_KEY=223e5ef8b2b8fc1f55025b002b695187
export GPTI_CAPTCHA_TIMEOUT_S=120
export GPTI_CAPTCHA_POLL_S=5

if [[ "${GPTI_ACCESS_CHECK:-1}" == "1" ]]; then
	python3 -m gpti_bot access-check "${GPTI_ACCESS_LIMIT:-20}"
fi

LIMIT=${GPTI_MISSING_LIMIT:-50}

python3 /opt/gpti/gpti-data-bot/scripts/auto_enrich_missing.py --limit "$LIMIT" --resume
python3 -m gpti_bot export-snapshot
python3 -m gpti_bot score-snapshot
python3 -m gpti_bot verify-snapshot
python3 -m gpti_bot export-snapshot --public
python3 /opt/gpti/scripts/audit-missing-firm-fields.py
