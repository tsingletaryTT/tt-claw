# Starting Services for TT-CLAW Adventure Games

## What Services Are Needed?

For TT-CLAW adventure games to work, you need **3 services** running:

### 1. vLLM Server (port 8000)
**What:** AI inference backend running on Tenstorrent hardware
**Why:** Generates game responses using large language model

**Check if running:**
```bash
curl http://localhost:8000/health
```

**Start if needed:**
```bash
# If using tt-inference-server Docker:
cd ~/code/tt-inference-server
python3 run.py --model <model-name> --workflow server --docker-server

# Or direct vLLM:
cd ~
./run-70b-vllm.sh <model-path>
```

---

### 2. vLLM Proxy (port 8001)
**What:** Compatibility layer between OpenClaw and vLLM
**Why:** OpenClaw sends newer OpenAI API fields (`strict`, `store`) that the vLLM version doesn't support. The proxy strips these incompatible fields before forwarding to vLLM.

**Architecture:**
```
OpenClaw → Proxy (8001) → vLLM (8000) → Tenstorrent Hardware
           strips fields
```

**Check if running:**
```bash
curl http://localhost:8001/v1/models
```

**Start:**
```bash
cd ~/openclaw
python3 vllm-proxy.py
```

**Debug mode (see all requests):**
```bash
cd ~/openclaw
python3 vllm-proxy-debug.py
```

---

### 3. OpenClaw Gateway (port 18789)
**What:** WebSocket server that manages agent sessions
**Why:** Handles game state, agent routing, and TUI connections

**Check if running:**
```bash
netstat -tlnp | grep 18789
# or
pgrep -f "openclaw.*gateway"
```

**Start:**
```bash
cd ~/openclaw
./openclaw.sh gateway run
```

---

## Quick Start (Recommended Order)

### Terminal 1: vLLM Server
```bash
# If not already running, start vLLM
# (Usually started once and left running)
curl http://localhost:8000/health
```

### Terminal 2: Proxy
```bash
cd ~/openclaw
python3 vllm-proxy.py
```
**Wait for:** `Proxy listening on port 8001`

### Terminal 3: Gateway
```bash
cd ~/openclaw
./openclaw.sh gateway run
```
**Wait for:** `[gateway] listening on ws://127.0.0.1:18789`

### Terminal 4: Adventure Menu
```bash
cd ~/tt-claw/adventure-games/scripts
./adventure-menu.sh
```

---

## All-in-One Script (Background Services)

If you want to start proxy + gateway in the background:

```bash
#!/bin/bash
# start-adventure-services.sh

# Start proxy in background
cd ~/openclaw
nohup python3 vllm-proxy.py > /tmp/vllm-proxy.log 2>&1 &
PROXY_PID=$!
echo "Started proxy (PID: $PROXY_PID)"

# Wait for proxy to be ready
sleep 2
if ! curl -s http://localhost:8001/v1/models > /dev/null; then
    echo "ERROR: Proxy failed to start!"
    tail /tmp/vllm-proxy.log
    kill $PROXY_PID 2>/dev/null
    exit 1
fi

echo "✓ Proxy ready"

# Start gateway in background
nohup ./openclaw.sh gateway run > /tmp/openclaw-gateway.log 2>&1 &
GATEWAY_PID=$!
echo "Started gateway (PID: $GATEWAY_PID)"

# Wait for gateway to be ready
sleep 3
if ! pgrep -f "openclaw.*gateway" > /dev/null; then
    echo "ERROR: Gateway failed to start!"
    tail /tmp/openclaw-gateway.log
    kill $GATEWAY_PID 2>/dev/null
    kill $PROXY_PID 2>/dev/null
    exit 1
fi

echo "✓ Gateway ready"
echo ""
echo "All services started!"
echo "  Proxy logs:   tail -f /tmp/vllm-proxy.log"
echo "  Gateway logs: tail -f /tmp/openclaw-gateway.log"
echo ""
echo "To stop services:"
echo "  kill $PROXY_PID $GATEWAY_PID"
```

