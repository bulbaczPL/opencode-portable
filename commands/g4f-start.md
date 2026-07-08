---
description: Start the G4F local keyless aggregator (91+ models, 30+ providers, no API keys). Usage: /g4f-start
---

Start G4F (GPT4Free) as a local API server on port 1337:

- Provides **91+ models** through **30+ keyless providers** (Pollinations, DuckDuckGo, DeepInfra, WeWordle, etc.)
- No API keys needed
- Auto-failover between providers built in

To start: run `python -c "from g4f.api import run_api; run_api(port=1337)"` in a separate terminal.

Once running, opencode will use `g4f/provider` models from the fallback chain.