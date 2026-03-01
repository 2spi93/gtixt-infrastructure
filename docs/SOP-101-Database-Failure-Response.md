# SOP-101: Database Failure Response & Recovery Procedure
**GTIXT Standard Operating Procedure**

---

## Document Control

| **Property** | **Value** |
|--------------|-----------|
| **Document ID** | SOP-101 |
| **Title** | Database Failure Response & Recovery Procedure |
| **Version** | 1.0.0 |
| **Created** | February 26, 2026 |
| **Owner** | Tech Lead / Infrastructure Team |
| **Review Cycle** | Quarterly |
| **Classification** | INTERNAL - Operational |
| **RTO Target** | 2 hours |
| **RPO Target** | 24 hours |

---

## Purpose

This document describes the step-by-step procedure for responding to and recovering from a PostgreSQL database failure in the GTIXT production environment.

**Scope:** Production PostgreSQL database (gpti database on port 5434 via Docker container `gpti-postgres`)

**Expected Outcome:** Database restored to functional state with data loss limited to RPO target (24 hours maximum)

---

## Prerequisites

**Required Access:**
- Root/sudo access to production server
- Docker access
- Database credentials (stored in /opt/gpti/gpti-site/.env.local)

**Required Knowledge:**
- Basic SQL and PostgreSQL administration
- Docker container management
- Linux command line proficiency

**Required Tools:**
- Docker CLI
- psql (PostgreSQL client)
- Access to backup directory: `/var/lib/postgresql/backups/`

---

## Failure Detection

### Symptoms of Database Failure

1. **Application Error Messages:**
   - "Connection refused" errors from Next.js application
   - HTTP 500 errors on admin.gtixt.com
   - Database timeout errors in logs

2. **Infrastructure Alerts:**
   - Docker container status: Exited or Restarting
   - Port 5434 not responding
   - High memory/CPU usage followed by crash

3. **Manual Verification:**
   ```bash
   # Check if container is running
   sudo docker ps | grep gpti-postgres
   
   # Test database connectivity
   sudo docker exec gpti-postgres psql -U gpti -d gpti -c "SELECT 1;"
   ```

**If any of these checks fail → Proceed to Recovery Procedure**

---

## Recovery Procedure

### Phase 1: Incident Response (First 15 Minutes)

#### Step 1.1: Confirm Failure
```bash
# Check container status
sudo docker ps -a | grep gpti-postgres

# Check container logs (last 50 lines)
sudo docker logs --tail 50 gpti-postgres

# Attempt restart
sudo docker restart gpti-postgres

# Wait 30 seconds and recheck
sleep 30
sudo docker exec gpti-postgres psql -U gpti -d gpti -c "SELECT COUNT(*) FROM firms;"
```

**If restart successful → Monitor for 10 minutes → Document incident → END**  
**If restart fails → Continue to Step 1.2**

#### Step 1.2: Notify Stakeholders
```bash
# Send alert to team (example using internal notification system)
echo "ALERT: Database failure detected at $(date). Recovery in progress. ETA: 2 hours (RTO target)." | mail -s "CRITICAL: GTIXT DB Failure" team@gtixt.com
```

#### Step 1.3: Stop Application Server
```bash
# Stop Next.js to prevent further connection attempts
sudo systemctl stop gpti-site

# Verify stopped
systemctl status gpti-site
```

#### Step 1.4: Identify Latest Backup
```bash
# List available backups (sorted by date)
sudo ls -lht /var/lib/postgresql/backups/ | head -10

# Identify latest backup
LATEST_BACKUP=$(sudo ls -t /var/lib/postgresql/backups/gpti_backup_*.sql.gz | head -1)
echo "Latest backup: $LATEST_BACKUP"

# Verify backup integrity
sudo zcat "$LATEST_BACKUP" | head -10
sudo zcat "$LATEST_BACKUP" | tail -10

# Check backup size (should be > 10KB)
sudo du -h "$LATEST_BACKUP"
```

**Expected Output:** Backup file exists, is readable, contains SQL dump data

---

### Phase 2: Database Recovery (30-60 Minutes)

#### Step 2.1: Stop and Remove Failed Container
```bash
# Stop container
sudo docker stop gpti-postgres

# Remove container (data volume will persist)
sudo docker rm gpti-postgres

# List volumes to verify data volume exists
sudo docker volume ls | grep gpti
```

