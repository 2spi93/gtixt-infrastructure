# GTIXT Institutional Governance Framework

**Version:** 1.0.0
**Effective Date:** 2025-02-24
**Last Updated:** 2025-02-24
**Status:** Active

---

## Table of Contents

1. [Governance Structure](#governance-structure)
2. [Methodology Committee](#methodology-committee)
3. [Review Processes](#review-processes)
4. [Error Correction Policy](#error-correction-policy)
5. [Firm Retraction Policy](#firm-retraction-policy)
6. [Contestation Policy](#contestation-policy)
7. [Transparency Policy](#transparency-policy)
8. [Change Management](#change-management)

---

## 1. Governance Structure

### 1.1 Organizational Hierarchy

```
GTIXT Governance Board
    ├── Methodology Committee (policy & scoring rules)
    ├── Technical Committee (infrastructure & security)
    ├── Compliance Officer (regulatory adherence)
    └── Community Advisory Panel (stakeholder input)
```

### 1.2 Roles & Responsibilities

| Role | Responsibilities | Authority Level |
|------|------------------|-----------------|
| **Chief Methodology Officer** | Overall methodology direction | Final decision on methodology |
| **Senior Quantitative Analyst** | Scoring model development | Methodology proposals |
| **Domain Expert (Prop Trading)** | Industry expertise validation | Advisory |
| **External Academic Advisor** | Independent review | Advisory |
| **Compliance Officer** | Regulatory compliance | Veto on compliance issues |
| **Technical Lead** | Infrastructure & security | Technical implementation |

---

## 2. Methodology Committee

### 2.1 Committee Composition

**Core Members (5):**
1. **Chief Methodology Officer** - Chairperson
   - PhD in Quantitative Finance or related field
   - 10+ years industry experience
   - Final vote in case of tie

2. **Senior Quantitative Analyst**
   - PhD or Master's in Statistics/Economics
   - 5+ years in quantitative analysis
   - Voting member

3. **Prop Trading Domain Expert**
   - 15+ years prop trading experience
   - Former senior executive at tier-1 firm
   - Voting member

4. **External Academic Advisor**
   - Professor at accredited university
   - Published research in finance/economics
   - Independent, no conflicts of interest
   - Voting member

5. **Compliance Officer**
   - Legal/compliance background
   - Regulatory expertise (SEC, FINRA, etc.)
   - Voting member

**Advisory Members (non-voting):**
- Technical Lead
- Community representatives (2)

### 2.2 Committee Meetings

**Regular Meetings:**
- **Frequency:** Quarterly (at minimum)
- **Duration:** 2-3 hours
- **Format:** Video conference + in-person (annually)
- **Schedule:** 
  - Q1: March (methodology review)
  - Q2: June (mid-year assessment)
  - Q3: September (specification updates planning)
  - Q4: December (year-end review + next year planning)

**Emergency Meetings:**
- Called within 48 hours for critical issues
- Quorum: 3/5 members minimum
- Decision authority: Same as regular meetings

### 2.3 Decision Making Process

**Voting Rules:**
- Simple majority (3/5) for routine decisions
- Supermajority (4/5) for:
  - Major methodology changes
  - Specification version updates
  - Firm retraction appeals
- Unanimous (5/5) for:
  - Fundamental scoring model changes
  - Data source removal

**Chairperson Tie-Breaking:**
- In case of 2-2 vote (with 1 abstention), Chairperson has deciding vote

**Conflict of Interest:**
- Member must recuse from vote if conflict exists
- Quorum recalculated excluding recused member

---

## 3. Review Processes

### 3.1 Quarterly Methodology Review

**Scope:**
1. Review all published scores from previous quarter
2. Analyze anomalies and outliers
3. Assess user feedback and complaints
4. Evaluate new data sources
5. Review error log and corrections

**Process:**
```
Week 1: Data collection and preparation
Week 2: Committee review of materials
Week 3: Committee meeting and discussion
Week 4: Decision publication and implementation planning
```

**Deliverables:**
- Quarterly review report (public)
- Proposed changes (if any)
- Implementation timeline
- Public minutes (summary)

### 3.2 Annual Comprehensive Review

**Scope:**
1. Full methodology audit
2. Specification version assessment
3. Competitor analysis
4. Academic research review
5. Stakeholder survey results

**Timeline:**
- Starts: November 1st
- Committee decision: December 31st
- Publication: January 15th
- Implementation: Q1 following year

**Deliverables:**
- Annual methodology report (40-60 pages)
- Next year roadmap
- Specification v2.0 (if major changes)

---

## 4. Error Correction Policy

### 4.1 Error Classification

| Severity | Definition | Response Time | Notification |
|----------|-----------|---------------|--------------|
| **Critical** | Score impact > 5 points OR affects > 10 firms | 24 hours | Immediate |
| **Major** | Score impact 1-5 points OR affects 3-10 firms | 48 hours | Within 24h |
| **Minor** | Metadata only OR affects < 3 firms | 1 week | Next business day |

### 4.2 Error Detection

**Sources:**
- Automated validation checks (daily)
- User reports (via support@gtixt.com)
- Internal audits (monthly)
- External audits (annual)
- Committee review (quarterly)

**Automated Checks:**
```python
# Daily validation
- Score range validation (0-100)
- Pillar sum consistency
- Hash verification
- Provenance completeness
- Outlier detection (> 3 std deviations)
```

### 4.3 Error Correction Workflow

```
1. ERROR DETECTED
   ↓
2. TRIAGE (classify severity)
   ↓
3. INVESTIGATION (root cause analysis)
   ↓ (within response time SLA)
4. CORRECTION PROPOSAL
   ↓
5. COMMITTEE REVIEW (for Critical/Major)
   ↓
6. CORRECTION IMPLEMENTATION
   ↓
7. USER NOTIFICATION
   ↓
8. POST-MORTEM PUBLICATION
```

**Example:**

```markdown
## Error Correction Notice - 2025-02-24-001

### Error Details
- **Detected:** 2025-02-24 09:00 UTC
- **Severity:** Major
- **Affected Firms:** 5 firms
- **Score Impact:** 1.2 - 3.8 points

### Root Cause
Evidence extraction script v1.2.3 had regex bug that misclassified certain regulatory filings.

### Correction
- Script fixed in v1.2.4
- All affected firms re-scored
- New snapshots published

### Affected Snapshots
- firm_abc: snapshot_123 → snapshot_124
- firm_def: snapshot_125 → snapshot_126
[...]

### Timeline
- Detection: 2025-02-24 09:00 UTC
- Investigation complete: 2025-02-24 11:30 UTC
- Correction applied: 2025-02-24 14:00 UTC
- Notification sent: 2025-02-24 14:15 UTC

### Preventive Measures
1. Add unit test for this regex case
2. Increase evidence review sampling rate to 20%
3. Add automated alert for classification rate changes > 5%

### Post-Mortem
Published at: https://gtixt.com/governance/postmortem/2025-02-24-001
```

### 4.4 User Notification

**Critical Errors:**
- Email to all API users immediately
- Status page banner
- Twitter/LinkedIn announcement
- Individual notification to affected firms

**Major Errors:**
- Email to affected API users within 24h
- Status page update
- Changelog entry

**Minor Errors:**
- Changelog entry
- Next monthly newsletter

---

## 5. Firm Retraction Policy

### 5.1 Retraction Criteria

A firm may be retracted from the index if:

1. **Firm Closure/Liquidation**
   - Firm ceased operations
   - Filed for bankruptcy
   - Regulatory shutdown

2. **Data Insufficiency**
   - < 3 independent data sources
   - < 5 pieces of evidence total
   - Evidence age > 24 months

3. **Eligibility Criteria Not Met**
   - Not a proprietary trading firm
   - < $10M in capital
   - < 2 years of operation

4. **Legitimate Contestation**
   - Firm provided proof of material errors
   - Committee voted to accept contestation
   - No viable correction possible

5. **Data Quality Issues**
   - Evidence found to be fraudulent
   - Persistent validation failures
   - Irreconcilable conflicts in sources

### 5.2 Retraction Process

```
1. RETRACTION TRIGGER
   ↓
2. INVESTIGATION (7 days)
   ↓
3. FIRM NOTIFICATION (if applicable)
   ↓ (firm has 14 days to respond)
4. COMMITTEE REVIEW (30 days max)
   ↓
5. VOTE (majority required)
   ↓
6. RETRACTION DECISION
   ↓
7. IMPLEMENTATION (status → "retracted")
   ↓
8. PUBLIC ANNOUNCEMENT
```

### 5.3 Retraction Implementation

**Technical:**
```typescript
// Snapshot NOT deleted, only status changed
interface RetractedSnapshot {
  status: "retracted";
  retraction: {
    retracted_at: "2025-02-24T14:00:00Z";
    retracted_by: "committee";
    reason: "firm_closure";
    decision_id: "committee_decision_2025_02_001";
  };
}
```

**API Behavior:**
- `/api/snapshots/latest`: Excludes retracted firms
- `/api/snapshots/history?firm_id=X`: Shows all, with status
- `/api/evidence/firm_id`: Returns 404 with retraction notice

**Communication:**
```markdown
## Firm Retraction Notice

**Firm:** ABC Capital Partners
**Firm ID:** abc_capital
**Retraction Date:** 2025-02-24
**Reason:** Firm ceased operations (confirmed liquidation)

**Historical Data:**
All historical snapshots remain accessible via API for research purposes.
Snapshots are marked as "retracted" and excluded from current index.

**Committee Decision:** #2025-02-001
Minutes: https://gtixt.com/governance/minutes/2025-02-001
```

### 5.4 Archive Policy

**Retracted firm data:**
- Kept indefinitely (minimum 10 years)
- Clearly marked as retracted
- Accessible via API with explicit filters
- Not included in aggregated statistics
- Referenced in governance records

---

## 6. Contestation Policy

### 6.1 Who Can Contest

**Eligible Parties:**
1. Firm being evaluated (direct interest)
2. Institutional investor (professional use of data)
3. Regulatory authority (compliance concern)
4. Academic researcher (methodology concern)

**Non-Eligible:**
- Individual retail investors
- Competitors acting in bad faith
- Anonymous submissions

### 6.2 Contestation Grounds

**Valid Grounds:**
1. **Factual Error**
   - Evidence is demonstrably false
   - Source misattributed
   - Data incorrectly extracted

2. **Methodological Error**
   - Rules misapplied
   - Calculation error
   - Specification not followed

3. **Eligibility Error**
   - Firm should not be in index
   - Firm should be in index but isn't

4. **Procedural Error**
   - Governance process not followed
   - Decision made without proper authority

**Invalid Grounds:**
- Disagreement with methodology itself
- Preference for different weighting
- General dissatisfaction with score
- Competitive concerns

### 6.3 Contestation Process

**Step 1: Submission**
- Email: contestation@gtixt.com
- Required information:
  ```
  - Your name and organization
  - Firm ID being contested
  - Snapshot ID (if specific snapshot)
  - Ground for contestation
  - Detailed reasoning
  - Supporting evidence (documents, links)
  - Requested outcome
  ```

**Step 2: Acknowledgment**
- Automatic acknowledg within 24 hours
- Case number assigned
- Expected timeline communicated

**Step 3: Initial Review (5 business days)**
- Compliance check (eligible party?)
- Completeness check (sufficient information?)
- Categorization (valid ground?)
- Decision: Accept for investigation OR Reject

**Step 4: Investigation (30 days max)**
```
Week 1: Evidence gathering
Week 2: Analysis and verification
Week 3: Committee review
Week 4: Decision drafting
```

**Step 5: Committee Decision**
- Vote required (majority)
- Decision must be:
  - In writing
  - Reasoned
  - Include proposed remedy (if accepted)

**Step 6: Notification**
- Submitter notified within 48h of decision
- Public record published (may be anonymized)

### 6.4 Possible Outcomes

| Outcome | Definition | Action |
|---------|-----------|--------|
| **Accepted** | Contestation valid, error confirmed | Correction applied, apology issued |
| **Partially Accepted** | Some points valid, some not | Partial correction |
| **Rejected** | No error found, methodology correct | No change, reasoning provided |
| **Withdrawn** | Submitter withdraws before decision | Case closed |

### 6.5 Fee Structure

**Purpose:** Prevent spam and frivolous contestations

| Party Type | Fee | Refund Policy |
|------------|-----|---------------|
| Firm being evaluated | $0 | N/A |
| Institutional investor | $500 | Full refund if accepted/partially accepted |
| Academic | $0 | N/A |
| Other parties | $1,000 | Full refund if accepted, 50% if partially accepted |

**Fee waiver:**
- Available for demonstrated financial hardship
- Request must be made in writing
- Approved by Compliance Officer

### 6.6 Appeal Process

If contestation rejected:
- One appeal allowed (within 30 days)
- Must present new evidence not in original submission
- Reviewed by different committee member
- Final decision (no further appeals)

---

## 7. Transparency Policy

### 7.1 Public Disclosures

**Published Quarterly:**
1. **Governance Report**
   - Committee decisions summary
   - Error corrections list
   - Contestations received and outcomes
   - Methodology changes proposed/implemented

2. **Usage Statistics**
   - API request volume
   - Active API keys
   - Most queried firms
   - Geographic distribution

3. **Incident Report**
   - Service uptime
   - Incidents and resolutions
   - Performance metrics
   - Security events (if any)

4. **Committee Minutes** (summarized)
   - Decisions made
   - Vote tallies
   - Key discussion points
   - Rationale for decisions

**Published Annually:**
1. **Comprehensive Methodology Report**
   - Full scoring methodology
   - Data sources detailed
   - Validation procedures
   - Quality control measures

2. **Financial Report** (if applicable)
   - Revenue sources
   - Operating expenses
   - Independence verification

3. **Audit Results**
   - External audit findings
   - Compliance certifications
   - Security assessments

### 7.2 Open Data Policy

**Publicly Available (no authentication):**
- Historical scores (> 6 months old)
- Methodology documentation
- Governance policies
- Committee decisions (summaries)
- Error corrections and retractions

**API Access (free tier):**
- Latest scores (up to 50 requests/day)
- Historical snapshots
- Specification documents
- Validation tools

**Premium API Access:**
- Real-time updates
- Higher rate limits
- Webhook notifications
- Bulk exports

### 7.3 Code Transparency

**Open Source Components:**
- Scoring calculation engine (business logic)
- Validation rules
- Hash computation
- SDK client libraries

**Proprietary Components:**
- Data collection crawlers (anti-gaming)
- LLM prompts (anti-gaming)
- Specific heuristics (competitive advantage)

**Reproducibility:**
- All code tagged with version
- Docker containers for exact environment
- Dependency lock files published
- Scoring can be reproduced with published spec

---

## 8. Change Management

### 8.1 Change Types

| Type | Definition | Approval | Notice |
|------|-----------|----------|--------|
| **Patch** | Bug fix, no methodology impact | Tech Lead | 24 hours |
| **Minor** | New data source, backward compatible | Committee majority | 30 days |
| **Major** | Methodology change, breaking | Committee supermajority | 90 days |
| **Critical** | Emergency security/compliance | Compliance Officer | Immediate |

### 8.2 Change Proposal Process

**Step 1: Proposal Submission**
- Submitted by: Any committee member or stakeholder
- Format: Written proposal (template provided)
- Contents:
  - Change rationale
  - Expected impact
  - Implementation plan
  - Rollback plan

**Step 2: Impact Assessment (7 days)**
- Technical feasibility
- Methodology impact
- User impact
- Compliance implications
- Cost/benefit analysis

**Step 3: Committee Review (14 days)**
- Proposal distributed to all members
- Questions and discussion
- Revisions if needed

**Step 4: Vote**
- Scheduled committee meeting
- Discussion of proposal
- Vote (type-dependent majority)
- Decision recorded

**Step 5: Implementation Planning**
- Timeline defined
- Resources allocated
- Communication plan
- Rollback triggers

**Step 6: Announcement**
- Posted to changelog
- Email to API users
- Status page
- Social media

**Step 7: Implementation**
- Staged rollout
- Monitoring
- Feedback collection

**Step 8: Post-Implementation Review**
- Assess impact
- Gather feedback
- Document lessons learned

### 8.3 Emergency Changes

**Triggers:**
- Critical security vulnerability
- Regulatory compliance requirement
- Data quality crisis
- System outage

**Process:**
```
1. Compliance Officer authorizes emergency change
2. Technical Lead implements immediately
3. Committee notified within 24h
4. Retroactive review in next committee meeting
5. Public announcement within 48h
```

---

## 9. Stakeholder Engagement

### 9.1 Community Advisory Panel

**Purpose:** Gather input from diverse stakeholders

**Members:**
- 2 prop trading firm representatives
- 2 institutional investor representatives
- 2 academic representatives
- 2 technology/data science representatives

**Meetings:** Semi-annually

**Role:** Advisory (non-voting)

### 9.2 Public Comment Periods

**When:**
- Major methodology changes
- Specification version updates
- Governance policy changes

**Duration:** 30-45 days

**Process:**
1. Proposal published
2. Comment period opens
3. Comments reviewed by committee
4. Response document published
5. Final decision incorporating feedback

---

## 10. Compliance & Audits

### 10.1 Internal Audits

**Frequency:** Monthly
**Scope:**
- Data quality checks
- Calculation verification
- Provenance completeness
- Hash integrity

**Auditor:** Technical Lead
**Report:** Quarterly to committee

### 10.2 External Audits

**Frequency:** Annual
**Scope:**
- Methodology compliance
- Data accuracy
- Governance adherence
- Security assessment

**Auditor:** Independent third-party firm
**Report:** Public summary published

### 10.3 Compliance Certifications

**Target Certifications:**
- SOC 2 Type II (security, availability)
- ISO 27001 (information security)
- Custom methodology attestation

---

## Appendix A: Contact Information

| Purpose | Contact |
|---------|---------|
| General governance questions | governance@gtixt.com |
| Error reports | errors@gtixt.com |
| Contestations | contestation@gtixt.com |
| Methodology questions | methodology@gtixt.com |
| Press inquiries | press@gtixt.com |

---

## Appendix B: Document History

| Version | Date | Changes | Approved By |
|---------|------|---------|-------------|
| 1.0.0 | 2025-02-24 | Initial governance framework | Committee |

---

**Next Review:** 2025-05-24 (Quarterly)
**Document Owner:** Chief Methodology Officer
