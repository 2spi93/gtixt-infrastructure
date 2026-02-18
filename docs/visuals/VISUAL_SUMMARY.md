# 📈 GTIXT PROJECT - VISUAL SUMMARY & QUICK REFERENCE

## 🎯 Current State vs Desired State

### CURRENT STATE (❌ Incomplete)
```
User Journey:
┌─ /rankings ────────────────────────────────────────────┐
│ Displays: 56 firms in table                             │
│ Features: Sort, pagination, score bar                   │
│ Link: Click firm → /firm/[id]                          │
└────────────────────────────────────────────────────────┘
                          ↓
┌─ /firm/[id] ──────────────────────────────────────────┐
│ Displays:                                              │
│ ✅ Firm name + status badge                            │
│ ✅ Overall score (89/100)                              │
│ ✅ Link to website                                     │
│ ✅ AgentEvidence component (9 agents)                  │
│                                                        │
│ ❌ Missing:                                            │
│ • Pillar breakdown (5 scores: governance, fair...)     │
│ • Metric breakdown (6 scores: RVI, SSS, REM...)       │
│ • Evidence section (2 records per firm)                │
│ • Audit verdict + confidence                          │
│ • Historical trend chart                              │
│ • Data quality indicators (N/A rate)                  │
│ • Related firms recommendations                       │
└────────────────────────────────────────────────────────┘
```

### DESIRED STATE (✅ Complete)
```
User Journey:
┌─ /rankings ────────────────────────────────────────────┐
│ Displays: 56 firms in table                             │
│ Features: Sort, pagination, score bar, search           │
│ Link: Click firm → /firm/[id]                          │
└────────────────────────────────────────────────────────┘
                          ↓
┌─ /firm/[id] ──────────────────────────────────────────┐
│                                                        │
│ ✅ HEADER SECTION                                      │
│    Firm name, logo, status, website, jurisdiction     │
│                                                        │
│ ✅ SCORE OVERVIEW                                      │
│    Overall score (89/100), confidence (0.85)          │
│    Data quality (90% complete, 10% N/A)               │
│                                                        │
│ ✅ PILLAR BREAKDOWN                                    │
│    5 pillar scores with visualization:                │
│    • Governance: 48/100                               │
│    • Fair Dealing: 65/100                             │
│    • Market Integrity: 71/100                         │
│    • Regulatory Compliance: 31/100                    │
│    • Operational Resilience: 57/100                   │
│                                                        │
│ ✅ METRIC BREAKDOWN (6 AGENTS)                        │
│    6 metric scores from agent analysis:               │
│    • RVI (Reputation): 50/100                         │
│    • SSS (Systemic Stress): 36/100                    │
│    • REM (Risk Management): 47/100                    │
│    • IRS (Information Ready): 63/100                  │
│    • FRP (Financial Performance): 29/100              │
│    • MIS (Market Integrity): 50/100                   │
│                                                        │
│ ✅ EVIDENCE SECTION                                    │
│    Data sources supporting the score:                 │
│    ☑ Regulatory Status (FCA Register)                │
│    ☑ Reputation Score (Trustpilot)                   │
│    [View Details] [Download Evidence]                 │
│                                                        │
│ ✅ AUDIT VERDICT                                       │
│    Gate Verdict: PASS ✓                               │
│    Oversigh Status: Approved for Publication          │
│    Updated: 2026-02-05                                │
│                                                        │
│ ✅ HISTORICAL CHART                                    │
│    Score trend over time:                             │
│    2026-01-05: 87 → 2026-02-05: 89 (+2)              │
│    [Line chart showing trend]                         │
│                                                        │
│ ✅ RELATED FIRMS                                       │
│    Similar firms (score 88-90):                       │
│    • Firm A (89)  • Firm B (88)  • Firm C (90)       │
│                                                        │
│ ✅ AGENT EVIDENCE                                      │
│    Detailed evidence from 7 analysis agents           │
│                                                        │
└────────────────────────────────────────────────────────┘
```

---

## 🔄 Data Flow Architecture

