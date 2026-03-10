# ✅ OpenClaw on QB2 - Setup Complete

**Date:** 2026-03-09
**Status:** Fully Working

## 🎯 What's Working

### vLLM Server
- ✅ Running on port 8000
- ✅ Tool calling enabled with `llama3_json` parser
- ✅ Model: Llama-3.1-8B-Instruct on QB2 P150 chip
- ✅ Context: 128K tokens
- ✅ No authentication required (--no-auth)

**Start command:**
```bash
cd /home/ttuser/code/tt-inference-server
python3 run.py \
  --model Llama-3.1-8B-Instruct \
  --tt-device p150 \
  --workflow server \
  --docker-server \
  --override-docker-image "ghcr.io/tenstorrent/tt-inference-server/vllm-tt-metal-src-dev-ubuntu-22.04-amd64:0.10.0-84b4c53-222ee06" \
  --no-auth \
  --vllm-override-args '{"enable_auto_tool_choice": true, "tool_call_parser": "llama3_json"}'
```

### OpenClaw
- ✅ Configured to use vLLM on port 8000
- ✅ Text generation working
- ✅ Tool calling supported
- ✅ Adventure games ready
- ✅ Gateway mode working (embedded fallback if gateway not running)

**Config location:** `~/.openclaw/openclaw.json` (ttclaw user)

## 🎮 How to Use

### As ttclaw User

```bash
# Switch to ttclaw user
sudo su - ttclaw
cd ~/openclaw

# Start gateway (optional - embedded mode works too)
./openclaw.sh gateway run &

# Option 1: Use TUI (interactive)
./openclaw.sh tui

# Option 2: Direct agent command
./openclaw.sh agent --agent main -m "Your message here"

# Option 3: Play adventure games
./openclaw.sh agent --agent chip-quest -m "Start the adventure"
./openclaw.sh agent --agent terminal-dungeon -m "Look around"
./openclaw.sh agent --agent conference-chaos -m "Begin"
```

### Available Scripts in ttclaw Home

All scripts in `/home/ttclaw/` are working:

1. **`./start-adventure.sh`** - Quick launcher (checks vLLM, starts gateway)
2. **`./test-simple.sh`** - Test vLLM and OpenClaw
3. **`./test-config.sh`** - Test configuration
4. **`./restart-gateway.sh`** - Restart gateway with clean config
5. **`./restart-openclaw.sh`** - Full restart

### Available Scripts in tt-claw Repo

All scripts in `/home/ttuser/tt-claw/scripts/` are working:

1. **`restart-gateway-clean.sh`** - Restart with config verification
2. **`restart-openclaw-clean.sh`** - Clean restart
3. **`test-openclaw-simple.sh`** - Simple health tests
4. **`test-openclaw-connection.sh`** - Connection tests

**Note:** The proxy script (`vllm-openclaw-proxy.py`) is NOT needed - we enabled tool calling directly in vLLM instead.

## 📝 Configuration Files

### Active Configs

**`~/.openclaw/openclaw.json`** (ttclaw user):
```json
{
  "models": {
    "providers": {
      "vllm": {
        "baseUrl": "http://127.0.0.1:8000/v1",
        "api": "openai-completions",
        "apiKey": "sk-no-auth",
        "models": [{
          "id": "meta-llama/Llama-3.1-8B-Instruct",
          "name": "Llama 3.1 8B on QB2",
          "contextWindow": 128000,
          "maxTokens": 8192,
          "supportsToolUse": true,
          "supportsStreaming": true
        }]
      }
    }
  },
  "agents": {
    "defaults": {
      "model": {
        "primary": "vllm/meta-llama/Llama-3.1-8B-Instruct"
      },
      "workspace": "/home/ttclaw/workspace"
    }
  },
  "gateway": {
    "port": 18789,
    "mode": "local",
    "bind": "loopback"
  }
}
```

**Note:** The `supportsToolUse` and `supportsStreaming` fields appear to work now (or are ignored by OpenClaw).

### vLLM Server Config

Modified `/home/ttuser/code/tt-inference-server/workflows/run_docker_server.py`:
- Lines 302-313: Added tool calling flag support from model spec

## 🧪 Test Results

**Direct vLLM API:**
```bash
curl http://localhost:8000/v1/chat/completions \
  -H "Content-Type: application/json" \
  -d '{
    "model": "meta-llama/Llama-3.1-8B-Instruct",
    "messages": [{"role": "user", "content": "What is 2+2?"}],
    "tools": [{"type": "function", "function": {"name": "calculate", ...}}],
    "tool_choice": "auto"
  }'
```
✅ Returns proper tool call (not 400 error)

**OpenClaw Agent:**
```bash
./openclaw.sh agent --agent main -m "Tell me a joke"
```
✅ Returns joke response

**Test Scripts:**
```bash
./test-simple.sh
```
✅ All tests pass

## 🎮 Adventure Games

All adventure agents are working:

- **chip-quest** - Chip Quest with Archie
- **terminal-dungeon** - Terminal Dungeon
- **conference-chaos** - Conference Chaos
- **main** - General assistant

Example gameplay:
```bash
sudo su - ttclaw
cd ~/openclaw
./openclaw.sh agent --agent terminal-dungeon -m "You awaken in a dark dungeon. Describe what you see."
./openclaw.sh agent --agent terminal-dungeon -m "Examine the walls"
./openclaw.sh agent --agent terminal-dungeon -m "Go north"
```

## 🔧 Troubleshooting

**If OpenClaw times out:**
- Check vLLM server: `curl http://localhost:8000/health`
- Verify config: `cat ~/.openclaw/openclaw.json | jq .models.providers.vllm`
- Clear sessions: `rm -rf ~/.openclaw/agents/*/sessions/*.jsonl`

**If gateway fails:**
- Gateway is optional - embedded mode works fine
- The "Gateway agent failed; falling back to embedded" message is normal

**If you see old provider configs:**
- Delete: `rm -rf ~/.openclaw/agents/*/agent/models.json`
- The global config in `~/.openclaw/openclaw.json` takes precedence

## 📚 Documentation

Additional docs in `/home/ttuser/tt-claw/`:
- `TOOL_CALLING_EXPLAINED.md` - How tool calling works
- `FINAL_SETUP.md` - Previous setup notes
- `TROUBLESHOOTING.md` - Common issues
- `docs/` - Archive of setup history

## 🎉 Success Criteria

All requirements met:

- ✅ vLLM server running on QB2 hardware
- ✅ Tool calling enabled and working
- ✅ OpenClaw configured correctly
- ✅ Adventure games playable
- ✅ All scripts working
- ✅ Both repo scripts and user scripts functional

**Ready to play!** 🚀
