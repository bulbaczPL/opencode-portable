# opencode-portable — Zasady dla agenta

Jesteś agentem opencode działającym na konfiguracji **opencode-portable**. Masz dostęp do ~26 providerów AI, w tym 2 keyless (bez klucza API). Poniższe zasady określają jak masz działać.

## 1. Priorytet providerów

Zawsze używaj providerów w tej kolejności:

1. **G4F (lokalny, keyless)** — `g4f/gpt-4o-mini` (domyślny). 12 zweryfikowanych modeli działających bez klucza. Jeśli nie działa, spróbuj go uruchomić przez `/g4f-start` lub `python3 -c "from g4f.api import run_api; run_api(port=1337)"`.
2. **Pollinations.ai (keyless)** — `pollinations/openai` (jedyny działający keyless external provider, rate limit 5 req/min)
3. **OpenRouter free** — `openrouter/*:free`
4. **Darmowe z kluczem** (Groq, Cerebras, Mistral, NVIDIA, itd.)

NOTE: ApiAirforce, Kilo Gateway, OVHcloud, smanxfree były oznaczone jako keyless ale nie działają (401/404/timeout). Nie używaj ich jako fallback.

## 2. G4F — dostępne modele (12 verified, działają bez klucza)

G4F dostarcza 12 modeli które działają natychmiast (żaden klucz nie potrzebny):

| Model | Provider | Uwagi |
|-------|----------|-------|
| `g4f/gpt-4o-mini` | WeWordle | Domyślny, szybki |
| `g4f/gpt-4o` | WeWordle | Pełny GPT-4o |
| `g4f/gpt-4` | WeWordle | Klasyczny GPT-4 |
| `g4f/deepseek-r1` | WeWordle | Reasoning |
| `g4f/o1` | CopilotApp | Reasoning |
| `g4f/o3-mini` | CopilotApp | Reasoning |
| `g4f/command-a` | CohereForAI | 111B param |
| `g4f/command-r` | CohereForAI | |
| `g4f/command-r-plus` | CohereForAI | |
| `g4f/command-r7b` | CohereForAI | |
| `g4f/aria` | OperaAria | |
| `g4f/r1-1776` | Perplexity | |

## 3. G4F — zarządzanie

- G4F działa na `http://localhost:1337/v1`
- Uruchom przez: `systemctl --user start g4f.service` lub `python3 -c "from g4f.api import run_api; run_api(port=1337)"`
- Jeśli G4F nie odpowiada, sprawdź: `curl -X POST http://localhost:1337/v1/chat/completions -H "Content-Type: application/json" -d '{"model":"gpt-4o-mini","messages":[{"role":"user","content":"hi"}],"max_tokens":3}'`
- Jeśli G4F nie chce wystartować, przełącz na Pollinations (jedyny działający keyless external)

## 4. Failover chain

Gdy model nie odpowiada (rate limit, timeout, auth error, pusty response):
1. Zanotuj który provider/model zawiódł
2. Przejdź do następnego w chain: G4F → Pollinations → OpenRouter free → z kluczem
3. Poinformuj użytkownika o przełączeniu
4. Wznów zadanie na nowym modelu

## 5. Komendy dostępne w TUI

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

## 6. Providerzy z kluczem

Jeśli użytkownik chce użyć providera wymagającego klucza:
- Pomóż dodać klucz przez `/connect` w TUI
- Lub edytuj `~/.config/opencode/opencode.jsonc` i dodaj `"apiKey": "${env:NAZWA_ZMIENNEJ}"`
- Providerzy z darmowym kluczem (no credit card): Groq, Cerebras, Mistral, NVIDIA NIM, OpenRouter, Cloudflare, Together AI, SambaNova, Hugging Face, GitHub Models, DeepSeek, Scaleway, Cohere, SiliconFlow, Z.AI, Kilo Code, ModelScope, DashScope, Ollama Cloud, FreeTheAi, Aion Labs

## 7. Konfiguracja

- Główny config: `~/.config/opencode/opencode.jsonc`
- Agenci: `~/.config/opencode/agents/`
- Komendy: `~/.config/opencode/commands/`
- Skille: `~/.config/opencode/skills/`
- Instalator: `~/opencode-portable/setup.sh`
- Aktualizacja: `cd ~/opencode-portable && git pull && bash setup.sh`