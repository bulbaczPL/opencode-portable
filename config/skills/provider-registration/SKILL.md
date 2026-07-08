---
name: provider-registration
description: Step-by-step registration guide for 23 free AI providers with API keys. No credit card required. Use when the user wants to add a key-requiring provider for better quality or higher rate limits.
license: MIT
metadata:
  author: opencode-portable
  version: "1.0"
  category: provider-setup
---

# Provider Registration Guide

## Quick start with keyless

Most users don't need API keys at all. The 6 keyless providers (G4F, Pollinations, ApiAirforce, OVHcloud, KeylessAI, LLM7) work immediately.

For better quality or higher rate limits, register at these free providers:

## Tier 1: Top priority (best models, 30+ RPM free)

### Groq
1. Go to https://console.groq.com
2. Sign up with Google/GitHub/email
3. Go to API Keys section
4. Click "Create API Key"
5. Copy key
6. In opencode TUI: `/connect` → paste key → select Groq
7. Or add to env: `export GROQ_API_KEY=gsk_...`

### Cerebras
1. Go to https://inference.cerebras.ai
2. Sign up
3. Go to API Keys
4. Create key
5. Add via `/connect` or env var

### Mistral AI
1. Go to https://console.mistral.ai
2. Sign up (Google/GitHub)
3. Go to API Keys → Create new key
4. Free: 1B tokens/month, ~2 RPM

### NVIDIA NIM
1. Go to https://build.nvidia.com
2. Sign up
3. Get API key from build.nvidia.com
4. 100+ models, ~40 RPM

### OpenRouter
1. Go to https://openrouter.ai
2. Sign up
3. Go to Keys → Create key
4. ~22 free models via `:free` suffix
5. 200 RPD per model

## Tier 2: Good quality

### GitHub Models
1. Go to https://github.com/marketplace/models
2. Sign in with GitHub
3. Generate key in Settings → Developer settings → Personal access tokens
4. 45+ models including GPT-5, GPT-4.1

### Cloudflare Workers AI
1. Go to https://dash.cloudflare.com
2. Sign up (free plan)
3. Get Account ID from dashboard
4. Create API token: "Workers AI" template
5. Update baseURL in config with your Account ID

### Together AI
1. Go to https://api.together.ai
2. Sign up
3. Go to API Keys → Create
4. 68 free models + $25 credits

### Hugging Face
1. Go to https://huggingface.co/settings/tokens
2. Sign up
3. Create "read" token
4. Thousands of models via Inference Router

### DeepSeek
1. Go to https://platform.deepseek.com
2. Sign up
3. 5M token grant, no credit card

### SambaNova
1. Go to https://cloud.sambanova.ai
2. Sign up
3. 20 RPM, 200K tokens/day + $5 trial

## Tier 3: Specialized

### Cohere
- https://dashboard.cohere.com — 1000 req/month, no CC
### Scaleway
- https://console.scaleway.com — 1M permanent tokens
### SiliconFlow
- https://cloud.siliconflow.cn — permanently free models, no CC
### Z.AI (Zhipu)
- https://open.bigmodel.cn — permanent free models
### Kilo Code
- https://kilo.ai — free models auto-router
### Alibaba DashScope
- https://dashscope.aliyun.com — 1M tokens per model
### ModelScope
- https://modelscope.cn — 2000 req/day
### Ollama Cloud
- https://ollama.com/settings/keys — free tier
### FreeTheAi
- https://freetheai.xyz — key via Discord
### Aion Labs
- https://www.aionlabs.ai — 15 RPM, 20K tokens/day, specialized for storytelling

## Adding a key to opencode

```bash
# Option 1: Via TUI
# Type /connect → select provider → paste key

# Option 2: Via environment variable
export GROQ_API_KEY="gsk_your_key_here"
# Then edit opencode.jsonc to add for that provider:
# "options": { "apiKey": "${env:GROQ_API_KEY}" }

# Option 3: Directly in config file
# ~/.config/opencode/opencode.jsonc
# Add to the provider section:
# "groq": {
#   "apiKey": "gsk_your_key_here",
#   ...
# }
```