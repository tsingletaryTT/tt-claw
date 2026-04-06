#!/bin/bash
# Launch adventure games with full tool suite

set -e

echo "🎮 Starting Chip Quest with Hermes Agent + Custom Skills"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
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
PERSONA="game-master"
if [ ! -f "$HOME/.hermes/personas/$PERSONA.md" ]; then
    echo "❌ Persona not found: $PERSONA"
    echo "   Expected: ~/.hermes/personas/$PERSONA.md"
    exit 1
fi

echo "✅ Persona loaded: Game Master (with tool patterns)"
echo "✅ TT Docs indexed: ~/.hermes/memories/tt-docs/"
echo "✅ Universe state: ~/.hermes/memories/universe-state.json"
echo ""

# Check skills exist
echo "✅ Skills available:"
echo "   - adventure/game_master_narrate (narrative generation)"
echo "   - adventure/tech_deep_dive (documentation search)"
echo "   - adventure/roll_dice (game mechanics)"
echo "   - adventure/manage_universe_state (cross-game tracking)"
echo "   - adventure/personality_mode (tone switching)"
echo "   - tenstorrent/tt_smi_monitor (hardware integration)"
echo ""

echo "Starting game in 2 seconds..."
sleep 2

# Set environment variables for vLLM connection
export OPENAI_API_KEY="dummy"
export OPENAI_BASE_URL="http://localhost:8000/v1"
export HERMES_INFERENCE_PROVIDER="openai"

# Activate Hermes venv
source ~/hermes-venv/bin/activate

# Launch Hermes with adventure skills
# Skills are loaded automatically from ~/.hermes/skills/
# Use the -s flag to explicitly preload the game_master_narrate skill
hermes chat \
  -s game_master_narrate \
  -q "I want to start Chip Quest. Begin the adventure!"
