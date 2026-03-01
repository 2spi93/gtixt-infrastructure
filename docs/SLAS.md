# GTIXT API SLAs and Guarantees

**Version:** 1.0.0
**Effective Date:** 2025-02-01
**Last Updated:** 2025-02-23

---

## Executive Summary

GTIXT commits to institutional-grade SLAs for the GTIXT Global Proprietary Trading Index API:

| Metric | Commitment | SLA |
|--------|------------|-----|
| **Availability** | Uptime | 99.9% (8.76 hours/month downtime) |
| **Response Time (p50)** | Median latency | < 200ms |
| **Response Time (p95)** | 95th percentile | < 500ms |
| **Response Time (p99)** | 99th percentile | < 1000ms |
| **Data Accuracy** | Score correctness | 100% (cryptographically verified) |
| **Rate Limiting** | Throughput per key | 1,000 req/min (burst: 10,000/s) |
| **Data Retention** | Historical data | 7 years (audit trail) |
| **Consistency** | Determinism | Same inputs = same score |

---

## 1. Availability SLA

### 99.9% Uptime Guarantee

**Definition:** API is available when ≥ 99.9% of requests complete successfully (HTTP 200-299, not 5xx or timeout)

**Monthly Allowance:**
- 30-day month: 43,200 seconds downtime (8.76 hours)
- Measured per calendar month
- Excludes scheduled maintenance windows (announced 7 days in advance)

### Uptime Status Page
- Real-time status: https://status.gtixt.com
- Incident notifications: status@gtixt.com
- Historical uptime: https://status.gtixt.com/history

### Scheduled Maintenance
- **Window:** Sundays 22:00-23:30 UTC
- **Frequency:** Weekly (typically one hour or less)
- **Advance Notice:** 7 days via status page
- **Expected Duration:** 15-30 minutes
- **Count:** Does NOT count against SLA

### Emergency Maintenance
- **Scope:** Critical security or data integrity issues only
- **Notice:** Minimum 1 hour advance notification (when possible)
- **Frequency:** < 2 times per quarter
- **SLA Impact:** Excluded from uptime calculation

### Incident Response Times

| Severity | Response Time | Resolution Target |
|----------|---------------|--------------------|
| Critical (all requests failing) | 5 minutes | 1 hour |
| Major (> 50% requests failing) | 15 minutes | 4 hours |
| Minor (> 10% requests failing) | 1 hour | 8 hours |
| Degraded (elevated latency only) | 4 hours | 24 hours |

---

## 2. Response Time SLA

### Latency Targets

```
p50 (median):    < 200ms  (50% of requests faster)
p90 (90th tile): < 400ms  (90% of requests faster)
p95 (95th tile): < 500ms  (95% of requests faster)
p99 (99th tile): < 1000ms (99% of requests faster)
```

### Measured From
- Request accepted by API load balancer
- To response first byte sent to client
- Excludes network transit time
- Excludes client-side processing

### Per-Endpoint Targets

| Endpoint | p50 | p95 | p99 |
|----------|-----|-----|-----|
| GET /snapshots/latest | 100ms | 250ms | 500ms |
| GET /snapshots/history | 150ms | 350ms | 700ms |
| GET /evidence/{firm_id} | 120ms | 300ms | 600ms |
| GET /specification | 50ms | 100ms | 200ms |
| POST /verify_score | 300ms | 600ms | 1200ms |
| POST /audit_export | 500ms | 1000ms | 2000ms |

### Monitoring

- Real-time metrics: https://metrics.gtixt.com
- Weekly performance report: emailed Mondays
- Monthly SLA report: dashboard.gtixt.com/reports

### Latency Credits

If we fail to meet SLA benchmarks two consecutive months:

| p95 Actual | % Credit |
|-----------|----------|
| 500-750ms | 5% |
| 750-1000ms | 10% |
| > 1000ms | 25% |

Applies to next month's invoice

---

## 3. Data Accuracy & Integrity SLA

### Score Correctness: 100%

**Guarantee:** Every published score can be independently verified as correct

**Verification Method:**
1. Consumer downloads evidence for firm + date
2. Applies specification rules
3. Computes score
4. Compares result (must match exact GTIXT score)

**Verification Proof:**
- SHA-256 hash of (evidence + specification reference) = reported_hash
- If hash doesn't match: GTIXT reimburses (see credit policy below)

