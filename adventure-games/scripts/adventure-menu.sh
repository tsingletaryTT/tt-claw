#!/bin/bash
# OpenClaw Adventure Games - Interactive Menu Launcher
# GDC Infinity Demo Booth

set -e

OPENCLAW_DIR="/home/ttclaw/openclaw"
SHARED_DIR="/home/ttclaw/.openclaw/shared"

# Colors for better UX
CYAN='\033[0;36m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

# ASCII art banner with service status
show_banner() {
    echo -e "${CYAN}"
    cat << 'BANNER'
╔═══════════════════════════════════════════════════════════════╗
║                                                               ║
║   ██████╗ ██████╗ ███████╗███╗   ██╗ ██████╗██╗      █████╗  ║
║  ██╔═══██╗██╔══██╗██╔════╝████╗  ██║██╔════╝██║     ██╔══██╗ ║
║  ██║   ██║██████╔╝█████╗  ██╔██╗ ██║██║     ██║     ███████║ ║
║  ██║   ██║██╔═══╝ ██╔══╝  ██║╚██╗██║██║     ██║     ██╔══██║ ║
║  ╚██████╔╝██║     ███████╗██║ ╚████║╚██████╗███████╗██║  ██║ ║
║   ╚═════╝ ╚═╝     ╚══════╝╚═╝  ╚═══╝ ╚═════╝╚══════╝╚═╝  ╚═╝ ║
║                                                               ║
║            ADVENTURE GAMES - EAC 2026 DEMO BOOTH             ║
BANNER
    get_service_status
    echo -e "${CYAN}╚═══════════════════════════════════════════════════════════════╝${NC}"
}

# Auto-detect and configure model with progress
auto_detect_model() {
    # Check for environment override
    if [ -n "$OPENCLAW_MODEL" ]; then
        echo -e "${CYAN}🎯 Using override: $OPENCLAW_MODEL${NC}"
        python3 "$OPENCLAW_DIR/detect-model.py" --quiet > /dev/null 2>&1
        return 0
    fi

    # Run detection with progress
    python3 "$OPENCLAW_DIR/detect-model.py" --progress 2>&1 | grep -v "^=" || true
    return 0
}

# Check if vLLM proxy is running (non-blocking)
check_proxy() {
    if ! curl -s http://127.0.0.1:8001/v1/models > /dev/null 2>&1; then
        echo -e "${YELLOW}⚠️  vLLM proxy not detected on port 8001${NC}"
        echo -e "   ${CYAN}Tip: Start with ./start-services.sh${NC}"
        return 1
    else
        echo -e "${GREEN}✓ vLLM proxy detected${NC}"
        return 0
    fi
}

# Check if gateway is running (non-blocking)
check_gateway() {
    if ! pgrep -f "openclaw.*gateway" > /dev/null; then
        echo -e "${YELLOW}⚠️  OpenClaw gateway not running${NC}"
        echo -e "   ${CYAN}Tip: Start with ./start-services.sh${NC}"
        return 1
    else
        echo -e "${GREEN}✓ OpenClaw gateway running${NC}"
        return 0
    fi
}

