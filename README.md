# opencode-portable

> **Zero API keys · 29 AI providers · 6 keyless · 1058 models · 1 command**

Portable [opencode CLI](https://opencode.ai) configuration with G4F keyless aggregator, 6 direct keyless providers, 23 free-tier providers (API key optional), 3 agent skills, 8 custom commands, and intelligent model failover.

## Quick start

```bash
curl -sL https://raw.githubusercontent.com/bulbaczPL/opencode-portable/main/setup.sh | bash
```

The script auto-installs Python, Node.js, git, G4F, opencode CLI, and all config. Works on clean systems — only `curl` required.

## 29 providers

### Keyless — works immediately, no key needed

| Provider | Models | Status |
|----------|--------|--------|
| G4F (local) | 1058 models, 30+ providers | ✅ verified |
| Pollinations.ai | GPT-OSS 20B | ✅ verified |
| ApiAirforce | Grok 4.1, Gemma 3, Step 3.5 Flash | ✅ verified |
| OVHcloud | Llama 3.3, Mistral, Qwen 3.6 | ✅ verified |
| KeylessAI | GPT-OSS, Grok 4.1 | ⚠️ Unstable DNS |
| LLM7.io | DeepSeek, GPT-4o mini, Mistral | ⚠️ Unstable |
| AI Horde | Llama 3.3, Gemma 4 | Community |

### Free tier — API key required, no credit card

Groq · Cerebras · Mistral · NVIDIA NIM · OpenRouter · Cloudflare Workers · Together AI · SambaNova · Hugging Face · GitHub Models · DeepSeek · Scaleway · Cohere · SiliconFlow · Z.AI · Kilo Code · ModelScope · DashScope · Ollama Cloud · FreeTheAi · Aion Labs · Token-Free Gateway

## Custom commands

| Command | Description |
|---------|-------------|
| `/status` | Model, G4F, keyless, API keys status |
| `/switch-model` | Switch model (keyless priority) |
| `/g4f-health` | G4F health check, restart, logs |
| `/g4f-start` | Start G4F aggregator |
| `/fallback-chain` | View/test failover chain |
| `/fallback-chain test` | Test all providers in chain |
| `/provider-test` | Test all 29 providers |
| `/provider-register` | Registration guide (23 providers) |
| `/auto-failover` | Toggle auto-failover |

## Agent skills

| Skill | Description |
|-------|-------------|
| `g4f-management` | Start, stop, restart, logs, troubleshooting |
| `keyless-providers` | All 6 keyless providers, rate limits, reliability |
| `provider-registration` | Step-by-step guide for 23 registration processes |

## Subagent

| Agent | Role | Permissions |
|-------|------|-------------|
| `g4f-manager` | G4F lifecycle management | bash: allow, edit: deny |
| `model-router` | Automatic model failover | bash: allow, read: allow |

## Model failover

Automatic 4-tier fallback when a model fails:

```
Keyless (G4F → Pollinations → ApiAirforce → OVHcloud)
  ↓
Free API key (Groq → Cerebras → Mistral → NVIDIA → OpenRouter …)
  ↓
Specialized (Cohere → DashScope → Z.AI → Kilo → SiliconFlow …)
  ↓
Community (AI Horde → FreeTheAi → Aion Labs)
```

---

## Szybki start / Quick start

- **PL:** `curl -sL https://raw.githubusercontent.com/bulbaczPL/opencode-portable/main/setup.sh | bash`
- **EN:** `curl -sL https://raw.githubusercontent.com/bulbaczPL/opencode-portable/main/setup.sh | bash`
- **DE:** `curl -sL https://raw.githubusercontent.com/bulbaczPL/opencode-portable/main/setup.sh | bash`
- **FR:** `curl -sL https://raw.githubusercontent.com/bulbaczPL/opencode-portable/main/setup.sh | bash`
- **ES:** `curl -sL https://raw.githubusercontent.com/bulbaczPL/opencode-portable/main/setup.sh | bash`
- **IT:** `curl -sL https://raw.githubusercontent.com/bulbaczPL/opencode-portable/main/setup.sh | bash`
- **PT:** `curl -sL https://raw.githubusercontent.com/bulbaczPL/opencode-portable/main/setup.sh | bash`
- **RU:** `curl -sL https://raw.githubusercontent.com/bulbaczPL/opencode-portable/main/setup.sh | bash`
- **ZH:** `curl -sL https://raw.githubusercontent.com/bulbaczPL/opencode-portable/main/setup.sh | bash`
- **JA:** `curl -sL https://raw.githubusercontent.com/bulbaczPL/opencode-portable/main/setup.sh | bash`

> One command works in every language.

## Requirements

- Linux / WSL
- Internet (first install only)

Everything else is auto-installed.

## License

MIT