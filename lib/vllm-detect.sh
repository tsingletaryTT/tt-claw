#!/bin/bash
# vLLM Detection Library for tt-claw
# Auto-detects vLLM endpoint, models, and capabilities

# This script can be sourced for functions or run directly for detection

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

# Detect vLLM endpoint
# Returns: port number (8000 or 8001) or empty if not found
# Sets: VLLM_PORT, VLLM_BASE_URL
detect_vllm_endpoint() {
    # Try proxy port first (8001)
    if curl -sf http://localhost:8001/v1/models >/dev/null 2>&1; then
        VLLM_PORT="8001"
        VLLM_BASE_URL="http://127.0.0.1:8001/v1"
        VLLM_NEEDS_PROXY=false
    # Try direct vLLM port (8000)
    elif curl -sf http://localhost:8000/v1/models >/dev/null 2>&1; then
        VLLM_PORT="8000"
        VLLM_BASE_URL="http://127.0.0.1:8000/v1"

        # Check if proxy is needed (test for 'strict' field support)
        local test_response=$(curl -sf -X POST http://localhost:8000/v1/chat/completions \
            -H "Content-Type: application/json" \
            -d '{"model":"test","messages":[],"strict":true}' 2>&1 || true)

        if echo "$test_response" | grep -q "strict"; then
            VLLM_NEEDS_PROXY=true
        else
            VLLM_NEEDS_PROXY=false
        fi
    fi

    export VLLM_PORT
    export VLLM_BASE_URL
    export VLLM_NEEDS_PROXY

    echo "$VLLM_PORT"
}

# Get list of available models
# Returns: newline-separated list of model IDs
# Requires: VLLM_BASE_URL to be set
get_vllm_models() {
    if [ -z "$VLLM_BASE_URL" ]; then
        error "VLLM_BASE_URL not set. Run detect_vllm_endpoint first."
        return 1
    fi

    local models_json=$(curl -sf "$VLLM_BASE_URL/models")

    if [ -z "$models_json" ]; then
        error "Failed to get models from $VLLM_BASE_URL/models"
        return 1
    fi

    # Extract model IDs using Python
    echo "$models_json" | python3 -c "
import sys, json
try:
    data = json.load(sys.stdin)
    if 'data' in data:
        for model in data['data']:
            print(model.get('id', ''))
except Exception as e:
    pass
" 2>/dev/null
}

# Pick best model from list
# Prefers: instruct/chat models, larger models (70B > 8B)
# Input: newline-separated list of model IDs
# Output: single best model ID
pick_best_model() {
    local models="$1"

    if [ -z "$models" ]; then
        error "No models provided"
        return 1
    fi

    # Prefer instruct/chat models
    local instruct_models=$(echo "$models" | grep -i "instruct\|chat")

    if [ -n "$instruct_models" ]; then
        # If multiple instruct models, prefer 70B > 8B > others
        local model_70b=$(echo "$instruct_models" | grep -i "70b" | head -1)
        local model_8b=$(echo "$instruct_models" | grep -i "8b" | head -1)

        if [ -n "$model_70b" ]; then
            echo "$model_70b"
        elif [ -n "$model_8b" ]; then
            echo "$model_8b"
        else
            echo "$instruct_models" | head -1
        fi
    else
        # No instruct models, just pick first available
        echo "$models" | head -1
    fi
}

# Determine context window for model
# Input: model ID
# Output: context window size in tokens
get_context_window() {
    local model="$1"

    # Heuristics based on model name
    if echo "$model" | grep -qi "70b"; then
        echo 131072  # 128K for 70B models
    elif echo "$model" | grep -qi "8b"; then
        echo 65536   # 64K for 8B models
    elif echo "$model" | grep -qi "1b"; then
        echo 32768   # 32K for 1B models
    else
        echo 32768   # 32K default
    fi
}