# Get service status for menu header
get_service_status() {
    local vllm_status proxy_status gateway_status model_name

    # Check vLLM
    if curl -s http://127.0.0.1:8000/health > /dev/null 2>&1; then
        vllm_status="${GREEN}✓${NC}"
    else
        vllm_status="${RED}✗${NC}"
    fi

    # Check proxy
    if curl -s http://127.0.0.1:8001/v1/models > /dev/null 2>&1; then
        proxy_status="${GREEN}✓${NC}"
        model_name=$(curl -s http://127.0.0.1:8001/v1/models 2>/dev/null | python3 -c "import sys, json; data=json.load(sys.stdin); print(data['data'][0]['id'].split('/')[-1] if data.get('data') else 'Unknown')" 2>/dev/null || echo "Unknown")
    else
        proxy_status="${YELLOW}⚠${NC}"
        model_name="Unknown"
    fi

    # Check gateway
    if pgrep -f "openclaw.*gateway" > /dev/null 2>&1; then
        gateway_status="${GREEN}✓${NC}"
    else
        gateway_status="${RED}✗${NC}"
    fi

    echo -e "║   Services: vLLM $vllm_status | Proxy $proxy_status | Gateway $gateway_status | Model: $model_name"
}

# Show system status
show_status() {
    clear
    show_banner
    echo ""
    echo -e "${CYAN}═══ System Status ══════════════════════════════════════════════${NC}"
    echo ""

    # Check vLLM
    if curl -s http://127.0.0.1:8001/v1/models > /dev/null 2>&1; then
        MODEL=$(curl -s http://127.0.0.1:8001/v1/models | python3 -c "import sys, json; data=json.load(sys.stdin); print(data['data'][0]['id'] if data.get('data') else 'Unknown')" 2>/dev/null || echo "Unknown")
        echo -e "  ${GREEN}✓ vLLM Proxy${NC}    : localhost:8001"
        echo -e "  ${GREEN}✓ Model${NC}        : $MODEL"
    else
        echo -e "  ${RED}✗ vLLM Proxy${NC}    : Not running"
    fi

    # Check gateway
    if pgrep -f "openclaw.*gateway" > /dev/null; then
        echo -e "  ${GREEN}✓ Gateway${NC}      : Running (port 18789)"
    else
        echo -e "  ${RED}✗ Gateway${NC}      : Not running"
    fi

    # Check agents
    echo ""
    echo -e "${CYAN}═══ Available Games ════════════════════════════════════════════${NC}"
    echo ""
    for agent in chip-quest terminal-dungeon conference-chaos; do
        SOUL_FILE="/home/ttclaw/.openclaw/agents/$agent/agent/SOUL.md"
        if [ -f "$SOUL_FILE" ]; then
            SIZE=$(stat -c%s "$SOUL_FILE" 2>/dev/null || echo "0")
            KB=$((SIZE / 1024))
            echo -e "  ${GREEN}✓ ${agent}${NC} (${KB}KB)"
        else
            echo -e "  ${RED}✗ ${agent}${NC}"
        fi
    done

    echo ""
    echo -e "${CYAN}═══ Model Override ═════════════════════════════════════════════${NC}"
    echo ""
    echo -e "  To use a specific model:"
    echo -e "  ${GREEN}OPENCLAW_MODEL='your/model' ./adventure-menu.sh${NC}"
    echo ""
    echo -e "${CYAN}════════════════════════════════════════════════════════════════${NC}"
    echo ""
    read -p "Press Enter to return to menu..."
}

# Show main menu
show_menu() {
    clear
    show_banner

    echo -e "${CYAN}═══════════════════════════════════════════════════════════════${NC}"
    echo ""
    echo -e "  ${GREEN}Welcome to the OpenClaw Adventure Games!${NC}"
    echo ""
    echo -e "  Three interconnected text adventures powered by AI running on"
    echo -e "  Tenstorrent hardware. All games share a connected universe at"
    echo -e "  Experience Architect Convergence 2026 (EAC 2026)."
    echo ""
    echo -e "${CYAN}═══════════════════════════════════════════════════════════════${NC}"
    echo ""

    echo -e "  ${YELLOW}1. Chip Quest${NC} ⭐ ${GREEN}(RECOMMENDED START)${NC}"
    echo -e "     Journey through Tenstorrent chip architecture"
    echo -e "     Location: Booth #42 (Main Level)"
    echo -e "     Learn about: Tensix cores, NOC, DRAM, parallel processing"
    echo -e "     ${RED}Features: Memory Grues lurk in dark DRAM caverns!${NC}"
    echo ""

    echo -e "  ${YELLOW}2. Terminal Dungeon${NC}"
    echo -e "     Classic ASCII roguelike adventure"
    echo -e "     Location: Booth #42 (Basement Level)"
    echo -e "     Features: Combat, items, TT hardware as magical artifacts"
    echo -e "     ${RED}Features: All 6 types of TT-grues!${NC}"
    echo ""

    echo -e "  ${YELLOW}3. Conference Chaos${NC}"
    echo -e "     Navigate the chaotic conference floor"
    echo -e "     Location: EAC 2026 Expo Floor (Overworld)"
    echo -e "     Features: NPCs, panels, booth exploration, networking"
    echo ""

    echo -e "${CYAN}═══════════════════════════════════════════════════════════════${NC}"
    echo ""
    echo -e "  ${YELLOW}0.${NC} Service Management (Start/Stop/Restart/Logs)"
    echo -e "  ${YELLOW}4.${NC} System Status & Info"
    echo -e "  ${YELLOW}5.${NC} Read About TT-Grues 🐉"
    echo -e "  ${YELLOW}6.${NC} Exit"
    echo ""
    echo -e "${CYAN}═══════════════════════════════════════════════════════════════${NC}"
    echo ""
    echo -n "  Choose your adventure (0-6): "
}

# Launch game
launch_game() {
    local agent_id=$1
    echo ""
    echo -e "${CYAN}🚀 Starting $agent_id...${NC}"
    echo ""
    cd "$OPENCLAW_DIR"
    ./openclaw.sh agent --agent "$agent_id" --interactive
}

# Show service management menu
show_service_management() {
    clear
    echo -e "${CYAN}═══════════════════════════════════════════════════════════════${NC}"
    echo -e "${CYAN}   Service Management${NC}"
    echo -e "${CYAN}═══════════════════════════════════════════════════════════════${NC}"
    echo ""
    echo -e "  ${YELLOW}1.${NC} Check service status"
    echo -e "  ${YELLOW}2.${NC} Start all services"
    echo -e "  ${YELLOW}3.${NC} Stop all services"
    echo -e "  ${YELLOW}4.${NC} Restart all services"
    echo -e "  ${YELLOW}5.${NC} View logs"
    echo -e "  ${YELLOW}6.${NC} Check system health"
    echo -e "  ${YELLOW}0.${NC} Back to main menu"
    echo ""
    echo -n "  Choose an option: "
    read -r choice

    case $choice in
        1)
            echo ""
            if [ -f "$OPENCLAW_DIR/start-services.sh" ]; then
                bash "$OPENCLAW_DIR/start-services.sh" status
            else
                echo -e "${RED}Service manager not found${NC}"
            fi
            ;;
        2)
            echo ""
            if [ -f "$OPENCLAW_DIR/start-services.sh" ]; then
                bash "$OPENCLAW_DIR/start-services.sh" start
            else
                echo -e "${RED}Service manager not found${NC}"
            fi
            ;;
        3)
            echo ""
            if [ -f "$OPENCLAW_DIR/start-services.sh" ]; then
                bash "$OPENCLAW_DIR/start-services.sh" stop
            else
                echo -e "${RED}Service manager not found${NC}"
            fi
            ;;
        4)
            echo ""
            if [ -f "$OPENCLAW_DIR/start-services.sh" ]; then
                bash "$OPENCLAW_DIR/start-services.sh" restart
            else
                echo -e "${RED}Service manager not found${NC}"
            fi
            ;;
        5)
            echo ""
            if [ -f "$OPENCLAW_DIR/start-services.sh" ]; then
                echo -e "${CYAN}Press Ctrl+C to stop tailing logs${NC}"
                echo ""
                sleep 2
                bash "$OPENCLAW_DIR/start-services.sh" logs
            else
                echo -e "${RED}Service manager not found${NC}"
            fi
            ;;
        6)
            echo ""
            if [ -f "$OPENCLAW_DIR/check-health.sh" ]; then
                bash "$OPENCLAW_DIR/check-health.sh"
            else
                echo -e "${RED}Health check not found${NC}"
            fi
            ;;
        0)
            return
            ;;
        *)
            echo -e "${RED}Invalid option${NC}"
            sleep 1
            show_service_management
            return
            ;;
    esac

    echo ""
    read -p "Press Enter to continue..."
    show_service_management
}

