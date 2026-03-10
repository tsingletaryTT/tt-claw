#!/bin/bash
# Simple OpenClaw test - just the essentials

echo "=============================================="
echo "OpenClaw Simple Test"
echo "=============================================="
echo ""

cd /home/ttclaw/openclaw

# Test 1: vLLM server
echo "1. Testing vLLM server on port 8000..."
HTTP_CODE=$(curl -s -o /dev/null -w "%{http_code}" http://localhost:8000/health)
if [ "$HTTP_CODE" = "200" ]; then
    echo "   ✅ vLLM server is healthy"
else
    echo "   ❌ vLLM server not responding (HTTP $HTTP_CODE)"
    exit 1
fi

# Test 2: Direct text generation
echo ""
echo "2. Testing direct text generation..."
TEXT=$(curl -s http://localhost:8000/v1/completions \
  -H "Content-Type: application/json" \
  -d '{"model": "meta-llama/Llama-3.1-8B-Instruct", "prompt": "You are in a dungeon.", "max_tokens": 20}' \
  | jq -r '.choices[0].text // .error')

if [ "$TEXT" != "null" ] && [ "$TEXT" != "" ] && [ "$TEXT" != "Unauthorized" ]; then
    echo "   ✅ Generated: $TEXT"
else
    echo "   ❌ Generation failed: $TEXT"
    exit 1
fi

# Test 3: Check configs
echo ""
echo "3. Checking OpenClaw configs..."
GLOBAL_TOOL=$(cat ~/.openclaw/openclaw.json | jq -r '.models.providers.vllm.models[0].supportsToolUse // "not set"')
echo "   - Global supportsToolUse: $GLOBAL_TOOL"

# Test 4: Gateway status
echo ""
echo "4. Checking gateway..."
GATEWAY_PID=$(pgrep -f "openclaw.*gateway" || echo "")
if [ -n "$GATEWAY_PID" ]; then
    echo "   ✅ Gateway is running (PID: $GATEWAY_PID)"
    GATEWAY_RUNNING=1
else
    echo "   ⚠️  Gateway is not running"
    GATEWAY_RUNNING=0
fi

# Test 5: Try agent command
echo ""
echo "5. Testing OpenClaw agent command..."
if [ $GATEWAY_RUNNING -eq 1 ]; then
    echo "   Running: ./openclaw.sh agent --agent main -m 'Test message'"
    AGENT_RESULT=$(timeout 30 ./openclaw.sh agent --agent main -m "Describe a dungeon in one sentence" 2>&1)
    AGENT_EXIT=$?

    if [ $AGENT_EXIT -eq 0 ]; then
        echo "   ✅ Agent command succeeded!"
        echo "   Response preview:"
        echo "$AGENT_RESULT" | head -3 | sed 's/^/      /'
    elif [ $AGENT_EXIT -eq 124 ]; then
        echo "   ⏱️  Agent command timed out (30s)"
    else
        echo "   ❌ Agent command failed (exit: $AGENT_EXIT)"
        echo "   Error:"
        echo "$AGENT_RESULT" | head -5 | sed 's/^/      /'
    fi
else
    echo "   ⚠️  Skipping (gateway not running)"
fi

echo ""
echo "=============================================="
echo "Test Complete"
echo "=============================================="
echo ""

if [ $GATEWAY_RUNNING -eq 0 ]; then
    echo "To start the gateway:"
    echo "  cd ~/openclaw"
    echo "  ./openclaw.sh gateway run &"
    echo ""
fi

echo "To try the TUI:"
echo "  cd ~/openclaw"
echo "  ./openclaw.sh tui"
echo ""
