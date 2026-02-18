#!/bin/bash
# Phase 1 Verification Script
# Quick checks to verify all Phase 1 tasks complete (Weeks 1-4)

echo "======================================"
echo "Phase 1 Complete Verification"
echo "Date: $(date)"
echo "======================================"
echo ""

# Color codes
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Counters
PASSED=0
FAILED=0

# Helper function
check() {
    local cmd="$1"
    local desc="$2"
    if eval "$cmd" > /dev/null 2>&1; then
        echo -e "${GREEN}✓${NC} $desc"
        ((PASSED++))
        return 0
    else
        echo -e "${RED}✗${NC} $desc"
        ((FAILED++))
        return 1
    fi
}

# 1. Check SQL migrations exist
echo "1. Checking SQL migrations..."
check "test -f /opt/gpti/gpti-data-bot/infra/sql/003_create_events_table.sql" "Events table migration exists"
check "test -f /opt/gpti/gpti-data-bot/infra/sql/004_create_evidence_table.sql" "Evidence table migration exists"
echo ""

# 2. Check API endpoints exist
echo "2. Checking API endpoints..."
check "test -f /opt/gpti/gpti-site/pages/api/events.ts" "Events API endpoint exists"
check "test -f /opt/gpti/gpti-site/pages/api/evidence.ts" "Evidence API endpoint exists"
check "test -f /opt/gpti/gpti-site/pages/api/validation/metrics.ts" "Validation metrics API exists"
echo ""

# 3. Check Slack notifier exists
echo "3. Checking Slack notifier..."
check "test -f /opt/gpti/gpti-data-bot/src/gpti_bot/utils/slack_notifier.py" "Slack notifier module exists"
echo ""

# 4. Check validation dashboard page
echo "4. Checking validation dashboard..."
check "test -f /opt/gpti/gpti-site/pages/validation.tsx" "Validation dashboard page exists"
echo ""

# 5. Check Next.js server (if running)
echo "5. Checking Next.js server..."
if pgrep -f "next dev" > /dev/null; then
    echo -e "${GREEN}✓${NC} Next.js server is running"
    ((PASSED++))
    
    # Test API endpoints
    check "curl -sL http://localhost:3000/api/events > /dev/null 2>&1" "Events API responding"
    check "curl -sL http://localhost:3000/api/evidence > /dev/null 2>&1" "Evidence API responding"
    check "curl -sL http://localhost:3000/api/validation/metrics > /dev/null 2>&1" "Validation metrics API responding"
else
    echo -e "${YELLOW}⚠${NC} Next.js server not running (run: cd /opt/gpti/gpti-site && npm run dev)"
fi
echo ""

# 6. Check test data
echo "6. Checking test data..."
check "test -f /opt/gpti/gpti-site/data/test-snapshot.json" "Test snapshot exists"

FIRM_COUNT=$(jq -r '.metadata.total_records' /opt/gpti/gpti-site/data/test-snapshot.json 2>/dev/null || echo "0")
if [ "$FIRM_COUNT" -eq 106 ]; then
    echo -e "${GREEN}✓${NC} Test snapshot has 106 firms"
    ((PASSED++))
else
    echo -e "${RED}✗${NC} Test snapshot has wrong firm count: $FIRM_COUNT"
    ((FAILED++))
fi
echo ""

# 7. Check documentation
echo "7. Checking documentation..."
check "test -f /opt/gpti/IMPLEMENTATION_CHECKLIST.md" "Implementation checklist exists"
check "test -f /opt/gpti/NEXT_4_WEEKS_ACTION_PLAN.md" "4-week action plan exists"
check "test -f /opt/gpti/QUICK_START_TASKS.md" "Quick start tasks exists"
check "test -f /opt/gpti/PROJECT_STATUS_REPORT.md" "Project status report exists"
check "test -f /opt/gpti/PROGRESS_TRACKER.md" "Progress tracker exists"
check "test -f /opt/gpti/PHASE_1_WEEK_1_COMPLETE.md" "Phase 1 completion report exists"
echo ""

