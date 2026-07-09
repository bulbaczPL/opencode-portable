#!/usr/bin/env bash
set -euo pipefail

log()  { echo -e "${CYAN:-}[toolbox]${NC:-} $1"; }
ok()   { echo -e "${GREEN:-}  ✓${NC:-} $1"; }
warn() { echo -e "${YELLOW:-}  ⚠${NC:-} $1"; }

log "Instaluję toolbox dla agentów testowych..."

# Detekcja OS
if command -v apt-get &>/dev/null; then
  INSTALL_CMD="sudo apt-get install -y -qq"
elif command -v dnf &>/dev/null; then
  INSTALL_CMD="sudo dnf install -y -q"
elif command -v pacman &>/dev/null; then
  INSTALL_CMD="sudo pacman -S --noconfirm"
else
  warn "Nieznany menedżer pakietów — próbuję apt-get"
  INSTALL_CMD="sudo apt-get install -y -qq"
fi

# System packages
$INSTALL_CMD \
  shellcheck jq parallel curl git python3 python3-pip nodejs npm \
  gcc g++ ruby php-cli lua5.4 sqlite3 netcat-openbsd nmap \
  2>/dev/null || warn "Część pakietów systemowych nie została zainstalowana"

# Python tools
if pip3 install --break-system-packages -q \
  bandit pylint flake8 mypy radon semgrep 2>/dev/null; then
  ok "Python tools"
else
  warn "Python tools partial"
fi

# Node tools
if npm install -g markdownlint-cli typescript eslint prettier 2>/dev/null; then
  ok "Node tools"
else
  warn "Node tools partial"
fi

# Go tools (gitleaks)
if command -v go &>/dev/null; then
  if go install github.com/gitleaks/gitleaks/v8@latest 2>/dev/null; then
    ok "gitleaks"
  else
    warn "gitleaks"
  fi
else
  warn "Go not available — skip gitleaks"
fi

# Debug: what we have
echo ""
echo "=== Toolbox Status ==="
for tool in shellcheck jq parallel curl git python3 node npm gcc g++ ruby php lua5.4 sqlite3 bandit pylint flake8 mypy radon gitleaks; do
  if command -v "$tool" &>/dev/null; then
    ok "$tool: $($tool --version 2>&1 | head -1)"
  else
    warn "$tool: NOT FOUND"
  fi
done

echo ""
ok "Toolbox installation complete"
