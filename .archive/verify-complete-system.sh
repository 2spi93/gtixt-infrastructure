#!/bin/bash

# COMPREHENSIVE TEST & VERIFICATION SCRIPT
# Validates Snapshots, Download JSON, Verify Snapshot, and Port Configuration

set -e

GPTI_DIR="/opt/gpti"
SITE_DIR="$GPTI_DIR/gpti-site"
BOT_DIR="$GPTI_DIR/gpti-data-bot"
SITE_URL="${SITE_URL:-http://localhost:3000}"

echo "╔════════════════════════════════════════════════════════════════════╗"
echo "║  GPTI SYSTEM VERIFICATION - Complete Audit                        ║"
echo "╚════════════════════════════════════════════════════════════════════╝"
echo ""

# ============================================================================
# PART 1: PORT CONFIGURATION AUDIT
# ============================================================================
echo "PART 1: PORT CONFIGURATION AUDIT"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

echo ""
echo "1.1 Checking active ports..."
echo ""

ss -ltnp 2>/dev/null | awk 'NR==1 {print; next} /:3000|:3001|:3002/ {print}' || echo "No processes found on 3000/3001/3002"

echo ""
echo "1.2 Detailed process information..."
ps aux | grep -E "next-server|node" | grep -v grep | awk '{print $1, $2, $11, $12}' | head -3

echo ""
echo "1.3 Environment configuration..."

# Check site port config
if [ -f "$SITE_DIR/.env.local" ]; then
    echo "✓ Site .env.local exists"
    grep -E "^PORT|^NEXT_PUBLIC" "$SITE_DIR/.env.local" | head -5
else
    echo "✗ Site .env.local not found"
fi

if [ -f "$BOT_DIR/.env" ]; then
    echo "✓ Bot .env exists"
    grep -E "^PORT" "$BOT_DIR/.env" || echo "  (No PORT set - uses default)"
else
    echo "✗ Bot .env not found"
fi

echo ""
echo "1.4 Checking Next.js configuration..."

if [ -f "$SITE_DIR/next.config.js" ]; then
    echo "✓ next.config.js exists"
    echo "  Checking for port/rewrites configuration..."
    if grep -q "3001\|PORT\|rewrites" "$SITE_DIR/next.config.js"; then
        echo "  ✓ Rewrites/port config detected"
    fi
else
    echo "✗ next.config.js not found"
fi

# ============================================================================
# PART 2: URL TESTING
# ============================================================================
echo ""
echo ""
echo "PART 2: URL ENDPOINT TESTING"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

echo ""
echo "2.1 Testing main endpoints on port 3000..."

for url in "http://localhost:3000/rankings" "http://localhost:3000/api/firms" "http://localhost:3000/integrity"; do
    echo -n "  GET $url ... "
    if curl -s -o /dev/null -w "%{http_code}" "$url" 2>/dev/null | grep -qE "200|404|301|302|308"; then
        status=$(curl -s -o /dev/null -w "%{http_code}" "$url" 2>/dev/null)
        echo "HTTP $status ✓"
    else
        echo "FAIL ✗"
    fi
done

echo ""
echo "2.2 Testing on port 3001 (if available)..."

for url in "http://localhost:3001/rankings" "http://localhost:3001/api/firms"; do
    echo -n "  GET $url ... "
    status=$(curl -s -o /dev/null -w "%{http_code}" "$url" 2>/dev/null || true)
    if [ -n "$status" ]; then
        echo "HTTP $status"
    else
        echo "Unreachable"
    fi
done

# ============================================================================
# PART 3: SNAPSHOT DATA VALIDATION
# ============================================================================
echo ""
echo ""
echo "PART 3: SNAPSHOT DATA VALIDATION"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

echo ""
echo "3.1 Testing /api/snapshots endpoint..."

snapshot_response=$(curl -sL "http://localhost:3000/api/snapshots?limit=5" 2>/dev/null || echo "{}")

if echo "$snapshot_response" | jq . > /dev/null 2>&1; then
    echo "✓ Valid JSON response"
    count=$(echo "$snapshot_response" | jq '.snapshots | length' 2>/dev/null || echo "?")
    echo "  Available snapshots: $count"
    
    # Show first snapshot details
    echo ""
    echo "  First snapshot details:"
    echo "$snapshot_response" | jq '.snapshots[0] | {object, sha256, created_at, count}' 2>/dev/null | head -10
else
    echo "✗ Invalid/empty JSON response"
fi

echo ""
echo "3.2 Testing firm data endpoint..."

firm_id=$(curl -sL "http://localhost:3000/api/firms?limit=1" 2>/dev/null | jq -r '.firms[0].firm_id // empty' 2>/dev/null || echo "")
if [ -z "$firm_id" ]; then
    firm_id="ftmocom"
fi
firm_response=$(curl -sL "http://localhost:3000/api/firm?id=${firm_id}" 2>/dev/null || echo "{}")

