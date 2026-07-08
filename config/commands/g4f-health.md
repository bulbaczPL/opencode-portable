---
description: Check G4F health, restart if needed, show logs. Usage: /g4f-health
agent: g4f-manager
subtask: true
---

Check G4F (GPT4Free) local keyless aggregator status.

## Check health

1. Run `systemctl --user is-active g4f.service 2>/dev/null || echo "inactive"`
2. Run `curl -s -o /dev/null -w "%{http_code}" -X POST http://localhost:1337/v1/chat/completions -H "Content-Type: application/json" -d '{"model":"gpt-4o-mini","messages":[{"role":"user","content":"hi"}],"max_tokens":3}' --connect-timeout 5`

## If not running

1. Try `systemctl --user start g4f.service`
2. Wait 3 seconds
3. Test again with curl
4. If still not running, start manually: `nohup python3 -c "from g4f.api import run_api; run_api(port=1337)" > /tmp/g4f.log 2>&1 &`
5. Wait 5 seconds, test again

## Show log

Run `journalctl --user -u g4f.service -n 20 --no-pager` if systemd, or `cat /tmp/g4f.log 2>/dev/null` if manual.

## Report

Return a summary:
- Status: running / started / failed
- HTTP response code
- Log excerpt (last 5 lines)
- If G4F cannot start, suggest using direct keyless providers: Pollinations, ApiAirforce