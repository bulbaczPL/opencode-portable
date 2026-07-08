#!/usr/bin/env bash
#=============================================================================
# opencode-portable — self-installing, self-updating opencode config
# Repo: https://github.com/DevMike1993/opencode-portable
#
# One-liner:
#   curl -sL https://gh.io/opencode-portable | bash
#   # or
#   curl -sL https://tinyurl.com/opencode-portable | bash
#
# After install:
#   ~/opencode-portable/setup.sh
#=============================================================================
set -euo pipefail

REPO="DevMike1993/opencode-portable"
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
# Pobieranie plików z GitHub (przez gh lub curl z tokenem)
#=============================================================================
gh_get() {
  local path="$1"
  local out="$2"

  # Priorytet 1: gh
  if command -v gh &>/dev/null && gh auth status -h github.com &>/dev/null 2>&1; then
    local content
    content=$(gh api "repos/$REPO/contents/$path" --jq '.content' 2>/dev/null || true)
    if [ -n "$content" ]; then
      echo "$content" | base64 -d > "$out"
      return 0
    fi
  fi

  # Priorytet 2: GITHUB_TOKEN
  if [ -n "${GITHUB_TOKEN:-}" ]; then
    curl -sfL -H "Authorization: Bearer $GITHUB_TOKEN" \
      "https://api.github.com/repos/$REPO/contents/$path" 2>/dev/null \
      | python3 -c "
import sys, json, base64
d = json.load(sys.stdin)
c = base64.b64decode(d['content']).decode()
with open('$out', 'w') as f:
    f.write(c)
" 2>/dev/null && return 0
  fi

  # Priorytet 3: git clone (działa w większości przypadków)
  local tmpdir
  tmpdir=$(mktemp -d)
  if GIT_TERMINAL_PROMPT=0 git clone --depth 1 "$REPO_URL" "$tmpdir" 2>/dev/null; then
    if [ -f "$tmpdir/$path" ]; then
      cp "$tmpdir/$path" "$out"
      rm -rf "$tmpdir"
      return 0
    fi
  fi
  rm -rf "$tmpdir"

  return 1
}

get_file() {
  local path="$1"
  local out="$2"
  mkdir -p "$(dirname "$out")"

  if get_gh "$path" "$out"; then
    return 0
  fi

  return 1
}

#=============================================================================
# AUTO-UPDATE
#=============================================================================
do_update() {
  log "Sprawdzam aktualizacje..."

  if [ -d "$INSTALL_DIR/.git" ]; then
    cd "$INSTALL_DIR"
    local old_hash
    old_hash=$(git rev-parse HEAD 2>/dev/null || echo "")

    git fetch origin main 2>&1 | grep -v "Already up to date" | grep -v "From" | grep -v "^$" || true
    local new_hash
    new_hash=$(git rev-parse origin/main 2>/dev/null || echo "")

    if [ -n "$old_hash" ] && [ "$old_hash" != "$new_hash" ] && [ -n "$new_hash" ]; then
      echo -n "  Nowa wersja dostępna. Aktualizować? [Y/n] "
      read -r answer
      if [ "$answer" != "n" ] && [ "$answer" != "N" ]; then
        git pull origin main 2>&1 | tail -1
        ok "Zaktualizowano"
      else
        warn "Pomijam"
      fi
    else
      ok "Masz najnowszą wersję"
    fi
    cd - > /dev/null
  else
    # Pierwszy raz: sklonuj
    log "Pobieram pliki z GitHub..."

    if command -v gh &>/dev/null && gh auth status &>/dev/null 2>&1; then
      # Użyj gh do klonowania (działa z tokenem)
      gh repo clone "$REPO" "$INSTALL_DIR" 2>&1 | tail -1
    elif [ -n "${GITHUB_TOKEN:-}" ]; then
      # Użyj git z tokenem w URL
      GIT_TERMINAL_PROMPT=0 git clone --depth 1 "https://DevMike1993:${GITHUB_TOKEN}@github.com/$REPO.git" "$INSTALL_DIR" 2>&1 | tail -1
    else
      # Spróbuj bez auth
      if GIT_TERMINAL_PROMPT=0 git clone --depth 1 "$REPO_URL" "$INSTALL_DIR" 2>/dev/null; then
        :
      else
        fail "GitHub nie pozwala na anonimowy dostęp dla tego konta."
        fail "Zainstaluj GitHub CLI i zaloguj się:"
        fail "  sudo apt install gh && gh auth login"
        fail "Po zalogowaniu uruchom setup.sh ponownie."
        exit 1
      fi
    fi
    ok "Pobrano pliki"
  fi
}

