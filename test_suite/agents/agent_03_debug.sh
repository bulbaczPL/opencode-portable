#!/usr/bin/env bash
#====================================================================
# Agent 3: Smart Debugger — finds and fixes bugs in generated code
#====================================================================
set -euo pipefail
G4F_URL="http://localhost:1337/v1/chat/completions"
RESULTS_DIR="${1:-test_results/agent_03}"
mkdir -p "$RESULTS_DIR"

BUGGY_SNIPPETS=(
  'print("Hello World"'                          # missing paren
  'x = [1,2,3]; print(x[3])'                      # index error
  'def f(): return 1/0'                            # zero division
  'import os; os.remove("/nonexistent/file")'     # file error
)

for i in "${!BUGGY_SNIPPETS[@]}"; do
  snippet="${BUGGY_SNIPPETS[$i]}"
  echo "  Bug #$((i+1)): $snippet"

  prompt="Fix this Python bug. Explain what is wrong and provide corrected code.\n\n\`\`\`\n$snippet\n\`\`\`"
  result=$(curl -s -w "\n%{http_code}" -X POST "$G4F_URL" \
    -H "Content-Type: application/json" \
      -d "$(jq -n --arg m "gpt-4o" --arg p "$prompt" \
          '{model: $m, messages: [{role: "user", content: $p}], max_tokens: 200}')" \
    --connect-timeout 10 --max-time 60 2>/dev/null)
  code=$(echo "$result" | tail -1)
  body=$(echo "$result" | sed '$d')

  if [ "$code" != "200" ]; then
    echo "  ✗ Bug #$((i+1)): HTTP $code"
    continue
  fi

  content=$(echo "$body" | python3 -c "import sys,json; d=json.load(sys.stdin); print(d.get('choices',[{}])[0].get('message',{}).get('content',''))" 2>/dev/null || echo "")
  fix=$(echo "$content" | awk '/```python/{flag=1; next} /```/ { if (flag) flag=0; next } flag')
  if [ -z "$fix" ]; then
    fix=$(echo "$content" | awk '/```/ { if (!flag) flag=1; else flag=0; next } flag')
  fi

  f="$RESULTS_DIR/fix_$i.py"
  echo "$fix" > "$f"

  if python3 -c "compile(open('$f').read(), '$f', 'exec')" 2>/dev/null; then
    echo "  ✓ Bug #$((i+1)): fixed (syntax OK)"
  else
    err=$(python3 -c "compile(open('$f').read(), '$f', 'exec')" 2>&1 || true)
    echo "  ⚠ Bug #$((i+1)): partial fix — $err"
  fi
done

echo "Agent 3 done."
