# Deploy 70B Model on QB2 - When Ready

## Current Status (Working)
- ✅ Llama-3.1-8B-Instruct on p150 (single chip)
- ✅ Tool calling enabled
- ✅ OpenClaw configured and working

## Next Step: Llama-3.3-70B-Instruct on P150X4

### Model Details
- **Name:** Llama-3.3-70B-Instruct
- **Device:** P150X4 (all 4 Blackhole chips)
- **Size:** ~140GB download
- **Docker:** `ghcr.io/tenstorrent/tt-inference-server/vllm-tt-metal-src-release-ubuntu-22.04-amd64:0.9.0-55fd115-aa4ae1e`
- **Context:** 131K tokens
- **Batch:** 32 sequences max

### Deployment Command

```bash
cd /home/ttuser/code/tt-inference-server

# Stop current 8B server first
docker stop $(docker ps -q --filter ancestor=*tt-inference-server*) 2>/dev/null || true

# Deploy 70B on all 4 chips
python3 run.py \
  --model Llama-3.3-70B-Instruct \
  --tt-device p150x4 \
  --workflow server \
  --docker-server \
  --no-auth \
  --vllm-override-args '{"enable_auto_tool_choice": true, "tool_call_parser": "llama3_json"}'
```

### Timeline Expectations

**First-time deployment:**
1. **Docker pull:** 2-5 minutes (image is ~15GB)
2. **Model download:** 30-45 minutes (~140GB from HuggingFace)
   - Requires HF_TOKEN for meta-llama models
   - Set: `export HF_TOKEN="your_token_here"`
3. **Model initialization:** 40-60 minutes
   - Hardware init: ~1 minute
   - Weight loading: ~15 minutes
   - TT cache generation: ~20 minutes
   - Model warmup/trace: ~25-40 minutes

**Total: 70-110 minutes first time**

**Subsequent runs (model cached):**
- Skip download
- ~40-60 minutes init only

### Known Risks

⚠️ **Trace compilation hang:**
- Previous DeepSeek-R1-70B attempt got stuck in trace compilation for 2.5+ hours
- This is a different model/version, may work better
- Monitor logs carefully

⚠️ **If deployment hangs:**
- Check `docker logs -f <container_id>` for progress
- Look for: "warming up prefill", "decode_forward", etc.
- If stuck >60 min with no log output = likely hung

### Monitoring

**Check health:**
```bash
# In another terminal
docker ps  # Get container ID
docker logs -f <container_id>  # Watch logs

# When ready (appears "healthy"):
curl http://localhost:8000/health
```

**Expected log progression:**
1. "Detected 4 devices"
2. "Mesh device created"
3. "Loading checkpoint shards" (17/17 for 70B)
4. "Allocated TT KV caches"
5. "Warming up prefill for sequence length: 128"
6. "Starting prefill_forward_text" (this is where it might hang)
7. Eventually: "Application startup complete"

### What Changes for OpenClaw

**Nothing!** OpenClaw config stays the same - it just talks to port 8000.

The vLLM server on port 8000 will now be serving the 70B model instead of 8B.

### Rollback to 8B

If 70B doesn't work or is too slow:

```bash
# Stop 70B
docker stop $(docker ps -q --filter ancestor=*tt-inference-server*)

# Restart 8B
cd /home/ttuser/code/tt-inference-server
python3 run.py \
  --model Llama-3.1-8B-Instruct \
  --tt-device p150 \
  --workflow server \
  --docker-server \
  --override-docker-image "ghcr.io/tenstorrent/tt-inference-server/vllm-tt-metal-src-dev-ubuntu-22.04-amd64:0.10.0-84b4c53-222ee06" \
  --no-auth \
  --vllm-override-args '{"enable_auto_tool_choice": true, "tool_call_parser": "llama3_json"}'
```

### HuggingFace Access

**Required:** You need HF access to meta-llama models

1. Go to: https://huggingface.co/meta-llama/Llama-3.3-70B-Instruct
2. Request access (usually instant approval)
3. Get your token: https://huggingface.co/settings/tokens
4. Export before running:
   ```bash
   export HF_TOKEN="hf_xxxxxxxxxxxxxxxxxxxx"
   ```

### Performance Comparison

**8B on 1 chip (current):**
- TTFT: ~100ms
- Throughput: ~50 tokens/sec
- Context: 128K

**70B on 4 chips (expected):**
- TTFT: ~200-300ms (slower)
- Throughput: ~20-30 tokens/sec (slower but smarter)
- Context: 131K
- **Much better quality responses!**

### When to Try This

- ✅ When you have 2+ hours of monitoring time
- ✅ When system is stable and not being used for other work
- ✅ When you want significantly smarter responses
- ❌ Not when you need quick turnaround
- ❌ Not right before a demo

### Success Criteria

✅ Container starts without errors
✅ All 4 chips detected and initialized
✅ Model weights loaded (140GB)
✅ Warmup completes (doesn't hang)
✅ `/health` returns 200
✅ Test prompt generates response
✅ OpenClaw can use it

Good luck! 🚀
