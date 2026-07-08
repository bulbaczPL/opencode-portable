#!/usr/bin/env bash
#=============================================================================
# opencode-portable — self-installing, self-updating opencode config
# Repo: https://github.com/DevMike1993/opencode-portable
#
# Usage:
#   curl -L https://raw.githubusercontent.com/DevMike1993/opencode-portable/main/setup.sh | bash
#   # or after install:
#   ~/opencode-portable/setup.sh
#=============================================================================
set -euo pipefail

REPO_OWNER="DevMike1993"
REPO_NAME="opencode-portable"
REPO_BRANCH="main"
REPO_BASE="https://raw.githubusercontent.com/$REPO_OWNER/$REPO_NAME/$REPO_BRANCH"

INSTALL_DIR="$HOME/opencode-portable"
CONFIG_DIR="$HOME/.config/opencode"
SYSTEMD_DIR="$HOME/.config/systemd/user"

VERSION="1.0.0"
YELLOW='\033[1;33m'
GREEN='\033[1;32m'
RED='\033[1;31m'
CYAN='\033[1;36m'
NC='\033[0m'

log()  { echo -e "${CYAN}[opencode-portable]${NC} $1"; }
ok()   { echo -e "${GREEN}  ✓${NC} $1"; }
warn() { echo -e "${YELLOW}  ⚠${NC} $1"; }
fail() { echo -e "${RED}  ✗${NC} $1"; }

#=============================================================================
# AUTO-UPDATE
#=============================================================================
auto_update() {
  log "Sprawdzam aktualizacje..."

  # Pobierz VERSION z repo
  local remote_version
  remote_version=$(curl -sf "$REPO_BASE/VERSION" 2>/dev/null || echo "")

  if [ -z "$remote_version" ]; then
    warn "Nie mogę sprawdzić wersji online — kontynuuję z lokalną"
    return
  fi

  # Porównaj wersje (sort -V porównuje semver)
  if [ "$(printf '%s\n' "$VERSION" "$remote_version" | sort -V | tail -1)" != "$VERSION" ]; then
    log "Nowa wersja: $remote_version (obecna: $VERSION)"
    echo -n "   Aktualizować? [Y/n] "
    read -r answer
    if [ "$answer" != "n" ] && [ "$answer" != "N" ]; then
      update_files "$remote_version"
    else
      warn "Pomijam aktualizację"
    fi
  else
    ok "Masz najnowszą wersję ($VERSION)"
  fi
}

update_files() {
  local new_version="$1"

  log "Pobieram listę plików do aktualizacji..."

  # Pobierz checksumy z repo
  local remote_checksums
  remote_checksums=$(curl -sf "$REPO_BASE/checksums.txt") || {
    warn "Nie mogę pobrać checksums.txt — pobieram wszystko"
    download_all "$new_version"
    return
  }

  # Pobierz lokalne checksumy
  local temp_dir
  temp_dir=$(mktemp -d)

  while IFS= read -r line; do
    [ -z "$line" ] && continue
    local expected_hash
    local file_path
    expected_hash=$(echo "$line" | awk '{print $1}')
    file_path=$(echo "$line" | awk '{$1=""; print $0}' | sed 's/^ //')

    # Porównaj z lokalnym plikiem
    local local_file="$INSTALL_DIR/$file_path"
    local local_hash=""
    if [ -f "$local_file" ]; then
      if command -v sha256sum &>/dev/null; then
        local_hash=$(sha256sum "$local_file" | awk '{print $1}')
      elif command -v shasum &>/dev/null; then
        local_hash=$(shasum -a 256 "$local_file" | awk '{print $1}')
      fi
    fi

    if [ "$expected_hash" != "$local_hash" ]; then
      # Pobierz tylko zmieniony plik
      log "  ↻ aktualizuję: $file_path"
      mkdir -p "$(dirname "$local_file")"
      curl -sfL "$REPO_BASE/$file_path" -o "$local_file" || warn "  Nie udało się pobrać $file_path"
    fi
  done <<< "$remote_checksums"

  rm -rf "$temp_dir"
  echo "$new_version" > "$INSTALL_DIR/VERSION"
  VERSION="$new_version"
  ok "Zaktualizowano do v$new_version"
}

