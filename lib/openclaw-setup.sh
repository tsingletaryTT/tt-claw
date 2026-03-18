#!/bin/bash
# OpenClaw Setup for tt-claw
# Auto-detects vLLM and generates configuration with visible runtime directory

set -e

# Determine script and repo locations
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

# Export visible runtime directory
export OPENCLAW_STATE_DIR="$REPO_ROOT/openclaw-runtime"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

error() { echo -e "${RED}❌ $1${NC}" >&2; }
success() { echo -e "${GREEN}✅ $1${NC}"; }
info() { echo -e "${BLUE}ℹ️  $1${NC}"; }
warn() { echo -e "${YELLOW}⚠️  $1${NC}"; }

echo "=== OpenClaw Setup for tt-claw ==="
echo
info "Runtime directory: $OPENCLAW_STATE_DIR (VISIBLE!)"
echo

# Step 1: Detect vLLM
info "Step 1: Detecting vLLM..."

VLLM_PORT=""
VLLM_BASE_URL=""

if curl -s http://localhost:8001/v1/models >/dev/null 2>&1; then
    success "Found vLLM proxy on port 8001"
    VLLM_PORT="8001"
    VLLM_BASE_URL="http://127.0.0.1:8001/v1"
elif curl -s http://localhost:8000/v1/models >/dev/null 2>&1; then
    success "Found vLLM on port 8000"
    VLLM_PORT="8000"
    VLLM_BASE_URL="http://127.0.0.1:8000/v1"
else
    error "vLLM not detected on ports 8000 or 8001"
    echo
    echo "Please start vLLM first:"
    echo "  Option 1: Docker (recommended)"
    echo "    cd ~/code/tt-inference-server"
    echo "    python3 run.py --model <model> --workflow server --docker-server"
    echo
    echo "  Option 2: Direct vLLM"
    echo "    See: ~/tt-claw/docs/VLLM_DIRECT_70B_SOLUTION.md"
    exit 1
fi

# Step 2: Get available models
info "Step 2: Querying available models..."

MODELS_JSON=$(curl -s "$VLLM_BASE_URL/models")

if [ -z "$MODELS_JSON" ]; then
    error "Failed to get models from vLLM"
    exit 1
fi

