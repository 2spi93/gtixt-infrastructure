# API Validation Implementation Guide

This guide explains how to use the validation middleware and ensure all GTIXT APIs implement the data contracts.

**Version:** 1.0.0
**Last Updated:** 2025-02-23

---

## Quick Start

### 1. Import Validation Tools

```typescript
import { withValidation, sendSuccess, sendError, validateRequest } from "@/lib/api-middleware";
import { requireGET, requirePOST, applyRateLimit } from "@/lib/api-middleware";
import { 
  QuerySnapshotHistorySchema,
  BodyVerifyScoreSchema,
  VerificationResultSchema
} from "@/lib/validation-schemas";
import { validateAndParse } from "@/lib/validation-schemas";
```

### 2. Wrap Handler with Validation

```typescript
import type { NextApiRequest, NextApiResponse } from "next";
import { withValidation, sendSuccess, sendError, requireGET } from "@/lib/api-middleware";

async function handler(req: NextApiRequest, res: NextApiResponse) {
  if (!requireGET(req, res)) return;
  
  // Your handler logic
  const firms = await db.firms.findAll();
  sendSuccess(res, firms);
}

export default withValidation(handler, {
  methods: ["GET"],
  rateLimit: 1000,
});
```

---

## Detailed Implementation Patterns

### Pattern 1: Simple GET Endpoint

**File:** `/api/snapshots/latest.ts`

```typescript
import type { NextApiRequest, NextApiResponse } from "next";
import { withValidation, sendSuccess, requireGET } from "@/lib/api-middleware";
import { FirmSnapshot } from "@/lib/data-models";

async function handler(req: NextApiRequest, res: NextApiResponse) {
  if (!requireGET(req, res)) return;

  try {
    // Fetch latest snapshots
    const snapshots = await db.snapshots.getLatest();

    // Type-safe response
    const data: FirmSnapshot[] = snapshots.map(s => ({
      firm_id: s.firm_id,
      firm_name: s.firm_name,
      score: s.score,
      pillar_scores: s.pillar_scores,
      sha256: s.sha256,
      status: s.status,
      timestamp: s.timestamp,
      version: s.version,
      percentile: s.percentile,
    }));

    sendSuccess(res, data, 200, "Latest snapshots retrieved successfully");
  } catch (error) {
    console.error("Error fetching snapshots:", error);
    sendError(res, "Failed to retrieve snapshots", 500);
  }
}

export default withValidation(handler, {
  methods: ["GET"],
  rateLimit: 1000,
});
```

### Pattern 2: Paginated GET with Query Validation

**File:** `/api/snapshots/history.ts`

```typescript
import type { NextApiRequest, NextApiResponse } from "next";
import { withValidation, sendSuccess, sendError, requireGET, validateQuery } from "@/lib/api-middleware";
import { QuerySnapshotHistorySchema } from "@/lib/validation-schemas";
import { HistoricalSnapshot, ApiResponse } from "@/lib/data-models";
import { z } from "zod";

async function handler(req: NextApiRequest, res: NextApiResponse) {
  if (!requireGET(req, res)) return;

  // Validate query parameters
  const params = await validateQuery(req, res, QuerySnapshotHistorySchema);
  if (!params) return;

  const { firm_id, date_start, date_end, limit } = params;

  try {
    // Fetch historical data
    const snapshots = await db.snapshots.getHistory({
      firm_id,
      dateStart: date_start,
      dateEnd: date_end,
      limit,
    });

    // Map to correct type
    const data: HistoricalSnapshot[] = snapshots.map(s => ({
      date: s.date,
      version: s.version,
      score: s.score,
      sha256: s.sha256,
      status: s.status,
      pillar_scores: s.pillar_scores,
    }));

    // Return typed response
    const response: ApiResponse<{ snapshots: HistoricalSnapshot[]; total_count: number }> = {
      success: true,
      data: {
        snapshots,
        total_count: snapshots.length,
      },
      meta: {
        api_version: "1.0.0",
        spec_version: "1.0.0",
        sdk_version: "1.0.0",
        timestamp: new Date().toISOString(),
      },
    };

    res.status(200).json(response);
  } catch (error) {
    console.error("Error fetching snapshot history:", error);
    sendError(res, "Failed to retrieve snapshot history", 500);
  }
}

export default withValidation(handler, {
  methods: ["GET"],
  rateLimit: 1000,
});
```

### Pattern 3: POST with Request Body Validation

**File:** `/api/verify_score.ts`

