#!/usr/bin/env bash
# test_suite/run_all.sh — Master orchestrator for full test suite
set -euo pipefail
BASE_DIR="$(cd "$(dirname "$0")" && pwd)"
RESULTS_DIR="${1:-test_results/full_suite}"
mkdir -p "$RESULTS_DIR"
SUMMARY="$RESULTS_DIR/summary.md"
ALL_PASS=0
ALL_FAIL=0
ALL_TOTAL=0

run_suite() {
  local name="$1" script="$2"
  echo ""
  echo "╔════════════════════════════════════════════════╗"
  echo "║  $name"
  echo "╚════════════════════════════════════════════════╝"
  local start end elapsed
  start=$(date +%s)
  if bash "$script" "$RESULTS_DIR/$name" 2>&1; then
    end=$(date +%s); elapsed=$((end - start))
    echo "  [$name] PASSED (${elapsed}s)"
    echo "| $name | PASS | ${elapsed}s |" >> "$SUMMARY"
    ALL_PASS=$((ALL_PASS+1))
  else
    end=$(date +%s); elapsed=$((end - start))
    echo "  [$name] FAILED (${elapsed}s)"
    echo "| $name | FAIL | ${elapsed}s |" >> "$SUMMARY"
    ALL_FAIL=$((ALL_FAIL+1))
  fi
  ALL_TOTAL=$((ALL_TOTAL+1))
}

# Header
cat > "$SUMMARY" << 'EOF'
# Full Test Suite Results
Date: $(date)
| Suite | Status | Time |
|-------|--------|------|
EOF

# Check G4F
echo "Checking G4F..."
if ! curl -s -o /dev/null -w "" http://localhost:1337/v1/models --connect-timeout 5 2>/dev/null; then
  echo "❌ G4F not running! Start it first."
  exit 1
fi
echo "✓ G4F is running"

# Run all suites
run_suite "01_shellcheck" "$BASE_DIR/01_shellcheck.sh"
run_suite "02_lang" "$BASE_DIR/02_lang/test_all.sh"
run_suite "03_agent" "$BASE_DIR/03_agent/test_all.sh"
run_suite "04_security" "$BASE_DIR/04_security/test_all.sh"
run_suite "05_edge" "$BASE_DIR/05_edge/test_all.sh"
run_suite "06_perf" "$BASE_DIR/06_perf/test_all.sh"
run_suite "07_failover" "$BASE_DIR/07_failover/test_all.sh"

# Summary
echo ""
echo "╔════════════════════════════════════════════════╗"
echo "║  FINAL: $ALL_PASS/$ALL_TOTAL suites passed"
echo "╚════════════════════════════════════════════════╝"
echo "" >> "$SUMMARY"
echo "**Final: $ALL_PASS/$ALL_TOTAL suites passed**" >> "$SUMMARY"

exit $((ALL_FAIL > 0))
