# OpenClaw Tool Calling Fix

## Problem Diagnosed

OpenClaw agent executes tools but doesn't answer questions because **vLLM is missing tool calling configuration**.

### Evidence

Session logs show the model generating **text** that looks like function calls instead of actual tool calls:

```json
{
  "role": "assistant",
  "content": [
    {
      "type": "text",
      "text": "{\"type\": \"function\", \"name\": \"read\", \"parameters\": {\"path\": \"SKILL.md\"}}"
    }
  ]
}
```

**This is WRONG.** It should be a proper tool call structure, not a text string.

### Root Cause

vLLM server is running WITHOUT tool calling flags:

**Current (broken):**
```bash
python run_vllm_api_server.py \
  --model meta-llama/Llama-3.3-70B-Instruct \
  --tt-device p300x2 \
  --no-auth
```

**Required (working):**
```bash
python run_vllm_api_server.py \
  --model meta-llama/Llama-3.3-70B-Instruct \
  --tt-device p300x2 \
  --no-auth \
  --enable-auto-tool-choice \
  --tool-call-parser llama3_json
```

## Solution

Restart vLLM with tool calling flags enabled.

### Method 1: Direct Docker Command (Recommended)

This is the proven approach from your previous 8B setup:

```bash
cd ~/tt-claw
./scripts/start-vllm-70b-direct.sh
```

**What it does:**
1. Stops current vLLM container
2. Starts new container with tool calling flags
3. Uses same Docker image and model weights
4. Wait 10-30 minutes for model warmup

**Flags added:**
- `--enable-auto-tool-choice` - Enables automatic tool selection
- `--tool-call-parser llama3_json` - Uses Llama 3's JSON tool calling format

### Method 2: Via run.py (If Method 1 Fails)

```bash
cd ~/tt-claw
./scripts/start-vllm-70b-toolcalling.sh
```

This tries to pass flags via `--vllm-override-args` but may not work (known issue with run.py).

## Verification Steps

### 1. Wait for Warmup

After starting, vLLM needs 10-30 minutes to load the 70B model and compile traces.

**Monitor progress:**
```bash
docker logs -f tt-inference-server-70b
```

**Look for:**
- "Readiness file created" = ready
- No "tool" warnings or errors

### 2. Test Tool Calling

```bash
curl -X POST http://localhost:8000/v1/chat/completions \
  -H "Content-Type: application/json" \
  -d '{
    "model": "meta-llama/Llama-3.3-70B-Instruct",
    "messages": [{"role": "user", "content": "What is the weather?"}],
    "tools": [{
      "type": "function",
      "function": {
        "name": "get_weather",
        "parameters": {"type": "object", "properties": {}}
      }
    }],
    "max_tokens": 50
  }' | jq .
```

**Expected:** Tool call in response, NOT plain text

### 3. Test in OpenClaw

```bash
./bin/tt-claw restart  # Restart gateway
./bin/tt-claw tui      # Launch TUI
```

In TUI, ask:
```
What can you do?
```

**Expected behavior:**
- Agent searches memory with `memory_search` tool
- Agent synthesizes information from results
- Agent responds with actual answer, not just "I found information"

**Bad response:** `{"type": "function", ...}` as text
**Good response:** Actual answer about capabilities with citations

## Why This Happens

OpenClaw uses tool calling to interact with:
- `memory_search` - Search indexed documentation
- `read` - Read files
- `write` - Write files
- `bash` - Execute commands
- And more...

Without `--enable-auto-tool-choice` and `--tool-call-parser`, vLLM treats tools as part of the prompt but generates text responses instead of structured tool calls. The model "knows about" tools but can't actually call them.

## Configuration Files

### System Prompt (Already Correct)

`openclaw-runtime/agents/main/agent/system.md` has good instructions:
- "ALWAYS use memory_search first"
- "DO read the results and provide clear answers"
- "DON'T just say 'I found information'"

This is fine! The problem is vLLM, not the prompt.

### OpenClaw Config (Already Correct)

`openclaw-runtime/openclaw.json` has correct provider setup:
- Provider: vllm
- API: openai-completions
- Model: meta-llama/Llama-3.3-70B-Instruct
- Memory search: configured with extraPaths

This is fine! The problem is vLLM, not OpenClaw.

### vLLM Server (NEEDS FIX)

Current server command is missing:
- `--enable-auto-tool-choice`
- `--tool-call-parser llama3_json`

## Reference

This exact issue was encountered and solved for the 8B model. See:
- `~/tt-claw/CLAUDE.md` - Section "vLLM Tool Calling for OpenClaw (2026-03-11)"
- `docs/openclaw/VLLM_TOOL_CALLING_COMMAND.md` - Complete documentation

## After Fixing

Once vLLM restarts with tool calling:

✅ Agent will actually call tools
✅ Agent will read memory search results
✅ Agent will synthesize answers
✅ You'll see actual responses instead of JSON strings
✅ tt-claw will work as intended

---

**Created:** March 17, 2026
**Status:** Fix ready to apply
**Time to fix:** 1 minute + 10-30 min warmup
