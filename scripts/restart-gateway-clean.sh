#!/bin/bash
# Restart OpenClaw gateway to pick up config changes

cd /home/ttclaw/openclaw

echo "=============================================="
echo "Restarting OpenClaw Gateway"
echo "=============================================="
echo ""

echo "1. Stopping gateway..."
./openclaw.sh gateway stop
sleep 2

# Kill any stuck processes
STUCK_PIDS=$(pgrep -f "openclaw.*gateway")
if [ -n "$STUCK_PIDS" ]; then
    echo "   Killing stuck gateway processes: $STUCK_PIDS"
    kill -9 $STUCK_PIDS 2>/dev/null
    sleep 1
fi

echo "   ✅ Gateway stopped"
echo ""

echo "2. Clearing cached sessions..."
rm -rf ~/.openclaw/agents/*/sessions/*.json 2>/dev/null
echo "   ✅ Sessions cleared"
echo ""

echo "3. Verifying config..."
TOOL_USE=$(cat ~/.openclaw/openclaw.json | jq '.models.providers.vllm.models[0].supportsToolUse')
API_MODE=$(cat ~/.openclaw/openclaw.json | jq -r '.models.providers.vllm.api')
BASE_URL=$(cat ~/.openclaw/openclaw.json | jq -r '.models.providers.vllm.baseUrl')

echo "   - API mode: $API_MODE"
echo "   - Base URL: $BASE_URL"
echo "   - supportsToolUse: $TOOL_USE"

if [ "$TOOL_USE" = "false" ]; then
    echo "   ✅ Tool calling is disabled"
else
    echo "   ⚠️  Warning: supportsToolUse is not false!"
fi
echo ""

echo "4. Starting gateway with fresh config..."
./openclaw.sh gateway run &
GATEWAY_PID=$!
sleep 5

# Check if it actually started
NEW_PID=$(pgrep -f "openclaw.*gateway" | head -1)
if [ -n "$NEW_PID" ]; then
    echo "   ✅ Gateway started (PID: $NEW_PID)"
else
    echo "   ❌ Gateway failed to start"
    exit 1
fi
echo ""

echo "5. Testing agent command..."
sleep 2
TEST_RESULT=$(timeout 20 ./openclaw.sh agent --agent main -m "Say hello in 5 words" 2>&1)
TEST_EXIT=$?

if [ $TEST_EXIT -eq 0 ]; then
    echo "   ✅ Agent command succeeded!"
    echo "   Response:"
    echo "$TEST_RESULT" | head -3 | sed 's/^/      /'
elif echo "$TEST_RESULT" | grep -q "400.*tool"; then
    echo "   ❌ Still getting 400 tool error!"
    echo "   This means the config isn't being read correctly."
    echo ""
    echo "   Try running the gateway in foreground to see errors:"
    echo "      ./openclaw.sh gateway stop"
    echo "      ./openclaw.sh gateway run"
else
    echo "   ⚠️  Command returned: $TEST_EXIT"
    echo "   Output:"
    echo "$TEST_RESULT" | head -5 | sed 's/^/      /'
fi

echo ""
echo "=============================================="
echo "Gateway Restart Complete"
echo "=============================================="
echo ""
echo "Gateway PID: $NEW_PID"
echo "Check logs: ./openclaw.sh gateway logs"
echo ""
