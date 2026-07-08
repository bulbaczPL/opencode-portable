---
description: Enable or disable automatic model failover. Usage: /auto-failover [on|off|status]
agent: model-router
subtask: true
---

Manage automatic model failover:

- `/auto-failover on` — Enable auto-failover (default). When a model errors, automatically try the next in chain.
- `/auto-failover off` — Disable auto-failover. Stop on errors instead.
- `/auto-failover status` — Show current failover state.
- `/auto-failover reset` — Reset the failover chain (clear all failed model history).

When enabled, the model-router agent will:
1. Detect API errors (rate limits, timeouts, auth failures)
2. Automatically switch to the next working model in the fallback chain
3. Log the switch with reason
4. Resume the original task