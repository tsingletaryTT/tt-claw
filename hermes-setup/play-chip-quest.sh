#!/bin/bash
# Launch Chip Quest on Hermes Agent

set -e

PERSONA="archie"

echo "🎮 Starting Chip Quest on Hermes Agent"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

# Check vLLM
if ! curl -s http://localhost:8000/health > /dev/null 2>&1; then
    echo "❌ vLLM not running on port 8000"
    echo "   Start vLLM first, then try again"
    exit 1
fi

echo "✅ vLLM detected on port 8000"
MODEL=$(curl -s http://localhost:8000/v1/models | jq -r '.data[0].id')
echo "✅ Model: $MODEL"
echo ""

# Check persona exists
if [ ! -f "$HOME/.hermes/personas/$PERSONA.md" ]; then
    echo "❌ Persona not found: $PERSONA"
    echo "   Expected: ~/.hermes/personas/$PERSONA.md"
    exit 1
fi

echo "✅ Persona loaded: Archie (Chip Quest Game Master)"
echo "✅ TT Docs indexed: ~/.hermes/memories/tt-docs/"
echo "✅ Universe state: ~/.hermes/memories/universe-state.json"
echo ""
echo "Starting game in 2 seconds..."
sleep 2

# Start Hermes with environment variables for vLLM
export OPENAI_API_KEY="dummy"
export OPENAI_BASE_URL="http://localhost:8000/v1"
export HERMES_INFERENCE_PROVIDER="openai"

hermes chat -q "I want to start the adventure. Begin the game!"
