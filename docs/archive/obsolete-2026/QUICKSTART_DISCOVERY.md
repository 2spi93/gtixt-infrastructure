## 🚀 GTIXT Discovery - Quick Start Commands

**Run these commands NOW to start discovery automated pipeline**

---

## Command 1: Quick Verification (2 minutes)
```bash
cd /opt/gpti/gpti-data-bot

# Verify discovery agent is ready
python3 -c "
import sys
sys.path.insert(0, 'src')
from gpti_bot.agents.market_discovery_agent import MarketDiscoveryAgent
agent = MarketDiscoveryAgent()
print('✅ Discovery Agent Ready')
"

# Check database connection
python3 -c "
import sys
sys.path.insert(0, 'src')
from gpti_bot.db import connect
try:
    with connect() as conn:
        cur = conn.cursor()
        cur.execute('SELECT COUNT(*) FROM firms')
        count = cur.fetchone()[0]
        print(f'✅ Database Ready: {count} firms in DB')
except Exception as e:
    print(f'❌ DB Error: {e}')
"
```

---

## Command 2: Run Discovery (5-10 minutes)
```bash
cd /opt/gpti/gpti-data-bot

# Run discovery with 10 max candidates (test)
python3 scripts/autonomous_pipeline.py --discovery --max-discoveries 10

# Expected output after 2-3 min:
# ✓ CySEC: 200 entities
# ✓ Raw discoveries: 300+
# ✓ Validated: 50+
# ✓ Inserted: 5-10 new firms
```

---

## Command 3: Verify Results (1 minute)
```bash
# Check newly inserted firms
psql $DATABASE_URL << 'SQL'
SELECT COUNT(*) as recent_count 
FROM firms 
WHERE created_at > NOW() - INTERVAL '10 minutes';

SELECT name, jurisdiction, created_at 
FROM firms 
WHERE created_at > NOW() - INTERVAL '10 minutes'
ORDER BY created_at DESC
LIMIT 10;
SQL
```

---

## Command 4: Setup Cron (2 minutes)
```bash
# Edit crontab
crontab -e

# Add this line (runs discovery every night at 3am UTC):
0 3 * * * cd /opt/gpti/gpti-data-bot && PYTHONPATH=/opt/gpti/gpti-data-bot/src python3 scripts/autonomous_pipeline.py --discovery --max-discoveries 50 2>&1 | tee -a /var/log/gtixt-discovery.log

# Save and exit (Ctrl+X in nano, :wq in vi)

# Verify cron is set
crontab -l
```

---

## Command 5: Monitor Cron Execution (Optional)
```bash
# Watch cron logs in real-time
tail -f /var/log/gtixt-discovery.log

# Or check last execution
tail -20 /var/log/gtixt-discovery.log | grep -E "(Starting|Complete|Inserted)"
```

---

## 📊 Full Automation Script (Copy-Paste Ready)
```bash
#!/bin/bash
# setup-gtixt-discovery.sh

set -e

echo "🚀 Setting up GTIXT Discovery Automation..."

# 1. Test agent loads
cd /opt/gpti/gpti-data-bot
python3 -c "
import sys
sys.path.insert(0, 'src')
from gpti_bot.agents.market_discovery_agent import MarketDiscoveryAgent
print('✅ Agent verified')
"

# 2. Run discovery test
echo "🔍 Running discovery test (10 firms)..."
python3 scripts/autonomous_pipeline.py --discovery --max-discoveries 10 | tee /tmp/discovery-test.log

# 3. Count results
INSERTED=$(grep "Inserted:" /tmp/discovery-test.log | tail -1 | grep -oE '[0-9]+' | head -1)
echo "✅ Test complete: $INSERTED new firms discovered"

# 4. Setup cron
echo "⏰ Setting up nightly discovery (3am UTC)..."
(crontab -l 2>/dev/null; echo "0 3 * * * cd /opt/gpti/gpti-data-bot && PYTHONPATH=/opt/gpti/gpti-data-bot/src python3 scripts/autonomous_pipeline.py --discovery --max-discoveries 50 2>&1 | tee -a /var/log/gtixt-discovery.log") | crontab -

# 5. Verify
echo "✅ Setup complete!"
echo ""
echo "Discovery status:"
echo "  - Agent: ✅ Ready"
echo "  - Recent run: ✅ $INSERTED firms"
echo "  - Cron job: ✅ Scheduled nightly at 3am UTC"
echo ""
echo "Next: Monitor /var/log/gtixt-discovery.log for results"
```

**To run**:
```bash
chmod +x setup-gtixt-discovery.sh
./setup-gtixt-discovery.sh
```

---

## 🎯 Daily Operations

### Check Discovery Status (Every morning)
```bash
# See last night's discoveries
tail -30 /var/log/gtixt-discovery.log | grep -E "(Starting|Complete|Inserted|Duration)"
```

### Manual Discovery Run (Anytime)
```bash
cd /opt/gpti/gpti-data-bot
python3 scripts/autonomous_pipeline.py --discovery --max-discoveries 30
```

### Disable/Enable Cron
```bash
# Disable
crontab -e  # Comment out the line with #

# Re-enable
crontab -e  # Uncomment the line
```

---

## 🔍 Troubleshooting

### Discovery returns 0 firms
```bash
# Check if DB connection works
psql $DATABASE_URL -c "SELECT 1;"

# Check if agent loads
python3 -c "from gpti_bot.agents.market_discovery_agent import MarketDiscoveryAgent; print('OK')"

# Run with verbose output
PYTHONPATH=/opt/gpti/gpti-data-bot/src python3 scripts/autonomous_pipeline.py --discovery --max-discoveries 5
```

### Cron job not running
```bash
# Check if cron daemon is running
systemctl status cron

# Check cron logs
sudo tail -50 /var/log/syslog | grep CRON

# Manually test cron environment
env -i HOME=$HOME /bin/sh -c 'cd /opt/gpti/gpti-data-bot && python3 scripts/autonomous_pipeline.py --discovery --max-discoveries 1'
```

### Database locked
```bash
# Check active connections
psql $DATABASE_URL -c "SELECT * FROM pg_stat_activity;"

# Kill long-running queries if needed
psql $DATABASE_URL -c "SELECT pg_terminate_backend(pid) FROM pg_stat_activity WHERE datname = 'gpti' AND query_start < NOW() - interval '30 minutes';"
```

---

## 📈 Expected Metrics (After 1 Week)

| Metric | Value | Status |
|--------|-------|--------|
| Daily discoveries | 5-10 | ✅ |
| Weekly total | 35-70 | ✅ |
| Database inserts | 5-20/week | ✅ |
| Cron success rate | 95%+ | ✅ |

---

## 🎓 Next Phase (After 1 week)

1. **Monitor & Optimize**
   - Review which regulatory sources return best candidates
   - Adjust max-discoveries based on DB growth

2. **Add Crawling**
   - Automatically crawl new discovered firms
   - Extract rules, payouts, terms

3. **Add Notifications**
   - Slack alerts on new discoveries
   - Daily summary reports

4. **Scale**
   - Multiple discovery agents in parallel
   - Geographic targeting

---

## 💬 Questions?

Check documentation:
- `/opt/gpti/DISCOVERY_TESTS_1_2_3_COMPLETE.md` - Test results
- `/opt/gpti/REALISTIC_DISCOVERY_PLAN.md` - Full strategy
- `/opt/gpti/PLAYWRIGHT_STRATEGIC_PIVOT.md` - Why certain approaches don't work

---

**Status**: 🟢 **Ready to Go**  
**Start time**: Now  
**Expected result**: 5-10 new firms by tomorrow + automated nightly discovery
