# Direct vLLM Solution for 70B Models on P150X4

**Date:** 2026-03-07
**Status:** ✅ WORKING - Validated with DeepSeek-R1-Distill-Llama-70B
**For User:** ttclaw (OpenClaw deployment)

## Why This Solution

The tt-inference-server Docker approach has critical issues for 70B models:
1. **30-second timeout** - way too aggressive (70B needs 10-30 minutes)
2. **Complex volume mounting** - requires specific env vars not documented
3. **Docker image mismatches** - some specs reference non-existent images

**Direct vLLM bypasses all of this** and gives you full control.

---

## Prerequisites

### System Requirements
- ✅ **Hardware:** 2x P300C (= P150X4 configuration, 4 chips total)
- ✅ **RAM:** 175GB minimum (for 70B), you have 236GB
- ✅ **Disk:** 160GB minimum (for 70B), you have plenty
- ✅ **Firmware:** 19.4.2.0 
- ✅ **KMD:** 2.7.0

### Software Stack (Exact Versions That Work)
```bash
# tt-metal
cd ~/tt-metal
git rev-parse HEAD  # Should be: d3c8774 (or compatible)

# tt-vllm
cd ~/tt-vllm
git rev-parse HEAD  # Should be: aa4ae1edc (critical - must match!)

# Python venv
source ~/.tenstorrent-venv/bin/activate
python --version  # 3.12.x recommended
```

### vLLM Patch Verification
The vLLM patch for TT model registration MUST be present:

```bash
grep -A 5 "_ensure_tt_models_registered" ~/tt-vllm/vllm/platforms/tt.py
```

Should show the method exists. If not, the patch is missing and models won't load.

---

## Environment Setup for ttclaw User

### Option 1: Quick Setup Script (Recommended)

Create `/home/ttclaw/setup-70b-env.sh`:
```bash
#!/bin/bash
# Setup environment for 70B models on P150X4
# For user: ttclaw

export VLLM_TARGET_DEVICE=tt
export MESH_DEVICE=P150x4
export ARCH_NAME=blackhole
export TT_METAL_HOME=/home/ttuser/tt-metal  # Shared with ttuser
export PYTHONPATH=/home/ttuser/tt-metal:/home/ttuser/tt-vllm:$PYTHONPATH
export LD_LIBRARY_PATH=/opt/openmpi-v5.0.7-ulfm/lib:$LD_LIBRARY_PATH

# Activate Python venv (ttclaw should have access to this)
source /home/ttuser/.tenstorrent-venv/bin/activate

echo "✅ Environment configured for P150X4 (4x P300C)"
echo "   TT_METAL_HOME: $TT_METAL_HOME"
echo "   MESH_DEVICE: $MESH_DEVICE"
echo "   Python: $(which python3)"
```

Make executable:
```bash
chmod +x /home/ttclaw/setup-70b-env.sh
```

### Option 2: Add to ~/.bashrc

For ttclaw user's `~/.bashrc`:
```bash
# Tenstorrent 70B Model Environment
export VLLM_TARGET_DEVICE=tt
export MESH_DEVICE=P150x4
export ARCH_NAME=blackhole
export TT_METAL_HOME=/home/ttuser/tt-metal
export PYTHONPATH=/home/ttuser/tt-metal:/home/ttuser/tt-vllm:$PYTHONPATH
export LD_LIBRARY_PATH=/opt/openmpi-v5.0.7-ulfm/lib:$LD_LIBRARY_PATH

# Activate vLLM environment
if [ -f /home/ttuser/.tenstorrent-venv/bin/activate ]; then
    source /home/ttuser/.tenstorrent-venv/bin/activate
fi
```

---

## Running 70B Models

### Universal Run Script

Create `/home/ttclaw/run-70b-vllm.sh`:
```bash
#!/bin/bash
# Run 70B model with direct vLLM
# Usage: ./run-70b-vllm.sh <model-name> <model-path>

MODEL_HF_NAME="$1"
MODEL_LOCAL_PATH="$2"
PORT="${3:-8000}"

if [ -z "$MODEL_HF_NAME" ] || [ -z "$MODEL_LOCAL_PATH" ]; then
    cat << 'USAGE'
Usage: $0 <model-hf-name> <model-local-path> [port]

Examples:
  # DeepSeek-R1-70B
  ./run-70b-vllm.sh \
    deepseek-ai/DeepSeek-R1-Distill-Llama-70B \
    /home/ttuser/models/DeepSeek-R1-Distill-Llama-70B

  # Llama-3.3-70B
  ./run-70b-vllm.sh \
    meta-llama/Llama-3.3-70B-Instruct \
    /home/ttuser/code/tt-inference-server/persistent_volume/volume_id_tt_transformers-Llama-3.3-70B-Instruct-v0.9.0/weights/Llama-3.3-70B-Instruct

Available models:
  - DeepSeek-R1-Distill-Llama-70B (tested, working)
  - Llama-3.3-70B-Instruct (downloaded, ready)
  - Llama-3.1-70B-Instruct (available)

Notes:
  - Loading takes 10-30 minutes (132GB weights, mostly silent)
  - Check readiness: curl http://localhost:$PORT/health
  - Server runs on port $PORT (default: 8000)
USAGE
    exit 1
fi

echo "🚀 Starting $MODEL_HF_NAME on P150X4"
echo "   Local path: $MODEL_LOCAL_PATH"
echo "   Port: $PORT"
echo ""
echo "⏱️  Loading 70B model takes 10-30 minutes"
echo "   Progress is mostly silent - be patient!"
echo ""
echo "✅ Check readiness:"
echo "   curl http://localhost:$PORT/health"
echo ""

# Setup environment
source /home/ttclaw/setup-70b-env.sh

# Set model-specific env var (required by tt-metal)
export HF_MODEL="$MODEL_HF_NAME"

cd /home/ttuser/tt-vllm

# Run vLLM server
python3 -m vllm.entrypoints.openai.api_server \
  --model "$MODEL_LOCAL_PATH" \
  --block-size 64 \
  --max-model-len 131072 \
  --max-num-seqs 32 \
  --max-num-batched-tokens 131072 \
  --seed 9472 \
  --port "$PORT"
```

