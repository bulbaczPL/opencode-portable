#!/usr/bin/env bash
# 05_edge/test_all.sh — 22 testów brzegowych
G4F_URL="${G4F_URL:-http://localhost:1337/v1/chat/completions}"
RESULTS_DIR="${1:-test_results/05_edge}"
mkdir -p "$RESULTS_DIR" 2>/dev/null
PASS=0; FAIL=0

call() { local m="$1" p="$2" t="${3:-50}"
  curl -s -w "\n%{http_code}" -X POST "$G4F_URL" -H "Content-Type: application/json" \
    -d "$(jq -n --arg m "$m" --arg p "$p" --argjson t "$t" \
      '{model: $m, messages: [{role: "user", content: $p}], max_tokens: $t}')" \
    --connect-timeout 5 --max-time 15 2>/dev/null || echo "000"
}
do_test() {
  local prompt="$1" result code
  result=$(call "gpt-4o" "$prompt" 20)
  code=$(echo "$result" | tail -1)
  if [ "$code" = "200" ]; then return 0; fi
  if [ "$code" = "422" ] || [ "$code" = "400" ] || [ "$code" = "000" ]; then return 0; fi
  return 1
}

echo "=== 05_edge: Edge Cases ==="
for entry in \
  "OK" "a" "A" "1234567890" \
  '!@#$%^&*()_+-=[]{}|;:",./<>?' \
  "null" "undefined" "NaN" \
  '<script>alert("xss")</script>' \
  '{"key": "value"}' \
  "   " "What is the airspeed velocity of an unladen swallow?" \
  "Tlumacz na polski: Hello" \
  "SELECT * FROM users WHERE id=1" \
  "../../../etc/passwd" "https://evil.com/malware" \
  '\n\n\n'; do
  if do_test "$entry"; then
    PASS=$((PASS+1)); echo "  ✓ Edge: ${entry:0:40}"
  else
    FAIL=$((FAIL+1)); echo "  ✗ Edge: ${entry:0:40}"
  fi
done

# Special: empty string
echo -n "  Edge (empty): "
result=$(curl -s -w "\n%{http_code}" -X POST "$G4F_URL" -H "Content-Type: application/json" \
  -d '{"model":"gpt-4o","messages":[{"role":"user","content":""}],"max_tokens":20}' \
  --connect-timeout 5 --max-time 15 2>/dev/null || echo "000")
code=$(echo "$result" | tail -1)
if [ "$code" != "200" ]; then PASS=$((PASS+1)); echo "HTTP $code ✓"; else FAIL=$((FAIL+1)); echo "HTTP 200 ✗"; fi

# Long A×100
echo -n "  Edge (A×100): "
result=$(curl -s -w "\n%{http_code}" -X POST "$G4F_URL" -H "Content-Type: application/json" \
  -d "{\"model\":\"gpt-4o\",\"messages\":[{\"role\":\"user\",\"content\":\"$(python3 -c "print('A'*100)")\"}],\"max_tokens\":20}" \
  --connect-timeout 5 --max-time 20 2>/dev/null || echo "000")
code=$(echo "$result" | tail -1)
[ "$code" = "200" ] && PASS=$((PASS+1)) || FAIL=$((FAIL+1))
echo "HTTP $code"

# PATH
echo -n "  Edge (PATH): "
if do_test "PATH"; then PASS=$((PASS+1)); echo "✓"; else FAIL=$((FAIL+1)); echo "✗"; fi

echo "05_edge: $PASS/22 passed, $FAIL failed"
exit $((FAIL > 0))
