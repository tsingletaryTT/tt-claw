# Quick Fix Applied ✅

## What Was Fixed

### Issue 1: Script Location
- **Wrong**: `~/openclaw/start-adventure.sh`
- **Right**: `~/start-adventure.sh` (in home directory)

### Issue 2: Tool Choice Error
```
400 "auto" tool choice requires --enable-auto-tool-choice
```

**Fixed by**: Disabled tool calling in OpenClaw config
- Updated: `/home/ttclaw/.openclaw/openclaw.json`
- Added: `"supportsToolUse": false`
- This tells OpenClaw to use pure text generation (no function calling)

## ✅ Ready to Try Again

### Terminal 1 - Start Gateway:
```bash
sudo su - ttclaw
~/start-adventure.sh
```

### Terminal 2 - Launch TUI:
```bash
sudo su - ttclaw
cd ~/openclaw
./openclaw.sh tui
```

### In the TUI:
1. Select an adventure (arrow keys + Enter)
2. Try a command like: `"What is this?"`
3. Should now generate text without the 400 error

## What Changed in Config

The vLLM server doesn't support OpenAI's tool/function calling API. We disabled it so OpenClaw uses pure text generation instead:

```json
{
  "id": "meta-llama/Llama-3.1-8B-Instruct",
  "supportsToolUse": false,     ← Added this
  "supportsStreaming": true,    ← Added this
  "contextWindow": 65536
}
```

## If It Still Doesn't Work

**Restart the gateway:**
```bash
# Stop any running gateway
cd ~/openclaw
./openclaw.sh gateway stop

# Start fresh
~/start-adventure.sh
```

**Check server is responding:**
```bash
curl -s http://localhost:8000/v1/models | jq
# Should show: { "object": "list", "data": [...] }
```

Try it now! 🎮
