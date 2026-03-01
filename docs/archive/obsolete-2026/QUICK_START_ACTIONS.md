# 🚀 QUICK START: NEXT ACTIONS (5-30 MIN)

## ✅ WHAT'S DONE
- ✅ Snapshot rebuilt with 157 firms + verdicts
- ✅ Database synced (157 firm_profiles updated)
- ✅ API metrics fixed (98% Agent C pass rate)
- ✅ Audit trail showing real data (no "—" symbols)
- ✅ Complete system verification (no data loss)

---

## 📋 DO THIS NOW (Pick 1-2)

### Option 1: Archive Old Snapshot (5 min)
**Goal:** Prevent accidental rollback

```bash
cd /opt/gpti

# Move old snapshot to archive
mkdir -p archive/snapshots
mv /backup/minio/final_snapshot_20260223_041214Z.json archive/snapshots/DEPRECATED_final_snapshot_20260223_041214Z.json

# Verify latest.json points to NEW snapshot
curl -s http://localhost:9002/gpti-snapshots/universe_v0.1_public/_public/latest.json | jq '{object: .object, count: .count}'

# Expected output:
# {
#   "object": "20260223T121520.939041+0000_c86d411ef08e.json",
#   "count": 157
# }
```

---

### Option 2: Setup Auto-Sync (10 min)
**Goal:** Auto-sync new snapshots to DB every 30 min

```bash
# Create startup script
cat > /opt/gpti/start-auto-sync.sh << 'EOF'
#!/bin/bash
cd /opt/gpti
export DATABASE_URL="postgresql://gpti:superpassword@localhost:5434/gpti"
export MINIO_ENDPOINT="http://localhost:9002"
export MINIO_ACCESS_KEY="minioadmin"
export MINIO_SECRET_KEY="minioadmin123"

# Run in watch mode
python3 auto_sync_db_from_snapshot.py --watch --interval 30
EOF

chmod +x /opt/gpti/start-auto-sync.sh

# Start in background (terminal or systemd)
./start-auto-sync.sh &
# or
# systemctl start gpti-auto-sync (if configured as service)
```

---

### Option 3: Test Deduplication (15 min)
**Goal:** Understand which 19 firms are duplicated

```bash
psql postgresql://gpti:superpassword@localhost:5434/gpti << 'EOF'

-- Check which firms appear multiple times in snapshot
SELECT firm_id, COUNT(*) as duplicate_count
FROM jsonb_each((
  SELECT data FROM system_cache 
  WHERE key = 'snapshot_records'
)) AS records(firm_id, record_data)
GROUP BY firm_id
HAVING COUNT(*) > 1
ORDER BY duplicate_count DESC;

-- If no cache, get from MinIO snapshot
-- curl http://localhost:9002/gpti-snapshots/.../snapshot.json | jq '.records | group_by(.firm_id) | map(select(length > 1))'

EOF
```

---

### Option 4: Setup Monitoring (20 min)
**Goal:** Track metrics daily

```bash
cat > /opt/gpti/scripts/daily-monitor.sh << 'EOF'
#!/bin/bash

echo "=== Data Quality Monitor ===" >> /tmp/monitor.log
date >> /tmp/monitor.log

# 1. Check snapshot freshness
SNAPSHOT_AGE=$(curl -s http://localhost:9002/gpti-snapshots/universe_v0.1_public/_public/latest.json | jq -r '.created_at')
echo "Latest snapshot: $SNAPSHOT_AGE" >> /tmp/monitor.log

# 2. Check database sync
FIRMS_COUNT=$(psql -U gpti -d gpti -tc "SELECT COUNT(*) FROM firms;")
PROFILES_COUNT=$(psql -U gpti -d gpti -tc "SELECT COUNT(*) FROM firm_profiles WHERE oversight_gate_verdict IS NOT NULL;")
echo "DB: $FIRMS_COUNT firms, $PROFILES_COUNT with verdicts" >> /tmp/monitor.log

# 3. Check API metrics
PASS_RATE=$(curl -s http://localhost:3000/api/validation/snapshot-metrics | jq '.agent_c_pass_rate')
echo "Agent C pass rate: $PASS_RATE%" >> /tmp/monitor.log

# 4. Alert if issues
if [ "$FIRMS_COUNT" != "193" ] || [ "$PROFILES_COUNT" != "157" ]; then
    echo "⚠️  ALERT: Sync issue detected!" >> /tmp/monitor.log
    # Send alert (Slack/email)
fi

echo "" >> /tmp/monitor.log
EOF

chmod +x /opt/gpti/scripts/daily-monitor.sh

# Run daily at 3 AM
(crontab -l; echo "0 3 * * * /opt/gpti/scripts/daily-monitor.sh") | crontab -
```

