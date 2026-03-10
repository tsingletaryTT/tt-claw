# 🔧 Root Cause Found & Fixed

## What Was Wrong

**The TUI wasn't reading the global config** - it was using **agent-specific configs** that had:

1. ❌ **Wrong port**: Pointing to `8001` (old proxy) instead of `8000` (actual vLLM server)
2. ❌ **No supportsToolUse setting**: Missing the flag that disables tool calling
3. ❌ **Stale sessions**: Cached sessions with old settings

## What I Fixed

✅ Updated `/home/ttclaw/.openclaw/agents/main/agent/models.json`:
   - Changed all `8001` → `8000`
   - Added `supportsToolUse: false` to all models
   - Added `supportsStreaming: true`

✅ Updated `/home/ttclaw/.openclaw/agents/tt-claw-qb2/agent/models.json`:
   - Same fixes as above

✅ Cleared all cached sessions:
   - Removed `~/.openclaw/agents/*/sessions/*.json`

## 🧪 Test the Fix

**Run this as ttclaw:**
```bash
sudo su - ttclaw
~/test-config.sh
```

This will:
- ✅ Verify vLLM server is running on port 8000
- ✅ Test text generation
- ✅ Check all configs (global + agent-specific)
- ✅ Try the chat command
- ✅ Report any remaining issues

## 🎮 Try Again Now

### Step 1: Stop and restart gateway
```bash
sudo su - ttclaw
cd ~/openclaw
./openclaw.sh gateway stop
./openclaw.sh gateway run &
```

### Step 2: Test with direct command first
```bash
./openclaw.sh chat -a main -m "Hello, describe this place"
```

If this works, the config is correct!

### Step 3: Try the TUI
```bash
./openclaw.sh tui
```

1. Select "main" agent (or any other)
2. Wait for `>` prompt
3. Type: `Hello, what is this place?`
4. Press Enter

## Expected Behavior

**Before fix:**
```
run error: 400 "auto" tool choice requires...
```

**After fix:**
```
> Hello, what is this place?

[LLM generates response about the dungeon/scene]
```

## If Still Not Working

Run the test script and share the output:
```bash
sudo su - ttclaw
~/test-config.sh 2>&1 | tee ~/test-results.txt
cat ~/test-results.txt
```

This will show exactly which step is failing.

## What Each Config Does

### Global config (`~/.openclaw/openclaw.json`):
```json
{
  "models": {
    "providers": {
      "vllm": {
        "baseUrl": "http://127.0.0.1:8000/v1",  ← Correct port
        "models": [{
          "supportsToolUse": false               ← No tool calling
        }]
      }
    }
  }
}
```

### Agent config (`~/.openclaw/agents/main/agent/models.json`):
```json
{
  "providers": {
    "vllm": {
      "baseUrl": "http://127.0.0.1:8000/v1",    ← Was 8001, now 8000
      "models": [{
        "supportsToolUse": false                ← Now added
      }]
    }
  }
}
```

**Agent configs override global config**, which is why fixing the global config alone didn't work!

## Summary

- ✅ Port 8000 (not 8001)
- ✅ supportsToolUse: false
- ✅ Sessions cleared
- ✅ Test script created

Try `~/test-config.sh` first to verify everything is working! 🎯
