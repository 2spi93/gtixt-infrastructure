# GPTI Crawl Status - 2026-02-19 21:20 UTC

## 🎬 Current Crawl Status

```
START TIME:     2026-02-19 21:19:55 UTC  
PROCESS PIDs:   646679, 646798
CPU USAGE:      2.1% (lean, healthy crawl)
MEMORY USAGE:   56.5 MB (excellent - was 200+ MB before optimization)
STATUS:         ✅ OPTIMIZED & RUNNING
```

## ⚙️ Configuration (Final)

```env
GPTI_ENABLE_JS_RENDER=0         ✓ NO Playwright (avoids 80MB/instance)
GPTI_ENABLE_PDF=0               ✓ Skip PDFs (fast)
GPTI_MAX_PAGES_PER_FIRM=50      ✓ Conservative (vs 120)
GPTI_MAX_JS_PAGES=0             ✓ No browser rendering
GPTI_FIRM_TIMEOUT_S=60          ✓ Timeout protection
GPTI_DOMAIN_DELAY_S=0.1         ✓ Fast crawl
GPTI_CRAWL_TIMEOUT_S=1800       ✓ 30min safety limit
GPTI_MISSING_LIMIT=227          ✓ Process all firms
```

## 📊 Expected Timeline

```
NOW (21:20 UTC)       → Processing has begun
21:35 UTC (15 min)    → ~10-15 firms enriched
21:50 UTC (30 min)    → ~50 firms enriched (22%)
22:05 UTC (45 min)    → ~100 firms enriched (50%)
22:20 UTC (60 min)    → All firms should be complete
22:25 UTC             → Snapshot generated
22:26 UTC             → MinIO sync complete
22:27 UTC             → API returns live data
```

## 🔍 Monitoring Commands

```bash
# Real-time crawl progress (updates every 5 seconds)
watch -n 5 'tail -20 /opt/gpti/tmp/crawl-optimized.log'

# Check process status
ps aux | grep auto_enrich | grep -v grep

# Monitor memory
free -h && echo "---" && ps aux | grep auto_enrich | grep -v grep | awk '{print "Memory: " $6 " KB"}'

# Database enrichment check (run after crawl finishes)
psql -U gpti -d gpti -c "SELECT COUNT(*), COUNT(CASE WHEN score_0_100>50 THEN 1 END) as enriched FROM firms;"

# API verification (after crawl completes)
curl -s http://localhost:3000/api/firms/?limit=1 | jq '.firms[0] | {name, jurisdiction, score_0_100}'
```

## 🚨 If Issues Occur

**Process dies with TargetClosedError:**
```bash
# Kill all auto_enrich processes
pkill -f auto_enrich_missing.py

# Check if JS rendering somehow re-enabled
grep GPTI_ENABLE_JS_RENDER /opt/gpti/docker/.env

# Restart with explicit disable
cd /opt/gpti && /opt/gpti/start-crawl.sh
```

**Memory spike above 500MB:**
```bash
# Stop Ollama (fallback LLM not needed now)
docker-compose -f /opt/gpti/docker/docker-compose.yml stop ollama

# Restart crawl
/opt/gpti/start-crawl.sh
```

**Database connection fails:**
```bash
# Test connection
psql -U gpti -d gpti -c "SELECT 1"

# Check if PostgreSQL is running
docker-compose -f /opt/gpti/docker/docker-compose.yml ps postgres
```

## 📈 What's Being Extracted (Per Firm)

From each firm's website, the crawler extracts:

```json
{
  "firm_id": "ftmocom",
  "name": "FTMO",
  "website_root": "https://ftmo.com",
  "headquarters": "Prague, Czech Republic",
  "founded_year": 2015,
  "jurisdiction": "Czech Republic",
  "leverage_info": "1:100",
  "spreads": "Variable 0.1 pips",
  "minimum_deposit": 100,
  "commission": "0.1 pips per trade",
  "licenses": ["CySEC/248/15"],
  "score_0_100": 82,
  "confidence": 0.88,
  "na_rate": 12,
  "pillar_scores": {
    "A_transparency": 0.9,
    "B_payout_reliability": 0.85,
    "C_risk_model": 0.70,
    "D_legal_compliance": 0.95,
    "E_reputation_support": 0.80
  },
  "enrichment_timestamp": 1739975400
}
```

