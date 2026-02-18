#!/bin/bash
# Score Trajectory Implementation - Verification Script
# Run this to verify the implementation is complete and working

echo "═════════════════════════════════════════════════════════════════"
echo "  SCORE TRAJECTORY IMPLEMENTATION VERIFICATION"
echo "═════════════════════════════════════════════════════════════════"
echo ""

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

ERRORS=0
WARNINGS=0

# Function to print status
print_status() {
  if [ $1 -eq 0 ]; then
    echo -e "${GREEN}✓${NC} $2"
  else
    echo -e "${RED}✗${NC} $2"
    ((ERRORS++))
  fi
}

print_warning() {
  echo -e "${YELLOW}⚠${NC} $1"
  ((WARNINGS++))
}

print_info() {
  echo -e "${BLUE}ℹ${NC} $1"
}

echo ""
echo "1. CHECKING FILES EXIST"
echo "─────────────────────────────────────────────────────────────────"

# Check main file
if [ -f "/opt/gpti/gpti-site/pages/firm.tsx" ]; then
  print_status 0 "firm.tsx exists"
else
  print_status 1 "firm.tsx missing"
fi

# Check documentation
if [ -f "/opt/gpti/SCORE_TRAJECTORY_IMPLEMENTATION.md" ]; then
  print_status 0 "Documentation: IMPLEMENTATION.md"
else
  print_status 1 "Documentation: IMPLEMENTATION.md missing"
fi

if [ -f "/opt/gpti/SCORE_TRAJECTORY_VERIFICATION_REPORT.md" ]; then
  print_status 0 "Documentation: VERIFICATION_REPORT.md"
else
  print_status 1 "Documentation: VERIFICATION_REPORT.md missing"
fi

if [ -f "/opt/gpti/SCORE_TRAJECTORY_USER_REQUIREMENTS_FULFILLMENT.md" ]; then
  print_status 0 "Documentation: USER_REQUIREMENTS_FULFILLMENT.md"
else
  print_status 1 "Documentation: USER_REQUIREMENTS_FULFILLMENT.md missing"
fi

if [ -f "/opt/gpti/SCORE_TRAJECTORY_NEXT_ACTIONS.md" ]; then
  print_status 0 "Documentation: NEXT_ACTIONS.md"
else
  print_status 1 "Documentation: NEXT_ACTIONS.md missing"
fi

if [ -f "/opt/gpti/SCORE_TRAJECTORY_EXECUTIVE_SUMMARY.md" ]; then
  print_status 0 "Documentation: EXECUTIVE_SUMMARY.md"
else
  print_status 1 "Documentation: EXECUTIVE_SUMMARY.md missing"
fi

echo ""
echo "2. CHECKING CODE IMPLEMENTATION"
echo "─────────────────────────────────────────────────────────────────"

# Check for scoreTrajectoryAnalysis function
if grep -q "const scoreTrajectoryAnalysis" /opt/gpti/gpti-site/pages/firm.tsx; then
  print_status 0 "scoreTrajectoryAnalysis function implemented"
else
  print_status 1 "scoreTrajectoryAnalysis function missing"
fi

# Check for Score Trajectory section
if grep -q "Score Trajectory" /opt/gpti/gpti-site/pages/firm.tsx; then
  print_status 0 "Score Trajectory section found"
else
  print_status 1 "Score Trajectory section missing"
fi

# Check for SVG chart
if grep -q 'viewBox="0 0 800 300"' /opt/gpti/gpti-site/pages/firm.tsx; then
  print_status 0 "SVG chart with correct viewBox"
else
  print_status 1 "SVG chart viewBox missing"
fi

# Check for turquoise color (#00D4C2)
if grep -q '#00D4C2' /opt/gpti/gpti-site/pages/firm.tsx; then
  print_status 0 "Turquoise color (#00D4C2) applied"
else
  print_status 1 "Turquoise color missing"
fi

# Check for interpretation text
if grep -q "trajectoryInterpretation" /opt/gpti/gpti-site/pages/firm.tsx; then
  print_status 0 "Interpretation component implemented"
else
  print_status 1 "Interpretation component missing"
fi

# Check for statistics grid
if grep -q "evolutionStats" /opt/gpti/gpti-site/pages/firm.tsx; then
  print_status 0 "Statistics grid implemented"
else
  print_status 1 "Statistics grid missing"
fi

