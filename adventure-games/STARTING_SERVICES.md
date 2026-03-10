# Starting Adventure Game Services

## Quick Reference

### First Time Setup
```bash
cd ~/tt-claw/adventure-games/scripts
./setup-game-agents.sh
```
- Creates all game agents
- Seeds initial memory
- Configures models (65K context)

### Normal Start (Services Only)
```bash
cd ~/tt-claw/adventure-games/scripts
./start-adventure-services.sh
```
- Checks vLLM is running
- Starts proxy (port 8001)
- Starts gateway (port 18789)
- Ready to play!

### Fresh Restart (Clear Cache + Start)
```bash
cd ~/tt-claw/adventure-games/scripts
./start-adventure-services.sh --fresh
```
- Stops gateway
- Clears old sessions (removes stale SOUL cache)
- Seeds memory (adventure already begun)
- Verifies configs (65K context, CRITICAL sections)
- Starts proxy + gateway

### Just Reset (No Service Start)
```bash
cd ~/tt-claw/adventure-games/scripts
./restart-games.sh
```
- Does the reset without starting services
- Useful when gateway is already running but needs cache clear

## Workflow

### First Time Ever
```bash
# 1. Initial setup
cd ~/tt-claw/adventure-games/scripts
./setup-game-agents.sh

# 2. Make sure vLLM is running (separate terminal)
# Either Docker or direct vLLM

# 3. Start services
./start-adventure-services.sh

# 4. Launch game
./adventure-menu.sh
```

### Daily Use (Services Already Configured)
```bash
# Just start services if they're not running
cd ~/tt-claw/adventure-games/scripts
./start-adventure-services.sh
```

### After Code Changes (SOUL updates, config changes)
```bash
# Fresh start to reload everything
cd ~/tt-claw/adventure-games/scripts
./start-adventure-services.sh --fresh
```

### Troubleshooting Issues
```bash
# Full fresh restart
cd ~/tt-claw/adventure-games/scripts
./start-adventure-services.sh --fresh
```

## Service Architecture

```
vLLM (port 8000)
    ↓
Proxy (port 8001) - strips incompatible API fields
    ↓
Gateway (port 18789) - manages agents/sessions
    ↓
TUI - interactive game interface
```

## Scripts Explained

| Script | Purpose | When to Use |
|--------|---------|-------------|
| `setup-game-agents.sh` | Initial configuration | First time only |
| `start-adventure-services.sh` | Start proxy + gateway | Every session |
| `start-adventure-services.sh --fresh` | Reset + start | After changes / issues |
| `restart-games.sh` | Reset without starting | Manual troubleshooting |
| `adventure-menu.sh` | Game launcher | After services running |

## What `--fresh` Does

1. **Stops gateway** - Ensures clean state
2. **Clears sessions** - Removes cached SOUL files (old 16K context)
3. **Seeds memory** - Copies starter templates (adventure already begun)
4. **Verifies configs** - Checks 65K context, CRITICAL sections present
5. **Starts services** - Proxy + gateway with fresh state

## When to Use `--fresh`

Use fresh restart when:
- Context window shows 16K instead of 65K
- Agent writes to memory instead of starting game
- After updating SOUL files or configs
- Games not responding correctly
- "NO_REPLY" errors
- Token overflow errors

## Service Status

Check what's running:
```bash
# Check all services
ps aux | grep -E "(vllm|openclaw|proxy)"

# Check specific ports
netstat -tlnp | grep -E "(8000|8001|18789)"
```

## Logs

```bash
# Proxy logs
tail -f /tmp/vllm-proxy.log

# Gateway logs
tail -f /tmp/openclaw-gateway.log

# vLLM logs (if running in terminal)
# Check the terminal where you started vLLM
```

## Stopping Services

```bash
# Stop proxy
pkill -f vllm-proxy

# Stop gateway
pkill -f 'openclaw.*gateway'

# Stop all
pkill -f vllm-proxy; pkill -f 'openclaw.*gateway'
```

## Common Issues

### "Gateway already running" but games not working
```bash
./start-adventure-services.sh --fresh
```

### "Port 8001 already in use by non-proxy"
```bash
lsof -ti:8001 | xargs kill -9
./start-adventure-services.sh
```

### "vLLM not running"
Start vLLM first:
```bash
# Docker method
cd ~/code/tt-inference-server
python3 run.py ...

# Direct method
cd ~
./run-70b-vllm.sh meta-llama/Llama-3.1-8B-Instruct
```

### Token overflow (69k/16k)
```bash
./start-adventure-services.sh --fresh
```
The fresh flag clears old sessions with cached 16K limits.

## Recommendation

**Use `start-adventure-services.sh --fresh` as default** until you're confident everything works correctly. It's safer and only takes a few extra seconds.

Once stable:
- Normal daily use: `./start-adventure-services.sh` (no flag)
- After any changes: `./start-adventure-services.sh --fresh`
