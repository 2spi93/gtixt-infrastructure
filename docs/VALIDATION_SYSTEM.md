# GTIXT Validation System - Integration Guide and API Documentation

**Version:** 1.0.0  
**Last Updated:** 2026-02-24  
**Status:** Ready for integration

---

## Overview

GTIXT validation uses a multi-method agent validation layer to score and approve evidence items. The system combines:

- LLM validation (GPT-4 / Claude-3 reasoning)
- Rule validation (deterministic business rules)
- Heuristic validation (anomaly detection)
- Cross-reference validation (multi-source consistency)

The output is a single `AgentValidationLayer` object with a final score, confidence, approval decision, and flags.

---

## Architecture

**Primary components:**

- Orchestrator: `gpti-site/lib/validation/agent-validation-layer.ts`
- LLM Validator: `gpti-site/lib/validation/llm-validator.ts`
- Rule Validator: `gpti-site/lib/validation/rule-validator.ts`
- Heuristic Validator: `gpti-site/lib/validation/heuristic-validator.ts`
- Cross-Reference Validator: `gpti-site/lib/validation/cross-reference-validator.ts`

**Data models:**

- `InstitutionalEvidenceItem`
- `LLMValidation`, `RuleValidation`, `HeuristicValidation`, `CrossReferenceValidation`
- `AgentValidationLayer`

All models are defined in `gpti-site/lib/institutional-data-models.ts`.

---

## Integration Guide

### 1) Basic validation

```ts
import { validateEvidence } from '../lib/validation/agent-validation-layer';

const validation = await validateEvidence({
  evidence_item: evidenceItem,
  firm_id: 'jane_street',
  snapshot_id: 'snap_123',
  pillar_id: 'regulatory_compliance',
  related_evidence: relatedItems,
});

console.log(validation.final_validation.approved);
console.log(validation.final_validation.validation_score);
```

### 2) Configure validation behavior

```ts
import { validateEvidence } from '../lib/validation/agent-validation-layer';

const validation = await validateEvidence(
  { evidence_item: evidenceItem },
  {
    enable_llm: true,
    enable_rules: true,
    enable_heuristics: true,
    enable_cross_reference: false,
    require_approval: true,
    confidence_threshold: 80,
    weights: {
      llm_weight: 0.4,
      rule_weight: 0.3,
      heuristic_weight: 0.2,
      cross_reference_weight: 0.1,
    },
  }
);
```

### 3) Batch validation

```ts
import { validateEvidenceBatch } from '../lib/validation/agent-validation-layer';

const results = await validateEvidenceBatch(evidenceItems);
```

### 4) Manual override

```ts
import { overrideValidation } from '../lib/validation/agent-validation-layer';

const updated = overrideValidation(
  validation,
  true,
  'Reviewed by compliance lead, approved as verified.',
  'compliance_user_01'
);
```

---

## Environment Variables

- `LLM_API_KEY` - required for LLM validation (OpenAI/Anthropic)

Optional for external metrics endpoints:

- `DATABASE_URL` - required for `/api/validation/metrics`

---

## Validation Output

### `AgentValidationLayer` structure

```json
{
  "validation_id": "val_evt_abc123_1700000000000",
  "evidence_item_id": "evt_abc123",
  "validations": {
    "llm_validation": { "model": "gpt-4", "confidence_score": 85, "reasoning": "..." },
    "rule_validation": { "overall_score": 88, "rules_applied": ["..."] },
    "heuristic_validation": { "overall_anomaly_score": 15, "summary": { "is_anomaly": false } },
    "cross_reference": { "agreement_score": 80, "summary": { "conflict_sources": 0 } }
  },
  "final_validation": {
    "overall_confidence": "high",
    "validation_score": 86.4,
    "approved": true,
    "flags": ["rule_failed_r_source_not_expired"],
    "reviewer_notes": "LLM analysis ... | Rules: ... | Heuristics: ...",
    "timestamp": "2026-02-24T12:00:00Z",
    "validated_by": "agent:validation-layer-v1.0"
  }
}
```