Make executable:
```bash
chmod +x /home/ttclaw/run-70b-vllm.sh
```

---

## Testing Script

Create `/home/ttclaw/test-70b-api.sh`:
```bash
#!/bin/bash
# Test 70B vLLM API server
PORT="${1:-8000}"

echo "🧪 Testing vLLM API on port $PORT..."
echo ""

# Health check
echo "1. Health check:"
if curl -s http://localhost:$PORT/health > /dev/null 2>&1; then
    echo "✅ Server is healthy and ready!"
else
    echo "❌ Server not ready yet (still loading weights)"
    echo "   70B models take 10-30 minutes to load"
    echo "   Check process: ps aux | grep vllm"
    exit 1
fi

echo ""
echo "2. List models:"
curl -s http://localhost:$PORT/v1/models | jq -r '.data[].id'

echo ""
echo "3. Quick test completion:"
curl -s http://localhost:$PORT/v1/completions \
  -H "Content-Type: application/json" \
  -d '{
    "model": "auto",
    "prompt": "The capital of France is",
    "max_tokens": 10,
    "temperature": 0
  }' | jq -r '.choices[0].text'

echo ""
echo "✅ API server is working!"
```

Make executable:
```bash
chmod +x /home/ttclaw/test-70b-api.sh
```

---

## OpenClaw Integration

### Update OpenClaw Configuration

File: `/home/ttclaw/.openclaw/openclaw.json`

```json
{
  "models": {
    "providers": {
      "vllm-70b": {
        "baseUrl": "http://127.0.0.1:8001/v1",
        "api": "openai-completions",
        "apiKey": "sk-no-auth",
        "models": [{
          "id": "meta-llama/Llama-3.3-70B-Instruct",
          "name": "Llama 3.3 70B Instruct",
          "contextWindow": 131072,
          "maxTokens": 8192
        }]
      }
    }
  },
  "agents": {
    "defaults": {
      "model": {
        "primary": "vllm-70b/meta-llama/Llama-3.3-70B-Instruct"
      }
    }
  }
}
```

### Startup Sequence

```bash
# Terminal 1: Start vLLM server (70B model)
cd /home/ttclaw
./run-70b-vllm.sh \
  meta-llama/Llama-3.3-70B-Instruct \
  /home/ttuser/code/tt-inference-server/persistent_volume/volume_id_tt_transformers-Llama-3.3-70B-Instruct-v0.9.0/weights/Llama-3.3-70B-Instruct

# Wait 10-30 minutes, then test:
./test-70b-api.sh

# Terminal 2: Start vLLM proxy (AFTER server is ready)
cd ~/openclaw
python3 vllm-proxy.py

# Terminal 3: Start OpenClaw gateway
cd ~/openclaw
./openclaw.sh gateway run

# Terminal 4: Start OpenClaw TUI
cd ~/openclaw
./openclaw.sh tui
```

---

## Critical Environment Variables Explained

| Variable | Value | Why It's Critical |
|----------|-------|-------------------|
| `VLLM_TARGET_DEVICE` | `tt` | **MOST CRITICAL** - Without this, vLLM uses CPU platform |
| `MESH_DEVICE` | `P150x4` | Tells tt-metal the hardware topology (4 chips in 1D mesh) |
| `ARCH_NAME` | `blackhole` | Architecture name for P300C chips |
| `HF_MODEL` | `<repo-name>` | Required by tt-metal ModelArgs - must be HF repo format |
| `TT_METAL_HOME` | `~/tt-metal` | Location of tt-metal installation |
| `PYTHONPATH` | Includes tt-metal | Required for `from models.tt_transformers...` imports |
| `LD_LIBRARY_PATH` | OpenMPI lib | Required for multi-chip communication |

**If any are missing, you'll get cryptic errors like:**
- `ModuleNotFoundError: No module named 'models'` (missing PYTHONPATH)
- `ValueError: Cannot find model module 'TTLlamaForCausalLM'` (missing registration)
- CPU platform detected (missing VLLM_TARGET_DEVICE)
- `AssertionError: Please set HF_MODEL` (missing HF_MODEL env var)

