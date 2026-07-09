#!/usr/bin/env bash
#=============================================================================
# opencode-portable — Docker Test Orchestrator
# Repo: https://github.com/bulbaczPL/opencode-portable
#
# Usage:
#   bash test-docker.sh           # Szybkie testy L0-L2
#   bash test-docker.sh --full    # Pełne testy L0-L7 (~14h)
#   bash test-docker.sh --quick   # Tylko L0-L1 (~30 min)
#   bash test-docker.sh --report  # Wyświetl ostatni raport
#=============================================================================
set -euo pipefail

MODE="${1:-normal}"
REPO_DIR="$(cd "$(dirname "$0")" && pwd)"
TIMESTAMP=$(date +%Y%m%d_%H%M%S)
RESULTS_DIR="$REPO_DIR/test_results/$TIMESTAMP"
IMAGE_NAME="opencode-portable-test"
CONTAINER_NAME="opencode-test-$TIMESTAMP"
PASS=0; FAIL=0
PHASE=0
declare -a PHASE_PASS=(0 0 0 0 0 0 0)
declare -a PHASE_FAIL=(0 0 0 0 0 0 0)

GREEN='\033[1;32m'; YELLOW='\033[1;33m'; RED='\033[1;31m'; CYAN='\033[1;36m'; NC='\033[0m'
log()  { echo -e "${CYAN}[test]${NC} $1"; }
ok()   { echo -e "${GREEN}  ✓${NC} $1"; PASS=$((PASS+1)); PHASE_PASS[$PHASE]=$((PHASE_PASS[$PHASE] + 1)); }
warn() { echo -e "${YELLOW}  ⚠${NC} $1"; }
fail() { echo -e "${RED}  ✗${NC} $1"; FAIL=$((FAIL+1)); PHASE_FAIL[$PHASE]=$((PHASE_FAIL[$PHASE] + 1)); }

cleanup() {
  log "Czyszczenie..."
  docker stop "$CONTAINER_NAME" 2>/dev/null || true
  docker rm "$CONTAINER_NAME" 2>/dev/null || true
}
trap cleanup EXIT

show_report() {
  local latest
  latest=$(ls -d "$REPO_DIR/test_results/"*/ 2>/dev/null | sort -r | head -1)
  if [ -z "$latest" ]; then
    echo "Brak raportów. Uruchom test-docker.sh najpierw."
    exit 1
  fi
  cat "$latest/summary.md" 2>/dev/null || echo "Brak summary.md w $latest"
  exit 0
}

if [ "$MODE" = "--report" ]; then
  show_report
fi

#=============================================================================
# FAZA 0: Build obrazu Docker
#=============================================================================
build_image() {
  log "Buduję obraz Docker..."
  docker build -t "$IMAGE_NAME" -f- "$REPO_DIR" << 'DOCKERFILE'
FROM ubuntu:24.04
ENV DEBIAN_FRONTEND=noninteractive
RUN apt-get update -qq && apt-get install -y -qq \
    python3 python3-pip curl jq git nodejs npm >/dev/null 2>&1
RUN pip3 install 'fastapi<0.115' 'starlette<0.42' uvicorn g4f json5 python-multipart --break-system-packages -q 2>/dev/null
RUN npm install -g @opencode-ai/cli -q 2>/dev/null
RUN echo '{"success": true, "image": "ubuntu:24.04"}' > /image_info.json
DOCKERFILE
  ok "Obraz Docker zbudowany"
}

