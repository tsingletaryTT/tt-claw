#!/bin/bash
# Shutdown all OpenClaw and vLLM services cleanly

BOLD='\033[1m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

echo -e "${BOLD}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${BOLD}Shutting Down OpenClaw Services${NC}"
echo -e "${BOLD}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""

# Function to stop a service
stop_service() {
    local name=$1
    local pattern=$2

    if pgrep -f "$pattern" > /dev/null 2>&1; then
        echo -e "${YELLOW}Stopping $name...${NC}"
        sudo pkill -f "$pattern" 2>/dev/null || pkill -f "$pattern" 2>/dev/null
        sleep 2

        if pgrep -f "$pattern" > /dev/null 2>&1; then
            echo -e "${RED}  Failed to stop gracefully, force killing...${NC}"
            sudo pkill -9 -f "$pattern" 2>/dev/null || pkill -9 -f "$pattern" 2>/dev/null
            sleep 1
        fi

        if ! pgrep -f "$pattern" > /dev/null 2>&1; then
            echo -e "${GREEN}  ✅ $name stopped${NC}"
        else
            echo -e "${RED}  ❌ Failed to stop $name${NC}"
        fi
    else
        echo -e "  $name not running"
    fi
}

# 1. Stop OpenClaw TUI (user sessions)
echo -e "${BOLD}1. OpenClaw TUI Sessions${NC}"
stop_service "OpenClaw TUI" "openclaw.*tui"
echo ""

# 2. Stop OpenClaw Gateway
echo -e "${BOLD}2. OpenClaw Gateway${NC}"
stop_service "OpenClaw Gateway" "openclaw-gateway"
echo ""

# 3. Stop vLLM Proxy
echo -e "${BOLD}3. vLLM Proxy${NC}"
stop_service "vLLM Proxy" "vllm-proxy.py"
echo ""

# 4. Stop vLLM Docker Container
echo -e "${BOLD}4. vLLM Docker Container${NC}"
if docker ps | grep -q "tt-inference-server"; then
    echo -e "${YELLOW}Stopping vLLM container...${NC}"
    CONTAINER_ID=$(docker ps | grep "tt-inference-server" | awk '{print $1}')
    docker stop "$CONTAINER_ID" 2>/dev/null

    if ! docker ps | grep -q "tt-inference-server"; then
        echo -e "${GREEN}  ✅ vLLM container stopped${NC}"
    else
        echo -e "${RED}  ❌ Failed to stop vLLM container${NC}"
    fi
else
    echo "  vLLM container not running"
fi
echo ""

# 5. Summary
echo -e "${BOLD}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${BOLD}Service Status${NC}"
echo -e "${BOLD}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""

# Check final status
ANYTHING_RUNNING=0

if pgrep -f "openclaw-gateway" > /dev/null 2>&1; then
    echo -e "${YELLOW}⚠️  OpenClaw Gateway still running${NC}"
    ANYTHING_RUNNING=1
else
    echo -e "${GREEN}✅ OpenClaw Gateway stopped${NC}"
fi

if pgrep -f "vllm-proxy" > /dev/null 2>&1; then
    echo -e "${YELLOW}⚠️  vLLM Proxy still running${NC}"
    ANYTHING_RUNNING=1
else
    echo -e "${GREEN}✅ vLLM Proxy stopped${NC}"
fi

if docker ps | grep -q "tt-inference-server"; then
    echo -e "${YELLOW}⚠️  vLLM Docker container still running${NC}"
    ANYTHING_RUNNING=1
else
    echo -e "${GREEN}✅ vLLM Docker container stopped${NC}"
fi

echo ""

if [ $ANYTHING_RUNNING -eq 0 ]; then
    echo -e "${GREEN}${BOLD}All services stopped cleanly! ✅${NC}"
else
    echo -e "${YELLOW}${BOLD}Some services may still be running ⚠️${NC}"
    echo ""
    echo "To force kill everything:"
    echo "  sudo pkill -9 -f openclaw"
    echo "  docker stop \$(docker ps -q --filter ancestor=ghcr.io/tenstorrent/tt-inference-server)"
fi

echo ""
echo -e "${BOLD}Next Steps:${NC}"
echo "  - Machine can be safely suspended/shutdown"
echo "  - vLLM weights cached in Docker volumes (no re-download needed)"
echo "  - OpenClaw config preserved in ~/.openclaw/"
echo ""
echo -e "${GREEN}Good night! 🌙${NC}"
echo ""
