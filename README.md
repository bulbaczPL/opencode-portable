# opencode-portable

**Zero API keys. 29 providerów. 1 komenda.**

Przenośna konfiguracja [opencode CLI](https://opencode.ai) z keyless agregatorem G4F (1058 modeli), 6 keyless providerami (działają od razu), 23 darmowymi providerami (API key opcjonalnie) i token-free gateway (Claude/ChatGPT przez przeglądarkę).

## Szybki start

```bash
curl -sL https://raw.githubusercontent.com/bulbaczPL/opencode-portable/main/setup.sh | bash
```

Skrypt sam instaluje wszystkie zależności (Python, Node.js, git, G4F, opencode CLI, config).

## Po instalacji

```bash
# Wejdź w interfejs opencode (TUI)
opencode

# G4F uruchomi się automatycznie przez systemd
# Sprawdź czy działa:
curl -X POST http://localhost:1337/v1/chat/completions \
  -H "Content-Type: application/json" \
  -d '{"model":"gpt-4o-mini","messages":[{"role":"user","content":"hi"}],"max_tokens":3}'

# Aktualizacja
cd ~/opencode-portable && bash setup.sh
```

## 29 providerów

### Keyless — działają od razu, bez klucza

| Provider | Modele | Status |
|----------|--------|-------|
| G4F (lokalny) | 1058 modeli, 30+ providerów | ✅ zweryfikowany |
| Pollinations.ai | GPT-OSS 20B | ✅ zweryfikowany |
| ApiAirforce | Grok 4.1, Gemma 3, Step 3.5 Flash | ✅ zweryfikowany |
| OVHcloud | Llama 3.3, Mistral, Qwen 3.6 | ✅ zweryfikowany |
| KeylessAI | GPT-OSS, Grok 4.1 | ⚠️ niestabilny DNS |
| LLM7.io | DeepSeek, GPT-4o mini, Mistral | ⚠️ niestabilny |
| AI Horde | Llama 3.3, Gemma 4 | społecznościowy |

### Z darmowym kluczem (no credit card)

Groq, Cerebras, Mistral, NVIDIA NIM, OpenRouter, Cloudflare Workers, Together AI, SambaNova, Hugging Face, GitHub Models, DeepSeek, Scaleway, Cohere, SiliconFlow, Z.AI, Kilo Code, ModelScope, DashScope, Ollama Cloud, FreeTheAi, Aion Labs, Token-Free Gateway

### Komendy

| Komenda | Opis |
|---------|------|
| `/status` | Status providerów i modeli |
| `/switch-model` | Zmień model ręcznie |
| `/fallback-chain` | Pokaż chain failover |
| `/auto-failover` | Włącz/wyłącz auto-failover |
| `/g4f-start` | Uruchom G4F agregator |

## Wymagania

- Linux / WSL
- Internet (tylko pierwsza instalacja)

Resztę instaluje skrypt.

## Model fallback

Gdy model nie odpowiada, automatycznie przełącza przez 6-tier chain: G4F (lokalny) → Pollinations → ApiAirforce → OVHcloud → openrouter (free) → z darmowym kluczem.

## Licencja

MIT