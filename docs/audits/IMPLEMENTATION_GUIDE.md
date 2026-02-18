# 💻 GTIXT IMPLEMENTATION GUIDE - Code-Level Details

## 🎯 Critical Issues & Fixes

### ISSUE #1: Query Parameter Mismatch ⚠️ CRITICAL

#### Problem
Profile page sends `?firmId=` but API expects `?id=`

#### Affected Files
- **Frontend:** `/opt/gpti/gpti-site/pages/firm/[id].tsx` line 39
- **Backend:** `/opt/gpti/gpti-site/pages/api/firm.ts` line 60

#### Current Code (BROKEN)
```typescript
// File: pages/firm/[id].tsx, line 39
const fetchFirmDetails = async () => {
  try {
    const response = await fetch(`/api/firm?firmId=${id}`);  // ❌ WRONG PARAM
    if (response.ok) {
      const data = await response.json();
      setFirm(data);
    }
  } catch (error) {
    console.error('Failed to fetch firm:', error);
  } finally {
    setLoading(false);
  }
};
```

```typescript
// File: pages/api/firm.ts, line 60
const { id, name } = req.query;  // ✅ Expects 'id', not 'firmId'

if (!id && !name) {
  return res.status(400).json({ error: "Missing id or name parameter" });
}
```

#### Fix #1a: Update Profile Page (Quickest)
```typescript
// pages/firm/[id].tsx, line 39 - CHANGE TO:
const fetchFirmDetails = async () => {
  try {
    const response = await fetch(`/api/firm?id=${id}`);  // ✅ Use 'id' parameter
    if (response.ok) {
      const data = await response.json();
      setFirm(data);  // Expect { firm, snapshot } structure
    }
  } catch (error) {
    console.error('Failed to fetch firm:', error);
  } finally {
    setLoading(false);
  }
};
```

#### Fix #1b: Add Alias Support (More Robust)
```typescript
// pages/api/firm.ts, line 60 - CHANGE TO:
const { id: paramId, firmId, name } = req.query;
const id = paramId || firmId;  // Support both 'id' and 'firmId'

if (!id && !name) {
  return res.status(400).json({ error: "Missing id or name parameter" });
}
```

**Recommended:** Use Fix #1b (supports both formats)

---

### ISSUE #2: API Returns Limited Data ⚠️ CRITICAL

#### Problem
`/api/firm` only returns data from test-snapshot.json, missing:
- Profile metadata (executive_summary, audit_verdict)
- Evidence records (112 exist in database)
- Historical scores
- Confidence/N/A rate details

#### Affected Files
- **Backend:** `/opt/gpti/gpti-site/pages/api/firm.ts` (complete rewrite needed)

#### Current Implementation (LIMITED)
```typescript
// File: pages/api/firm.ts, lines 130-160
export default async function handler(...) {
  // ... code to load snapshot.json ...
  
  // ❌ Only searches in snapshot data
  const firmRecord = rows.find((f: FirmRecord) => {
    if (idStr) {
      return (f.firm_id || "").toLowerCase() === idStr.toLowerCase();
    }
    // ... search logic ...
  });

  // ❌ Only returns snapshot data
  return res.status(200).json({ firm: firmRecord, snapshot: snapshotMetadata });
}
```

