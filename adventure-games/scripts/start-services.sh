#!/bin/bash
# OpenClaw Service Manager
# Manages background services: vLLM proxy and OpenClaw gateway

set -e

# Auto-detect OpenClaw installation
if [ -n "$OPENCLAW_HOME" ]; then
    OPENCLAW_DIR="$OPENCLAW_HOME"
elif [ -d "$HOME/openclaw" ]; then
    OPENCLAW_DIR="$HOME/openclaw"
else
    echo -e "\033[0;31mERROR: OpenClaw not found.\033[0m"
    echo "Set OPENCLAW_HOME environment variable or install to ~/openclaw"
    exit 1
fi

PROXY_LOG="/tmp/openclaw-proxy.log"
GATEWAY_LOG="/tmp/openclaw-gateway.log"
PROXY_PID_FILE="/tmp/openclaw-proxy.pid"
GATEWAY_PID_FILE="/tmp/openclaw-gateway.pid"

# Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
CYAN='\033[0;36m'
NC='\033[0m'

show_help() {
    cat << HELP
OpenClaw Service Manager

USAGE:
    $0 [command]

COMMANDS:
    start       Start all services in background
    stop        Stop all services
    restart     Restart all services
    status      Show service status
    logs        Tail service logs
    help        Show this help

EXAMPLES:
    $0              # Start all services (default)
    $0 status       # Check if services are running
    $0 logs         # View real-time logs

SERVICES:
    - vLLM Proxy (port 8001) - API compatibility layer
    - OpenClaw Gateway (port 18789) - WebSocket server

LOGS:
    - Proxy: $PROXY_LOG
    - Gateway: $GATEWAY_LOG
HELP
}

# Check if vLLM is running (required)
check_vllm() {
    if curl -s http://127.0.0.1:8000/health > /dev/null 2>&1; then
        return 0
    else
        return 1
    fi
}

# Check if proxy is running
is_proxy_running() {
    if [ -f "$PROXY_PID_FILE" ]; then
        local pid=$(cat "$PROXY_PID_FILE")
        if kill -0 "$pid" 2>/dev/null; then
            return 0
        fi
    fi

    # Also check by port
    if lsof -i:8001 -t > /dev/null 2>&1; then
        return 0
    fi

    return 1
}

# Check if gateway is running
is_gateway_running() {
    if [ -f "$GATEWAY_PID_FILE" ]; then
        local pid=$(cat "$GATEWAY_PID_FILE")
        if kill -0 "$pid" 2>/dev/null; then
            return 0
        fi
    fi

    # Also check by process name
    if pgrep -f "openclaw.*gateway" > /dev/null 2>&1; then
        return 0
    fi

    return 1
}

# Start proxy service
start_proxy() {
    if is_proxy_running; then
        echo -e "${YELLOW}⚠️  Proxy already running${NC}"
        return 0
    fi

    echo -ne "${CYAN}Starting vLLM proxy...${NC}"

    # Start proxy in background
    cd "$OPENCLAW_DIR"
    nohup python3 vllm-proxy.py > "$PROXY_LOG" 2>&1 &
    local pid=$!
    echo $pid > "$PROXY_PID_FILE"

    # Wait for health check (max 10 seconds)
    local count=0
    while [ $count -lt 20 ]; do
        if curl -s http://127.0.0.1:8001/v1/models > /dev/null 2>&1; then
            echo -e " ${GREEN}✓${NC}"
            return 0
        fi
        sleep 0.5
        ((count++))
    done

    echo -e " ${RED}✗ (timeout)${NC}"
    return 1
}

# Start gateway service
start_gateway() {
    if is_gateway_running; then
        echo -e "${YELLOW}⚠️  Gateway already running${NC}"
        return 0
    fi

    echo -ne "${CYAN}Starting OpenClaw gateway...${NC}"

    # Start gateway in background
    cd "$OPENCLAW_DIR"
    nohup ./openclaw.sh gateway run > "$GATEWAY_LOG" 2>&1 &
    local pid=$!
    echo $pid > "$GATEWAY_PID_FILE"

    # Wait for gateway to be ready (check for WebSocket listener)
    local count=0
    while [ $count -lt 30 ]; do
        if grep -q "listening on ws://" "$GATEWAY_LOG" 2>/dev/null; then
            echo -e " ${GREEN}✓${NC}"
            return 0
        fi
        sleep 0.5
        ((count++))
    done

    echo -e " ${RED}✗ (timeout)${NC}"
    return 1
}