# Show grues guide
show_grues() {
    clear
    if [ -f "$OPENCLAW_DIR/TT_GRUES_GUIDE.md" ]; then
        cat "$OPENCLAW_DIR/TT_GRUES_GUIDE.md" | less
    else
        echo -e "${RED}TT-Grues guide not found!${NC}"
        read -p "Press Enter to continue..."
    fi
}

# Main menu loop
main() {
    # Initial checks (non-blocking)
    clear
    show_banner
    echo ""
    echo -e "${CYAN}═══ Initializing ═══════════════════════════════════════════════${NC}"
    echo ""

    # Auto-detect model
    auto_detect_model

    # Check services (non-blocking - just show warnings)
    echo ""
    local proxy_ok gateway_ok
    check_proxy && proxy_ok=true || proxy_ok=false
    check_gateway && gateway_ok=true || gateway_ok=false

    echo ""
    if [ "$proxy_ok" = true ] && [ "$gateway_ok" = true ]; then
        echo -e "${GREEN}✅ All systems ready!${NC}"
    else
        echo -e "${YELLOW}⚠️  Some services not running (see above)${NC}"
        echo -e "   ${CYAN}You can start them from menu option 0${NC}"
    fi
    echo ""
    read -p "Press Enter to continue..."

    # Menu loop
    while true; do
        show_menu
        read -r choice

        case $choice in
            0)
                show_service_management
                ;;
            1)
                launch_game "chip-quest"
                ;;
            2)
                launch_game "terminal-dungeon"
                ;;
            3)
                launch_game "conference-chaos"
                ;;
            4)
                show_status
                ;;
            5)
                show_grues
                ;;
            6)
                echo ""
                echo -e "${CYAN}Thanks for playing! Watch out for tt-grues!${NC}"
                echo ""
                exit 0
                ;;
            *)
                echo ""
                echo -e "${RED}Invalid choice. Please select 0-6.${NC}"
                sleep 2
                ;;
        esac
    done
}

# Run
main