### Current Flow
```
PostgreSQL (100 firms)
        ↓
export_snapshot.py (export to JSON)
        ↓
/data/test-snapshot.json (56 published firms)
        ↓
/api/firms ← reads local JSON
        ↓
Frontend /rankings ← displays list
        ↓
Click firm ↓
        ↓
/api/firm ← reads same JSON (limited data!)
        ↓
Frontend /firm/[id] ← displays basic profile
        ↓
❌ Missing: evidence, pillars, history, audit verdict
```

### Desired Flow
```
PostgreSQL (100 firms, 112 evidence, 1 snapshot)
        ↓
        ├─→ /api/firms
        │   • Query: firms + snapshot_scores (published only)
        │   • Return: 56 firms list
        │   ↓
        │   Frontend /rankings (displays list)
        │   ↓
        │   Click firm
        │   ↓
        └─→ /api/firm/:id
            • Query: firms
            •        + firm_profiles
            •        + snapshot_scores (latest)
            •        + agent_c_audit
            •        + evidence
            •        + snapshot_metadata (all for history)
            • Return: Complete FirmProfile object
            ↓
            Frontend /firm/[id] (displays full profile)
            ↓
            ✅ Shows: header, scores, pillars, metrics,
                     evidence, audit verdict, history,
                     related firms, confidence
```

---

## 📊 Database Query Mapping

### List Endpoint: /api/firms

**Query:**
```sql
SELECT f.*, ss.score_0_100, ss.confidence, ss.pillar_scores,
       ss.metric_scores, ss.na_rate
FROM firms f
JOIN snapshot_scores ss ON f.firm_id = ss.firm_id
JOIN agent_c_audit aca ON f.firm_id = aca.firm_id
WHERE aca.verdict = 'pass'
ORDER BY ss.score_0_100 DESC
LIMIT 50 OFFSET 0;
```

**Response:** 50 firms with scores

---

### Detail Endpoint: /api/firm/:id

**Query 1 - Get Firm + Profile + Latest Score:**
```sql
SELECT f.*, fp.executive_summary, fp.audit_verdict, 
       fp.oversight_gate_verdict, ss.score_0_100, ss.confidence,
       ss.na_rate, ss.pillar_scores, ss.metric_scores,
       aca.verdict, aca.confidence
FROM firms f
LEFT JOIN firm_profiles fp ON f.firm_id = fp.firm_id
LEFT JOIN snapshot_scores ss ON f.firm_id = ss.firm_id 
  AND ss.snapshot_id = (
    SELECT snapshot_id FROM snapshot_metadata 
    WHERE snapshot_key = 'snapshot-2026-02-05'
  )
LEFT JOIN agent_c_audit aca ON f.firm_id = aca.firm_id
WHERE f.firm_id = $1;
```

**Query 2 - Get Evidence:**
```sql
SELECT * FROM evidence WHERE firm_id = $1 ORDER BY created_at;
```

**Query 3 - Get History:**
```sql
SELECT sm.snapshot_key, sm.created_at, ss.score_0_100
FROM snapshot_metadata sm
JOIN snapshot_scores ss ON sm.snapshot_id = ss.snapshot_id
WHERE ss.firm_id = $1
ORDER BY sm.created_at DESC;
```

**Response:** Complete FirmProfile with evidence + history

---

## 🐛 Critical Bugs to Fix

### Bug #1: Query Parameter Mismatch
```
Profile page:  fetch(`/api/firm?firmId=${id}`)
API expects:   ?id=... or ?name=...
Result:        ❌ 400 Bad Request
Fix:           Add firmId support to API
```

### Bug #2: Missing Database Integration
```
Current:  /api/firm reads test-snapshot.json
Needed:   /api/firm queries PostgreSQL
Missing:  Evidence, profiles, audit verdict, history
Fix:      Add database queries to API
```

### Bug #3: Profile Page Incomplete
```
Current:  Shows only name, status, overall score
Needed:   All sections from "desired state" above
Missing:  Pillars, metrics, evidence, chart, related
Fix:      Add components and data binding
```

---

## 📁 File Structure Reference

