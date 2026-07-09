#!/usr/bin/env bash
#====================================================================
# Agent 4: Refactoring Specialist — code quality improvement
#====================================================================
set -euo pipefail
G4F_URL="http://localhost:1337/v1/chat/completions"
RESULTS_DIR="${1:-test_results/agent_04}"
mkdir -p "$RESULTS_DIR"

SNIPPETS=(
  'def f(x):\n    r = []\n    for i in range(len(x)):\n        r.append(x[i] * 2)\n    return r'
  'def calc(a,b,c):\n    t = a + b\n    return t + c + t + c + t + c'
  'x = 42\ny = 7\nz = x * y\nprint(z)\nw = x / y\nprint(w)'
)

for i in "${!SNIPPETS[@]}"; do
  snippet="${SNIPPETS[$i]}"
  echo "  Snippet #$((i+1))"

  prompt="Refactor this Python code to be more idiomatic, readable, and efficient.\nProvide ONLY the refactored code in a single code block.\n\n\`\`\`python\n$snippet\n\`\`\`"
  result=$(curl -s -w "\n%{http_code}" -X POST "$G4F_URL" \
    -H "Content-Type: application/json" \
      -d "$(jq -n --arg m "gpt-4o" --arg p "$prompt" \
          '{model: $m, messages: [{role: "user", content: $p}], max_tokens: 200}')" \
    --connect-timeout 10 --max-time 60 2>/dev/null)
  code=$(echo "$result" | tail -1)
  body=$(echo "$result" | sed '$d')

  if [ "$code" != "200" ]; then
    echo "  ✗ Snippet #$((i+1)): HTTP $code"
    continue
  fi

  content=$(echo "$body" | python3 -c "import sys,json; d=json.load(sys.stdin); print(d.get('choices',[{}])[0].get('message',{}).get('content',''))" 2>/dev/null || echo "")
  refactored=$(echo "$content" | awk '/```python/{flag=1; next} /```/ { if (flag) flag=0; next } flag')
  if [ -z "$refactored" ]; then
    refactored=$(echo "$content" | awk '/```/ { if (!flag) flag=1; else flag=0; next } flag')
  fi

  f="$RESULTS_DIR/refactored_$i.py"
  echo "$refactored" > "$f"

  if python3 -c "compile(open('$f').read(), '$f', 'exec')" 2>/dev/null; then
    echo "  ✓ Snippet #$((i+1)): syntax OK"
  else
    err=$(python3 -c "compile(open('$f').read(), '$f', 'exec')" 2>&1 || true)
    echo "  ⚠ Snippet #$((i+1)): $err"
  fi
done

echo "Agent 4 done."
