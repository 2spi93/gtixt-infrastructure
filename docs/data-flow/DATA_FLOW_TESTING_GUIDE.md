# 📊 GPTI Data Flow Testing Guide

## Overview

Ce guide documente le flux complet des données du système GPTI, de la source (seed data) jusqu'à l'affichage dans les pages frontend.

```
┌─────────────────────────────────────────────────────────────────┐
│                    DATA FLOW ARCHITECTURE                       │
├─────────────────────────────────────────────────────────────────┤
│                                                                 │
│  Seed Data (seed.json)                                          │
│      ↓                                                          │
│  Bots & Agents Processing                                      │
│      ├─ RVI (Registry Verification)                            │
│      ├─ SSS (Sanctions Screening)                              │
│      ├─ CRAWLER (Evidence collection)                          │
│      ├─ RVI (Registry Verification)                            │
│      ├─ SSS (Sanctions Screening)                              │
│      ├─ IIP (Integrity Index Project)                          │
│      ├─ MIS (Model Integrity Score)                            │
│      ├─ IRS (Institutional Readiness)                         │
│      ├─ REM (Regulatory Exposure)                              │
│      ├─ FRP (Future Risk Projection)                           │
│      └─ AGENT_C (Oversight Gate)                              │
│      ↓                                                          │
│  Data Storage                                                   │
│      ├─ MinIO (Object Storage - snapshots)                     │
│      ├─ PostgreSQL (Metrics & History)                         │
│      └─ Redis (Cache)                                          │
│      ↓                                                          │
│  Next.js API Routes (/pages/api)                               │
│      ├─ /api/health                                            │
│      ├─ /api/firms                                             │
│      ├─ /api/firm                                              │
│      ├─ /api/firm-history                                      │
│      ├─ /api/agents/status                                     │
│      ├─ /api/evidence                                          │
│      ├─ /api/events                                            │
│      ├─ /api/validation/metrics                                │
│      └─ /api/snapshots                                         │
│      ↓                                                          │
│  Frontend Pages                                                 │
│      ├─ /agents-dashboard (Agent Metrics)                      │
│      ├─ /phase2 (Validation Status)                            │
│      ├─ /firms (Firm List)                                     │
│      ├─ /firm/[id] (Firm Details)                              │
│      └─ /data (Data Explorer)                                  │
│      ↓                                                          │
│  React Components & UI Display                                 │
│                                                                 │
└─────────────────────────────────────────────────────────────────┘
```

---

## Test Suites Available

### 1. **Architecture Verification** (`run-integration-tests.sh`)
Vérifie la structure et la disponibilité de tous les composants.

```bash
cd /opt/gpti/gpti-site
bash tests/run-integration-tests.sh
```

**What it checks:**
- ✅ Seed data file (100 firms)
- ✅ Database connectivity
- ✅ API route files (9/9)
- ✅ Frontend pages (5/5)
- ✅ Data integration patterns
- ✅ Validation files

**Expected output:**
```
✅ Data Flow Verification Complete
- ✅ Seed data: 100 firms found
- ✅ API Routes: 9/9 routes found
- ✅ Frontend Pages: 5/5 pages found
- ✅ Data Integration: API calls found in pages
```

---

### 2. **E2E Runtime Tests** (`e2e-data-flow.sh`)
Teste les APIs en direct pendant que le serveur est en cours d'exécution.

```bash
# Terminal 1: Start dev server
npm run dev

# Terminal 2: Run E2E tests
bash tests/e2e-data-flow.sh
```

**What it tests:**
- ✅ Health endpoint (all services)
- ✅ Firms list loading
- ✅ Agent status retrieval
- ✅ Evidence data flow
- ✅ Validation metrics
- ✅ Events stream
- ✅ Page accessibility
- ✅ Data freshness

**Expected output:**
```
Testing Health endpoint ... ✅ OK (200)
Testing Firms endpoint ... ✅ OK (200)
Retrieved 100 firms from seed data
Testing Agent status endpoint ... ✅ OK (200)
Retrieved status for 9 agents
```

---

### 3. **Data Flow Debugger** (Browser UI)
Outil interactif pour inspecter les réponses API en temps réel.