#=============================================================================
# INSTALACJA GH
#=============================================================================
install_gh() {
  if command -v gh &>/dev/null; then
    if gh auth status &>/dev/null 2>&1; then
      ok "gh: $(gh --version | head -1 | awk '{print $3}')"
      return 0
    else
      warn "gh nie zalogowane. Uruchom: gh auth login"
    fi
  fi

  log "Instaluję GitHub CLI..."
  if command -v apt &>/dev/null; then
    curl -fsSL https://cli.github.com/packages/githubcli-archive-keyring.gpg | dd of=/usr/share/keyrings/githubcli-archive-keyring.gpg 2>/dev/null || true
    echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/githubcli-archive-keyring.gpg] https://cli.github.com/packages stable main" | tee /etc/apt/sources.list.d/github-cli.list > /dev/null
    apt-get update -qq && apt-get install -y -qq gh 2>/dev/null | tail -1
    ok "gh zainstalowany"
    log "Zaloguj się:  gh auth login"
    log "Potem uruchom setup.sh ponownie"
  else
    warn "Zainstaluj gh ręcznie: https://cli.github.com"
  fi
}

#=============================================================================
# INSTALACJA ZALEŻNOŚCI
#=============================================================================
install_deps() {
  log "Sprawdzam zależności..."

  if command -v python3 &>/dev/null; then
    ok "Python: $(python3 --version)"
  else
    fail "Python3 wymagany"
    return 1
  fi

  if command -v pip3 &>/dev/null || command -v pip &>/dev/null; then
    ok "pip: $([ -x "$(command -v pip3)" ] && pip3 --version | awk '{print $2}' || pip --version | awk '{print $2}')"
  else
    fail "pip wymagany"
    return 1
  fi

  if command -v node &>/dev/null; then
    ok "Node.js: $(node --version)"
  else
    log "Instaluję Node.js..."
    curl -fsSL https://deb.nodesource.com/setup_22.x | bash - &>/dev/null
    apt-get install -y nodejs &>/dev/null
    ok "Node.js zainstalowany"
  fi

  if command -v npm &>/dev/null; then
    ok "npm: $(npm --version)"
  fi

  if command -v git &>/dev/null; then
    ok "git: $(git --version | awk '{print $3}')"
  else
    apt-get install -y git &>/dev/null
    ok "git zainstalowany"
  fi
}

#=============================================================================
# INSTALACJA OPENCODE CLI
#=============================================================================
install_opencode() {
  log "Sprawdzam opencode CLI..."
  if command -v opencode &>/dev/null; then
    ok "opcode: $(opencode --version 2>/dev/null || echo 'zainstalowany')"
  else
    log "Instaluję opencode..."
    npm install -g @opencode/cli 2>&1 | tail -1
    ok "opencode CLI zainstalowany"
  fi
}

#=============================================================================
# INSTALACJA G4F
#=============================================================================
install_g4f() {
  log "Sprawdzam G4F..."
  if python3 -c "import g4f" &>/dev/null 2>&1; then
    ok "G4F: $(python3 -c "import g4f; print(f'v{g4f.__version__}')" 2>/dev/null || echo 'zainstalowany')"
  else
    log "Instaluję G4F..."
    pip3 install g4f 2>&1 | tail -1
    ok "G4F zainstalowany"
  fi
}

