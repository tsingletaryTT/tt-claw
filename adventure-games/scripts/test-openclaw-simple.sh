#!/bin/bash
# Simple OpenClaw test script - tests without full onboarding

echo "🦞 OpenClaw Simple Test"
echo "======================="
echo

# Test 1: Check vLLM server
echo "1. Testing vLLM server (no auth)..."
HEALTH=$(curl -s http://127.0.0.1:8000/health 2>&1)
if [ "$HEALTH" == "OK" ]; then
    echo "   ✅ vLLM server is healthy"
else
    echo "   ❌ vLLM server not ready: $HEALTH"
    echo "   (Server may still be initializing - this is normal)"
fi
echo

# Test 2: Check models endpoint
echo "2. Testing models endpoint..."
MODELS=$(curl -s http://127.0.0.1:8000/v1/models 2>&1)
if echo "$MODELS" | grep -qE "(Llama|Qwen)"; then
    echo "   ✅ Models endpoint working"
    echo "$MODELS" | jq '.data[].id' 2>/dev/null || echo "$MODELS"
else
    echo "   ❌ Models endpoint not responding correctly"
    echo "   Response: ${MODELS:0:200}"
fi
echo

# Test 3: Simple completion test
echo "3. Testing simple completion..."
RESPONSE=$(curl -s -X POST http://127.0.0.1:8000/v1/completions \
  -H 'Content-Type: application/json' \
  -d '{
    "model": "Qwen/Qwen3-32B",
    "prompt": "2+2=",
    "max_tokens": 5,
    "temperature": 0
  }' 2>&1)

if echo "$RESPONSE" | grep -q "choices"; then
    echo "   ✅ Completion working"
    TEXT=$(echo "$RESPONSE" | jq -r '.choices[0].text' 2>/dev/null)
    echo "   Response: 2+2=${TEXT}"
else
    echo "   ⚠️  Completion test inconclusive"
    echo "   Response: ${RESPONSE:0:300}"
fi
echo

# Test 4: Check OpenClaw config
echo "4. Checking OpenClaw configuration..."
if sudo -u ttclaw test -f /home/ttclaw/openclaw/openclaw.json; then
    echo "   ✅ OpenClaw config exists"
    if sudo cat /home/ttclaw/openclaw/openclaw.json | grep -q "apiKey"; then
        echo "   ⚠️  Config still has apiKey field (should be removed)"
    else
        echo "   ✅ Config has no auth requirement"
    fi
else
    echo "   ❌ OpenClaw config not found"
fi
echo

# Test 5: OpenClaw version
echo "5. Checking OpenClaw installation..."
if sudo -u ttclaw bash -c 'cd /home/ttclaw/openclaw && npx openclaw --version' &>/dev/null; then
    VERSION=$(sudo -u ttclaw bash -c 'cd /home/ttclaw/openclaw && npx openclaw --version 2>/dev/null')
    echo "   ✅ OpenClaw v$VERSION installed"
else
    echo "   ❌ OpenClaw not installed or not accessible"
fi
echo

echo "======================="
echo "Test complete!"
echo
echo "If vLLM server is not ready:"
echo "  • Check logs: docker logs tt-inference-server-a48a4637"
echo "  • Wait longer (can take 5-15 minutes on first start)"
echo "  • Check container status: docker ps"
echo
echo "To test OpenClaw when server is ready:"
echo "  sudo -u ttclaw -i"
echo "  cd /home/ttclaw/openclaw"
echo "  ./openclaw.sh onboard --non-interactive --accept-risk"
echo
