#!/usr/bin/env bash
#=============================================================================
# opencode-portable — self-installing, self-updating opencode config
# Repo: https://github.com/bulbaczPL/opencode-portable
#
# Usage:
#   bash <(curl -sL https://git.io/opencode-portable)
#   # or
#   curl -sL https://git.io/opencode-portable | bash
#
# After install:
#   cd ~/opencode-portable && bash setup.sh
#=============================================================================
set -euo pipefail

REPO="bulbaczPL/opencode-portable"
REPO_URL="https://github.com/$REPO.git"
INSTALL_DIR="$HOME/opencode-portable"
CONFIG_DIR="$HOME/.config/opencode"
SYSTEMD_DIR="$HOME/.config/systemd/user"

GREEN='\033[1;32m'; YELLOW='\033[1;33m'; RED='\033[1;31m'; CYAN='\033[1;36m'; NC='\033[0m'
log()  { echo -e "${CYAN}[opencode-portable]${NC} $1"; }
ok()   { echo -e "${GREEN}  ✓${NC} $1"; }
warn() { echo -e "${YELLOW}  ⚠${NC} $1"; }
fail() { echo -e "${RED}  ✗${NC} $1"; }

#=============================================================================
# AUTO-UPDATE przez gh
#=============================================================================
do_update() {
  log "Sprawdzam aktualizacje..."

  if [ -d "$INSTALL_DIR/.git" ]; then
    # Lokalna kopia — git pull
    cd "$INSTALL_DIR"
    local old_hash
    old_hash=$(git rev-parse HEAD 2>/dev/null || echo "")
    git fetch origin main 2>&1 | grep -v "Already up to date" | grep -v "From" | grep -v "^$" || true
    local new_hash
    new_hash=$(git rev-parse origin/main 2>/dev/null || echo "")

    if [ -n "$old_hash" ] && [ "$new_hash" != "$old_hash" ] && [ -n "$new_hash" ]; then
      echo -ne "  Nowa wersja. Aktualizować? [Y/n] "
      read -r ans
      if [ "$ans" != "n" ] && [ "$ans" != "N" ]; then
        git pull origin main 2>&1 | tail -1
        ok "Zaktualizowano do najnowszej wersji"
      else
        warn "Pomijam"
      fi
    else
      ok "Masz najnowszą wersję"
    fi
    cd - > /dev/null
  else
    # Pierwsza instalacja — curl z raw (nie wymaga git/gh na czystym systemie)
    log "Pobieram pliki z GitHub (curl)..."
    mkdir -p "$INSTALL_DIR"
    TAR_URL="https://api.github.com/repos/$REPO/tarball/main"
    curl -sL "$TAR_URL" | tar xz --strip-components=1 -C "$INSTALL_DIR" 2>&1
    ok "Pobrano pliki"
  fi
}



#=============================================================================
# ZALEŻNOŚCI
#=============================================================================
install_deps() {
  log "Sprawdzam zależności..."
  for cmd in python3 pip3 node npm git; do
    if command -v "$cmd" &>/dev/null; then
      ok "$([ "$cmd" = "python3" ] && echo "Python: $(python3 --version)" || \
            [ "$cmd" = "pip3" ] && echo "pip: $(pip3 --version | awk '{print $2}')" || \
            [ "$cmd" = "node" ] && echo "Node.js: $(node --version)" || \
            [ "$cmd" = "npm" ] && echo "npm: $(npm --version)" || \
            [ "$cmd" = "git" ] && echo "git: $(git --version | awk '{print $3}')")"
    else
      case "$cmd" in
        node|npm)
          log "Instaluję Node.js..."
          curl -fsSL https://deb.nodesource.com/setup_22.x | bash - &>/dev/null
          apt-get install -y nodejs &>/dev/null
          ok "Node.js: $(node --version)"
          ;;
        git)
          apt-get install -y git &>/dev/null
          ok "git zainstalowany"
          ;;
        *)
          fail "$cmd wymagany. Zainstaluj: sudo apt install $cmd"
          return 1
          ;;
      esac
    fi
  done
}