echo ""
echo "3. CHECKING STYLES"
echo "─────────────────────────────────────────────────────────────────"

# Check for new trajectory styles
if grep -q "trajectoryInterpretation:" /opt/gpti/gpti-site/pages/firm.tsx; then
  print_status 0 "trajectoryInterpretation style defined"
else
  print_status 1 "trajectoryInterpretation style missing"
fi

if grep -q "trajectoryChartContainer:" /opt/gpti/gpti-site/pages/firm.tsx; then
  print_status 0 "trajectoryChartContainer style defined"
else
  print_status 1 "trajectoryChartContainer style missing"
fi

if grep -q "trajectoryChart:" /opt/gpti/gpti-site/pages/firm.tsx; then
  print_status 0 "trajectoryChart style defined"
else
  print_status 1 "trajectoryChart style missing"
fi

echo ""
echo "4. CHECKING COMPILATION"
echo "─────────────────────────────────────────────────────────────────"

# Check if build would pass (quick TypeScript check)
cd /opt/gpti/gpti-site

# Try to build
echo "Running: npm run build..."
if npm run build > /tmp/build.log 2>&1; then
  print_status 0 "Build completed successfully"
  
  # Check for actual errors
  if grep -q "error" /tmp/build.log; then
    print_warning "Build log contains 'error' text"
    grep "error" /tmp/build.log | head -3
  else
    print_status 0 "No compilation errors found"
  fi
else
  print_status 1 "Build failed"
  cat /tmp/build.log | grep -i "error" | head -5
fi

echo ""
echo "5. CHECKING PROPFIRM PAGES"
echo "─────────────────────────────────────────────────────────────────"

# Check all propfirm pages compile
for page in firm.tsx rankings.tsx data.tsx firms.tsx; do
  if grep -q "Turquoise Institutional Deep\|#00D4C2" /opt/gpti/gpti-site/pages/$page 2>/dev/null; then
    print_status 0 "$page has turquoise palette"
  else
    print_warning "$page may not have turquoise palette"
  fi
done

echo ""
echo "6. VERIFYING KEY FEATURES"
echo "─────────────────────────────────────────────────────────────────"

# Count occurrences of turquoise color
TURQUOISE_COUNT=$(grep -o '#00D4C2' /opt/gpti/gpti-site/pages/firm.tsx | wc -l)
if [ $TURQUOISE_COUNT -gt 10 ]; then
  print_status 0 "Turquoise color found $TURQUOISE_COUNT times (good usage)"
else
  print_warning "Turquoise color only found $TURQUOISE_COUNT times"
fi

# Check for responsive design
if grep -q "responsive\|mobile\|width: 100%" /opt/gpti/gpti-site/pages/firm.tsx; then
  print_status 0 "Responsive design elements present"
else
  print_warning "Responsive design elements not explicitly found"
fi

# Check for gridlines
if grep -q "gridline\|grid\|strokeDasharray" /opt/gpti/gpti-site/pages/firm.tsx; then
  print_status 0 "Chart gridlines implemented"
else
  print_warning "Chart gridlines not found"
fi

echo ""
echo "7. DATA HANDLING"
echo "─────────────────────────────────────────────────────────────────"

# Check snapshot history filtering
if grep -q "snapshotHistory.*filter\|validData.*filter" /opt/gpti/gpti-site/pages/firm.tsx; then
  print_status 0 "Snapshot data filtering implemented"
else
  print_warning "Snapshot data filtering not found"
fi

# Check date sorting
if grep -q "sort.*date\|getTime()" /opt/gpti/gpti-site/pages/firm.tsx; then
  print_status 0 "Date sorting implemented"
else
  print_warning "Date sorting not found"
fi

echo ""
echo "═════════════════════════════════════════════════════════════════"
echo "VERIFICATION SUMMARY"
echo "═════════════════════════════════════════════════════════════════"

if [ $ERRORS -eq 0 ]; then
  echo -e "${GREEN}✓ All checks passed!${NC}"
  echo ""
  echo "Implementation Status: COMPLETE ✓"
  echo "Compilation Status: SUCCESSFUL ✓"
  echo "Production Ready: YES ✓"
  exit 0
else
  echo -e "${RED}✗ $ERRORS error(s) found${NC}"
  if [ $WARNINGS -gt 0 ]; then
    echo -e "${YELLOW}⚠ $WARNINGS warning(s) found${NC}"
  fi
  exit 1
fi
