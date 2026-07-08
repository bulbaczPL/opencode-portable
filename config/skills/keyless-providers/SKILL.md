---
name: keyless-providers
description: Reference for all 6 direct keyless AI providers — Pollinations, ApiAirforce, OVHcloud, KeylessAI, LLM7, AI Horde. Rate limits, working models, reliability status. Use when G4F is down or user needs backup provider info.
license: MIT
metadata:
  author: opencode-portable
  version: "1.0"
  category: provider-reference
---

# Keyless AI Providers

These providers work **without any API key**. Open them directly in opencode via `provider/model` syntax.

## 1. Pollinations.ai — VERIFIED WORKS ✅

| Property | Value |
|----------|-------|
| Provider name | `pollinations` |
| Model | `openai` |
| baseURL | `https://text.pollinations.ai/openai` |
| Rate limit | 1 concurrent request per IP |
| Reliability | High |
| Usage | `pollinations/openai` |

## 2. ApiAirforce — VERIFIED WORKS ✅

| Property | Value |
|----------|-------|
| Provider name | `apiairforce` |
| Models | `openai`, `grok-4.1-mini`, `step-3.5-flash`, `gemma3-270m`, `moirai-agent`, `translategemma-27b` |
| baseURL | `https://api.airforce/v1` |
| Rate limit | 1 req/s |
| Status | High |

## 3. OVHcloud AI Endpoints — VERIFIED WORKS ✅

| Property | Value |
|----------|-------|
| Provider name | `ovhcloud` |
| Models | `Mistral-7B-Instruct-v0.3`, `Meta-Llama-3_3-70B-Instruct`, `Qwen3.6-27B`, `Qwen3-Coder-30B-A3B-Instruct`, `Mistral-Small-3.2-24B-Instruct`, `Llama-3.1-8B-Instruct`, `Mistral-Nemo-Instruct-2407`, `Qwen2.5-VL-72B-Instruct` |
| baseURL | `https://oai.endpoints.kepler.ai.cloud.ovh.net/v1` |
| Rate limit | 2 req/min without key, ~400 RPM with key |
| Status | High, returns 429 on rate limit |

## 4. KeylessAI — ⚠️ UNSTABLE DNS

| Property | Value |
|----------|-------|
| Provider name | `keylessai` |
| Models | `openai-fast`, `grok-4.1-mini` |
| baseURL | `https://keylessai.thryx.workers.dev/v1` |
| Rate limit | Unknown |
| Status | DNS unreliable, may not resolve |

## 5. LLM7.io — ⚠️ UNSTABLE

| Property | Value |
|----------|-------|
| Provider name | `llm7` |
| Models | `deepseek-r1-0528`, `deepseek-v3-0324`, `gpt-4o-mini`, `mistral-small-3.1-24b`, `qwen2.5-coder-32b` |
| baseURL | `https://api.llm7.io/v1` |
| Rate limit | Unknown |
| Status | DNS timeout reported |

## 6. AI Horde — FREE COMMUNITY

| Property | Value |
|----------|-------|
| Provider name | `aihorde` |
| Models | `koboldcpp/llama-3.3-70b`, `koboldcpp/gemma-4-31b`, `koboldcpp/mistral-small-3.1` |
| baseURL | `https://aihorde.net/api/v2` |
| Auth | Anonymous key: `0000000000` |
| Status | Community-powered, may be slow |

## Failover priority

```
G4F (local) → Pollinations → ApiAirforce → OVHcloud → KeylessAI → LLM7 → AI Horde
```

The first 4 are verified working. Last 3 are fallbacks when the others are rate-limited.