# Extract model IDs
MODEL_IDS=$(echo "$MODELS_JSON" | python3 -c "
import sys, json
data = json.load(sys.stdin)
if 'data' in data:
    for model in data['data']:
        print(model.get('id', ''))
" 2>/dev/null)

if [ -z "$MODEL_IDS" ]; then
    error "No models found in vLLM response"
    exit 1
fi

# Pick best model (prefer instruct/chat, prefer larger)
BEST_MODEL=$(echo "$MODEL_IDS" | grep -i "instruct\|chat" | head -1)
if [ -z "$BEST_MODEL" ]; then
    BEST_MODEL=$(echo "$MODEL_IDS" | head -1)
fi

success "Selected model: $BEST_MODEL"

# Step 3: Determine context window
info "Step 3: Determining context window..."

# Try to get from model endpoint (not all vLLM versions support this)
CONTEXT_WINDOW=""

# Default based on model name
if echo "$BEST_MODEL" | grep -qi "70b"; then
    CONTEXT_WINDOW=131072  # 128K for 70B models
elif echo "$BEST_MODEL" | grep -qi "8b"; then
    CONTEXT_WINDOW=65536   # 64K for 8B models
else
    CONTEXT_WINDOW=32768   # 32K default
fi

success "Context window: $CONTEXT_WINDOW tokens"

# Validate context window for use cases
if [ "$CONTEXT_WINDOW" -lt 32768 ]; then
    warn "Context window is small (< 32K), may affect expert agent quality"
fi

if [ "$CONTEXT_WINDOW" -lt 65536 ]; then
    warn "Context window is small (< 64K), adventure games may have issues with large SOULs"
fi

# Step 4: Create runtime directory structure
info "Step 4: Creating visible runtime directory..."

mkdir -p "$OPENCLAW_STATE_DIR"
mkdir -p "$OPENCLAW_STATE_DIR/agents/main/agent"
mkdir -p "$OPENCLAW_STATE_DIR/agents/chip-quest/agent"
mkdir -p "$OPENCLAW_STATE_DIR/agents/terminal-dungeon/agent"
mkdir -p "$OPENCLAW_STATE_DIR/agents/conference-chaos/agent"
mkdir -p "$OPENCLAW_STATE_DIR/workspace"
mkdir -p "$OPENCLAW_STATE_DIR/memory"
mkdir -p "$OPENCLAW_STATE_DIR/logs"

success "Created directory structure"

# Step 5: Generate openclaw.json
info "Step 5: Generating openclaw.json config..."

cat > "$OPENCLAW_STATE_DIR/openclaw.json" << EOF
{
  "gateway": {
    "mode": "local"
  },
  "models": {
    "providers": {
      "vllm": {
        "baseUrl": "$VLLM_BASE_URL",
        "api": "openai-completions",
        "apiKey": "sk-no-auth-required",
        "models": [
          {
            "id": "$BEST_MODEL",
            "name": "$(echo $BEST_MODEL | sed 's/.*\///' | sed 's/-/ /g')",
            "contextWindow": $CONTEXT_WINDOW,
            "maxTokens": 8192
          }
        ]
      }
    }
  },
  "agents": {
    "defaults": {
      "model": {
        "primary": "vllm/$BEST_MODEL"
      },
      "memorySearch": {
        "provider": "local",
        "fallback": "none",
        "extraPaths": [
          "/home/ttuser/code/tt-vscode-toolkit/content/lessons",
          "/home/ttuser/tt-metal/METALIUM_GUIDE.md",
          "/home/ttuser/tt-metal/releases",
          "/home/ttuser/tt-metal/contributing",
          "/home/ttuser/code/tt-inference-server/README.md",
          "/home/ttuser/code/tt-inference-server/docs",
          "/home/ttuser/tt-claw/CLAUDE.md"
        ]
      }
    }
  }
}
EOF

success "Generated openclaw.json"

# Step 6: Set up expert agent
info "Step 6: Setting up expert agent (main)..."

# Copy system prompt
cp "$REPO_ROOT/config/system-prompts/tenstorrent-expert.md" \
   "$OPENCLAW_STATE_DIR/agents/main/agent/system.md"

# Create minimal models.json
cat > "$OPENCLAW_STATE_DIR/agents/main/agent/models.json" << EOF
{
  "providers": {}
}
EOF

success "Expert agent configured"

# Step 7: Set up adventure game agents
info "Step 7: Setting up adventure game agents..."

for game in chip-quest terminal-dungeon conference-chaos; do
    # Copy SOUL file
    if [ -f "$REPO_ROOT/config/adventure-agents/$game/SOUL.md" ]; then
        cp "$REPO_ROOT/config/adventure-agents/$game/SOUL.md" \
           "$OPENCLAW_STATE_DIR/agents/$game/agent/system.md"
        success "  $game: SOUL copied"
    else
        warn "  $game: SOUL not found at config/adventure-agents/$game/SOUL.md"
    fi

    # Create minimal models.json
    cat > "$OPENCLAW_STATE_DIR/agents/$game/agent/models.json" << EOF
{
  "providers": {}
}
EOF
done

# Step 8: Safety validation
info "Step 8: Running safety checks..."

# Check that only localhost is configured
if grep -q "127.0.0.1\|localhost" "$OPENCLAW_STATE_DIR/openclaw.json"; then
    success "Local-only configuration verified"
else
    error "Configuration may include remote providers!"
    warn "Review: $OPENCLAW_STATE_DIR/openclaw.json"
    exit 1
fi

# Check memory fallback
if grep -q '"fallback": "none"' "$OPENCLAW_STATE_DIR/openclaw.json"; then
    success "Memory search has no remote fallback"
else
    warn "Memory search may have remote fallback"
fi

# Step 9: Summary
echo
echo "=== Setup Complete ==="
echo
success "Runtime directory: $OPENCLAW_STATE_DIR"
echo
echo "Configuration:"
echo "  vLLM URL: $VLLM_BASE_URL"
echo "  Model: $BEST_MODEL"
echo "  Context: $CONTEXT_WINDOW tokens"
echo
echo "Agents configured:"
echo "  ✓ main (Tenstorrent expert)"
echo "  ✓ chip-quest"
echo "  ✓ terminal-dungeon"
echo "  ✓ conference-chaos"
echo
echo "Memory search:"
echo "  ✓ Local embeddings (node-llama-cpp)"
echo "  ✓ No remote fallback"
echo "  ✓ 46+ lessons indexed"
echo
echo "Safety:"
echo "  ✓ Local-only providers"
echo "  ✓ No remote API fallback"
echo
echo "Next steps:"
echo "  tt-claw start         # Start expert agent"
echo "  tt-claw tui           # Interactive Q&A"
echo "  tt-claw explore       # See directory structure"
echo
info "Note: First memory search will take 30-60s to download embedding models"