```bash
npm run dev
# Open: http://localhost:3000/debug/data-flow
```

**Features:**
- 📋 Test individual endpoints
- 📊 View response data (JSON)
- ⏱️ Measure response times
- 🔄 Auto-refresh mode
- 📈 Summary table
- 🔍 Data flow diagram

**How to use:**
1. Click "Run All Tests" button
2. Select an endpoint from the list
3. View the response in the details panel
4. Check data structure and counts

---

### 4. **TypeScript Test Suite** (`data-flow.test.ts`)
Tests programmatiques des endpoints (pour CI/CD).

```bash
npm run test:data-flow
```

**Tests included:**
- Health Check
- Firms Endpoint
- Firm Details
- Firm History
- Snapshots
- Agents Status
- Evidence
- Events
- Validation Metrics
- Latest Pointer

---

## Data Sources & Flows

### Seed Data
**Location:** `/opt/gpti/gpti-data-bot/data/seeds/seed.json`
**Format:** Array of 100 firms

```json
[
  {
    "firm_name": "Topstep",
    "website": "https://www.topstep.com",
    "model_type": "FUTURES",
    "status": "candidate",
    "set_aside_reason": ""
  },
  ...
]
```

**Data Loading:**
```
seed.json → populate_data.py → MinIO/PostgreSQL
```

### Agent Processing
**Agents (9 total):**
1. **CRAWLER** (Web Crawler) - Public page collection (rules, pricing, legal, FAQ)
2. **RVI** (Registry Verification) - License verification
3. **SSS** (Sanctions Screening) - Watchlist matching
4. **REM** (Regulatory Events Monitor) - Regulatory actions monitoring
5. **IRS** (Independent Review System) - Submission/document validation
6. **FRP** (Firm Reputation & Payout) - Reputation and payout analysis
7. **MIS** (Manual Investigation System) - Anomaly investigations
8. **IIP** (IOSCO Implementation & Publication) - Compliance reporting
9. **AGENT_C** (Oversight Gate) - Final validation and snapshot approval

**Output:** Evidence data stored in MinIO

### API Endpoints

#### GET `/api/health`
**Purpose:** System health status
**Returns:** Service status (MinIO, Database, Frontend)

#### GET `/api/firms`
**Purpose:** List all firms with scores
**Query params:**
- `limit` (default: 100)
- `offset` (default: 0)
- `status` (filter by status)

**Returns:**
```json
{
  "success": true,
  "count": 100,
  "total": 100,
  "firms": [
    {
      "firm_id": "firm-1",
      "name": "Topstep",
      "website_root": "topstep.com",
      "score_0_100": 85,
      "pillar_scores": { ... }
    }
  ]
}
```

#### GET `/api/firm?id=X`
**Purpose:** Get single firm details
**Returns:** Detailed firm information with all metrics

#### GET `/api/agents/status`
**Purpose:** Agent metrics and readiness
**Returns:**
```json
{
  "agents": [ { "agent": "RVI", "status": "complete", ... } ],
  "totalAgents": 9,
  "completeAgents": 7,
  "productionReady": false
}
```

#### GET `/api/evidence?limit=10`
**Purpose:** Evidence data collected by agents
**Returns:** Array of evidence items with metadata

#### GET `/api/events?limit=10`
**Purpose:** Event stream
**Returns:** Timeline of events and status changes

#### GET `/api/validation/metrics`
**Purpose:** Validation pipeline metrics
**Returns:** Test passing rates, coverage, etc.

#### GET `/api/snapshots`
**Purpose:** Agent data snapshots
**Returns:** Timestamped snapshots of agent outputs

---

## Frontend Pages Integration

### `/agents-dashboard`
**Data consumed:**
- `/api/agents/status` → Agent metrics
- `/api/validation/metrics` → Test results

**Displays:**
- Agent status cards
- Evidence collection progress
- Test results

### `/phase2`
**Data consumed:**
- `/api/agents/status` → Agent readiness
- `/api/validation/metrics` → Validation progress

**Displays:**
- Validation status
- Agent completion
- Test suite results

### `/firms`
**Data consumed:**
- `/api/firms?limit=100` → Firm list

**Displays:**
- Searchable firm list
- Status badges
- Score indicators

