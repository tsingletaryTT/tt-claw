#!/bin/bash
# Test OpenClaw configuration and connection to vLLM

echo "=============================================="
echo "OpenClaw Configuration Test"
echo "=============================================="
echo ""

cd /home/ttclaw

echo "1. Checking vLLM server..."
HTTP_CODE=$(curl -s -o /dev/null -w "%{http_code}" http://localhost:8000/health)
if [ "$HTTP_CODE" = "200" ]; then
    echo "   ✅ vLLM server responding on port 8000"
else
    echo "   ❌ vLLM server not responding (got HTTP $HTTP_CODE)"
    exit 1
fi

echo ""
echo "2. Testing text generation..."
RESPONSE=$(curl -s http://localhost:8000/v1/completions \
  -H "Content-Type: application/json" \
  -d '{
    "model": "meta-llama/Llama-3.1-8B-Instruct",
    "prompt": "Hello",
    "max_tokens": 10
  }' | jq -r '.choices[0].text // .error')

if [ "$RESPONSE" != "null" ] && [ "$RESPONSE" != "" ]; then
    echo "   ✅ Generated text: $RESPONSE"
else
    echo "   ❌ Failed to generate text"
    exit 1
fi

echo ""
echo "3. Checking global OpenClaw config..."
GLOBAL_TOOL_USE=$(cat ~/.openclaw/openclaw.json | jq -r '.models.providers.vllm.models[0].supportsToolUse // "not set"')
GLOBAL_PORT=$(cat ~/.openclaw/openclaw.json | jq -r '.models.providers.vllm.baseUrl' | grep -o ':[0-9]*' | grep -o '[0-9]*')
echo "   - Global port: $GLOBAL_PORT"
echo "   - Global supportsToolUse: $GLOBAL_TOOL_USE"

echo ""
echo "4. Checking agent-specific configs..."
for agent_dir in ~/.openclaw/agents/*/agent; do
    if [ -f "$agent_dir/models.json" ]; then
        agent_name=$(basename $(dirname "$agent_dir"))
        # Check for any port 8001 references
        if grep -q "8001" "$agent_dir/models.json" 2>/dev/null; then
            echo "   ❌ Agent '$agent_name' still has port 8001!"
        else
            echo "   ✅ Agent '$agent_name' config OK"
        fi
    fi
done

echo ""
echo "5. Testing OpenClaw chat command..."
cd ~/openclaw
CHAT_RESULT=$(timeout 30 ./openclaw.sh chat -a main -m "Say hello" 2>&1)
CHAT_EXIT_CODE=$?

if [ $CHAT_EXIT_CODE -eq 0 ]; then
    echo "   ✅ Chat command succeeded"
    echo "   Response preview: $(echo "$CHAT_RESULT" | head -2)"
elif [ $CHAT_EXIT_CODE -eq 124 ]; then
    echo "   ⏱️  Chat command timed out (30s) - server may be slow"
else
    echo "   ❌ Chat command failed (exit code: $CHAT_EXIT_CODE)"
    echo "   Error: $CHAT_RESULT"
fi

echo ""
echo "=============================================="
echo "Configuration Test Complete"
echo "=============================================="
echo ""
echo "If all tests passed, try:"
echo "  cd ~/openclaw"
echo "  ./openclaw.sh gateway stop"
echo "  ./openclaw.sh gateway run &"
echo "  ./openclaw.sh tui"
echo ""
