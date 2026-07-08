---
description: Switch to a specific model in the fallback chain. Usage: /switch-model <number or name>
agent: build
---

Switch to a specific model from the fallback chain.

You can specify:
- A number from the fallback chain: `/switch-model 1` (primary), `/switch-model 5`
- A model name: `/switch-model groq/llama-3.3-70b-versatile`
- A shortcut: `/switch-model primary`, `/switch-model fast`, `/switch-model powerful`, `/switch-model reasoning`, `/switch-model coding`, `/switch-model keyless`
- Auto mode: `/switch-model auto` (picks the best available working model from the chain)

Fallback chain:
1. groq/llama-3.3-70b-versatile (Primary - fast)
2. groq/gpt-oss-120b (Fast powerful)
3. cerebras/gpt-oss-120b (Ultra-fast)
4. cerebras/qwen3-235b (Qwen 235B)
5. mistral/mistral-large-3 (Large)
6. mistral/codestral (Coding)
7. nvidia/deepseek-ai/deepseek-r1 (Reasoning)
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

Shortcuts:
- primary -> 1 (groq/llama-3.3-70b-versatile)
- fast -> 1-4 (Groq/Cerebras)
- powerful -> 5-7 (Mistral Large, Codestral, DeepSeek R1)
- reasoning -> 7 (DeepSeek R1)
- coding -> 6 (Codestral)
- keyless -> 26-28

When switching, first read the current model setting, then update it and inform the user.