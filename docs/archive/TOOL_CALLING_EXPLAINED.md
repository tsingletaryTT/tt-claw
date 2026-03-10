# Tool Calling in vLLM - Explained

## Your Question: Model or vLLM Limitation?

**Answer: vLLM server configuration** (not model or hardware limitation)

## What's Happening

### vLLM Side (serving_chat.py):
```python
if request.tool_choice == "auto" and not self.enable_auto_tools:
    return self.create_error_response(
        "\"auto\" tool choice requires "
        "--enable-auto-tool-choice and --tool-call-parser to be set"
    )
```

### Translation:
- vLLM **CAN** do tool calling
- But it's **disabled by default**
- Needs `--enable-auto-tool-choice` and `--tool-call-parser <parser>` flags at startup

### OpenClaw Side:
- Sends `tool_choice: "auto"` in every request
- Even when `supportsToolUse: false` is set (config is ignored for this!)
- This triggers the vLLM error

## Model Capability

**Llama-3.1-8B-Instruct DOES support tool calling!**

Available parsers in vLLM:
- `llama3_json` - For Llama 3/3.1/3.2 models ✅
- `mistral` - For Mistral models
- `pythonic` - Python-style function calls
- `granite`, `phi4_mini_json`, etc.

## Two Solutions

### Option 1: Enable Tool Calling in vLLM (Full Featured)

**Restart vLLM server with tool support:**
```bash
docker stop $(docker ps | grep tt-inference-server | awk '{print $1}')

python3 run.py \
  --model Llama-3.1-8B-Instruct \
  --tt-device p150 \
  --workflow server \
  --docker-server \
  --no-auth \
  --vllm-override-args '{"enable_auto_tool_choice": true, "tool_call_parser": "llama3_json"}'
```

**Pros:**
- Full OpenAI API compatibility
- OpenClaw can use tools/functions
- More feature-complete

**Cons:**
- Slower inference (tool parsing overhead)
- More complex
- May have bugs in TT-Metal implementation

### Option 2: Use Compatibility Proxy (Simple)

**Keep vLLM as-is, strip tool_choice from requests:**

1. Start proxy:
   ```bash
   python3 ~/tt-claw/scripts/vllm-openclaw-proxy.py
   ```

2. Update OpenClaw config to use port 8001:
   ```bash
   # Point to proxy instead of direct vLLM
   baseUrl: "http://127.0.0.1:8001/v1"
   ```

**Pros:**
- No vLLM restart needed
- Faster inference (no tool overhead)
- Simpler
- Works right now

**Cons:**
- OpenClaw can't use tools
- Extra proxy layer

## What tt-inference-server Would Need

To enable tool calling from `run.py`, the codebase would need:

1. **Add flags to `run_docker_server.py`:**
   ```python
   if runtime_config.enable_tools:
       vllm_args.extend([
           "--enable-auto-tool-choice",
           "--tool-call-parser", "llama3_json"
       ])
   ```

2. **Add CLI flag:**
   ```bash
   python3 run.py --model Llama-3.1-8B-Instruct --enable-tools
   ```

3. **Or use `--vllm-override-args` (already works!):**
   ```bash
   --vllm-override-args '{"enable_auto_tool_choice": true, "tool_call_parser": "llama3_json"}'
   ```

## Recommendation

**For adventure games:** Use **Option 2 (proxy)** - you don't need tools, just text generation.

**For AI agents with tools:** Use **Option 1** - restart vLLM with tool support.

## Testing Tool Calling (If Enabled)

```bash
curl http://localhost:8000/v1/chat/completions \
  -H "Content-Type: application/json" \
  -d '{
    "model": "meta-llama/Llama-3.1-8B-Instruct",
    "messages": [{"role": "user", "content": "What is the weather in SF?"}],
    "tools": [{
      "type": "function",
      "function": {
        "name": "get_weather",
        "description": "Get weather for a city",
        "parameters": {
          "type": "object",
          "properties": {
            "city": {"type": "string"}
          },
          "required": ["city"]
        }
      }
    }],
    "tool_choice": "auto"
  }'
```

Should return a tool call instead of an error!

## Summary

**Not a limitation - just needs configuration:**
- ✅ Model supports it (Llama-3.1-8B-Instruct)
- ✅ vLLM supports it (with flags)
- ✅ TT hardware supports it
- ❌ Current server **not configured** for it

Choose which solution fits your use case! 🚀
