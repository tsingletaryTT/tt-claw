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

# Step 3: Auto-detect vLLM models and create configuration
echo "📦 Auto-detecting vLLM models..."
mkdir -p "$OPENCLAW_AGENTS/main/agent"

python3 << 'PYEOF'
import json
import urllib.request
import sys
from pathlib import Path

def detect_vllm_models():
    """Detect models from vLLM server"""
    # Try proxy first, then direct
    for url in ["http://127.0.0.1:8001/v1/models", "http://127.0.0.1:8000/v1/models"]:
        try:
            req = urllib.request.Request(url, headers={"User-Agent": "OpenClaw-Setup"})
            with urllib.request.urlopen(req, timeout=3) as response:
                data = json.loads(response.read().decode())
                if data.get("data"):
                    port = "8001" if ":8001" in url else "8000"
                    return data["data"], port
        except Exception as e:
            continue
    return None, None

# Detect models
detected_models, port = detect_vllm_models()

if not detected_models:
    print("  ⚠️  vLLM server not running - using default configuration")
    print("     Start vLLM first for auto-detection")
    print("     Configuring with placeholder (update after starting vLLM)")

    # Create default config that will work once vLLM starts
    config = {
        "providers": {
            "vllm": {
                "baseUrl": "http://127.0.0.1:8001/v1",
                "api": "openai-completions",
                "apiKey": "sk-no-auth",
                "models": []
            }
        }
    }
    best_model = None
else:
    print(f"  ✓ Detected {len(detected_models)} model(s) from vLLM (port {port})")

    # Pick best model (prefer instruct/chat models, then by size)
    def model_score(model):
        model_id = model.get("id", "").lower()
        score = 0

        # Prefer instruct/chat models
        if "instruct" in model_id or "chat" in model_id:
            score += 100

        # Extract size (e.g., "70b", "8b")
        import re
        size_match = re.search(r'(\d+)b', model_id)
        if size_match:
            score += int(size_match.group(1))

        return score

    best_model = max(detected_models, key=model_score)

    print(f"  ✓ Selected best model: {best_model['id']}")

    # Convert vLLM models to OpenClaw format
    openclaw_models = []
    for model in detected_models:
        model_id = model.get("id", "")
        # Use model name as display name (last part after /)
        display_name = model_id.split("/")[-1] if "/" in model_id else model_id

        openclaw_models.append({
            "id": model_id,
            "name": display_name,
            "reasoning": False,
            "input": ["text"],
            "contextWindow": model.get("max_model_len", 65536),
            "maxTokens": 8192
        })

    # Use detected proxy port
    base_url = f"http://127.0.0.1:{port}/v1"

    config = {
        "providers": {
            "vllm": {
                "baseUrl": base_url,
                "api": "openai-completions",
                "apiKey": "sk-no-auth",
                "models": openclaw_models
            }
        }
    }

# Save models.json
models_path = Path.home() / ".openclaw" / "agents" / "main" / "agent" / "models.json"
with open(models_path, "w") as f:
    json.dump(config, f, indent=2)

print(f"  ✓ Created models.json with {len(config['providers']['vllm']['models'])} model(s)")

# Set global default if we have a best model
if best_model:
    config_path = Path.home() / ".openclaw" / "openclaw.json"
    if config_path.exists():
        with open(config_path) as f:
            global_config = json.load(f)

        if "agents" not in global_config:
            global_config["agents"] = {}
        if "defaults" not in global_config["agents"]:
            global_config["agents"]["defaults"] = {}
        if "model" not in global_config["agents"]["defaults"]:
            global_config["agents"]["defaults"]["model"] = {}

        global_config["agents"]["defaults"]["model"]["primary"] = f"vllm/{best_model['id']}"

        with open(config_path, "w") as f:
            json.dump(global_config, f, indent=4)

        print(f"  ✓ Set default: vllm/{best_model['id']}")

PYEOF

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
