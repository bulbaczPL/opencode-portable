#!/usr/bin/env bash
set -euo pipefail

BASE_DIR="$(cd "$(dirname "$0")/.." && pwd)"
CHECKSUMS_FILE="$BASE_DIR/checksums.txt"

cd "$BASE_DIR"

> "$CHECKSUMS_FILE"

# Lista plików do monitorowania (względem BASE_DIR)
FILES=(
  "VERSION"
  "setup.sh"
  "config/opencode.jsonc"
  "agents/model-router.md"
  "commands/auto-failover.md"
  "commands/fallback-chain.md"
  "commands/g4f-start.md"
  "commands/status.md"
  "commands/switch-model.md"
  "systemd/g4f.service"
)

for f in "${FILES[@]}"; do
  if [ -f "$BASE_DIR/$f" ]; then
    sha256sum "$BASE_DIR/$f" | sed "s|$BASE_DIR/||" >> "$CHECKSUMS_FILE"
  fi
done

echo "checksums.txt wygenerowany ($(wc -l < "$CHECKSUMS_FILE") plików)"