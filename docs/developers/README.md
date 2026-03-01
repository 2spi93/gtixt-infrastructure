# GTIXT Developer Portal

Welcome to the GTIXT Developer Portal - your comprehensive resource for integrating the Global Transparency Index for Prop Trading (GTIXT) into your applications.

---

## 🚀 Quick Start

Get up and running with GTIXT in minutes:

```typescript
import { GTIXTClient } from '@gtixt/sdk';

const client = new GTIXTClient({
  apiKey: process.env.GTIXT_API_KEY
});

// Get latest snapshot for a firm
const snapshot = await client.getLatestSnapshot('jane_street');
console.log(`Jane Street Score: ${snapshot.score}`);
```

[Get your API key →](https://gtixt.com/dashboard/api-keys)

---

## 📚 Documentation Sections

### Getting Started
- [Quickstart Guide](./getting-started/quickstart.md) - 5-minute setup
- [Authentication](./getting-started/authentication.md) - API key management
- [Your First Request](./getting-started/first-request.md) - Complete walkthrough
- [Rate Limits](./getting-started/rate-limits.md) - Fair use policy

### API Reference
- [Endpoints](./api/endpoints.md) - Complete endpoint documentation
- [Request/Response Format](./api/format.md) - Standard envelope structure
- [Error Handling](./api/errors.md) - Error codes and handling
- [Pagination](./api/pagination.md) - Working with large datasets
- [Filtering](./api/filtering.md) - Query parameters
- [Versioning](./api/versioning.md) - API version management

### SDKs & Libraries
- [TypeScript/JavaScript](./sdks/typescript.md) - Official Node.js SDK
- [Python](./sdks/python.md) - Official Python SDK
- [Examples](./sdks/examples.md) - Real-world usage examples
- [Community SDKs](./sdks/community.md) - Third-party libraries

### Data Models & Schemas
- [Data Contracts](./schemas/data-contracts.md) - Complete field specifications
- [Validation Rules](./schemas/validation.md) - Input/output validation
- [Validation System Guide](../VALIDATION_SYSTEM.md) - Integration guide & API documentation
- [OpenAPI Spec](./schemas/openapi.md) - Machine-readable API spec
- [TypeScript Types](./schemas/typescript-types.md) - Type definitions
- [Provenance Models](./schemas/provenance.md) - Institutional data models

### Service Level Agreements
- [Uptime Guarantees](./slas/uptime.md) - 99.9% availability SLA
- [Performance Targets](./slas/performance.md) - Response time budgets
- [Data Accuracy](./slas/accuracy.md) - Reproducibility & verification
- [Support Response Times](./slas/support.md) - Support SLAs

### Use Cases & Examples
- [Verify a Score](./examples/verify-score.md) - End-to-end verification
- [Export Audit Trail](./examples/export-audit.md) - Compliance reporting
- [Track Score Changes](./examples/track-changes.md) - Historical analysis
- [Explore Provenance Graph](./examples/provenance-graph.md) - Data lineage
- [Bulk Firm Analysis](./examples/bulk-analysis.md) - Multi-firm queries

### Advanced Topics
- [Webhooks](./advanced/webhooks.md) - Real-time notifications
- [Bulk Export](./advanced/bulk-export.md) - Large-scale data access
- [Caching Strategies](./advanced/caching.md) - Performance optimization
- [Cryptographic Verification](./advanced/crypto-verification.md) - Hash & signature validation
- [Reproducibility Bundles](./advanced/reproducibility.md) - Complete data reconstruction

### Governance & Compliance
- [Governance Framework](./governance/framework.md) - Decision-making process
- [Methodology](./governance/methodology.md) - Scoring methodology
- [Error Corrections](./governance/corrections.md) - Error handling policy
- [Contestations](./governance/contestations.md) - Dispute resolution
- [Committee Decisions](./governance/committee.md) - Published decisions
- [Transparency Reports](./governance/transparency.md) - Quarterly reports

### Service Status
- [Current Status](./status/current.md) - Real-time status
- [Uptime History](./status/uptime.md) - Historical availability
- [Incident Reports](./status/incidents.md) - Post-mortems
- [Planned Maintenance](./status/maintenance.md) - Upcoming maintenance
- [Changelog](./status/changelog.md) - API changes

---

## 🔑 API Basics

### Base URL
```
https://api.gtixt.com/v1
```

### Authentication
```bash
curl https://api.gtixt.com/v1/snapshots/latest \
  -H "Authorization: Bearer YOUR_API_KEY"
```

### Response Format
All API responses use a standard envelope:

```typescript
{
  "success": true,
  "data": { /* your data */ },
  "meta": {
    "timestamp": "2025-02-24T12:00:00Z",
    "version": "1.0.0",
    "request_id": "req_abc123"
  }
}
```

### Rate Limits

| Tier | Requests/Minute | Requests/Day |
|------|-----------------|--------------|
| **Free** | 60 | 1,000 |
| **Pro** | 600 | 50,000 |
| **Enterprise** | Custom | Custom |

[View pricing →](https://gtixt.com/pricing)

---

## 📊 Core Concepts

### What is GTIXT?

GTIXT is an institutional-grade transparency index for proprietary trading firms, providing:

- **Transparency scores** (0-100) across 7 pillars
- **Complete evidence trails** with full provenance
- **Cryptographic verification** at multiple levels
- **Immutable historical snapshots** with blockchain-style chaining
- **Reproducible scoring** with locked methodologies

### Key Entities

**Firm:**
A proprietary trading company being evaluated.

**Snapshot:**
A point-in-time evaluation with score, evidence, and complete audit trail.

**Pillar:**
One of 7 dimensions of transparency (e.g., "Regulatory Compliance", "Team Structure").

**Evidence:**
Raw data supporting a score, with full provenance tracking.

**Provenance Graph:**
Complete data lineage from source to final score.

---

## 🛠️ SDK Installation

### TypeScript/JavaScript
```bash
npm install @gtixt/sdk
# or
yarn add @gtixt/sdk
```

### Python
```bash
pip install gtixt
```

---

## 💡 Common Workflows

### 1. Get Latest Firm Score
```typescript
const snapshot = await client.getLatestSnapshot('jane_street');
console.log(snapshot.score); // 87.5
```

### 2. Verify Score Calculation
```typescript
const verification = await client.verifyScore({
  firm_id: 'jane_street',
  snapshot_id: 'snap_abc123'
});
console.log(verification.verified); // true
```

### 3. Export Historical Data
```typescript
const history = await client.getSnapshotHistory({
  firm_id: 'jane_street',
  start_date: '2024-01-01',
  end_date: '2025-01-01'
});
```

### 4. Track Score Changes
```typescript
client.webhooks.subscribe('score_updated', {
  firm_id: 'jane_street',
  callback_url: 'https://yourapp.com/webhooks/gtixt'
});
```

---

## 🔐 Security Best Practices

### API Key Management
- **Never commit API keys** to source control
- **Use environment variables** for secrets
- **Rotate keys** every 90 days
- **Use separate keys** for dev/staging/production

### Request Security
- **Always use HTTPS** (HTTP not supported)
- **Validate webhook signatures** using HMAC
- **Implement rate limiting** on your end
- **Cache responses** where appropriate

### Data Handling
- **Verify cryptographic hashes** for critical data
- **Check snapshot signatures** for immutability
- **Validate data contracts** using provided schemas
- **Store provenance data** for audit trails

---

## 📞 Support & Resources

### Documentation
- [Full API Docs](./api/endpoints.md)
- [SDKs](./sdks/typescript.md)
- [Examples](./examples/verify-score.md)

### Community
- [GitHub Discussions](https://github.com/gtixt/community/discussions)
- [Stack Overflow](https://stackoverflow.com/questions/tagged/gtixt) - Tag: `gtixt`
- [Discord](https://discord.gg/gtixt)

### Support
- **Email:** support@gtixt.com
- **Response Time:** < 24 hours (business days)
- **Enterprise Support:** < 4 hours (24/7)

### Issues & Bugs
- [GitHub Issues](https://github.com/gtixt/sdk/issues)
- [Report a bug](https://gtixt.com/support/bug-report)

---

## 🎯 Interactive Tools

### API Explorer
Test API endpoints directly in your browser:

[Launch API Explorer →](./sandbox/api-explorer.md)

### Schema Validator
Validate your requests against our schemas:

[Schema Validator →](./sandbox/schema-validator.md)

### Code Generator
Generate code snippets in your language:

[Code Generator →](./sandbox/code-generator.md)

---

## 📈 Versioning & Updates

### Current Version
**API Version:** v1.0.0  
**Last Updated:** 2025-02-24  
**Status:** Stable

### Changelog
View all API changes and updates:

[View Changelog →](./status/changelog.md)

### Breaking Changes Policy
- **90 days notice** for breaking changes
- **Deprecated endpoints** supported for 1 year minimum
- **Version in URL path** (`/v1/`, `/v2/`, etc.)

---

## 🏆 Data Contracts & SLAs

### Signed Data Contract
Download our cryptographically signed data contract:

```bash
curl https://gtixt.com/contracts/v1.0.0.json > contract.json

# Verify signature
gtixt-cli verify-contract contract.json
```

[View Contract →](../DATA_CONTRACTS.md)

### Service Level Agreements
- **Uptime:** 99.9% guaranteed
- **Response Time (p95):** < 500ms
- **Data Accuracy:** 100% verifiable
- **Support Response:** < 24 hours

[Full SLAs →](../SLAS.md)

---

## 🌍 Transparency & Governance

GTIXT is committed to institutional-grade transparency:

- **Quarterly governance reports** published
- **Open methodology** documentation
- **Public error correction** logs
- **Committee decision** transparency
- **External audits** annually

[Governance Framework →](../GOVERNANCE.md)

---

## ✅ Getting Help

### Quick Links
- [FAQ](./support/faq.md)
- [Troubleshooting Guide](./support/troubleshooting.md)
- [Migration Guides](./support/migrations.md)
- [Best Practices](./support/best-practices.md)

### Contact
- **General:** developer@gtixt.com
- **Technical:** api-support@gtixt.com
- **Business:** partnerships@gtixt.com

---

**Last Updated:** 2025-02-24  
**Documentation Version:** 1.0.0
