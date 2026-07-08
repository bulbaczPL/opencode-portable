---
description: Test all 29 AI providers and report which ones are responding. Usage: /provider-test
agent: build
subtask: true
---

Test each provider in the config and return a table of results.

## Testing procedure

For each provider, check if its baseURL responds:

### Keyless providers (test via curl)
- Pollinations: `curl -s -o /dev/null -w "%{http_code}" -X POST https://text.pollinations.ai/openai/v1/chat/completions -H "Content-Type: application/json" -d '{"model":"openai","messages":[{"role":"user","content":"hi"}],"max_tokens":3}' --connect-timeout 5`
- ApiAirforce: `curl -s -o /dev/null -w "%{http_code}" -X POST https://api.airforce/v1/chat/completions -H "Content-Type: application/json" -d '{"model":"openai","messages":[{"role":"user","content":"hi"}],"max_tokens":3}' --connect-timeout 5`
- OVHcloud: `curl -s -o /dev/null -w "%{http_code}" -X POST https://oai.endpoints.kepler.ai.cloud.ovh.net/v1/chat/completions -H "Content-Type: application/json" -d '{"model":"Mistral-7B-Instruct-v0.3","messages":[{"role":"user","content":"hi"}],"max_tokens":3}' --connect-timeout 5`
- G4F local: `curl -s -o /dev/null -w "%{http_code}" -X POST http://localhost:1337/v1/chat/completions -H "Content-Type: application/json" -d '{"model":"gpt-4o-mini","messages":[{"role":"user","content":"hi"}],"max_tokens":3}' --connect-timeout 3`

### Providers with API keys (check if key is configured)
Check env vars or config for these providers and report if key is present (not the actual key):

- Groq → check `GROQ_API_KEY` env var
- Cerebras → check `CEREBRAS_API_KEY`
- Mistral → check `MISTRAL_API_KEY`
- NVIDIA → check `NVIDIA_API_KEY`
- OpenRouter → check `OPENROUTER_API_KEY`
- DeepSeek → check `DEEPSEEK_API_KEY`
- Together AI → check `TOGETHERAI_API_KEY`
- Others → report "key not configured"

## Output format

```
Provider              | Type    | Status    | Notes
----------------------|---------|-----------|------
G4F (local)           | Keyless | ✅ WORKING | port 1337
Pollinations          | Keyless | ✅ WORKING |
ApiAirforce           | Keyless | ✅ WORKING |
OVHcloud              | Keyless | ✅ WORKING |
KeylessAI             | Keyless | ⚠️ FAIL    | DNS timeout
LLM7                  | Keyless | ⚠️ FAIL    | DNS timeout
Groq                  | API key | ❌ no key  | export GROQ_API_KEY
Cerebras              | API key | ❌ no key  | export CEREBRAS_API_KEY
...
```

At the end, suggest:
1. If G4F is not running: `/g4f-start` or `systemctl --user start g4f.service`
2. For providers without keys: use `/provider-register` for setup guide
3. Which 3 working providers to use as primary fallback