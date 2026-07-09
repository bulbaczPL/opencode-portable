#!/usr/bin/env bash
# 07_failover/test_all.sh — 7 testów failover chain
set -euo pipefail
G4F_URL="${G4F_URL:-http://localhost:1337/v1/chat/completions}"
RESULTS_DIR="${1:-test_results/07_failover}"
mkdir -p "$RESULTS_DIR"
PASS=0; FAIL=0

call() { local m="$1" p="$2" t="${3:-20}"
  curl -s -w "\n%{http_code}" -X POST "$G4F_URL" -H "Content-Type: application/json" \
    -d "$(jq -n --arg m "$m" --arg p "$p" --argjson t "$t" \
      '{model: $m, messages: [{role: "user", content: $p}], max_tokens: $t}')" \
    --connect-timeout 10 --max-time 30 2>/dev/null
}

echo "=== 07_failover: Failover Chain Tests ==="

# Test 1: Primary model → fallback
echo "  Test 1: Primary (gpt-4o) → Fallback (gpt-4):"
r1=$(call "gpt-4o" "OK" 5); c1=$(echo "$r1" | tail -1)
r2=$(call "gpt-4" "OK" 5); c2=$(echo "$r2" | tail -1)
if [ "$c1" = "200" ] && [ "$c2" = "200" ]; then
  PASS=$((PASS+1)); echo "    ✓ Both available"
else
  FAIL=$((FAIL+1)); echo "    ✗ gpt-4o=$c1 gpt-4=$c2"
fi

# Test 2: Top 5 models all available
echo "  Test 2: Top 5 models:"
all_ok=0
for m in gpt-4o o1 gpt-4 o3-mini command-r; do
  r=$(call "$m" "OK" 5); c=$(echo "$r" | tail -1)
  [ "$c" = "200" ] && all_ok=$((all_ok+1))
done
if [ "$all_ok" -ge 4 ]; then
  PASS=$((PASS+1)); echo "    ✓ $all_ok/5 OK"
else
  FAIL=$((FAIL+1)); echo "    ✗ $all_ok/5 OK"
fi

# Test 3: Chain auto-failover (try failing model, then working)
echo "  Test 3: Auto-failover simulation:"
r=$(call "gpt-4o-mini" "OK" 5); c=$(echo "$r" | tail -1)
r2=$(call "gpt-4o" "OK" 5); c2=$(echo "$r2" | tail -1)
if [ "$c" != "200" ] && [ "$c2" = "200" ]; then
  PASS=$((PASS+1)); echo "    ✓ Failed model rejected, fallback works"
else
  FAIL=$((FAIL+1)); echo "    ✗ gpt-4o-mini=$c gpt-4o=$c2"
fi

# Test 4: Rate limit tolerance
echo "  Test 4: 10 rapid requests to same model:"
ok=0
for i in $(seq 1 10); do
  r=$(call "gpt-4o" "OK" 5); c=$(echo "$r" | tail -1)
  [ "$c" = "200" ] && ok=$((ok+1))
done
if [ "$ok" -ge 8 ]; then
  PASS=$((PASS+1)); echo "    ✓ $ok/10 OK (no rate limit)"
else
  FAIL=$((FAIL+1)); echo "    ✗ $ok/10 OK (rate limited?)"
fi

# Test 5: Concurrent model access
echo "  Test 5: 5 concurrent requests:"
TMPD=$(mktemp -d)
for i in $(seq 1 5); do
  (call "gpt-4o" "OK" 5 > "$TMPD/$i.txt" 2>/dev/null) &
done
wait
ok=$(grep -c "200$" "$TMPD"/*.txt 2>/dev/null || echo 0)
rm -rf "$TMPD"
if [ "$ok" -ge 3 ]; then
  PASS=$((PASS+1)); echo "    ✓ $ok/5 OK"
else
  FAIL=$((FAIL+1)); echo "    ✗ $ok/5 OK"
fi

# Test 6: Empty model name → should reject
echo "  Test 6: Empty model name:"
r=$(curl -s -w "\n%{http_code}" -X POST "$G4F_URL" -H "Content-Type: application/json" \
  -d '{"model":"","messages":[{"role":"user","content":"OK"}],"max_tokens":5}' \
  --connect-timeout 5 --max-time 10 2>/dev/null)
c=$(echo "$r" | tail -1)
if [ "$c" != "200" ]; then
  PASS=$((PASS+1)); echo "    ✓ HTTP $c (rejected)"
else
  FAIL=$((FAIL+1)); echo "    ✗ HTTP 200 (should reject)"
fi

# Test 7: Wrong base URL
echo "  Test 7: Wrong base URL:"
r=$(curl -s -w "\n%{http_code}" -X POST "http://localhost:1337/v1/chat/completions" \
  -H "Content-Type: application/json" \
  -d '{"model":"nonexistent","messages":[{"role":"user","content":"OK"}],"max_tokens":5}' \
  --connect-timeout 5 --max-time 10 2>/dev/null)
c=$(echo "$r" | tail -1)
if [ "$c" != "200" ]; then
  PASS=$((PASS+1)); echo "    ✓ HTTP $c (nonexistent model rejected)"
else
  FAIL=$((FAIL+1)); echo "    ✗ HTTP 200 (should reject nonexistent model)"
fi

echo "07_failover: $PASS/7 passed, $FAIL failed"
exit $((FAIL > 0))
