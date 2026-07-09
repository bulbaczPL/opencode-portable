#!/usr/bin/env bash
#====================================================================
# Agent 6: Security Auditor — find vulns in generated code
#====================================================================
set -euo pipefail
RESULTS_DIR="${1:-test_results/agent_06}"
mkdir -p "$RESULTS_DIR"
PASS=0
FAIL=0

check_tool() {
  if command -v "$1" &>/dev/null; then
    echo "  ✓ $1 available"
    return 0
  fi
  echo "  ⚠ $1 not installed"
  return 1
}

run_bandit() {
  local target="$1"
  [ ! -f "$target" ] && return 0
  if bandit -q "$target" 2>/dev/null; then
    echo "  ✓ bandit: no issues"
    return 0
  fi
  echo "  ⚠ bandit: issues found"
  return 1
}

run_gitleaks() {
  local target="$1"
  if ! command -v gitleaks &>/dev/null; then
    echo "  ⚠ gitleaks not available — skip"
    return 0
  fi
  if gitleaks detect --no-git -v -s "$target" 2>/dev/null; then
    echo "  ✓ gitleaks: no secrets"
  fi
}

run_semgrep() {
  local target="$1"
  if ! command -v semgrep &>/dev/null; then
    echo "  ⚠ semgrep not available — skip"
    return 0
  fi
  semgrep --quiet --metrics=off "$target" 2>/dev/null || true
}

# Scan key project files
SCAN_TARGETS=(
  "/home/michal/opencode-portable/setup.sh"
  "/home/michal/opencode-portable/test-docker.sh"
  "/home/michal/opencode-portable/test_runner.py"
)

for target in "${SCAN_TARGETS[@]}"; do
  [ ! -f "$target" ] && continue
  echo "  Scanning $target..."
  run_bandit "$target" && PASS=$((PASS+1)) || FAIL=$((FAIL+1))
  run_gitleaks "$target"
  run_semgrep "$target"
done

# Check for secrets
echo "  Checking for secrets..."
if ! grep -rn "api_key\|API_KEY\|password\|secret\|token\|sk-[a-zA-Z0-9]\|ghp_\|gho_" /home/michal/opencode-portable --include="*.sh" --include="*.py" --include="*.jsonc" --include="*.json" --include="*.yaml" 2>/dev/null | grep -v "test_runner.py\|./.git/\|./test_results/\|summary\|opencode\.jsonc.*provider\|opencode\.jsonc.*api_key"; then
  PASS=$((PASS+1))
fi

echo "Agent 6 done. Pass=$PASS Fail=$FAIL"
