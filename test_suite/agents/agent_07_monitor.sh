#!/usr/bin/env bash
#====================================================================
# Agent 7: Performance Monitor & Reporter
#====================================================================
set -euo pipefail
REPORT_DIR="${1:-test_results/agent_07}"
mkdir -p "$REPORT_DIR"
REPORT="$REPORT_DIR/monitor_report.md"

echo "# Performance Monitor Report" > "$REPORT"
echo "Generated: $(date)" >> "$REPORT"
echo "" >> "$REPORT"

check_memory() {
  free -h | awk '/^Mem:/ {print "Memory: " $3 " / " $2}' >> "$REPORT"
}

check_cpu() {
  top -bn1 | awk '/^%Cpu/ {print "CPU: " $2 "% user, " $4 "% sys"}' >> "$REPORT"
}

check_disk() {
  df -h / | awk 'NR==2 {print "Disk: " $3 " / " $2 " (" $5 ")"}' >> "$REPORT"
}

check_g4f() {
  if curl -s -o /dev/null -w "%{http_code}" http://localhost:1337/v1/models --connect-timeout 5 2>/dev/null; then
    echo "G4F API: ONLINE" >> "$REPORT"
  else
    echo "G4F API: OFFLINE" >> "$REPORT"
  fi
}

check_models() {
  echo "" >> "$REPORT"
  echo "## Model Response Times" >> "$REPORT"
  for model in gpt-4o o1 gpt-4 aria; do
    start=$(date +%s%N)
    curl -s -o /dev/null -w "" -X POST http://localhost:1337/v1/chat/completions \
      -H "Content-Type: application/json" \
      -d "$(jq -n --arg m "$model" '{model: $m, messages: [{role: "user", content: "OK"}], max_tokens: 5}')" \
      --connect-timeout 10 --max-time 30 2>/dev/null || true
    end=$(date +%s%N)
    elapsed=$(( (end - start) / 1000000 ))
    echo "- $model: ${elapsed}ms" >> "$REPORT"
  done
}

check_memory
check_cpu
check_disk
check_g4f
check_models

echo "Report: $REPORT"
cat "$REPORT"
echo "Agent 7 done."
