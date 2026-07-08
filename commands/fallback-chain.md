---
description: Configure and view the model fallback chain
agent: build
---

Manage the model fallback chain for automatic failover.

Usage:
- `/fallback-chain` — view the current chain
- `/fallback-chain add groq/llama-3.3-70b-versatile` — add a model to the chain
- `/fallback-chain remove 5` — remove model at position 5
- `/fallback-chain move 3 1` — move model from position 3 to position 1
- `/fallback-chain test` — test each model in the chain and remove failing ones

Current fallback chain (ordered by priority):
1. groq/llama-3.3-70b-versatile (Primary - fast)
2. groq/gpt-oss-120b (Fast powerful)
3. cerebras/gpt-oss-120b (Ultra-fast inference)
4. cerebras/qwen3-235b (Qwen 235B)
5. mistral/mistral-large-3 (Mistral Large 3)
6. mistral/codestral (Coding specialist)
7. nvidia/deepseek-ai/deepseek-r1 (Reasoning specialist)
8. openrouter/meta-llama/llama-3.3-70b-instruct:free
9. openrouter/qwen/qwen3-coder:free
10. openrouter/nvidia/nemotron-3-ultra-550b-a55b:free
11. openrouter/nvidia/nemotron-3-super-120b-a12b:free
12. sambanova/Meta-Llama-3.3-70B-Instruct
13. sambanova/DeepSeek-V3.1
14. huggingface/meta-llama/Llama-3.3-70B-Instruct
15. ollamacloud/gpt-oss:120b-cloud
16. githubmodels/Meta-Llama-3.3-70B
17. deepseek/deepseek-v4-flash
18. scaleway/meta-llama/llama-3.3-70b
19. togetherai/meta-llama/Llama-3.3-70B-Instruct-Turbo
20. cloudflare/@cf/meta/llama-3.3-70b-instruct-fp8-fast
21. groq/llama-4-scout-17b-16e-instruct
22. cerebras/llama-3.1-70b
23. cohere/command-a
24. dashscope/qwen/qwen3.6-27b
25. zai/GLM-4.7-Flash
26. pollinations/openai-fast (Keyless - last resort)
27. keylessai/openai-fast (Keyless - last resort)
28. keylessai/grok-4.1-mini (Keyless - last resort)