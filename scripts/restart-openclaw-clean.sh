#!/bin/bash
# Clean restart of OpenClaw to pick up config changes

echo "=============================================="
echo "OpenClaw Clean Restart"
echo "=============================================="
echo ""

cd /home/ttclaw/openclaw

echo "1. Stopping gateway..."
./openclaw.sh gateway stop 2>/dev/null
sleep 2

echo "2. Clearing sessions..."
rm -rf /home/ttclaw/.openclaw/agents/*/sessions/*.json 2>/dev/null
echo "   ✓ Sessions cleared"

echo "3. Verifying config..."
MODEL_SUPPORTS_TOOLS=$(cat /home/ttclaw/.openclaw/openclaw.json | jq -r '.models.providers.vllm.models[0].supportsToolUse // "not set"')
echo "   - supportsToolUse: $MODEL_SUPPORTS_TOOLS"

echo "4. Checking vLLM server..."
if curl -s -o /dev/null -w "%{http_code}" http://localhost:8000/health | grep -q "200"; then
    echo "   ✓ vLLM server is healthy"
else
    echo "   ✗ vLLM server not responding!"
    exit 1
fi

echo ""
echo "5. Starting gateway..."
./openclaw.sh gateway run &
GATEWAY_PID=$!
echo "   ✓ Gateway started (PID: $GATEWAY_PID)"

sleep 3

echo ""
echo "=============================================="
echo "Ready! In a NEW terminal run:"
echo "  sudo su - ttclaw"
echo "  cd ~/openclaw"
echo "  ./openclaw.sh tui"
echo "=============================================="
echo ""
echo "Press Ctrl+C to stop gateway"
echo ""

wait $GATEWAY_PID
