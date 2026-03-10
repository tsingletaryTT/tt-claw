#!/bin/bash
# Stop all TT-CLAW adventure game services

set -e

# Colors
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m'

echo -e "${CYAN}Stopping TT-CLAW Adventure Services...${NC}"
echo ""

# Stop gateway
echo -n "Stopping OpenClaw gateway... "
if pgrep -f "openclaw.*gateway" > /dev/null; then
    pkill -f "openclaw.*gateway"
    sleep 2
    if pgrep -f "openclaw.*gateway" > /dev/null; then
        echo -e "${YELLOW}⚠️  Still running, force killing...${NC}"
        pkill -9 -f "openclaw.*gateway"
        sleep 1
    fi
    echo -e "${GREEN}✓ Stopped${NC}"
else
    echo -e "${YELLOW}Not running${NC}"
fi

# Stop proxy
echo -n "Stopping vLLM proxy... "
if pgrep -f "vllm-proxy" > /dev/null; then
    pkill -f "vllm-proxy"
    sleep 1
    if pgrep -f "vllm-proxy" > /dev/null; then
        echo -e "${YELLOW}⚠️  Still running, force killing...${NC}"
        pkill -9 -f "vllm-proxy"
        sleep 1
    fi
    echo -e "${GREEN}✓ Stopped${NC}"
else
    echo -e "${YELLOW}Not running${NC}"
fi

# Check vLLM (informational - don't stop it)
echo -n "vLLM backend status... "
if timeout 2 curl -s http://localhost:8000/health > /dev/null 2>&1; then
    echo -e "${CYAN}Running (not stopped - use docker to manage)${NC}"
else
    echo -e "${YELLOW}Not running${NC}"
fi

echo ""
echo -e "${GREEN}✅ Services stopped!${NC}"
echo ""
echo "Logs preserved:"
echo "  Proxy:   /tmp/vllm-proxy*.log"
echo "  Gateway: /tmp/openclaw-gateway*.log"
echo ""
echo "To restart:"
echo "  cd ~/tt-claw/adventure-games/scripts"
echo "  ./start-adventure-services.sh"