#### Required Fix
```typescript
// File: pages/api/firm.ts - Add database integration

import pg from 'pg';

const pgClient = new pg.Client({
  host: process.env.DB_HOST || 'localhost',
  port: parseInt(process.env.DB_PORT || '5432'),
  database: process.env.DB_NAME || 'gpti_data',
  user: process.env.DB_USER || 'postgres',
  password: process.env.DB_PASSWORD,
});

export default async function handler(
  req: NextApiRequest,
  res: NextApiResponse<ApiResponse>
) {
  // ... existing rate limiting ...

  const { id, name } = req.query;
  
  if (!id && !name) {
    return res.status(400).json({ error: "Missing id or name parameter" });
  }

  try {
    // Connect to database
    if (!pgClient._connected) {
      await pgClient.connect();
    }

    // Query 1: Get firm + profile + latest score + audit
    const firmQuery = `
      SELECT 
        f.*,
        fp.executive_summary,
        fp.data_sources,
        fp.audit_verdict as profile_audit_verdict,
        fp.oversight_gate_verdict,
        ss.score_0_100,
        ss.confidence,
        ss.na_rate,
        ss.pillar_scores,
        ss.metric_scores,
        aca.verdict as agent_verdict,
        aca.confidence as agent_confidence,
        aca.reasons as agent_reasons
      FROM firms f
      LEFT JOIN firm_profiles fp ON f.firm_id = fp.firm_id
      LEFT JOIN snapshot_scores ss ON f.firm_id = ss.firm_id 
        AND ss.snapshot_id = (
          SELECT snapshot_id FROM snapshot_metadata 
          ORDER BY created_at DESC LIMIT 1
        )
      LEFT JOIN agent_c_audit aca ON f.firm_id = aca.firm_id
      WHERE LOWER(f.firm_id) = LOWER($1) 
         OR LOWER(f.name) = LOWER($2)
      LIMIT 1
    `;
    
    const firmResult = await pgClient.query(firmQuery, [
      id || '',
      name || ''
    ]);

    if (firmResult.rows.length === 0) {
      return res.status(404).json({ 
        error: `Firm not found: ${id || name}` 
      });
    }

    const firmRecord = firmResult.rows[0];
    const firmId = firmRecord.firm_id;

    // Query 2: Get evidence records
    const evidenceQuery = `
      SELECT id, key, source, source_url, excerpt, sha256, raw_object_path, created_at
      FROM evidence 
      WHERE firm_id = $1
      ORDER BY created_at DESC
    `;
    
    const evidenceResult = await pgClient.query(evidenceQuery, [firmId]);
    const evidenceRecords = evidenceResult.rows;

    // Query 3: Get historical scores (last 12 months or all if fewer)
    const historyQuery = `
      SELECT 
        sm.snapshot_key,
        sm.created_at,
        ss.score_0_100,
        ss.confidence,
        ss.pillar_scores,
        ss.metric_scores
      FROM snapshot_metadata sm
      JOIN snapshot_scores ss ON sm.snapshot_id = ss.snapshot_id
      WHERE ss.firm_id = $1
      ORDER BY sm.created_at DESC
      LIMIT 12
    `;
    
    const historyResult = await pgClient.query(historyQuery, [firmId]);
    const scoreHistory = historyResult.rows;

    // Combine into complete response
    const completeProfile = {
      ...firmRecord,
      evidence: evidenceRecords,
      history: scoreHistory
    };

    res.setHeader(
      "Cache-Control", 
      "public, max-age=300, s-maxage=300, stale-while-revalidate=600"
    );

    return res.status(200).json({ 
      firm: completeProfile,
      snapshot: {
        count: evidenceRecords.length,
        source: 'postgresql'
      }
    });

  } catch (error) {
    console.error('[API] Firm endpoint error:', error);
    return res.status(500).json({
      error: error instanceof Error ? error.message : "Unknown error"
    });
  }
}
```

**Implementation Time:** ~60 minutes

---

### ISSUE #3: Profile Page Incomplete ⚠️ HIGH

#### Problem
Profile page only displays basic info. Missing major sections:
1. Pillar scores breakdown (5 scores)
2. Metrics breakdown (6 scores from agents)
3. Evidence display (2-12 records)
4. Historical chart
5. Audit verdict badge
6. Confidence/quality indicators

#### Affected Files
- **Frontend:** `/opt/gpti/gpti-site/pages/firm/[id].tsx` (extend from 283 lines)

#### Current Implementation (BASIC)
```typescript
// pages/firm/[id].tsx - currently shows:
- Firm header ✅
- Status badge ✅
- Website link ✅
- Overall score card ✅
- Optional sub-score cards ⚠️ (transparency, legal, payout - not from API)
- AgentEvidence component ✅

// Missing sections:
- ❌ Pillar scores with visualization
- ❌ Metrics breakdown (6 agents)
- ❌ Evidence section with list
- ❌ Historical chart
- ❌ Audit verdict + gate status
- ❌ Data quality indicators
```

#### Required Fix - Extend Component

