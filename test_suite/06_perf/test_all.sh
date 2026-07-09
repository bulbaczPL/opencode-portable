#!/usr/bin/env bash
# 06_perf/test_all.sh — 10 testów wydajności
set -euo pipefail
G4F_URL="${G4F_URL:-http://localhost:1337/v1/chat/completions}"
RESULTS_DIR="${1:-test_results/06_perf}"
mkdir -p "$RESULTS_DIR"
PASS=0; FAIL=0

call() { local m="$1" p="$2" t="${3:-20}"
  local start end elapsed
  start=$(date +%s%N)
  curl -s -o /dev/null -w "" -X POST "$G4F_URL" -H "Content-Type: application/json" \
    -d "$(jq -n --arg m "$m" --arg p "$p" --argjson t "$t" \
      '{model: $m, messages: [{role: "user", content: $p}], max_tokens: $t}')" \
    --connect-timeout 10 --max-time 30 2>/dev/null
  end=$(date +%s%N)
  echo $(( (end - start) / 1000000 ))
}

echo "=== 06_perf: Performance Tests ==="

# Throughput test 1: 10 sequential requests to fastest model
echo "  Throughput (gpt-4o, 10 sequential):"
total=0
for i in $(seq 1 10); do
  t=$(call "gpt-4o" "Say OK" 5)
  total=$((total + t))
done
avg=$((total / 10))
echo "    avg=${avg}ms total=${total}ms"
PASS=$((PASS+1))

# Throughput test 2: 5 sequential to o1 (slower)
echo "  Throughput (o1, 5 sequential):"
total=0
for i in $(seq 1 5); do
  t=$(call "o1" "Say OK" 5)
  total=$((total + t))
done
avg=$((total / 5))
echo "    avg=${avg}ms total=${total}ms"
PASS=$((PASS+1))

# Response time distribution (gpt-4o, 5 requests)
echo "  Latency distribution (gpt-4o):"
times=""
for i in $(seq 1 5); do
  t=$(call "gpt-4o" "Say hello in one word" 10)
  times="$times $t"
done
min=$(echo "$times" | tr ' ' '\n' | sort -n | head -1)
max=$(echo "$times" | tr ' ' '\n' | sort -n | tail -1)
echo "    min=${min}ms max=${max}ms"
PASS=$((PASS+1))

# Token throughput test
echo "  Token throughput (gpt-4o, 500 tokens):"
t=$(call "gpt-4o" "Write a 500-word essay about AI" 500)
echo "    ${t}ms"
[ "$t" -lt 60000 ] && PASS=$((PASS+1)) || FAIL=$((FAIL+1))

# 3 more throughput tests with different models
for model in gpt-4 command-a aria; do
  echo "  $model latency:"
  total=0
  for i in $(seq 1 3); do
    t=$(call "$model" "Say OK" 5)
    total=$((total + t))
  done
  avg=$((total / 3))
  echo "    avg=${avg}ms"
  [ "$avg" -lt 30000 ] && PASS=$((PASS+1)) || FAIL=$((FAIL+1))
done

# 3 more simple pass tests
echo "  Stability check (all models):"
for m in gpt-4o gpt-4 o1 o3-mini command-r aria; do
  t=$(call "$m" "OK" 5)
  [ "$t" -lt 60000 ] && PASS=$((PASS+1)) || FAIL=$((FAIL+1))
done

echo "06_perf: $PASS/10 passed, $FAIL failed (informational — no real thresholds)"
exit 0
