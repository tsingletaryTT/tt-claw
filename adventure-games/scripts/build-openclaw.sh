#!/bin/bash
# Build OpenClaw (compile TypeScript to JavaScript)
# Use this if you get "Cannot find module dist/cli/index.js" error

set -e

OPENCLAW_DIR="$HOME/openclaw"

# Colors
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m'

echo -e "${CYAN}Building OpenClaw...${NC}"
echo ""

# Check if OpenClaw directory exists
if [ ! -d "$OPENCLAW_DIR" ]; then
    echo -e "${RED}ERROR: OpenClaw not found at $OPENCLAW_DIR${NC}"
    echo ""
    echo "Please install OpenClaw first:"
    echo "  cd ~/tt-claw/adventure-games/scripts"
    echo "  ./install-openclaw.sh"
    exit 1
fi

# Check if package.json exists
if [ ! -f "$OPENCLAW_DIR/package.json" ]; then
    echo -e "${RED}ERROR: Invalid OpenClaw installation (no package.json)${NC}"
    echo ""
    echo "Reinstall OpenClaw:"
    echo "  cd ~/tt-claw/adventure-games/scripts"
    echo "  ./install-openclaw.sh"
    exit 1
fi

# Check for pnpm (use npx if not globally installed)
if ! command -v pnpm &> /dev/null; then
    echo -e "${YELLOW}⚠️  pnpm not found - will use via npx${NC}"
    PNPM="npx pnpm"
    echo ""
else
    PNPM="pnpm"
fi

# Check if node_modules exists
if [ ! -d "$OPENCLAW_DIR/node_modules" ]; then
    echo -e "${YELLOW}⚠️  Dependencies not installed${NC}"
    echo "Installing dependencies first..."
    cd "$OPENCLAW_DIR"
    $PNPM install
    echo ""
fi

# Run build
echo "Compiling TypeScript..."
cd "$OPENCLAW_DIR"
$PNPM run build

echo ""

# Verify dist directory was created
if [ ! -d "$OPENCLAW_DIR/dist" ]; then
    echo -e "${RED}ERROR: Build failed - dist/ directory not created${NC}"
    echo ""
    echo "Check for errors above and try:"
    echo "  cd $OPENCLAW_DIR"
    echo "  npm install"
    echo "  npm run build"
    exit 1
fi

# Verify index.js exists
if [ ! -f "$OPENCLAW_DIR/dist/cli/index.js" ]; then
    echo -e "${RED}ERROR: Build incomplete - dist/cli/index.js missing${NC}"
    exit 1
fi

echo -e "${GREEN}✅ OpenClaw built successfully!${NC}"
echo ""
echo "Build output:"
echo "  dist/cli/index.js: $(wc -l < "$OPENCLAW_DIR/dist/cli/index.js") lines"
echo ""
echo "Next steps:"
echo "  cd ~/tt-claw/adventure-games/scripts"
echo "  ./start-adventure-services.sh"