#### Step 2.2: Start Fresh Database Container
```bash
# Start new container with same configuration
sudo docker run -d \
  --name gpti-postgres \
  -e POSTGRES_USER=gpti \
  -e POSTGRES_PASSWORD=superpassword \
  -e POSTGRES_DB=gpti \
  -p 5434:5432 \
  -v gpti_postgres_data:/var/lib/postgresql/data \
  --restart unless-stopped \
  postgres:16

# Wait for database to initialize (30 seconds)
sleep 30

# Verify container is running
sudo docker ps | grep gpti-postgres

# Test connectivity
sudo docker exec gpti-postgres psql -U gpti -d gpti -c "SELECT 1;"
```

**If container fails to start → Check Docker logs → Escalate to DevOps**

#### Step 2.3: Restore from Backup
```bash
# Set backup file path
LATEST_BACKUP=$(sudo ls -t /var/lib/postgresql/backups/gpti_backup_*.sql.gz | head -1)
echo "Restoring from: $LATEST_BACKUP"

# Restore database from backup
sudo zcat "$LATEST_BACKUP" | sudo docker exec -i gpti-postgres psql -U gpti -d gpti

# Expected output: Many "CREATE TABLE", "ALTER TABLE", "COPY" statements
# Process takes 1-5 minutes depending on database size
```

**If errors occur:**
- "relation already exists" → Normal, continue
- "permission denied" → Check Docker container permissions
- "out of memory" → Check Docker resource limits

#### Step 2.4: Verify Restoration
```bash
# Count firms (should be ~227)
sudo docker exec gpti-postgres psql -U gpti -d gpti -c "SELECT COUNT(*) FROM firms;"

# Check other critical tables
sudo docker exec gpti-postgres psql -U gpti -d gpti -c "SELECT COUNT(*) FROM internal_users;"
sudo docker exec gpti-postgres psql -U gpti -d gpti -c "SELECT COUNT(*) FROM internal_sessions;"

# Verify sample data integrity
sudo docker exec gpti-postgres psql -U gpti -d gpti -c "SELECT name, country, website FROM firms LIMIT 5;"
```

**Expected Results:**
- firms: ~227 rows
- internal_users: 4+ rows
- Data looks valid (correct names, URLs)

---

### Phase 3: Application Recovery (15-30 Minutes)

#### Step 3.1: Restart Application Server
```bash
# Start Next.js application
sudo systemctl start gpti-site

# Monitor startup logs
sudo journalctl -u gpti-site -f

# Wait for "Ready" message (30-60 seconds)
```

#### Step 3.2: Verify Application Functionality
```bash
# Test health endpoint
curl -s http://localhost:3000/api/health

# Test login endpoint
curl -s -X POST "http://localhost:3000/api/internal/auth/login/" \
  -H "Content-Type: application/json" \
  -d '{"username":"founder","password":"FounderSecure2026$9x"}' | jq .

# Test public endpoints
curl -s -o /dev/null -w "Status: %{http_code}\n" https://admin.gtixt.com/admin/login/
```

**Expected Results:**
- Health endpoint returns 200
- Login returns token
- Admin pages load

#### Step 3.3: Functional Smoke Tests
```bash
# Test database read operations
curl -s "http://localhost:3000/api/firms?limit=5" | jq .

# Test dashboard stats
curl -s "http://localhost:3000/api/admin/dashboard-stats/" \
  -H "Authorization: Bearer [TOKEN]" | jq .
```

**If tests fail → Check application logs → Verify database schema**

---

### Phase 4: Post-Recovery Validation (15-30 Minutes)

#### Step 4.1: Calculate Data Loss Window
```bash
# Get backup timestamp from filename
LATEST_BACKUP=$(sudo ls -t /var/lib/postgresql/backups/gpti_backup_*.sql.gz | head -1)
BACKUP_TIME=$(echo "$LATEST_BACKUP" | grep -oP '\d{8}_\d{6}')
echo "Backup taken at: $BACKUP_TIME"

# Calculate data loss (current time - backup time)
# Manual calculation or use date command
```

**Document:** Time of failure, backup timestamp, data loss window (should be < 24 hours)

#### Step 4.2: Notify Stakeholders of Recovery
```bash
# Send recovery notification
echo "RESOLVED: Database restored at $(date). Data loss: [X] hours. All systems operational." | mail -s "RESOLVED: GTIXT DB Recovery Complete" team@gtixt.com
```

