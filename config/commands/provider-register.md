---
description: Interactive guide to register for free API keys. Usage: /provider-register <provider-name>
agent: build
subtask: true
---

Provide step-by-step registration instructions for the specified provider.

## Usage

- `/provider-register groq` — Groq registration guide
- `/provider-register cerebras` — Cerebras guide
- `/provider-register mistral` — Mistral AI guide
- `/provider-register nvidia` — NVIDIA NIM guide
- `/provider-register openrouter` — OpenRouter guide
- `/provider-register github` — GitHub Models guide
- `/provider-register deepseek` — DeepSeek guide
- `/provider-register all` — show all providers summary

## How it works

Load the `provider-registration` skill to get full instructions, then present them to the user.

If the user specifies a provider:
1. Load `skill({ name: "provider-registration" })`
2. Extract the relevant section for that provider
3. Present: signup link, steps, what the free tier includes
4. Ask if user wants help adding the key through `/connect`

If no provider specified:
1. Show available providers grouped by tier
2. List keyless providers that work immediately (no registration needed)
3. Ask which provider they want to register for