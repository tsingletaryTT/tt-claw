#!/bin/bash
# Complete restart script for adventure games

set -e

echo "🔄 Complete Adventure Games Restart"
echo ""

# Step 1: Stop gateway
echo "1️⃣ Stopping gateway..."
pkill -f openclaw-gateway 2>/dev/null || echo "   Gateway not running"
sleep 2

# Step 2: Clear old sessions (they have old SOUL cached)
echo ""
echo "2️⃣ Clearing cached sessions..."
for agent in chip-quest terminal-dungeon conference-chaos; do
    session_dir=~/.openclaw/agents/$agent/sessions
    if [ -d "$session_dir" ]; then
        echo "   Clearing $agent sessions..."
        rm -f $session_dir/*.jsonl
        echo '{"activeSessions":[]}' > $session_dir/sessions.json
    fi
done

# Step 2.5: Seed initial memory (adventure already begun)
echo ""
echo "2️⃣.5 Seeding initial memory..."
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
MEMORY_TEMPLATES="$SCRIPT_DIR/../memory-templates"
DATE=$(date +%Y-%m-%d)

for agent in chip-quest terminal-dungeon conference-chaos; do
    memory_dir=~/.openclaw/workspace-$agent/memory
    template="$MEMORY_TEMPLATES/${agent}-start.md"

    if [ -f "$template" ]; then
        mkdir -p "$memory_dir"
        cp "$template" "$memory_dir/$DATE.md"
        echo "   ✅ Seeded $agent memory ($DATE.md)"
    else
        echo "   ⚠️  No template for $agent (expected: $template)"
    fi
done

# Step 3: Verify configs
echo ""
echo "3️⃣ Verifying configurations..."
for agent in chip-quest terminal-dungeon conference-chaos; do
    context=$(cat ~/.openclaw/agents/$agent/agent/models.json 2>/dev/null | jq -r '.providers.vllm.models[0].contextWindow' || echo "ERROR")
    critical=$(grep -c "CRITICAL: Tool Usage" ~/.openclaw/agents/$agent/agent/SOUL.md || echo "0")

    if [ "$context" = "65536" ] && [ "$critical" -gt "0" ]; then
        echo "   ✅ $agent: 65K context, CRITICAL section present"
    else
        echo "   ⚠️  $agent: context=$context, critical=$critical (may have issues)"
    fi
done

echo ""
echo "4️⃣ Ready to restart!"
echo ""
echo "In terminal 1 (proxy - should already be running):"
echo "  cd ~/openclaw && python3 vllm-proxy.py"
echo ""
echo "In terminal 2 (gateway):"
echo "  cd ~/openclaw && ./openclaw.sh gateway run"
echo ""
echo "In terminal 3 (TUI):"
echo "  cd ~/openclaw && ./openclaw.sh tui --session 'agent:chip-quest:main' --message 'start the adventure'"
echo ""
echo "Or use the menu:"
echo "  cd ~/tt-claw/adventure-games/scripts && ./adventure-menu.sh"
echo ""