Save as `~/openclaw/start-adventure-services.sh` and run:
```bash
chmod +x ~/openclaw/start-adventure-services.sh
~/openclaw/start-adventure-services.sh
```

---

## Troubleshooting

### Proxy Timeout Error

**Symptoms:**
- `curl http://localhost:8001/v1/models` hangs or times out
- Proxy script shows no output
- Adventure menu says "vLLM proxy not responding"

**Causes:**
1. **vLLM backend not running** - Proxy forwards to port 8000, which must be up first
2. **Port 8001 already in use** - Another process using the port
3. **Python script error** - Check if proxy script has syntax errors

**Diagnosis:**
```bash
# Check vLLM backend
curl http://localhost:8000/health
# Should return: {"status":"ok"} or similar

# Check port 8001
netstat -tlnp | grep 8001
# Should show python3 process if proxy running

# Test proxy directly
curl -X POST http://localhost:8001/v1/models
# Should return model list

# Check proxy logs (if running in background)
tail -f /tmp/vllm-proxy.log
```

**Fix:**
```bash
# 1. Start vLLM first (if not running)
cd ~/code/tt-inference-server
python3 run.py --model Llama-3.1-8B-Instruct --workflow server --docker-server

# 2. Wait for vLLM to be fully ready
curl http://localhost:8000/health
# Wait until this returns successfully

# 3. Then start proxy
cd ~/openclaw
python3 vllm-proxy.py
```

### Gateway Won't Start

**Symptoms:**
- `./openclaw.sh gateway run` exits immediately
- Port 18789 shows nothing

**Causes:**
1. OpenClaw not installed correctly
2. Node.js version too old
3. Missing dependencies

**Fix:**
```bash
# Check OpenClaw installation
cd ~/openclaw
./openclaw.sh --version

# Reinstall if needed
cd ~/tt-claw/adventure-games/scripts
./install-openclaw.sh

# Check Node.js
node --version  # Should be v18+

# Check dependencies
cd ~/openclaw
npm install
```

### Port Already in Use

**Symptoms:**
- Error: "EADDRINUSE: address already in use"

**Fix:**
```bash
# Find and kill process using port
# For proxy (8001):
lsof -ti:8001 | xargs kill -9

# For gateway (18789):
lsof -ti:18789 | xargs kill -9

# Or kill by name:
pkill -f vllm-proxy
pkill -f openclaw.*gateway
```

---

## Why Do I Need the Proxy?

**Short answer:** OpenClaw and vLLM speak slightly different versions of the OpenAI API.

**Long answer:**

OpenClaw v2026.3.2 uses the latest OpenAI API spec, which includes fields like:
- `strict` - For structured output validation
- `store` - For conversation persistence
- `prompt_cache_key` - For prompt caching

The vLLM version (locked in Docker) doesn't support these newer fields. Even though vLLM logs say "ignored", it still returns `400 Bad Request` errors, causing OpenClaw requests to fail.

**The proxy solution:**
1. Receives requests from OpenClaw (with `strict`, `store` fields)
2. Strips the incompatible fields
3. Forwards clean request to vLLM
4. Returns vLLM's response to OpenClaw

**Code snippet:**
```python
# vllm-proxy.py (simplified)
data = json.loads(request_body)

# Remove incompatible fields
data.pop('strict', None)
data.pop('store', None)
data.pop('prompt_cache_key', None)

# Clean messages too
for msg in data.get('messages', []):
    msg.pop('strict', None)

# Forward to vLLM
response = requests.post('http://localhost:8000/v1/...', json=data)
```

**Can I skip the proxy?**
No - without it, OpenClaw's requests will fail with 400 errors and games won't work.

---

## Service Dependencies

```
vLLM (port 8000)
   ↓ (must be running first)
Proxy (port 8001)
   ↓ (must be running second)
Gateway (port 18789)
   ↓ (must be running third)
Adventure Menu
```

**Critical:** Start in this order! Proxy needs vLLM, Gateway needs Proxy (via OpenClaw config).
