#!/bin/bash
# Fix openclaw.sh wrapper to use correct path (dist/index.js instead of dist/cli/index.js)

set -e

OPENCLAW_DIR="$HOME/openclaw"

# Colors
GREEN='\033[0;32m'
RED='\033[0;31m'
CYAN='\033[0;36m'
NC='\033[0m'

echo -e "${CYAN}Fixing OpenClaw wrapper script...${NC}"
echo ""

# Check if OpenClaw directory exists
if [ ! -d "$OPENCLAW_DIR" ]; then
    echo -e "${RED}ERROR: OpenClaw not found at $OPENCLAW_DIR${NC}"
    exit 1
fi

# Backup existing wrapper if it exists
if [ -f "$OPENCLAW_DIR/openclaw.sh" ]; then
    cp "$OPENCLAW_DIR/openclaw.sh" "$OPENCLAW_DIR/openclaw.sh.backup"
    echo "Backed up existing wrapper to openclaw.sh.backup"
fi

# Create corrected wrapper
cat > "$OPENCLAW_DIR/openclaw.sh" << 'EOF'
#!/bin/bash
# OpenClaw wrapper script
OPENCLAW_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$OPENCLAW_DIR"
node dist/index.js "$@"
EOF

chmod +x "$OPENCLAW_DIR/openclaw.sh"

echo ""
echo -e "${GREEN}✅ Wrapper script fixed!${NC}"
echo ""
echo "Changed:"
echo "  OLD: node dist/cli/index.js"
echo "  NEW: node dist/index.js"
echo ""

# Verify the correct file exists
if [ -f "$OPENCLAW_DIR/dist/index.js" ]; then
    echo -e "${GREEN}✓ dist/index.js exists${NC} ($(wc -l < "$OPENCLAW_DIR/dist/index.js") lines)"
else
    echo -e "${RED}⚠️  dist/index.js not found${NC}"
    echo "You may need to build OpenClaw:"
    echo "  cd ~/openclaw && npx pnpm run build"
fi

echo ""
echo "Next step:"
echo "  cd ~/tt-claw/adventure-games/scripts && ./start-adventure-services.sh"