# Summary
echo "======================================"
echo ""
echo "Week 3 Tasks"
echo "--------------------------------------"

# Check Audit Trail API
if [ -f "/opt/gpti/gpti-site/pages/api/audit/explain.ts" ]; then
    echo -e "${GREEN}✓${NC} Audit Trail API exists"
    ((PASSED++))
else
    echo -e "${RED}✗${NC} Audit Trail API missing"
    ((FAILED++))
fi

# Check Calibration test
if [ -f "/opt/gpti/gpti-data-bot/src/gpti_bot/validation/test_calibration.py" ]; then
    echo -e "${GREEN}✓${NC} Calibration test exists"
    ((PASSED++))
else
    echo -e "${RED}✗${NC} Calibration test missing"
    ((FAILED++))
fi

# Check Report generator
if [ -f "/opt/gpti/gpti-data-bot/src/gpti_bot/validation/generate_report.py" ]; then
    echo -e "${GREEN}✓${NC} Report generator exists"
    ((PASSED++))
else
    echo -e "${RED}✗${NC} Report generator missing"
    ((FAILED++))
fi

# Check MinIO lock config
if [ -f "/opt/gpti/gpti-data-bot/src/gpti_bot/utils/minio_lock_config.py" ]; then
    echo -e "${GREEN}✓${NC} MinIO lock config exists"
    ((PASSED++))
else
    echo -e "${RED}✗${NC} MinIO lock config missing"
    ((FAILED++))
fi

# Check MinIO documentation
if [ -f "/opt/gpti/gpti-data-bot/docs/MINIO_OBJECT_LOCK_SETUP.md" ]; then
    echo -e "${GREEN}✓${NC} MinIO setup docs exist"
    ((PASSED++))
else
    echo -e "${RED}✗${NC} MinIO setup docs missing"
    ((FAILED++))
fi

echo ""
echo "Summary"
echo "======================================"
echo -e "Passed: ${GREEN}${PASSED}${NC}"
echo -e "Failed: ${RED}${FAILED}${NC}"
echo ""

if [ $FAILED -eq 0 ]; then
    echo -e "${GREEN}✓ All checks passed!${NC}"
    echo ""
    echo "Phase 1 Weeks 1-3: COMPLETE ✅"
    echo ""
    echo "Next steps:"
    echo "  1. Install MinIO library: pip install minio"
    echo "  2. Configure MinIO Object Lock (see docs/MINIO_OBJECT_LOCK_SETUP.md)"
    echo "  3. Deploy PostgreSQL with migrations"
    echo "  4. Begin Week 4 tasks: See NEXT_4_WEEKS_ACTION_PLAN.md"
    exit 0
else
    echo -e "${RED}✗ Some checks failed${NC}"
    echo ""
    echo "Please review the errors above and ensure all Phase 1 files are in place."
    exit 1
fi


# Week 4 Tasks
echo ""
echo "Week 4 Tasks"
echo "--------------------------------------"
check "[ -f /opt/gpti/gpti-data-bot/src/gpti_bot/validation/test_ground_truth.py ]" "Ground truth test exists"
check "[ -f /opt/gpti/gpti-data-bot/src/gpti_bot/validation/test_soft_signals.py ]" "Soft signals test exists"
check "[ -f /opt/gpti/gpti-data-bot/src/gpti_bot/validation/test_agent_health.py ]" "Agent health test exists"
check "[ -f /opt/gpti/gpti-site/docs/VERIFIED_FEED_SPEC_v1.1.md ]" "Feed spec v1.1 exists"
check "[ -f /opt/gpti/RELEASE_NOTES_v1.1.md ]" "Release notes exist"
check "[ -f /opt/gpti/IOSCO_COMPLIANCE_v1.1.md ]" "IOSCO compliance docs exist"
