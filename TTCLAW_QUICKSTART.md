# Running OpenClaw as ttclaw (Demo Mode)

## Quick Start

```bash
# As ttuser, start the adventure menu as ttclaw
~/tt-claw/ttclaw-services.sh menu
```

## What Was Fixed

### 1. Permission Issues ✅
- Made `/home/ttuser` readable (755) so ttclaw can traverse
- Made `~/tt-claw/runtime` writable (777) so ttclaw can write logs/configs
- Made `~/tt-metal` readable so ttclaw can access documentation
- Added ttclaw to ttuser group for shared access

### 2. Memory Search Issues ✅
- All documentation paths are now readable by ttclaw:
  - ✅ `/home/ttuser/code/tt-vscode-toolkit/content/lessons` (45 lessons)
  - ✅ `/home/ttuser/code/tt-inference-server/docs`
  - ✅ `/home/ttuser/tt-metal/` (METALIUM_GUIDE, etc.)
  - ✅ `/home/ttuser/tt-claw/CLAUDE.md`

### 3. Model Auto-Detection ✅
- Updated `detect-model.py` to use portable runtime config
- Uses `OPENCLAW_CONFIG_PATH` environment variable
- Detects model from vLLM on port 8001 (proxy)
- Updates config automatically with correct model name and baseUrl

## Service Management

### Start Services Individually

```bash
# Start gateway (as ttclaw)
~/tt-claw/ttclaw-services.sh gateway

# Start TUI (as ttclaw) - in another terminal
~/tt-claw/ttclaw-services.sh tui

# Or start adventure menu (includes all checks)
~/tt-claw/ttclaw-services.sh menu
```

### Stop Services

```bash
~/tt-claw/ttclaw-services.sh stop
```

## Architecture

```
ttuser                          ttclaw (demo/public)
├─ vLLM (port 8000) ────────────┐
├─ Proxy (port 8001) ───────────┼─→ Shared services
│                               │
├─ Code & docs (read-only) ────┼─→ Shared read access
│  ├─ tt-vscode-toolkit         │
│  ├─ tt-metal                  │
│  └─ tt-inference-server       │
│                               │
└─ ~/tt-claw/runtime/ ──────────┼─→ Shared config & state
                                │   (world-writable)
                                │
                                └─→ Gateway (port 18789)
                                └─→ TUI
```

## Why ttclaw?

- **Security isolation**: ttclaw has no access to ttuser's private data
- **Demo safety**: Can't accidentally expose secrets or break ttuser's setup
- **Shared resources**: Both use same vLLM, docs, and model
- **Portable config**: Runtime config works for both users

## Config Location

Both users use: `~/tt-claw/runtime/openclaw.json`

This is set via: `export OPENCLAW_CONFIG_PATH="$HOME/tt-claw/runtime/openclaw.json"`

## Logs

ttclaw services log to `/tmp/ttclaw-*.log`:
- `/tmp/ttclaw-gateway.log` - Gateway debug output
- PID files in `/tmp/ttclaw-*.pid`

## Manual Commands (if needed)

```bash
# As ttuser, switch to ttclaw
sudo -u ttclaw bash

# Set environment
export OPENCLAW_CONFIG_PATH="$HOME/tt-claw/runtime/openclaw.json"
export OPENCLAW_STATE_DIR="$HOME/tt-claw/runtime"

# Start gateway
cd ~/openclaw  # or /home/ttuser/openclaw
./openclaw.sh gateway run

# In another terminal, start TUI
sudo -u ttclaw bash
export OPENCLAW_CONFIG_PATH="$HOME/tt-claw/runtime/openclaw.json"
cd ~/openclaw
./openclaw.sh tui
```

## Troubleshooting

### Can't write to runtime
```bash
# Make runtime writable
chmod 777 ~/tt-claw/runtime
```

### Can't access tt-claw
```bash
# Make ttuser home traversable
chmod 755 /home/ttuser
```

### Memory search errors
```bash
# Verify ttclaw can read docs
sudo -u ttclaw ls ~/tt-metal
sudo -u ttclaw ls ~/code/tt-vscode-toolkit/content/lessons
```

### Model not detected
```bash
# Run detection manually
cd ~/tt-claw
python3 adventure-games/scripts/detect-model.py
```