#=============================================================================
# OPENCODE CLI
#=============================================================================
install_opencode() {
  log "Sprawdzam opencode..."
  command -v opencode &>/dev/null && ok "opencode: $(opencode --version 2>/dev/null || echo 'zainstalowany')" \
    || { npm install -g @opencode/cli 2>&1 | tail -1 && ok "opencode CLI zainstalowany"; }
}

#=============================================================================
# G4F
#=============================================================================
install_g4f() {
  log "Sprawdzam G4F..."
  python3 -c "import g4f" &>/dev/null 2>&1 \
    && ok "G4F: $(python3 -c "import g4f; print(f'v{g4f.__version__}')" 2>/dev/null || echo 'zainstalowany')" \
    || { pip3 install g4f 2>&1 | tail -1 && ok "G4F zainstalowany"; }
}

#=============================================================================
# KONFIGURACJA
#=============================================================================
setup_config() {
  log "Konfiguruję opencode..."
  mkdir -p "$CONFIG_DIR" "$CONFIG_DIR/agents" "$CONFIG_DIR/commands"
  cp "$INSTALL_DIR/config/opencode.jsonc" "$CONFIG_DIR/opencode.jsonc" 2>/dev/null && ok "config skopiowany"
  cp "$INSTALL_DIR/agents/"*.md "$CONFIG_DIR/agents/" 2>/dev/null; ok "agenty: $(ls "$INSTALL_DIR/agents/"*.md 2>/dev/null | wc -l)"
  cp "$INSTALL_DIR/commands/"*.md "$CONFIG_DIR/commands/" 2>/dev/null; ok "komendy: $(ls "$INSTALL_DIR/commands/"*.md 2>/dev/null | wc -l)"
}

setup_systemd() {
  log "Konfiguruję G4F service..."
  mkdir -p "$SYSTEMD_DIR"
  cp "$INSTALL_DIR/systemd/g4f.service" "$SYSTEMD_DIR/g4f.service"
  systemctl --user daemon-reload 2>/dev/null || { warn "systemd nie dostępny"; return; }
  systemctl --user enable --now g4f.service 2>/dev/null && ok "G4F aktywny" || warn "G4F: restart"
}

test_g4f() {
  sleep 3
  curl -sf -o /dev/null -w "%{http_code}" -X POST \
    "http://localhost:1337/v1/chat/completions" \
    -H "Content-Type: application/json" \
    -d '{"model":"gpt-4o-mini","messages":[{"role":"user","content":"hi"}],"max_tokens":3}' 2>/dev/null \
    | grep -q 200 && ok "G4F działa na :1337" || warn "G4F nie odpowiada"
}

summary() {
  local pc=0
  [ -f "$CONFIG_DIR/opencode.jsonc" ] && pc=$(python3 -c "import json5; f=open('$CONFIG_DIR/opencode.jsonc'); d=json5.load(f); print(len(d.get('providers',{})))" 2>/dev/null || echo "0")
  local v=$(cat "$INSTALL_DIR/VERSION" 2>/dev/null || echo "?")
  echo ""
  echo -e "${GREEN}╔══════════════════════════════════════════════════════╗${NC}"
  echo -e "${GREEN}║  opencode-portable v$v                                ║${NC}"
  echo -e "${GREEN}╚══════════════════════════════════════════════════════╝${NC}"
  echo "  G4F:    $(systemctl --user is-active g4f.service 2>/dev/null || echo 'ręcznie')"
  echo "  opencode: $(command -v opencode &>/dev/null && echo 'OK' || echo 'brak')"
  echo "  Providerów: $pc"
  echo "  Aktualizacja: cd ~/opencode-portable && bash setup.sh"
  echo ""
}

main() {
  echo ""
  echo -e "${CYAN}╔══════════════════════════════════════════════════════╗${NC}"
  echo -e "${CYAN}║  opencode-portable — Instalator / Aktualizator      ║${NC}"
  echo -e "${CYAN}╚══════════════════════════════════════════════════════╝${NC}"
  echo ""
  install_deps || exit 1
  do_update
  install_opencode
  install_g4f
  setup_config
  setup_systemd
  test_g4f
  summary
}

main "$@"