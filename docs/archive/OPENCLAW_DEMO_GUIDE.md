# OpenClaw Demo Guide - Quick Start

**Status:** ✅ Ready to use (authentication issue fixed)
**Date:** 2026-03-06

## Prerequisites

✅ OpenClaw v2026.3.2 installed at `/home/ttclaw/openclaw/`
✅ vLLM server running on `http://localhost:8000` with Llama-3.1-8B-Instruct
✅ Authentication configured (dummy keys added to models.json)

## Quick Demo (Two-Terminal Setup)

### Terminal 1: Start OpenClaw Gateway

```bash
sudo -u ttclaw bash -c 'cd ~/openclaw && ./openclaw.sh gateway run'
```

**Expected output:**
```
[gateway] agent model: tt-claw-qb2/meta-llama/Llama-3.1-8B-Instruct
[gateway] listening on ws://127.0.0.1:18789, ws://[::1]:18789
```

Leave this running in the background.

### Terminal 2: Start OpenClaw TUI

```bash
sudo -u ttclaw bash -c 'cd ~/openclaw && ./openclaw.sh tui'
```

This opens an interactive terminal UI.

### Test Messages

Try these prompts in the TUI:

1. **Basic test:** "Is this on?"
2. **Code generation:** "Write a Python function to calculate fibonacci numbers"
3. **Reasoning:** "Explain quantum entanglement in simple terms"
4. **Multi-turn:** Ask follow-up questions to previous responses

## Advanced Usage

### Single Message (No TUI)

```bash
sudo -u ttclaw bash -c 'cd ~/openclaw && ./openclaw.sh agent --message "What is 2+2?"'
```

### Message via Channel

```bash
sudo -u ttclaw bash -c 'cd ~/openclaw && ./openclaw.sh message send --target @self --message "Hello from CLI"'
```

### Check Gateway Status

```bash
sudo -u ttclaw bash -c 'cd ~/openclaw && ./openclaw.sh gateway status'
```

### Stop Gateway

```bash
sudo -u ttclaw bash -c 'cd ~/openclaw && ./openclaw.sh gateway stop'
```

## Architecture

```
OpenClaw CLI → Gateway Server (ws://127.0.0.1:18789)
                    ↓
               Agent (with skills)
                    ↓
            LLM Provider (vLLM at http://localhost:8000)
                    ↓
         Tenstorrent Hardware (4x P300C chips)
```

## What You're Actually Running

- **OpenClaw Agent Framework** - Full AI agent with:
  - File operations
  - Code execution
  - Web browsing (if configured)
  - Memory management
  - Skill system

- **Llama-3.1-8B-Instruct** - Running on:
  - 4x Tenstorrent P300C chips (Blackhole architecture)
  - Optimized with vLLM for fast inference
  - No cloud dependencies (fully local)

## Configuration Files

- **Main config:** `/home/ttclaw/.openclaw/openclaw.json`
- **Agent workspace:** `/home/ttclaw/.openclaw/agents/main/`
- **Provider definitions:** `/home/ttclaw/.openclaw/agents/main/agent/models.json`
- **Auth profiles:** `/home/ttclaw/.openclaw/agents/main/agent/auth-profiles.json`

## Troubleshooting

### Gateway won't start

```bash
# Check if port 18789 is in use
sudo netstat -tlnp | grep 18789

# Kill existing gateway
sudo -u ttclaw bash -c 'cd ~/openclaw && ./openclaw.sh gateway stop'
```

### vLLM server not responding

```bash
# Check if vLLM is running
curl http://localhost:8000/health

# Restart vLLM (if needed)
# [Use your vLLM startup script here]
```

### Authentication errors (shouldn't happen now)

If you still see "No API key found" errors, verify the fix was applied by checking provider configurations.

## Key Features Demonstrated

1. ✅ **Local AI Agent** - Runs entirely on your hardware
2. ✅ **No Cloud Dependencies** - All computation on Tenstorrent chips
3. ✅ **Fast Inference** - vLLM optimization + TT hardware acceleration
4. ✅ **Interactive UI** - TUI for conversational interaction
5. ✅ **Secure** - ttclaw user has limited privileges, no sudo access
6. ✅ **Self-contained** - All files in `/home/ttclaw/openclaw/`

## Next Steps

### Explore Skills

OpenClaw agents can have custom skills. Check the workspace:

```bash
ls /home/ttclaw/.openclaw/agents/main/skills/
```

### Add More Models

Edit `/home/ttclaw/.openclaw/agents/main/agent/models.json` to add more model options from your vLLM server.

### Enable Channels (Optional)

OpenClaw supports integrations with:
- WhatsApp
- Telegram
- Discord
- Slack
- SMS

See [OpenClaw Channel Docs](https://docs.openclaw.ai/channels/) for setup.

## Resources

- **Fix Documentation:** `OPENCLAW_AUTH_FIX.md` - Technical details of authentication fix
- **Installation Guide:** `OPENCLAW_INSTALLATION_GUIDE.md` - Original installation instructions
- **Quick Reference:** `OPENCLAW_QUICK_REFERENCE.md` - Command cheat sheet
- **Official Docs:** https://docs.openclaw.ai/

---

**Status:** Demo Ready ✅
**Last Updated:** 2026-03-06