**Step 1: Create new component for pillar scores**
```typescript
// File: components/PillarScoresChart.tsx (NEW)
import React from 'react';

interface PillarScores {
  governance: number;
  fair_dealing: number;
  market_integrity: number;
  regulatory_compliance: number;
  operational_resilience: number;
}

interface Props {
  scores: PillarScores;
}

export default function PillarScoresChart({ scores }: Props) {
  const pillars = [
    { name: 'Governance', value: scores.governance },
    { name: 'Fair Dealing', value: scores.fair_dealing },
    { name: 'Market Integrity', value: scores.market_integrity },
    { name: 'Regulatory Compliance', value: scores.regulatory_compliance },
    { name: 'Operational Resilience', value: scores.operational_resilience },
  ];

  return (
    <div className="pillar-scores">
      <h2>Pillar Scores Breakdown</h2>
      <div className="pillars-grid">
        {pillars.map((pillar) => (
          <div key={pillar.name} className="pillar-card">
            <h3>{pillar.name}</h3>
            <div className="score-value">{pillar.value}</div>
            <div className="score-bar">
              <div 
                className="score-fill" 
                style={{ width: `${pillar.value}%` }}
              ></div>
            </div>
            <div className="score-label">{pillar.value}/100</div>
          </div>
        ))}
      </div>
      <style jsx>{`
        .pillar-scores {
          margin: 3rem 0;
        }
        .pillar-scores h2 {
          margin-bottom: 1.5rem;
          font-size: 1.5rem;
        }
        .pillars-grid {
          display: grid;
          grid-template-columns: repeat(auto-fit, minmax(150px, 1fr));
          gap: 1rem;
        }
        .pillar-card {
          background: white;
          border: 1px solid #ddd;
          border-radius: 8px;
          padding: 1rem;
          text-align: center;
        }
        .pillar-card h3 {
          margin: 0 0 0.5rem 0;
          font-size: 0.875rem;
          color: #666;
          text-transform: uppercase;
          font-weight: 600;
        }
        .score-value {
          font-size: 1.75rem;
          font-weight: bold;
          color: #0066cc;
          margin: 0.5rem 0;
        }
        .score-bar {
          height: 6px;
          background: #e5e5e5;
          border-radius: 3px;
          overflow: hidden;
          margin: 0.5rem 0;
        }
        .score-fill {
          height: 100%;
          background: linear-gradient(90deg, #0066cc, #00a3ff);
        }
        .score-label {
          font-size: 0.75rem;
          color: #999;
        }
      `}</style>
    </div>
  );
}
```

**Step 2: Create metrics breakdown component**
```typescript
// File: components/MetricsBreakdown.tsx (NEW)
import React from 'react';

interface MetricScores {
  rvi: number;   // Reputation
  sss: number;   // Systemic Stress
  rem: number;   // Risk Management
  irs: number;   // Information Ready
  frp: number;   // Financial Performance
  mis: number;   // Market Integrity
}

interface Props {
  scores: MetricScores;
}

const METRIC_NAMES = {
  rvi: { name: 'Reputation Index', abbr: 'RVI' },
  sss: { name: 'Systemic Stress Score', abbr: 'SSS' },
  rem: { name: 'Risk Management', abbr: 'REM' },
  irs: { name: 'Information Ready Score', abbr: 'IRS' },
  frp: { name: 'Financial Performance', abbr: 'FRP' },
  mis: { name: 'Market Integrity Score', abbr: 'MIS' },
};

export default function MetricsBreakdown({ scores }: Props) {
  const metrics = Object.entries(scores).map(([key, value]) => ({
    key,
    ...METRIC_NAMES[key as keyof MetricScores],
    value,
  }));

  return (
    <div className="metrics-breakdown">
      <h2>Agent Analysis - 6 Metrics</h2>
      <div className="metrics-list">
        {metrics.map((metric) => (
          <div key={metric.key} className="metric-row">
            <div className="metric-info">
              <div className="metric-name">
                <strong>{metric.abbr}</strong> - {metric.name}
              </div>
            </div>
            <div className="metric-score">
              <div className="score-value">{metric.value}</div>
            </div>
            <div className="metric-bar">
              <div 
                className="metric-fill" 
                style={{ width: `${metric.value}%` }}
              ></div>
            </div>
          </div>
        ))}
      </div>
      <style jsx>{`
        .metrics-breakdown {
          margin: 3rem 0;
        }
        .metrics-breakdown h2 {
          margin-bottom: 1.5rem;
          font-size: 1.5rem;
        }
        .metrics-list {
          display: flex;
          flex-direction: column;
          gap: 1rem;
        }
        .metric-row {
          display: grid;
          grid-template-columns: 1fr 60px 150px;
          gap: 1rem;
          align-items: center;
          background: white;
          padding: 1rem;
          border-radius: 8px;
          border: 1px solid #ddd;
        }
        .metric-name {
          font-size: 0.875rem;
        }
        .metric-name strong {
          color: #0066cc;
          font-weight: 600;
        }
        .score-value {
          text-align: center;
          font-weight: bold;
          font-size: 1.25rem;
          color: #0066cc;
        }
        .metric-bar {
          height: 8px;
          background: #e5e5e5;
          border-radius: 4px;
          overflow: hidden;
        }
        .metric-fill {
          height: 100%;
          background: linear-gradient(90deg, #0066cc, #00a3ff);
        }
      `}</style>
    </div>
  );
}
```

**Step 3: Create evidence section component**
```typescript
// File: components/EvidenceSection.tsx (NEW)
import React, { useState } from 'react';

interface EvidenceRecord {
  id: string;
  key: string;
  source: string;
  source_url: string;
  excerpt: Record<string, any>;
  created_at: string;
}

interface Props {
  evidence: EvidenceRecord[];
}

export default function EvidenceSection({ evidence }: Props) {
  const [expandedId, setExpandedId] = useState<string | null>(null);

  if (!evidence || evidence.length === 0) {
    return (
      <div className="evidence-section">
        <h2>Evidence & Data Sources</h2>
        <p>No evidence records found.</p>
      </div>
    );
  }

  return (
    <div className="evidence-section">
      <h2>Evidence & Data Sources ({evidence.length} records)</h2>
      <div className="evidence-list">
        {evidence.map((record) => (
          <div 
            key={record.id} 
            className="evidence-card"
            onClick={() => setExpandedId(
              expandedId === record.id ? null : record.id
            )}
          >
            <div className="evidence-header">
              <div className="evidence-info">
                <h3>{record.source}</h3>
                <p className="evidence-key">{record.key}</p>
              </div>
              <div className="evidence-actions">
                <button 
                  className="icon-btn"
                  onClick={(e) => {
                    e.stopPropagation();
                    window.open(record.source_url, '_blank');
                  }}
                >
                  🔗 Visit
                </button>
                <span className="expand-icon">
                  {expandedId === record.id ? '▼' : '▶'}
                </span>
              </div>
            </div>
            
            {expandedId === record.id && (
              <div className="evidence-details">
                <div className="evidence-excerpt">
                  <h4>Details:</h4>
                  <pre>{JSON.stringify(record.excerpt, null, 2)}</pre>
                </div>
                <div className="evidence-metadata">
                  <small>Source: {record.source_url}</small>
                  <small>Updated: {new Date(record.created_at).toLocaleDateString()}</small>
                </div>
              </div>
            )}
          </div>
        ))}
      </div>
      <style jsx>{`
        .evidence-section {
          margin: 3rem 0;
        }
        .evidence-section h2 {
          margin-bottom: 1.5rem;
          font-size: 1.5rem;
        }
        .evidence-list {
          display: flex;
          flex-direction: column;
          gap: 1rem;
        }
        .evidence-card {
          background: white;
          border: 1px solid #ddd;
          border-radius: 8px;
          overflow: hidden;
          cursor: pointer;
          transition: border-color 0.2s;
        }
        .evidence-card:hover {
          border-color: #0066cc;
        }
        .evidence-header {
          display: flex;
          justify-content: space-between;
          align-items: center;
          padding: 1rem;
          background: #f9f9f9;
        }
        .evidence-info h3 {
          margin: 0;
          color: #0066cc;
          font-size: 1rem;
        }
        .evidence-key {
          margin: 0.25rem 0 0 0;
          color: #666;
          font-size: 0.875rem;
        }
        .evidence-actions {
          display: flex;
          gap: 0.5rem;
          align-items: center;
        }
        .icon-btn {
          padding: 0.5rem 1rem;
          background: #0066cc;
          color: white;
          border: none;
          border-radius: 4px;
          cursor: pointer;
          font-size: 0.875rem;
        }
        .icon-btn:hover {
          background: #0052a3;
        }
        .expand-icon {
          font-size: 0.75rem;
          color: #666;
        }
        .evidence-details {
          padding: 1rem;
          border-top: 1px solid #e5e5e5;
          background: #fafafa;
        }
        .evidence-excerpt {
          margin-bottom: 1rem;
        }
        .evidence-excerpt h4 {
          margin: 0 0 0.5rem 0;
          font-size: 0.875rem;
          color: #666;
        }
        .evidence-excerpt pre {
          background: white;
          padding: 0.75rem;
          border-radius: 4px;
          border: 1px solid #ddd;
          overflow-x: auto;
          font-size: 0.75rem;
          margin: 0;
        }
        .evidence-metadata {
          display: flex;
          gap: 1rem;
          font-size: 0.75rem;
          color: #999;
        }
      `}</style>
    </div>
  );
}
```

**Step 4: Update profile page to use new components**
```typescript
// File: pages/firm/[id].tsx - UPDATE MAIN COMPONENT

import { useRouter } from 'next/router';
import { useState, useEffect } from 'react';
import Layout from '../../components/Layout';
import SeoHead from '../../components/SeoHead';
import PillarScoresChart from '../../components/PillarScoresChart';
import MetricsBreakdown from '../../components/MetricsBreakdown';
import EvidenceSection from '../../components/EvidenceSection';
import AgentEvidence from '../../components/AgentEvidence';
import { useTranslation } from '../../lib/useTranslationStub';

interface FirmData {
  firm_id: string;
  name: string;
  website_root?: string;
  logo_url?: string;
  status: string;
  score_0_100: number;
  confidence: number;
  na_rate: number;
  pillar_scores: Record<string, number>;
  metric_scores: Record<string, number>;
  agent_verdict?: string;
  executive_summary?: string;
  data_sources?: string[];
  evidence?: any[];
  history?: any[];
}

export default function FirmDetail() {
  const { t } = useTranslation("common");
  const router = useRouter();
  const { id } = router.query;
  
  const [firm, setFirm] = useState<FirmData | null>(null);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);

  useEffect(() => {
    if (!id) return;
    fetchFirmDetails();
  }, [id]);

  const fetchFirmDetails = async () => {
    try {
      setLoading(true);
      setError(null);
      
      // Use corrected query parameter
      const response = await fetch(`/api/firm?id=${id}`);
      
      if (!response.ok) {
        throw new Error(`Failed to fetch: ${response.status}`);
      }
      
      const data = await response.json();
      setFirm(data.firm);
    } catch (err) {
      console.error('Failed to fetch firm:', err);
      setError(err instanceof Error ? err.message : 'Unknown error');
    } finally {
      setLoading(false);
    }
  };

  if (loading) {
    return (
      <Layout>
        <div className="loading-container">
          <div className="spinner"></div>
          <p>{t("firmDetail.loading")}</p>
        </div>
        <style jsx>{`
          .loading-container {
            text-align: center;
            padding: 4rem;
          }
          .spinner {
            width: 50px;
            height: 50px;
            border: 4px solid #f3f3f3;
            border-top: 4px solid #0066cc;
            border-radius: 50%;
            animation: spin 1s linear infinite;
            margin: 0 auto 1rem;
          }
          @keyframes spin {
            0% { transform: rotate(0deg); }
            100% { transform: rotate(360deg); }
          }
        `}</style>
      </Layout>
    );
  }

  if (error || !firm) {
    return (
      <Layout>
        <div className="error-container">
          <h1>{t("firmDetail.notFound")}</h1>
          <p>{error || t("firmDetail.notFoundDescription")}</p>
          <button onClick={() => router.push('/')}>
            {t("firmDetail.backToFirms")}
          </button>
        </div>
      </Layout>
    );
  }

  return (
    <>
      <SeoHead
        title={`${firm.name} - GTIXT`}
        description={`Detailed analysis and verification for ${firm.name}`}
      />
      <Layout>
        <div className="firm-detail">
          {/* SECTION 1: Header */}
          <div className="firm-header">
            <div className="firm-title">
              <h1>{firm.name}</h1>
              <span className={`status-badge status-${firm.status}`}>
                {firm.status}
              </span>
            </div>
            
            {firm.website_root && (
              <a 
                href={firm.website_root} 
                target="_blank" 
                rel="noopener noreferrer"
                className="website-link"
              >
                Visit Website →
              </a>
            )}
          </div>

          {/* SECTION 2: Executive Summary */}
          {firm.executive_summary && (
            <div className="summary-section">
              <p>{firm.executive_summary}</p>
            </div>
          )}

          {/* SECTION 3: Score Overview */}
          <div className="scores-overview">
            <div className="score-card primary">
              <h3>Overall Score</h3>
              <div className="score-value">{firm.score_0_100}</div>
              <div className="score-bar">
                <div 
                  className="score-fill" 
                  style={{ width: `${firm.score_0_100}%` }}
                ></div>
              </div>
            </div>

            <div className="score-card">
              <h3>Confidence</h3>
              <div className="score-value">{(firm.confidence * 100).toFixed(0)}%</div>
              <p className="score-detail">Analysis confidence</p>
            </div>

            <div className="score-card">
              <h3>Data Quality</h3>
              <div className="score-value">{100 - firm.na_rate}%</div>
              <p className="score-detail">{firm.na_rate}% N/A</p>
            </div>
          </div>

          {/* SECTION 4: Pillar Scores */}
          {firm.pillar_scores && (
            <PillarScoresChart scores={firm.pillar_scores} />
          )}

          {/* SECTION 5: Metrics Breakdown */}
          {firm.metric_scores && (
            <MetricsBreakdown scores={firm.metric_scores} />
          )}

          {/* SECTION 6: Evidence */}
          {firm.evidence && firm.evidence.length > 0 && (
            <EvidenceSection evidence={firm.evidence} />
          )}

          {/* SECTION 7: Audit Verdict */}
          {firm.agent_verdict && (
            <div className="audit-section">
              <h2>Audit Verdict</h2>
              <div className={`verdict-badge verdict-${firm.agent_verdict}`}>
                {firm.agent_verdict === 'pass' ? '✓ PASS' : '⚠ REVIEW'}
              </div>
              <p>Quality gate status for publication approval</p>
            </div>
          )}

          {/* SECTION 8: Agent Evidence */}
          <AgentEvidence firmId={firm.firm_id} />
        </div>

        <style jsx>{`
          .firm-detail {
            max-width: 1200px;
            margin: 0 auto;
            padding: 2rem;
          }

          .firm-header {
            display: flex;
            justify-content: space-between;
            align-items: center;
            margin-bottom: 2rem;
            padding-bottom: 1.5rem;
            border-bottom: 2px solid #e5e5e5;
          }

          .firm-title {
            display: flex;
            align-items: center;
            gap: 1rem;
          }

          .firm-title h1 {
            margin: 0;
            font-size: 2rem;
          }

          .status-badge {
            padding: 0.25rem 0.75rem;
            border-radius: 12px;
            font-size: 0.875rem;
            font-weight: 600;
            text-transform: uppercase;
          }

          .status-candidate {
            background: #fff3cd;
            color: #856404;
          }

          .status-active {
            background: #d1f4e0;
            color: #0f5132;
          }

          .website-link {
            color: #0066cc;
            text-decoration: none;
            font-weight: 500;
          }

          .website-link:hover {
            text-decoration: underline;
          }

          .summary-section {
            background: #f9f9f9;
            padding: 1.5rem;
            border-radius: 8px;
            margin-bottom: 2rem;
            line-height: 1.6;
            color: #333;
          }

          .scores-overview {
            display: grid;
            grid-template-columns: repeat(auto-fit, minmax(180px, 1fr));
            gap: 1.5rem;
            margin-bottom: 3rem;
          }

          .score-card {
            background: white;
            border: 1px solid #ddd;
            border-radius: 8px;
            padding: 1.5rem;
          }

          .score-card.primary {
            border: 2px solid #0066cc;
            background: #f0f7ff;
          }

          .score-card h3 {
            margin: 0 0 0.5rem 0;
            font-size: 0.875rem;
            color: #666;
            text-transform: uppercase;
            font-weight: 600;
          }

          .score-value {
            font-size: 2.5rem;
            font-weight: bold;
            color: #0066cc;
          }

          .score-detail {
            margin: 0.5rem 0 0 0;
            font-size: 0.875rem;
            color: #999;
          }

          .score-bar {
            margin-top: 0.5rem;
            height: 8px;
            background: #e5e5e5;
            border-radius: 4px;
            overflow: hidden;
          }

          .score-fill {
            height: 100%;
            background: linear-gradient(90deg, #0066cc, #00a3ff);
            transition: width 0.5s ease;
          }

          .audit-section {
            margin: 3rem 0;
            padding: 2rem;
            background: white;
            border-radius: 8px;
            border: 1px solid #ddd;
            text-align: center;
          }

          .audit-section h2 {
            margin-top: 0;
          }

          .verdict-badge {
            display: inline-block;
            padding: 0.5rem 1.5rem;
            border-radius: 8px;
            font-size: 1.25rem;
            font-weight: 600;
            margin: 1rem 0;
          }

          .verdict-pass {
            background: #d1f4e0;
            color: #0f5132;
          }

          .verdict-review {
            background: #fff3cd;
            color: #856404;
          }

          @media (max-width: 768px) {
            .firm-header {
              flex-direction: column;
              align-items: flex-start;
            }

            .firm-title {
              flex-direction: column;
            }

            .website-link {
              margin-top: 1rem;
            }

            .scores-overview {
              grid-template-columns: 1fr;
            }
          }
        `}</style>
      </Layout>
    </>
  );
}
```

**Implementation Time:** ~2 hours

---

## 📊 Database Connection Setup

### Environment Variables Needed
```
# .env.local (for development)
DB_HOST=localhost
DB_PORT=5432
DB_NAME=gpti_data
DB_USER=postgres
DB_PASSWORD=your_password
```

### Database Connection Module
```typescript
// lib/dbConnection.ts (NEW)
import pg from 'pg';

let client: pg.Client | null = null;

export async function getDbConnection(): Promise<pg.Client> {
  if (client && client._connected) {
    return client;
  }

  client = new pg.Client({
    host: process.env.DB_HOST || 'localhost',
    port: parseInt(process.env.DB_PORT || '5432'),
    database: process.env.DB_NAME || 'gpti_data',
    user: process.env.DB_USER || 'postgres',
    password: process.env.DB_PASSWORD,
  });

  await client.connect();
  console.log('[DB] Connected to PostgreSQL');
  return client;
}

export async function closeDbConnection(): Promise<void> {
  if (client && client._connected) {
    await client.end();
    console.log('[DB] Disconnected from PostgreSQL');
  }
}
```

---

## 🧪 Testing Checklist

### Quick Test After Fixes
```bash
# Test 1: List endpoint
curl "http://localhost:3000/api/firms?limit=5"

# Test 2: Detail endpoint with id
curl "http://localhost:3000/api/firm?id=-op-ne-rader"

# Test 3: Detail endpoint with name
curl "http://localhost:3000/api/firm?name=Top%20One%20Trader"

# Test 4: Detail endpoint with firmId alias (after fix)
curl "http://localhost:3000/api/firm?firmId=-op-ne-rader"

# Expected response includes:
# - firm.pillar_scores
# - firm.metric_scores
# - firm.evidence (array)
# - firm.history (array)
# - firm.executive_summary
# - firm.agent_verdict
```

### Browser Tests
1. Navigate to `http://localhost:3000/`
2. Click on a firm name
3. Verify profile page loads
4. Scroll through all sections:
   - Header ✅
   - Summary ✅
   - Score overview ✅
   - Pillar scores chart ✅
   - Metrics breakdown ✅
   - Evidence section ✅
   - Audit verdict ✅
   - Agent evidence ✅

---

## 📈 Performance Optimization

### Add Database Indexes
```sql
-- Index for firm lookup
CREATE INDEX IF NOT EXISTS idx_firms_firm_id 
ON firms(LOWER(firm_id));

-- Index for firm name lookup
CREATE INDEX IF NOT EXISTS idx_firms_name 
ON firms(LOWER(name));

-- Index for evidence lookup
CREATE INDEX IF NOT EXISTS idx_evidence_firm_id 
ON evidence(firm_id);

-- Index for snapshot scores
CREATE INDEX IF NOT EXISTS idx_snapshot_scores_firm_id 
ON snapshot_scores(firm_id, snapshot_id DESC);

-- Index for audit lookup
CREATE INDEX IF NOT EXISTS idx_agent_c_audit_firm_id 
ON agent_c_audit(firm_id, verdict);
```

### Add Response Caching
```typescript
// In API responses
res.setHeader(
  "Cache-Control",
  "public, max-age=300, s-maxage=300, stale-while-revalidate=600"
);
```

---

## 🚀 Deployment Order

1. **Fix critical issues** (Day 1)
   - Query parameter mismatch
   - API database integration
   - Profile page fetch

2. **Create new components** (Day 2)
   - PillarScoresChart
   - MetricsBreakdown
   - EvidenceSection

3. **Update profile page** (Day 2)
   - Integrate new components
   - Add styling
   - Test responsiveness

4. **Test thoroughly** (Day 3)
   - API tests
   - Browser tests
   - Edge cases (no evidence, no history)

5. **Deploy to production** (Day 3)
   - Environment variables
   - Database indexes
   - Cache headers

---

**File:** `/opt/gpti/IMPLEMENTATION_GUIDE.md`  
**Created:** 2026-02-05  
**Status:** Ready to implement