# Validate context window for use case
# Input: context window size, use case (expert|game)
# Output: warnings if context is too small
validate_context_window() {
    local context_window="$1"
    local use_case="${2:-expert}"

    case "$use_case" in
        expert)
            if [ "$context_window" -lt 32768 ]; then
                warn "Context window ($context_window) is small for expert agent (recommended: ≥32K)"
                return 1
            fi
            ;;
        game)
            if [ "$context_window" -lt 65536 ]; then
                warn "Context window ($context_window) is small for adventure games (recommended: ≥64K)"
                warn "Large SOUL files may not fit in context"
                return 1
            fi
            ;;
    esac

    return 0
}

# Check if proxy is needed and running
# Returns: 0 if proxy setup is correct, 1 if issues
check_proxy_setup() {
    local needs_proxy="${VLLM_NEEDS_PROXY:-unknown}"

    if [ "$needs_proxy" = "true" ]; then
        # Proxy is needed, check if it's running
        if [ "$VLLM_PORT" = "8001" ]; then
            success "vLLM proxy is running and accessible"
            return 0
        else
            warn "vLLM needs proxy but proxy (port 8001) not detected"
            info "Start proxy: cd ~/openclaw && python3 vllm-proxy.py"
            return 1
        fi
    elif [ "$needs_proxy" = "false" ]; then
        # Direct vLLM works fine
        success "vLLM supports all required API features (no proxy needed)"
        return 0
    else
        warn "Proxy requirement unknown (couldn't determine)"
        return 1
    fi
}

# Full detection report
# Runs all detection steps and prints summary
vllm_detect_report() {
    echo "=== vLLM Detection Report ==="
    echo

    # Detect endpoint
    info "Detecting vLLM endpoint..."
    detect_vllm_endpoint > /dev/null

    if [ -z "$VLLM_PORT" ]; then
        error "vLLM not found on ports 8000 or 8001"
        echo
        echo "Please start vLLM first:"
        echo "  Option 1: Docker (recommended)"
        echo "    cd ~/code/tt-inference-server"
        echo "    python3 run.py --model <model> --workflow server --docker-server"
        echo
        echo "  Option 2: Direct vLLM"
        echo "    See: ~/tt-claw/docs/VLLM_DIRECT_70B_SOLUTION.md"
        return 1
    fi

    success "vLLM found on port $VLLM_PORT"
    info "Base URL: $VLLM_BASE_URL"

    # Check proxy
    echo
    info "Checking proxy requirements..."
    check_proxy_setup

    # Get models
    echo
    info "Querying available models..."
    local models=$(get_vllm_models)

    if [ -z "$models" ]; then
        error "No models found"
        return 1
    fi

    local model_count=$(echo "$models" | wc -l)
    success "Found $model_count model(s)"

    # Show all models
    echo
    echo "Available models:"
    echo "$models" | sed 's/^/  - /'

    # Pick best
    echo
    info "Selecting best model..."
    local best_model=$(pick_best_model "$models")
    success "Best model: $best_model"

    # Context window
    echo
    info "Determining context window..."
    local context=$(get_context_window "$best_model")
    success "Context window: $context tokens"

    # Validate for use cases
    echo
    info "Validating for use cases..."
    validate_context_window "$context" "expert" && success "  Expert agent: OK"
    validate_context_window "$context" "game" && success "  Adventure games: OK"

    # Export for other scripts
    export VLLM_DETECTED_MODEL="$best_model"
    export VLLM_DETECTED_CONTEXT="$context"

    echo
    success "Detection complete!"
    echo
    echo "Detected configuration:"
    echo "  Port: $VLLM_PORT"
    echo "  URL: $VLLM_BASE_URL"
    echo "  Model: $VLLM_DETECTED_MODEL"
    echo "  Context: $VLLM_DETECTED_CONTEXT"
    echo "  Proxy needed: $VLLM_NEEDS_PROXY"
}

# If run directly (not sourced), run full report
if [ "${BASH_SOURCE[0]}" = "${0}" ]; then
    vllm_detect_report
fi
