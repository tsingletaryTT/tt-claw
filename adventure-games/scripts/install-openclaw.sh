#!/bin/bash
# Install OpenClaw v2026.3.2 for TT-CLAW adventure games
# Requires: Node.js 18+ and npm

set -e

OPENCLAW_VERSION="v2026.3.2"
OPENCLAW_DIR="$HOME/openclaw"

echo "======================================="
echo "  OpenClaw Installation for TT-CLAW"
echo "======================================="
echo ""

# Check Node.js version
if ! command -v node &> /dev/null; then
    echo "❌ Node.js not found!"
    echo ""
    echo "Please install Node.js 18+ first:"
    echo "  curl -fsSL https://deb.nodesource.com/setup_18.x | sudo -E bash -"
    echo "  sudo apt-get install -y nodejs"
    exit 1
fi

NODE_VERSION=$(node --version | cut -d'v' -f2 | cut -d'.' -f1)
if [ "$NODE_VERSION" -lt 18 ]; then
    echo "❌ Node.js version too old: v$(node --version)"
    echo "OpenClaw requires Node.js 18 or newer"
    exit 1
fi

echo "✓ Node.js $(node --version) found"
echo "✓ npm $(npm --version) found"

# Check for pnpm (required by OpenClaw)
# We'll use npx to run pnpm without global installation
if ! command -v pnpm &> /dev/null; then
    echo "⚠️  pnpm not found - will use via npx"
    PNPM="npx pnpm"
else
    echo "✓ pnpm $(pnpm --version) found"
    PNPM="pnpm"
fi
echo ""

# Check if OpenClaw already installed
if [ -d "$OPENCLAW_DIR" ]; then
    echo "⚠️  OpenClaw directory already exists: $OPENCLAW_DIR"
    read -p "Reinstall? (y/N): " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        echo "Installation cancelled."
        exit 0
    fi
    rm -rf "$OPENCLAW_DIR"
fi

# Create installation directory
mkdir -p "$OPENCLAW_DIR"
cd "$OPENCLAW_DIR"

echo "Downloading OpenClaw $OPENCLAW_VERSION..."
echo ""

# Download and extract OpenClaw
curl -L "https://github.com/openclaw/openclaw/archive/refs/tags/${OPENCLAW_VERSION}.tar.gz" -o openclaw.tar.gz
tar -xzf openclaw.tar.gz --strip-components=1
rm openclaw.tar.gz

echo ""
echo "Installing dependencies (this may take a few minutes)..."
$PNPM install

echo ""
echo "Building OpenClaw (compiling TypeScript)..."
$PNPM run build

echo ""
echo "Creating OpenClaw wrapper script..."

# Create wrapper script
cat > "$OPENCLAW_DIR/openclaw.sh" << 'EOF'
#!/bin/bash
# OpenClaw wrapper script
OPENCLAW_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$OPENCLAW_DIR"
node dist/cli/index.js "$@"
EOF

chmod +x "$OPENCLAW_DIR/openclaw.sh"

echo ""
echo "Installing vLLM compatibility proxy..."

# Find the tt-claw repo to get the proxy script
TTCLAW_REPO=""
if [ -d "$HOME/tt-claw" ]; then
    TTCLAW_REPO="$HOME/tt-claw"
elif [ -d "$(dirname "$(dirname "$0")")/../.." ]; then
    # We're running from tt-claw/adventure-games/scripts
    TTCLAW_REPO="$(cd "$(dirname "$0")/../.." && pwd)"
fi

if [ -n "$TTCLAW_REPO" ] && [ -f "$TTCLAW_REPO/openclaw-proxy/vllm-proxy.py" ]; then
    cp "$TTCLAW_REPO/openclaw-proxy/vllm-proxy.py" "$OPENCLAW_DIR/"
    chmod +x "$OPENCLAW_DIR/vllm-proxy.py"
    echo "  ✓ Installed vllm-proxy.py"
else
    echo "  ⚠️  Could not find vllm-proxy.py in tt-claw repo"
    echo "     You'll need to copy it manually from:"
    echo "     ~/tt-claw/openclaw-proxy/vllm-proxy.py → $OPENCLAW_DIR/"
fi

echo ""
echo "✓ OpenClaw $OPENCLAW_VERSION installed successfully!"
echo ""
echo "Installation directory: $OPENCLAW_DIR"
echo ""
echo "Next steps:"
echo "  1. Run onboarding: $OPENCLAW_DIR/openclaw.sh onboard"
echo "  2. Or use TT-CLAW setup: cd ~/tt-claw/adventure-games/scripts && ./setup-game-agents.sh"
echo ""
