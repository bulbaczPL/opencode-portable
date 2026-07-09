#!/usr/bin/env bash
#====================================================================
# Agent 8: Chaos Engineer — stress test & failover
#====================================================================
set -euo pipefail
G4F_URL="http://localhost:1337/v1/chat/completions"
RESULTS_DIR="${1:-test_results/agent_08}"
mkdir -p "$RESULTS_DIR"
PASS=0
FAIL=0

stop_g4f() {
  pkill -f "python3 -m g4f" 2>/dev/null || true
  pkill -f "g4f.api" 2>/dev/null || true
  sleep 1
}

start_g4f() {
  cd /home/michal/opencode-portable
  python3 -m g4f.api --port 1337 --debug 2>/dev/null &
  for i in $(seq 1 10); do
    if curl -s -o /dev/null -w "" http://localhost:1337/v1/models --connect-timeout 2 2>/dev/null; then
      return 0
    fi
    sleep 2
  done
  return 1
}

test_g4f() {
  local model="$1"
  local result
  result=$(curl -s -w "\n%{http_code}" -X POST "$G4F_URL" \
    -H "Content-Type: application/json" \
    -d "$(jq -n --arg m "$model" '{model: $m, messages: [{role: "user", content: "OK"}], max_tokens: 5}')" \
    --connect-timeout 5 --max-time 15 2>/dev/null)
  echo "$result" | tail -1
}

echo "=== Chaos Test 1: Stop & Restart G4F ==="
stop_g4f
if start_g4f; then
  echo "  ✓ Restart OK"
  PASS=$((PASS+1))
else
  echo "  ✗ Restart FAIL"
  FAIL=$((FAIL+1))
fi

echo "=== Chaos Test 2: Rapid model switching (20 requests) ==="
MODELS=(gpt-4o o1 gpt-4 aria o3-mini)
PASSING=0
for i in $(seq 1 20); do
  m=${MODELS[$((RANDOM % ${#MODELS[@]}))]}
  code=$(test_g4f "$m")
  [ "$code" = "200" ] && PASSING=$((PASSING+1))
done
echo "  Rapid switch: $PASSING/20 OK"
[ "$PASSING" -ge 15 ] && PASS=$((PASS+1)) || FAIL=$((FAIL+1))

echo "=== Chaos Test 3: Concurrent requests ==="
WORKDIR=$(mktemp -d)
for i in $(seq 1 5); do
  (
    for j in $(seq 1 3); do
      m=${MODELS[$((RANDOM % ${#MODELS[@]}))]}
      test_g4f "$m" > "$WORKDIR/result_${i}_${j}.txt" 2>/dev/null
    done
  ) &
done
wait
OK_COUNT=$(grep -l "200" "$WORKDIR"/result_*.txt 2>/dev/null | wc -l)
rm -rf "$WORKDIR"
echo "  Concurrent: $OK_COUNT/15 OK"
[ "$OK_COUNT" -ge 10 ] && PASS=$((PASS+1)) || FAIL=$((FAIL+1))

echo "=== Chaos Test 4: Malformed JSON ==="
result=$(curl -s -w "\n%{http_code}" -X POST "$G4F_URL" \
  -H "Content-Type: application/json" \
  -d 'invalid json' --connect-timeout 5 --max-time 10 2>/dev/null)
code=$(echo "$result" | tail -1)
[ "$code" != "200" ] && PASS=$((PASS+1)) || FAIL=$((FAIL+1))
echo "  Malformed JSON: HTTP $code (expected non-200)"

echo "=== Chaos Test 5: Empty messages ==="
result=$(curl -s -w "\n%{http_code}" -X POST "$G4F_URL" \
  -H "Content-Type: application/json" \
  -d '{"model":"gpt-4o","messages":[]}' --connect-timeout 5 --max-time 10 2>/dev/null)
code=$(echo "$result" | tail -1)
[ "$code" != "200" ] && PASS=$((PASS+1)) || FAIL=$((FAIL+1))
echo "  Empty messages: HTTP $code (expected non-200)"

echo ""
echo "Agent 8 done. Pass=$PASS Fail=$FAIL"
echo "Results: $RESULTS_DIR"