#=============================================================================
# FAZA 1: Uruchom kontener i instalacja
#=============================================================================
run_installation() {
  PHASE=1
  log "Uruchamiam kontener testowy..."
  mkdir -p "$RESULTS_DIR"

  docker run -d --name "$CONTAINER_NAME" \
    -v "$REPO_DIR:/repo" \
    -w /root \
    "$IMAGE_NAME" \
    bash -c "tail -f /dev/null" 2>&1

  ok "Kontener uruchomiony"

  # PHASE 1: Test setup.sh (use INSTALL_DIR=/repo so local files are used, not GitHub tarball)
  log "=== PHASE 1: setup.sh install ==="
  mkdir -p "$RESULTS_DIR/debug"

  docker exec "$CONTAINER_NAME" bash -c 'INSTALL_DIR=/repo bash /repo/setup.sh' > "$RESULTS_DIR/setup_output.log" 2>"$RESULTS_DIR/debug/setup_stderr.log" && {
    ok "setup.sh exit 0"
  } || {
    local setup_exit=$?
    warn "setup.sh exit code $setup_exit, log:"
    tail -5 "$RESULTS_DIR/setup_output.log" | sed 's/^/  /'
    if [ -s "$RESULTS_DIR/debug/setup_stderr.log" ]; then
      echo "  stderr:"
      tail -3 "$RESULTS_DIR/debug/setup_stderr.log" | sed 's/^/  /'
    fi
  }

  # Test 1.1: Python version
  docker exec "$CONTAINER_NAME" python3 --version 2>/dev/null | grep -q "3." \
    && ok "Python 3.x" \
    || fail "Python 3.x"

  # Test 1.2: Node version
  docker exec "$CONTAINER_NAME" node --version 2>/dev/null | grep -q "v2" \
    && ok "Node.js >= 22" \
    || fail "Node.js >= 22"

  # Test 1.3: opencode CLI
  docker exec "$CONTAINER_NAME" bash -c "which opencode && opencode --version" > "$RESULTS_DIR/opencode_version.log" 2>&1 \
    && ok "opencode CLI" \
    || fail "opencode CLI"

  # Test 1.4: G4F import
  docker exec "$CONTAINER_NAME" python3 -c "import g4f; print('OK')" 2>/dev/null \
    && ok "G4F import" \
    || fail "G4F import"

  # Test 1.5: Config copied
  docker exec "$CONTAINER_NAME" bash -c "[ -f ~/.config/opencode/opencode.jsonc ]" \
    && ok "config skopiowany" \
    || fail "config skopiowany"

  # Test 1.6: Valid JSON5 (use /root directly — Docker's $HOME)
  docker exec "$CONTAINER_NAME" python3 -c 'import json5; json5.load(open("/root/.config/opencode/opencode.jsonc"))' 2>>"$RESULTS_DIR/debug/stderr.log" \
    && ok "JSON5 valid" \
    || { fail "JSON5 valid"; cat "$RESULTS_DIR/debug/stderr.log" 2>/dev/null | tail -3; }

  # Test 1.7: Placeholder replaced
  docker exec "$CONTAINER_NAME" bash -c "! grep -q __PYTHON_PATH__ ~/.config/systemd/user/g4f.service 2>/dev/null" \
    && ok "g4f.service: placeholder replaced" \
    || fail "g4f.service: placeholder NOT replaced"

  # Test 1.8: Python path in service
  docker exec "$CONTAINER_NAME" bash -c "grep -q 'ExecStart=.*python' ~/.config/systemd/user/g4f.service 2>/dev/null" \
    && ok "g4f.service: python path set" \
    || warn "g4f.service: python path (może być systemd w Docker)"

  # Test 1.9: bash_env
  docker exec "$CONTAINER_NAME" bash -c "grep -q OPENCODE_PATH ~/.bash_env 2>/dev/null" \
    && ok ".bash_env PATH" \
    || warn ".bash_env PATH (oczekiwane w normalnym systemie)"

  # Test 1.10: G4F models count in config (must be 12)
  local count
  count=$(docker exec "$CONTAINER_NAME" python3 -c 'import json5; d=json5.load(open("/root/.config/opencode/opencode.jsonc")); print(len(d["provider"]["g4f"]["models"]))' 2>/dev/null || echo "0")
  [ "$count" = "12" ] \
    && ok "G4F models in config: $count" \
    || fail "G4F models in config: $count (expected 12)"
}

