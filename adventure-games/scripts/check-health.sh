#!/bin/bash
# OpenClaw Health Check Utility
# Quick diagnostic tool for troubleshooting

set -e

# Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
CYAN='\033[0;36m'
NC='\033[0m'

EXIT_CODE=0

show_header() {
    echo -e "${CYAN}═══════════════════════════════════════════════════════════════${NC}"
    echo -e "${CYAN}   OpenClaw Health Check${NC}"
    echo -e "${CYAN}═══════════════════════════════════════════════════════════════${NC}"
    echo ""
}

# Check vLLM server
check_vllm() {
    echo -ne "  vLLM Server (8000)............ "
    if curl -s http://127.0.0.1:8000/health > /dev/null 2>&1; then
        # Try to get model info
        local model=$(curl -s http://127.0.0.1:8000/v1/models 2>/dev/null | python3 -c "import sys, json; data=json.load(sys.stdin); print(data['data'][0]['id'] if data.get('data') else 'Unknown')" 2>/dev/null || echo "Unknown")
        echo -e "${GREEN}✓ Running${NC}"
        echo -e "    Model: $model"
        return 0
    else
        echo -e "${RED}✗ Not running${NC}"
        echo -e "    ${RED}CRITICAL: vLLM must be running for OpenClaw to work${NC}"
        EXIT_CODE=1
        return 1
    fi
}

# Check proxy
check_proxy() {
    echo -ne "  vLLM Proxy (8001)............. "
    if curl -s http://127.0.0.1:8001/v1/models > /dev/null 2>&1; then
        echo -e "${GREEN}✓ Running${NC}"
        echo -e "    Forwarding to vLLM on port 8000"
        return 0
    else
        echo -e "${YELLOW}⚠️  Not running${NC}"
        echo -e "    ${YELLOW}WARNING: Proxy recommended but not required${NC}"
        echo -e "    Start with: cd ~/openclaw && python3 vllm-proxy.py"
        EXIT_CODE=2
        return 1
    fi
}

# Check gateway
check_gateway() {
    echo -ne "  OpenClaw Gateway (18789)...... "
    if pgrep -f "openclaw.*gateway" > /dev/null 2>&1; then
        local pid=$(pgrep -f "openclaw.*gateway")
        echo -e "${GREEN}✓ Running${NC} (PID: $pid)"
        return 0
    else
        echo -e "${RED}✗ Not running${NC}"
        echo -e "    ${RED}CRITICAL: Gateway must be running for games${NC}"
        echo -e "    Start with: cd ~/openclaw && ./openclaw.sh gateway run"
        EXIT_CODE=3
        return 1
    fi
}

# Check agent configurations
check_agents() {
    echo -e "  Game Agents................... "

    local all_ok=true
    for agent in chip-quest terminal-dungeon conference-chaos; do
        local soul_file="$HOME/.openclaw/agents/$agent/agent/SOUL.md"
        echo -ne "    $agent: "

        if [ -f "$soul_file" ]; then
            local size=$(stat -c%s "$soul_file" 2>/dev/null || echo "0")
            local kb=$((size / 1024))
            echo -e "${GREEN}✓${NC} (${kb}KB)"
        else
            echo -e "${RED}✗ Missing SOUL.md${NC}"
            all_ok=false
        fi
    done

    if [ "$all_ok" = true ]; then
        return 0
    else
        echo -e "    ${YELLOW}WARNING: Some agent files missing${NC}"
        EXIT_CODE=4
        return 1
    fi
}

# Check model configuration
check_model_config() {
    echo -ne "  Model Configuration........... "

    local config_file="$HOME/.openclaw/openclaw.json"
    if [ ! -f "$config_file" ]; then
        echo -e "${RED}✗ Config file missing${NC}"
        EXIT_CODE=5
        return 1
    fi

    # Try to parse config
    local model=$(python3 << 'PYEOF'
import json
try:
    with open("$HOME/.openclaw/openclaw.json") as f:
        config = json.load(f)
        model = config.get("agents", {}).get("defaults", {}).get("model", {}).get("primary", "Not configured")
        print(model)
except Exception as e:
    print(f"Error: {e}")
PYEOF
)

    if [[ "$model" == *"vllm/"* ]]; then
        echo -e "${GREEN}✓ Configured${NC}"
        echo -e "    Primary model: $model"
        return 0
    else
        echo -e "${YELLOW}⚠️  $model${NC}"
        EXIT_CODE=6
        return 1
    fi
}

# Show summary
show_summary() {
    echo ""
    echo -e "${CYAN}═══════════════════════════════════════════════════════════════${NC}"
    echo ""

    if [ $EXIT_CODE -eq 0 ]; then
        echo -e "${GREEN}✅ All systems operational!${NC}"
        echo ""
        echo -e "Ready to play: ${CYAN}cd ~/openclaw && ./adventure-menu.sh${NC}"
    elif [ $EXIT_CODE -le 2 ]; then
        echo -e "${YELLOW}⚠️  Some non-critical issues detected${NC}"
        echo ""
        echo -e "Games may work but with degraded functionality."
        echo -e "Check warnings above for details."
    else
        echo -e "${RED}❌ Critical issues detected${NC}"
        echo ""
        echo -e "OpenClaw requires these services to function:"
        echo -e "  1. vLLM server running on port 8000"
        echo -e "  2. OpenClaw gateway running"
        echo ""
        echo -e "Fix critical issues before starting games."
    fi

    echo ""
    echo -e "${CYAN}═══════════════════════════════════════════════════════════════${NC}"
}

# Show quick start help
show_quick_start() {
    if [ $EXIT_CODE -gt 0 ]; then
        echo ""
        echo -e "${CYAN}Quick Start Commands:${NC}"
        echo ""

        if [ $EXIT_CODE -eq 1 ]; then
            echo -e "  ${YELLOW}Start vLLM:${NC}"
            echo -e "    See vLLM deployment documentation"
            echo ""
        fi

        if [ $EXIT_CODE -ge 2 ]; then
            echo -e "  ${YELLOW}Start all services:${NC}"
            echo -e "    cd ~/openclaw"
            echo -e "    ./start-services.sh"
            echo ""
        fi

        echo -e "  ${YELLOW}Check status:${NC}"
        echo -e "    ./start-services.sh status"
        echo ""

        echo -e "  ${YELLOW}View logs:${NC}"
        echo -e "    ./start-services.sh logs"
        echo ""
    fi
}

# Main
main() {
    show_header

    echo -e "${CYAN}Checking system components...${NC}"
    echo ""

    # Run all checks
    check_vllm
    echo ""
    check_proxy
    echo ""
    check_gateway
    echo ""
    check_agents
    echo ""
    check_model_config

    # Show summary
    show_summary

    # Show quick start if needed
    show_quick_start

    exit $EXIT_CODE
}

# Run
main
