# OpenClaw Adventure Games - Scripts

This directory contains all the runtime scripts for managing and launching OpenClaw Adventures.

## Quick Start

```bash
# One command to rule them all:
./quick-start.sh
```

This will:
1. Start all required services (proxy, gateway)
2. Detect your model automatically
3. Launch the interactive game menu

---

## Scripts Overview

### Service Management

#### `start-services.sh`
**Complete service lifecycle management**

```bash
./start-services.sh start    # Start all services in background
./start-services.sh stop     # Stop all services
./start-services.sh restart  # Restart services cleanly
./start-services.sh status   # Show service status with PIDs
./start-services.sh logs     # Tail service logs (Ctrl+C to exit)
```

**What it manages:**
- vLLM Proxy (port 8001) - API compatibility layer
- OpenClaw Gateway (port 18789) - WebSocket server

**Features:**
- Background execution with nohup
- PID file tracking
- Health checks with timeouts
- Clear status indicators

#### `check-health.sh`
**System diagnostics and troubleshooting**

```bash
./check-health.sh
```

**Checks:**
- vLLM server (port 8000) - Required
- vLLM proxy (port 8001) - Recommended
- OpenClaw gateway (port 18789) - Required
- Game agent configurations (3 games)
- Model configuration in OpenClaw

**Exit codes:**
- 0 = All systems operational
- 1 = vLLM not running (critical)
- 2 = Proxy not running (warning)
- 3 = Gateway not running (critical)
- 4+ = Other issues

---

### User Interface

#### `adventure-menu.sh`
**Interactive game launcher**

```bash
./adventure-menu.sh
```

**Features:**
- Real-time service status in header
- Non-blocking checks (warnings, not errors)
- Auto model detection with progress
- Service management submenu (option 0)
- Three games + system info + TT-Grues guide

**Menu Options:**
- 1: Chip Quest (recommended start)
- 2: Terminal Dungeon
- 3: Conference Chaos
- 0: Service Management
- 4: System Status
- 5: TT-Grues Guide
- 6: Exit

#### `quick-start.sh`
**Simplest entry point**

```bash
./quick-start.sh
```

All-in-one launcher:
1. Starts services automatically
2. Launches adventure menu
3. Handles environment overrides

**Environment override:**
```bash
OPENCLAW_MODEL="meta-llama/Llama-3.3-70B-Instruct" ./quick-start.sh
```

---

### Utilities

#### `detect-model.py`
**Automatic model detection and configuration**

```bash
python3 detect-model.py              # Auto-detect and update config
python3 detect-model.py --dry-run    # Show what would be detected
python3 detect-model.py --quiet      # Minimal output (for scripts)
python3 detect-model.py --progress   # Show progress indicators
```

**What it does:**
- Queries localhost:8001 (proxy) or 8000 (vLLM) for available models
- Detects model context window
- Updates OpenClaw configuration automatically
- Supports environment override: `OPENCLAW_MODEL="your/model"`

**Works with any model:**
- Llama (3.1, 3.2, 3.3)
- DeepSeek (R1, Distill)
- Qwen (2, 2.5)
- Mistral
- Any vLLM-compatible model

#### `vllm-proxy.py`
**API compatibility layer**

```bash
python3 vllm-proxy.py
```

**Purpose:**
Strips incompatible OpenAI API fields that newer OpenClaw sends but older vLLM doesn't support:
- `strict` field in requests
- `store` field in requests
- `prompt_cache_key` field

**Flow:**
```
OpenClaw (8001) → Proxy (strips fields) → vLLM (8000) → TT Hardware
```

---

## Typical Workflows

### First Time Setup

```bash
# 1. Ensure vLLM is running
curl http://localhost:8000/v1/models

# 2. Check system health
./check-health.sh

# 3. Launch!
./quick-start.sh
```

### Daily Use

```bash
# Just launch and go
./quick-start.sh
```

### Troubleshooting

```bash
# Check what's wrong
./check-health.sh

# Restart services
./start-services.sh restart

# View logs for errors
./start-services.sh logs
```

### Switching Models

```bash
# Stop current services
./start-services.sh stop

# Start vLLM with new model
# (see vLLM deployment docs)

# Restart OpenClaw services
./start-services.sh start

# Or use quick start which handles it
./quick-start.sh
```

---

## Directory Structure