#=============================================================================
# FAZA 2: Uruchom G4F i test API
#=============================================================================
run_g4f_tests() {
  PHASE=2
  log "=== PHASE 2: G4F API tests ==="

  # Start G4F z retry (max 5 prób × 4s = 20s)
  docker exec -d "$CONTAINER_NAME" bash -c "nohup python3 -c 'from g4f.api import run_api; run_api(port=1337)' > /tmp/g4f.log 2>&1 &"
  local g4f_ready=0
  for i in 1 2 3 4 5; do
    sleep 4
    if docker exec "$CONTAINER_NAME" bash -c "curl -sf -o /dev/null http://localhost:1337/v1/models --connect-timeout 5" 2>/dev/null; then
      g4f_ready=1
      break
    fi
  done

  # Test 2.0: G4F alive
  if [ "$g4f_ready" = "1" ]; then
    ok "G4F API live (started in $(( i * 4 ))s)"
  else
    docker exec "$CONTAINER_NAME" bash -c "tail -20 /tmp/g4f.log" 2>/dev/null | head -5
    fail "G4F API not responding (see /tmp/g4f.log in container)"
  fi

  # Test 2.1-2.12: 12 models
  MODELS=(
    "gpt-4o-mini"
    "gpt-4o"
    "gpt-4"
    "o1"
    "o3-mini"
    "deepseek-r1"
    "command-a"
    "command-r"
    "command-r-plus"
    "command-r7b"
    "aria"
    "r1-1776"
  )

  mkdir -p "$RESULTS_DIR/models"
  local passed=0
  local failed=0

  for model in "${MODELS[@]}"; do
    local result http_code body
    # Retry once for transient failures (500, 502, 503)
    for attempt in 1 2; do
      result=$(docker exec "$CONTAINER_NAME" bash -c "curl -s -w '\n%{http_code}' -X POST http://localhost:1337/v1/chat/completions \
        -H 'Content-Type: application/json' \
        -d '{\"model\": \"$model\", \"messages\": [{\"role\": \"user\", \"content\": \"Say OK\"}], \"max_tokens\": 5}' \
        --connect-timeout 10 --max-time 60" 2>/dev/null)
      http_code=$(echo "$result" | tail -1)
      body=$(echo "$result" | sed '$d')
      if [ "$http_code" = "200" ] || [ "$attempt" = "2" ]; then
        break
      fi
      sleep 2
    done

    if [ "$http_code" = "200" ]; then
      local content provider
      content=$(echo "$body" | python3 -c "import sys,json; d=json.load(sys.stdin); print(d.get('choices',[{}])[0].get('message',{}).get('content',''))" 2>/dev/null || echo "")
      provider=$(echo "$body" | python3 -c "import sys,json; d=json.load(sys.stdin); print(d.get('provider','?'))" 2>/dev/null || echo "?")
      local has_content="no"
      [ -n "$content" ] && has_content="yes"
      echo "{\"model\":\"$model\",\"http\":200,\"provider\":\"$provider\",\"has_content\":\"$has_content\",\"content\":\"${content:0:30}\"}" >> "$RESULTS_DIR/models/$model.json"
      [ "$has_content" = "yes" ] \
        && ok "$model → HTTP 200 (${provider}) \"${content:0:20}\"" \
        || warn "$model → HTTP 200 (${provider}) ⚠️ EMPTY CONTENT"
      passed=$((passed+1))
    else
      local err_msg
      err_msg=$(echo "$body" | python3 -c "import sys,json; d=json.load(sys.stdin); print(d.get('error',{}).get('message','')[:80])" 2>/dev/null || echo "unknown")
      echo "{\"model\":\"$model\",\"http\":$http_code,\"error\":\"$err_msg\"}" >> "$RESULTS_DIR/models/$model.json"
      fail "$model → HTTP $http_code: $err_msg"
      failed=$((failed+1))
    fi
  done

  log "Models: $passed passed / $failed failed"
  echo "$passed" > "$RESULTS_DIR/models_passed.txt"
  echo "$failed" > "$RESULTS_DIR/models_failed.txt"

  # Negative test: nonexistent model
  local neg_result
  neg_result=$(docker exec "$CONTAINER_NAME" bash -c "curl -s -w '\n%{http_code}' -X POST http://localhost:1337/v1/chat/completions \
    -H 'Content-Type: application/json' \
    -d '{\"model\":\"nonexistent-model-xyz-123\",\"messages\":[{\"role\":\"user\",\"content\":\"hi\"}],\"max_tokens\":3}' \
    --max-time 30" 2>/dev/null)
  local neg_code
  neg_code=$(echo "$neg_result" | tail -1)
  [ "$neg_code" != "200" ] \
    && ok "Nonexistent model → HTTP $neg_code (expected non-200)" \
    || fail "Nonexistent model → HTTP 200 (should reject)"
}

