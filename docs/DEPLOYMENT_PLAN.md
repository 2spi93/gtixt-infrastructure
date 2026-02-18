# 🚀 DEPLOYMENT PLAN — GPTI Data Bot v1.0.0

**Date**: 18 février 2026  
**Version**: 1.0.0-prod  
**Status**: Ready for Staging → Production  

---

## 📋 Pre-Deployment Checklist

### Code Review ✅
- [x] Web search system code reviewed
- [x] Agent integration verified
- [x] No breaking changes to existing APIs
- [x] All tests passed
- [x] Documentation complete

### Security Review ✅
- [x] No hardcoded secrets in code
- [x] Environment variables correctly configured
- [x] Database credentials in .env.production.local (gitignored)
- [x] API keys (if any) properly scoped
- [x] Web search requires no API keys (risk eliminated)

### Data Backup ✅
- [x] PostgreSQL: `/opt/gpti/backups/postgres/` ready
- [x] MinIO: `/opt/gpti/backups/minio/` ready
- [x] Configuration: docker/.env backed up

### Infrastructure ✅
- [x] PostgreSQL: Running on port 5432
- [x] Ollama LLM: Available on port 11435
- [x] MinIO: Running on port 9000
- [x] Redis (optional): Available if needed
- [x] Docker resources: Adequate

---

## 🔄 Deployment Stages

### Stage 1: Staging Validation (1-2 hours)

**Timeline**: Day 1, 9:00-11:00

```bash
# 1. Pull latest code
cd /opt/gpti
git fetch origin && git pull origin main

# 2. Install/update dependencies
pip install -r gpti-data-bot/requirements.txt
npm install --prefix gpti-site

# 3. Run database migrations
cd gpti-data-bot
alembic upgrade head

# 4. Run health checks
PYTHONPATH=/opt/gpti/gpti-data-bot/src python3 -m gpti_bot verify-ollama
PYTHONPATH=/opt/gpti/gpti-data-bot/src python3 -m gpti_bot web-search "TopStep" 5

# 5. Run full test suite
pytest tests/ -v --tb=short

# 6. Validate API responses
curl -s http://localhost:4000/graphql -X POST \
  -H "Content-Type: application/json" \
  -d '{"query": "{ firms { id firmId brandName } }"}' | jq .
```

**Expected Results**:
- ✅ All migrations applied successfully
- ✅ Ollama connectivity: 200 OK
- ✅ Web search: 2+ results returned with cache
- ✅ Tests: 100% passing
- ✅ API: Returns JSON with firms data

### Stage 2: Production Deployment (30-45 minutes)

**Timeline**: Day 1, 14:00-15:00 (after 3-hour validation)

#### 2a. Database Snapshot
```bash
# Create backup before any changes
docker exec postgres_gpti pg_dump gpti > /opt/gpti/backups/postgres/pre-deployment-$(date +%Y%m%d_%H%M%S).sql

# Verify backup size
ls -lh /opt/gpti/backups/postgres/ | tail -5
```

#### 2b. Deploy Services
```bash
cd /opt/gpti

# 1. Stop current services (graceful)
docker-compose down --timeout 10

# 2. Pull latest images
docker-compose pull

# 3. Start services with new code
docker-compose up -d

# 4. Wait for stability (30s)
sleep 30

# 5. Verify all containers are running
docker-compose ps

# 6. Check logs for errors
docker-compose logs --tail 100 | grep -i error || echo "✅ No errors"
```

#### 2c. Post-Deployment Verification
```bash
# Health check
PYTHONPATH=/opt/gpti/gpti-data-bot/src python3 -m gpti_bot verify-ollama

# Test web search (with cache)
PYTHONPATH=/opt/gpti/gpti-data-bot/src python3 -m gpti_bot web-search "TopStep"

# Test access-check
PYTHONPATH=/opt/gpti/gpti-data-bot/src \
  GPTI_ACCESS_LIMIT=5 python3 -m gpti_bot access-check

# Verify database connectivity
psql -U gpti -d gpti -h localhost -c "SELECT COUNT(*) as firm_count FROM firms;"

# Check MinIO connectivity
aws s3 ls s3://gpti-snapshots --endpoint-url http://localhost:9000
```

---

## 🎯 Deployment Phases (Next 30 Days)

### Phase 1: Immediate (Today)
- [x] Git init and commit base code
- [x] Audit complete
- [x] Documentation up-to-date
- **→ GO**: Proceed to Staging

### Phase 2: Staging (Tomorrow)
- [ ] Deploy to staging environment
- [ ] Run full smoke tests
- [ ] Validate data flow end-to-end
- [ ] Performance baseline measurement
- **→ GATE**: Sign-off required before Production

### Phase 3: Production (Next Week)
- [ ] Blue-green deployment (old ↔ new)
- [ ] Gradual traffic shift (10% → 25% → 50% → 100%)
- [ ] Monitor error rates (target: <0.1%)
- [ ] Monitor latency (target: <500ms p99)
- **→ COMPLETE**: Full rollout

### Phase 4: Stabilization (Days 7-14)
- [ ] Monitor production metrics
- [ ] Fix any discovered issues
- [ ] Gather user feedback
- [ ] Document learnings

