#!/usr/bin/env bash
# 03_agent/test_all.sh — 22 promptów do generowania projektów
set -euo pipefail
G4F_URL="${G4F_URL:-http://localhost:1337/v1/chat/completions}"
RESULTS_DIR="${1:-test_results/03_agent}"
mkdir -p "$RESULTS_DIR"
PASS=0; FAIL=0

call() { local m="$1" p="$2" t="${3:-500}"
  curl -s -w "\n%{http_code}" -X POST "$G4F_URL" -H "Content-Type: application/json" \
    -d "$(jq -n --arg m "$m" --arg p "$p" --argjson t "$t" \
      '{model: $m, messages: [{role: "user", content: $p}], max_tokens: $t}')" \
    --connect-timeout 10 --max-time 120 2>/dev/null
}

PROJECTS=(
  "Python Flask TODO app with SQLite"
  "Node.js Express REST API with 3 endpoints"
  "React component library with Button, Card, Modal"
  "Vue.js todo app with localStorage"
  "Bash script to monitor CPU/memory/disk"
  "Python CLI tool to count lines/words/chars in files"
  "Go HTTP server with /hello and /health endpoints"
  "Rust CLI calculator with + - * / operations"
  "Docker Compose for web + db + cache"
  "FastAPI CRUD for user management"
  "Next.js blog with 3 sample posts"
  "Django models for e-commerce (Product, Order, User)"
  "Flask file upload with virus scan simulation"
  "Express.js middleware for JWT auth"
  "Python script to batch resize images"
  "Shell script that auto-backups a directory"
  "SQLite schema for a library management system"
  "Python async web scraper with aiohttp"
  "Tailwind CSS landing page with hero + features + footer"
  "Redis-based rate limiter in Python"
  "Python script to parse CSV and generate JSON"
  "Makefile with build/test/clean targets for a Python project"
)

for i in "${!PROJECTS[@]}"; do
  prompt="${PROJECTS[$i]}"
  result=$(call "gpt-4o" "Generate a complete $prompt. Provide code in a single markdown block." 1500)
  code=$(echo "$result" | tail -1); body=$(echo "$result" | sed '$d')
  if [ "$code" = "200" ]; then
    content=$(echo "$body" | python3 -c "import sys,json; d=json.load(sys.stdin); print(d.get('choices',[{}])[0].get('message',{}).get('content',''))" 2>/dev/null || echo "")
    lines=$(echo "$content" | wc -l)
    echo "$content" > "$RESULTS_DIR/project_$i.txt"
    echo "  ✓ Project $((i+1)): $lines lines"
    PASS=$((PASS+1))
  else
    echo "  ✗ Project $((i+1)): HTTP $code"
    FAIL=$((FAIL+1))
  fi
done

echo "03_agent: $PASS/22 passed, $FAIL failed"
exit $((FAIL > 0))
