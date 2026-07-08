#!/usr/bin/env bash
#=============================================================================
# opencode-portable — self-installing, self-updating opencode config
# Repo: https://github.com/DevMike1993/opencode-portable
#
# Usage:
#   bash <(curl -sL https://tinyurl.com/opencode-portable)
#   # or after install:
#   ~/opencode-portable/setup.sh
#
# To update:
#   cd ~/opencode-portable && git pull && ./setup.sh
#=============================================================================
set -euo pipefail

REPO_URL="https://github.com/DevMike1993/opencode-portable.git"
INSTALL_DIR="$HOME/opencode-portable"
CONFIG_DIR="$HOME/.config/opencode"
SYSTEMD_DIR="$HOME/.config/systemd/user"

GREEN='\033[1;32m'
YELLOW='\033[1;33m'
RED='\033[1;31m'
CYAN='\033[1;36m'
BOLD='\033[1m'
NC='\033[0m'

log()  { echo -e "${CYAN}[opencode-portable]${NC} $1"; }
ok()   { echo -e "${GREEN}  ✓${NC} $1"; }
warn() { echo -e "${YELLOW}  ⚠${NC} $1"; }
fail() { echo -e "${RED}  ✗${NC} $1"; }

#=============================================================================
# AUTO-UPDATE (przez git pull)
#=============================================================================
do_update() {
  log "Sprawdzam aktualizacje..."

  if [ ! -d "$INSTALL_DIR/.git" ]; then
    log "Brak repozytorium git — pobieram całość..."
    rm -rf "$INSTALL_DIR"
    git clone --depth 1 "$REPO_URL" "$INSTALL_DIR"
    ok "Pobrano najnowszą wersję"
    return
  fi

  cd "$INSTALL_DIR"

  # Pobierz najnowsze zmiany
  local old_hash
  old_hash=$(git rev-parse HEAD 2>/dev/null || echo "")

  git fetch origin main 2>&1 | grep -v "Already up to date" | grep -v "From" || true

  local remote_hash
  remote_hash=$(git rev-parse origin/main 2>/dev/null || echo "")

  if [ "$old_hash" = "$remote_hash" ] || [ -z "$remote_hash" ]; then
    ok "Masz najnowszą wersję"
    return
  fi

  # Pytaj przed aktualizacją
  if [ -t 1 ]; then
    echo -n "  Nowa wersja dostępna. Aktualizować? [Y/n] "
    read -r answer
    if [ "$answer" = "n" ] || [ "$answer" = "N" ]; then
      warn "Pomijam aktualizację"
      return
    fi
  fi

  log "Aktualizuję..."
  git pull origin main 2>&1 | tail -3
  ok "Zaktualizowano do najnowszej wersji"

  cd - > /dev/null
}

#=============================================================================
# INSTALACJA ZALEŻNOŚCI
#=============================================================================
install_deps() {
  log "Sprawdzam zależności..."

  if command -v python3 &>/dev/null; then
    ok "Python: $(python3 --version)"
  else
    fail "Python3 wymagany. Zainstaluj: sudo apt install python3 python3-pip"
    return 1
  fi

  if command -v pip3 &>/dev/null; then
    ok "pip: $(pip3 --version | awk '{print $2}')"
  elif command -v pip &>/dev/null; then
    ok "pip: $(pip --version | awk '{print $2}')"
  else
    fail "pip wymagany. Zainstaluj: sudo apt install python3-pip"
    return 1
  fi

  if command -v node &>/dev/null; then
    ok "Node.js: $(node --version)"
  else
    log "Instaluję Node.js..."
    if command -v apt &>/dev/null; then
      curl -fsSL https://deb.nodesource.com/setup_22.x | bash -
      apt-get install -y nodejs
      ok "Node.js zainstalowany"
    else
      warn "Zainstaluj Node.js ręcznie: https://nodejs.org"
    fi
  fi

  if command -v npm &>/dev/null; then
    ok "npm: $(npm --version)"
  else
    fail "npm wymagany. Zainstaluj Node.js (zawiera npm)"
    return 1
  fi

  if command -v git &>/dev/null; then
    ok "git: $(git --version | awk '{print $3}')"
  else
    log "Instaluję git..."
    apt-get install -y git
    ok "git zainstalowany"
  fi
}

#=============================================================================
# INSTALACJA OPENCODE CLI
#=============================================================================
install_opencode() {
  log "Sprawdzam opencode CLI..."

  if command -v opencode &>/dev/null; then
    ok "opencode: $(opencode --version 2>/dev/null || echo 'zainstalowany')"
  else
    log "Instaluję opencode CLI przez npm..."
    npm install -g @opencode/cli 2>&1 | tail -3
    ok "opencode CLI zainstalowany"
  fi
}

#=============================================================================
# INSTALACJA G4F
#=============================================================================
install_g4f() {
  log "Sprawdzam G4F (GPT4Free)..."

  if python3 -c "import g4f" &>/dev/null 2>&1; then
    local ver
    ver=$(python3 -c "import g4f; print(g4f.__version__)" 2>/dev/null || echo "zainstalowany")
    ok "G4F: $ver"
  else
    log "Instaluję G4F przez pip..."
    pip3 install g4f 2>&1 | tail -3
    ok "G4F zainstalowany"
  fi
}

