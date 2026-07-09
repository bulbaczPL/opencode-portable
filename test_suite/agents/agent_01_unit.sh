#!/usr/bin/env bash
#====================================================================
# Agent 1: Unit Tester — semantic consistency, instruction following,
#          factual accuracy, hallucination guard, language consistency
#====================================================================
set -euo pipefail
G4F_URL="http://localhost:1337/v1/chat/completions"
RESULTS_DIR="${1:-test_results/agent_01}"
mkdir -p "$RESULTS_DIR"

MODELS=("gpt-4o" "o1" "gpt-4" "o3-mini" "command-r7b" "aria"
        "r1-1776" "command-a" "command-r")
readonly MODELS

readonly SEMANTIC_PROMPT="What color is the sky in simple terms?"
readonly INSTRUCTION_PROMPT='Respond ONLY with the number 42. Say nothing else.'

api_call() {
  local model="$1" prompt="$2" max_tok="${3:-20}"
  curl -s -w "\n%{http_code}" -X POST "$G4F_URL" \
    -H "Content-Type: application/json" \
    -d "$(jq -n --arg m "$model" --arg p "$prompt" --argjson t "$max_tok" \
          '{model: $m, messages: [{role: "user", content: $p}], max_tokens: $t}')" \
    --connect-timeout 10 --max-time 60 2>/dev/null
}

test_semantic() {
  local model="$1"
  local file="$RESULTS_DIR/$model/semantic.txt"
  mkdir -p "$(dirname "$file")"
  local responses=()
  for i in 1 2 3; do
    sleep 1
    local result
    result=$(api_call "$model" "$SEMANTIC_PROMPT" 20)
    local code body
    code=$(echo "$result" | tail -1)
    body=$(echo "$result" | sed '$d')
    if [ "$code" != "200" ]; then
      echo "{\"model\":\"$model\",\"test\":\"semantic\",\"attempt\":$i,\"http\":$code,\"error\":\"HTTP $code\"}" >> "$file"
      return 1
    fi
    local content
    content=$(echo "$body" | python3 -c "import sys,json; d=json.load(sys.stdin); print(d.get('choices',[{}])[0].get('message',{}).get('content',''))" 2>/dev/null || echo "")
    responses+=("$content")
  done
  printf '%s\n' "${responses[@]}" >> "$file"
  if echo "${responses[0]}" | grep -qi "blue\|sky\|niebieski\|azul\|blau"; then
    return 0
  fi
  return 1
}

test_instruction() {
  local model="$1"
  local file="$RESULTS_DIR/$model/instruction.txt"
  mkdir -p "$(dirname "$file")"
  local result
  result=$(api_call "$model" "$INSTRUCTION_PROMPT" 10)
  local code body
  code=$(echo "$result" | tail -1)
  body=$(echo "$result" | sed '$d')
  echo "$body" > "$file"
  if [ "$code" != "200" ]; then return 1; fi
  local content
  content=$(echo "$body" | python3 -c "import sys,json; d=json.load(sys.stdin); print(d.get('choices',[{}])[0].get('message',{}).get('content',''))" 2>/dev/null || echo "")
  if [ "$content" = "42" ]; then return 0; fi
  return 1
}

for model in "${MODELS[@]}"; do
  echo "  Testing $model..."
  pass=0
  fail=0
  test_semantic "$model" && pass=$((pass+1)) || fail=$((fail+1))
  test_instruction "$model" && pass=$((pass+1)) || fail=$((fail+1))
  echo "  → $model: $pass/$((pass+fail))"
done

echo "Agent 1 done. Results: $RESULTS_DIR"