---

## Decision Logic

1. All enabled validators run in parallel.
2. Final score is a weighted average of scores from enabled validators.
3. Approval requires:
   - `final_score >= confidence_threshold` **and**
   - no critical failures in LLM or rule validation.

### Weighting default

- LLM: 0.4
- Rules: 0.3
- Heuristics: 0.2
- Cross-reference: 0.1

### Confidence levels

- High: `score >= 85`
- Medium: `score >= 60`
- Low: `score < 60`

---

## API Documentation

### 1) Validation Metrics (Database)

**Endpoint:** `GET /api/validation/metrics`

**Purpose:** Returns validation KPIs from the `validation_metrics` table.

**Response:**

- `coverage`: coverage and NA rates
- `stability`: score stability metrics
- `ground_truth`: ground-truth alignment
- `calibration`: confidence distribution
- `sensitivity`: score distribution
- `auditability`: evidence coverage metrics

**Example response (partial):**

```json
{
  "snapshot_id": "snapshot_2026_02_24",
  "timestamp": "2026-02-24T00:00:00Z",
  "coverage": {
    "total_firms": 120,
    "coverage_percent": 92.5,
    "avg_na_rate": 7.5,
    "agent_c_pass_rate": 90.0
  },
  "calibration": {
    "avg_confidence": 0.82,
    "high_confidence_count": 80,
    "medium_confidence_count": 30,
    "low_confidence_count": 10
  }
}
```

**Errors:**

- 503: Database not configured
- 404: No validation metrics found

---

### 2) Snapshot Metrics (MinIO/Pointer)

**Endpoint:** `GET /api/validation/snapshot-metrics`

**Purpose:** Calculates metrics from latest snapshot via MinIO pointer.

**Response fields:**

- `metrics.coverage_percent`
- `metrics.avg_na_rate`
- `metrics.agent_c_pass_rate`
- `metrics.score_mean`
- `metrics.score_std_dev`
- `metrics.total_firms`
- `metrics.by_jurisdiction`
- `tests` array of validation tests

**Example response (partial):**

```json
{
  "snapshot_id": "latest",
  "snapshot_date": "2026-02-24T00:00:00Z",
  "metrics": {
    "coverage_percent": 91.2,
    "avg_na_rate": 8.8,
    "agent_c_pass_rate": 89.5,
    "score_mean": 73.4,
    "score_std_dev": 11.2,
    "total_firms": 135
  },
  "tests": [
    { "name": "Coverage & Data Sufficiency", "status": "PASS", "passed": true }
  ]
}
```

**Errors:**

- 500: Pointer or snapshot fetch failure

---

## Validator Details

### LLM Validator

- Uses GPT-4 or Claude-3
- Prompt includes evidence metadata, provenance, and impact
- Returns confidence score (0-100) and flags

**Config:**

```ts
{
  model: 'gpt-4' | 'gpt-4-turbo' | 'claude-3-opus' | 'claude-3-sonnet',
  temperature: 0.3,
  max_tokens: 500,
  api_key?: string
}
```

### Rule Validator

- Deterministic checks for source authenticity, recency, provenance completeness
- Returns rule results + overall score

### Heuristic Validator

- Anomaly detection (impact vs confidence, source reliability, temporal consistency)
- Returns anomaly score (0-100, higher means more anomalous)

### Cross-Reference Validator

- Compares evidence with related items
- Returns agreement score and conflict list

---

## Operational Notes

- If `LLM_API_KEY` is not set, LLM validator returns a neutral score and warning flag.
- Cross-reference validator requires `related_evidence` input; otherwise it returns neutral.
- Consider caching LLM results for cost control.
- Configure rate limits around validation batch jobs to avoid burst failures.

---

## Testing Checklist

- LLM validation returns response with flags
- Rules validator detects invalid source URL
- Heuristic validator flags old evidence with high impact
- Cross-reference validation catches conflicting impact direction
- Orchestrator score aligns with expected weights

---

## Ready Status

✅ The validation system integration guide and API documentation are now available and ready to use.
