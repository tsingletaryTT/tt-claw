# Adventure Games - vLLM-Only Configuration Fix

## Problem
OpenClaw's `main` agent had 125 HuggingFace router models configured, showing remote models instead of just the local vLLM server.

## Root Cause
During OpenClaw onboarding, the wizard created `~/.openclaw/agents/main/agent/models.json` with default HuggingFace models. The game agents (chip-quest, terminal-dungeon, conference-chaos) inherit from the main agent, so they were also seeing remote models.

## Solution Applied

### 1. Replaced main agent models.json

**File:** `~/.openclaw/agents/main/agent/models.json`

**Before:** 125 HuggingFace models
**After:** 1 local vLLM model

```json
{
  "providers": {
    "vllm": {
      "baseUrl": "http://127.0.0.1:8001/v1",
      "api": "openai-completions",
      "apiKey": "sk-no-auth",
      "models": [
        {
          "id": "meta-llama/Llama-3.1-8B-Instruct",
          "name": "Llama 3.1 8B Instruct",
          "reasoning": false,
          "input": ["text"],
          "contextWindow": 65536,
          "maxTokens": 8192
        }
      ]
    }
  }
}
```

### 2. Set Global Default Model

**File:** `~/.openclaw/openclaw.json`

Added to `agents.defaults.model`:
```json
{
  "agents": {
    "defaults": {
      "model": {
        "primary": "vllm/meta-llama/Llama-3.1-8B-Instruct"
      }
    }
  }
}
```

### 3. Restarted Gateway

Gateway needed restart to pick up new configuration:
```bash
pkill -f "openclaw.*gateway"
cd ~/openclaw && ./openclaw.sh gateway run
```

## Verification

**Check model config:**
```bash
# Main agent models
cat ~/.openclaw/agents/main/agent/models.json | python3 -c "
import sys, json
data = json.load(sys.stdin)
providers = list(data.get('providers', {}).keys())
models = sum(len(p.get('models', [])) for p in data.get('providers', {}).values())
print(f'Providers: {providers}')
print(f'Total models: {models}')
"

# Expected output:
# Providers: ['vllm']
# Total models: 1
```

**Check default model:**
```bash
cat ~/.openclaw/openclaw.json | python3 -c "
import sys, json
data = json.load(sys.stdin)
model = data.get('agents', {}).get('defaults', {}).get('model', {}).get('primary', 'Not set')
print(f'Default model: {model}')
"

# Expected output:
# Default model: vllm/meta-llama/Llama-3.1-8B-Instruct
```

## Backup Files Created

In case you need to revert:
- `~/.openclaw/agents/main/agent/models.json.backup-huggingface` - Original 125 models
- `~/.openclaw/openclaw.json.backup-before-vllm-only` - Original global config

## For Fresh Installations

To avoid this issue in future installations, the setup script should create models.json directly instead of relying on the onboarding wizard.

**Script location:** `~/tt-claw/adventure-games/scripts/setup-game-agents.sh`

**Add after agent creation:**
```bash
# Create vLLM-only models.json for main agent
mkdir -p ~/.openclaw/agents/main/agent
cat > ~/.openclaw/agents/main/agent/models.json << 'EOF'
{
  "providers": {
    "vllm": {
      "baseUrl": "http://127.0.0.1:8001/v1",
      "api": "openai-completions",
      "apiKey": "sk-no-auth",
      "models": [
        {
          "id": "meta-llama/Llama-3.1-8B-Instruct",
          "name": "Llama 3.1 8B Instruct",
          "reasoning": false,
          "input": ["text"],
          "contextWindow": 65536,
          "maxTokens": 8192
        }
      ]
    }
  }
}
EOF
```

## Impact

- ✅ Game agents now only see local vLLM model
- ✅ No remote API calls attempted
- ✅ No API keys needed
- ✅ Faster agent startup (fewer models to check)
- ✅ Cleaner model selection interface

---

**Applied:** March 10, 2026
**Status:** ✅ Verified working