### Phase 5: Cleanup (Days 15-30)
- [ ] Archive staging environment
- [ ] Shut down old infrastructure
- [ ] Update runbooks
- [ ] Plan Phase 2 improvements

---

## 🔍 Monitoring & Alerts (Post-Deployment)

### Key Metrics to Track

| Metric | Target | Warning | Critical |
|--------|--------|---------|----------|
| API Response Time (p99) | <500ms | >800ms | >2000ms |
| Error Rate | <0.1% | >0.5% | >2% |
| Ollama Availability | 99% | <95% | <90% |
| Database Connection Pool | Healthy | 80% usage | 95% usage |
| Web Search Cache Hit | >80% | <60% | <40% |
| Access-Check Success | >40% | <30% | <20% |

### Alert Configuration
```yaml
# Prometheus alerts would be set up as:
- alert: HighAPILatency
  expr: http_request_duration_seconds{quantile="0.99"} > 2
  for: 5m

- alert: OllamaDown
  expr: up{job="ollama"} == 0
  for: 1m

- alert: DatabaseConnectionPoolFull
  expr: db_connections_used / db_connections_total > 0.95
  for: 5m
```

### Logging & Debugging
- **Application Logs**: Docker container logs
- **Database Logs**: PostgreSQL query log
- **Access Logs**: nginx/reverse proxy (if applicable)
- **Error Tracking**: Sentry/rollbar (optional)

---

## 🆘 Rollback Procedures

### If Critical Issues Found

**Within first 5 minutes** → Automatic rollback
```bash
cd /opt/gpti
docker-compose down
# Revert to previous git commit
git checkout HEAD~1
docker-compose up -d
```

**Within 12 hours** → Database restore needed
```bash
# Stop services
docker-compose down

# Restore from backup
docker exec postgres_gpti psql -U gpti postgres < /opt/gpti/backups/postgres/pre-deployment-TIMESTAMP.sql

# Restart services
docker-compose up -d
```

**Beyond 12 hours** → Contact data team lead

### Rollback Success Criteria
- ✅ API responding (curl http://localhost:4000/healthz)
- ✅ Frontend displays correctly
- ✅ Database queries returning expected results
- ✅ All error logs clear

---

## 📞 Support & Escalation

### On-Call Team (Prod)
| Role | Name | Phone | Slack |
|------|------|-------|-------|
| DevOps Lead | @oncall-devops | TBD | #gpti-alerts |
| Data Lead | @data-lead | TBD | #gpti-data |
| Frontend Lead | @frontend-lead | TBD | #gpti-frontend |

### Escalation Path
1. **Issue detected** → #gpti-alerts (Slack)
2. **On-call responds** → Assess severity
3. **P1-P2** → War room in Discord/Zoom
4. **P3+** → Standard issue tracker

---

## 📝 Post-Deployment Report Template

```markdown
## Deployment Report: GPTI v1.0.0

**Date**: 2026-02-XX
**Duration**: X hours
**Status**: ✅ Successful / ⚠️ Partial / ❌ Rolled Back

### Deployment Summary
- Services deployed: [list]
- Database migrations: [X applied]
- Configuration changes: [summary]

### Validation Results
- Health checks: ✅ Pass
- API tests: ✅ Pass (95% passing rate)
- Performance: ✅ Within targets
- Data integrity: ✅ Verified

### Issues Encountered
- [Issue 1]: Resolved/Outstanding
- [Issue 2]: Resolved/Outstanding

### Metrics (Post-Deployment)
- API Response Time: 250ms (target: <500ms) ✅
- Error Rate: 0.02% (target: <0.1%) ✅
- Web Search Cache Hit: 92% (target: >80%) ✅

### Lessons Learned
- [Learning 1]
- [Learning 2]

### Next Steps
- [ ] Task 1
- [ ] Task 2

**Approved By**: [Name]
```

---

## 🎓 Knowledge Transfer

### Documentation to Review
1. [WEB_SEARCH_SERVICE.md](../docs/WEB_SEARCH_SERVICE.md) — Web search system architecture
2. [DEPLOYMENT_AUDIT.md](../docs/DEPLOYMENT_AUDIT.md) — Full audit trail
3. [DB_ADDENDUM.md](../docs/DB_ADDENDUM.md) — Database schema
4. [README.md](../docs/README.md) — Project overview

### Video Walkthroughs (To Record)
- [ ] How web search integration works
- [ ] How to run access-check
- [ ] How to troubleshoot Ollama timeouts
- [ ] How to read the deployment audit

---

## ✅ Sign-Off

**Deployment Manager**: _________________  
**Date**: _________________  
**Notes**: _________________________________________________________________

**DevOps Lead**: _________________  
**Date**: _________________  
**Notes**: _________________________________________________________________

**Data Lead**: _________________  
**Date**: _________________  
**Notes**: _________________________________________________________________

---

**Next Review Date**: 2026-03-18  
**Maintenance Window**: Saturdays 2-4 AM UTC  
**Escalation Contact**: #gpti-alerts (Slack)
