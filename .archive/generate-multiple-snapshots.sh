#!/bin/bash

# Script to generate multiple snapshots with real data for GPTI system
# This enables testing of Snapshot History and data comparison features

set -e

echo "=========================================="
echo "GPTI - Generate Multiple Snapshots"
echo "=========================================="

GPTI_DIR="/opt/gpti"
BOT_DIR="$GPTI_DIR/gpti-data-bot"
SNAPSHOTS_COUNT=${1:-3}
DELAY_BETWEEN=${2:-2}  # seconds between snapshots

cd "$BOT_DIR"

echo "Environment: Setting up Python path..."
export PYTHONPATH="$BOT_DIR/src:$PYTHONPATH"

# Check if we have at least one firm in the database
echo ""
echo "Checking database state..."
python3 -c "
from gpti_bot.db import connect
with connect() as conn:
    cur = conn.cursor()
    cur.execute('SELECT COUNT(*) FROM firms')
    count = cur.fetchone()[0]
    print(f'Firms in database: {count}')
    if count == 0:
        print('⚠️  WARNING: No firms in database. Run seed data first.')
        print('   Consider: cd $BOT_DIR && python3 load_seed_data.py')
" || true

echo ""
echo "Generating $SNAPSHOTS_COUNT snapshots with $DELAY_BETWEEN second intervals..."
echo ""

for i in $(seq 1 $SNAPSHOTS_COUNT); do
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "Snapshot $i/$SNAPSHOTS_COUNT - $(date '+%Y-%m-%d %H:%M:%S UTC' -u)"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    
    # Step 1: Export snapshot (public=false for internal)
    echo "  [1/3] Exporting snapshot..."
    python3 -m gpti_bot export-snapshot --public 2>&1 | grep -E "\[export\]|snapshot|object|sha256|✓|✗" || true
    
    # Step 2: Score snapshot
    echo "  [2/3] Scoring snapshot..."
    python3 -m gpti_bot score-snapshot 2>&1 | grep -E "\[score\]|scored|avg_score|✓|✗" || true
    
    # Step 3: Verify snapshot (Oversight Gate)
    echo "  [3/3] Running verification (Oversight Gate)..."
    python3 -m gpti_bot verify-snapshot 2>&1 | grep -E "\[verify\]|verdict|passed|failed|✓|✗" || true
    
    echo ""
    
    if [ $i -lt $SNAPSHOTS_COUNT ]; then
        echo "⏳ Waiting $DELAY_BETWEEN seconds before next snapshot..."
        sleep $DELAY_BETWEEN
    fi
done

echo ""
echo "=========================================="
echo "✓ Snapshot generation complete!"
echo "=========================================="
echo ""
echo "Next steps:"
echo "1. Visit http://localhost:3000/rankings to see all firms"
echo "2. Click on a firm to view details"
echo "3. Scroll to 'Snapshot History' to see historical data"
echo "4. Use 'Download Raw JSON' to export snapshot"
echo "5. Use 'Verify Snapshot' to validate integrity"
echo ""