```typescript
import type { NextApiRequest, NextApiResponse } from "next";
import { 
  withValidation, 
  sendSuccess, 
  sendError, 
  requirePOST, 
  validateRequest,
  applyRateLimit,
} from "@/lib/api-middleware";
import { BodyVerifyScoreSchema } from "@/lib/validation-schemas";
import { VerificationResult } from "@/lib/data-models";

async function handler(req: NextApiRequest, res: NextApiResponse) {
  if (!requirePOST(req, res)) return;

  // Validate request body
  const body = await validateRequest(req, res, BodyVerifyScoreSchema);
  if (!body) return;

  const { firm_id, snapshot_date, reported_score, evidence, reported_hash, specification_version } = body;

  try {
    // Verify score independently
    const verification = await verifyScore({
      firm_id,
      snapshot_date,
      reportedScore: reported_score,
      evidence,
      reportedHash: reported_hash,
      specVersion: specification_version,
    });

    // Type-safe response
    const result: VerificationResult = {
      success: verification.success,
      firm_id: verification.firm_id,
      snapshot_date: verification.snapshot_date,
      reported_score: verification.reported_score,
      computed_score: verification.computed_score,
      score_match: verification.score_match,
      reported_hash: verification.reported_hash,
      computed_hash: verification.computed_hash,
      hash_match: verification.hash_match,
      pillar_details: verification.pillar_details,
      verification_timestamp: new Date().toISOString(),
      reproducibility_verification: {
        deterministic: true,
        evidence_complete: verification.evidence_complete,
        rule_application_correct: verification.rules_correct,
        cryptographic_integrity: verification.hash_match,
      },
      message: verification.success ? "Score verified successfully" : "Score verification failed",
    };

    sendSuccess(res, result, 200);
  } catch (error) {
    console.error("Error verifying score:", error);
    sendError(res, "Failed to verify score", 500);
  }
}

export default withValidation(handler, {
  methods: ["POST"],
  rateLimit: 500, // Lower for compute-intensive endpoint
  parseJSON: true,
});
```

### Pattern 4: Dynamic Path Parameters

**File:** `/api/evidence/[firm_id].ts`

```typescript
import type { NextApiRequest, NextApiResponse } from "next";
import { 
  withValidation, 
  sendSuccess, 
  sendError, 
  requireGET,
  validateQuery,
  validatePath,
} from "@/lib/api-middleware";
import { FirmEvidence } from "@/lib/data-models";
import { z } from "zod";

async function handler(req: NextApiRequest, res: NextApiResponse) {
  if (!requireGET(req, res)) return;

  // Validate path parameters
  const { firm_id } = req.query;
  const pathValidation = validatePath(
    { firm_id: firm_id as string },
    {
      firm_id: z.string().min(1).max(50),
    }
  );

  if (!pathValidation.valid) {
    sendError(res, "Invalid path parameters", 400, pathValidation.errors as any);
    return;
  }

  // Validate query parameters
  const query = await validateQuery(
    req,
    res,
    z.object({
      snapshot_date: z.string().regex(/^\d{4}-\d{2}-\d{2}$/).optional(),
      version: z.string().default("v1.0"),
    })
  );
  if (!query) return;

  try {
    // Fetch evidence
    const evidence = await db.evidence.getForFirm({
      firm_id: firm_id as string,
      snapshot_date: query.snapshot_date,
      version: query.version,
    });

    // Type-safe response
    const data: FirmEvidence = {
      firm_id: evidence.firm_id,
      total_score: evidence.total_score,
      snapshot_date: evidence.snapshot_date,
      evidence_by_pillar: evidence.evidence_by_pillar,
      verification_status: evidence.verification_status,
      sha256: evidence.sha256,
    };

    sendSuccess(res, data);
  } catch (error) {
    console.error("Error fetching evidence:", error);
    sendError(res, "Failed to retrieve evidence", 500);
  }
}

export default withValidation(handler, {
  methods: ["GET"],
  rateLimit: 1000,
});
```

### Pattern 5: Complex POST with Multiple Validations

**File:** `/api/audit_export.ts`

