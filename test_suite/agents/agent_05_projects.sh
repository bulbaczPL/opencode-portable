#!/usr/bin/env bash
#====================================================================
# Agent 5: Micro Project Generator — full stack micro-apps
#====================================================================
set -euo pipefail
G4F_URL="http://localhost:1337/v1/chat/completions"
RESULTS_DIR="${1:-test_results/agent_05}"
mkdir -p "$RESULTS_DIR"

PROJECT_TASKS=(
  "Python:Create a Flask TODO app with SQLite. Single file."
  "JavaScript:Create a Node.js Express REST API with 3 endpoints."
  "Python:Create a CLI tool that counts words in a file."
  "Bash:Create a script that monitors CPU and memory usage."
)

for task in "${PROJECT_TASKS[@]}"; do
  lang="${task%%:*}"
  desc="${task#*:}"
  echo "  Generating $lang project: ${desc:0:60}..."

  result=$(curl -s -w "\n%{http_code}" -X POST "$G4F_URL" \
    -H "Content-Type: application/json" \
    -d "$(jq -n --arg m "gpt-4o" --arg p "$desc" \
          '{model: $m, messages: [{role: "user", content: $p}], max_tokens: 500}')" \
    --connect-timeout 10 --max-time 120 2>/dev/null)
  code=$(echo "$result" | tail -1)
  body=$(echo "$result" | sed '$d')

  if [ "$code" != "200" ]; then
    echo "  ✗ $lang project: HTTP $code"
    continue
  fi

  content=$(echo "$body" | python3 -c "import sys,json; d=json.load(sys.stdin); print(d.get('choices',[{}])[0].get('message',{}).get('content',''))" 2>/dev/null || echo "")
  f="$RESULTS_DIR/project_${lang}.txt"
  echo "$content" > "$f"
  lines=$(echo "$content" | wc -l)
  echo "  ✓ $lang project: $lines lines generated"
done

echo "Agent 5 done."
