<p align="center">
  <picture>
    <source media="(prefers-color-scheme: dark)" srcset="https://img.shields.io/badge/opencode--portable-000?style=for-the-badge&logo=openai&logoColor=white">
    <img alt="opencode-portable" src="https://img.shields.io/badge/opencode--portable-0a6?style=for-the-badge&logo=openai&logoColor=white" width="320">
  </picture>
</p>

<p align="center">
  <b>Portable AI configuration for <a href="https://opencode.ai">opencode CLI</a><br>
  Zero API keys &middot; 18 verified models &middot; 27 providers &middot; 1 command</b>
</p>

<p align="center">
  <a href="#polski"><img src="https://img.shields.io/badge/🇵🇱-Polski-gray?style=flat-square" alt="polski"></a>
  <a href="#deutsch"><img src="https://img.shields.io/badge/🇩🇪-Deutsch-gray?style=flat-square" alt="deutsch"></a>
  <a href="#francais"><img src="https://img.shields.io/badge/🇫🇷-Français-gray?style=flat-square" alt="français"></a>
  <a href="#espanol"><img src="https://img.shields.io/badge/🇪🇸-Español-gray?style=flat-square" alt="español"></a>
  <a href="#italiano"><img src="https://img.shields.io/badge/🇮🇹-Italiano-gray?style=flat-square" alt="italiano"></a>
  <a href="#portugues"><img src="https://img.shields.io/badge/🇵🇹-Português-gray?style=flat-square" alt="português"></a>
  <a href="#russkiy"><img src="https://img.shields.io/badge/🇷🇺-Русский-gray?style=flat-square" alt="русский"></a>
  <a href="#zhongwen"><img src="https://img.shields.io/badge/🇨🇳-中文-gray?style=flat-square" alt="中文"></a>
  <a href="#nihongo"><img src="https://img.shields.io/badge/🇯🇵-日本語-gray?style=flat-square" alt="日本語"></a>
</p>

<p align="center">
  <a href="https://github.com/bulbaczPL/opencode-portable/blob/main/LICENSE"><img src="https://img.shields.io/badge/license-MIT-green?style=for-the-badge" alt="MIT License"></a>
  <a href="https://github.com/bulbaczPL/opencode-portable"><img src="https://img.shields.io/github/stars/bulbaczPL/opencode-portable?style=for-the-badge&logo=github&color=black" alt="GitHub stars"></a>
  <a href="https://raw.githubusercontent.com/bulbaczPL/opencode-portable/main/setup.sh"><img src="https://img.shields.io/badge/install-curl|bash-blue?style=for-the-badge&logo=linux&logoColor=white" alt="curl | bash"></a>
  <a href="https://github.com/xtekky/gpt4free"><img src="https://img.shields.io/badge/powered_by-G4F 7.7.2-purple?style=for-the-badge&logo=python&logoColor=white" alt="G4F"></a>
  <a href="https://github.com/bulbaczPL/opencode-portable/pulls"><img src="https://img.shields.io/badge/PRs-welcome-brightgreen?style=for-the-badge&logo=git&logoColor=white" alt="PRs welcome"></a>
</p>

<p align="center">
  <a href="https://opencode.ai"><code>opencode</code></a> ·
  <a href="#quick-start">Quick Start</a> ·
  <a href="#features">Features</a> ·
  <a href="#keyless-models">Keyless Models</a> ·
  <a href="#all-providers">All Providers</a> ·
  <a href="#custom-commands">Commands</a> ·
  <a href="#agent-skills">Skills</a> ·
  <a href="#model-failover">Failover</a> ·
  <a href="#faq">FAQ</a>
</p>

---

<details>
<summary><b>📑 Table of Contents</b></summary>

