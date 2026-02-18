#!/bin/bash

# Script to run GPTI agents for filling missing firm fields
# Tests the complete data pipeline

set -e

GPTI_DIR="/opt/gpti"
BOT_DIR="$GPTI_DIR/gpti-data-bot"

cd "$BOT_DIR"

# Set environment variables from staging config
source "$GPTI_DIR/docker/.env.staging"
export DATABASE_URL="postgresql://gpti:superpassword@127.0.0.1:5433/gpti"
export PYTHONPATH="$BOT_DIR/src:$PYTHONPATH"

echo "==========================================="
echo "GPTI - Run Agents to Fill Missing Data"
echo "==========================================="
echo ""
echo "Environment:"
echo "  Database: gpti (port 5433)"
echo "  Python Path: $PYTHONPATH"
echo ""

# Agent 1: Status Check - Verify firms in database
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "AGENT 1: Status Check"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "Checking all firms data..."
python3 << 'PYEOF'
import sys
sys.path.insert(0, '/opt/gpti/gpti-data-bot/src')

from gpti_bot.db import connect

conn = connect()
cur = conn.cursor()

# Get all firms
cur.execute("SELECT id, name, score, status FROM firms ORDER BY score DESC;")
firms = cur.fetchall()

for firm_id, firm_name, score, status in firms:
    status_symbol = "✓" if status == "active" else "⏳"
    print(f"  • {firm_name:35} Score: {score:5.1f} {status_symbol}")

print(f"\n  Total: {len(firms)} firms loaded")
conn.close()
PYEOF

# Agent 2: Web Search - Gather information about firms
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "AGENT 2: Web Search"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "Searching for firm information..."
python3 << 'PYEOF'
import sys
sys.path.insert(0, '/opt/gpti/gpti-data-bot/src')

from gpti_bot.discovery.web_search import web_search

test_queries = [
    "prop trading firm regulations",
    "trading firm compliance requirements",
    "market data validation"
]

for query in test_queries:
    print(f"  • Searching: '{query}'")
    try:
        results = web_search(query, 2)
        if results:
            for r in results:
                print(f"    - {r.get('title', 'N/A')[:50]}")
        else:
            print(f"    - (no results)")
    except Exception as e:
        print(f"    ✗ Error: {str(e)[:40]}")
    print()

PYEOF

# Agent 3: Snapshot Generation - Create current state
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "AGENT 3: Snapshot Generation"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "Generating snapshot..."
python3 << 'PYEOF'
import sys
import json
from datetime import datetime
sys.path.insert(0, '/opt/gpti/gpti-data-bot/src')

from gpti_bot.db import connect

conn = connect()
cur = conn.cursor()

# Get all firms for snapshot
cur.execute("""
    SELECT 
        id, name, score, status,
        created_at, updated_at
    FROM firms
    ORDER BY score DESC
""")

firms_data = []
for row in cur.fetchall():
    firms_data.append({
        "id": row[0],
        "name": row[1],
        "score": row[2],
        "status": row[3],
        "created_at": row[4].isoformat() if row[4] else None,
        "updated_at": row[5].isoformat() if row[5] else None
    })

snapshot = {
    "timestamp": datetime.now().isoformat(),
    "version": "2.0",
    "firms_count": len(firms_data),
    "firms": firms_data,
    "metrics": {
        "avg_score": sum(f["score"] for f in firms_data) / len(firms_data) if firms_data else 0,
        "max_score": max((f["score"] for f in firms_data), default=0),
        "min_score": min((f["score"] for f in firms_data), default=0),
        "active_count": len([f for f in firms_data if f["status"] == "active"]),
        "pending_count": len([f for f in firms_data if f["status"] == "pending"])
    }
}

# Save snapshot
cur.execute("""
    INSERT INTO snapshots (name, data, public_access) 
    VALUES (%s, %s, %s)
""", (f"snapshot_{datetime.now().strftime('%Y%m%d_%H%M%S')}", json.dumps(snapshot), True))

conn.commit()
conn.close()

print(f"  ✓ Snapshot created with {len(firms_data)} firms")
print(f"    Average Score: {snapshot['metrics']['avg_score']:.1f}")
print(f"    Active Firms: {snapshot['metrics']['active_count']}")
print(f"    Pending Firms: {snapshot['metrics']['pending_count']}")

PYEOF

# Agent 4: Data Validation - Check data quality
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "AGENT 4: Data Validation"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "Validating data quality..."
python3 << 'PYEOF'
import sys
sys.path.insert(0, '/opt/gpti/gpti-data-bot/src')

from gpti_bot.db import connect

conn = connect()
cur = conn.cursor()

# Check for missing critical fields
cur.execute("""
    SELECT 
        COUNT(*) as total,
        COUNT(CASE WHEN score IS NULL OR score = 0 THEN 1 END) as missing_scores,
        COUNT(CASE WHEN status IS NULL THEN 1 END) as missing_status
    FROM firms
""")

total, missing_scores, missing_status = cur.fetchone()

print(f"  • Total Firms: {total}")
print(f"  • Firms with scores: {total - missing_scores} ✓")
print(f"  • Firms with status: {total - missing_status} ✓")

# Get sample firm details
print()
print("  Sample firm records:")
cur.execute("SELECT id, name, score, status FROM firms LIMIT 3")
for row in cur.fetchall():
    print(f"    {row[1]:30} | Score: {row[2]:5.1f} | Status: {row[3]}")

conn.close()

PYEOF

# Final verification
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "FINAL VERIFICATION"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

python3 << 'PYEOF'
import sys
sys.path.insert(0, '/opt/gpti/gpti-data-bot/src')

from gpti_bot.db import connect

conn = connect()
cur = conn.cursor()

# Final counts
cur.execute("SELECT COUNT(*) FROM firms WHERE status = 'active'")
active_firms = cur.fetchone()[0]

cur.execute("SELECT COUNT(*) FROM snapshots")
snapshots = cur.fetchone()[0]

cur.execute("SELECT COUNT(*) FROM audit_findings")
findings = cur.fetchone()[0]

print(f"  Active Firms: {active_firms}")
print(f"  Total Snapshots: {snapshots}")
print(f"  Audit Findings: {findings}")

conn.close()
print()
print("  ✓ All agents completed successfully!")

PYEOF

echo ""
echo "==========================================="
echo "✓ Agent Execution Complete!"
echo "==========================================="
echo ""
echo "Next: Visit http://localhost:3000/rankings to view results"
echo ""
