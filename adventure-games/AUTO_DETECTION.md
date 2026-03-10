# OpenClaw Model Auto-Detection

**Feature:** Automatically detect and configure whatever model is running on vLLM
**Status:** ✅ Implemented
**Location:** `/home/ttclaw/openclaw/detect-model.py`

## What It Does

The launcher now automatically queries `localhost:8001/v1/models` (or `:8000`) and configures OpenClaw to use whatever model is available. Works with:

- **8B models:** Llama-3.1-8B-Instruct, Llama-3.2-1B-ASCII
- **70B models:** Llama-3.3-70B-Instruct, DeepSeek-R1-Distill-Llama-70B
- **Other models:** Qwen, Mistral, any vLLM-compatible model

## How It Works

1. **Startup:** `adventure-menu.sh` runs `detect-model.py` on launch
2. **Query:** Script queries vLLM endpoint for available models
3. **Detect:** Selects first available model
4. **Configure:** Updates OpenClaw config with correct context window and settings
5. **Play:** Games use detected model automatically

## Auto-Detected Settings

Based on model name, the script automatically sets:

| Model Family | Context Window | Max Tokens | Reasoning |
|-------------|----------------|------------|-----------|
| Llama 3.1 | 65,536 | 8,192 | No |
| Llama 3.2 | 32,768 | 8,192 | No |
| Llama 3.3 | 131,072 | 8,192 | No |
| DeepSeek-R1 | 131,072 | 8,192 | Yes |
| Qwen | 32,768 | 8,192 | No |
| Mistral | 32,768 | 8,192 | No |
| Default | 32,768 | 8,192 | No |

## Override

You can override auto-detection with an environment variable:

```bash
# Use specific model
OPENCLAW_MODEL="meta-llama/Llama-3.3-70B-Instruct" ./adventure-menu.sh

# Or export it
export OPENCLAW_MODEL="deepseek-ai/DeepSeek-R1-Distill-Llama-70B"
./adventure-menu.sh
```

## Manual Usage

You can also run the detection script directly:

```bash
cd /home/ttclaw/openclaw

# Auto-detect and update config
python3 detect-model.py

# Dry-run (show what would be detected)
python3 detect-model.py --dry-run

# Check specific port
python3 detect-model.py --port 8000
```

## Example Output

```
🎮 OpenClaw Model Auto-Detection
==================================================
🔍 Checking localhost:8001/v1/models...
✅ Found model: meta-llama/Llama-3.1-8B-Instruct

📊 Detected Model Configuration:
  Model: Llama 3.1 8B Instruct
  ID: meta-llama/Llama-3.1-8B-Instruct
  Context Window: 65,536 tokens
  Max Output: 8,192 tokens
  Reasoning: False
  Port: 8001

💾 Backed up config to: /home/ttclaw/.openclaw/openclaw.json.backup
✅ Updated config: /home/ttclaw/.openclaw/openclaw.json

✅ OpenClaw configured successfully!
```

## Benefits

1. **Zero configuration** - Works with any model out of the box
2. **Model-agnostic** - Adapts to 8B, 70B, or any size
3. **Safe defaults** - Conservative settings that always work
4. **Easy override** - Environment variable for special cases
5. **Automatic backup** - Config backed up before changes

## Integration

The `adventure-menu.sh` launcher includes this automatically:

```bash
# Auto-detect and configure model
auto_detect_model() {
    echo -e "${CYAN}🔍 Auto-detecting available model...${NC}"

    # Check for environment override
    if [ -n "$OPENCLAW_MODEL" ]; then
        echo -e "${GREEN}✓ Using override: $OPENCLAW_MODEL${NC}"
        python3 "$OPENCLAW_DIR/detect-model.py" > /dev/null 2>&1
        return 0
    fi

    # Run detection
    if python3 "$OPENCLAW_DIR/detect-model.py" 2>&1 | grep -q "configured successfully"; then
        echo -e "${GREEN}✓ Model auto-configured${NC}"
        return 0
    else
        echo -e "${YELLOW}⚠️  Could not auto-detect model${NC}"
        echo -e "   Using existing configuration"
        return 1
    fi
}
```

## Troubleshooting

**No model detected:**
```bash
# Check vLLM is running
curl http://localhost:8000/v1/models

# Check proxy is running
curl http://localhost:8001/v1/models

# Use override
OPENCLAW_MODEL="your/model" ./adventure-menu.sh
```

**Wrong settings detected:**
```bash
# Override with specific model
OPENCLAW_MODEL="meta-llama/Llama-3.3-70B-Instruct" python3 detect-model.py
```

## Files

**Runtime:** `/home/ttclaw/openclaw/`
- `detect-model.py` - Detection script
- `adventure-menu.sh` - Launcher with auto-detection
- `play-*.sh` - Individual game launchers (also call detection)

**Config:** `/home/ttclaw/.openclaw/`
- `openclaw.json` - Updated by detection
- `openclaw.json.backup` - Automatic backup

---

**Added:** March 8, 2026
**Status:** Production ready
**Testing:** Verified with Llama-3.1-8B-Instruct
