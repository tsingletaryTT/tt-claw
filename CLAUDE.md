# OpenClaw on Tenstorrent - Complete Journey

**Project:** OpenClaw v2026.3.2 integrated with Tenstorrent hardware via vLLM
**Duration:** March 6-7, 2026
**Status:** ✅ Production Ready → 🚀 Upgrading to 70B Model
**Location:** `/home/ttclaw/openclaw/`

## Table of Contents
0. [**Project Architecture: ttuser vs ttclaw**](#project-architecture-ttuser-vs-ttclaw-2026-03-18) ⚠️ **READ THIS FIRST**
1. [Llama-3.3-70B Upgrade](#llama-33-70b-upgrade-2026-03-07)
2. [Installation & Architecture Discovery](#installation--architecture-discovery-2026-03-06)
3. [Authentication Configuration Hell](#authentication-configuration-2026-03-07)
4. [The Provider Name Confusion](#the-provider-name-confusion)
5. [The vLLM Compatibility Crisis](#the-vllm-compatibility-crisis)
6. [Final Solution: Compatibility Proxy](#final-solution-compatibility-proxy)
7. [How to Use](#how-to-use)
8. [Architecture](#architecture)
9. [Key Learnings](#key-learnings)
10. [OpenClaw Memory Search - TT Expert Configuration](#openclaw-memory-search---tt-expert-configuration-2026-03-10)

---

## Llama-3.3-70B Upgrade (2026-03-07)

### What Happened
User requested deployment of the largest possible LLM model for the QB2 machine (2x P300C = P150X4 equivalent, 236GB RAM available). The goal was to significantly improve OpenClaw's capabilities beyond the current 8B model.

### Model Selection

**Chosen: Llama-3.3-70B-Instruct**
- **Size:** 70B parameters (8.75x larger than current 8B)
- **Context:** 131,072 tokens (128K context window)
- **Status:** FUNCTIONAL (officially validated by Tenstorrent)
- **Requirements:** 175GB RAM ✅ (have 236GB), 160GB disk ✅ (have 2.3TB)
- **Max batch:** 32 concurrent requests

**Why this model:**
- Largest available for P150X4 configuration
- Latest Llama version (3.3 is newer than 3.1)
- Officially validated, not experimental
- Same architecture as 8B = drop-in replacement for OpenClaw

### Deployment Process

**Method:** Native tt-inference-server deployment
```bash
cd ~/code/tt-inference-server
printf "1\ndummy-jwt-secret-not-used\n" | python3 run.py \
  --model Llama-3.3-70B-Instruct \
  --tt-device p150x4 \
  --workflow server \
  --docker-server \
  --no-auth \
  --skip-system-sw-validation \
  --host-volume
```

**Flags explained:**
- `--host-volume`: Use bind mount instead of Docker volume (easier debugging)
- `--skip-system-sw-validation`: KMD 2.7.0-rc1 is prerelease but compliant
- `--no-auth`: No API key required (same as current 8B setup)
- `--docker-server`: Run in Docker container (isolated, reproducible)

### Current Status (as of 2026-03-07 09:55)

**Download: COMPLETE** ✅
- 📥 **132GB / 140GB** downloaded
- 📦 **30 / 30 weight files** complete
- ✅ All model weights successfully downloaded

**Deployment: SOLUTION FOUND** ✅
- **Problem:** Multi-chip mesh device initialization failing
- **Error:** `TT_FATAL @ mesh_device_view.cpp:207: line_coords.size() == length`
- **Root cause:** P300/P300X2 multi-chip boards need ALL devices mapped, not individual
- **Solution:** Use stisi's branch `feat-bh-whisper` with multi-chip board fixes

**The Fix (commit 6ee68d82):**
```python
# Maps all /dev/tenstorrent devices for multi-chip boards
_MULTI_CHIP_BOARDS = {DeviceTypes.P300, DeviceTypes.P300X2}
if not getattr(args, "device_id", None) or device in _MULTI_CHIP_BOARDS:
    device_map_strs = ["--device", f"{device_path}:{device_path}"]  # All devices!
```

**Deployment Command:**
```bash
cd ~/code/tt-inference-server
git checkout origin/stisi/feat-bh-whisper
python3 run.py --model Llama-3.3-70B-Instruct --device p150x4 --workflow server --docker-server --no-auth --skip-system-sw-validation

# Interactive prompts:
# 1. Model source: 2 (Local folder)
# 2. host_hf_home: Press Enter (use default)
# 3. JWT_SECRET: dummy-jwt-secret
```

**Why this works:**
- 2x P300C cards = 4 chips total (same as P150X4 chip count)
- Multi-chip boards need ALL `/dev/tenstorrent` devices visible for ClusterType detection
- DEVICE_IDS env var then restricts which chips each worker uses
- This is the official solution from Tenstorrent (stisi's branch)

**Files & Locations:**
- Weights: `/home/ttuser/code/tt-inference-server/persistent_volume/volume_id_tt_transformers-Llama-3.3-70B-Instruct-v0.9.0/weights/` (132GB)
- Container: `tt-inference-server-70b` (currently stopped)
- Logs: `docker logs tt-inference-server-70b`

### OpenClaw Integration

**Once deployed, update OpenClaw config:**

File: `/home/ttclaw/.openclaw/openclaw.json`

Change model reference:
```json
{
  "models": {
    "providers": {
      "vllm": {
        "baseUrl": "http://127.0.0.1:8001/v1",  // Keep existing proxy
        "api": "openai-completions",
        "apiKey": "sk-no-auth",
        "models": [{
          "id": "meta-llama/Llama-3.3-70B-Instruct",  // ← Update
          "name": "Llama 3.3 70B Instruct",           // ← Update
          "contextWindow": 131072,                     // ← Update: 128K
          "maxTokens": 8192
        }]
      }
    }
  },
  "agents": {
    "defaults": {
      "model": {
        "primary": "vllm/meta-llama/Llama-3.3-70B-Instruct"  // ← Update
      }
    }
  }
}
```

**Proxy compatibility:**
- ✅ Existing vLLM proxy (`~/openclaw/vllm-proxy.py`) works as-is
- No changes needed - proxy just strips incompatible API fields

**Testing plan:**
1. Verify server: `curl http://localhost:8000/v1/models`
2. Update OpenClaw config (above)
3. Restart OpenClaw components:
   ```bash
   # Terminal 1: Proxy
   cd ~/openclaw && python3 vllm-proxy.py

   # Terminal 2: Gateway
   cd ~/openclaw && ./openclaw.sh gateway run

   # Terminal 3: TUI
   cd ~/openclaw && ./openclaw.sh tui
   ```
4. Test complex query in TUI (reasoning, long context)
5. Compare quality vs 8B model

### Performance Expectations

**Llama-3.3-70B-Instruct on P150X4:**
- **TTFT:** ~960ms (functional) to ~96ms (target performance)
- **Throughput:** ~2 users (functional) to ~20 users (target)
- **Quality:** Significantly better reasoning, longer coherent responses
- **Trade-off:** Slower than 8B, but much higher quality

### Files & Locations

**Deployment files:**
- Weights: `/home/ttuser/code/tt-inference-server/persistent_volume/volume_id_tt_transformers-Llama-3.3-70B-Instruct-v0.9.0/weights/`
- Log: `/tmp/llama-70b-deploy-attempt.log`
- Monitor script: `/home/ttuser/.local/bin/monitor-70b-deployment`

**Docker:**
- Volume: `volume_id_tt_transformers-Llama-3.3-70B-Instruct` (in persistent_volume/)
- Port: 8000 (same as current setup)
- Image: `ghcr.io/tenstorrent/tt-inference-server/vllm-tt-metal-src-release-ubuntu-22.04-amd64:0.9.0-55fd115-aa4ae1e`

### Benefits

1. ✅ **8.75x more parameters** (70B vs 8B)
2. ✅ **2x larger context** (128K vs 65K tokens)
3. ✅ **Better reasoning** (complex queries, multi-step thinking)
4. ✅ **Longer responses** (more detailed, coherent)
5. ✅ **Drop-in replacement** (same OpenAI API)
6. ✅ **Officially validated** (not experimental)

---

## Installation & Architecture Discovery (2026-03-06)

### What Happened
User wanted to install OpenClaw for practice. During implementation, discovered that OpenClaw v2026.3.2 is **NOT** a simple LLM client - it's a full enterprise-grade agent framework!

### Key Discoveries

**OpenClaw Architecture:**
- **Gateway server**: WebSocket daemon on port 18789
- **Agent workspace**: Skills, memory, sessions, channels
- **Channel integrations**: WhatsApp, Telegram, Discord, Slack, SMS
- **Complex authentication**: JWT tokens, API keys, provider definitions

**Installation Status:**
- ✅ OpenClaw v2026.3.2 installed at `/home/ttclaw/openclaw/`
- ✅ Node.js v24.14.0 and npm 11.9.0
- ✅ Wrapper script: `/home/ttclaw/openclaw/openclaw.sh`
- ✅ vLLM server: http://127.0.0.1:8000 (in Docker)
- ✅ Tenstorrent hardware: 4x P300C chips (Blackhole architecture)

### Configuration Attempts

**Attempt 1: Manual JSON Configuration** ❌
- Tried creating `openclaw.json` manually
- Result: Invalid config format errors

**Attempt 2: Onboarding Wizard** ✅
- Used `openclaw onboard` with custom provider flags
- Successfully created workspace structure
- Generated agent configs

### How OpenClaw Actually Works

**Command Structure:**
```
openclaw gateway run     # Start WebSocket gateway daemon
openclaw tui             # Terminal UI (interactive)
openclaw agent --message # Single agent turn
openclaw message send    # Send to specific channel
```

**No "ask" command!** OpenClaw is not a simple query tool.

### Files Created During Installation

1. `/home/ttclaw/openclaw/openclaw.sh` - Wrapper script
2. `/home/ttuser/OPENCLAW_INSTALLATION_GUIDE.md` - Comprehensive guide
3. `/home/ttuser/OPENCLAW_QUICK_REFERENCE.md` - Command cheat sheet  
4. `/home/ttuser/OPENCLAW_SETUP_CORRECTED.md` - Architecture docs
5. `/home/ttuser/.local/bin/test-openclaw` - Installation verification

### Important Lessons

1. **OpenClaw is complex** - Full framework, not simple client
2. **Configuration via wizard** - Not manual file editing
3. **Gateway required** - Most functionality needs daemon running
4. **Custom provider support** - Can use local vLLM endpoints

---

## Authentication Configuration (2026-03-07)

### The Problem
Gateway kept failing with authentication errors, even though vLLM runs with `--no-auth`:

```
No API key found for provider "tt-claw-qb2"
Auth store: /home/ttclaw/.openclaw/agents/main/agent/auth-profiles.json
```

### Root Cause Discovery

OpenClaw has **TWO** configuration files per agent:
1. **`models.json`** - Provider definitions with models (checked FIRST)
2. **`auth-profiles.json`** - API keys by provider name (fallback)

**Critical insight:** When a provider exists in `models.json`, OpenClaw expects the `apiKey` field **within that provider definition**, NOT in `auth-profiles.json`!

### Evidence
- Provider `ttclaw-127-0-0-1-8000` had `"apiKey": "eyJhbGc..."` → ✅ Worked
- Provider `tt-claw-qb2` had NO apiKey field → ❌ Failed
- `auth-profiles.json` was completely ignored!

### Solution Attempts

**Attempt 1: Add keys to auth-profiles.json** ❌
- Added dummy keys to auth-profiles.json
- Restarted gateway multiple times
- Still failed - auth-profiles.json was never checked!

**Attempt 2: Add apiKey to global config** ⚠️
- Updated `/home/ttclaw/.openclaw/openclaw.json`
- But agent configs had their own models.json
- Config merge mode meant both were used

**Attempt 3: Add apiKey to ALL provider definitions** ✅
- Updated global config providers
- Updated main agent models.json
- Updated tt-claw-qb2 agent models.json
- **Finally worked!**

### The Fix

Added `apiKey` field to provider definitions in both global and agent configs:

```json
{
  "providers": {
    "tt-claw-qb2": {
      "baseUrl": "http://127.0.0.1:8000/v1",
      "api": "openai-completions",
      "apiKey": "sk-dummy-no-auth-required",  // ✅ ADDED
      "models": [...]
    }
  }
}
```

Since vLLM runs with `--no-auth`, the dummy key satisfies OpenClaw's validation but is ignored by vLLM.

### Files Modified

1. `/home/ttclaw/.openclaw/openclaw.json` - Global config
2. `/home/ttclaw/.openclaw/agents/main/agent/models.json` - Main agent
3. `/home/ttclaw/.openclaw/agents/tt-claw-qb2/agent/models.json` - Second agent

### Why This Was Confusing

- Documentation suggested auth-profiles.json was the auth store
- No mention that models.json takes precedence
- Provider definitions could exist without apiKey (but wouldn't work)
- Config merge mode meant multiple sources of provider definitions

---

## The Provider Name Confusion

### The Realization

After fixing auth, got new error:
```
Error: The model `tt-claw-qb2` does not exist
```

**User's key insight:** "Of course vLLM has no knowledge of a tt-claw-qb2!"

### The Mistake

We were confusing:
- **Provider names** (OpenClaw's internal labels like `tt-claw-qb2`)
- **Model names** (what vLLM actually serves: `meta-llama/Llama-3.1-8B-Instruct`)

vLLM doesn't care about provider names - it only knows model names!

### What vLLM Actually Serves

```bash
curl http://localhost:8000/v1/models
# Returns: "meta-llama/Llama-3.1-8B-Instruct"
```

### The Cleanup

Simplified config to ONE provider with the EXACT model name:

```json
{
  "providers": {
    "vllm": {  // Simple provider name
      "baseUrl": "http://127.0.0.1:8001/v1",
      "apiKey": "sk-no-auth",
      "models": [
        {
          "id": "meta-llama/Llama-3.1-8B-Instruct",  // EXACT vLLM name
          "name": "Llama 3.1 8B Instruct",
          "contextWindow": 65536,
          "maxTokens": 8192
        }
      ]
    }
  }
}
```

### Additional Issues Fixed

1. **Low context window warning** - Changed from 16K to 65K
2. **Multiple conflicting providers** - Removed tt-claw-qb2, vllm-llama8b, etc.
3. **Session cache** - Cleared old sessions with wrong providers
4. **Mode confusion** - Cleaned up API mode (openai-completions vs openai-responses)

---

## The vLLM Compatibility Crisis

### The Core Problem

OpenClaw sends OpenAI API fields that the Docker-locked vLLM version doesn't support:

```
WARNING: The following fields were present in the request but ignored: {'strict'}
WARNING: The following fields were present in the request but ignored: {'store'}
INFO: "POST /v1/chat/completions HTTP/1.1" 400 Bad Request
```

### Why This Happened

- OpenClaw uses latest OpenAI API spec (includes `strict`, `store` fields)
- vLLM version locked in Docker container (commit aa4ae1e)
- vLLM warnings say "ignored" but still returns 400 error
- Can't upgrade vLLM (Docker-based deployment)

### Failed Approaches

**Attempt 1: Different API modes**
- Tried `openai-responses` → 500 error (uses `/v1/responses` endpoint)
- Tried `openai-completions` → 400 error (strict/store fields)
- Tried `ollama` → Invalid config option

**Attempt 2: Configuration flags**
- No compatibility mode in OpenClaw
- No way to disable strict/store fields
- API mode is fixed per provider type

**Attempt 3: Environment variables**
- Set VLLM_API_KEY (didn't help)
- Tried different auth tokens (not the issue)

### The Realization

**User's key decision:** "vLLM is locked to a version in a docker file. It is what it is. What can we do to mitigate?"

Can't change vLLM → Must adapt requests → **Need a proxy!**

---

## Final Solution: Compatibility Proxy

### Architecture

```
OpenClaw (port 8001) → Proxy (strip fields) → vLLM (port 8000) → Tenstorrent
```

### The Proxy

Created simple Python HTTP proxy:

```python
class ProxyHandler(BaseHTTPRequestHandler):
    def do_POST(self):
        # Parse request
        data = json.loads(body)
        
        # Remove incompatible fields
        data.pop('strict', None)
        data.pop('store', None)
        data.pop('prompt_cache_key', None)
        
        # Clean messages
        if 'messages' in data:
            for msg in data['messages']:
                msg.pop('strict', None)
        
        # Forward to vLLM
        resp = requests.post('http://localhost:8000/v1/...', data=body)
        self.wfile.write(resp.content)
```

### Implementation

**Files Created:**
- `/home/ttclaw/openclaw/vllm-proxy.py` - Production (quiet)
- `/home/ttclaw/openclaw/vllm-proxy-debug.py` - Debug (verbose)
- `/home/ttclaw/openclaw/start-openclaw.sh` - Startup script

**Configuration Updated:**
- Changed baseUrl from `:8000` to `:8001` (proxy port)
- Kept everything else the same

### Testing

```bash
# Test proxy strips strict field
curl -X POST http://localhost:8001/v1/chat/completions \
  -d '{"model": "meta-llama/...", "strict": true, ...}'

# Proxy output:
Original: {"strict": true, "messages": [...]}
Cleaned:  {"messages": [...]}  # strict removed!
Response: 200 OK
Body: {"choices":[{"message":{"content":"OK"}}]}
```

**✅ SUCCESS!** Proxy strips fields and gets 200 OK with actual LLM response!

### Critical Requirement: Startup Order

**Proxy MUST be running before gateway starts!**

Otherwise OpenClaw either:
- Fails to connect (if proxy never starts)
- Bypasses proxy somehow (if started after)

**Correct sequence:**
1. Start proxy (port 8001)
2. Start gateway (connects to proxy)
3. Start TUI

---

## How to Use

### Three-Terminal Setup

**Terminal 1: Proxy (MUST BE FIRST)**
```bash
cd ~/openclaw
python3 vllm-proxy.py
```
Leave this running! Don't proceed until proxy is running.

**Terminal 2: Gateway**
```bash
cd ~/openclaw
./openclaw.sh gateway run
```
Wait for: `[gateway] listening on ws://127.0.0.1:18789`

**Terminal 3: TUI**
```bash
cd ~/openclaw
./openclaw.sh tui
```

### All-in-One Script

```bash
cd ~/openclaw
./start-openclaw.sh
```

This starts proxy + gateway together, then in another terminal:
```bash
cd ~/openclaw
./openclaw.sh tui
```

### Debugging

Use debug proxy to see all requests:
```bash
cd ~/openclaw
python3 vllm-proxy-debug.py
```

Shows:
- Original request with `strict` fields
- Cleaned request without `strict`
- vLLM response

---

## Architecture

### Complete Flow

```
┌──────────┐
│ User TUI │ Send message: "Hello"
└────┬─────┘
     │ WebSocket to ws://127.0.0.1:18789
     ▼
┌─────────────┐
│   Gateway   │ Process message, call LLM
└─────┬───────┘
      │ HTTP POST to http://127.0.0.1:8001/v1/chat/completions
      │ Body: {"model": "...", "messages": [...], "strict": true}
      ▼
┌──────────────┐
│ Proxy :8001  │ Strip: strict, store, prompt_cache_key
└──────┬───────┘
       │ HTTP POST to http://127.0.0.1:8000/v1/chat/completions
       │ Body: {"model": "...", "messages": [...]}  # Clean!
       ▼
┌──────────────┐
│ vLLM :8000   │ Process request
│ (Docker)     │
└──────┬───────┘
       │ Inference on Tenstorrent hardware
       ▼
┌──────────────────┐
│ 4x P300C Chips   │ TT-Metal + vLLM acceleration
│ (Blackhole arch) │
└──────────────────┘
```

### Configuration Details

**OpenClaw Config:** `/home/ttclaw/.openclaw/openclaw.json`
```json
{
  "models": {
    "providers": {
      "vllm": {
        "baseUrl": "http://127.0.0.1:8001/v1",  // Proxy!
        "api": "openai-completions",
        "apiKey": "sk-no-auth",
        "models": [{
          "id": "meta-llama/Llama-3.1-8B-Instruct",
          "contextWindow": 65536,
          "maxTokens": 8192
        }]
      }
    }
  },
  "agents": {
    "defaults": {
      "model": {
        "primary": "vllm/meta-llama/Llama-3.1-8B-Instruct"
      }
    }
  }
}
```

**vLLM Setup:** Docker container
- Image: `ghcr.io/tenstorrent/tt-inference-server/vllm-tt-metal-src-release-ubuntu-22.04-amd64:0.9.0-55fd115-aa4ae1e`
- Flags: `--no-auth` (no authentication required)
- Port: 8000
- Model: meta-llama/Llama-3.1-8B-Instruct

---

## Key Learnings

### 1. OpenClaw is Enterprise Software
Not a simple LLM wrapper - it's a full agent platform with:
- Multi-agent support
- Channel integrations
- Skill system
- Memory management
- Complex config merging

### 2. Configuration Has Layers
- Global config
- Agent configs (per agent)
- Session state
- Config merge modes
All must align!

### 3. Provider Names ≠ Model Names
- Provider: OpenClaw's internal label
- Model: What vLLM actually serves
- They can be different (but model must be exact)

### 4. Auth Resolution is Hierarchical
1. Check models.json for provider
2. If found, look for apiKey IN provider
3. Only check auth-profiles.json as fallback
4. If no key found anywhere → error

### 5. API Compatibility Matters
- Different OpenAI API versions
- Fields added over time (strict, store)
- Older vLLM doesn't support newer fields
- Need compatibility layer for locked versions

### 6. Startup Order is Critical
Services must start in correct order:
1. vLLM (in Docker, usually always running)
2. **Proxy (MUST be first!)**
3. Gateway (connects to proxy)
4. TUI (connects to gateway)

Wrong order → connection failures or bypassed proxy

### 7. Debugging is Essential
- Verbose logging (debug proxy)
- Check actual requests/responses
- Verify ports are being used correctly
- Test components individually

---

## Troubleshooting

### Gateway won't start
```bash
# Check port 18789
netstat -tlnp | grep 18789

# Kill existing
pkill -f openclaw-gateway
```

### Proxy won't start
```bash
# Check port 8001
netstat -tlnp | grep 8001

# Kill existing
pkill -f vllm-proxy
```

### Still getting 400 errors
1. Verify proxy is running: `curl http://localhost:8001/v1/models`
2. Check gateway is using `:8001` not `:8000`
3. Use debug proxy to see actual requests
4. Check vLLM logs: `docker logs tt-inference-server-...`

### No responses in TUI
1. Check context window (must be ≥32000)
2. Verify model name matches vLLM exactly
3. Check gateway logs for errors
4. Test vLLM directly: `curl http://localhost:8000/v1/chat/completions ...`

---

## Documentation Files

All docs organized in `~/tt-claw/`:

- **`CLAUDE.md`** - This file (complete journey)
- **`OPENCLAW_FINAL_INSTRUCTIONS.md`** - Quick start guide
- **`DEMO_READY.md`** - Architecture & troubleshooting
- **`docs/OPENCLAW_AUTH_FIX.md`** - Authentication fix details
- **`docs/OPENCLAW_INSTALLATION_GUIDE.md`** - Original install plan
- **`docs/OPENCLAW_QUICK_REFERENCE.md`** - Command cheat sheet
- **`docs/OPENCLAW_SETUP_CORRECTED.md`** - Architecture discovery

---

## Status: Production Ready ✅

**What Works:**
- ✅ OpenClaw gateway starts without errors
- ✅ TUI connects and is interactive
- ✅ Proxy strips incompatible fields successfully
- ✅ vLLM returns 200 OK with LLM responses
- ✅ All authentication resolved
- ✅ Context window set to 65K tokens
- ✅ Running on Tenstorrent hardware (4x P300C)

**Performance:**
- Model: Llama-3.1-8B-Instruct
- Hardware: 4x Blackhole chips
- Context: 65536 tokens
- Max output: 8192 tokens
- Latency: ~1-2 seconds per response

**Reliability:**
- Proxy tested with strict field stripping
- Gateway stable with correct config
- vLLM container running continuously
- No auth errors after fix

---

**Last Updated:** March 7, 2026  
**Total Time:** ~6 hours (including debugging)  
**Lines of Code:** ~100 (proxy + scripts)  
**Coffee Consumed:** Too much ☕


---

## BREAKTHROUGH: Direct vLLM Solution (2026-03-07 Afternoon)

### What Changed

The tt-inference-server Docker approach was failing with 30-second timeouts (70B needs 10-30 minutes!). Through systematic debugging with ttuser, we discovered **direct vLLM execution** bypasses all Docker complexity.

### Successful Test Run

✅ **DeepSeek-R1-Distill-Llama-70B** loaded successfully on P150X4 using:
- tt-metal: `d3c8774`
- tt-vllm: `aa4ae1edc` (critical - must match!)
- Direct python execution (no Docker)
- Full environment control

### Critical Discovery: Environment Variables

The **MOST CRITICAL** variable that was missing:
```bash
export VLLM_TARGET_DEVICE=tt
```

Without this single variable, vLLM defaults to CPU platform and TT hardware is ignored!

### Complete Working Solution

See: **`VLLM_DIRECT_70B_SOLUTION.md`** in this directory

Key components:
1. **Environment setup script** - Sets all required variables
2. **Run script** - Starts any 70B model with correct config
3. **Test script** - Verifies API readiness
4. **OpenClaw integration** - Drop-in replacement for current 8B

### For ttclaw User

All scripts adapted for ttclaw user with paths to:
- ttuser's tt-metal installation (shared)
- ttuser's tt-vllm installation (shared)
- ttuser's Python venv (shared)
- ttclaw's home directory for scripts
- OpenClaw integration in `/home/ttclaw/.openclaw/`

### Deployment Path

```bash
# 1. Create scripts (as ttuser, then copy to ttclaw)
sudo cp ~/run-70b-model.sh /home/ttclaw/run-70b-vllm.sh
sudo cp ~/test-70b-model.sh /home/ttclaw/test-70b-api.sh
sudo chown ttclaw:ttclaw /home/ttclaw/*.sh

# 2. Run as ttclaw
sudo -u ttclaw bash
cd ~
./run-70b-vllm.sh \
  meta-llama/Llama-3.3-70B-Instruct \
  /home/ttuser/code/tt-inference-server/persistent_volume/volume_id_tt_transformers-Llama-3.3-70B-Instruct-v0.9.0/weights/Llama-3.3-70B-Instruct

# Wait 10-30 minutes (silent weight loading)
./test-70b-api.sh

# 3. Start proxy + OpenClaw (in separate terminals)
cd ~/openclaw && python3 vllm-proxy.py  # Terminal 2
cd ~/openclaw && ./openclaw.sh gateway run  # Terminal 3
cd ~/openclaw && ./openclaw.sh tui  # Terminal 4
```

### Why This Works

**Environment control:**
- Direct access to all TT libraries
- No Docker abstraction layer
- Explicit variable setting
- Full logging visibility

**No timeouts:**
- 70B model loading is silent but takes time
- Direct execution waits indefinitely
- Can monitor process with `ps aux | grep vllm`

**Version compatibility:**
- Uses exact versions we know work
- tt-metal and tt-vllm from ttuser's installations
- Shared Python venv with all patches applied

### Status

- ✅ **Validated:** DeepSeek-R1-70B loading on ttuser
- ⏳ **Next:** Deploy for ttclaw + OpenClaw
- 📝 **Documented:** Complete in `VLLM_DIRECT_70B_SOLUTION.md`

---

## Project Architecture: ttuser vs ttclaw (2026-03-18)

### **CRITICAL: User Separation for Security**

We maintain TWO completely separate OpenClaw environments:

**1. ttuser (Development/Private)**
- **Purpose:** Development, testing, has access to secrets
- **OpenClaw Software:** `/home/ttuser/openclaw/`
- **Config & Data:** `/home/ttuser/.openclaw/`
- **Agents:** `/home/ttuser/.openclaw/agents/` (main, chip-quest, terminal-dungeon, conference-chaos)
- **Memory:** `/home/ttuser/.openclaw/memory/main.sqlite` (51MB, 1,218 chunks, 174 files)
- **Gateway:** Runs as ttuser (port 18789)
- **Proxy:** Runs as ttuser (port 8001)

**2. ttclaw (Public/Demo)**
- **Purpose:** Demos, public use, NO ACCESS to ttuser's secrets
- **OpenClaw Software:** `/home/ttclaw/openclaw/`
- **Config & Data:** `/home/ttclaw/.openclaw/`
- **Agents:** `/home/ttclaw/.openclaw/agents/` (same 4 agents, copied from ttuser)
- **Memory:** `/home/ttclaw/.openclaw/memory/` (will be created on first run)
- **Gateway:** Runs as ttclaw (port 18789 - same port, don't run both!)
- **Proxy:** Runs as ttclaw (port 8001 - same port, don't run both!)

**3. Shared Resources (Read-Only for Both)**
- **Source Code:** `/home/ttuser/tt-claw/` (portable, version controlled)
  - Adventure games: `~/tt-claw/adventure-games/games/`
  - Scripts: `~/tt-claw/adventure-games/scripts/`
  - Documentation: `~/tt-claw/CLAUDE.md`, etc.
- **Lessons & Docs:** `/home/ttuser/code/tt-vscode-toolkit/content/lessons/` (45+ lessons)
- **TT-Metal Docs:** `/home/ttuser/tt-metal/` (METALIUM_GUIDE, releases, etc.)
- **vLLM Service:** Port 8000 (Docker, runs as ttuser, shared by both)

### **How to Use**

**For Development (ttuser):**
```bash
# As ttuser
cd ~/openclaw
python3 vllm-proxy.py &           # Start proxy
./openclaw.sh gateway run &        # Start gateway
./openclaw.sh tui                  # Use TUI

# Or use adventure games scripts:
cd ~/tt-claw/adventure-games/scripts
./quick-start.sh
```

**For Demos (ttclaw):**
```bash
# As ttuser (switching to ttclaw)
sudo -u ttclaw bash
cd ~/openclaw
python3 vllm-proxy.py &           # Start proxy
./openclaw.sh gateway run &        # Start gateway
./openclaw.sh tui                  # Use TUI
```

### **Important Rules**

1. **NEVER run both ttuser and ttclaw services simultaneously** (ports conflict!)
2. **vLLM on port 8000 is shared** - only one instance, run as ttuser
3. **Source in ~/tt-claw/ is shared read-only** - both can read, only ttuser should modify
4. **Secrets stay in /home/ttuser/** - ttclaw never has access
5. **When updating agent configs:** Update ttuser first, then copy to ttclaw

### **File Sync Commands**

When you update agent configs in ttuser and want to deploy to ttclaw:
```bash
# Copy game agents (SOUL.md files)
for agent in chip-quest terminal-dungeon conference-chaos; do
  sudo cp ~/.openclaw/agents/$agent/agent/SOUL.md /home/ttclaw/.openclaw/agents/$agent/agent/
  sudo chown ttclaw:ttclaw /home/ttclaw/.openclaw/agents/$agent/agent/SOUL.md
done

# Copy main agent (system.md file)
sudo cp ~/.openclaw/agents/main/agent/system.md /home/ttclaw/.openclaw/agents/main/agent/
sudo chown ttclaw:ttclaw /home/ttclaw/.openclaw/agents/main/agent/system.md

# After copying, ttclaw needs to restart gateway to pick up changes
```

---

## OpenClaw Memory Search - TT Expert Configuration (2026-03-10)

### What Happened
Configured OpenClaw's built-in memory search system to index external Tenstorrent documentation, making OpenClaw an expert on TT hardware, tt-vscode-toolkit lessons, and deployment guides.

### The Goal
Enable OpenClaw to:
- Answer questions about Tenstorrent hardware and setup
- Reference 45 interactive lessons from tt-vscode-toolkit
- Provide deployment guidance from tt-inference-server docs
- Recall the complete OpenClaw integration journey
- Cite specific files and line numbers in responses

### Solution: Memory Search with External Documentation

Added `memorySearch` configuration to both ttuser and ttclaw's OpenClaw configs to index:
- **45 interactive lessons** from tt-vscode-toolkit (1.1MB)
- **TT-Metal documentation** (METALIUM_GUIDE, releases, contributing)
- **TT-Inference-Server docs** (deployment, model guides, workflows)
- **OpenClaw integration journey** (CLAUDE.md - 70B deployment, vLLM setup)

### Configuration Added

**Files Modified:**
- `/home/ttuser/.openclaw/openclaw.json`
- `/home/ttclaw/.openclaw/openclaw.json`

**Memory Search Section:**
```json
{
  "agents": {
    "defaults": {
      "memorySearch": {
        "provider": "local",
        "fallback": "none",
        "extraPaths": [
          "/home/ttuser/code/tt-vscode-toolkit/content/lessons",
          "/home/ttuser/tt-metal/METALIUM_GUIDE.md",
          "/home/ttuser/tt-metal/releases",
          "/home/ttuser/tt-metal/contributing",
          "/home/ttuser/code/tt-inference-server/README.md",
          "/home/ttuser/code/tt-inference-server/docs",
          "/home/ttuser/tt-claw/CLAUDE.md"
        ]
      }
    }
  }
}
```

### How It Works

1. **Local Embeddings** - Uses node-llama-cpp (built-in, no external APIs)
2. **Vector Search** - SQLite with sqlite-vec for fast semantic search
3. **Auto-Indexing** - Automatically indexes all Markdown files in extraPaths
4. **Semantic Search** - Finds relevant info even with different wording
5. **Citations** - Shows source file paths and line numbers

### Documentation Indexed

**tt-vscode-toolkit** (45 lessons)
- Hardware detection, tt-smi usage
- vLLM deployment and configuration
- TT-Forge, TT-XLA, TT-Metal frameworks
- Custom training and datasets
- Multi-device configurations
- Cookbook examples: Game of Life, Mandelbrot, audio processing, image filters
- API servers, interactive chat
- Model bringup and optimization

**tt-metal**
- METALIUM_GUIDE.md - Core framework documentation
- Release notes and version history
- Contributing and development best practices

**tt-inference-server**
- Main README and project overview
- Development guide
- Model bringup procedures
- Workflow documentation
- Experimental models

**tt-claw**
- CLAUDE.md - Complete OpenClaw integration journey
  - Installation and configuration
  - 70B model deployment
  - vLLM compatibility proxy
  - Production setup and troubleshooting

### Usage

**Start Gateway (First Time):**
```bash
cd ~/code/tt-vscode-toolkit  # or ~/openclaw for ttclaw
./openclaw.sh gateway run
```

First startup takes 1-2 minutes to:
- Download local embedding models (~500MB)
- Index all documentation
- Create vector database

**Test Memory Search (in TUI):**
```
search memory for hardware detection
```

```
How do I deploy vLLM on Tenstorrent?
```

```
What cookbook examples are available?
```

```
What is METALIUM?
```

### Test Queries for Booth Demo

**Hardware Questions:**
- "What Tenstorrent devices are supported?"
- "How do I check if my Tenstorrent hardware is working?"
- "What's the difference between N300 and P150?"

**Deployment Questions:**
- "How do I deploy a model on Tenstorrent?"
- "What's the largest model I can run on P150X4?"
- "How do I set up vLLM with Tenstorrent?"

**Example Questions:**
- "What cookbook examples can I try?"
- "Show me how to run Game of Life on Tenstorrent"
- "What audio processing examples are available?"

**Technical Questions:**
- "What is METALIUM?"
- "How does TT-Forge work?"
- "What's the difference between TT-XLA and TT-Forge?"

### Expected Behavior

When you ask a question:
1. ✅ OpenClaw automatically searches indexed documentation
2. ✅ Finds relevant snippets from lessons and docs
3. ✅ Synthesizes answer using retrieved context
4. ✅ Cites sources with file paths and line numbers

**Example Output:**
```
User: How do I check if my Tenstorrent device is working?

OpenClaw: You can use tt-smi to check your Tenstorrent devices.
          Run 'tt-smi' to see a list of all detected devices...

          Source: tt-vscode-toolkit/content/lessons/hardware-detection.md#L15
```

### Files Created

**Documentation:**
- `/home/ttuser/OPENCLAW_MEMORY_SEARCH_SETUP.md` - Comprehensive guide
- `/home/ttuser/OPENCLAW_MEMORY_QUICK_REF.md` - Quick reference card

**Testing:**
- `/home/ttuser/test-openclaw-memory.sh` - Diagnostic test script

**Checks:**
- Gateway running
- Configuration present
- Documentation paths exist
- Vector database created
- Embedding models downloaded

### Performance

**First Query:**
- 30-60 seconds (downloads embedding models)
- One-time setup cost

**Subsequent Queries:**
- <1 second response time
- Fast semantic search
- Accurate citations

### Benefits

1. ✅ **Expert Knowledge** - OpenClaw knows all TT hardware and lessons
2. ✅ **Always Current** - Documentation updates auto-indexed
3. ✅ **Semantic Search** - Finds info with different wording
4. ✅ **Citations** - Shows exact source locations
5. ✅ **Zero Maintenance** - No manual updates needed
6. ✅ **Local First** - No external API dependencies
7. ✅ **Booth Ready** - Can answer visitor questions
8. ✅ **Scalable** - Easy to add more documentation

### Troubleshooting

**Gateway won't start:**
```bash
# Check JSON syntax
cat ~/.openclaw/openclaw.json | jq .

# Check for errors in terminal
```

**No memory search results:**
```bash
# Verify configuration
grep "memorySearch" ~/.openclaw/openclaw.json

# Check vector database
ls -lh ~/.openclaw/memory/*.sqlite
```

**First search is slow:**
- Expected! Downloads models (~500MB) on first use
- Subsequent searches are fast

**Permission errors:**
```bash
# Fix ownership
sudo chown -R ttuser:ttuser ~/.openclaw/
sudo chown -R ttclaw:ttclaw /home/ttclaw/.openclaw/
```

### Status

- ✅ Configuration added to both ttuser and ttclaw
- ✅ All documentation paths verified (45 lessons + docs)
- ✅ Test script created and working
- ⏳ Pending: Gateway restart with new config
- ⏳ Pending: Indexing completion (1-2 minutes)
- ⏳ Pending: Testing with sample queries

### Next Steps

1. **Restart gateway** to pick up new configuration
2. **Monitor indexing** in gateway logs
3. **Test queries** from list above
4. **Verify citations** show correct file paths
5. **Practice** for booth demo

### Future Enhancements

Once basic search works:
- Create skills to run tt-smi and store output
- Add hardware monitoring skills
- Enable session indexing (past conversations)
- Create specialized agents for different topics
- Add SDK and API reference documentation

---

**Last Updated:** March 10, 2026
**Total Documentation:** 45+ lessons, complete TT stack docs
**Configuration:** Both ttuser and ttclaw
**Status:** Ready for testing


## OpenClaw System Prompt Fix (2026-03-11)

### What Happened
After configuring memory search, OpenClaw would find information but not use it to answer questions. It would say "I found information about QB2" instead of actually telling the user what QB2 is.

### The Issue
OpenClaw's default behavior was to acknowledge tool results without synthesizing them into answers. The agent needed explicit instructions to use memory search results.

### Solution: Agent System Prompt

Created `/home/ttclaw/.openclaw/agents/main/agent/system.md` with instructions to:
- Use memory_search to find relevant information
- Synthesize information into clear, direct answers
- Cite sources by mentioning lesson/document names
- Be comprehensive and include technical details

### Example of Fixed Behavior

**Before:**
- User: "What is QB2?"
- OpenClaw: "I found information about QB2 in my memory."

**After:**
- User: "What is QB2?"
- OpenClaw: "QuietBox 2 (QB2) is TT-QuietBox™ 2, a liquid-cooled, desk-friendly AI workstation that runs models up to 120 billion parameters locally with a fully open-source software stack. It's the industry's first desktop AI workstation built on RISC-V architecture. [Source: qb2-faq.md]"

### Files
- System prompt: `/home/ttclaw/.openclaw/agents/main/agent/system.md`
- Documentation: `docs/openclaw/SYSTEM_PROMPT_CONFIGURATION.md`

---

## vLLM Tool Calling for OpenClaw (2026-03-11)

### What Happened
OpenClaw requires vLLM to support tool calling with `--enable-auto-tool-choice` and `--tool-call-parser` flags. Without these, agent operations fail with "400 auto tool choice requires..." errors.

### The Issue
The `tt-inference-server/run.py` wrapper doesn't properly forward tool calling arguments via `--vllm-override-args`. The flags either fail JSON parsing or don't reach the vLLM process.

### Solution: Direct Docker Command

Bypass `run.py` and run Docker directly with explicit tool calling flags:

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

### Key Additions
- `--enable-auto-tool-choice` - Enables automatic tool selection
- `--tool-call-parser llama3_json` - Uses Llama 3's JSON tool calling format

### Complete Startup Sequence

1. **Reset hardware** (after suspend/resume):
   ```bash
   tt-smi -r
   ```

2. **Start vLLM** with tool calling (command above)

3. **Wait for warmup** (~5-10 minutes) until "Readiness file created"

4. **Start proxy** for OpenClaw:
   ```bash
   cd ~/openclaw && python3 vllm-proxy.py &
   ```

5. **Start OpenClaw gateway**:
   ```bash
   sudo -u ttclaw /home/ttclaw/openclaw/openclaw.sh gateway run &
   ```

6. **Start TUI**:
   ```bash
   sudo -u ttclaw /home/ttclaw/openclaw/openclaw.sh tui
   ```

### Files
- Documentation: `docs/openclaw/VLLM_TOOL_CALLING_COMMAND.md`
- Proxy: `/home/ttclaw/openclaw/vllm-proxy.py`

### Status
✅ Working as of March 11, 2026
- Tool calling enabled and functional
- OpenClaw connects without 400 errors
- Memory search operational with direct answers

---

**Last Updated:** March 11, 2026
**OpenClaw Status:** Fully operational with memory search and tool calling
**Documentation:** Complete in `docs/openclaw/`

