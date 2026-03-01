# GTIXT Quickstart Guide

Get started with GTIXT API in 5 minutes.

---

## Prerequisites

- Node.js 16+ or Python 3.8+
- GTIXT API key ([get one here](https://gtixt.com/dashboard/api-keys))

---

## Step 1: Install SDK

Choose your preferred language:

### TypeScript/JavaScript
```bash
npm install @gtixt/sdk
```

### Python
```bash
pip install gtixt
```

---

## Step 2: Set Your API Key

Create a `.env` file in your project root:

```bash
GTIXT_API_KEY=your_api_key_here
```

**Security:** Never commit API keys to git. Add `.env` to `.gitignore`.

---

## Step 3: Make Your First Request

### TypeScript/JavaScript

```typescript
import { GTIXTClient } from '@gtixt/sdk';

const client = new GTIXTClient({
  apiKey: process.env.GTIXT_API_KEY
});

async function main() {
  try {
    // Get latest snapshot for Jane Street
    const snapshot = await client.getLatestSnapshot('jane_street');
    
    console.log('=== Jane Street Transparency Score ===');
    console.log(`Score: ${snapshot. score}/100`);
    console.log(`Percentile: ${snapshot.percentile}th`);
    console.log(`Status: ${snapshot.status}`);
    console.log(`Last Updated: ${snapshot.timestamp}`);
    
    console.log('\n=== Pillar Scores ===');
    Object.entries(snapshot.pillar_scores).forEach(([pillar, score]) => {
      console.log(`${pillar}: ${score}/100`);
    });
    
  } catch (error) {
    console.error('Error:', error.message);
  }
}

main();
```

**Output:**
```
=== Jane Street Transparency Score ===
Score: 87.5/100
Percentile: 95th
Status: active
Last Updated: 2025-02-20T00:00:00Z

=== Pillar Scores ===
regulatory_compliance: 92/100
team_structure: 88/100
technology_infrastructure: 85/100
risk_management: 90/100
capital_transparency: 82/100
track_record: 89/100
market_reputation: 86/100
```

### Python

```python
from gtixt import GTIXTClient
import os

client = GTIXTClient(api_key=os.environ['GTIXT_API_KEY'])

# Get latest snapshot
snapshot = client.get_latest_snapshot('jane_street')

print('=== Jane Street Transparency Score ===')
print(f"Score: {snapshot.score}/100")
print(f"Percentile: {snapshot.percentile}th")
print(f"Status: {snapshot.status}")
print(f"Last Updated: {snapshot.timestamp}")

print('\n=== Pillar Scores ===')
for pillar, score in snapshot.pillar_scores.items():
    print(f"{pillar}: {score}/100")
```

---

## Step 4: Query Firms

### List All Firms

```typescript
const firms = await client.listFirms({
  status: 'active',
  min_score: 50,
  limit: 10
});

firms.forEach(firm => {
  console.log(`${firm.name}: ${firm.latest_score}`);
});
```

### Search Firms

```typescript
const results = await client.searchFirms({
  query: 'market making',
  min_score: 70
});
```

---

## Step 5: Get Historical Data

### Snapshot History

```typescript
const history = await client.getSnapshotHistory({
  firm_id: 'jane_street',
  start_date: '2024-01-01',
  end_date: '2025-01-01',
  limit: 100
});

// Calculate score trend
const scores = history.snapshots.map(s => s.score);
const avg = scores.reduce((a, b) => a + b) / scores.length;
console.log(`Average score (2024): ${avg.toFixed(1)}`);
```

---

## Step 6: Verify Score Integrity

GTIXT provides cryptographic verification of all scores:

```typescript
const verification = await client.verifyScore({
  firm_id: 'jane_street',
  snapshot_id: snapshot.snapshot_id
});

console.log('=== Verification Result ===');
console.log(`Score Verified: ${verification.verified}`);
console.log(`Hash Match: ${verification.hash_valid}`);
console.log(`Signature Valid: ${verification.signature_valid}`);
console.log(`Provenance Complete: ${verification.provenance_complete}`);
```

**Output:**
```
=== Verification Result ===
Score Verified: true
Hash Match: true
Signature Valid: true
Provenance Complete: true
```

---

## Step 7: Explore Evidence

Get the evidence behind a firm's score:

```typescript
const evidence = await client.getEvidence({
  firm_id: 'jane_street',
  snapshot_id: snapshot.snapshot_id
});

console.log(`Total evidence items: ${evidence.total_items}`);
console.log('\n=== Evidence by Pillar ===');

Object.entries(evidence.by_pillar).forEach(([pillar, items]) => {
  console.log(`\n${pillar}:`);
  items.slice(0, 3).forEach(item => {
    console.log(`  - ${item.description}`);
    console.log(`    Source: ${item.source}`);
    console.log(`    Confidence: ${item.confidence_level}`);
  });
});
```

---

## Step 8: Handle Errors

Always implement proper error handling:

```typescript
import { GTIXTError, ValidationError, RateLimitError } from '@gtixt/sdk';

try {
  const snapshot = await client.getLatestSnapshot('invalid_firm_id');
  
} catch (error) {
  if (error instanceof ValidationError) {
    console.error('Validation error:', error.details);
    // error.details is array of field-level errors
    
  } else if (error instanceof RateLimitError) {
    console.error('Rate limit exceeded');
    console.error(`Retry after: ${error.retryAfter} seconds`);
    
  } else if (error instanceof GTIXTError) {
    console.error(`API error: ${error.message}`);
    console.error(`Status code: ${error.statusCode}`);
    
  } else {
    console.error('Unknown error:', error);
  }
}
```

---

## Next Steps

### Explore Advanced Features

1. **[Provenance Graphs](../examples/provenance-graph.md)**  
   Trace data lineage from source to score

2. **[Webhooks](../advanced/webhooks.md)**  
   Get real-time notifications when scores change

3. **[Bulk Export](../advanced/bulk-export.md)**  
   Download complete datasets for analysis

4. **[Custom Validation](../advanced/crypto-verification.md)**  
   Implement your own hash and signature verification

### Read Full Documentation

- [API Reference](../api/endpoints.md) - All endpoints documented
- [Data Models](../schemas/data-contracts.md) - Complete field specifications
- [SDK Examples](../sdks/examples.md) - Real-world usage patterns
- [Best Practices](../support/best-practices.md) - Production-ready patterns

### Join Community

- [GitHub Discussions](https://github.com/gtixt/community)
- [Discord](https://discord.gg/gtixt)
- [Stack Overflow](https://stackoverflow.com/questions/tagged/gtixt)

---

## Complete Example: Score Dashboard

Here's a complete example building a simple dashboard:

```typescript
import { GTIXTClient } from '@gtixt/sdk';
import { writeFileSync } from 'fs';

const client = new GTIXTClient({
  apiKey: process.env.GTIXT_API_KEY
});

async function buildDashboard() {
  // Get top 10 firms by score
  const topFirms = await client.listFirms({
    status: 'active',
    sort_by: 'score',
    order: 'desc',
    limit: 10
  });
  
  const dashboard = {
    generated_at: new Date().toISOString(),
    summary: {
      total_firms: topFirms.meta.total_count,
      average_score: 0,
      median_score: 0
    },
    top_firms: []
  };
  
  // Get detailed snapshots for top firms
  for (const firm of topFirms.firms) {
    const snapshot = await client.getLatestSnapshot(firm.firm_id);
    
    dashboard.top_firms.push({
      rank: dashboard.top_firms.length + 1,
      name: firm.name,
      score: snapshot.score,
      percentile: snapshot.percentile,
      pillar_scores: snapshot.pillar_scores,
      last_updated: snapshot.timestamp
    });
  }
  
  // Calculate summary stats
  const scores = dashboard.top_firms.map(f => f.score);
  dashboard.summary.average_score = 
    scores.reduce((a, b) => a + b) / scores.length;
  dashboard.summary.median_score = 
    scores.sort((a, b) => a - b)[Math.floor(scores.length / 2)];
  
  // Save to file
  writeFileSync(
    'gtixt_dashboard.json',
    JSON.stringify(dashboard, null, 2)
  );
  
  console.log('Dashboard generated: gtixt_dashboard.json');
  console.log(`Average score: ${dashboard.summary.average_score.toFixed(1)}`);
  console.log(`Median score: ${dashboard.summary.median_score.toFixed(1)}`);
}

buildDashboard().catch(console.error);
```

---

## Troubleshooting

### Issue: "Invalid API key"

**Solution:**  
- Verify your API key is correct
- Check environment variable is loaded
- Ensure key hasn't been revoked

### Issue: " Rate limit exceeded"

**Solution:**  
- Wait for rate limit window to reset (1 minute)
- Implement exponential backoff
- Upgrade to higher tier
- Cache responses to reduce requests

### Issue: "Firm not found"

**Solution:**  
- Check firm_id spelling (use underscore, lowercase)
- Verify firm exists: `client.searchFirms({ query: 'Firm Name' })`
- Firm may be retracted (check status)

---

## Support

Need help?

- **Email:** support@gtixt.com
- **Docs:** [Full Documentation](../README.md)
- **Status:** [API Status](../status/current.md)

---

**Next:** [Authentication Guide](./authentication.md) →