### Evidence Completeness: 100%

**Guarantee:** All evidence used in score is provided via `/api/evidence` endpoint

**Verification:**
- Call `/api/verify_score` with provided evidence
- reproducibility_verification.evidence_complete must be true
- If false: Contact support for investigation

### Rule Application: 100%

**Guarantee:** Scoring rules applied consistently and correctly

**Verification:**
- reproducibility_verification.rule_application_correct must be true
- If false: GTIXT commits to root cause investigation within 24 hours
- Score correction published within 5 business days if error found

### Cryptographic Integrity: 100%

**Guarantee:** Scores cannot be modified undetected

**Mechanism:**
- Every score signed with GTIXT private key
- Signature available via verify_score endpoint
- Public key at https://gtixt.com/keys/public.pem
- Signature breaks if any field modified

### Credit Policy for Data Accuracy Failures

| Issue | Evidence | Credit |
|-------|----------|--------|
| Score mismatch after verification | VerificationResult.score_match=false | 50% monthly fee |
| Evidence incomplete | VerificationResult.reproducibility_verification.evidence_complete=false | 25% next month |
| Hash mismatch | VerificationResult.hash_match=false | 50% monthly fee |
| Rule application error | VerificationResult.reproducibility_verification.rule_application_correct=false | 25% monthly fee |
| Signature invalid | Cryptographic verification fails | Investigation + correction |

### Data Retention SLA

**Audit Trail:** 7 years (meet regulatory requirements)
- All audit records preserved
- Accessible via audit_export endpoint
- Searchable by date range

**Snapshots:** 5 years
- All published snapshots retained
- Accessible via snapshots/history endpoint
- Immutable (cannot be modified)

**Evidence:** 5 years
- All evidence backing scores retained
- Accessible via evidence endpoint

---

## 4. Rate Limiting & Throughput SLA

### Rate Limits (per API Key)

```
Standard Plan:
  - Sustained: 1,000 req/minute (16.7 req/second average)
  - Burst: 10,000 requests/second
  - Daily limit: 1,000,000 requests

Premium Plan:
  - Sustained: 10,000 req/minute (166 req/second)
  - Burst: 100,000 requests/second
  - Daily limit: 50,000,000 requests

Enterprise Plan:
  - Custom limits (contact sales)
```

### Rate Limit Headers

Every response includes:
```
X-RateLimit-Limit: 1000
X-RateLimit-Remaining: 998
X-RateLimit-Reset: 2025-02-23T10:01:00Z
X-RateLimit-Retry-After: 5
```

### Burst Handling

- First 10,000 requests in 1-second window: ALLOWED
- Remaining in second: QUEUED (max 5s wait)
- After 5s wait: Returns 429 Too Many Requests

### Rate Limit Errors

```json
{
  "success": false,
  "error": "Rate limit exceeded",
  "code": 429,
  "details": {
    "limit": 1000,
    "current": 1002,
    "reset_at": "2025-02-23T10:01:00Z",
    "retry_after": 45
  }
}
```

### Fair Use Policy

Requests that violate fair use (regardless of rate limit):
- Automated bulk downloads of all firm data
- Concurrent requests > 100 simultaneous connections
- Scraping without explicit permission
- **Consequence:** Account suspend, notification sent first

---

## 5. Consistency & Determinism SLA

### Deterministic Scoring: 100%

**Guarantee:** Same input (firm_id + date + evidence) always produces same score

**Verification:**
- Call verify_score twice with identical input
- Both responses must have identical computed_score
- deterministic flag in reproducibility_verification must be true

**Impact:**
- Replays always work
- Audits are reproducible
- Historical verification always succeeds

### Version Stability: 7 year minimum

**Specification Versions:** Never removed
- v1.0.0 will remain available forever
- Can query historical snapshots with original version
- score remains same when recomputed with original spec

### Specification Changes

**Major Breaking Changes:**
- 60+ days advance notice
- Published via status page + email
- New /v2/ endpoint launched, /v1/ remains
- SLA for old version remains 99.9% uptime (not accepting new scores)

**Minor Non-Breaking Changes:**
- 30 days advance notice
- Backward compatible (old queries still work)
- Optional new fields with defaults

---

## 6. Security & Privacy SLA

