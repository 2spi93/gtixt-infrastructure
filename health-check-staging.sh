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
