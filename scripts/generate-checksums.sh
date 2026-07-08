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
  "config/AGENTS.md"
  "config/agents/g4f-manager.md"
  "config/agents/model-router.md"
  "config/commands/g4f-health.md"
  "config/commands/provider-register.md"
  "config/commands/provider-test.md"
  "config/commands/status.md"
  "config/commands/switch-model.md"
  "config/commands/fallback-chain.md"
  "config/commands/auto-failover.md"
  "config/commands/g4f-start.md"
  "config/skills/g4f-management/SKILL.md"
  "config/skills/keyless-providers/SKILL.md"
  "config/skills/provider-registration/SKILL.md"
  "systemd/g4f.service"
)

for f in "${FILES[@]}"; do
  if [ -f "$BASE_DIR/$f" ]; then
    sha256sum "$BASE_DIR/$f" | sed "s|$BASE_DIR/||" >> "$CHECKSUMS_FILE"
  fi
done

echo "checksums.txt wygenerowany ($(wc -l < "$CHECKSUMS_FILE") plików)"