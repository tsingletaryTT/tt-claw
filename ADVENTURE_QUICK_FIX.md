# Adventure Games - Auto-Detect vLLM Models

## Problem
OpenClaw's `main` agent had 125 HuggingFace models configured from default onboarding, showing remote models instead of just the local vLLM server.

## Solution: Auto-Detection

The setup script now **auto-detects** models from the running vLLM server instead of hardcoding specific models.

### How It Works

1. **Query vLLM server** at `http://localhost:8001/v1/models` (proxy) or `http://localhost:8000/v1/models` (direct)
2. **Extract model information** (ID, context window, etc.)
3. **Pick best model** if multiple available:
   - Prefer instruct/chat models (score +100)
   - Prefer larger models (score = parameter count)
   - Example: "Llama-3.1-70B-Instruct" scores higher than "Llama-3.1-8B"
4. **Create OpenClaw config** with detected models
5. **Set as default** in global config

### Script Location

**File:** `adventure-games/scripts/setup-game-agents.sh`

**Step 3:** Auto-detection logic (Python)

```python
def detect_vllm_models():
    """Detect models from vLLM server"""
    for url in ["http://127.0.0.1:8001/v1/models", "http://127.0.0.1:8000/v1/models"]:
        try:
            with urllib.request.urlopen(url, timeout=3) as response:
                data = json.loads(response.read().decode())
                if data.get("data"):
                    return data["data"], port
        except:
            continue
    return None, None
```

### Example Output

**When vLLM is running:**
```
📦 Auto-detecting vLLM models...
  ✓ Detected 1 model(s) from vLLM (port 8001)
  ✓ Selected best model: meta-llama/Llama-3.1-8B-Instruct
  ✓ Created models.json with 1 model(s)
  ✓ Set default: vllm/meta-llama/Llama-3.1-8B-Instruct
```

**When vLLM is NOT running:**
```
📦 Auto-detecting vLLM models...
  ⚠️  vLLM server not running - using default configuration
     Start vLLM first for auto-detection
     Configuring with placeholder (update after starting vLLM)
```

### Generated Config

**File:** `~/.openclaw/agents/main/agent/models.json`

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
          "name": "Llama-3.1-8B-Instruct",
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

**Note:** Model ID, context window, and other details are **auto-detected** from vLLM, not hardcoded!

### Benefits

✅ **Works with any model** - 8B, 70B, or custom models
✅ **No hardcoding** - Adapts to whatever vLLM is serving
✅ **Accurate context windows** - Uses actual `max_model_len` from vLLM
✅ **Multi-model support** - Detects all available models
✅ **Smart selection** - Picks best model automatically
✅ **Fallback handling** - Works even if vLLM isn't running yet

### Model Selection Logic

**Priority (highest to lowest):**
1. Instruct/chat models over base models
2. Larger models over smaller models
3. First model if multiple with same score

**Examples:**
- `Llama-3.3-70B-Instruct` beats `Llama-3.1-8B-Instruct` (larger + instruct)
- `Llama-3.1-8B-Instruct` beats `Llama-3.1-8B` (instruct variant)
- `DeepSeek-R1-70B` beats `Llama-3.1-8B-Instruct` (much larger)

### Usage

**Fresh installation:**
```bash
# 1. Install OpenClaw
cd ~/tt-claw/adventure-games/scripts
./install-openclaw.sh

# 2. Start vLLM (if not already running)
# ... your vLLM startup command ...

# 3. Setup game agents (auto-detects models)
./setup-game-agents.sh
```

**Verify detection:**
```bash
# Check detected models
cat ~/.openclaw/agents/main/agent/models.json | python3 -c "
import sys, json
data = json.load(sys.stdin)
models = data['providers']['vllm']['models']
print(f'Detected {len(models)} models:')
for m in models:
    print(f'  - {m[\"id\"]} (context: {m[\"contextWindow\"]:,})')
"

# Check default model
cat ~/.openclaw/openclaw.json | python3 -c "
import sys, json
data = json.load(sys.stdin)
print('Default:', data.get('agents', {}).get('defaults', {}).get('model', {}).get('primary', 'Not set'))
"
```

**Re-detect after changing models:**
```bash
# Stop gateway
pkill -f "openclaw.*gateway"

# Re-run setup (detects new model)
cd ~/tt-claw/adventure-games/scripts
./setup-game-agents.sh

# Restart gateway
cd ~/openclaw && ./openclaw.sh gateway run
```

### Port Detection

The script tries both ports in order:
1. **Port 8001** - Proxy (strips incompatible fields)
2. **Port 8000** - Direct vLLM (fallback)

**Recommended:** Use proxy (port 8001) for OpenClaw compatibility.

### Troubleshooting

**"vLLM server not running"**
- Start vLLM first: See `START_SERVICES.md`
- Or run setup script after vLLM starts
- Config will have empty models list (still works, just shows no models)

**"Wrong model detected"**
- Only one model per vLLM instance
- If multiple models: Script picks best automatically
- To override: Edit `~/.openclaw/agents/main/agent/models.json` manually

**"Context window too small/large"**
- Auto-detected from vLLM's `max_model_len`
- Reflects actual vLLM configuration
- To change: Restart vLLM with different `--max-model-len`

### Future Enhancements

Potential improvements:
- **Live refresh** - Periodically re-detect models
- **Manual override** - Flag to skip auto-detection
- **Model profiles** - Save configs for different deployments
- **Health checks** - Verify models are actually working

---

**Status:** ✅ Implemented and tested
**Updated:** March 10, 2026
**Script:** `adventure-games/scripts/setup-game-agents.sh`