#=============================================================================
# KONFIGURACJA
#=============================================================================
setup_config() {
  log "Konfiguruję opencode..."

  mkdir -p "$CONFIG_DIR" "$CONFIG_DIR/agents" "$CONFIG_DIR/commands"

  if [ -f "$INSTALL_DIR/config/opencode.jsonc" ]; then
    cp "$INSTALL_DIR/config/opencode.jsonc" "$CONFIG_DIR/opencode.jsonc"
    ok "opencode.jsonc skopiowany"
  fi
  if ls "$INSTALL_DIR/agents/"*.md &>/dev/null; then
    cp "$INSTALL_DIR/agents/"*.md "$CONFIG_DIR/agents/" 2>/dev/null
    ok "Agenty: $(ls "$INSTALL_DIR/agents/"*.md 2>/dev/null | wc -l) plików"
  fi
  if ls "$INSTALL_DIR/commands/"*.md &>/dev/null; then
    cp "$INSTALL_DIR/commands/"*.md "$CONFIG_DIR/commands/" 2>/dev/null
    ok "Komendy: $(ls "$INSTALL_DIR/commands/"*.md 2>/dev/null | wc -l) plików"
  fi
}

setup_systemd() {
  log "Konfiguruję G4F service..."

  if [ ! -f "$INSTALL_DIR/systemd/g4f.service" ]; then
    warn "Brak g4f.service"
    return
  fi

  mkdir -p "$SYSTEMD_DIR"
  cp "$INSTALL_DIR/systemd/g4f.service" "$SYSTEMD_DIR/g4f.service"

  systemctl --user daemon-reload 2>/dev/null || {
    warn "systemd nie dostępny. Uruchom G4F ręcznie:"
    warn "  python3 -c \"from g4f.api import run_api; run_api(port=1337)\""
    return
  }

  systemctl --user enable --now g4f.service 2>/dev/null && ok "G4F service uruchomiony" || warn "G4F service: restart"
}

test_g4f() {
  sleep 3
  if curl -sf -o /dev/null -w "%{http_code}" -X POST \
    "http://localhost:1337/v1/chat/completions" \
    -H "Content-Type: application/json" \
    -d '{"model":"gpt-4o-mini","messages":[{"role":"user","content":"hi"}],"max_tokens":3}' 2>/dev/null | grep -q 200; then
    ok "G4F działa na http://localhost:1337"
  else
    warn "G4F nie odpowiada (port 1337)"
  fi
}

summary() {
  local pc=0
  if [ -f "$CONFIG_DIR/opencode.jsonc" ] && command -v python3 &>/dev/null; then
    pc=$(python3 -c "import json5; f=open('$CONFIG_DIR/opencode.jsonc'); d=json5.load(f); print(len(d.get('provider',{})))" 2>/dev/null || echo "?")
  fi
  local v=$(cat "$INSTALL_DIR/VERSION" 2>/dev/null || echo "?")
  echo ""
  echo -e "${GREEN}╔══════════════════════════════════════════════════════╗${NC}"
  echo -e "${GREEN}║  opencode-portable v$v                                ║${NC}"
  echo -e "${GREEN}╚══════════════════════════════════════════════════════╝${NC}"
  echo "  ● G4F:   $(systemctl --user is-active g4f.service 2>/dev/null || echo 'ręcznie')"
  echo "  ● opencode: $(command -v opencode &>/dev/null && echo 'OK' || echo 'brak')"
  echo "  ● Providerów: $pc"
  echo "  ● Katalog: $INSTALL_DIR"
  echo ""
  echo "  Aktualizacja: cd $INSTALL_DIR && ./setup.sh"
  echo "  (lub: curl -sL https://tinyurl.com/opencode-portable | bash)"
  echo ""
}

#=============================================================================
# MAIN
#=============================================================================
main() {
  echo ""
  echo -e "${CYAN}╔══════════════════════════════════════════════════════╗${NC}"
  echo -e "${CYAN}║  opencode-portable — Instalator / Aktualizator      ║${NC}"
  echo -e "${CYAN}╚══════════════════════════════════════════════════════╝${NC}"
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