#### Step 4.3: Schedule Post-Mortem
- Schedule incident review meeting (within 48 hours)
- Prepare timeline of events
- Document lessons learned
- Identify preventive measures

---

## Recovery Time Metrics

**Target RTO:** 2 hours  
**Actual Recovery Time:** [To be recorded during incident]

| **Phase** | **Target Time** | **Actual Time** |
|-----------|----------------|-----------------|
| Phase 1: Incident Response | 15 min | ___ |
| Phase 2: Database Recovery | 60 min | ___ |
| Phase 3: Application Recovery | 30 min | ___ |
| Phase 4: Post-Recovery | 15 min | ___ |
| **TOTAL** | **120 min** | **___** |

---

## Data Loss Metrics

**Target RPO:** 24 hours  
**Actual Data Loss:** [To be recorded during incident]

**Backup Schedule:** Daily at 2:00 AM UTC  
**Maximum Loss Window:** 24 hours (if failure occurs just before next backup)  
**Typical Loss Window:** 12 hours (assuming random failure time)

---

## Troubleshooting Guide

### Issue: Container won't start
**Symptoms:** `docker run` fails or container exits immediately  
**Solutions:**
1. Check Docker logs: `sudo docker logs gpti-postgres`
2. Verify port 5434 is available: `sudo lsof -i :5434`
3. Check disk space: `df -h`
4. Verify Docker volume exists: `sudo docker volume ls`

### Issue: Backup file corrupted
**Symptoms:** `zcat` fails or SQL restore errors  
**Solutions:**
1. Try previous backup: `sudo ls -t /var/lib/postgresql/backups/ | head -5`
2. Verify backup integrity: `sudo zcat [backup] | head -100`
3. Contact DevOps if all backups corrupted

### Issue: Restore successful but data missing
**Symptoms:** Table counts lower than expected  
**Solutions:**
1. Document exactly what data is missing
2. Check if data was added after backup time (RPO window)
3. Contact users to re-enter recent data if necessary

### Issue: Application can't connect after recovery
**Symptoms:** "Connection refused" errors persist  
**Solutions:**
1. Verify database is actually running: `sudo docker ps`
2. Test connectivity manually: `sudo docker exec gpti-postgres psql -U gpti -d gpti -c "SELECT 1;"`
3. Check application environment variables (.env.local)
4. Verify port forwarding: `sudo lsof -i :5434`
5. Restart application: `sudo systemctl restart gpti-site`

---

## Prevention & Monitoring

### Proactive Measures
1. **Daily Backup Verification:**
   - Automated: Cron job runs daily at 2:00 AM
   - Manual check: `sudo ls -lh /var/lib/postgresql/backups/`
   - Verify latest backup < 24 hours old

2. **Database Health Monitoring:**
   - Container status checks
   - Disk space monitoring
   - Query performance tracking
   - Error log review

3. **Regular Recovery Testing:**
   - Quarterly: Restore backup to staging environment
   - Verify RTO can be achieved
   - Update procedure based on lessons learned

### Alert Configuration (Future Enhancement)
- PagerDuty integration for container failures
- Disk space alerts (< 10GB free)
- Backup failure notifications
- Application connection error spikes

---

## Escalation Path

| **Severity** | **Contact** | **Response Time** |
|-------------|-------------|-------------------|
| P0 (Production down) | Tech Lead | 15 minutes |
| P1 (Degraded service) | DevOps Team | 1 hour |
| P2 (Backup failure) | Infrastructure | 4 hours |

**After Hours:** Contact on-call engineer via PagerDuty (to be configured)

---

## Document Revision History

| **Version** | **Date** | **Author** | **Changes** |
|------------|----------|------------|-------------|
| 1.0.0 | Feb 26, 2026 | Chief Operational Agent | Initial creation |

---

## Approval

| **Role** | **Name** | **Signature** | **Date** |
|----------|----------|---------------|----------|
| Tech Lead | [Name] | _______________ | ________ |
| DevOps Lead | [Name] | _______________ | ________ |
| Founder/CEO | [Name] | _______________ | ________ |

---

**END OF DOCUMENT**

*For questions or updates to this SOP, contact: Tech Lead or Infrastructure Team*