download_all() {
  local new_version="$1"
  # Lista plików do ściągnięcia
  local files=(
    "setup.sh"
    "config/opencode.jsonc"
    "agents/model-router.md"
    "commands/auto-failover.md"
    "commands/fallback-chain.md"
    "commands/g4f-start.md"
    "commands/status.md"
    "commands/switch-model.md"
    "systemd/g4f.service"
    "scripts/generate-checksums.sh"
    "scripts/bump-version.sh"
  )

  mkdir -p "$INSTALL_DIR"

  for f in "${files[@]}"; do
    local target="$INSTALL_DIR/$f"
    mkdir -p "$(dirname "$target")"
    log "  ↓ pobieram: $f"
    curl -sfL "$REPO_BASE/$f" -o "$target" || warn "Nie udało się pobrać $f"
  done

  echo "$new_version" > "$INSTALL_DIR/VERSION"
  chmod +x "$INSTALL_DIR/setup.sh" "$INSTALL_DIR/scripts/"*.sh 2>/dev/null
  ok "Pobrano wszystkie pliki"
}

#=============================================================================
# INSTALACJA ZALEŻNOŚCI
#=============================================================================
install_deps() {
  log "Sprawdzam zależności..."

  # Node.js
  if command -v node &>/dev/null; then
    ok "Node.js: $(node --version)"
  else
    warn "Node.js nie znaleziony"
    if command -v apt &>/dev/null; then
      log "Instaluję Node.js przez apt..."
      curl -fsSL https://deb.nodesource.com/setup_22.x | bash -
      apt-get install -y nodejs
      ok "Node.js zainstalowany"
    else
      fail "Zainstaluj Node.js ręcznie: https://nodejs.org"
    fi
  fi

  # Python 3
  if command -v python3 &>/dev/null; then
    ok "Python: $(python3 --version)"
  else
    fail "Python3 jest wymagany. Zainstaluj: sudo apt install python3 python3-pip"
  fi

  # pip
  if command -v pip3 &>/dev/null; then
    ok "pip: $(pip3 --version | awk '{print $2}')"
  elif command -v pip &>/dev/null; then
    ok "pip: $(pip --version | awk '{print $2}')"
  else
    fail "pip jest wymagany. Zainstaluj: sudo apt install python3-pip"
  fi

  # git
  if command -v git &>/dev/null; then
    ok "git: $(git --version | awk '{print $3}')"
  else
    warn "git nie znaleziony — instaluję..."
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
    npm install -g @opencode/cli
    ok "opencode CLI zainstalowany"
  fi
}

#=============================================================================
# INSTALACJA G4F (GPT4Free)
#=============================================================================
install_g4f() {
  log "Sprawdzam G4F (GPT4Free)..."

  if python3 -c "import g4f" &>/dev/null 2>&1; then
    ok "G4F: $(python3 -c "import g4f; print(f'v{g4f.__version__}')" 2>/dev/null || echo 'zainstalowany')"
  else
    log "Instaluję G4F przez pip..."
    pip3 install g4f
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

  cp "$INSTALL_DIR/config/opencode.jsonc" "$CONFIG_DIR/opencode.jsonc"
  ok "opencode.jsonc skopiowany"

  cp "$INSTALL_DIR/agents/"*.md "$CONFIG_DIR/agents/" 2>/dev/null
  ok "Agenty skopiowane"

  cp "$INSTALL_DIR/commands/"*.md "$CONFIG_DIR/commands/" 2>/dev/null
  ok "Komendy skopiowane"
}

