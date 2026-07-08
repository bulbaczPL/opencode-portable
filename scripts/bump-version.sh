#!/usr/bin/env bash
set -euo pipefail

BASE_DIR="$(cd "$(dirname "$0")/.." && pwd)"
VERSION_FILE="$BASE_DIR/VERSION"

if [ $# -ne 1 ]; then
  echo "Usage: $0 <new_version>"
  echo "  np. $0 1.0.1"
  exit 1
fi

NEW_VERSION="$1"
echo "$NEW_VERSION" > "$VERSION_FILE"
echo "VERSION -> $NEW_VERSION"

# Regeneruj checksumy
bash "$BASE_DIR/scripts/generate-checksums.sh"

echo "Zaktualizowano do v$NEW_VERSION. Zatwierdź i push:"
echo "  git add -A && git commit -m \"v$NEW_VERSION\" && git push"