# tt-claw: OpenClaw on Tenstorrent Hardware

**Status:** ✅ Production Ready
**Date:** 2026-03-06
**Location:** `/home/ttuser/tt-claw/`

## Overview

This directory contains all documentation, scripts, and configuration for running OpenClaw v2026.3.2 on Tenstorrent hardware. OpenClaw is a full AI agent framework with skills, memory, and channel integrations, backed by Llama-3.1-8B-Instruct running on 4x P300C chips.

## Quick Start

### Start OpenClaw (Two Terminals Required)

**Terminal 1 - Gateway:**
```bash
sudo -u ttclaw bash -c 'cd ~/openclaw && ./openclaw.sh gateway run'
```

**Terminal 2 - TUI:**
```bash
sudo -u ttclaw bash -c 'cd ~/openclaw && ./openclaw.sh tui'
```

Then send messages in the TUI and get responses from the AI agent!

## Directory Structure

```
~/tt-claw/
├── docs/              # Documentation
├── scripts/           # Test and utility scripts
├── config/            # Configuration examples
├── backups/           # Configuration backups
└── README.md          # This file
```

## Documentation (docs/)

### Primary Docs
- **`OPENCLAW_IMPLEMENTATION_SUMMARY.md`** - Complete overview of what was built
- **`OPENCLAW_AUTH_FIX.md`** - Technical details of authentication fix
- **`OPENCLAW_DEMO_GUIDE.md`** - Quick start and usage examples

### Installation & Setup
- **`OPENCLAW_INSTALLATION_GUIDE.md`** - Original installation instructions
- **`OPENCLAW_SETUP_CORRECTED.md`** - Corrected setup based on actual architecture
- **`OPENCLAW_QUICK_REFERENCE.md`** - Command cheat sheet

### Reading Order for New Users
1. Start with: `OPENCLAW_DEMO_GUIDE.md` (quickest path to running)
2. Then read: `OPENCLAW_IMPLEMENTATION_SUMMARY.md` (understand the system)
3. For troubleshooting: `OPENCLAW_AUTH_FIX.md` (technical deep dive)

## Scripts (scripts/)

- **`test-openclaw-demo.py`** - Python test script for OpenClaw functionality
- **`test-openclaw-simple.sh`** - Simple bash test script

### Running Tests
```bash
# Python test
python3 ~/tt-claw/scripts/test-openclaw-demo.py

# Shell test
bash ~/tt-claw/scripts/test-openclaw-simple.sh
```

## Configuration

### Active Configuration
- **Location:** `/home/ttclaw/.openclaw/`
- **Main config:** `/home/ttclaw/.openclaw/openclaw.json`
- **Agent workspace:** `/home/ttclaw/.openclaw/agents/main/`

### Key Files
- `models.json` - Provider definitions (includes apiKey fix)
- `auth-profiles.json` - API key storage (fallback)
- `openclaw.json` - Main OpenClaw configuration

### Backups
Configuration backups are stored in `backups/` directory.

## Architecture

```
OpenClaw CLI/TUI
        ↓
Gateway Server (ws://127.0.0.1:18789)
        ↓
Agent (main) with Skills & Memory
        ↓
Provider: tt-claw-qb2
        ↓
vLLM Server (http://localhost:8000)
        ↓
Llama-3.1-8B-Instruct
        ↓
4x Tenstorrent P300C Chips (Blackhole)
```

## What Was Fixed

### Problem
OpenClaw gateway was throwing authentication errors when trying to use the local vLLM server, even though vLLM runs with `--no-auth` flag.

### Solution
Added `apiKey` field directly to provider definitions in `models.json`. The dummy key (`"sk-dummy-no-auth-required"`) satisfies OpenClaw's validation while being safely ignored by vLLM's --no-auth server.

### Result
✅ Gateway starts without errors  
✅ TUI works interactively  
✅ LLM responds correctly  
✅ All components verified working  

## Common Commands

