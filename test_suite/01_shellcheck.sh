#!/usr/bin/env bash
# 01_shellcheck/test_all.sh — shellcheck all scripts
set -euo pipefail
cd "$(dirname "$0")/.." || exit 1
PASS=0; FAIL=0; TOTAL=0

for f in setup.sh test-docker.sh test_runner.py test_suite/run_all.sh test_suite/01_shellcheck.sh test_suite/agents/*.sh test_suite/tools/*.sh test_suite/*/*.sh; do
  [ -f "$f" ] || continue
  TOTAL=$((TOTAL+1))
  if shellcheck --shell=bash "$f" 2>&1 | grep -q "error\|warning"; then
    FAIL=$((FAIL+1)); echo "  ✗ $(basename "$f")"
    shellcheck --shell=bash "$f" 2>&1 | grep "error\|warning"
  else
    PASS=$((PASS+1)); echo "  ✓ $(basename "$f")"
  fi
done

echo "01_shellcheck: $PASS/$TOTAL passed, $FAIL failed"
exit $((FAIL > 0))