# Stop proxy service
stop_proxy() {
    echo -ne "${CYAN}Stopping vLLM proxy...${NC}"

    if [ -f "$PROXY_PID_FILE" ]; then
        local pid=$(cat "$PROXY_PID_FILE")
        if kill -0 "$pid" 2>/dev/null; then
            kill "$pid" 2>/dev/null || true
            rm -f "$PROXY_PID_FILE"
            echo -e " ${GREEN}✓${NC}"
            return 0
        fi
    fi

    # Try killing by port
    local pids=$(lsof -i:8001 -t 2>/dev/null || true)
    if [ -n "$pids" ]; then
        kill $pids 2>/dev/null || true
        echo -e " ${GREEN}✓${NC}"
        return 0
    fi

    echo -e " ${YELLOW}(not running)${NC}"
    return 0
}

# Stop gateway service
stop_gateway() {
    echo -ne "${CYAN}Stopping OpenClaw gateway...${NC}"

    if [ -f "$GATEWAY_PID_FILE" ]; then
        local pid=$(cat "$GATEWAY_PID_FILE")
        if kill -0 "$pid" 2>/dev/null; then
            kill "$pid" 2>/dev/null || true
            rm -f "$GATEWAY_PID_FILE"
            echo -e " ${GREEN}✓${NC}"
            return 0
        fi
    fi

    # Try killing by process name
    pkill -f "openclaw.*gateway" 2>/dev/null || true
    echo -e " ${GREEN}✓${NC}"
    return 0
}

# Show service status
cmd_status() {
    echo -e "${CYAN}═══ OpenClaw Service Status ═══${NC}"
    echo ""

    # vLLM (required)
    echo -ne "  vLLM (8000): "
    if check_vllm; then
        echo -e "${GREEN}✓ Running${NC}"
    else
        echo -e "${RED}✗ Not running (REQUIRED)${NC}"
    fi

    # Proxy
    echo -ne "  Proxy (8001): "
    if is_proxy_running; then
        local pid=$(cat "$PROXY_PID_FILE" 2>/dev/null || echo "unknown")
        echo -e "${GREEN}✓ Running${NC} (PID: $pid)"
    else
        echo -e "${YELLOW}✗ Not running${NC}"
    fi

    # Gateway
    echo -ne "  Gateway (18789): "
    if is_gateway_running; then
        local pid=$(cat "$GATEWAY_PID_FILE" 2>/dev/null || pgrep -f "openclaw.*gateway" || echo "unknown")
        echo -e "${GREEN}✓ Running${NC} (PID: $pid)"
    else
        echo -e "${YELLOW}✗ Not running${NC}"
    fi

    echo ""
}

# Start all services
cmd_start() {
    echo -e "${CYAN}🚀 Starting OpenClaw services...${NC}"
    echo ""

    # Check vLLM first
    if ! check_vllm; then
        echo -e "${RED}❌ vLLM is not running on port 8000!${NC}"
        echo -e "   Start vLLM before running OpenClaw services."
        return 1
    fi
    echo -e "${GREEN}✓ vLLM is running${NC}"

    # Start proxy
    if ! start_proxy; then
        echo -e "${RED}❌ Failed to start proxy${NC}"
        return 1
    fi

    # Start gateway
    if ! start_gateway; then
        echo -e "${RED}❌ Failed to start gateway${NC}"
        return 1
    fi

    echo ""
    echo -e "${GREEN}✅ All services started successfully!${NC}"
    echo ""
    echo -e "To launch games: ${CYAN}cd ~/openclaw && ./adventure-menu.sh${NC}"
    echo -e "To view logs: ${CYAN}$0 logs${NC}"
    return 0
}

# Stop all services
cmd_stop() {
    echo -e "${CYAN}🛑 Stopping OpenClaw services...${NC}"
    echo ""

    stop_gateway
    stop_proxy

    echo ""
    echo -e "${GREEN}✅ All services stopped${NC}"
}

# Restart all services
cmd_restart() {
    cmd_stop
    sleep 1
    cmd_start
}

# Tail logs
cmd_logs() {
    echo -e "${CYAN}📋 Tailing OpenClaw logs (Ctrl+C to exit)...${NC}"
    echo ""

    if [ -f "$PROXY_LOG" ] && [ -f "$GATEWAY_LOG" ]; then
        tail -f "$PROXY_LOG" "$GATEWAY_LOG"
    elif [ -f "$PROXY_LOG" ]; then
        tail -f "$PROXY_LOG"
    elif [ -f "$GATEWAY_LOG" ]; then
        tail -f "$GATEWAY_LOG"
    else
        echo -e "${YELLOW}No log files found${NC}"
        echo -e "  Proxy log: $PROXY_LOG"
        echo -e "  Gateway log: $GATEWAY_LOG"
    fi
}

# Main command dispatch
case "${1:-start}" in
    start)
        cmd_start
        ;;
    stop)
        cmd_stop
        ;;
    restart)
        cmd_restart
        ;;
    status)
        cmd_status
        ;;
    logs)
        cmd_logs
        ;;
    help|--help|-h)
        show_help
        ;;
    *)
        echo -e "${RED}❌ Unknown command: $1${NC}"
        echo ""
        show_help
        exit 1
        ;;
esac