### `/firm/[id]`
**Data consumed:**
- `/api/firm?id=[id]` → Firm details
- `/api/firm-history?id=[id]` → Historical data
- `/api/evidence?firm=[id]` → Evidence items

**Displays:**
- Firm details card
- Historical metrics
- Evidence timeline
- Agent results

### `/data`
**Data consumed:**
- `/api/firms` → All firms
- `/api/evidence` → All evidence
- `/api/events` → Event stream

**Displays:**
- Data explorer interface
- Real-time updates
- Export functionality

---

## Testing Checklist

### Pre-Flight Checks
- [ ] Seed data exists: `ls -la /opt/gpti/gpti-data-bot/data/seeds/seed.json`
- [ ] API routes exist: `ls -la /opt/gpti/gpti-site/pages/api/`
- [ ] Pages exist: `ls -la /opt/gpti/gpti-site/pages/{agents-dashboard,phase2,firms,firm,data}.tsx`

### Static Tests
```bash
bash tests/run-integration-tests.sh
```
- [ ] All checks pass
- [ ] 100 firms in seed data
- [ ] 9/9 API routes found
- [ ] 5/5 pages found

### Runtime Tests
```bash
npm run dev  # Terminal 1
bash tests/e2e-data-flow.sh  # Terminal 2
```
- [ ] Health check passes (200)
- [ ] All API endpoints respond (200)
- [ ] Data count > 0 for each endpoint
- [ ] Response times < 1000ms
- [ ] Pages load (200)

### Browser Tests
Navigate to `http://localhost:3000`:
- [ ] `/agents-dashboard` loads data
- [ ] `/phase2` shows validation status
- [ ] `/firms` shows firm list
- [ ] `/firm/1` shows firm details
- [ ] `/data` shows data explorer
- [ ] `/debug/data-flow` shows debugger

### Console Checks
Open DevTools (F12) → Console:
- [ ] No 404 errors
- [ ] No CORS errors
- [ ] No unhandled promise rejections
- [ ] API calls succeed

---

## Troubleshooting

### API Endpoints Return 503 (Service Unavailable)
**Issue:** Backend services not running
```bash
# Start services
docker-compose up -d postgres minio redis

# Populate data
npm run populate-data

# Start dev server
npm run dev
```

### Seed Data Not Loading
**Issue:** Seed file missing or invalid
```bash
# Check seed file
jq . /opt/gpti/gpti-data-bot/data/seeds/seed.json | head -20

# Repopulate
npm run populate-data
```

### CORS Errors
**Issue:** API URL mismatch
```bash
# Check API_URL in .env.local
cat .env.local | grep API_URL

# Should be: http://localhost:3000
```

### Blank Pages on Frontend
**Issue:** Data not fetching
1. Check browser console (F12)
2. Check network tab (XHR requests)
3. Verify API responses have data

```bash
# Quick debug from terminal
curl http://localhost:3000/api/firms | jq .
```

### High Response Times
**Issue:** Database or MinIO slow
1. Check database logs: `docker logs postgres`
2. Check MinIO logs: `docker logs minio`
3. Increase query limits in .env

---

## Performance Metrics

**Target response times:**
- Health check: < 100ms
- Firms list (100): < 500ms
- Agent status: < 200ms
- Evidence: < 300ms
- Validation metrics: < 200ms

**Monitor with:**
```bash
bash tests/e2e-data-flow.sh
# Look for duration values in output
```

---

## Next Steps

1. ✅ **Verify Architecture**: Run `bash tests/run-integration-tests.sh`
2. ✅ **Start Services**: `docker-compose up -d && npm run populate-data`
3. ✅ **Start Dev Server**: `npm run dev`
4. ✅ **Run E2E Tests**: `bash tests/e2e-data-flow.sh`
5. ✅ **Browse Debugger**: http://localhost:3000/debug/data-flow
6. ✅ **Check Pages**: Navigate to `/agents-dashboard`, `/firms`, etc.
7. ✅ **Monitor Console**: Check for errors in DevTools

---

## Generated: 2026-02-05

For issues or questions, check:
- `/opt/gpti/TEST_REPORT_*.md` - Latest test reports
- Browser DevTools Console - Runtime errors
- API response in network tab

