#!/bin/bash
# OpenClaw Quick Start Script
# Usage: ./openclaw-quickstart.sh [command]

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

show_help() {
    cat << HELP
OpenClaw Quick Start Script

Usage: $0 [command]

Commands:
    gateway         Start OpenClaw gateway
    tui             Start OpenClaw TUI (interactive)
    status          Check gateway status
    stop            Stop OpenClaw gateway
    test            Run simple test
    verify          Verify configuration
    docs            Show documentation links
    help            Show this help message

Examples:
    $0 gateway      # Start gateway in foreground
    $0 tui          # Open interactive TUI
    $0 verify       # Check if everything is configured correctly

Note: Most commands run as ttclaw user (uses sudo)
HELP
}

check_vllm() {
    echo "🔍 Checking vLLM server..."
    if curl -s http://localhost:8000/health > /dev/null; then
        echo "✅ vLLM server is running"
        return 0
    else
        echo "❌ vLLM server is not responding"
        echo "   Start it before using OpenClaw"
        return 1
    fi
}

cmd_gateway() {
    check_vllm || exit 1
    echo "🚀 Starting OpenClaw gateway..."
    echo "   Press Ctrl+C to stop"
    sudo -u ttclaw bash -c 'cd ~/openclaw && ./openclaw.sh gateway run'
}

cmd_tui() {
    echo "🖥️  Starting OpenClaw TUI..."
    echo "   Make sure gateway is running in another terminal!"
    sudo -u ttclaw bash -c 'cd ~/openclaw && ./openclaw.sh tui'
}

cmd_status() {
    echo "📊 Checking OpenClaw status..."
    sudo -u ttclaw bash -c 'cd ~/openclaw && ./openclaw.sh gateway status'
}

cmd_stop() {
    echo "🛑 Stopping OpenClaw gateway..."
    sudo -u ttclaw bash -c 'cd ~/openclaw && ./openclaw.sh gateway stop'
}

cmd_test() {
    check_vllm || exit 1
    echo "🧪 Running simple test..."
    curl -X POST http://localhost:8000/v1/chat/completions \
        -H 'Content-Type: application/json' \
        -d '{
            "model": "meta-llama/Llama-3.1-8B-Instruct",
            "messages": [{"role": "user", "content": "Say OK"}],
            "max_tokens": 5
        }' | python3 -c "import json,sys; resp=json.load(sys.stdin); print('✅ Response:', resp['choices'][0]['message']['content'])"
}

cmd_verify() {
    echo "🔍 Verifying OpenClaw configuration..."
    echo ""
    echo "1. Checking provider configurations..."
    sudo -u ttclaw python3 << 'PYTHON_EOF'
import json
with open('/home/ttclaw/.openclaw/agents/main/agent/models.json') as f:
    config = json.load(f)
    print("   Providers configured:")
    for name, provider in config['providers'].items():
        key = provider.get('apiKey', 'MISSING')
        status = '✅' if key and key != 'MISSING' else '❌'
        print(f"   {status} {name}")
PYTHON_EOF
    
    echo ""
    echo "2. Checking vLLM server..."
    check_vllm
    
    echo ""
    echo "3. Checking OpenClaw installation..."
    if [ -f /home/ttclaw/openclaw/openclaw.sh ]; then
        echo "   ✅ OpenClaw wrapper script exists"
    else
        echo "   ❌ OpenClaw wrapper script not found"
    fi
    
    echo ""
    echo "✅ Verification complete!"
}

cmd_docs() {
    echo "📚 Documentation"
    echo ""
    echo "Available documentation in $SCRIPT_DIR/docs/:"
    echo ""
    ls -1 "$SCRIPT_DIR/docs/" | sed 's/^/   - /'
    echo ""
    echo "Quick links:"
    echo "   - Demo Guide: $SCRIPT_DIR/docs/OPENCLAW_DEMO_GUIDE.md"
    echo "   - Auth Fix: $SCRIPT_DIR/docs/OPENCLAW_AUTH_FIX.md"
    echo "   - Implementation: $SCRIPT_DIR/docs/OPENCLAW_IMPLEMENTATION_SUMMARY.md"
}

# Main command dispatch
case "${1:-help}" in
    gateway)
        cmd_gateway
        ;;
    tui)
        cmd_tui
        ;;
    status)
        cmd_status
        ;;
    stop)
        cmd_stop
        ;;
    test)
        cmd_test
        ;;
    verify)
        cmd_verify
        ;;
    docs)
        cmd_docs
        ;;
    help|--help|-h)
        show_help
        ;;
    *)
        echo "❌ Unknown command: $1"
        echo ""
        show_help
        exit 1
        ;;
esac
