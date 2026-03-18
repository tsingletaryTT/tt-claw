# vLLM Compatibility Proxy for OpenClaw

This proxy solves an API compatibility issue between OpenClaw v2026.3.2 and the vLLM version running in Docker.

## The Problem

**OpenClaw v2026.3.2** uses the latest OpenAI API specification, which includes these fields:
- `strict` - For structured output validation
- `store` - For conversation persistence
- `prompt_cache_key` - For prompt caching

**vLLM (Docker version)** doesn't support these newer fields. Even though vLLM logs say the fields are "ignored", it still returns `400 Bad Request` errors, causing OpenClaw requests to fail.

## The Solution

This proxy sits between OpenClaw and vLLM:

```
OpenClaw (port 8001) → Proxy (strips fields) → vLLM (port 8000) → Tenstorrent
```

**What it does:**
1. Receives requests from OpenClaw on port 8001
2. Strips `strict`, `store`, and `prompt_cache_key` from the request
3. Forwards the clean request to vLLM on port 8000
4. Returns vLLM's response back to OpenClaw

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

### Why Not Fix vLLM?

The vLLM version is locked in the Docker image (can't upgrade easily). Even if we could upgrade, the proxy approach is:
- **Simpler** - No Docker rebuild required
- **Safer** - Doesn't modify vLLM internals
- **Portable** - Works with any vLLM version

### Alternatives

**Option 1: Downgrade OpenClaw** ❌
Would lose features and compatibility with newer models.

**Option 2: Upgrade vLLM** ⚠️
Requires rebuilding Docker image, may break Tenstorrent optimizations.

**Option 3: This proxy** ✅
Simple, non-invasive, works with existing setup.

## See Also

- **`START_SERVICES.md`** - Complete service startup guide
- **`INSTALLATION.md`** - Full installation instructions
- **`OPENCLAW_FINAL_INSTRUCTIONS.md`** - OpenClaw + vLLM setup details
