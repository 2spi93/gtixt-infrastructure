# GTIXT Data Contracts

This document defines the complete data contracts for all GTIXT API endpoints, ensuring consistency, type safety, and data integrity.

**Version:** 1.0.0
**Last Updated:** 2025-02-23
**Status:** Active

---

## Table of Contents

1. [Overview](#overview)
2. [Core Principles](#core-principles)
3. [Response Format](#response-format)
4. [Data Models](#data-models)
5. [API Endpoints](#api-endpoints)
6. [Validation Rules](#validation-rules)
7. [Error Handling](#error-handling)
8. [Examples](#examples)

---

## Overview

Data contracts define:
- **Structure**: Shape of all request/response objects
- **Types**: Exact data types for every field
- **Constraints**: Validation rules (min/max, patterns, etc.)
- **Examples**: Valid and invalid usage
- **Guarantees**: Data quality commitments

### Contract Levels

| Level | Purpose | Example |
|-------|---------|---------|
| **Type Contract** | Field types, optional/required | `firm_id: string` |
| **Value Contract** | Valid value ranges | `score: 0-100` |
| **Structural Contract** | Nested object shapes | `pillar_scores: Record<PillarId, number>` |
| **Behavioral Contract** | API guarantees | "Score deterministic", "Hash verified" |

---

## Core Principles

### 1. Single Source of Truth

All API data types are defined in **`lib/data-models.ts`**:
- TypeScript interfaces for type safety
- Exported for SDK consumers
- Referenced by OpenAPI spec
- Validated by Zod schemas

### 2. Standard Response Envelope

**Every** API response uses:

```typescript
type ApiResponse<T> = 
  | { success: true, data: T, meta?: ApiMeta, message?: string }
  | { success: false, error: string, code?: number, details?: ValidationError[] }
```

### 3. Bidirectional Validation

```
Request → Zod Schema Validation → Type-Safe Handler → Response Type Check → Client
```

### 4. Cryptographic Integrity

Every score response includes `sha256` hash for verification:
- Consumer can independently verify score correctness
- Hash includes evidence and specification reference
- Breaking change if hash algorithm changes

---

## Response Format

### Success Response

```json
{
  "success": true,
  "data": { /* T - endpoint-specific data */ },
  "meta": {
    "api_version": "1.0.0",
    "spec_version": "1.0.0",
    "sdk_version": "1.0.0",
    "timestamp": "2025-02-23T10:30:45Z"
  },
  "message": "Optional success message"
}
```

**Fields:**
- `success`: Always `true` for successful responses
- `data`: Response payload (type varies by endpoint)
- `meta`: API version info and timestamp
- `message`: Optional user-friendly message

### Error Response

```json
{
  "success": false,
  "error": "Validation failed",
  "code": 400,
  "details": [
    {
      "field": "firm_id",
      "message": "Must be between 1-50 characters",
      "value": "",
      "rule": "min_length"
    }
  ]
}
```

**Fields:**
- `success`: Always `false` for error responses
- `error`: Error type/category
- `code`: HTTP status code (400, 404, 500, etc.)
- `details`: Array of specific validation errors

### ApiMeta Structure

```typescript
interface ApiMeta {
  api_version: string;      // e.g. "1.0.0"
  spec_version: string;     // e.g. "1.0.0" - specification used for scoring
  sdk_version: string;      // e.g. "1.0.0" - SDK version
  timestamp: string;        // ISO 8601 datetime
}
```

---

## Data Models

### Enumerations

#### PillarId
Supported scoring pillars:
- `regulatory_compliance` - Regulatory compliance history
- `financial_stability` - Financial position & stability
- `operational_risk` - Operational risk management
- `governance` - Corporate governance structure
- `client_protection` - Client protection measures
- `market_conduct` - Market conduct record
- `transparency_disclosure` - Transparency & disclosure

#### ConfidenceLevel
Evidence confidence ratings:
- `high` - High confidence (>90%)
- `medium` - Medium confidence (70-90%)
- `low` - Low confidence (40-70%)
- `very_low` - Very low confidence (<40%)
- `na` - Not applicable

#### EvidenceType
Types of evidence sources:
- `regulatory_filing` - SEC/regulatory filings
- `regulatory_action` - Regulatory actions/orders
- `financial_report` - Financial reports/statements
- `audit` - Audit reports
- `news` - News articles/reports
- `disclosure` - Public disclosures
- `litigation` - Litigation records

#### FirmStatus
Assessment status:
- `published` - Published and active
- `pending` - Under review, not published
- `retracted` - Published then retracted

### Core Models

#### FirmSnapshot

Firm's complete score at a point in time.

```typescript
interface FirmSnapshot {
  firm_id: string;                              // 1-50 chars
  firm_name: string;                            // 1-200 chars
  score: number;                                // 0-100
  pillar_scores: Record<PillarId, number>;     // 0-100 each
  sha256: string;                               // 64-char hex
  status: FirmStatus;
  timestamp: string;                            // ISO 8601
  version: string;                              // Semantic version
  percentile?: number;                          // 0-100
}
```

**Constraints:**
- `firm_id`: Required, 1-50 characters, alphanumeric + underscore
- `firm_name`: Required, 1-200 characters
- `score`: 0-100, calculated from pillar scores
- `pillar_scores`: Must have entry for each pillar
- `sha256`: Deterministic hash of score + evidence + spec reference
- `status`: Reflects publication status
- `timestamp`: UTC time score was calculated
- `percentile`: Optional, calculated against historical scores

**Examples:**
```json
{
  "firm_id": "vertex_capital",
  "firm_name": "Vertex Capital Partners",
  "score": 87.5,
  "pillar_scores": {
    "regulatory_compliance": 92,
    "financial_stability": 85,
    "operational_risk": 88,
    "governance": 84,
    "client_protection": 90,
    "market_conduct": 82,
    "transparency_disclosure": 86
  },
  "sha256": "a1b2c3d4e5f6...",
  "status": "published",
  "timestamp": "2025-02-23T10:00:00Z",
  "version": "1.0.0",
  "percentile": 78.5
}
```

#### EvidenceItem

Single piece of evidence backing a score.

```typescript
interface EvidenceItem {
  type: EvidenceType;
  description: string;                  // 1-500 chars
  confidence: ConfidenceLevel;
  timestamp: string;                    // ISO 8601
  source: string;                       // 1-100 chars
  value?: number;                       // 0-100, optional
  reference_id?: string;                // optional
}
```

**Constraints:**
- All fields required except `value` and `reference_id`
- `description`: Human-readable evidence summary
- `confidence`: Must be explicit (no implicit medium/unknown)
- `timestamp`: When evidence was discovered
- `source`: System/database evidence came from
- `value`: Evidence-specific score contribution if quantifiable
- `reference_id`: URL, filing ID, case number, etc.

#### PillarEvidence

Aggregated evidence for a single pillar.

```typescript
interface PillarEvidence {
  pillar_id: PillarId;
  pillar_name: string;
  weight: number;                       // 0-1
  score: number;                        // 0-100
  evidence: EvidenceItem[];
  verification_status: "verified" | "unverified";
}
```

**Constraints:**
- `pillar_id` + `pillar_name` must match current specification
- `weight`: Percentage of overall score (sum across pillars ≈ 1.0)
- `score`: Weighted average of evidence
- `evidence`: Must be non-empty if score > 0
- `verification_status`: Indicates if pillar evidence was audited

#### HistoricalSnapshot

Time-series data point for a firm.

```typescript
interface HistoricalSnapshot {
  date: string;                         // YYYY-MM-DD
  version: string;                      // Semantic version
  score: number;                        // 0-100
  sha256: string;                       // 64-char hex
  status: FirmStatus;
  pillar_scores?: Record<PillarId, number>;
}
```

**Constraints:**
- `date`: Exact date snapshot was taken
- `version`: Specification version used
- `score`: Historical score (may differ from current due to spec changes)
- `sha256`: Hash from that time (immutable)
- `pillar_scores`: Optional for older snapshots

#### AuditRecord

Single event in audit trail.

```typescript
interface AuditRecord {
  timestamp: string;                    // ISO 8601
  event_type: "evidence_added" | "evidence_reviewed" | "score_snapshot" | "evidence_retracted";
  firm_id: string;
  action: string;                       // 1-200 chars
  pillar_id: PillarId | "aggregate";
  evidence_type: EvidenceType | "snapshot";
  evidence_description: string;         // 1-500 chars
  confidence_before: ConfidenceLevel | null;
  confidence_after: ConfidenceLevel;
  score_before: number | null;
  score_after: number;                  // 0-100
  operator_id: string;
  source: string;
  notes: string;                        // 0-1000 chars
  verification_status: FirmStatus;
  sha256_before: string | null;
  sha256_after: string;
}
```

**Constraints:**
- Records immutable once written
- `timestamp`: UTC event time
- `event_type`: Specific action taken
- `confidence_before/after`: Tracks changes to confidence
- `score_before/after`: Tracks score impact
- `sha256_before/after`: Cryptographic proof of change
- `operator_id`: User or system that made change

#### VerificationResult

Result of independent score verification.

```typescript
interface VerificationResult {
  success: boolean;
  firm_id: string;
  snapshot_date: string;                // YYYY-MM-DD
  reported_score: number;               // 0-100
  computed_score: number;               // 0-100 (independently computed)
  score_match: boolean;
  reported_hash: string;
  computed_hash: string;                // 64-char hex
  hash_match: boolean;
  pillar_details: PillarVerification[];
  verification_timestamp: string;       // ISO 8601
  reproducibility_verification: {
    deterministic: boolean;
    evidence_complete: boolean;
    rule_application_correct: boolean;
    cryptographic_integrity: boolean;
  };
  message: string;
}
```

**Constraints:**
- `success`: true if score matches, false otherwise
- `reported_score`: Score from original snapshot
- `computed_score`: Re-calculated score
- `score_match`: Must be false if scores differ
- `hash_match`: Must be false if computed_hash ≠ reported_hash
- All reproducibility checks must be boolean

---

## API Endpoints

### GET /api/snapshots/latest

**Returns:** Latest snapshot for all published firms

**Response Schema:**
```typescript
ApiResponse<FirmSnapshot[]>
```

**Query Parameters:** None

**Example Response:**
```json
{
  "success": true,
  "data": [
    { /* FirmSnapshot */ },
    { /* FirmSnapshot */ }
  ],
  "meta": { /* ApiMeta */ }
}
```

**Guarantees:**
- Returns only `published` status firms
- Sorted by firm_name A-Z
- Data updated every 6 hours
- Response time: p95 < 500ms

---

### GET /api/snapshots/history?firm_id={id}

**Returns:** Historical snapshots for a firm (time-series)

**Response Schema:**
```typescript
ApiResponse<{
  snapshots: HistoricalSnapshot[],
  total_count: number
}>
```

**Query Parameters:**
- `firm_id` (required): Firm identifier, 1-50 chars
- `version` (optional): Specification version, default "v1.0"
- `date_start` (optional): YYYY-MM-DD
- `date_end` (optional): YYYY-MM-DD
- `limit` (optional): 1-250, default 50

**Validation Rules:**
- `firm_id`: Required, must exist
- `limit`: Must be between 1-250
- `date_start <= date_end` if both provided

**Example Response:**
```json
{
  "success": true,
  "data": {
    "snapshots": [
      {
        "date": "2025-02-23",
        "version": "1.0.0",
        "score": 87.5,
        "sha256": "...",
        "status": "published"
      }
    ],
    "total_count": 45
  },
  "meta": { /* ApiMeta */ }
}
```

---

### GET /api/evidence/{firm_id}

**Returns:** Evidence backing a firm's score

**Response Schema:**
```typescript
ApiResponse<FirmEvidence>
```

**Path Parameters:**
- `firm_id`: Firm identifier, 1-50 chars

**Query Parameters:**
- `snapshot_date` (optional): YYYY-MM-DD, default latest
- `version` (optional): Specification version, default "v1.0"

**Example Response:**
```json
{
  "success": true,
  "data": {
    "firm_id": "vertex_capital",
    "total_score": 87.5,
    "snapshot_date": "2025-02-23",
    "evidence_by_pillar": [
      {
        "pillar_id": "regulatory_compliance",
        "pillar_name": "Regulatory Compliance",
        "weight": 0.15,
        "score": 92,
        "evidence": [
          {
            "type": "regulatory_filing",
            "description": "Clean regulatory record",
            "confidence": "high",
            "timestamp": "2025-02-23T10:00:00Z",
            "source": "SEC"
          }
        ],
        "verification_status": "verified"
      }
    ],
    "verification_status": "published",
    "sha256": "..."
  }
}
```

---

### POST /api/verify_score

**Verifies** a reported score is reproducible

**Request Schema:**
```typescript
{
  firm_id: string;
  snapshot_date: string;
  reported_score: number;
  evidence: Record<PillarId, { score: number, items: EvidenceItem[] }>;
  reported_hash?: string;
  specification_version?: string;
}
```

**Response Schema:**
```typescript
ApiResponse<VerificationResult>
```

**Example Request:**
```json
{
  "firm_id": "vertex_capital",
  "snapshot_date": "2025-02-23",
  "reported_score": 87.5,
  "evidence": {
    "regulatory_compliance": {
      "score": 92,
      "items": [
        {
          "type": "regulatory_filing",
          "description": "Clean record",
          "confidence": "high",
          "timestamp": "2025-02-23T10:00:00Z",
          "source": "SEC"
        }
      ]
    }
  }
}
```

**Example Response:**
```json
{
  "success": true,
  "data": {
    "success": true,
    "firm_id": "vertex_capital",
    "snapshot_date": "2025-02-23",
    "reported_score": 87.5,
    "computed_score": 87.5,
    "score_match": true,
    "reported_hash": "abc123...",
    "computed_hash": "abc123...",
    "hash_match": true,
    "pillar_details": [
      {
        "pillar_id": "regulatory_compliance",
        "pillar_name": "Regulatory Compliance",
        "weight": 0.15,
        "reported_score": 92,
        "computed_score": 92,
        "evidence_count": 1,
        "verification_status": "match"
      }
    ],
    "verification_timestamp": "2025-02-23T11:00:00Z",
    "reproducibility_verification": {
      "deterministic": true,
      "evidence_complete": true,
      "rule_application_correct": true,
      "cryptographic_integrity": true
    },
    "message": "Score verified successfully"
  }
}
```

---

### POST /api/audit_export

**Exports** audit trail for a firm

**Request Schema:**
```typescript
{
  firm_id: string;
  date_start?: string;
  date_end?: string;
  format?: "json" | "csv";
}
```

**Response Schema:**
```typescript
ApiResponse<AuditTrailExport>
```

**Example Request:**
```json
{
  "firm_id": "vertex_capital",
  "date_start": "2025-01-01",
  "date_end": "2025-02-23",
  "format": "json"
}
```

**Example Response:**
```json
{
  "success": true,
  "data": {
    "export_metadata": {
      "firm_id": "vertex_capital",
      "date_start": "2025-01-01",
      "date_end": "2025-02-23",
      "format": "json",
      "record_count": 45,
      "export_timestamp": "2025-02-23T11:00:00Z",
      "export_hash": "def456..."
    },
    "records": [
      {
        "timestamp": "2025-02-23T10:00:00Z",
        "event_type": "evidence_added",
        "firm_id": "vertex_capital",
        "action": "Added regulatory filing evidence",
        "pillar_id": "regulatory_compliance",
        "evidence_type": "regulatory_filing",
        "evidence_description": "SEC filing review",
        "confidence_before": null,
        "confidence_after": "high",
        "score_before": null,
        "score_after": 92,
        "operator_id": "system",
        "source": "crawler",
        "notes": "Automated crawl",
        "verification_status": "published",
        "sha256_before": null,
        "sha256_after": "..."
      }
    ]
  }
}
```

---

## Validation Rules

### Field Types

| Field | Type | Min | Max | Pattern | Required |
|-------|------|-----|-----|---------|----------|
| firm_id | string | 1 | 50 | alphanumeric_ | ✓ |
| firm_name | string | 1 | 200 | any | ✓ |
| score | number | 0 | 100 | N/A | ✓ |
| percentile | number | 0 | 100 | N/A | ✗ |
| sha256 | string | 64 | 64 | `^[a-f0-9]{64}$` | ✓ |
| weight | number | 0 | 1 | N/A | ✓ |
| timestamp | string | N/A | N/A | ISO 8601 | ✓ |
| date | string | 10 | 10 | `^\d{4}-\d{2}-\d{2}$` | ✓ |

### Common Validation Error Messages

```
field: "firm_id"
message: "firm_id must be 1-50 characters"
rule: "min_max_length"

field: "score"
message: "score must be between 0 and 100"
rule: "range"

field: "snapshot_date"
message: "snapshot_date must be in YYYY-MM-DD format"
rule: "format"

field: "evidence"
message: "evidence array cannot be empty"
rule: "non_empty"

field: "pillar_scores.regulatory_compliance"
message: "Pillar score must be 0-100"
rule: "range"
```

---

## Error Handling

### Error Response Format

All errors use standard ApiErrorResponse:

```json
{
  "success": false,
  "error": "error_type",
  "code": 400,
  "details": [
    {
      "field": "field_name",
      "message": "Human-readable message",
      "value": "actual_value",
      "rule": "validation_rule"
    }
  ]
}
```

### Error Codes and Meanings

| Code | Type | Meaning | Retry |
|------|------|---------|-------|
| 400 | ValidationError | Invalid request format/values | No |
| 401 | AuthenticationError | API key missing/invalid | No |
| 403 | AuthorizationError | Insufficient permissions | No |
| 404 | NotFoundError | Resource doesn't exist | No |
| 429 | RateLimitError | Too many requests | Yes (with backoff) |
| 500 | ServerError | Internal error | Yes (with backoff) |
| 503 | ServiceUnavailable | Service temporarily down | Yes (with backoff) |

### Example: Validation Error

```json
{
  "success": false,
  "error": "Validation failed",
  "code": 400,
  "details": [
    {
      "field": "firm_id",
      "message": "firm_id is required",
      "value": null,
      "rule": "required"
    },
    {
      "field": "reported_score",
      "message": "reported_score must be between 0 and 100",
      "value": 150,
      "rule": "range"
    }
  ]
}
```

---

## Examples

### Example 1: Get Latest Scores

**Request:**
```bash
curl -X GET "https://gtixt.com/api/snapshots/latest" \
  -H "Accept: application/json"
```

**Response:**
```json
{
  "success": true,
  "data": [
    {
      "firm_id": "citadel",
      "firm_name": "Citadel Securities",
      "score": 89.2,
      "pillar_scores": {
        "regulatory_compliance": 94,
        "financial_stability": 91,
        "operational_risk": 86,
        "governance": 88,
        "client_protection": 89,
        "market_conduct": 87,
        "transparency_disclosure": 85
      },
      "sha256": "abc123...",
      "status": "published",
      "timestamp": "2025-02-23T10:00:00Z",
      "version": "1.0.0",
      "percentile": 92.1
    },
    {
      "firm_id": "vertex_capital",
      "firm_name": "Vertex Capital",
      "score": 87.5,
      "pillar_scores": { /* ... */ },
      "sha256": "def456...",
      "status": "published",
      "timestamp": "2025-02-23T10:00:00Z",
      "version": "1.0.0",
      "percentile": 85.3
    }
  ],
  "meta": {
    "api_version": "1.0.0",
    "spec_version": "1.0.0",
    "sdk_version": "1.0.0",
    "timestamp": "2025-02-23T11:30:00Z"
  }
}
```

### Example 2: Verify a Score

**Request:**
```bash
curl -X POST "https://gtixt.com/api/verify_score" \
  -H "Content-Type: application/json" \
  -d '{
    "firm_id": "citadel",
    "snapshot_date": "2025-02-23",
    "reported_score": 89.2,
    "evidence": {
      "regulatory_compliance": {
        "score": 94,
        "items": [
          {
            "type": "regulatory_filing",
            "description": "SEC filings reviewed",
            "confidence": "high",
            "timestamp": "2025-02-23T10:00:00Z",
            "source": "sec"
          }
        ]
      }
    }
  }'
```

**Response:**
```json
{
  "success": true,
  "data": {
    "success": true,
    "firm_id": "citadel",
    "snapshot_date": "2025-02-23",
    "reported_score": 89.2,
    "computed_score": 89.2,
    "score_match": true,
    "reported_hash": "abc123...",
    "computed_hash": "abc123...",
    "hash_match": true,
    "pillar_details": [
      {
        "pillar_id": "regulatory_compliance",
        "pillar_name": "Regulatory Compliance",
        "weight": 0.15,
        "reported_score": 94,
        "computed_score": 94,
        "evidence_count": 1,
        "verification_status": "match"
      }
    ],
    "verification_timestamp": "2025-02-23T11:00:00Z",
    "reproducibility_verification": {
      "deterministic": true,
      "evidence_complete": true,
      "rule_application_correct": true,
      "cryptographic_integrity": true
    },
    "message": "All checks passed"
  },
  "meta": {
    "api_version": "1.0.0",
    "spec_version": "1.0.0",
    "sdk_version": "1.0.0",
    "timestamp": "2025-02-23T11:00:00Z"
  }
}
```

---

## Summary

This data contract ensures:

✅ **Consistency**: All APIs use same response format
✅ **Type Safety**: TypeScript interfaces for compile-time checking
✅ **Validation**: Zod schemas for runtime validation
✅ **Documentation**: Clear field specifications and constraints
✅ **Integrity**: Cryptographic verification available
✅ **Clarity**: Examples and error messages
✅ **Compatibility**: Semantic versioning for changes

For SDK developers: Import types from `lib/data-models.ts`
For API consumers: Reference OpenAPI spec at `/public/openapi/gtixt-api-v1.0.yaml`
For validators: Use Zod schemas from `lib/validation-schemas.ts`