```typescript
import type { NextApiRequest, NextApiResponse } from "next";
import {
  withValidation,
  sendSuccess,
  sendError,
  requirePOST,
  validateRequest,
} from "@/lib/api-middleware";
import { QueryAuditExportSchema } from "@/lib/validation-schemas";
import { AuditTrailExport } from "@/lib/data-models";

async function handler(req: NextApiRequest, res: NextApiResponse) {
  if (!requirePOST(req, res)) return;

  // Validate request body
  const body = await validateRequest(req, res, QueryAuditExportSchema);
  if (!body) return;

  const { firm_id, date_start, date_end, format } = body;

  try {
    // Fetch audit records
    const records = await db.audit.getRecords({
      firm_id,
      dateStart: date_start,
      dateEnd: date_end,
    });

    // Prepare export
    const exportData: AuditTrailExport = {
      export_metadata: {
        firm_id,
        date_start: date_start || "1900-01-01",
        date_end: date_end || new Date().toISOString().split("T")[0],
        format: format || "json",
        record_count: records.length,
        export_timestamp: new Date().toISOString(),
        export_hash: generateHash(records),
      },
      records: records,
      csv_data: format === "csv" ? convertToCSV(records) : undefined,
    };

    // Handle format-based response
    if (format === "csv") {
      res.setHeader("Content-Type", "text/csv");
      res.setHeader("Content-Disposition", `attachment; filename="audit_${firm_id}.csv"`);
      res.write(exportData.csv_data);
      res.end();
    } else {
      sendSuccess(res, exportData);
    }
  } catch (error) {
    console.error("Error exporting audit trail:", error);
    sendError(res, "Failed to export audit trail", 500);
  }
}

export default withValidation(handler, {
  methods: ["POST"],
  rateLimit: 100, // Lower for potentially large exports
  parseJSON: true,
  requireAuth: true, // Audit data is sensitive
});

function generateHash(records: any[]): string {
  // Implement SHA-256 hashing
  return "hash_placeholder";
}

function convertToCSV(records: any[]): string {
  // Implement CSV conversion
  return "timestamp,event_type,firm_id,...";
}
```

---

## Testing Your Implementation

### Unit Test Example

```typescript
import { validateRequest, sendSuccess, sendError } from "@/lib/api-middleware";
import { BodyVerifyScoreSchema } from "@/lib/validation-schemas";
import { NextApiRequest, NextApiResponse } from "next";

describe("API Validation", () => {
  it("should validate correct request body", async () => {
    const req = {
      body: {
        firm_id: "citadel",
        snapshot_date: "2025-02-23",
        reported_score: 85,
        evidence: {
          regulatory_compliance: {
            score: 90,
            items: [
              {
                type: "regulatory_filing",
                description: "Clean record",
                confidence: "high",
                timestamp: "2025-02-23T10:00:00Z",
                source: "SEC",
              },
            ],
          },
        },
      },
    } as any as NextApiRequest;

    const res = { json: jest.fn(), status: jest.fn().mockReturnThis() } as any as NextApiResponse;

    const data = await validateRequest(req, res, BodyVerifyScoreSchema);
    expect(data).toBeDefined();
    expect(data.firm_id).toBe("citadel");
  });

  it("should reject invalid request body", async () => {
    const req = {
      body: {
        firm_id: "", // Too short
        reported_score: 150, // Out of range
      },
    } as any as NextApiRequest;

    const res = {
      json: jest.fn(),
      status: jest.fn().mockReturnThis(),
    } as any as NextApiResponse;

    const data = await validateRequest(req, res, BodyVerifyScoreSchema);
    expect(data).toBeNull();
    expect(res.status).toHaveBeenCalledWith(400);
  });
});
```

---

## Integration Checklist

### API Endpoint Checklist

For each API endpoint, ensure:

- [ ] **Imports**
  - [ ] Correct validation schema imported
  - [ ] Middleware functions imported
  - [ ] Data model types imported

- [ ] **Method Validation**
  - [ ] `requireGET()` / `requirePOST()` implemented
  - [ ] CORS headers set
  - [ ] Allow header set for method not allowed

- [ ] **Request Validation**
  - [ ] Query parameters validated (if applicable)
  - [ ] Path parameters validated (if applicable)  
  - [ ] Request body validated (if applicable)
  - [ ] Validation errors return 400

- [ ] **Response Format**
  - [ ] Success responses use `sendSuccess()`
  - [ ] Error responses use `sendError()`
  - [ ] All responses include api_version, spec_version, sdk_version, timestamp
  - [ ] Errors include validation details when applicable

- [ ] **Error Handling**
  - [ ] Database errors caught and logged
  - [ ] Network errors caught and logged
  - [ ] Validation errors have descriptive messages
  - [ ] No sensitive data in error messages

- [ ] **Rate Limiting**
  - [ ] `withValidation()` includes rateLimit option
  - [ ] Rate limit headers set on response
  - [ ] 429 returned when limit exceeded
  - [ ] Appropriate limits for endpoint (lower for expensive operations)

- [ ] **Performance**
  - [ ] Handler completes within p95 budget
  - [ ] Database queries optimized
  - [ ] No N+1 queries
  - [ ] Response payload reasonable size

- [ ] **Documentation**
  - [ ] JSDoc comments on handler function
  - [ ] Describes parameters, return value, errors
  - [ ] Example usage in comments
  - [ ] References data contract documentation

### Example Documentation Comment