---

## 🎯 THEN DO THIS (After picking 1-2 above)

### 1. Restart Next.js (1 min)
```bash
# If you made API changes, restart server
cd /opt/gpti/gpti-site
npm run build
npm run start &

# or if using systemctl
systemctl restart gpti-site
```

### 2. Verify Everything Works (5 min)
```bash
# Test 1: Can we see audit trail?
curl -s http://localhost:3000/api/firm/?id=akunacapitalcom | jq '.firm | {gtixt_status, oversight_gate_verdict, score_0_100}'

# Test 2: Are metrics correct?
curl -s http://localhost:3000/api/validation/snapshot-metrics | jq '{agent_c_pass_rate, total_firms}'

# Test 3: Is snapshot fresh?
curl -s http://localhost:9002/gpti-snapshots/universe_v0.1_public/_public/latest.json | jq '.created_at'

# All should show ✅ GREEN
```

### 3. Document Findings (5 min)
```bash
# Log today's changes
echo "$(date): Auto-sync started" >> /opt/gpti/DEPLOYMENT_LOG.md
echo "$(date): Snapshot archived" >> /opt/gpti/DEPLOYMENT_LOG.md
echo "$(date): Monitoring configured" >> /opt/gpti/DEPLOYMENT_LOG.md
```

---

## 📍 WHAT IF SOMETHING BREAKS?

**Snapshot stops updating:**
```bash
# Check MinIO connection
curl http://localhost:9002/gpti-snapshots/

# Re-run snapshot build
cd /opt/gpti
python3 rebuild_snapshot_with_verdicts.py

# Force re-sync
python3 auto_sync_db_from_snapshot.py
```

**Database not syncing:**
```bash
# Check logs
tail -50 /tmp/sync.log

# Manual sync with verbose output
DATABASE_URL="postgresql://gpti:superpassword@localhost:5434/gpti" python3 auto_sync_db_from_snapshot.py --verbose
```

**API shows wrong data:**
```bash
# Verify latest snapshot
curl -s http://localhost:3000/api/firm/?id=akunacapitalcom | jq .sha256

# Compare with MinIO
curl -s http://localhost:9002/gpti-snapshots/universe_v0.1_public/_public/latest.json | jq .sha256

# Should match ✅
```

---

## 📋 REFERENCE FILES

| File | Purpose |
|------|---------|
| `/opt/gpti/rebuild_snapshot_with_verdicts.py` | One-time rebuild (already done) |
| `/opt/gpti/auto_sync_db_from_snapshot.py` | Auto-sync script (use with --watch) |
| `/opt/gpti/RECOMMENDATIONS_ACTIONS_20260223.md` | Full recommendations |
| `/opt/gpti/AUDIT_SYNCHRONISATION_COMPLETE_20260223.md` | Sync verification report |
| `/opt/gpti/RESUME_COHERENCE_COMPTAGES_20260223.md` | Firm count explanation |

---

## ✅ SUCCESS CHECKLIST

After completing your chosen actions:

- [ ] Can you see audit trail data on firm pages? (No "—")
- [ ] Does API show `gtixt_status: "pass"` or `"controversial"`?
- [ ] Does validation dashboard show >95% Agent C pass rate?
- [ ] Does MinIO have active snapshot (157 firms)?
- [ ] Does database have 157 firm_profiles with verdicts?
- [ ] Can you see fresh timestamp on latest.json?

**All green? ✅ SYSTEM FULLY OPERATIONAL**

---

**Next: Pick one of the 4 Options above and run the commands. Ask if you need help!**

Generated: 2026-02-23 13:05 UTC