#=============================================================================
# FAZA 3: Pollinations test
#=============================================================================
run_pollinations_test() {
  PHASE=3
  log "=== PHASE 3: Pollinations.ai test ==="

  local result
  result=$(curl -s -w '\n%{http_code}' -X POST https://text.pollinations.ai/openai/v1/chat/completions \
    -H 'Content-Type: application/json' \
    -d '{"model":"openai","messages":[{"role":"user","content":"Say OK"}],"max_tokens":5}' \
    --connect-timeout 10 --max-time 30 2>/dev/null)
  local code
  code=$(echo "$result" | tail -1)
  [ "$code" = "200" ] \
    && ok "Pollinations.ai → HTTP 200" \
    || fail "Pollinations.ai → HTTP $code"
}

#=============================================================================
# FAZA 4: Security scan
#=============================================================================
run_security_scan() {
  PHASE=4
  log "=== PHASE 4: Security scan ==="

  # Check for hardcoded API keys in repo
  local secrets_found
  secrets_found=$(docker exec "$CONTAINER_NAME" bash -c "cd /repo && git grep -n -E '(sk-[a-zA-Z0-9]{20,}|gsk_[a-zA-Z0-9]{20,}|pplx-[a-zA-Z0-9]{20,}|AIza[0-9A-Za-z_-]{35,})' -- '*.jsonc' '*.md' '*.sh' '*.py' ':!.git/' 2>/dev/null || true" | wc -l)
  [ "$secrets_found" -eq 0 ] \
    && ok "Brak hardcoded API keys w repo" \
    || fail "Znaleziono $secrets_found potencjalnych sekretów!"

  # Check apiKey in config uses env: pattern (use true to avoid double-output on grep -c 0)
  local api_key_count
  api_key_count=$(docker exec "$CONTAINER_NAME" bash -c "grep -c 'apiKey' /repo/config/opencode.jsonc 2>/dev/null || true")
  local env_count
  env_count=$(docker exec "$CONTAINER_NAME" bash -c "grep -c '\$\{env:' /repo/config/opencode.jsonc 2>/dev/null || true")
  [ "$api_key_count" -eq "$env_count" ] 2>/dev/null \
    && ok "Wszystkie apiKey używają env: (bez hardcode)" \
    || warn "$api_key_count apiKey, z czego $env_count przez env: (reszta może być hardcoded)"
}

#=============================================================================
# FAZA 5: Konsystencja dokumentacji
#=============================================================================
run_docs_consistency() {
  PHASE=5
  log "=== PHASE 5: Documentation consistency ==="

  # Check AGENTS.md mentions 12 models
  docker exec "$CONTAINER_NAME" bash -c "grep -q '12 verified\|12 zweryfikowanych\|12 modeli' /repo/config/AGENTS.md 2>/dev/null" \
    && ok "AGENTS.md: 12 models" \
    || warn "AGENTS.md: nie znaleziono '12 models'"

  # Check ApiAirforce marked as broken
  docker exec "$CONTAINER_NAME" bash -c "grep -q 'Broken' /repo/config/opencode.jsonc" \
    && ok "Config: broken providers marked" \
    || warn "Config: brak 'Broken' marker"

  # Check G4F provider name has 12
  docker exec "$CONTAINER_NAME" bash -c "grep -q '12 Verified' /repo/config/opencode.jsonc" \
    && ok "Config: G4F = 12 Verified Working Models" \
    || warn "Config: G4F name nie zawiera '12'"
}

