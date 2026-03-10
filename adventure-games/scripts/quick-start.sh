#!/bin/bash
# OpenClaw Quick Start - One Command to Rule Them All
# The simplest entry point for launching OpenClaw adventures

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
OPENCLAW_DIR="/home/ttclaw/openclaw"

# Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
CYAN='\033[0;36m'
NC='\033[0m'

show_banner() {
    echo -e "${CYAN}"
    cat << 'BANNER'
╔═══════════════════════════════════════════════════════════════╗
║                    OpenClaw Quick Start                       ║
╚═══════════════════════════════════════════════════════════════╝
BANNER
    echo -e "${NC}"
}

main() {
    clear
    show_banner
    echo ""

    # Step 1: Start services
    echo -e "${CYAN}🚀 Starting OpenClaw services...${NC}"
    echo ""

    if [ -f "$SCRIPT_DIR/start-services.sh" ]; then
        # Use the service manager
        bash "$SCRIPT_DIR/start-services.sh" start
        service_result=$?
    elif [ -f "$OPENCLAW_DIR/start-services.sh" ]; then
        # Try openclaw directory
        bash "$OPENCLAW_DIR/start-services.sh" start
        service_result=$?
    else
        echo -e "${RED}❌ Service manager not found${NC}"
        echo ""
        echo "Falling back to manual checks..."
        service_result=1
    fi

    echo ""

    # Step 2: Launch menu
    if [ -f "$OPENCLAW_DIR/adventure-menu.sh" ]; then
        echo -e "${CYAN}🎮 Launching adventure menu...${NC}"
        echo ""
        sleep 1
        exec bash "$OPENCLAW_DIR/adventure-menu.sh"
    else
        echo -e "${RED}❌ Adventure menu not found at: $OPENCLAW_DIR/adventure-menu.sh${NC}"
        echo ""
        echo "Please ensure OpenClaw is installed in $OPENCLAW_DIR"
        exit 1
    fi
}

# Handle environment overrides
if [ -n "$OPENCLAW_MODEL" ]; then
    echo -e "${CYAN}🎯 Using model override: $OPENCLAW_MODEL${NC}"
    echo ""
fi

# Run
main
