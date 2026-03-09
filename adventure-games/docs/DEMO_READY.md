# OpenClaw on Tenstorrent - Demo Ready Guide

**Date:** 2026-03-07
**Status:** Proxy solution implemented

## Problem Summary

OpenClaw sends OpenAI API fields (`strict`, `store`) that the vLLM version in Docker doesn't support, causing 400 errors.

## Solution: Compatibility Proxy

A simple Python proxy strips incompatible fields before forwarding to vLLM.

```
OpenClaw → Proxy (port 8001) → vLLM (port 8000) → Tenstorrent Hardware
```

## Files Created

- **`/home/ttclaw/openclaw/vllm-proxy.py`** - Production proxy (quiet)
- **`/home/ttclaw/openclaw/vllm-proxy-debug.py`** - Debug proxy (verbose logging)

## Configuration

OpenClaw is configured to:
- Use provider: `vllm`
- Base URL: `http://127.0.0.1:8001/v1` (proxy port)
- Model: `meta-llama/Llama-3.1-8B-Instruct`
- API mode: `openai-completions`

## Usage (3 Terminals)

### Terminal 1: Start Proxy
```bash
cd ~/openclaw
python3 vllm-proxy.py

# Or for debugging:
python3 vllm-proxy-debug.py
```

### Terminal 2: Start OpenClaw Gateway
```bash
cd ~/openclaw
./openclaw.sh gateway run
```

### Terminal 3: Start TUI
```bash
cd ~/openclaw
./openclaw.sh tui
```

Then send messages in the TUI!

## Troubleshooting

### If proxy fails to start
```bash
# Check if port 8001 is in use
netstat -tlnp | grep 8001

# Kill existing process if needed
pkill -f vllm-proxy
```

### If still getting errors
Use the debug proxy to see what's happening:
```bash
cd ~/openclaw
python3 vllm-proxy-debug.py
```

It will print all requests and responses.

### If vLLM is down
```bash
# Check vLLM status
curl http://localhost:8000/health

# Check Docker container
docker ps | grep tt-inference

# View vLLM logs
docker logs tt-inference-server-61c8a9c5 | tail -50
```

## What the Proxy Does

1. Receives request from OpenClaw (port 8001)
2. Strips incompatible fields:
   - `strict`
   - `store`
   - `prompt_cache_key`
3. Forwards clean request to vLLM (port 8000)
4. Returns vLLM's response to OpenClaw

## Architecture

```
┌──────────┐           ┌───────┐           ┌──────┐           ┌────────────┐
│ OpenClaw │  :8001    │ Proxy │  :8000    │ vLLM │           │ Tenstorrent│
│   TUI    │ ────────> │ Strip │ ────────> │Docker│ ────────> │  4x P300C  │
└──────────┘           └───────┘           └──────┘           └────────────┘
```

## Files Modified

- `/home/ttclaw/.openclaw/openclaw.json` - Global config pointing to proxy
- `/home/ttclaw/.openclaw/agents/main/agent/models.json` - Agent config
- All sessions cleared for fresh start

## Next Steps if Errors Persist

If the proxy setup still gives errors, we can:
1. Try Ollama API mode (different request format)
2. Use native tt-inference-server client (skip vLLM OpenAI API)
3. Upgrade vLLM version (but requires Docker rebuild)
4. Add more field stripping to proxy

## Success Criteria

✅ Proxy starts on port 8001  
✅ OpenClaw gateway starts without auth errors  
✅ TUI connects to gateway  
⏳ Send message and get response from LLM  

---

**Last Updated:** 2026-03-07
**Location:** ~/tt-claw/DEMO_READY.md
