# vLLM Docker Command with Tool Calling Support

**Date:** March 11, 2026
**Issue:** OpenClaw requires `--enable-auto-tool-choice` and `--tool-call-parser` flags for proper agent operation

## The Working Command

This Docker command successfully starts vLLM with tool calling support for OpenClaw:

```bash
docker run \
  --rm \
  --name tt-inference-server-manual \
  --env-file /home/ttuser/code/tt-inference-server/.env \
  --ipc host \
  --publish 8000:8000 \
  --device /dev/tenstorrent:/dev/tenstorrent \
  --mount type=bind,src=/dev/hugepages-1G,dst=/dev/hugepages-1G \
  --volume volume_id_tt_transformers-Llama-3.1-8B-Instruct:/home/container_app_user/cache_root \
  -e CACHE_ROOT=/home/container_app_user/cache_root \
  -d \
  ghcr.io/tenstorrent/tt-inference-server/vllm-tt-metal-src-dev-ubuntu-22.04-amd64:0.10.0-84b4c53-222ee06 \
  --model meta-llama/Llama-3.1-8B-Instruct \
  --tt-device p150 \
  --no-auth \
  --enable-auto-tool-choice \
  --tool-call-parser llama3_json
```

## Key Arguments

### Required for OpenClaw
- `--enable-auto-tool-choice` - Enables automatic tool selection
- `--tool-call-parser llama3_json` - Uses Llama 3's JSON tool calling format

### Standard Arguments
- `--model meta-llama/Llama-3.1-8B-Instruct` - The model to load
- `--tt-device p150` - Target Tenstorrent device
- `--no-auth` - Disable authentication (local use)

### Docker Configuration
- `--publish 8000:8000` - Expose vLLM API on port 8000
- `--device /dev/tenstorrent:/dev/tenstorrent` - Pass through TT hardware
- `--volume volume_id_tt_transformers-Llama-3.1-8B-Instruct:...` - Persistent model cache

## Why This is Necessary

### Problem
The `tt-inference-server/run.py` wrapper doesn't properly forward tool calling arguments via `--vllm-override-args`. The JSON parsing fails or arguments don't reach the vLLM process.

### Solution
Bypass `run.py` and run Docker directly with explicit arguments. This gives full control over vLLM startup parameters.

## Startup Process

1. **Hardware Reset** (after suspend/resume):
   ```bash
   tt-smi -r
   ```

2. **Start vLLM** with tool calling support (command above)

3. **Wait for warmup** (~5-10 minutes):
   - Model loading
   - Trace compilation
   - Background trace capture

4. **Verify readiness**:
   ```bash
   docker logs <container-id> 2>&1 | grep "Readiness file created"
   ```

5. **Start proxy** (for OpenClaw):
   ```bash
   cd ~/openclaw && python3 vllm-proxy.py &
   ```

6. **Start OpenClaw gateway**:
   ```bash
   cd /home/ttclaw/openclaw && sudo -u ttclaw ./openclaw.sh gateway run &
   ```

## Testing Tool Calling

Test that tool calling is enabled:

```bash
curl -s http://localhost:8000/v1/chat/completions \
  -H "Content-Type: application/json" \
  -d '{
    "model": "meta-llama/Llama-3.1-8B-Instruct",
    "messages": [{"role": "user", "content": "What is 2+2?"}],
    "tools": [{"type": "function", "function": {"name": "calculate"}}],
    "tool_choice": "auto"
  }'
```

Should return 200 OK with tool call suggestions.

## Container Management

### Check status:
```bash
docker ps | grep tt-inference-server
```

### View logs:
```bash
docker logs -f tt-inference-server-manual
```

### Stop:
```bash
docker stop tt-inference-server-manual
```

### Restart after changes:
```bash
docker stop tt-inference-server-manual
# Wait for cleanup
sleep 5
# Run command above
```

## Performance

With tool calling enabled:
- **TTFT**: 185-600ms (depending on context length)
- **TPOT**: 67-200ms
- **Max context**: 65,536 tokens
- **Warmup time**: ~5-10 minutes

## Related Documentation

- **OpenClaw Setup:** `OPENCLAW_MEMORY_SEARCH_SETUP.md`
- **Quick Reference:** `OPENCLAW_MEMORY_QUICK_REF.md`
- **Testing:** `test-openclaw-memory.sh`
- **Main Journey:** `../../CLAUDE.md`

## Status

✅ **Working** as of March 11, 2026
- Container starts successfully
- Tool calling enabled and functional
- OpenClaw connects without errors
- Memory search operational
