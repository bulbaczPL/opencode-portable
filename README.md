# opencode-portable

Przenośna konfiguracja **opencode** — 29 providerów AI, G4F keyless agregator (1058 modeli), 6-tier fallback chain. Zero API keys.

## Szybki start

```bash
# Opcja 1 (jeśli masz gh)
curl -sL https://raw.githubusercontent.com/DevMike1993/opencode-portable/main/setup.sh | bash

# Opcja 2 (bootstrap przez gist)
bash <(curl -sL https://gist.githubusercontent.com/DevMike1993/49d0824bb8df221172c7901b6a650343/raw/setup.sh)

# Opcja 3 (ręcznie)
git clone https://github.com/DevMike1993/opencode-portable.git
cd opencode-portable && bash setup.sh
```

Jeśli `raw.githubusercontent.com` nie działa (znany problem dla tego konta), użyj opcji 2 lub 3.

## Wymagania

- Linux / WSL na Windows
- Python 3, pip, Node.js, npm
- Git
- GitHub CLI (opcjonalnie, dla auto-pobierania)
- Internet (pierwsza instalacja)

Skrypt sam instaluje brakujące zależności.

## Po instalacji

```bash
# Sprawdź status
opencode config

# Uruchom G4F (jeśli nie startuje automatycznie)
python3 -c "from g4f.api import run_api; run_api(port=1337)"

# Aktualizuj
cd ~/opencode-portable && git pull && bash setup.sh
```

## Komendy

| Komenda | Opis |
|---------|------|
| `/status` | Status providerów i modeli |
| `/switch-model` | Ręczna zmiana modelu |
| `/fallback-chain` | Pokaż chain failover |
| `/auto-failover` | Włącz/wyłącz auto-failover |
| `/g4f-start` | Uruchom G4F agregator |

## Licencja

MIT