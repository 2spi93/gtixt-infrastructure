#!/bin/bash

# 🔧 Fix Remaining Issues Script
# Corrects: PYTHONPATH, snapshot generation, health checks

set -e

echo "╔════════════════════════════════════════════════════════════╗"
echo "║  FIXING REMAINING STAGING ISSUES                           ║"
echo "╚════════════════════════════════════════════════════════════╝"

# ========== ISSUE 1: PYTHONPATH for access_check import ==========
echo ""
echo "📌 ISSUE 1: PYTHONPATH Configuration"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

echo "Adding PYTHONPATH to .env files..."

# Update docker/.env
if ! grep -q "PYTHONPATH=" /opt/gpti/docker/.env; then
    echo "PYTHONPATH=/opt/gpti/gpti-data-bot/src" >> /opt/gpti/docker/.env
    echo "✅ Added PYTHONPATH to docker/.env"
else
    echo "✅ PYTHONPATH already in docker/.env"
fi

# Create .env.staging for staging environment
cat > /opt/gpti/docker/.env.staging << 'EOF'
# Staging Environment Configuration
POSTGRES_DB=gpti
POSTGRES_USER=gpti
POSTGRES_PASSWORD=superpassword

MINIO_ROOT_USER=minioadmin
MINIO_ROOT_PASSWORD=minioadmin123
MINIO_REGION=us-east-1

PREFECT_SERVER_API_HOST=0.0.0.0
PREFECT_SERVER_API_PORT=4200
PREFECT_API_URL=http://prefect-server:4200/api

GPTI_ENV=staging
GPTI_TIMEZONE=UTC

# CRITICAL: Python path for agent imports
PYTHONPATH=/opt/gpti/gpti-data-bot/src

# GPTI crawler defaults
GPTI_AUTO_RESUME=1
OLLAMA_TIMEOUT_S=30

# Web Search Service
GPTI_WEB_SEARCH_CACHE=/opt/gpti/tmp/web_search_cache
GPTI_WEB_SEARCH_CACHE_TTL_H=24
GPTI_WEB_SEARCH_TIMEOUT_S=10
GPTI_WEB_SEARCH_SOURCES=duckduckgo

# Access check
GPTI_ACCESS_CHECK=1
GPTI_ACCESS_LIMIT=20
EOF

echo "✅ Created .env.staging file"

# ========== ISSUE 2: Generate snapshot data ==========
echo ""
echo "📌 ISSUE 2: Snapshot Data Generation"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

SNAPSHOT_DIR="/opt/gpti/data/exports/universe_v0.1_public/_public"
mkdir -p "$SNAPSHOT_DIR" 2>/dev/null || true

if [ -f "$SNAPSHOT_DIR/latest.json" ]; then
    echo "✅ Snapshot exists at: $SNAPSHOT_DIR/latest.json"
    ls -lh "$SNAPSHOT_DIR/latest.json"
else
    echo "Creating minimal test snapshot..."
    cat > "$SNAPSHOT_DIR/latest.json" << 'SNAPSHOT_EOF'
{
  "object": "universe_v0.1_public/_public/latest.json",
  "created_at": "2026-02-18T12:00:00Z",
  "sha256": "placeholder_sha256_hash",
  "version": "v0.1",
  "firms_count": 0,
  "data": {
    "universe": [],
    "metadata": {
      "generated_at": "2026-02-18T12:00:00Z",
      "validation_passed": false,
      "qa_notes": "Test snapshot - replace with real data"
    }
  }
}
SNAPSHOT_EOF
    echo "✅ Created test snapshot at: $SNAPSHOT_DIR/latest.json"
fi

# ========== ISSUE 3: Health check endpoints ==========
echo ""
echo "📌 ISSUE 3: Health Check Configuration"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

cat > /opt/gpti/health-check-staging.sh << 'HEALTH_EOF'
#!/bin/bash
# Quick health check for staging

echo "🏥 STAGING HEALTH CHECK"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

# Frontend
echo -n "Frontend port 3000: "
nc -z localhost 3000 2>/dev/null && echo "✅" || echo "❌"

# API endpoints
echo -n "API /api/firms: "
curl -s -o /dev/null -w "%{http_code}\n" http://localhost:3000/api/firms | grep -q "200" && echo "✅" || echo "⚠️"

echo -n "Homepage /: "
curl -s -o /dev/null -w "%{http_code}\n" http://localhost:3000/ | grep -q "200" && echo "✅" || echo "⚠️"

# Python modules
export PYTHONPATH="/opt/gpti/gpti-data-bot/src"
echo -n "Python web_search module: "
python3 -c "from gpti_bot.discovery.web_search import web_search; print('OK')" 2>/dev/null && echo "✅" || echo "❌"

echo ""
echo "Health check complete!"
HEALTH_EOF

chmod +x /opt/gpti/health-check-staging.sh
echo "✅ Created /opt/gpti/health-check-staging.sh"

# ========== ISSUE 4: HTTP 308 Fix ==========
echo ""
echo "📌 ISSUE 4: HTTP 308 Redirects (Expected)"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

echo "✅ HTTP 308 is normal Next.js behavior for trailing slashes"
echo "   Use: curl -s -L http://localhost:3000/rankings (with -L flag)"
echo "   This will follow the redirect automatically"

# ========== SUCCESS ==========
echo ""
echo "╔════════════════════════════════════════════════════════════╗"
echo "║  ISSUES FIXED                                              ║"
echo "╚════════════════════════════════════════════════════════════╝"

echo ""
echo "✅ Next steps:"
echo "  export PYTHONPATH=/opt/gpti/gpti-data-bot/src"
echo "  bash /opt/gpti/health-check-staging.sh"
echo "  bash /opt/gpti/verify-staging.sh"
echo ""
