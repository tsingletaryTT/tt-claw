#!/bin/bash
# Start OpenClaw services for ttclaw user
# Use this when running demos or public use

set -e

CYAN='\033[0;36m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

# Portable config
export OPENCLAW_CONFIG_PATH="$HOME/tt-claw/runtime/openclaw.json"
export OPENCLAW_STATE_DIR="$HOME/tt-claw/runtime"

show_usage() {
    echo "Usage: $0 [gateway|tui|menu|stop]"
    echo ""
    echo "Commands:"
    echo "  gateway    Start gateway as ttclaw (port 18789)"
    echo "  tui        Start TUI as ttclaw"
    echo "  menu       Start adventure menu as ttclaw"
    echo "  stop       Stop gateway and TUI"
    echo ""
    echo "Note: vLLM proxy runs as ttuser (shared service)"
}

start_gateway() {
    echo -e "${CYAN}🚀 Starting gateway as ttclaw...${NC}"

    # Check if already running
    if sudo -u ttclaw pgrep -f "openclaw.*gateway" > /dev/null; then
        echo -e "${YELLOW}⚠️  Gateway already running${NC}"
        return 0
    fi

    sudo -u ttclaw bash -c "
        export OPENCLAW_CONFIG_PATH='$OPENCLAW_CONFIG_PATH'
        export OPENCLAW_STATE_DIR='$OPENCLAW_STATE_DIR'
        cd /home/ttclaw/openclaw 2>/dev/null || cd /home/ttuser/openclaw || exit 1
        nohup ./openclaw.sh gateway run > /tmp/ttclaw-gateway.log 2>&1 &
        echo \$! > /tmp/ttclaw-gateway.pid
    "

    sleep 2
    if sudo -u ttclaw pgrep -f "openclaw.*gateway" > /dev/null; then
        echo -e "${GREEN}✅ Gateway started (port 18789)${NC}"
        echo -e "   Log: /tmp/ttclaw-gateway.log"
    else
        echo -e "${RED}❌ Gateway failed to start${NC}"
        echo -e "   Check: /tmp/ttclaw-gateway.log"
        return 1
    fi
}

start_tui() {
    echo -e "${CYAN}🎮 Starting TUI as ttclaw...${NC}"

    sudo -u ttclaw bash -c "
        export OPENCLAW_CONFIG_PATH='$OPENCLAW_CONFIG_PATH'
        export OPENCLAW_STATE_DIR='$OPENCLAW_STATE_DIR'
        cd /home/ttclaw/openclaw 2>/dev/null || cd /home/ttuser/openclaw || exit 1
        exec ./openclaw.sh tui
    "
}

start_menu() {
    echo -e "${CYAN}🎮 Starting adventure menu as ttclaw...${NC}"
    echo ""

    sudo -u ttclaw bash -c "
        export OPENCLAW_CONFIG_PATH='$OPENCLAW_CONFIG_PATH'
        export OPENCLAW_STATE_DIR='$OPENCLAW_STATE_DIR'
        exec bash /home/ttuser/tt-claw/adventure-games/scripts/adventure-menu.sh
    "
}

stop_services() {
    echo -e "${CYAN}🛑 Stopping ttclaw services...${NC}"

    if [ -f /tmp/ttclaw-gateway.pid ]; then
        sudo -u ttclaw kill $(cat /tmp/ttclaw-gateway.pid) 2>/dev/null || true
        rm -f /tmp/ttclaw-gateway.pid
    fi

    sudo -u ttclaw pkill -f "openclaw.*gateway" 2>/dev/null || true
    sudo -u ttclaw pkill -f "openclaw.*tui" 2>/dev/null || true

    echo -e "${GREEN}✅ Services stopped${NC}"
}

case "${1:-menu}" in
    gateway)
        start_gateway
        ;;
    tui)
        start_tui
        ;;
    menu)
        start_menu
        ;;
    stop)
        stop_services
        ;;
    *)
        show_usage
        exit 1
        ;;
esac