### Data Security

**Encryption:**
- TLS 1.3+ for all network traffic
- AES-256-GCM for data at rest
- HSM-backed key management

**Access Control:**
- API key authentication (not passwords)
- IP whitelisting (optional, premium tier)
- Rate limiting per key
- Activity logging (all access)

**Audit Trail:**
- All operations logged
- Retention: 7 years
- Accessible via audit_export endpoint
- Immutable (tamper-evident)

### Data Privacy

**PII Handling:**
- No personally identifiable information stored
- Firm IDs are company identifiers, not person names
- Operators anonymous (only ID logged)

**Data Retention:**
- Historical data retained 7 years (regulatory)
- Audit trails retained 7 years
- No deletion requests honored (compliance requirement)

### Compliance

- **SOC 2 Type II:** Attested annually
- **GDPR:** Firm names (public data) not considered PII
- **CCPA:** No consumer personal information processed
- **Regulatory:** Data retention meets FinRA requirements

### Incident Disclosure

**Security incident** discovered:
- Internal investigation: 24 hours
- Notification to affected customers: 48 hours (if data exposure)
- Root cause analysis: 5 business days
- Remediation: 2 weeks (or sooner for critical)

---

## 7. Support SLA

### Support Channels

| Channel | Hours | Response Time |
|---------|-------|----------------|
| Email | 24/5 (weekdays) | 4 hours |
| Slack (premium) | 24/7 | 1 hour |
| Phone (enterprise) | 24/7 | 15 minutes |

### Issue Severity & Response

| Severity | Definition | Response | Resolution |
|----------|-----------|----------|------------|
| **Critical** | API completely down or data corruption | 15 min | 2 hours |
| **High** | API partially down or major feature broken | 1 hour | 8 hours |
| **Medium** | API working but degraded | 4 hours | 2 days |
| **Low** | Documentation issue or enhancement request | 24 hours | 2 weeks |

---

## 8. Performance Budget

### Request Processing Budget

```
Total Budget: 1000ms per request (p99)

├─ Network latency (client → server): 100ms
├─ Certificate validation: 5ms
├─ Request parsing: 10ms
├─ Authentication: 20ms
├─ Database query: 400-600ms
├─ Business logic: 200-400ms
├─ JSON serialization: 50ms
├─ Network transmission (server → client): 100ms
└─ Remaining buffer: 125-325ms

Special cases:
├─ verify_score: 2000ms (computation intensive)
└─ audit_export: 2000ms (large data sets)
```

### Database Query Budget

```
/snapshots/latest: 50-150ms (in-memory cache)
/snapshots/history: 100-200ms (indexed queries)
/evidence/{firm_id}: 100-300ms (nested queries)
/specification: 10-50ms (static, cached)
/verify_score: 800-1500ms (computation, verification)
/audit_export: 1000-2000ms (large result sets)
```

---

## 9. SLA Credits & Remedies

### How Credits Work

1. **Automatic:** Calculated and applied automatically
2. **Applied to:** Next month's invoice
3. **Minimum:** 5% ($50 minimum credit)
4. **Maximum:** 100% (full month refunded)
5. **Accumulation:** Multiple issues stack

### Credit Eligibility

Credits apply only when:
- Customer reported issue within 30 days
- Issue confirmed by GTIXT monitoring
- All reasonable troubleshooting attempted
- Not caused by customer misconfiguration

### No SLA Credit Conditions

- Scheduled maintenance (announced 7 days prior)
- Customer-side issues (network, firewall, application)
- DDoS or force majeure events
- Beta or experimental features
- Third-party service failures (not GTIXT responsibility)

### Requesting Credit

Contact: sla@gtixt.com
Include:
1. Error message or issue description
2. Timestamp(s) of incorrect behavior
3. Affected API endpoint(s)
4. Expected vs actual result

Response within 5 business days with credit decision

---

## 10. Change Management & Versioning

### Backward Compatibility Commitment

**API Version 1.x:** Backward compatible for 5 years minimum
- New optional fields may be added (ignored if not needed)
- Existing fields never removed
- Existing behaviors never change
- New endpoints can be added

### Breaking Changes

**Only with version increment (v1 → v2):**
- 60+ day advance notice
- Both versions supported simultaneously
- Gradual deprecation period (12+ months)
- Migration guide published

