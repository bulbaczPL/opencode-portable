#!/usr/bin/env bash
#====================================================================
# Agent 2: Code Polyglot — test code generation in 10+ languages
#====================================================================
set -euo pipefail
G4F_URL="http://localhost:1337/v1/chat/completions"
RESULTS_DIR="${1:-test_results/agent_02}"
mkdir -p "$RESULTS_DIR"

check_code() {
  local lang="$1" file="$2"
  case "$lang" in
    Python) python3 -c "compile(open('$file').read(), '$file', 'exec')" 2>/dev/null ;;
    JavaScript) node --check "$file" 2>/dev/null ;;
    Bash) bash -n "$file" 2>/dev/null ;;
    Ruby) ruby -c "$file" 2>/dev/null ;;
    PHP) php -l "$file" 2>/dev/null ;;
    Lua) luac -p "$file" 2>/dev/null ;;
    SQL) sqlite3 :memory: ".read $file" 2>/dev/null ;;
    *) return 1 ;;
  esac
}

LANGUAGES=("Python:py" "JavaScript:js" "Bash:sh" "Ruby:rb" "PHP:php" "Lua:lua" "SQL:sql")

TASKS=(
  "Write a Hello World program in LANGUAGE."
  "Write a FizzBuzz function in LANGUAGE."
  "Write a Fibonacci function with memoization in LANGUAGE."
)

for lang_entry in "${LANGUAGES[@]}"; do
  lang_name="${lang_entry%%:*}"
  lang_ext="${lang_entry#*:}"

  echo "  Testing $lang_name..."

  for task_i in "${!TASKS[@]}"; do
    task="${TASKS[$task_i]}"
    prompt="${task/LANGUAGE/$lang_name}"

    result=$(curl -s -w "\n%{http_code}" -X POST "$G4F_URL" \
      -H "Content-Type: application/json" \
      -d "$(jq -n --arg m "gpt-4o" --arg p "$prompt" \
            '{model: $m, messages: [{role: "user", content: $p}], max_tokens: 200}')" \
      --connect-timeout 10 --max-time 60 2>/dev/null)
    code=$(echo "$result" | tail -1)
    body=$(echo "$result" | sed '$d')

    if [ "$code" != "200" ]; then
      echo "  ✗ $lang_name task[$task_i]: HTTP $code"
      continue
    fi

    content=$(echo "$body" | python3 -c "import sys,json; d=json.load(sys.stdin); print(d.get('choices',[{}])[0].get('message',{}).get('content',''))" 2>/dev/null || echo "")
    code_block=$(echo "$content" | awk '/```/ { if (!flag) flag=1; else flag=0; next } flag')
    if [ -z "$code_block" ]; then
      echo "  ⚠ $lang_name task[$task_i]: no code block"
      continue
    fi

    f="$RESULTS_DIR/test_${lang_name}_${task_i}.${lang_ext}"
    echo "$code_block" > "$f"

    if check_code "$lang_name" "$f"; then
      echo "  ✓ $lang_name task[$task_i]: compile OK"
    else
      echo "  ✗ $lang_name task[$task_i]: compile FAIL"
    fi
  done
done

echo "Agent 2 done."