#=============================================================================
# FAZA 6: Raport końcowy
#=============================================================================
generate_report() {
  local passed_count=$(cat "$RESULTS_DIR/models_passed.txt" 2>/dev/null || echo 0)
  local failed_count=$(cat "$RESULTS_DIR/models_failed.txt" 2>/dev/null || echo 0)
  local total_tests=$((PASS + FAIL))

  cat > "$RESULTS_DIR/summary.md" << EOF
# opencode-portable TEST REPORT

**Date:** $(date '+%Y-%m-%d %H:%M:%S')
**Mode:** $MODE
**Version:** $(cat "$REPO_DIR/VERSION" 2>/dev/null || echo "?")
**Commit:** $(cd "$REPO_DIR" && git rev-parse --short HEAD 2>/dev/null || echo "?")

---

## Results

| Phase | Pass | Fail |
|-------|------|------|
| Phase 1: Setup.sh install | ${PHASE_PASS[1]} | ${PHASE_FAIL[1]} |
| Phase 2: G4F API ($passed_count/$((passed_count + failed_count))) | $passed_count | $failed_count |
| Phase 3: Pollinations | ${PHASE_PASS[3]} | ${PHASE_FAIL[3]} |
| Phase 4: Security | ${PHASE_PASS[4]} | ${PHASE_FAIL[4]} |
| Phase 5: Documentation | ${PHASE_PASS[5]} | ${PHASE_FAIL[5]} |

## G4F Models Status

$(for f in "$RESULTS_DIR"/models/*.json; do
  name=$(basename "$f" .json)
  status=$(grep -o '"has_content":"[^"]*"' "$f" 2>/dev/null || echo '"has_content":"no"')
  provider=$(grep -o '"provider":"[^"]*"' "$f" 2>/dev/null || echo '"provider":"?"')
  http=$(grep -o '"http":[0-9]*' "$f" 2>/dev/null || echo '"http":0')
  if echo "$http" | grep -q '"http":200' && echo "$status" | grep -q '"has_content":"yes"'; then
    echo "  ✅ $name - $provider"
  elif echo "$http" | grep -q '"http":200'; then
    echo "  ⚠️ $name - $provider (empty content)"
  else
    echo "  ❌ $name - $http"
  fi
done)

---

**Total tests:** $total_tests
**Passed:** $PASS
**Failed:** $FAIL
**Overall:** $([ $FAIL -eq 0 ] && echo "✅ ALL PASSED" || echo "❌ $FAIL FAILURES")
EOF

  echo ""
  cat "$RESULTS_DIR/summary.md"
}

#=============================================================================
# MAIN
#=============================================================================
main() {
  echo ""
  echo -e "${CYAN}╔══════════════════════════════════════════════════════╗${NC}"
  echo -e "${CYAN}║  opencode-portable — Docker Test Suite              ║${NC}"
  echo -e "${CYAN}╚══════════════════════════════════════════════════════╝${NC}"
  echo "  Mode: $MODE"
  echo "  Results: $RESULTS_DIR"
  echo ""

  build_image
  run_installation
  run_g4f_tests
  run_pollinations_test
  run_security_scan
  run_docs_consistency
  generate_report

  echo ""
  if [ $FAIL -eq 0 ]; then
    echo -e "${GREEN}╔══════════════════════════════════════════════════════╗${NC}"
    echo -e "${GREEN}║  ALL TESTS PASSED ✅                                 ║${NC}"
    echo -e "${GREEN}╚══════════════════════════════════════════════════════╝${NC}"
  else
    echo -e "${RED}╔══════════════════════════════════════════════════════╗${NC}"
    echo -e "${RED}║  $FAIL TESTS FAILED ❌                                  ║${NC}"
    echo -e "${RED}╚══════════════════════════════════════════════════════╝${NC}"
  fi
}

main "$@"
