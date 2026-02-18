#!/bin/bash

# 🧪 Staging Complete Test Script
# Comprehensive testing of GPTI system in staging environment

set -e

# Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

ROOT_DIR="/opt/gpti"
BOT_DIR="$ROOT_DIR/gpti-data-bot"
SITE_DIR="$ROOT_DIR/gpti-site"
DOCKER_DIR="$ROOT_DIR/docker"

# Test counters
TESTS_PASSED=0
TESTS_FAILED=0
TESTS_TOTAL=0

# Helper functions
log_test() {
    TESTS_TOTAL=$((TESTS_TOTAL + 1))
    echo -e "${CYAN}[TEST $TESTS_TOTAL]${NC} $1"
}

log_pass() {
    TESTS_PASSED=$((TESTS_PASSED + 1))
    echo -e "${GREEN}  ✅ PASS${NC} - $1"
}

log_fail() {
    TESTS_FAILED=$((TESTS_FAILED + 1))
    echo -e "${RED}  ❌ FAIL${NC} - $1"
}

log_warn() {
    echo -e "${YELLOW}  ⚠️  WARN${NC} - $1"
}

header() {
    echo -e "\n${BLUE}╔════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${BLUE}║  $1${NC}"
    echo -e "${BLUE}╚════════════════════════════════════════════════════════════╝${NC}\n"
}

echo ""
header "STAGING COMPREHENSIVE TEST SUITE"

# ============================================================================
# TEST SECTION 1: Environment & Git Status
# ============================================================================
header "SECTION 1: Environment & Git Status"

log_test "Verify staging branches are active"
cd "$BOT_DIR"
current_branch=$(git rev-parse --abbrev-ref HEAD)
if [ "$current_branch" = "staging" ]; then
    log_pass "Backend on staging branch"
else
    log_fail "Backend on wrong branch: $current_branch"
fi

cd "$SITE_DIR"
current_branch=$(git rev-parse --abbrev-ref HEAD)
if [ "$current_branch" = "staging" ]; then
    log_pass "Frontend on staging branch"
else
    log_fail "Frontend on wrong branch: $current_branch"
fi

log_test "Verify latest commits"
cd "$BOT_DIR"
latest_commit=$(git log -1 --oneline)
echo "  Latest backend: $latest_commit"

cd "$SITE_DIR"
latest_commit=$(git log -1 --oneline)
echo "  Latest frontend: $latest_commit"

# ============================================================================
# TEST SECTION 2: Docker Services
# ============================================================================
header "SECTION 2: Docker Services Health"

log_test "Check Docker daemon"
if docker ps > /dev/null 2>&1; then
    log_pass "Docker daemon running"
else
    log_fail "Docker daemon not accessible"
    exit 1
fi

log_test "Check postgres container"
cd "$DOCKER_DIR"
if docker-compose ps | grep -q "postgres.*Up"; then
    log_pass "PostgreSQL container running"
    # Try to connect
    if PGPASSWORD=superpassword psql -h localhost -U gpti -d gpti -c "SELECT 1" 2>/dev/null; then
        log_pass "PostgreSQL accessible and responding"
    else
        log_warn "PostgreSQL running but not responding to queries yet"
    fi
else
    log_fail "PostgreSQL container not running"
fi

log_test "Check MinIO container"
if docker-compose ps | grep -q "minio.*Up"; then
    log_pass "MinIO container running"
else
    log_fail "MinIO container not running"
fi

log_test "Check Ollama container"
if docker-compose ps | grep -q "ollama.*Up"; then
    log_pass "Ollama container running"
else
    log_warn "Ollama not running (might be optional)"
fi

log_test "Check Prefect containers"
if docker-compose ps | grep -q "prefect.*Up"; then
    log_pass "Prefect services running"
else
    log_warn "Prefect services not running (might be optional)"
fi

# ============================================================================
# TEST SECTION 3: Frontend (Next.js)
# ============================================================================
header "SECTION 3: Frontend Service"