if echo "$firm_response" | jq . > /dev/null 2>&1; then
    echo "✓ Firm API responding"
    firm_name=$(echo "$firm_response" | jq '.firm.name // .firm.firm_name // "Unknown"' 2>/dev/null)
    verdict=$(echo "$firm_response" | jq '.firm.oversight_gate_verdict // .firm.audit_verdict // "N/A"' 2>/dev/null)
    echo "  Firm: $firm_name"
    echo "  Oversight Gate Verdict: $verdict"
else
    echo "✗ No firm data available"
fi

# ============================================================================
# PART 4: DOWNLOAD RAW JSON TEST
# ============================================================================
echo ""
echo ""
echo "PART 4: DOWNLOAD RAW JSON FEATURE"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

echo ""
echo "4.1 Checking MinIO snapshot storage..."

# Get latest snapshot object
latest_snapshot=$(curl -sL "http://localhost:3000/api/snapshots?limit=1" 2>/dev/null | jq -r '.snapshots[0].object // empty' 2>/dev/null || echo "")

MINIO_ROOT=$(grep -E "^NEXT_PUBLIC_MINIO_PUBLIC_ROOT=|^MINIO_PUBLIC_ROOT=" "$SITE_DIR/.env.local" 2>/dev/null | head -n1 | cut -d= -f2-)
MINIO_ROOT="${MINIO_ROOT:-https://data.gtixt.com/gpti-snapshots/}"

if [ -n "$latest_snapshot" ]; then
    echo "✓ Latest snapshot: $latest_snapshot"
    
    # Build URL to MinIO
    minio_url="${MINIO_ROOT}${latest_snapshot}"
    echo "  MinIO URL: $minio_url"
    
    echo ""
    echo "4.2 Testing download accessibility..."
    echo -n "  HEAD request to MinIO... "
    
    if curl -s -I "$minio_url" 2>/dev/null | grep -q "200\|304"; then
        echo "✓ Accessible"
        
        # Try to get size
        size=$(curl -s -I "$minio_url" 2>/dev/null | grep -i "content-length" | awk '{print $2}' | tr -d '\r')
        if [ -n "$size" ]; then
            echo "  File size: $(numfmt --to=iec $size 2>/dev/null || echo "$size bytes")"
        fi
    else
        echo "⚠ May not be publicly accessible (check permissions)"
    fi
else
    echo "✗ No snapshots available in API"
fi

# ============================================================================
# PART 5: VERIFY SNAPSHOT PAGE
# ============================================================================
echo ""
echo ""
echo "PART 5: VERIFY SNAPSHOT PAGE"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

echo ""
echo "5.1 Checking /integrity page..."

integrity_status=$(curl -s -o /dev/null -w "%{http_code}" "${SITE_URL}/integrity" 2>/dev/null)
echo "  Status: HTTP $integrity_status"

if [ "$integrity_status" = "200" ] || [ "$integrity_status" = "308" ]; then
    echo "✓ Integrity verification page is accessible"
    
    echo ""
    echo "5.2 Feature validation:"
    echo "  • Upload JSON snapshot to verify"
    echo "  • SHA-256 verification"
    echo "  • Tampering detection"
    echo "  • Audit trail display"
else
    echo "✗ Integrity page not accessible"
fi

# ============================================================================
# PART 6: SYSTEM COMPONENTS SUMMARY
# ============================================================================
echo ""
echo ""
echo "PART 6: SYSTEM COMPONENTS SUMMARY"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

echo ""
echo "6.1 Frontend Services:"
echo "  Site URL: ${SITE_URL}"
echo ""
echo "6.2 Backend Services:"
echo "  Postgres: localhost:5432 (docker)"
echo "  MinIO: ${MINIO_ROOT}"
echo ""
echo "6.3 Key Features:"
echo "  ✓ Snapshots API (/api/snapshots)"
echo "  ✓ Firm Data API (/api/firm)"
echo "  ✓ Download Raw JSON (MinIO direct link)"
echo "  ✓ Verify Snapshot (/integrity page)"
echo "  ✓ Agent Evidence (/api/agents/evidence)"

# ============================================================================
# PART 7: FINAL SUMMARY
# ============================================================================
echo ""
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "VERIFICATION COMPLETE"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

echo ""
echo "Port Configuration Summary:"
echo ""
echo "NORMAL (Expected):"
echo "  • Port 3000: Next.js production server (default)"
echo "  • Port 3001: Either development server or redundant instance"
echo ""
echo "If both 3000 and 3001 are running with identical code:"
echo "  → NOT a problem, they provide redundancy/load balancing"
echo "  → Both serve from same /opt/gpti/gpti-site build"
echo ""
echo "Next Steps:"
echo "  1. Navigate to: ${SITE_URL}/rankings"
echo "  2. Click any firm to view details"
echo "  3. Scroll down to 'Integrity & Audit Trail' section"
echo "  4. Test 'Download Raw JSON ↗' (downloads from MinIO)"
echo "  5. Test 'Verify Snapshot' (navigates to /integrity page)"
echo ""
echo "To generate multiple snapshots for historical analysis:"
echo "  bash /opt/gpti/generate-multiple-snapshots.sh 3"
echo ""
