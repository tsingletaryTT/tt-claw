# vLLM Compatibility Proxy for OpenClaw

> **Status (2026-04-18): The proxy is no longer needed.** All current TT vLLM Docker
> images have `OpenAIBaseModel` with `extra="allow"` in `protocol.py`, which silently
> accepts and ignores unknown fields including `strict`, `store`, and `prompt_cache_key`.
> You can point OpenClaw directly at port 8000. See "Removing the Proxy" below for the
> clean options, including the defense-in-depth vLLM `--middleware` approach.

This proxy was created to solve an API compatibility issue between OpenClaw v2026.3.2
and an older vLLM Docker image. It is now obsolete.

## Why It Was Needed (Historical)

**OpenClaw v2026.3.2** sends newer OpenAI API fields at the top level of chat completions:
- `strict` - structured output validation flag
- `store` - Responses API persistence flag
- `prompt_cache_key` - prompt caching key

**vLLM (Docker version)** at the time returned `400 Bad Request` on these fields.

## Why It's No Longer Needed

All available TT vLLM images — including the original `0.9.0-e867533-22be241` that
motivated the proxy — define `OpenAIBaseModel` with `model_config = ConfigDict(extra="allow")`.
This means unknown top-level fields in `/v1/chat/completions` are silently accepted and
ignored. Confirmed in images:

- `0.9.0-e867533-22be241` (proxy-era)  → `extra="allow"` ✓
- `0.9.0-555f240-22be241` (current)   → `extra="allow"` ✓
- `0.10.0-84b4c53-222ee06` (latest)   → `extra="allow"` ✓

## Removing the Proxy

### Option A: Point OpenClaw directly at port 8000 (no code changes)

Edit `~/tt-claw/runtime/openclaw.json`:

```json
"vllm": {
    "baseUrl": "http://127.0.0.1:8000/v1",
    ...
}
```

Stop the proxy process (`pkill -f vllm-proxy`). Done.

### Option B: Defense-in-depth via vLLM's `--middleware` flag

vLLM has a built-in `--middleware` CLI argument (added to `EngineArgs` in
`cli_args.py:131`) that accepts importable Python callables injected as ASGI
middleware before any request reaches Pydantic parsing. This is the server-side
solution that survives future vLLM changes.

`openclaw_compat_middleware.py` in this directory is the middleware implementation.
To deploy it:

1. **Bind-mount the middleware into the container** by patching `run_docker_server.py`
   (same approach as `tt-local-generator/apply_patches.sh`):

   ```python
   # Add to run_docker_server.py before docker_command build loop
   _compat_mw = Path("/home/ttuser/tt-claw/proxy/openclaw_compat_middleware.py")
   if _compat_mw.exists():
       docker_command += [
           "--mount",
           f"type=bind,src={_compat_mw},"
           "dst=/home/container_app_user/tt-metal/openclaw_compat_middleware.py,"
           "readonly",
       ]
   ```

2. **Add `--middleware` to `vllm_override_args`** in model_spec.py or via run.py:

   ```bash
   python3 run.py \
       --model Llama-3.3-70B-Instruct \
       --tt-device p300x2 \
       --workflow server \
       --docker-server \
       --no-auth \
       --vllm-override-args '{
           "enable_auto_tool_choice": true,
           "tool_call_parser": "llama3_json",
           "middleware": ["openclaw_compat_middleware.OpenClawCompatMiddleware"]
       }'
   ```

   vLLM loads it via `importlib.import_module("openclaw_compat_middleware")` with
   `PYTHONPATH` including `/home/container_app_user/tt-metal/` (the container's
   `TT_METAL_HOME`).

## The Proxy (Legacy)

This proxy sits between OpenClaw and vLLM:

## Installation

### Automatic (with OpenClaw installation)

The proxy is automatically installed when you run:
```bash
cd ~/tt-claw/adventure-games/scripts
./install-openclaw.sh
```

### Standalone (if OpenClaw already installed)

```bash
cd ~/tt-claw/adventure-games/scripts
./install-proxy.sh
```

This copies `vllm-proxy.py` to `~/openclaw/vllm-proxy.py`

### Manual

```bash
cp ~/tt-claw/openclaw-proxy/vllm-proxy.py ~/openclaw/
chmod +x ~/openclaw/vllm-proxy.py
```

## Usage

### Start the proxy

```bash
cd ~/openclaw
python3 vllm-proxy.py
```

**Output:**
```
vLLM Compatibility Proxy listening on port 8001
Forwarding to: http://localhost:8000
Stripping fields: strict, store, prompt_cache_key

Press Ctrl+C to stop
```

### Verify it's working

```bash
# Check proxy is responding
curl http://localhost:8001/v1/models

# Should return vLLM model list (same as port 8000)
```

### Use with OpenClaw

Update `~/.openclaw/openclaw.json`:
```json
{
  "models": {
    "providers": {
      "vllm": {
        "baseUrl": "http://127.0.0.1:8001/v1",  // ← Port 8001 (proxy)
        "apiKey": "sk-no-auth",
        "models": [...]
      }
    }
  }
}
```

## Automated Startup

Use the service startup script:
```bash
cd ~/tt-claw/adventure-games/scripts
./start-adventure-services.sh
```

This starts both the proxy and OpenClaw gateway in the background.

## Troubleshooting

### Proxy won't start

**Check vLLM is running first:**
```bash
curl http://localhost:8000/health
```

The proxy forwards to port 8000, so vLLM must be running before starting the proxy.

### Port already in use

```bash
# Kill existing proxy
pkill -f vllm-proxy

# Or kill by port
lsof -ti:8001 | xargs kill -9
```

### Proxy times out

**Check vLLM backend:**
```bash
# Test vLLM directly
curl http://localhost:8000/v1/models

# If this times out, vLLM has issues (not the proxy)
```

**Check proxy logs (if running in background):**
```bash
tail -f /tmp/vllm-proxy.log
```

### Requests still failing

**Verify OpenClaw is using port 8001:**
```bash
grep baseUrl ~/.openclaw/openclaw.json
# Should show: "baseUrl": "http://127.0.0.1:8001/v1"
```

**Test the full chain:**
```bash
# Test proxy with actual request
curl -X POST http://localhost:8001/v1/chat/completions \
  -H 'Content-Type: application/json' \
  -d '{
    "model": "meta-llama/Llama-3.1-8B-Instruct",
    "messages": [{"role": "user", "content": "Hello"}],
    "strict": true
  }'

# Proxy should strip "strict" field and forward to vLLM
```

## Technical Details

### Code Structure

```python
class ProxyHandler(BaseHTTPRequestHandler):
    def do_POST(self):
        # Read request
        data = json.loads(body)

        # Strip incompatible fields
        data.pop('strict', None)
        data.pop('store', None)
        data.pop('prompt_cache_key', None)

        # Clean messages
        for msg in data.get('messages', []):
            msg.pop('strict', None)

        # Forward to vLLM
        requests.post('http://localhost:8000/v1/...', json=data)
```

### Why Not Fix vLLM? (Now Moot)

As of all current TT vLLM images, vLLM already accepts extra fields silently.
The right long-term approach if you need explicit stripping is the `--middleware`
flag described in "Option B" above — no Docker rebuild, no image modification,
no separate proxy process.

## See Also

- **`START_SERVICES.md`** - Complete service startup guide
- **`INSTALLATION.md`** - Full installation instructions
- **`OPENCLAW_FINAL_INSTRUCTIONS.md`** - OpenClaw + vLLM setup details
