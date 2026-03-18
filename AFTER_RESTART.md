# After Restart - 70B Tool Calling Setup

## Quick Start Command

After reboot, run this:

```bash
cd /home/ttuser/code/tt-inference-server

docker run \
  --rm \
  --name tt-inference-server-70b \
  --env-file .env \
  --ipc host \
  --publish 0.0.0.0:8000:8000 \
  --device /dev/tenstorrent:/dev/tenstorrent \
  --mount type=bind,src=/dev/hugepages-1G,dst=/dev/hugepages-1G \
  --volume volume_id_tt_transformers-Llama-3.3-70B-Instruct:/home/container_app_user/cache_root \
  -e CACHE_ROOT=/home/container_app_user/cache_root \
  -d \
  ghcr.io/tenstorrent/tt-inference-server/vllm-tt-metal-src-dev-ubuntu-22.04-amd64:0.9.0-e867533-22be241 \
  --model meta-llama/Llama-3.3-70B-Instruct \
  --tt-device p300x2 \
  --no-auth \
  --enable-auto-tool-choice \
  --tool-call-parser llama3_json
```

## Monitor Progress

```bash
# Watch logs
docker logs -f tt-inference-server-70b

# Check for tool calling flags in logs:
# Should see: "enable_auto_tool_choice': True, 'tool_call_parser': 'llama3_json"
```

## After Warmup (20-30 min)

```bash
# Test tool calling
curl http://localhost:8000/health

# Restart OpenClaw
cd ~/tt-claw
./bin/tt-claw restart
./bin/tt-claw tui
```

## What Was Fixed

- ✅ TUI port: Now uses 18789 (default)
- ✅ Tool calling flags: Added to Docker command
- ✅ Hardware: Reset with tt-smi -r

## Model Already Downloaded

The 140GB model weights are cached in Docker volume, so startup will be faster.

---

**See Also:**
- `TOOL_CALLING_FIX.md` - Full diagnosis
- `TUI_CONNECTION_FIX.md` - Port fix details