```typescript
/**
 * POST /api/verify_score
 * 
 * Verifies a firm score is reproducible and correct
 * 
 * @param {VerifyScoreRequest} body - Verification request
 * @returns {ApiResponse<VerificationResult>} Verification result with match status
 * 
 * @throws {ValidationError} 400 - Invalid request parameters
 * @throws {NotFoundError} 404 - Firm or snapshot not found
 * @throws {ComputationError} 500 - Score verification computation failed
 * 
 * @example
 * POST /api/verify_score
 * Content-Type: application/json
 * 
 * {
 *   "firm_id": "citadel",
 *   "snapshot_date": "2025-02-23",
 *   "reported_score": 89,
 *   "evidence": {...}
 * }
 * 
 * Response: 200 OK
 * {
 *   "success": true,
 *   "data": {
 *     "success": true,
 *     "score_match": true,
 *     ...
 *   }
 * }
 */
```

---

## Common Patterns

### Pattern: Optional Query Parameters

```typescript
import { z } from "zod";

const querySchema = z.object({
  limit: z.coerce.number().min(1).max(250).default(50),
  offset: z.coerce.number().min(0).default(0),
  sort_by: z.string().default("timestamp"),
  sort_order: z.enum(["asc", "desc"]).default("desc"),
});

const query = await validateQuery(req, res, querySchema);
if (!query) return;

const { limit, offset, sort_by, sort_order } = query;
```

### Pattern: Enum Validation

```typescript
import { z } from "zod";

const querySchema = z.object({
  format: z.enum(["json", "csv"]).default("json"),
  status: z.enum(["published", "pending", "retracted"]).optional(),
});
```

### Pattern: Date Range Validation

```typescript
import { z } from "zod";

const querySchema = z.object({
  date_start: z.string().regex(/^\d{4}-\d{2}-\d{2}$/).optional(),
  date_end: z.string().regex(/^\d{4}-\d{2}-\d{2}$/).optional(),
}).refine(
  (data) => {
    if (!data.date_start || !data.date_end) return true;
    return new Date(data.date_start) <= new Date(data.date_end);
  },
  { message: "date_start must be <= date_end" }
);
```

---

## Deployment Checklist

Before deploying API changes:

1. **Type Safety**
   - [ ] All handlers use correct request/response types
   - [ ] TypeScript compilation succeeds (no ts-errors)
   - [ ] Run `npm run type-check`

2. **Validation**
   - [ ] All Zod schemas imported and used
   - [ ] Validation tests pass: `npm run test -- validation`
   - [ ] Manual testing with invalid data

3. **Response Format**
   - [ ] All endpoints use ApiResponse envelope
   - [ ] Error responses include details array
   - [ ] Metadata includes correct versions

4. **Documentation**
   - [ ] OpenAPI spec updated for endpoint
   - [ ] Data contract documentation updated
   - [ ] JSDoc comments complete

5. **Monitoring**
   - [ ] Logging configured for endpoint
   - [ ] Performance metrics tracked
   - [ ] Error rates monitored

6. **SLA Compliance**
   - [ ] Response times meet p95 < 500ms target
   - [ ] Rate limits configured appropriately
   - [ ] Error responses complete in < 50ms

---

## Support & Troubleshooting

### Issue: Validation Passes But Type Error Later

**Cause:** Zod schema doesn't match TypeScript interface
**Solution:** Keep data-models.ts and validation-schemas.ts in sync

```typescript
// ❌ Wrong - they can diverge
interface User { id: number; name: string; optional?: string }
const userSchema = z.object({ id: z.number(), name: z.string(), optional: z.string() })

// ✅ Correct - schema matches interface
interface User { id: number; name: string; optional?: string }
const userSchema = z.object({ id: z.number(), name: z.string(), optional: z.string().optional() })
```

### Issue: Rate Limiting Too Strict

**Solution:** Adjust limits per endpoint based on usage

```typescript
// Lower rate for expensive operations
withValidation(handler, { rateLimit: 100 }) // verify_score
withValidation(handler, { rateLimit: 1000 }) // list snapshots
```

### Issue: Response Time SLA Violated

**Solution:** Profile and optimize

```typescript
// Add timing logs
const startTime = Date.now();
const data = await db.query();
console.log(`Query took ${Date.now() - startTime}ms`);

// If > 300ms, add indexes or caching
```

---

## References

- [Data Models](./lib/data-models.ts)
- [Validation Schemas](./lib/validation-schemas.ts)
- [API Middleware](./lib/api-middleware.ts)
- [Data Contracts](./docs/DATA_CONTRACTS.md)
- [SLAs](./docs/SLAS.md)
- [OpenAPI Spec](./public/openapi/gtixt-api-v1.0.yaml)