### Gateway Management
```bash
# Start gateway
sudo -u ttclaw bash -c 'cd ~/openclaw && ./openclaw.sh gateway run'

# Check status
sudo -u ttclaw bash -c 'cd ~/openclaw && ./openclaw.sh gateway status'

# Stop gateway
sudo -u ttclaw bash -c 'cd ~/openclaw && ./openclaw.sh gateway stop'
```

### Interactive Usage
```bash
# Start TUI
sudo -u ttclaw bash -c 'cd ~/openclaw && ./openclaw.sh tui'

# Send single message
sudo -u ttclaw bash -c 'cd ~/openclaw && ./openclaw.sh agent --message "Hello!"'
```

### Verification
```bash
# Check vLLM server
curl http://localhost:8000/health

# Verify provider configuration
sudo -u ttclaw python3 << 'EOF'
import json
with open('/home/ttclaw/.openclaw/agents/main/agent/models.json') as f:
    config = json.load(f)
    for name, provider in config['providers'].items():
        key = provider.get('apiKey', 'MISSING')
        print(f"{name}: {key[:20] if len(key) > 20 else key}")
EOF
```

## Troubleshooting

### Gateway won't start
1. Check if port 18789 is in use: `sudo netstat -tlnp | grep 18789`
2. Stop existing gateway: `sudo -u ttclaw bash -c 'cd ~/openclaw && ./openclaw.sh gateway stop'`
3. Check logs: `/tmp/openclaw/openclaw-*.log`

### vLLM server not responding
1. Check health: `curl http://localhost:8000/health`
2. Verify vLLM is running: `ps aux | grep vllm`
3. Check vLLM logs

### Authentication errors (shouldn't happen now)
See `docs/OPENCLAW_AUTH_FIX.md` for technical details of the fix.

## Features

- ✅ **Local AI Agent** - Fully local, no cloud dependencies
- ✅ **Tenstorrent Acceleration** - Runs on 4x P300C chips
- ✅ **Fast Inference** - vLLM optimization + TT hardware
- ✅ **Interactive TUI** - Terminal-based chat interface
- ✅ **Secure** - ttclaw user has limited privileges
- ✅ **Skills System** - Extensible agent capabilities
- ✅ **Memory** - Persistent conversation context
- ✅ **Channels** - Optional integrations (WhatsApp, Telegram, etc.)

## Resources

- **OpenClaw Docs:** https://docs.openclaw.ai/
- **GitHub:** https://github.com/openclaw/openclaw
- **Installation:** `docs/OPENCLAW_INSTALLATION_GUIDE.md`
- **Technical Fix:** `docs/OPENCLAW_AUTH_FIX.md`
- **Demo Guide:** `docs/OPENCLAW_DEMO_GUIDE.md`

## Security Notes

- vLLM server only listens on `localhost:8000` (no external access)
- Dummy API key never validated by vLLM
- ttclaw user has no sudo privileges
- All files isolated in `/home/ttclaw/openclaw/`
- Gateway uses WebSocket on localhost only

## Maintenance

### Update OpenClaw
```bash
sudo -u ttclaw bash -c 'cd ~/openclaw && npx openclaw@latest'
```

### Backup Configuration
```bash
sudo -u ttclaw tar czf ~/tt-claw/backups/openclaw-config-$(date +%Y%m%d).tar.gz   /home/ttclaw/.openclaw/
```

### Add New Models
Edit `/home/ttclaw/.openclaw/agents/main/agent/models.json` to add more model options.

## Next Steps

1. ✅ **Done:** OpenClaw working with Tenstorrent hardware
2. **Optional:** Add more models to provider definitions
3. **Optional:** Configure channels (Telegram, Discord, etc.)
4. **Optional:** Create custom skills for agent workspace
5. **Optional:** Set up monitoring and logging

## Credits

- **Implementation:** Claude Code (2026-03-06)
- **Hardware:** Tenstorrent P300C (4x Blackhole chips)
- **Framework:** OpenClaw v2026.3.2
- **LLM:** Llama-3.1-8B-Instruct via vLLM
- **Time:** ~50 minutes total implementation

---

**Status:** Production Ready ✅  
**Last Updated:** 2026-03-06  
**Maintained By:** ttuser