```
adventure-games/scripts/
├── README.md                 # This file
├── adventure-menu.sh         # Interactive game launcher
├── check-health.sh           # System diagnostics
├── detect-model.py           # Model auto-detection
├── quick-start.sh            # One-command launcher
├── start-services.sh         # Service lifecycle manager
└── vllm-proxy.py             # API compatibility proxy
```

---

## Requirements

**Software:**
- Python 3.8+
- Node.js v18+ (for OpenClaw)
- Bash 4.0+

**Services:**
- vLLM running on port 8000
- OpenClaw installed (via setup script)

**Hardware:**
- Any Tenstorrent device (N150, P150, P300C, T3K, Galaxy)
- Sufficient DRAM for model (8B needs ~10GB, 70B needs ~80GB)

---

## Environment Variables

**OPENCLAW_MODEL**
Override model detection:
```bash
export OPENCLAW_MODEL="meta-llama/Llama-3.3-70B-Instruct"
```

**Used by:**
- detect-model.py
- quick-start.sh (passes to detect-model.py)

---

## Logs

**Service logs:**
- Proxy: `/tmp/openclaw-proxy.log`
- Gateway: `/tmp/openclaw-gateway.log`

**PID files:**
- Proxy: `/tmp/openclaw-proxy.pid`
- Gateway: `/tmp/openclaw-gateway.pid`

**View logs:**
```bash
./start-services.sh logs                    # Tail both logs
tail -f /tmp/openclaw-proxy.log             # Just proxy
tail -f /tmp/openclaw-gateway.log           # Just gateway
```

---

## Troubleshooting

### vLLM Not Running

**Symptom:** "vLLM is not running on port 8000"

**Fix:**
```bash
# Check if vLLM is actually running
curl http://localhost:8000/v1/models

# If not, deploy vLLM first (see vLLM docs)
```

### Proxy Won't Start

**Symptom:** "Failed to start proxy (timeout)"

**Fix:**
```bash
# Check if port 8001 is in use
lsof -i:8001

# Kill existing process
pkill -f vllm-proxy

# Try again
./start-services.sh start
```

### Gateway Won't Start

**Symptom:** "Failed to start gateway (timeout)"

**Fix:**
```bash
# Check gateway logs
tail /tmp/openclaw-gateway.log

# Kill existing process
pkill -f "openclaw.*gateway"

# Try again
./start-services.sh start
```

### Model Not Detected

**Symptom:** "No model detected"

**Fix:**
```bash
# Override detection manually
OPENCLAW_MODEL="your/model-name" ./quick-start.sh

# Or configure directly
python3 detect-model.py --dry-run  # Test detection
python3 detect-model.py            # Apply config
```

---

## Development

### Testing Scripts

```bash
# Test health check
./check-health.sh
echo $?  # Check exit code

# Test service manager
./start-services.sh start
./start-services.sh status
./start-services.sh stop

# Test model detection
python3 detect-model.py --dry-run
python3 detect-model.py --progress
```

### Script Exit Codes

All scripts use standard exit codes:
- 0 = Success
- 1+ = Specific errors (see check-health.sh for details)

### Logging

All background services log to `/tmp/`:
- Use `start-services.sh logs` to view
- Logs rotate automatically (not implemented yet)

---

## Integration

These scripts are used by:

1. **tt-vscode-toolkit**: VS Code extension calls these via toolkit scripts
2. **Direct usage**: Users can run scripts directly
3. **Automation**: Scripts can be chained in CI/CD

**Toolkit integration:**
```bash
# VS Code command → toolkit script → these scripts
Clone    → clone.sh   → (git clone)
Setup    → setup.sh   → (copies these scripts)
Launch   → launch.sh  → quick-start.sh
Status   → status.sh  → check-health.sh
Restart  → restart.sh → start-services.sh restart
Logs     → logs.sh    → start-services.sh logs
```

---

## See Also

- [Implementation Summary](../IMPLEMENTATION_SUMMARY.md) - Complete implementation details
- [TT-Grues Guide](../TT_GRUES.md) - Educational creatures
- [Quick Start Guide](../../QUICKSTART_ADVENTURE.md) - User-friendly intro
- [Main README](../../README.md) - Project overview

---

## Credits

**Created for:** Experience Architect Convergence 2026 (EAC 2026)
**Repository:** [github.com/tsingletaryTT/tt-claw](https://github.com/tsingletaryTT/tt-claw)
**Technologies:** OpenClaw v2026.3.2, vLLM, Tenstorrent hardware
