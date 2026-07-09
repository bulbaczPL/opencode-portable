#!/usr/bin/env bash
# 02_lang/test_all.sh — 10 języków × 4 poziomy = 40 testów
set -euo pipefail
G4F_URL="${G4F_URL:-http://localhost:1337/v1/chat/completions}"
RESULTS_DIR="${1:-test_results/02_lang}"
mkdir -p "$RESULTS_DIR"
PASS=0; FAIL=0; TOTAL=0

call() { local m="$1" p="$2" t="${3:-100}"
  curl -s -w "\n%{http_code}" -X POST "$G4F_URL" -H "Content-Type: application/json" \
    -d "$(jq -n --arg m "$m" --arg p "$p" --argjson t "$t" \
      '{model: $m, messages: [{role: "user", content: $p}], max_tokens: $t}')" \
    --connect-timeout 10 --max-time 60 2>/dev/null
}
test_code() {
  local lang="$1" prompt="$2"
  local result; result=$(call "gpt-4o" "$prompt" 200)
  local code body
  code=$(echo "$result" | tail -1); body=$(echo "$result" | sed '$d')
  [ "$code" != "200" ] && return 1
  local content
  content=$(echo "$body" | python3 -c "import sys,json; d=json.load(sys.stdin); print(d.get('choices',[{}])[0].get('message',{}).get('content',''))" 2>/dev/null || echo "")
  local cb; cb=$(echo "$content" | awk '/```/ { if (!flag) flag=1; else flag=0; next } flag')
  [ -z "$cb" ] && return 1
  return 0
}

for lang in Python JavaScript TypeScript Bash Ruby Go Rust Java PHP Lua; do
  for level in 1 2 3 4; do
    TOTAL=$((TOTAL+1))
    case "$level" in
      1) prompt="Write Hello World in $lang." ;;
      2) prompt="Write a FizzBuzz function in $lang." ;;
      3) prompt="Write a Fibonacci function with memoization in $lang." ;;
      4) prompt="Implement a binary search tree with insert/search/delete in $lang." ;;
    esac
    if test_code "$lang" "$prompt"; then
      PASS=$((PASS+1)); echo "  ✓ $lang L$level"
    else
      FAIL=$((FAIL+1)); echo "  ✗ $lang L$level"
    fi
  done
done
echo "02_lang: $PASS/$TOTAL passed, $FAIL failed"
exit $((FAIL > 0))
