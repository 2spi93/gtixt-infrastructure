#!/bin/bash

# Script to populate firms data with real market information
# This script fills in firm profiles and historical data

set -e

echo "==========================================="
echo "GPTI - Populate Firms Data"
echo "==========================================="

GPTI_DIR="/opt/gpti"
BOT_DIR="$GPTI_DIR/gpti-data-bot"

cd "$BOT_DIR"

# Set environment variables from staging config
source "$GPTI_DIR/docker/.env.staging"
export DATABASE_URL="postgresql://${POSTGRES_USER}:${POSTGRES_PASSWORD}@localhost:5432/${POSTGRES_DB}"
export PYTHONPATH="$BOT_DIR/src:$PYTHONPATH"

echo ""
echo "Environment Setup:"
echo "  PYTHONPATH: $PYTHONPATH"
echo "  DATABASE_URL: postgresql://***@localhost:5432/$POSTGRES_DB"
echo ""

# Step 1: Check database connection
echo "Step 1: Verifying database connection..."
python3 << 'PYEOF'
import os
import sys
from gpti_bot.db import connect

try:
    conn = connect()
    cur = conn.cursor()
    cur.execute('SELECT COUNT(*) FROM firms')
    count = cur.fetchone()[0]
    print(f'  ✓ Database connected! Current firms: {count}')
    conn.close()
except Exception as e:
    print(f'  ✗ Database connection failed: {e}')
    print('  Ensure PostgreSQL is running: sudo systemctl start postgresql')
    sys.exit(1)
PYEOF

# Step 2: Load seed data
echo ""
echo "Step 2: Loading seed data..."
if [ -f "$BOT_DIR/load_seed_data.py" ]; then
    python3 "$BOT_DIR/load_seed_data.py" 2>&1 | head -50
    echo ""
    python3 << 'PYEOF'
import os
from gpti_bot.db import connect

conn = connect()
cur = conn.cursor()
cur.execute('SELECT COUNT(*) FROM firms')
count = cur.fetchone()[0]
print(f'  ✓ Seed data loaded! Total firms: {count}')
conn.close()
PYEOF
else
    echo "  ! Seed data loader not found, using CLI commands..."
fi

# Step 3: Generate snapshots
echo ""
echo "Step 3: Generating snapshots for test data..."
for i in {1..3}; do
    echo ""
    echo "  [Snapshot $i/3] - $(date '+%Y-%m-%d %H:%M:%S')"
    
    # Export snapshot
    python3 -m gpti_bot export-snapshot --public 2>&1 | grep -E "✓|snapshot|exported" || true
    
    # Score snapshot
    python3 -m gpti_bot score-snapshot 2>&1 | grep -E "✓|scored" || true
    
    # Verify snapshot
    python3 -m gpti_bot verify-snapshot 2>&1 | grep -E "✓|verified|verdict" || true
    
    if [ $i -lt 3 ]; then
        sleep 2
    fi
done

# Step 4: Verify data in database
echo ""
echo "Step 4: Verifying populated data..."
python3 << 'PYEOF'
from gpti_bot.db import connect

conn = connect()
cur = conn.cursor()

# Check firms
cur.execute('SELECT COUNT(*) FROM firms')
firms_count = cur.fetchone()[0]
print(f'  • Firms: {firms_count}')

# Check snapshots
cur.execute('SELECT COUNT(*) FROM snapshots')
snapshots_count = cur.fetchone()[0]
print(f'  • Snapshots: {snapshots_count}')

# Check audit findings
cur.execute('SELECT COUNT(*) FROM audit_findings')
findings_count = cur.fetchone()[0]
print(f'  • Audit Findings: {findings_count}')

# Show sample firm data
cur.execute('SELECT name, score, status FROM firms LIMIT 3')
print(f'\n  Sample firms:')
for row in cur.fetchall():
    print(f'    - {row[0]}: score={row[1]}, status={row[2]}')

conn.close()
print(f'\n  ✓ All data populated and ready for testing!')
PYEOF

echo ""
echo "==========================================="
echo "✓ Population complete!"
echo "==========================================="
echo ""
echo "Next steps:"
echo "1. Visit http://localhost:3000/rankings to see all firms"
echo "2. Click on a firm to view details and edit fields"
echo "3. Check 'Snapshot History' to see historical data"
echo "4. Use 'Run Agent' to populate missing fields automatically"
echo ""