#=============================================================================
# KONFIGURACJA SYSTEMD (Linux / WSL)
#=============================================================================
setup_systemd() {
  log "Konfiguruję G4F jako serwis systemd..."

  mkdir -p "$SYSTEMD_DIR"
  cp "$INSTALL_DIR/systemd/g4f.service" "$SYSTEMD_DIR/g4f.service"

  # Przeładuj i uruchom
  systemctl --user daemon-reload 2>/dev/null || true

  if systemctl --user is-enabled g4f.service &>/dev/null 2>&1; then
    systemctl --user restart g4f.service 2>/dev/null || true
    ok "G4F service zrestartowany"
  else
    systemctl --user enable --now g4f.service 2>/dev/null || {
      warn "Nie mogę uruchomić systemd service (WSL bez systemd?)"
      warn "Uruchom G4F ręcznie: python3 -c \"from g4f.api import run_api; run_api(port=1337)\""
    }
    ok "G4F service włączony"
  fi
}

#=============================================================================
# TEST G4F
#=============================================================================
test_g4f() {
  log "Testuję G4F endpoint..."
  sleep 3

  if curl -sf -X POST "http://localhost:1337/v1/chat/completions" \
    -H "Content-Type: application/json" \
    -d '{"model":"gpt-4o-mini","messages":[{"role":"user","content":"hi"}],"max_tokens":5}' \
    -o /dev/null -w "%{http_code}" 2>/dev/null | grep -q 200; then
    ok "G4F endpoint działa na http://localhost:1337"
  else
    warn "G4F endpoint nie odpowiada — sprawdź: systemctl --user status g4f.service"
  fi
}

#=============================================================================
# PODSUMOWANIE
#=============================================================================
summary() {
  echo ""
  echo -e "${GREEN}╔══════════════════════════════════════════════════════════╗${NC}"
  echo -e "${GREEN}║           opencode-portable v$VERSION                    ║${NC}"
  echo -e "${GREEN}╚══════════════════════════════════════════════════════════╝${NC}"
  echo ""

  local provider_count=0
  if [ -f "$CONFIG_DIR/opencode.jsonc" ]; then
    provider_count=$(python3 -c "
import json5
with open('$CONFIG_DIR/opencode.jsonc') as f:
    d = json5.load(f)
print(len(d.get('provider', {})))
" 2>/dev/null || echo "?")
  fi

  echo "  ● G4F service: $(systemctl --user is-active g4f.service 2>/dev/null || echo 'nieaktywny')"
  echo "  ● Open code CLI: $(command -v opencode &>/dev/null && echo 'zainstalowany' || echo 'brak')"
  echo "  ● Providerów w configu: $provider_count"
  echo "  ● Katalog: $INSTALL_DIR"
  echo ""
  echo "  Aby zaktualizować:  cd $INSTALL_DIR && ./setup.sh"
  echo "  Aby sprawdzić status: opencode config"
  echo ""
}

#=============================================================================
# MAIN
#=============================================================================
main() {
  echo ""
  echo -e "${CYAN}╔══════════════════════════════════════════════════════════╗${NC}"
  echo -e "${CYAN}║  opencode-portable — Instalator / Aktualizator          ║${NC}"
  echo -e "${CYAN}║  github.com/$REPO_OWNER/$REPO_NAME                        ║${NC}"
  echo -e "${CYAN}╚══════════════════════════════════════════════════════════╝${NC}"
  echo ""

  # Jeśli jesteśmy w katalogu INSTALL_DIR (lokalna instalacja)
  if [ -f "$INSTALL_DIR/VERSION" ]; then
    VERSION=$(cat "$INSTALL_DIR/VERSION")
    auto_update
  else
    # Pierwsza instalacja — pobierz wszystko z repo
    log "Pierwsze uruchomienie — pobieram pliki z GitHub..."
    mkdir -p "$INSTALL_DIR"
    local remote_version
    remote_version=$(curl -sf "$REPO_BASE/VERSION" 2>/dev/null || echo "1.0.0")
    download_all "$remote_version"
  fi

  install_deps
  install_opencode
  install_g4f
  setup_config
  setup_systemd
  test_g4f
  summary

  # Zapisz lokalną wersję
  echo "$VERSION" > "$INSTALL_DIR/VERSION"
}

main "$@"