## ✅ Success Criteria (To Validate After Crawl)

- [ ] Crawl completes without errors
- [ ] Log file shows `enriched=True` for majority of firms
- [ ] No `TargetClosedError` in logs (Playwright disabled)
- [ ] Database reports 160+ firms with score > 50
- [ ] `/api/firms/` returns diverse jurisdictions (not all "Global")
- [ ] Pages display coverage badge > 0%
- [ ] API response times < 200ms (live data)
- [ ] Snapshot SHA-256 hash matches MinIO
- [ ] Latest pointer updated in MinIO (/snapshots/latest.json)

## 🔄 Post-Crawl Steps (Will Execute After Completion)

1. **Generate Snapshot** (auto)
   - Export 227 enriched firms to JSON
   - Calculate SHA-256 hash
   - Timestamp: @(crawl_end_time)

2. **Sync to MinIO** (auto)
   - Upload to: `gpti-snapshots/universe_v0.1_public/_public/gtixt_snapshot_[timestamp].json`
   - Update latest pointer

3. **Refresh API** (auto)
   - Pages detect new snapshot
   - Reload firm data from PostgreSQL
   - Invalidate caches

4. **Re-render Pages** (browser)
   - /index shows coverage badge (75%+)
   - /rankings displays enriched scores
   - /firms searchable by jurisdiction
   - /firm/[id] shows full details

## 📝 Process Diagram

```
START (21:19 UTC)
    ↓
LOAD ENVIRONMENT ← from /opt/gpti/docker/.env
    ↓
CONNECT TO DATABASE ← PostgreSQL 5434
    ↓
IDENTIFY MISSING ← SELECT ... WHERE score_0_100=50
    ↓
FOR EACH FIRM (227):
    ├─ FETCH HTML (30-60s)
    ├─ PARSE: name, address, leverage, licenses
    ├─ ANALYZE: Apply rules OR fallback to Ollama
    ├─ SCORE: Calculate pillar scores (1-5)
    ├─ UPDATE: PostgreSQL INSERT/UPDATE
    └─ LOG: Progress indicator
    ↓
ALL FIRMS PROCESSED
    ↓
GENERATE SNAPSHOT (JSON)
    ↓
UPLOAD TO MinIO (S3)
    ↓
UPDATE LATEST POINTER
    ↓
END (~22:25 UTC)
    ↓
API RETURNS LIVE DATA
    ↓
PAGES RE-RENDER
```

## 💾 Files Involved

```
INPUT:
  /opt/gpti/docker/.env                     ← Configuration
  /opt/gpti/gpti-data-bot/scripts/          ← Crawler scripts
  PostgreSQL (firms table)                  ← Target data
  Live firm websites                        ← HTML sources

PROCESSING:
  /opt/gpti/gpti-data-bot/src/gpti_bot/     ← Core logic
  /opt/gpti/tmp/crawl-optimized.log         ← Progress/errors
  Ollama (localhost:11434)                  ← Fallback LLM

OUTPUT:
  PostgreSQL (updated firms)                ← Enriched data
  MinIO (gtixt_snapshot_*.json)             ← Archive snapshot
  /opt/gpti/tmp/                            ← Working files
```

## 🎯 Next Checklist

- [x] Kill old process with outdated config
- [x] Create env startup script  
- [x] Apply SWAP (2GB emergency buffer)
- [x] Disable Playwright rendering
- [x] Set conservative page limits
- [x] Start optimized crawl process
- [ ] **MONITOR**: Watch for ~60 minutes
- [ ] Verify database enrichment (mid-crawl)
- [ ] Confirm snapshot generated
- [ ] Test API returns real scores
- [ ] Validate pages show live data
- [ ] Check coverage badge > 0%

---

**Crawl Status**: ✅ **RUNNING & OPTIMIZED**  
**Memory Usage**: 56.5 MB (excellent)  
**CPU Usage**: 2.1% (lean)  
**ETA Completion**: ~22:20 UTC (60 minutes)  
**Last Update**: 2026-02-19 21:20 UTC

**Monitor with**: `watch -n 5 'tail -20 /opt/gpti/tmp/crawl-optimized.log'`