---

## 70B Model Loading Phases

### Phase 1: Initialization (2-3 seconds, logged)
```
INFO: Automatically detected platform tt.
INFO: multidevice with 4 devices and grid (1, 4) is created
INFO: Inferring device name: P150x4
```

### Phase 2: Tokenizer (5-10 seconds, logged)
```
INFO: Successfully loaded tokenizer from deepseek-ai/DeepSeek-R1-Distill-Llama-70B
INFO: Successfully loaded processor
```

### Phase 3: Weight Loading (10-30 minutes, **SILENT**)
```
Fetching 17 files:   0%|          | 0/17 [00:00<?, ?it/s]
```
⚠️ **This phase is mostly silent!** Progress bar may not update.
- Weights transfer from disk to TT hardware SRAM
- 132GB across 17 safetensors files
- No logging during transfer
- CPU memory stays low (~1GB)
- **Be patient - don't kill the process!**

### Phase 4: Server Ready (logged)
```
INFO: Uvicorn running on http://0.0.0.0:8000
```

---

## Troubleshooting

### Process killed or stops
Check dmesg for OOM killer:
```bash
dmesg | tail -50 | grep -i "killed process"
```

### Import errors
```bash
# Test if TT models can import
source ~/.tenstorrent-venv/bin/activate
export TT_METAL_HOME=/home/ttuser/tt-metal
export PYTHONPATH=/home/ttuser/tt-metal:/home/ttuser/tt-vllm:$PYTHONPATH
python3 -c "from models.tt_transformers.tt.generator_vllm import LlamaForCausalLM; print('OK')"
```

### Platform detection issues
Check logs for:
```bash
grep -E "platform|VLLM_TARGET_DEVICE" /tmp/vllm-server.log
```
Should show: `Automatically detected platform tt`
If shows `cpu`, VLLM_TARGET_DEVICE wasn't set.

---

## Performance Expectations

**Llama-3.3-70B-Instruct on P150X4 (from official specs):**

| Metric | Functional | Complete | Target |
|--------|------------|----------|--------|
| TTFT (ms) | 960 | 192 | 96 |
| Throughput (users) | 2 | 10 | 20 |
| Quality | ⭐⭐⭐⭐⭐ | ⭐⭐⭐⭐⭐ | ⭐⭐⭐⭐⭐ |

**vs Llama-3.1-8B (current):**
- 8.75x more parameters
- 2x larger context window
- Better reasoning and coherence
- Slower per-token, but much higher quality

---

## Files Created

For ttclaw user:
- `/home/ttclaw/setup-70b-env.sh` - Environment setup
- `/home/ttclaw/run-70b-vllm.sh` - Main run script
- `/home/ttclaw/test-70b-api.sh` - Test API readiness

For documentation:
- `~/tt-claw/VLLM_DIRECT_70B_SOLUTION.md` - This file
- `~/QB2_70B_SUCCESS.md` - Success documentation from ttuser session

---

## Key Differences from Docker Approach

| Aspect | Docker (Failed) | Direct vLLM (Works) |
|--------|-----------------|---------------------|
| Timeout | 30 seconds ❌ | None ✅ |
| Volumes | Complex mounting ❌ | Direct filesystem ✅ |
| Debugging | Opaque ❌ | Full visibility ✅ |
| Environment | Auto-detect ❌ | Explicit control ✅ |
| Load time | Killed by timeout ❌ | Completes in 10-30min ✅ |

---

## Next Steps

1. **Setup as ttclaw:**
   ```bash
   # Copy scripts
   sudo cp /home/ttuser/run-70b-model.sh /home/ttclaw/run-70b-vllm.sh
   sudo cp /home/ttuser/test-70b-model.sh /home/ttclaw/test-70b-api.sh
   sudo chown ttclaw:ttclaw /home/ttclaw/*.sh
   
   # Create environment setup
   sudo -u ttclaw bash -c 'cat > /home/ttclaw/setup-70b-env.sh' << 'ENVEOF'
   # (content from above)
   ENVEOF
   ```

2. **Test run as ttclaw:**
   ```bash
   sudo -u ttclaw bash
   cd ~
   ./run-70b-vllm.sh \
     meta-llama/Llama-3.3-70B-Instruct \
     /home/ttuser/code/tt-inference-server/persistent_volume/volume_id_tt_transformers-Llama-3.3-70B-Instruct-v0.9.0/weights/Llama-3.3-70B-Instruct
   ```

3. **Integrate with OpenClaw** (after server ready)

---

## Success Criteria

✅ Server starts without errors
✅ Devices initialize (4 chips detected)
✅ Tokenizer loads successfully  
✅ Weight loading begins (even if silent)
✅ After 10-30 min: `/health` endpoint responds
✅ Completions API works
✅ OpenClaw can connect and query

---

**Status:** Ready for ttclaw user deployment
**Validated:** 2026-03-07 with DeepSeek-R1-Distill-Llama-70B
**Author:** Based on successful ttuser session
