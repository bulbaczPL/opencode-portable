---
name: g4f-management
description: Manage the G4F (GPT4Free) local keyless aggregator — start, stop, restart, check health, view logs, troubleshoot. Use when G4F is unresponsive or needs maintenance.
license: MIT
metadata:
  author: opencode-portable
  version: "1.0"
  category: provider-management
---

# G4F Management

G4F (GPT4Free) v7.7.2 is a local keyless aggregator providing 1058 models through 30+ providers. Runs on `localhost:1337`.

## Quick commands

```bash
# Status
systemctl --user status g4f.service

# Start
systemctl --user start g4f.service

# Stop
systemctl --user stop g4f.service

# Restart
systemctl --user restart g4f.service

# Enable on boot
systemctl --user enable g4f.service

# View live logs
journalctl --user -u g4f.service -f

# Last 50 lines
journalctl --user -u g4f.service -n 50 --no-pager
```

## Manual start (if systemd unavailable)

```bash
python3 -c "from g4f.api import run_api; run_api(port=1337)"
```

## Health check

```bash
curl -X POST http://localhost:1337/v1/chat/completions \
  -H "Content-Type: application/json" \
  -d '{"model":"gpt-4o-mini","messages":[{"role":"user","content":"hi"}],"max_tokens":3}'
```

Expected: HTTP 200 with a JSON response.

## Troubleshooting

### G4F won't start

```bash
# Check Python import
python3 -c "import g4f; print('G4F OK')"

# Reinstall if missing
pip3 install --break-system-packages g4f

# Check port conflict
ss -tlnp | grep 1337

# Try with debug
python3 -c "from g4f.api import run_api; run_api(port=1337, debug=True)"
```

### G4F starts but returns errors

The aggregator relies on external keyless providers. If none respond:
1. G4F will fall back to whatever provider works
2. Use direct keyless providers as backup: Pollinations, ApiAirforce, OVHcloud
3. Check internet connectivity

### Slow responses

- G4F aggregates multiple providers — first request may be slow
- Subsequent requests cache the working provider
- Average response time: 2-10s depending on provider

## Model prefixes

Models are used as `g4f/model-name` in opencode:

- `g4f/gpt-4o-mini` — default, fast, reliable
- `g4f/gpt-4o` — full GPT-4o
- `g4f/claude-3.5-sonnet` — Claude through G4F
- `g4f/gemini-2.5-flash` — Gemini
- `g4f/deepseek-r1` — DeepSeek R1
- `g4f/llama-3.3-70b` — Llama
- See full list in `~/.config/opencode/opencode.jsonc` under `provider.g4f.models`