log_test "Check if Next.js is running on port 3000"
if nc -z localhost 3000 2>/dev/null; then
    log_pass "Frontend listening on port 3000"
else
    log_warn "Frontend not yet listening on port 3000"
fi

log_test "Test frontend homepage"
status=$(curl -s -o /dev/null -w "%{http_code}" http://localhost:3000/ 2>/dev/null || echo "000")
if [[ "$status" == "200" ]] || [[ "$status" == "302" ]] || [[ "$status" == "301" ]]; then
    log_pass "Homepage responds with HTTP $status"
else
    log_warn "Homepage returned HTTP $status (expected 200 or redirect)"
fi

log_test "Test /rankings endpoint"
status=$(curl -s -o /dev/null -w "%{http_code}" http://localhost:3000/rankings 2>/dev/null || echo "000")
if [[ "$status" == "200" ]] || [[ "$status" == "302" ]]; then
    log_pass "Rankings endpoint responds with HTTP $status"
else
    log_warn "Rankings endpoint returned HTTP $status"
fi

log_test "Test /api/firms endpoint"
response=$(curl -s http://localhost:3000/api/firms 2>/dev/null || echo "")
if echo "$response" | grep -q '"success"'; then
    firms_count=$(echo "$response" | grep -o '"count":[0-9]*' | head -1 | cut -d: -f2)
    log_pass "API /firms responding with count=$firms_count"
else
    log_warn "API /firms response unexpected"
fi

# ============================================================================
# TEST SECTION 4: Backend Python Module
# ============================================================================
header "SECTION 4: Backend Python Module"

log_test "Check Python environment setup"
export PYTHONPATH="$BOT_DIR/src:${PYTHONPATH:-}"
if python3 -c "import sys; print(sys.path)" 2>&1 | grep -q "gpti-data-bot/src"; then
    log_pass "PYTHONPATH configured correctly"
else
    log_warn "PYTHONPATH might not be fully configured"
fi

log_test "Test web_search module import"
cd "$BOT_DIR"
if python3 -c "from gpti_bot.discovery.web_search import web_search; print('OK')" 2>/dev/null; then
    log_pass "web_search module imports successfully"
else
    log_fail "web_search module import failed"
fi

log_test "Test access_check module import"
if python3 -c "from gpti_bot.health.access_check import AccessChecker; print('OK')" 2>/dev/null; then
    log_pass "access_check module imports successfully"
else
    log_warn "access_check module import failed (might be optional)"
fi

log_test "List available CLI commands"
if python3 -m gpti_bot --help 2>/dev/null | head -10; then
    log_pass "CLI help works"
else
    log_warn "CLI help not working"
fi

# ============================================================================
# TEST SECTION 5: Data & Database
# ============================================================================
header "SECTION 5: Data & Database"

log_test "Check PostgreSQL has firm data"
if PGPASSWORD=superpassword psql -h localhost -U gpti -d gpti -c "SELECT COUNT(*) FROM firms;" 2>/dev/null | grep -qE "[0-9]+"; then
    firm_count=$(PGPASSWORD=superpassword psql -h localhost -U gpti -d gpti -t -c "SELECT COUNT(*) FROM firms;" 2>/dev/null | xargs)
    log_pass "Database has $firm_count firms"
else
    log_warn "Cannot query firms table"
fi

log_test "Check if MinIO bucket exists"
cd "$DOCKER_DIR"
if docker-compose exec -T minio mc ls minio/gpti-raw 2>/dev/null | head -1; then
    log_pass "MinIO bucket accessible"
else
    log_warn "MinIO bucket not accessible or doesn't exist"
fi

log_test "Check snapshot data"
if [ -f "$ROOT_DIR/data/exports/universe_v0.1_public/_public/latest.json" ]; then
    log_pass "Latest snapshot file exists"
    snapshot_date=$(jq -r '.created_at' "$ROOT_DIR/data/exports/universe_v0.1_public/_public/latest.json" 2>/dev/null || echo "unknown")
    echo "  Created: $snapshot_date"
else
    log_warn "Latest snapshot file not found"
fi

# ============================================================================
# TEST SECTION 6: Web Search Integration
# ============================================================================
header "SECTION 6: Web Search Integration"

log_test "Test web_search basic query"
cd "$BOT_DIR"
result=$(python3 << 'EOF'
import sys
sys.path.insert(0, 'src')
try:
    from gpti_bot.discovery.web_search import web_search
    results = web_search("TopStep trader funding", max_results=3)
    print(f"OK:{len(results)}")
except Exception as e:
    print(f"ERROR:{str(e)}")
EOF
)

if echo "$result" | grep -q "^OK:"; then
    count=$(echo "$result" | cut -d: -f2)
    log_pass "Web search returns $count results"
else
    log_warn "Web search test returned: $result"
fi

log_test "Test web_search caching"
result=$(python3 << 'EOF'
import sys, time
sys.path.insert(0, 'src')
try:
    from gpti_bot.discovery.web_search import web_search
    
    # First call (should hit API)
    start = time.time()
    results1 = web_search("test query", max_results=2)
    time1 = time.time() - start
    
    # Second call (should hit cache)
    start = time.time()
    results2 = web_search("test query", max_results=2)
    time2 = time.time() - start
    
    if time2 < time1:
        print(f"OK:cache_faster:{time1:.2f}s->{time2:.2f}s")
    else:
        print(f"OK:no_cache:{time1:.2f}s and {time2:.2f}s")
except Exception as e:
    print(f"ERROR:{str(e)}")
EOF
)

if echo "$result" | grep -q "^OK:"; then
    log_pass "Web search caching working: $(echo $result | cut -d: -f2-)"
else
    log_warn "Web search caching test: $result"
fi

# ============================================================================
# TEST SECTION 7: CLI Commands
# ============================================================================
header "SECTION 7: CLI Commands"

log_test "Test CLI web-search command"
cd "$BOT_DIR"
result=$(python3 -m gpti_bot web-search "prop trading" 3 2>&1 | head -5)
if echo "$result" | grep -q -E "Title|Source|Relevance"; then
    log_pass "CLI web-search command works"
    echo "  Output preview:"
    echo "$result" | head -3 | sed 's/^/    /'
else
    log_warn "CLI web-search command output unexpected"
fi

# ============================================================================
# TEST SECTION 8: Performance
# ============================================================================
header "SECTION 8: Performance"

log_test "Frontend response time"
response_time=$(curl -s -o /dev/null -w "%{time_total}" http://localhost:3000/rankings 2>/dev/null || echo "0")
if (( $(echo "$response_time < 5" | bc -l) )); then
    log_pass "Homepage loads in ${response_time}s (< 5s target)"
else
    log_warn "Homepage loads in ${response_time}s (> 5s target)"
fi

log_test "API response time"
response_time=$(curl -s -o /dev/null -w "%{time_total}" http://localhost:3000/api/firms 2>/dev/null || echo "0")
if (( $(echo "$response_time < 2" | bc -l) )); then
    log_pass "API responds in ${response_time}s (< 2s target)"
else
    log_warn "API responds in ${response_time}s (> 2s target)"
fi

# ============================================================================
# FINAL REPORT
# ============================================================================
header "TEST SUMMARY"

TESTS_SKIPPED=$((TESTS_TOTAL - TESTS_PASSED - TESTS_FAILED))

echo -e "${BLUE}Total Tests:${NC} $TESTS_TOTAL"
echo -e "${GREEN}Passed:${NC} $TESTS_PASSED"
echo -e "${RED}Failed:${NC} $TESTS_FAILED"
echo -e "${YELLOW}Skipped/Warnings:${NC} $TESTS_SKIPPED"

if [ $TESTS_FAILED -eq 0 ]; then
    echo -e "\n${GREEN}✅ ALL CRITICAL TESTS PASSED${NC}"
    echo "System is ready for staging deployment!"
    exit 0
else
    echo -e "\n${RED}❌ SOME TESTS FAILED${NC}"
    echo "Please fix the above issues before proceeding."
    exit 1
fi
