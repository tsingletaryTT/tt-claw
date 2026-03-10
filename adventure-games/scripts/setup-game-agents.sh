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

# Step 3: Create main agent with vLLM-only configuration
echo "📦 Creating main agent with vLLM-only model config..."
mkdir -p "$OPENCLAW_AGENTS/main/agent"

cat > "$OPENCLAW_AGENTS/main/agent/models.json" << 'MODELS_EOF'
{
  "providers": {
    "vllm": {
      "baseUrl": "http://127.0.0.1:8001/v1",
      "api": "openai-completions",
      "apiKey": "sk-no-auth",
      "models": [
        {
          "id": "meta-llama/Llama-3.1-8B-Instruct",
          "name": "Llama 3.1 8B Instruct",
          "reasoning": false,
          "input": ["text"],
          "contextWindow": 65536,
          "maxTokens": 8192
        }
      ]
    }
  }
}
MODELS_EOF

echo "  ✓ Created main agent with vLLM provider"
echo "  ✓ Configured for local model only (no remote APIs)"
echo ""

# Step 4: Set global default model
echo "📦 Configuring global default model..."
if [ ! -f "$HOME/.openclaw/openclaw.json" ]; then
    echo "  ⚠️  OpenClaw not configured yet"
    echo "     Run: cd ~/openclaw && ./openclaw.sh config set gateway.mode local"
else
    python3 << 'PYEOF'
import json
from pathlib import Path

config_path = Path.home() / ".openclaw" / "openclaw.json"
with open(config_path) as f:
    config = json.load(f)

# Set default model to vllm
if "agents" not in config:
    config["agents"] = {}
if "defaults" not in config["agents"]:
    config["agents"]["defaults"] = {}
if "model" not in config["agents"]["defaults"]:
    config["agents"]["defaults"]["model"] = {}

config["agents"]["defaults"]["model"]["primary"] = "vllm/meta-llama/Llama-3.1-8B-Instruct"

with open(config_path, "w") as f:
    json.dump(config, f, indent=4)

print("  ✓ Set vllm/meta-llama/Llama-3.1-8B-Instruct as default")
PYEOF
fi
echo ""

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
