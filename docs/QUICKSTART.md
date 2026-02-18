# ⚡ QUICK START — GPTI Deployment

**For**: DevOps, System Admins, Release Managers  
**Duration**: 15 minutes  
**Prerequisites**: Docker, Python 3.9+, git  

---

## 🚀 5-Minute Deploy

```bash
# 1. Clone/update code
cd /opt/gpti && git pull origin main

# 2. Start services
docker-compose up -d

# 3. Verify health
docker-compose ps
docker compose logs --tail 20

# 4. Test access
curl http://localhost:4000/healthz
```

**If everything is green** ✅ → Deployment complete!

---

## 🔍 Quick Validation (3 min)

```bash
# Test each component
docker-compose ps | grep -E "gpti|postgres|ollama|minio"

PYTHONPATH=/opt/gpti/gpti-data-bot/src python3 -c "
from gpti_bot.discovery.web_search import web_search
results = web_search('test', max_results=1)
print(f'✅ Web search works: {len(results)} results')
"

psql -U gpti -d gpti -c "SELECT COUNT(*) FROM firms;" 2>&1 | tail -2

echo "✅ All components healthy!"
```

---

## 📋 Rollback (1 min)

```bash
# Immediate: Revert to previous commit
cd /opt/gpti
git checkout HEAD~1
docker-compose restart

# Verify rollback
curl http://localhost:4000/healthz
```

---

## 🐛 Troubleshooting

| Issue | Solution |
|-------|----------|
| Ollama timeout | Check: `docker logs ollama` \| Set `OLLAMA_TIMEOUT_S=30` |
| DB connection error | Check: `psql -U gpti -d gpti` \| Restart: `docker-compose restart postgres_gpti` |
| Web search 0 results | Clear cache: `rm -rf /opt/gpti/tmp/web_search_cache` \| Retry |
| Frontend not loading | Check: `docker logs gpti-site` \| Verify: `curl -I http://localhost:3000` |

---

## 📞 Need Help?

Documentation:
- Full deployment: [DEPLOYMENT_PLAN.md](DEPLOYMENT_PLAN.md)
- Audit trail: [DEPLOYMENT_AUDIT.md](DEPLOYMENT_AUDIT.md)
- Web search: [WEB_SEARCH_SERVICE.md](WEB_SEARCH_SERVICE.md)

Emergency contacts: See DEPLOYMENT_PLAN.md

---

**Last Updated**: 2026-02-18  
**Maintained By**: GPTI DevOps Team
