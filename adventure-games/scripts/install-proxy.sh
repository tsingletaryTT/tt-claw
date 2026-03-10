#!/bin/bash
# Install vLLM compatibility proxy to ~/openclaw/

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROXY_SOURCE="$SCRIPT_DIR/../../openclaw-proxy/vllm-proxy.py"
OPENCLAW_DIR="$HOME/openclaw"

echo "Installing vLLM compatibility proxy..."
echo ""

# Check if OpenClaw directory exists
if [ ! -d "$OPENCLAW_DIR" ]; then
    echo "ERROR: OpenClaw directory not found: $OPENCLAW_DIR"
    echo ""
    echo "Please install OpenClaw first:"
    echo "  cd ~/tt-claw/adventure-games/scripts"
    echo "  ./install-openclaw.sh"
    exit 1
fi

# Check if proxy script exists
if [ ! -f "$PROXY_SOURCE" ]; then
    echo "ERROR: Proxy script not found: $PROXY_SOURCE"
    echo ""
    echo "Expected location: ~/tt-claw/openclaw-proxy/vllm-proxy.py"
    exit 1
fi

# Copy proxy script
cp "$PROXY_SOURCE" "$OPENCLAW_DIR/vllm-proxy.py"
chmod +x "$OPENCLAW_DIR/vllm-proxy.py"

echo "✓ Installed: $OPENCLAW_DIR/vllm-proxy.py"
echo ""
echo "What this proxy does:"
echo "  - Receives requests from OpenClaw (port 8001)"
echo "  - Strips incompatible API fields (strict, store, prompt_cache_key)"
echo "  - Forwards clean requests to vLLM (port 8000)"
echo ""
echo "To start the proxy:"
echo "  cd ~/openclaw && python3 vllm-proxy.py"
echo ""
echo "Or use the automated startup:"
echo "  cd ~/tt-claw/adventure-games/scripts && ./start-adventure-services.sh"
