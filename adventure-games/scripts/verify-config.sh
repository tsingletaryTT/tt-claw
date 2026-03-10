#!/bin/bash
# Verify OpenClaw configuration is correct

set -e

GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m'

echo -e "${CYAN}Verifying OpenClaw Configuration...${NC}"
echo ""

# Check 1: Global config has provider
echo -n "1. Global provider definition... "
if grep -q '"vllm"' ~/.openclaw/openclaw.json 2>/dev/null; then
    echo -e "${GREEN}✓${NC}"
else
    echo -e "${RED}✗ Missing${NC}"
    echo "   Run: ./setup-game-agents.sh"
    exit 1
fi

# Check 2: Main agent has models.json
echo -n "2. Main agent models.json... "
if [ -f ~/.openclaw/agents/main/agent/models.json ]; then
    echo -e "${GREEN}✓${NC}"
else
    echo -e "${RED}✗ Missing${NC}"
    exit 1
fi

# Check 3: Main agent has auth-profiles.json
echo -n "3. Main agent auth-profiles.json... "
if [ -f ~/.openclaw/agents/main/agent/auth-profiles.json ]; then
    echo -e "${GREEN}✓${NC}"
else
    echo -e "${RED}✗ Missing${NC}"
    exit 1
fi

# Check 4: Game agents have auth-profiles.json
echo -n "4. Game agents auth-profiles... "
missing=""
for agent in chip-quest terminal-dungeon conference-chaos; do
    if [ ! -f ~/.openclaw/agents/$agent/agent/auth-profiles.json ]; then
        missing="$missing $agent"
    fi
done
if [ -z "$missing" ]; then
    echo -e "${GREEN}✓${NC}"
else
    echo -e "${RED}✗ Missing:$missing${NC}"
    exit 1
fi

# Check 5: OpenClaw can see the API key
echo -n "5. OpenClaw API key... "
cd ~/openclaw
if ./openclaw.sh config get models.providers.vllm.apiKey 2>&1 | grep -q "REDACTED\|sk-"; then
    echo -e "${GREEN}✓ Found${NC}"
else
    echo -e "${RED}✗ Not found${NC}"
    exit 1
fi

# Check 6: Services running
echo -n "6. vLLM backend (8000)... "
if timeout 2 curl -s http://localhost:8000/health > /dev/null 2>&1; then
    echo -e "${GREEN}✓${NC}"
else
    echo -e "${YELLOW}Not running${NC}"
fi

echo -n "7. vLLM proxy (8001)... "
if timeout 2 curl -s http://localhost:8001/v1/models > /dev/null 2>&1; then
    echo -e "${GREEN}✓${NC}"
else
    echo -e "${YELLOW}Not running${NC}"
    echo "   Start: ./start-adventure-services.sh"
fi

echo -n "8. OpenClaw gateway (18789)... "
if pgrep -f "openclaw.*gateway" > /dev/null; then
    echo -e "${GREEN}✓${NC}"
else
    echo -e "${YELLOW}Not running${NC}"
    echo "   Start: ./start-adventure-services.sh"
fi

echo ""
echo -e "${GREEN}✅ Configuration verified!${NC}"
echo ""
echo "Ready to play:"
echo "  ./adventure-menu.sh"
