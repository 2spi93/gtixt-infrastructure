#!/bin/bash
# Snapshot History Automation - Verification Script
# Tests all components of the automation pipeline

set -e

echo "=========================================="
echo "Snapshot History Automation Test Suite"
echo "=========================================="
echo ""

# Colors for output
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

test_count=0
pass_count=0
fail_count=0

# Helper function
run_test() {
    local test_name="$1"
    local command="$2"
    
    test_count=$((test_count + 1))
    echo -e "${YELLOW}[Test $test_count]${NC} $test_name"
    
    if eval "$command" > /dev/null 2>&1; then
        echo -e "${GREEN}  ✅ PASS${NC}"
        pass_count=$((pass_count + 1))
    else
        echo -e "${RED}  ❌ FAIL${NC}"
        fail_count=$((fail_count + 1))
    fi
    echo ""
}

# Test 1: Files exist
echo "=== Phase 1: File Structure ==="
run_test "Database schema exists" "[ -f /opt/gpti/gpti-data-bot/database/schema.sql ]"
run_test "Snapshot history agent exists" "[ -f /opt/gpti/gpti-data-bot/src/gpti_bot/agents/snapshot_history_agent.py ]"
run_test "API endpoint exists" "[ -f /opt/gpti/gpti-site/pages/api/firm-history.ts ]"
run_test "Prefect flow exists" "[ -f /opt/gpti/gpti-data-bot/flows/snapshot_history_automation.py ]"

echo ""
echo "=== Phase 2: Code Verification ==="

# Test 2: Check schema has firm_snapshots
run_test "Schema contains firm_snapshots table" "grep -q 'CREATE TABLE firm_snapshots' /opt/gpti/gpti-data-bot/database/schema.sql"

# Test 3: Check agent has key methods
run_test "Agent has capture_snapshot method" "grep -q 'def capture_snapshot' /opt/gpti/gpti-data-bot/src/gpti_bot/agents/snapshot_history_agent.py"
run_test "Agent has get_history method" "grep -q 'def get_history' /opt/gpti/gpti-data-bot/src/gpti_bot/agents/snapshot_history_agent.py"
run_test "Agent has get_trajectory method" "grep -q 'def get_trajectory' /opt/gpti/gpti-data-bot/src/gpti_bot/agents/snapshot_history_agent.py"

# Test 4: Check API endpoint
run_test "API endpoint exports handler" "grep -q 'export default async function handler' /opt/gpti/gpti-site/pages/api/firm-history.ts"
run_test "API has mock history data" "grep -q 'MOCK_HISTORY' /opt/gpti/gpti-site/pages/api/firm-history.ts"

# Test 5: Check Prefect flow
run_test "Flow has main pipeline" "grep -q 'def snapshot_history_pipeline' /opt/gpti/gpti-data-bot/flows/snapshot_history_automation.py"
run_test "Flow has hourly monitor" "grep -q 'def hourly_snapshot_monitor' /opt/gpti/gpti-data-bot/flows/snapshot_history_automation.py"

# Test 6: Check integration
run_test "Snapshot.py calls agent" "grep -q 'get_snapshot_history_agent' /opt/gpti/gpti-data-bot/src/gpti_bot/snapshots/snapshot.py"

echo ""
echo "=== Phase 3: API Testing ==="

# Test 7: API responses
run_test "API /firm-history responds" "curl -s -o /dev/null -w '%{http_code}' http://localhost:3005/api/firm-history?id=topstepclient | grep -q '200'"
run_test "API returns JSON" "curl -s 'http://localhost:3005/api/firm-history?id=topstepclient' | grep -q 'firmId'"
run_test "API has history data" "curl -s 'http://localhost:3005/api/firm-history?id=topstepclient' | grep -q 'history'"

echo ""
echo "=== Phase 4: Data Format Validation ==="

# Test 8: Response structure
api_response=$(curl -s 'http://localhost:3005/api/firm-history?id=topstepclient')
run_test "Response has firmId field" "echo '$api_response' | grep -q 'firmId'"
run_test "Response has recordCount field" "echo '$api_response' | grep -q 'recordCount'"
run_test "Response has history array" "echo '$api_response' | grep -q '\[\{'  "

echo ""
echo "=== Phase 5: Pages Integration ==="

# Test 9: Pages that depend on this
run_test "firm.tsx exists" "[ -f /opt/gpti/gpti-site/pages/firm.tsx ]"
run_test "firm.tsx loads snapshot_history" "grep -q 'snapshot_history' /opt/gpti/gpti-site/pages/firm.tsx"
run_test "firm.tsx calls scoreTrajectoryAnalysis" "grep -q 'scoreTrajectoryAnalysis' /opt/gpti/gpti-site/pages/firm.tsx"

echo ""
echo "=========================================="
echo "Test Results Summary"
echo "=========================================="
echo -e "Total Tests: $test_count"
echo -e "${GREEN}Passed: $pass_count${NC}"
echo -e "${RED}Failed: $fail_count${NC}"

if [ $fail_count -eq 0 ]; then
    echo ""
    echo -e "${GREEN}✅ All tests passed!${NC}"
    echo ""
    echo "Next Steps:"
    echo "1. Deploy to production database"
    echo "2. Configure Prefect scheduler"
    echo "3. Verify first snapshot capture"
    echo "4. Monitor Score Trajectory in UI"
    exit 0
else
    echo ""
    echo -e "${RED}❌ Some tests failed. Review the output above.${NC}"
    exit 1
fi
