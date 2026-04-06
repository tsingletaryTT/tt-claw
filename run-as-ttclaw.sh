#!/bin/bash
# Run adventure games as ttclaw user (demo/public mode)
# This ensures proper isolation from ttuser's private data

set -e

# Colors
CYAN='\033[0;36m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

echo -e "${CYAN}🎮 Starting OpenClaw as ttclaw user (demo mode)${NC}"
echo ""

# Set portable config path for ttclaw
export OPENCLAW_CONFIG_PATH="$HOME/tt-claw/runtime/openclaw.json"
export OPENCLAW_STATE_DIR="$HOME/tt-claw/runtime"

# Verify config exists
if [ ! -f "$OPENCLAW_CONFIG_PATH" ]; then
    echo -e "${YELLOW}⚠️  Config not found at: $OPENCLAW_CONFIG_PATH${NC}"
    echo "Creating from template..."
    # This would create a basic config if needed
fi

# Launch adventure menu as ttclaw
echo -e "${GREEN}✓ Using config: $OPENCLAW_CONFIG_PATH${NC}"
echo -e "${GREEN}✓ State directory: $OPENCLAW_STATE_DIR${NC}"
echo ""

# Switch to ttclaw and run
exec sudo -u ttclaw bash -c "
    export OPENCLAW_CONFIG_PATH='$OPENCLAW_CONFIG_PATH'
    export OPENCLAW_STATE_DIR='$OPENCLAW_STATE_DIR'
    cd ~/openclaw 2>/dev/null || cd /home/ttuser/openclaw || { echo 'OpenClaw not found'; exit 1; }
    exec bash /home/ttuser/tt-claw/adventure-games/scripts/adventure-menu.sh
"
