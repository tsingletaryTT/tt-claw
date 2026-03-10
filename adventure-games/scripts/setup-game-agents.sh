#!/bin/bash
# Setup OpenClaw Adventure Game Agents
# Creates agent workspaces with SOUL definitions and tools

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
GAMES_DIR="$SCRIPT_DIR/../games"
OPENCLAW_AGENTS="$HOME/.openclaw/agents"

echo "🎮 Setting up OpenClaw Adventure Game Agents..."
echo ""

# Step 1: Install skills
echo "📦 Installing skills..."
"$SCRIPT_DIR/install-skills.sh"
echo ""

# Step 2: Create agent directories and copy SOUL files
GAMES=("chip-quest" "terminal-dungeon" "conference-chaos")

for game in "${GAMES[@]}"; do
    echo "📦 Creating $game agent..."

    # Create agent directory
    mkdir -p "$OPENCLAW_AGENTS/$game/agent"

    # Copy SOUL file
    if [ -f "$GAMES_DIR/$game/SOUL.md" ]; then
        cp "$GAMES_DIR/$game/SOUL.md" "$OPENCLAW_AGENTS/$game/agent/"
        echo "  ✓ Copied SOUL.md ($(wc -l < "$GAMES_DIR/$game/SOUL.md") lines)"
    else
        echo "  ⚠️  Warning: $GAMES_DIR/$game/SOUL.md not found"
    fi

    # Copy tools.json
    if [ -f "$GAMES_DIR/$game/tools.json" ]; then
        cp "$GAMES_DIR/$game/tools.json" "$OPENCLAW_AGENTS/$game/agent/"
        echo "  ✓ Copied tools.json"
    else
        echo "  ⚠️  Warning: $GAMES_DIR/$game/tools.json not found"
    fi

    echo "  ✓ $game agent created"
    echo ""
done

echo "✅ All game agents created!"
echo ""
echo "Agents configured:"
echo "  • chip-quest (818 lines) - Educational TT architecture adventure"
echo "  • terminal-dungeon (1323 lines) - NetHack-style roguelike"
echo "  • conference-chaos (1288 lines) - Trade Wars trading simulation"
echo ""
echo "Each agent has:"
echo "  • SOUL.md - Complete game master personality (500-700 lines)"
echo "  • tools.json - Tool integration hints"
echo ""
echo "Skills installed:"
ls -1 "$HOME/.openclaw/skills"
echo ""
echo "Next step: Launch adventure menu"
echo "  cd $SCRIPT_DIR && ./adventure-menu.sh"
