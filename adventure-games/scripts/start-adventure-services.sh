#!/bin/bash
# Start all services needed for TT-CLAW adventure games
# This script starts proxy and gateway in the background

set -e

OPENCLAW_DIR="$HOME/openclaw"
LOG_DIR="/tmp"

# Colors
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m'

echo -e "${CYAN}Starting TT-CLAW Adventure Services...${NC}"
echo ""

# Function to check if port is in use
check_port() {
    local port=$1
    netstat -tlnp 2>/dev/null | grep -q ":$port " && return 0 || return 1
}

# Function to wait for service
wait_for_service() {
    local url=$1
    local name=$2
    local max_wait=10
    local count=0

    echo -n "  Waiting for $name..."
    while [ $count -lt $max_wait ]; do
        if timeout 2 curl -s "$url" > /dev/null 2>&1; then
            echo -e " ${GREEN}✓${NC}"
            return 0
        fi
        echo -n "."
        sleep 1
        count=$((count + 1))
    done
    echo -e " ${RED}✗ Timeout${NC}"
    return 1
}

# Step 1: Check vLLM backend
echo "Step 1: Checking vLLM backend (port 8000)..."
if timeout 3 curl -s http://localhost:8000/health > /dev/null 2>&1; then
    MODEL=$(curl -s http://localhost:8000/v1/models 2>/dev/null | python3 -c "import sys, json; data=json.load(sys.stdin); print(data['data'][0]['id'] if data.get('data') else 'Unknown')" 2>/dev/null || echo "Unknown")
    echo -e "  ${GREEN}✓ vLLM running${NC} (Model: $MODEL)"
else
    echo -e "  ${RED}✗ vLLM not running${NC}"
    echo ""
    echo "You need to start vLLM first!"
    echo ""
    echo "Options:"
    echo "  1. Docker: cd ~/code/tt-inference-server && python3 run.py ..."
    echo "  2. Direct: cd ~ && ./run-70b-vllm.sh <model>"
    echo ""
    echo "See: ~/tt-claw/START_SERVICES.md for details"
    exit 1
fi
echo ""

# Step 2: Start proxy (if not running)
echo "Step 2: Starting vLLM proxy (port 8001)..."
if check_port 8001; then
    echo -e "  ${YELLOW}⚠️  Port 8001 already in use${NC}"
    if timeout 2 curl -s http://localhost:8001/v1/models > /dev/null 2>&1; then
        echo -e "  ${GREEN}✓ Proxy already running${NC}"
    else
        echo -e "  ${RED}✗ Port in use by non-proxy process${NC}"
        echo "  Run: lsof -ti:8001 | xargs kill -9"
        exit 1
    fi
else
    if [ ! -f "$OPENCLAW_DIR/vllm-proxy.py" ]; then
        echo -e "  ${RED}✗ vllm-proxy.py not found${NC}"
        echo "  Expected: $OPENCLAW_DIR/vllm-proxy.py"
        echo "  See: ~/tt-claw/OPENCLAW_FINAL_INSTRUCTIONS.md"
        exit 1
    fi

    cd "$OPENCLAW_DIR"
    nohup python3 vllm-proxy.py > "$LOG_DIR/vllm-proxy.log" 2>&1 &
    PROXY_PID=$!
    echo "  Started proxy (PID: $PROXY_PID)"

    # Wait for proxy
    if ! wait_for_service "http://localhost:8001/v1/models" "proxy"; then
        echo -e "  ${RED}ERROR: Proxy failed to start!${NC}"
        echo "  Logs: tail $LOG_DIR/vllm-proxy.log"
        kill $PROXY_PID 2>/dev/null || true
        exit 1
    fi
fi
echo ""

# Step 3: Start gateway (if not running)
echo "Step 3: Starting OpenClaw gateway (port 18789)..."
if pgrep -f "openclaw.*gateway" > /dev/null; then
    echo -e "  ${GREEN}✓ Gateway already running${NC}"
else
    if [ ! -f "$OPENCLAW_DIR/openclaw.sh" ]; then
        echo -e "  ${RED}✗ OpenClaw not found${NC}"
        echo "  Run: cd ~/tt-claw/adventure-games/scripts && ./install-openclaw.sh"
        exit 1
    fi

    cd "$OPENCLAW_DIR"
    nohup ./openclaw.sh gateway run > "$LOG_DIR/openclaw-gateway.log" 2>&1 &
    GATEWAY_PID=$!
    echo "  Started gateway (PID: $GATEWAY_PID)"

    # Wait for gateway
    sleep 3
    if ! pgrep -f "openclaw.*gateway" > /dev/null; then
        echo -e "  ${RED}ERROR: Gateway failed to start!${NC}"
        echo ""
        echo "  Common causes:"

        # Check if dist directory exists
        if [ ! -d "$OPENCLAW_DIR/dist" ]; then
            echo -e "  ${YELLOW}✗ OpenClaw not built (dist/ missing)${NC}"
            echo "    Fix: cd $OPENCLAW_DIR && npm run build"
        fi

        # Check if node_modules exists
        if [ ! -d "$OPENCLAW_DIR/node_modules" ]; then
            echo -e "  ${YELLOW}✗ Dependencies not installed${NC}"
            echo "    Fix: cd $OPENCLAW_DIR && npm install"
        fi

        echo ""
        echo "  Full logs: tail $LOG_DIR/openclaw-gateway.log"
        echo ""
        echo "  Quick fix: Reinstall OpenClaw"
        echo "    cd ~/tt-claw/adventure-games/scripts && ./install-openclaw.sh"

        kill $GATEWAY_PID 2>/dev/null || true
        exit 1
    fi
    echo -e "  ${GREEN}✓ Gateway running${NC}"
fi
echo ""

# Summary
echo -e "${GREEN}✅ All services started!${NC}"
echo ""
echo "Service Status:"
echo "  vLLM:    http://localhost:8000 (Model: $MODEL)"
echo "  Proxy:   http://localhost:8001 (Compatibility layer)"
echo "  Gateway: ws://localhost:18789 (Agent manager)"
echo ""
echo "Logs:"
echo "  Proxy:   tail -f $LOG_DIR/vllm-proxy.log"
echo "  Gateway: tail -f $LOG_DIR/openclaw-gateway.log"
echo ""
echo "Next step:"
echo "  cd ~/tt-claw/adventure-games/scripts && ./adventure-menu.sh"
echo ""
echo "To stop services:"
echo "  pkill -f vllm-proxy"
echo "  pkill -f 'openclaw.*gateway'"