#=============================================================================
# KONFIGURACJA OPENCODE
#=============================================================================
setup_config() {
  log "Konfiguruję opencode..."

  mkdir -p "$CONFIG_DIR"
  mkdir -p "$CONFIG_DIR/agents"
  mkdir -p "$CONFIG_DIR/commands"

  if [ -f "$INSTALL_DIR/config/opencode.jsonc" ]; then
    cp "$INSTALL_DIR/config/opencode.jsonc" "$CONFIG_DIR/opencode.jsonc"
    ok "opencode.jsonc skopiowany"
  else
    warn "Brak config/opencode.jsonc"
  fi

  if ls "$INSTALL_DIR/agents/"*.md &>/dev/null; then
    cp "$INSTALL_DIR/agents/"*.md "$CONFIG_DIR/agents/" 2>/dev/null
    ok "Agenty skopiowane"
  fi

  if ls "$INSTALL_DIR/commands/"*.md &>/dev/null; then
    cp "$INSTALL_DIR/commands/"*.md "$CONFIG_DIR/commands/" 2>/dev/null
    ok "Komendy skopiowane"
  fi
}

#=============================================================================
# KONFIGURACJA SYSTEMD
#=============================================================================
setup_systemd() {
  log "Konfiguruję G4F jako serwis systemd..."

  if [ ! -f "$INSTALL_DIR/systemd/g4f.service" ]; then
    warn "Brak pliku g4f.service"
    return
  fi

  mkdir -p "$SYSTEMD_DIR"
  cp "$INSTALL_DIR/systemd/g4f.service" "$SYSTEMD_DIR/g4f.service"

  systemctl --user daemon-reload 2>/dev/null || {
    warn "systemd nie dostępny (WSL bez systemd?)"
    warn "Uruchom G4F ręcznie: python3 -c \"from g4f.api import run_api; run_api(port=1337)\""
    return
  }

  if systemctl --user is-enabled g4f.service &>/dev/null 2>&1; then
    systemctl --user restart g4f.service 2>/dev/null || true
  else
    systemctl --user enable --now g4f.service 2>/dev/null || {
      warn "Nie udało się włączyć serwisu"
    }
  fi

  ok "G4F service skonfigurowany"
}

#=============================================================================
# TEST G4F
#=============================================================================
test_g4f() {
  log "Testuję G4F endpoint..."
  sleep 3

  if command -v curl &>/dev/null; then
    local code
    code=$(curl -s -o /dev/null -w "%{http_code}" -X POST \
      "http://localhost:1337/v1/chat/completions" \
      -H "Content-Type: application/json" \
      -d '{"model":"gpt-4o-mini","messages":[{"role":"user","content":"hi"}],"max_tokens":3}' 2>/dev/null || echo "000")

    if [ "$code" = "200" ]; then
      ok "G4F endpoint działa na http://localhost:1337"
    else
      warn "G4F endpoint: HTTP $code"
    fi
  fi
}

#=============================================================================
# PODSUMOWANIE
#=============================================================================
summary() {
  local version
  version=$(cat "$INSTALL_DIR/VERSION" 2>/dev/null || echo "?")
  local provider_count=0

  if [ -f "$CONFIG_DIR/opencode.jsonc" ] && command -v python3 &>/dev/null; then
    provider_count=$(python3 -c "
import json5
with open('$CONFIG_DIR/opencode.jsonc') as f:
    d = json5.load(f)
print(len(d.get('provider', {})))
" 2>/dev/null || echo "?")
  fi

  echo ""
  echo -e "${GREEN}╔══════════════════════════════════════════════════════════╗${NC}"
  echo -e "${GREEN}║           opencode-portable v$ver                        ║${NC}"
  echo -e "${GREEN}╚══════════════════════════════════════════════════════════╝${NC}"
  echo ""

  if command -v systemctl &>/dev/null; then
    echo "  ● G4F service: $(systemctl --user is-active g4f.service 2>/dev/null || echo 'nieaktywny')"
  fi
  echo "  ● opencode CLI: $(command -v opencode &>/dev/null && echo 'zainstalowany' || echo 'brak')"
  echo "  ● Providerów w configu: $provider_count"
  echo "  ● Katalog: $INSTALL_DIR"
  echo ""
  echo "  Aby zaktualizować:  cd $INSTALL_DIR && git pull && ./setup.sh"
  echo "  Aby sprawdzić:      opencode config"
  echo ""
}

#=============================================================================
# MAIN
#=============================================================================
main() {
  echo ""
  echo -e "${CYAN}╔══════════════════════════════════════════════════════════╗${NC}"
  echo -e "${CYAN}║  opencode-portable — Instalator / Aktualizator          ║${NC}"
  echo -e "${CYAN}║  ${REPO_URL}  ║${NC}"
  echo -e "${CYAN}╚══════════════════════════════════════════════════════════╝${NC}"
  echo ""

  do_update
  install_deps
  install_opencode
  install_g4f
  setup_config
  setup_systemd
  test_g4f
  summary
}

main "$@"