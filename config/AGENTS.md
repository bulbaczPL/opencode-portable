# opencode-portable — Zasady dla agenta

Jesteś agentem opencode działającym na konfiguracji **opencode-portable**. Masz dostęp do ~26 providerów AI, w tym 4 keyless (bez klucza API). Poniższe zasady określają jak masz działać.

## 1. Priorytet providerów

Zawsze używaj providerów w tej kolejności:

1. **G4F (lokalny, keyless)** — `g4f/gpt-4o-mini` (domyślny). Jeśli nie działa, spróbuj go uruchomić przez `/g4f-start` lub `python3 -c "from g4f.api import run_api; run_api(port=1337)"`.
2. **Pollinations.ai (keyless)** — `pollinations/openai`
3. **Kilo Gateway (keyless)** — `kilo/kilo-auto/free`
4. **OVHcloud (keyless)** — `ovhcloud/Mistral-7B-Instruct-v0.3` (2 RPM bez klucza)
5. **OpenRouter free** — `openrouter/*:free`
6. **Darmowe z kluczem** (Groq, Cerebras, Mistral, NVIDIA, itd.)

## 2. G4F — zarządzanie

- G4F działa na `http://localhost:1337/v1`
- Uruchom przez: `systemctl --user start g4f.service` lub `python3 -c "from g4f.api import run_api; run_api(port=1337)"`
- Jeśli G4F nie odpowiada, sprawdź: `curl -X POST http://localhost:1337/v1/chat/completions -H "Content-Type: application/json" -d '{"model":"gpt-4o-mini","messages":[{"role":"user","content":"hi"}],"max_tokens":3}'`
- Jeśli G4F nie chce wystartować, przełącz na keyless providerów bezpośrednich (Pollinations, Kilo, OVHcloud)

## 3. Failover chain

Gdy model nie odpowiada (rate limit, timeout, auth error, pusty response):
1. Zanotuj który provider/model zawiódł
2. Przejdź do następnego w chain: G4F → Pollinations → Kilo → OVHcloud → OpenRouter free → z kluczem
3. Poinformuj użytkownika o przełączeniu
4. Wznów zadanie na nowym modelu

## 4. Komendy dostępne w TUI

| Komenda | Opis |
|---------|------|
| `/status` | Pokaż aktualny model, status providerów, statystyki |
| `/switch-model <nr\|nazwa>` | Przełącz na konkretny model z chain |
| `/fallback-chain` | Pokaż/konfiguruj chain failover |
| `/fallback-chain test` | Przetestuj wszystkie modele w chain |
| `/auto-failover on\|off` | Włącz/wyłącz auto-failover |
| `/g4f-start` | Uruchom G4F agregator |
| `/g4f-health` | Sprawdź status G4F, restart, logi |
| `/provider-test` | Przetestuj wszystkich 29 providerów |
| `/provider-register` | Przewodnik rejestracji do darmowych providerów |

## 5. Providerzy z kluczem

Jeśli użytkownik chce użyć providera wymagającego klucza:
- Pomóż dodać klucz przez `/connect` w TUI
- Lub edytuj `~/.config/opencode/opencode.jsonc` i dodaj `"apiKey": "${env:NAZWA_ZMIENNEJ}"`
- Providerzy z darmowym kluczem (no credit card): Groq, Cerebras, Mistral, NVIDIA NIM, OpenRouter, Cloudflare, Together AI, SambaNova, Hugging Face, GitHub Models, DeepSeek, Scaleway, Cohere, SiliconFlow, Z.AI, Kilo Code, ModelScope, DashScope, Ollama Cloud, FreeTheAi, Aion Labs

## 6. Konfiguracja

- Główny config: `~/.config/opencode/opencode.jsonc`
- Agenci: `~/.config/opencode/agents/`
- Komendy: `~/.config/opencode/commands/`
- Skille: `~/.config/opencode/skills/`
- Instalator: `~/opencode-portable/setup.sh`
- Aktualizacja: `cd ~/opencode-portable && git pull && bash setup.sh`