### Notification Policy

| Type | Channel | Advance Notice |
|------|---------|-----------------|
| Breaking change | Email + Dashboard | 60+ days |
| Non-breaking change | Dashboard | 30 days |
| Bug fix | Email | 24 hours |
| Security patch | Email | Immediate |
| Deprecation | Email | 6-12 months |

---

## 11. Benchmarks & Commitments Summary

### Availability: 99.9%
- **Commitment:** 8.76 hours downtime per month acceptable
- **Monitoring:** Real-time via status page
- **Action:** If exceeded: automatic credit

### Performance: p95 < 500ms
- **Commitment:** 95% of requests complete within 500ms
- **Monitoring:** Continuous tracking
- **Action:** If 2 consecutive months missed: automatic credit

### Accuracy: 100%
- **Commitment:** Every score independently verifiable
- **Monitoring:** Spot checks + customer verification reports
- **Action:** If failure detected: reproduce fix within 5 days

### Consistency: 100%
- **Commitment:** Same input always produces same score
- **Monitoring:** Automatic verification on /verify_score endpoint
- **Action:** If mismatch: immediate investigation

### Security: SOC 2 compliant
- **Commitment:** Annual audit by external firm
- **Monitoring:** Continuous compliance checks
- **Action:** Findings remediated per timeline

---

## 12. Legal & Disclaimers

### SLA Scope

This SLA applies to:
- GTIXT-hosted API at https://gtixt.com
- All authenticated requests with valid API key
- Business hours support (premium features outside hours on best-effort basis)

### SLA Exclusions

Does NOT apply to:
- Third-party integrations (partner APIs, external services)
- Customer application errors or misconfiguration
- Force majeure events (natural disasters, war, pandemics)
- Client database maintenance or outages
- Network issues beyond GTIXT control
- Beta or experimental API endpoints

### Limitation of Liability

- Maximum liability: 12 months of fees paid
- Credits are sole remedy for SLA breach
- No indirect damages, lost profits, etc.
- No liability if customer violates fair use policy

### Governing Law

- Jurisdiction: New York, USA
- Disputes: Binding arbitration (not litigation)
- Arbitration: JAMS rules, neutral location

---

## 13. Contact & Escalation

### Support Channels

| Channel | Purpose | Response |
|---------|---------|----------|
| support@gtixt.com | General questions | 4 hours (weekday) |
| api-status@gtixt.com | Incidents | 15 min (critical) |
| sla@gtixt.com | SLA credit requests | 5 business days |
| security@gtixt.com | Security issues | 1 hour (critical) |

### Escalation Path

1. **Level 1:** Support team (email support)
2. **Level 2:** API engineering team (30 min escalation)
3. **Level 3:** VP Engineering (2 hour escalation)
4. **Level 4:** CEO (critical only, 6 hour escalation)

---

## 14. SLA History

| Version | Effective | Changes |
|---------|-----------|---------|
| 1.0.0 | 2025-02-01 | Initial release |

---

## Appendix A: Metrics Dashboard

Real-time SLA metrics available at:
https://metrics.gtixt.com

Dashboard includes:
- Current uptime percentage
- Response time percentiles (p50, p95, p99)
- Data accuracy rate
- Rate limit usage
- Query performance by endpoint

---

## Appendix B: Sample SLA Report

```
Month: February 2025
Reporting Period: 2025-02-01 to 2025-02-28

Availability
  Uptime: 99.92%
  Downtime: 6.5 hours (within 8.76 hour budget)
  Incidents: 1 (4 hour outage due to DC power failure)
  Status: ✓ PASS

Response Time (p95)
  Target: < 500ms
  Actual: 358ms average
  Requests: 42.3M
  Status: ✓ PASS

Data Accuracy
  Verification success: 100%
  Hash mismatches: 0
  Reproducibility failures: 0
  Status: ✓ PASS

Rate Limiting
  Burst rejections: < 0.01%
  Fairness: Normal
  Status: ✓ PASS

Security
  Incidents: 0
  Key rotations: 2 (scheduled)
  Access violations: 0
  Status: ✓ PASS

SLA Credits Issued
  Reason: None
  Amount: $0
  Total: $0

Conclusion: All SLAs met. Excellent performance month.
```

---

**Questions?** Contact: sla@gtixt.com
