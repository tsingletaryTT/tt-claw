# ttclaw User Setup - Updated for Current Configuration

**Date:** 2026-03-07
**Status:** ✅ All files updated to match current working configuration

---

## What Was Out of Date

The ttclaw user's welcome files referenced old configuration that never worked:
- ❌ **Old**: Qwen3-32B on P150x8 (8 chips)
- ❌ **Old**: JWT bearer token authentication
- ❌ **Old**: 40-60 minute first-time startup

---

## What Was Updated

### ✅ Current Working Configuration

All files now correctly reflect:
- ✅ **Model**: Llama-3.1-8B-Instruct (8B parameters)
- ✅ **Device**: P150 (single Blackhole chip)
- ✅ **Authentication**: None (--no-auth mode)
- ✅ **Startup**: ~2 minutes (fast trace capture)
- ✅ **Performance**: ~400ms per request
- ✅ **Context**: 65K tokens

---

## Files Updated

### 1. `/home/ttclaw/.bashrc`
- **Added**: Welcome message on login
- **Shows**: Current model, device, API endpoint, quick commands

### 2. `/home/ttclaw/openclaw/README.md`
- **Updated**: Removed JWT authentication info (now --no-auth)
- **Updated**: Correct model (Llama-3.1-8B-Instruct)
- **Updated**: Correct device (P150, not P150x8)
- **Added**: Python examples without authentication
- **Added**: Links to demo scripts

### 3. `/home/ttuser/share_with_ttclaw/README.md`
- **Updated**: Correct model and device configuration
- **Updated**: Removed 40-60 minute startup warning
- **Updated**: OpenClaw config example (no auth)
- **Added**: Links to new demo scripts
- **Added**: Performance notes for single chip

### 4. `/home/ttuser/share_with_ttclaw/INFERENCE_SERVER_INFO.md`
- **Updated**: Complete rewrite for current configuration
- **Updated**: API examples without authentication
- **Updated**: Correct model ID in all examples
- **Updated**: Performance metrics for P150

---

## What ttclaw User Sees on Login

```
╔════════════════════════════════════════════════════════════════════╗
║       Tenstorrent QB2 - AI Inference Server (OpenClaw Ready)      ║
╚════════════════════════════════════════════════════════════════════╝

  Model:  Llama-3.1-8B-Instruct (8B parameters)
  Device: P150 (single Blackhole chip)
  API:    http://localhost:8000 (OpenAI-compatible)
  Auth:   None required (--no-auth)

Quick Test:
  curl http://localhost:8000/health

Documentation:
  ~/openclaw/README.md              - OpenClaw configuration
  ~/share_with_ttclaw/README.md     - API usage guide

Demo Scripts (in /home/ttuser):
  python3 ~ttuser/demo_tenstorrent_ai.py
```

---

## Quick Test Commands (for ttclaw user)

### 1. Health Check
```bash
curl http://localhost:8000/health
```

### 2. List Models
```bash
curl http://localhost:8000/v1/models
```

### 3. Simple Completion
```bash
curl -X POST http://localhost:8000/v1/completions \
  -H 'Content-Type: application/json' \
  -d '{
    "model": "meta-llama/Llama-3.1-8B-Instruct",
    "prompt": "What is 2+2?",
    "max_tokens": 20
  }'
```

### 4. Chat Completion
```bash
curl -X POST http://localhost:8000/v1/chat/completions \
  -H 'Content-Type: application/json' \
  -d '{
    "model": "meta-llama/Llama-3.1-8B-Instruct",
    "messages": [{"role": "user", "content": "Hello!"}],
    "max_tokens": 20
  }'
```

---

## OpenClaw Configuration

File: `/home/ttclaw/openclaw/openclaw.json`

```json
{
  "models": {
    "providers": {
      "vllm-llama8b": {
        "baseUrl": "http://127.0.0.1:8000/v1",
        "api": "openai-completions",
        "models": [{
          "id": "meta-llama/Llama-3.1-8B-Instruct",
          "name": "Llama 3.1 8B Instruct (Tenstorrent P150)",
          "contextWindow": 65536,
          "maxTokens": 16384
        }]
      }
    }
  }
}
```

**Note**: No authentication configuration needed (server runs with --no-auth)

---

## Key Information for ttclaw User

### What They Have Access To

✅ **Can read**:
- `~/openclaw/` - OpenClaw configuration
- `~/share_with_ttclaw/` - Shared documentation and examples
- Inference API at `http://localhost:8000`

❌ **Cannot access**:
- `/home/ttuser/` home directory (permission denied)
- Server management commands (no sudo access)
- Device reset commands (requires sudo)

### What They Can Do

- ✅ Query the inference API (no authentication required)
- ✅ Read documentation in `~/openclaw/` and `~/share_with_ttclaw/`
- ✅ Use OpenClaw with local inference server
- ✅ Write files in their own home directory
- ✅ Run demo scripts in `/home/ttuser/` (world-readable)

### What They Cannot Do

- ❌ Start/stop the inference server (managed by ttuser)
- ❌ Reset Tenstorrent devices (requires sudo)
- ❌ Access ttuser's home directory
- ❌ Install system packages

---

## Testing the Setup

### As ttclaw user:

```bash
# 1. Login as ttclaw (will show welcome message)
sudo -u ttclaw -i

# 2. Test API
curl http://localhost:8000/health

# 3. Read documentation
cat ~/openclaw/README.md
cat ~/share_with_ttclaw/README.md

# 4. Test inference
curl -X POST http://localhost:8000/v1/completions \
  -H 'Content-Type: application/json' \
  -d '{
    "model": "meta-llama/Llama-3.1-8B-Instruct",
    "prompt": "Hi!",
    "max_tokens": 10
  }'
```

---

## Documentation Structure

```
/home/ttclaw/
├── openclaw/
│   ├── README.md              ← OpenClaw config guide (UPDATED)
│   └── openclaw.json          ← Working config (no auth)
└── share_with_ttclaw/         ← Symlink to /home/ttuser/share_with_ttclaw
    ├── README.md              ← API usage guide (UPDATED)
    ├── INFERENCE_SERVER_INFO.md ← Complete API docs (UPDATED)
    └── manage-inference-server.sh ← Server management (ttuser only)

/home/ttuser/
├── DEMO_READY.md              ← Demo quick start
├── OPENCLAW_DEMO_GUIDE.md     ← Comprehensive demo guide
├── FINAL_WORKING_CONFIGURATION.md ← Technical reference
├── demo_tenstorrent_ai.py     ← Main demo script
└── test-openclaw-demo.py      ← Alternative demo
```

---

## Summary

**Before**: ttclaw user saw outdated information about Qwen3-32B, P150x8, JWT auth
**After**: ttclaw user sees correct information about Llama-3.1-8B-Instruct, P150, no auth

**All documentation is now accurate and consistent!** ✅

---

**Updated**: 2026-03-07
**Status**: Ready for use ✅
