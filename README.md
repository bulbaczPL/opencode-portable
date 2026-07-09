# opencode-portable

> **Zero API keys · 27 AI providers · 18 verified models · 1 command**

Portable [opencode CLI](https://opencode.ai) configuration with G4F keyless aggregator (18 verified models), 2 direct keyless providers, 25 free-tier providers (API key optional), and intelligent model failover.

---

**🌐 README in your language:**

[🇵🇱 Polski](#polski) · [🇬🇧 English](#english) · [🇩🇪 Deutsch](#deutsch) · [🇫🇷 Français](#français) · [🇪🇸 Español](#español) · [🇮🇹 Italiano](#italiano) · [🇵🇹 Português](#português) · [🇷🇺 Русский](#русский) · [🇨🇳 中文](#中文) · [🇯🇵 日本語](#日本語)

---

<a id="polski"></a>
## 🇵🇱 Polski

**Zero kluczy API. 27 providerów. 18 modeli. 1 komenda.**

```bash
curl -sL https://raw.githubusercontent.com/bulbaczPL/opencode-portable/main/setup.sh | bash
```

Przenośna konfiguracja opencode z G4F agregatorem (18 zweryfikowanych modeli), 2 keyless providerami (działają od razu), 25 darmowymi (klucz opcjonalny) i inteligentnym failoverem.

[⬆ Powrót na górę](#opencode-portable)

---

<a name="english"></a>
## 🇬🇧 English

**Zero API keys. 27 providers. 18 models. 1 command.**

```bash
curl -sL https://raw.githubusercontent.com/bulbaczPL/opencode-portable/main/setup.sh | bash
```

Portable opencode CLI configuration with G4F keyless aggregator (18 verified models), 2 direct keyless providers, 25 free-tier (API key optional), and intelligent model failover.

[⬆ Back to top](#opencode-portable)

---

<a name="deutsch"></a>
## 🇩🇪 Deutsch

**Keine API-Schlüssel. 27 Anbieter. 18 Modelle. 1 Befehl.**

```bash
curl -sL https://raw.githubusercontent.com/bulbaczPL/opencode-portable/main/setup.sh | bash
```

Tragbare opencode-Konfiguration mit G4F-Aggregator (18 geprüfte Modelle), 2 schlüssellosen Anbietern, 25 kostenlosen Anbietern (API-Schlüssel optional) und intelligentem Failover.

[⬆ Nach oben](#opencode-portable)

---

<a name="français"></a>
## 🇫🇷 Français

**Zéro clé API. 27 fournisseurs. 18 modèles. 1 commande.**

```bash
curl -sL https://raw.githubusercontent.com/bulbaczPL/opencode-portable/main/setup.sh | bash
```

Configuration portable opencode avec agrégateur G4F (18 modèles vérifiés), 2 fournisseurs sans clé, 25 fournisseurs gratuits (clé API optionnelle) et basculement intelligent.

[⬆ Haut de page](#opencode-portable)

---

<a name="español"></a>
## 🇪🇸 Español

**Cero claves API. 27 proveedores. 18 modelos. 1 comando.**

```bash
curl -sL https://raw.githubusercontent.com/bulbaczPL/opencode-portable/main/setup.sh | bash
```

Configuración portátil de opencode con agregador G4F (18 modelos verificados), 2 proveedores sin clave, 25 gratuitos (clave API opcional) y failover inteligente.

[⬆ Volver arriba](#opencode-portable)

---

<a name="italiano"></a>
## 🇮🇹 Italiano

**Zero chiavi API. 27 provider. 18 modelli. 1 comando.**

```bash
curl -sL https://raw.githubusercontent.com/bulbaczPL/opencode-portable/main/setup.sh | bash
```

Configurazione portatile opencode con aggregatore G4F (18 modelli verificati), 2 provider senza chiave, 25 gratuiti (chiave API opzionale) e failover intelligente.

[⬆ Torna su](#opencode-portable)

---

<a name="português"></a>
## 🇵🇹 Português

**Zero chaves de API. 27 provedores. 18 modelos. 1 comando.**

```bash
curl -sL https://raw.githubusercontent.com/bulbaczPL/opencode-portable/main/setup.sh | bash
```

Configuração portátil opencode com agregador G4F (18 modelos verificados), 2 provedores sem chave, 25 gratuitos (chave API opcional) e failover inteligente.

[⬆ Voltar ao topo](#opencode-portable)

---

<a name="русский"></a>
## 🇷🇺 Русский

**Ноль ключей API. 27 провайдеров. 18 моделей. 1 команда.**

```bash
curl -sL https://raw.githubusercontent.com/bulbaczPL/opencode-portable/main/setup.sh | bash
```

Портативная конфигурация opencode с G4F агрегатором (18 проверенных моделей), 2 провайдерами без ключа, 25 бесплатными (ключ опционально) и интеллектуальным переключением.

[⬆ Вверх](#opencode-portable)

---

<a name="中文"></a>
## 🇨🇳 中文

**零API密钥。27个提供商。18个模型。1条命令。**

```bash
curl -sL https://raw.githubusercontent.com/bulbaczPL/opencode-portable/main/setup.sh | bash
```

便携式opencode配置，包含G4F聚合器（18个已验证模型）、2个无需密钥的提供商、25个免费提供商（可选API密钥）和智能故障转移。

[⬆ 返回顶部](#opencode-portable)

---

<a name="日本語"></a>
## 🇯🇵 日本語

**APIキー不要。27のプロバイダー。18のモデル。1つのコマンド。**

```bash
curl -sL https://raw.githubusercontent.com/bulbaczPL/opencode-portable/main/setup.sh | bash
```

G4Fアグリゲーター（18の検証済みモデル）、2つのキーレスプロバイダー、25の無料プロバイダー（APIキー任意）を備えたポータブルopencode設定。

[⬆ トップへ戻る](#opencode-portable)

---

## 27 providers

### Keyless — works immediately, no key needed

| Provider | Models | Status |
|----------|--------|--------|
| G4F (local) | 18 verified text models | ✅ live tested |
| Pollinations.ai | GPT-OSS 20B | ✅ live tested |

### Keyless — broken (kept for reference)

| Provider | Status |
|----------|--------|
| ApiAirforce | Requires auth (401) |
| OVHcloud | HTTP 404 |
| Kilo Gateway | Connection timeout |
| KeylessAI | Cloudflare 1042 |
| LLM7.io | HTTP 405 |
| AI Horde | Dead |

### Free tier — API key required, no credit card

Groq · Cerebras · Mistral · NVIDIA NIM · OpenRouter · Cloudflare Workers · Together AI · SambaNova · Hugging Face · GitHub Models · DeepSeek · Scaleway · Cohere · SiliconFlow · Z.AI · ModelScope · DashScope · Ollama Cloud · FreeTheAi · Aion Labs · Token-Free Gateway · smanx-free

## Custom commands

| Command | Description |
|---------|-------------|
| `/status` | Model, G4F, keyless, API keys status |
| `/switch-model` | Switch model (keyless priority) |
| `/g4f-health` | G4F health check, restart, logs |
| `/g4f-start` | Start G4F aggregator |
| `/fallback-chain` | View/test failover chain |
| `/fallback-chain test` | Test all providers in chain |
| `/provider-test` | Test all 27 providers |
| `/provider-register` | Registration guide (25 providers) |
| `/auto-failover` | Toggle auto-failover |

## Agent skills

| Skill | Description |
|-------|-------------|
| `g4f-management` | Start, stop, restart, logs, troubleshooting |
| `keyless-providers` | All keyless providers, rate limits, reliability |
| `provider-registration` | Step-by-step guide for registration processes |

## Subagents

| Agent | Role | Permissions |
|-------|------|-------------|
| `g4f-manager` | G4F lifecycle management | bash: allow, edit: deny |
| `model-router` | Automatic model failover | bash: allow, read: allow |

## Model failover

Automatic 3-tier fallback when a model fails:

```
Keyless (G4F → Pollinations)
  ↓
Free API key (Groq → Cerebras → Mistral → NVIDIA → OpenRouter …)
  ↓
Specialized (Cohere → DashScope → Z.AI → SiliconFlow …)
```

## Requirements

- Linux / WSL
- Internet (first install only)

Everything else is auto-installed.

## License

MIT