```
Working:
├── /rankings.tsx ........................ ✅ Lists 56 firms
├── /api/firms.ts ....................... ✅ List endpoint
├── components/ScoreDistributionChart ✅ Chart working
└── components/AgentEvidence ........... ✅ Evidence viewer

Incomplete:
├── /firm/[id].tsx ...................... ⚠️ Profile page
├── /api/firm.ts ........................ ⚠️ Detail endpoint
└── components/(new) .................... ❌ Need to create:
    ├── PillarScoresChart
    ├── MetricsBreakdown
    ├── EvidenceSection
    ├── HistoricalChart
    ├── RelatedFirms
    └── ConfidenceIndicator
```

---

## 🎯 Implementation Priority

### P0 - CRITICAL (Must fix immediately)
1. Fix query parameter in profile page → `?id=` vs `?firmId=`
2. Add PostgreSQL integration to `/api/firm.ts`
3. Return evidence + audit verdict from API

### P1 - HIGH (Fix in Phase 1)
4. Add pillar scores visualization to profile
5. Add metrics breakdown to profile
6. Create evidence display section
7. Add data quality indicators

### P2 - MEDIUM (Implement Phase 2)
8. Add historical score tracking + chart
9. Implement related firms feature
10. Add detailed evidence modals

### P3 - LOW (Polish/Optimization)
11. Fix firm_id slugification
12. Set up MinIO snapshot management
13. Performance optimization
14. Advanced analytics

---

## 🔍 Quick Data Lookup

### Firm Example: Top One Trader
```
firm_id:              -op-ne-rader
name:                 Top One Trader
website:              https://toponetrader.com
status:               candidate
jurisdiction:         GB
fca_reference:        FCA123456

SCORE BREAKDOWN:
├─ Overall:           89/100 (confidence: 0.85)
├─ Governance:        48/100
├─ Fair Dealing:      65/100
├─ Market Integrity:  71/100
├─ Regulatory:        31/100
└─ Operational:       57/100

METRICS (6 AGENTS):
├─ RVI:  50/100 (Reputation)
├─ SSS:  36/100 (Systemic Stress)
├─ REM:  47/100 (Risk Management)
├─ IRS:  63/100 (Info Ready)
├─ FRP:  29/100 (Financial Performance)
└─ MIS:  50/100 (Market Integrity)

AUDIT:
├─ Verdict:           PASS ✓
├─ Gate Status:       Approved
├─ Updated:           2026-02-05
└─ Data Quality:      90% complete (10% N/A)

EVIDENCE (2 records):
├─ 1. Regulatory Status (FCA Register)
└─ 2. Reputation Score (Trustpilot: 4.5 stars)
```

---

## 🚀 Quick Fix Checklist

### Day 1
- [ ] Fix query parameter mismatch (5 min)
- [ ] Add firmId support to /api/firm.ts (10 min)
- [ ] Add PostgreSQL query to /api/firm.ts (30 min)
- [ ] Include evidence in API response (15 min)
- [ ] Test profile page loads (10 min)

### Day 2
- [ ] Create PillarScoresChart component (60 min)
- [ ] Create MetricsBreakdown component (60 min)
- [ ] Create EvidenceSection component (60 min)
- [ ] Integrate components in profile page (60 min)
- [ ] Style and responsive design (60 min)

### Day 3
- [ ] Add historical snapshots creation (60 min)
- [ ] Create HistoricalChart component (60 min)
- [ ] Implement related firms feature (60 min)
- [ ] Add confidence/quality indicators (30 min)
- [ ] Testing and bug fixes (60 min)

---

## 📞 Support References

**Database Connection:**
```
Host:     localhost (or production IP)
Port:     5432
Database: gpti_data
User:     postgres
Password: [env variable]
```

**API Endpoints:**
```
GET /api/firms?limit=50&offset=0&sort=score
GET /api/firm?id=firm-id
GET /api/firm?name=Firm Name
GET /api/firm-history?id=firm-id
```

**Test Data:**
- 100 total firms in database
- 56 published (verdict='pass')
- 44 in review (verdict='review')
- 112 evidence records
- 1 snapshot (2026-02-05)

---

**Created:** 2026-02-05  
**Version:** 1.0  
**Status:** Ready for Implementation
