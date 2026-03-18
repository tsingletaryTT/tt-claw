#!/bin/bash
# Test script to verify NO_REPLY fix

set -e

echo "🧪 Testing Adventure Games NO_REPLY Fix"
echo "========================================"
echo ""

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo "Test 1: Verify tools.json files removed"
echo "-----------------------------------------"
if [ -f ~/.openclaw/agents/chip-quest/agent/tools.json ]; then
    echo -e "${RED}✗ chip-quest tools.json still exists${NC}"
    exit 1
else
    echo -e "${GREEN}✓ chip-quest tools.json removed${NC}"
fi

if [ -f ~/.openclaw/agents/terminal-dungeon/agent/tools.json ]; then
    echo -e "${RED}✗ terminal-dungeon tools.json still exists${NC}"
    exit 1
else
    echo -e "${GREEN}✓ terminal-dungeon tools.json removed${NC}"
fi

if [ -f ~/.openclaw/agents/conference-chaos/agent/tools.json ]; then
    echo -e "${RED}✗ conference-chaos tools.json still exists${NC}"
    exit 1
else
    echo -e "${GREEN}✓ conference-chaos tools.json removed${NC}"
fi

echo ""
echo "Test 2: Verify SOUL files updated"
echo "----------------------------------"
if grep -q "show_ascii_map\|check_inventory\|encounter_grue\|roll_dice\|check_stats\|use_item\|show_floor_map\|npc_conversation\|collect_card" ~/.openclaw/agents/*/agent/SOUL.md; then
    echo -e "${RED}✗ SOUL files still reference non-existent tools${NC}"
    echo "Found in:"
    grep -l "show_ascii_map\|check_inventory\|encounter_grue\|roll_dice\|check_stats\|use_item\|show_floor_map\|npc_conversation\|collect_card" ~/.openclaw/agents/*/agent/SOUL.md
    exit 1
else
    echo -e "${GREEN}✓ SOUL files cleaned up (no tool references)${NC}"
fi

echo ""
echo "Test 3: Check services status"
echo "------------------------------"

# Check vLLM
if curl -s http://localhost:8000/health > /dev/null 2>&1; then
    echo -e "${GREEN}✓ vLLM running (port 8000)${NC}"
else
    echo -e "${RED}✗ vLLM not responding${NC}"
    exit 1
fi

# Check proxy
if curl -s http://localhost:8001/v1/models > /dev/null 2>&1; then
    echo -e "${GREEN}✓ Proxy running (port 8001)${NC}"
else
    echo -e "${RED}✗ Proxy not responding${NC}"
    exit 1
fi

# Check gateway
if pgrep -f "openclaw.*gateway" > /dev/null; then
    PID=$(pgrep -f "openclaw.*gateway")
    echo -e "${GREEN}✓ Gateway running (PID: $PID)${NC}"
else
    echo -e "${RED}✗ Gateway not running${NC}"
    exit 1
fi

echo ""
echo "Test 4: Quick agent response test"
echo "-----------------------------------"
echo "Testing chip-quest agent (30 second timeout)..."

RESPONSE=$(timeout 30 bash -c 'cd ~/openclaw && ./openclaw.sh agent --agent chip-quest --message "start the adventure" 2>/dev/null' || echo "TIMEOUT")

if [ "$RESPONSE" = "TIMEOUT" ]; then
    echo -e "${RED}✗ Agent timed out (NO_REPLY issue still present)${NC}"
    exit 1
elif [ -z "$RESPONSE" ]; then
    echo -e "${RED}✗ Agent returned empty response${NC}"
    exit 1
elif echo "$RESPONSE" | grep -qi "NO_REPLY"; then
    echo -e "${RED}✗ Agent returned NO_REPLY${NC}"
    exit 1
else
    echo -e "${GREEN}✓ Agent responded (response received)${NC}"
    echo "  First 100 chars: ${RESPONSE:0:100}..."
fi

echo ""
echo "Test 5: Check proxy log activity"
echo "---------------------------------"
if [ -s /tmp/vllm-proxy.log ]; then
    LINES=$(wc -l < /tmp/vllm-proxy.log)
    echo -e "${GREEN}✓ Proxy log has content ($LINES lines)${NC}"
else
    echo -e "${YELLOW}⚠  Proxy log is empty (requests may not be reaching vLLM)${NC}"
fi

echo ""
echo "========================================"
echo -e "${GREEN}✅ All basic tests passed!${NC}"
echo ""
echo "Next step: Test with TUI for full experience"
echo ""
echo "Run the adventure menu:"
echo "  cd ~/tt-claw/adventure-games/scripts"
echo "  ./adventure-menu.sh"
echo ""
echo "Or test directly:"
echo "  cd ~/openclaw"
echo "  ./openclaw.sh tui --session 'agent:chip-quest:main' --message 'start the adventure'"
echo ""
echo "Look for:"
echo "  ✓ ASCII art and opening narrative"
echo "  ✓ Token count in footer (e.g., 'tokens 8k/65k')"
echo "  ✓ NO 'NO_REPLY' messages"
echo "  ✓ Smooth conversation flow"