1. [Quick Start](#quick-start)
2. [Features](#features)
3. [Keyless Models](#keyless-models)
4. [All Providers](#all-providers)
5. [Custom Commands](#custom-commands)
6. [Agent Skills](#agent-skills)
7. [Model Failover](#model-failover)
8. [FAQ](#faq)
9. [Contributing](#contributing)
10. [License](#license)

</details>

---

## Quick Start

```bash
curl -sL https://raw.githubusercontent.com/bulbaczPL/opencode-portable/main/setup.sh | bash
```

Then run:

```bash
opencode
```

**Requirements:** Linux or WSL, internet connection (first install only). Everything else auto-installs.

> [!TIP]
> Run `opencode` directly after install — the default model `gpt-4o-mini` works immediately via local G4F. No API keys needed.

---

## Features

<table>
<tr>
<td>

- **🔑 Zero API keys required** — 18 models work immediately via G4F + Pollinations
- **🧠 18 verified text models** — each tested live via curl, no guesswork
- **🌐 27 AI providers** — keyless + free-tier with API key
- **⚡ Auto failover** — transparent fallback when a model hits rate limits
- **🐳 Docker-ready** — G4F runs in a container, no dependency hell
</td>
<td>

- **🔧 8 custom commands** — `/status`, `/switch-model`, `/g4f-health`, more
- **🧩 3 agent skills** — G4F management, keyless providers, registration guides
- **📦 Single install** — `curl | bash`, auto-installs everything
- **🎯 OpenCode-native** — designed for opencode CLI, uses native config format
- **🔌 OpenAI-compatible** — works with any tool that speaks OpenAI API
</td>
</tr>
</table>

---

## Keyless Models

These models work **right now, with zero configuration, no API key**.

| Provider | Models | Tested | Notes |
|----------|--------|--------|-------|
| **G4F** (local, Docker) | `gpt-4o-mini` `gpt-4o` `gpt-4` `o3-mini` `deepseek-r1` `deepseek` `deepseek-coder` `command-a` `command-a-03-2025` `command-r7b` `command-r` `command-r-plus` `gpt-5-thinking` `r1-1776` `reasoning` `perplexity` `pplx_pro` `aria` | ✅ live curl test | 18 text models — requires G4F running on `localhost:1337` |
| **Pollinations.ai** | `GPT-OSS 20B` (tool-capable, reasoning) | ✅ live curl test | 1 concurrent request per IP — [text.pollinations.ai](https://text.pollinations.ai) |

> [!WARNING]
> The following providers were previously listed as keyless but are currently broken (verified July 2026):
> - **Kilo Gateway** — connection timeout
> - **OVHcloud AI Endpoints** — HTTP 404
> - **ApiAirforce** — requires auth (401)
> - **KeylessAI** — Cloudflare 1042 error
> - **LLM7.io** — HTTP 405
> - **AI Horde** — dead endpoint

**How to start G4F:**

```bash
# Option A: Docker (recommended)
docker run -d --name g4f --rm -p 1337:1337 python:3.12-slim sh -c \
  "pip install -q g4f==7.7.2 nest-asyncio2 && \
   python3 -c 'from g4f.api import run_api; run_api(port=1337, host=\"0.0.0.0\")'"

# Option B: Direct Python
python3 -c "from g4f.api import run_api; run_api(port=1337)"
```

---

## All Providers

### Legend

| Color | Meaning |
|-------|---------|
| 🟢 | Keyless — no API key needed |
| 🟡 | Free tier — API key required, no credit card |
| 🔴 | Broken — kept for reference |

### Provider table

| Provider | Tier | Models | Key needed |
|----------|------|--------|------------|
| **G4F** (local) | 🟢 | 18 verified text models | — |
| **Pollinations.ai** | 🟢 | GPT-OSS 20B | — |
| **Groq** | 🟡 | Llama 3.3, Gemma 2, Mixtral, DeepSeek-R1-distill | Free key |
| **Cerebras** | 🟡 | Llama, Qwen (fastest inference) | Free key |
| **Mistral** | 🟡 | Mistral Small, Codestral | Free key |
| **NVIDIA NIM** | 🟡 | 100+ models, Nemotron 3, Llama | Free key |
| **OpenRouter** | 🟡 | ~22 free models (`:free` suffix) | Free key |
| **Cloudflare Workers AI** | 🟡 | 50+ models, Kimi K2.6, Llama, GPT-OSS | Free key |
| **Together AI** | 🟡 | Llama 3.3, Qwen, Gemma 4, GPT-OSS | Free key |
| **SambaNova** | 🟡 | DeepSeek V3.1, Llama 3.3, GPT-OSS | Free key |
| **Hugging Face** | 🟡 | DeepSeek V3, Llama 3.3, Phi-3.5 | Free key |
| **GitHub Models** | 🟡 | GPT-5, GPT-4.1, o4-mini, Llama 4 | Free key |
| **DeepSeek** | 🟡 | DeepSeek V4 Flash, V4 Pro | Free key |
| **Scaleway** | 🟡 | Llama 3.3, Qwen Coder, Mistral, DeepSeek R1 | Free key |
| **Cohere** | 🟡 | Command A+, Command A, Command R+ | Free trial |
| **SiliconFlow** | 🟡 | Qwen 3 8B, DeepSeek R1 Distill | Free key |
| **Z.AI (Zhipu)** | 🟡 | GLM 4.7 Flash, GLM 4.6V Flash | Free key |
| **ModelScope** | 🟡 | Qwen 3.5 35B, Qwen 3.5 27B | Free key |
| **DashScope** | 🟡 | Qwen 3.6 27B, Qwen 2.5 Coder 32B | Free key |
| **Ollama Cloud** | 🟡 | GPT-OSS 120B, DeepSeek V3.1, Qwen3 Coder | Free key |
| **FreeTheAi** | 🟡 | GPT-OSS 20B, Llama 3.3, Qwen3 Coder | Discord key |
| **Aion Labs** | 🟡 | Aion 2.5, Aion-RP 1.0 | Free key |
| **Token-Free Gateway** | 🟡 | Claude, ChatGPT, Gemini, DeepSeek, Grok | Browser login |
| **Kilo Gateway** | 🔴 | — | — |
| **OVHcloud** | 🔴 | — | — |
| **ApiAirforce** | 🔴 | — | — |
| **smanx-free** | 🔴 | — | — |

---

## Custom Commands

Available in opencode TUI. Type `/help` to see all commands.

| Command | Description |
|---------|-------------|
| `/status` | Show current model, provider status, API key status |
| `/switch-model <nr\|name>` | Switch to a specific model or provider |
| `/g4f-start` | Start G4F aggregator (auto-detect Docker or Python) |
| `/g4f-health` | G4F health check, restart, view logs |
| `/fallback-chain` | View or configure the failover chain |
| `/fallback-chain test` | Test all providers in the chain |
| `/provider-test` | Test all 27 providers |
| `/provider-register` | Step-by-step guide for free-tier provider registration |
| `/auto-failover on\|off` | Toggle auto-failover |

---

## Agent Skills

Skills are automatically available in opencode. They provide specialized know-how for agent operations.

| Skill | Description |
|-------|-------------|
| `g4f-management` | Start, stop, restart, troubleshoot G4F aggregator |
| `keyless-providers` | Rate limits, reliability data for all keyless providers |
| `provider-registration` | Step-by-step registration guides for all free-tier providers |

---

## Model Failover

When the current model fails (rate limit, timeout, auth error), opencode-portable automatically falls through this chain:

```
Keyless (G4F → Pollinations)
  ↓
OpenRouter free
  ↓
Free-tier API keys (Groq → Cerebras → Mistral → NVIDIA → …)
  ↓
Specialized (Cohere → SiliconFlow → Z.AI → …)
```

The router tries each provider in order. On success it stops; on failure it moves to the next. Configure via `/fallback-chain` in TUI.

---

## FAQ

### Why only 2 keyless providers?

We tested over 20 claimed "keyless" endpoints from Reddit, GitHub, and Discord. Only **G4F** and **Pollinations.ai** returned valid responses without any form of authentication. The rest required API keys, returned empty responses, or were dead.

### Can I still use the broken providers?

They remain in the config for reference. If their endpoints change, open them. Do not rely on them.

### Which G4F models were tested and failed?

Of the 24 originally listed G4F models, only 6 passed live testing. The remaining 18 passed — the others (claude-*, gemini-*, llama-*, grok-3, qwen-2.5-coder-32b, etc.) all returned HTTP 500/401/404 or empty responses.

### How do I add API keys?

In opencode TUI, run `/connect`. Or manually add to `~/.config/opencode/opencode.jsonc`:

```json
"providers": {
  "groq": {
    "id": "@ai-sdk/openai-compatible",
    "apiKey": "${env:GROQ_API_KEY}",
    "options": {
      "baseURL": "https://api.groq.com/openai/v1"
    }
  }
}
```

Each provider's key signup page is listed in the [All Providers](#all-providers) table.

### Does this work on macOS or Windows?

Linux and WSL only. You can run opencode-portable in Docker on any platform.

---

## Contributing

Contributions are welcome! Found a working keyless endpoint? Opened an issue or PR. Found a broken model? Same.

- [Open an issue](https://github.com/bulbaczPL/opencode-portable/issues)
- [Submit a PR](https://github.com/bulbaczPL/opencode-portable/pulls)

---

## License

[MIT](LICENSE) © 2026 bulbaczPL

---

<p align="center">
  <a href="#"><img src="https://img.shields.io/badge/⬆_back_to_top-gray?style=flat-square" alt="back to top"></a>
</p>

---

<a id="polski"></a><details><summary>🇵🇱 Polski — przeczytaj ten dokument po polsku</summary>

[Otwórz README.pl.md](README.pl.md)

</details>

<a id="deutsch"></a><details><summary>🇩🇪 Deutsch — dieses Dokument auf Deutsch lesen</summary>

[README.de.md öffnen](README.de.md)

</details>

<a id="francais"></a><details><summary>🇫🇷 Français — lire ce document en français</summary>

[Ouvrir README.fr.md](README.fr.md)

</details>

<a id="espanol"></a><details><summary>🇪🇸 Español — leer este documento en español</summary>

[Abrir README.es.md](README.es.md)

</details>

<a id="italiano"></a><details><summary>🇮🇹 Italiano — leggere questo documento in italiano</summary>

[Apri README.it.md](README.it.md)

</details>

<a id="portugues"></a><details><summary>🇵🇹 Português — ler este documento em português</summary>

[Abrir README.pt.md](README.pt.md)

</details>

<a id="russkiy"></a><details><summary>🇷🇺 Русский — прочитать этот документ на русском</summary>

[Открыть README.ru.md](README.ru.md)

</details>

<a id="zhongwen"></a><details><summary>🇨🇳 中文 — 阅读此文档的中文版本</summary>

[打开 README.zh.md](README.zh.md)

</details>

<a id="nihongo"></a><details><summary>🇯🇵 日本語 — 日本語でこのドキュメントを読む</summary>

[README.ja.md を開く](README.ja.md)

</details>