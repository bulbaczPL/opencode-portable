# opencode-portable

Przenośna konfiguracja **opencode** z 29 providerami AI i keyless agregatorem G4F (1058 modeli, zero API keys).

## Szybki start

```bash
curl -L https://raw.githubusercontent.com/DevMike1993/opencode-portable/main/setup.sh | bash
```

Skrypt automatycznie:
- Sprawdza aktualizacje i pobiera tylko zmienione pliki
- Instaluje opencode CLI, G4F, Node.js, Python (jeśli brak)
- Kopiuje config (29 providerów, 6-tier fallback chain)
- Uruchamia G4F jako serwis systemd na porcie 1337
- Testuje czy endpoint działa

## Użycie

```bash
# Instalacja na nowym urządzeniu
curl -L https://raw.githubusercontent.com/DevMike1993/opencode-portable/main/setup.sh | bash

# Aktualizacja na istniejącym
cd ~/opencode-portable && ./setup.sh

# Sprawdź status
opencode config
```

## Struktura

```
opencode-portable/
├── setup.sh                  # Instalator + auto-updater
├── VERSION                   # Numer wersji
├── checksums.txt             # SHA256 plików do auto-update
├── config/
│   └── opencode.jsonc        # 29 providerów, 171+ modeli
├── agents/
│   └── model-router.md       # 6-tier fallback chain
├── commands/                 # Custom komendy (/status, /switch-model, itd.)
├── systemd/
│   └── g4f.service           # G4F jako serwis systemd
└── scripts/
    ├── generate-checksums.sh # Regeneracja checksums.txt
    └── bump-version.sh       # Podbicie wersji
```

## Auto-update

Skrypt przy każdym uruchomieniu:
1. Pobiera `VERSION` z GitHub
2. Porównuje z lokalną wersją
3. Jeśli nowsza → pobiera `checksums.txt` i diffuje
4. Pobiera tylko zmienione pliki
5. Pyta przed aktualizacją

## Wymagania

- Linux / WSL na Windows
- Internet (do pierwszej instalacji)
- curl, bash

Skrypt sam instaluje brakujące zależności (Node.js, Python, pip, git).

## Licencja

MIT