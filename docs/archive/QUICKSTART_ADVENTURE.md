# QuickStart: Your First Adventure on QB2

## Current Setup ✅

**vLLM Server Running:**
- Model: Llama-3.1-8B-Instruct
- Hardware: Single P150 chip (1 of 4 Blackhole chips on QB2)
- Endpoint: http://localhost:8000/v1
- Auth: Disabled (--no-auth)
- Status: ✅ Healthy and responding

**OpenClaw Configuration:**
- Config: `/home/ttclaw/.openclaw/openclaw.json`
- Provider: vllm → http://127.0.0.1:8000/v1
- API Key: sk-no-auth
- Agent: chip-quest (and others available)

## Steps to Run Your First Adventure

### 1. Switch to ttclaw user
```bash
sudo su - ttclaw
```

### 2. Start OpenClaw Gateway
```bash
# Option 1: Use the helper script
~/start-adventure.sh

# Option 2: Manual start
cd ~/openclaw
./openclaw.sh gateway run
```
**What this does:**
- Starts the OpenClaw gateway on port 18789
- Connects to vLLM server on port 8000
- Enables local-mode adventures

### 5. Open a NEW terminal and start the TUI
```bash
sudo su - ttclaw
cd ~/openclaw
./openclaw.sh tui
```

### 6. In the TUI, select an adventure
- Use arrow keys to navigate
- Available adventures:
  - **Chip Quest - Archie**: Silicon adventure with Archie the chip
  - **Terminal Dungeon**: Classic text adventure
  - **Conference Chaos**: Tech conference adventure

### 7. Play!
- Type commands and watch the LLM generate responses
- All generation happens on the local QB2 P150 chip
- No cloud APIs, all local hardware

## Available Adventures

Check what's installed:
```bash
cd ~/openclaw
./openclaw.sh agent list
```

## Troubleshooting

### vLLM server not responding
```bash
# Check if running
docker ps | grep tt-inference-server

# Check health
curl http://localhost:8000/health
```

### OpenClaw can't connect
```bash
# Verify config
cat ~/.openclaw/openclaw.json | jq '.models.providers.vllm'
# Should show: baseUrl: "http://127.0.0.1:8000/v1"
```

### Gateway already running
```bash
# Stop existing gateway
./openclaw.sh gateway stop
# Then start again
./openclaw.sh gateway run
```

## What's Happening Under the Hood

1. **Your Command** → OpenClaw TUI
2. **TUI** → OpenClaw Gateway (localhost:18789)
3. **Gateway** → vLLM API Server (localhost:8000)
4. **vLLM** → TT-Metal → P150 Chip
5. **P150 Chip** → Generates tokens using Llama-3.1-8B
6. **Response** ← Back through the chain to your terminal

All inference happening on local Tenstorrent hardware! 🚀

## Performance Stats

- **Startup**: ~60 seconds (model already cached)
- **First token**: ~100-300ms
- **Generation**: ~30-50 tokens/second
- **Context window**: 65,536 tokens

## Next Steps

Once you're comfortable:
- Enable JWT authentication (see `~/tt-claw/deployment/jwt-setup.sh`)
- Try multi-chip deployment (p150x4 for 4x parallelism)
- Create custom adventures
- Benchmark performance

Enjoy your adventure! 🎮
