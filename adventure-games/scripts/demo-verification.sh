#!/bin/bash
# demo-verification.sh - Comprehensive OpenClaw Demo Readiness Validation
# Created: 2026-03-16
# Purpose: Verify all prerequisites, configuration, security, and functionality for OpenClaw demo

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Counters
PASS=0
FAIL=0
WARN=0

# Helper functions
pass() {
    echo -e "${GREEN}✅ $1${NC}"
    ((PASS++))
}

fail() {
    echo -e "${RED}❌ $1${NC}"
    ((FAIL++))
}

warn() {
    echo -e "${YELLOW}⚠️  $1${NC}"
    ((WARN++))
}

info() {
    echo -e "${BLUE}ℹ️  $1${NC}"
}

section() {
    echo ""
    echo -e "${BLUE}========================================${NC}"
    echo -e "${BLUE}$1${NC}"
    echo -e "${BLUE}========================================${NC}"
}

# Check if command exists
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Check if port is listening
port_listening() {
    netstat -tln 2>/dev/null | grep -q ":$1 " || ss -tln 2>/dev/null | grep -q ":$1 "
}

# Check if process is running
process_running() {
    pgrep -f "$1" >/dev/null 2>&1
}

# Main validation sections
validate_prerequisites() {
    section "1. Prerequisites Check"

    # Check vLLM service
    if port_listening 8000; then
        pass "vLLM service running on port 8000"

        # Get model info
        MODEL_INFO=$(curl -s http://localhost:8000/v1/models 2>/dev/null)
        if [ $? -eq 0 ]; then
            MODEL_ID=$(echo "$MODEL_INFO" | jq -r '.data[0].id // empty' 2>/dev/null)
            MODEL_CONTEXT=$(echo "$MODEL_INFO" | jq -r '.data[0].max_model_len // 0' 2>/dev/null)

            if [ -n "$MODEL_ID" ]; then
                pass "Model detected: $MODEL_ID (context: $MODEL_CONTEXT)"
            else
                fail "vLLM responding but no model loaded"
            fi
        else
            warn "vLLM port open but not responding to API calls"
        fi
    else
        fail "vLLM not running on port 8000"
        info "Start vLLM with: docker start <container-name>"
    fi

    # Check OpenClaw installation
    if [ -d ~/openclaw ]; then
        pass "OpenClaw installed at ~/openclaw/"

        # Check openclaw.sh wrapper
        if [ -x ~/openclaw/openclaw.sh ]; then
            pass "OpenClaw wrapper script exists and is executable"
        else
            fail "openclaw.sh not found or not executable"
        fi
    else
        fail "OpenClaw not installed at ~/openclaw/"
        info "Install with: ~/tt-claw/adventure-games/scripts/install-openclaw.sh"
    fi

    # Check Node.js
    if command_exists node; then
        NODE_VERSION=$(node --version | sed 's/v//')
        NODE_MAJOR=$(echo "$NODE_VERSION" | cut -d. -f1)

        if [ "$NODE_MAJOR" -ge 18 ]; then
            pass "Node.js $NODE_VERSION (>= 18 required)"
        else
            warn "Node.js $NODE_VERSION (< 18, may have issues)"
        fi
    else
        fail "Node.js not installed"
    fi

    # Check Python 3
    if command_exists python3; then
        PYTHON_VERSION=$(python3 --version | awk '{print $2}')
        pass "Python $PYTHON_VERSION available"
    else
        fail "Python 3 not installed"
    fi

    # Check jq for JSON parsing
    if command_exists jq; then
        pass "jq available for JSON parsing"
    else
        warn "jq not installed (helpful for debugging)"
    fi
}

validate_configuration() {
    section "2. Configuration Validation"

    CONFIG_FILE=~/.openclaw/openclaw.json

    if [ -f "$CONFIG_FILE" ]; then
        pass "OpenClaw config exists: $CONFIG_FILE"

        # Validate JSON syntax
        if jq empty "$CONFIG_FILE" 2>/dev/null; then
            pass "Configuration is valid JSON"
        else
            fail "Configuration has JSON syntax errors"
            return
        fi

        # Check model configuration
        CONFIG_MODEL=$(jq -r '.models.providers.vllm.models[0].id // empty' "$CONFIG_FILE")
        if [ -n "$CONFIG_MODEL" ]; then
            pass "Model configured: $CONFIG_MODEL"

            # Compare with running model
            if [ -n "$MODEL_ID" ] && [ "$CONFIG_MODEL" = "$MODEL_ID" ]; then
                pass "Config model matches vLLM model"
            elif [ -n "$MODEL_ID" ]; then
                fail "Model mismatch! Config: $CONFIG_MODEL, vLLM: $MODEL_ID"
                info "Update config with: ~/tt-claw/adventure-games/scripts/configure-memory-search.sh"
            fi
        else
            fail "No model configured in config"
        fi

        # Check context window
        CONFIG_CONTEXT=$(jq -r '.models.providers.vllm.models[0].contextWindow // 0' "$CONFIG_FILE")
        if [ "$CONFIG_CONTEXT" -ge 32000 ]; then
            pass "Context window: $CONFIG_CONTEXT (>= 32K)"

            if [ -n "$MODEL_CONTEXT" ] && [ "$CONFIG_CONTEXT" -ne "$MODEL_CONTEXT" ]; then
                warn "Context mismatch: Config=$CONFIG_CONTEXT, vLLM=$MODEL_CONTEXT"
            fi
        else
            warn "Context window: $CONFIG_CONTEXT (< 32K, may be too small)"
        fi

        # Check base URL
        BASE_URL=$(jq -r '.models.providers.vllm.baseUrl // empty' "$CONFIG_FILE")
        if [[ "$BASE_URL" == *":8000"* ]]; then
            pass "Using direct vLLM connection (port 8000)"
        elif [[ "$BASE_URL" == *":8001"* ]]; then
            pass "Using proxy connection (port 8001)"
            if ! port_listening 8001; then
                warn "Config uses port 8001 but proxy not running"
                info "Start proxy with: cd ~/openclaw && python3 vllm-proxy.py &"
            fi
        else
            warn "Unexpected base URL: $BASE_URL"
        fi

        # Check memory search configuration
        MEMORY_PATHS=$(jq -r '.agents.defaults.memorySearch.extraPaths // [] | length' "$CONFIG_FILE")
        if [ "$MEMORY_PATHS" -gt 0 ]; then
            pass "Memory search configured with $MEMORY_PATHS paths"
        else
            fail "No memory search paths configured"
            info "Configure with: ~/tt-claw/adventure-games/scripts/configure-memory-search.sh"
        fi

        # Check gateway mode
        GATEWAY_MODE=$(jq -r '.gateway.mode // empty' "$CONFIG_FILE")
        if [ "$GATEWAY_MODE" = "local" ]; then
            pass "Gateway mode: local (secure)"
        else
            warn "Gateway mode: $GATEWAY_MODE (not 'local')"
        fi

    else
        fail "OpenClaw configuration not found: $CONFIG_FILE"
        info "Create config with: ~/tt-claw/adventure-games/scripts/configure-memory-search.sh"
    fi
}

validate_security() {
    section "3. Security Validation"

    # Check for hardcoded credentials
    if [ -f ~/.openclaw/openclaw.json ]; then
        if grep -qi "hf_[a-zA-Z0-9]*" ~/.openclaw/openclaw.json; then
            fail "HuggingFace token found in config (security risk!)"
        else
            pass "No HuggingFace tokens in config"
        fi

        if grep -qi "ghp_[a-zA-Z0-9]*" ~/.openclaw/openclaw.json; then
            fail "GitHub token found in config (security risk!)"
        else
            pass "No GitHub tokens in config"
        fi

        # Check API key is dummy
        API_KEY=$(jq -r '.models.providers.vllm.apiKey // empty' ~/.openclaw/openclaw.json)
        if [[ "$API_KEY" == "sk-no-auth"* ]] || [[ "$API_KEY" == "sk-dummy"* ]]; then
            pass "Using dummy API key (correct for local vLLM)"
        elif [ -n "$API_KEY" ]; then
            warn "API key is not a dummy value: $API_KEY"
        fi
    fi

    # Check gateway is not exposing credentials
    if process_running "openclaw.*gateway"; then
        GATEWAY_PID=$(pgrep -f "openclaw.*gateway" | head -1)
        if [ -n "$GATEWAY_PID" ]; then
            # Check if HF_TOKEN is in environment
            if grep -q "HF_TOKEN" /proc/$GATEWAY_PID/environ 2>/dev/null; then
                warn "Gateway process has HF_TOKEN in environment"
            else
                pass "Gateway process does not expose HF_TOKEN"
            fi
        fi
    else
        info "Gateway not running (can't check process environment)"
    fi

    # Check SSH directory access
    if [ -d ~/openclaw ]; then
        if grep -r "\.ssh" ~/openclaw/ 2>/dev/null | grep -v "node_modules" | grep -q "."; then
            warn "SSH references found in OpenClaw directory"
        else
            pass "No SSH directory references in OpenClaw"
        fi
    fi

    # Check permissions
    if [ -d ~/.openclaw ]; then
        OWNER=$(stat -c '%U' ~/.openclaw)
        if [ "$OWNER" = "$USER" ]; then
            pass "OpenClaw config owned by current user"
        else
            warn "OpenClaw config owned by different user: $OWNER"
        fi
    fi
}

validate_memory_search() {
    section "4. Memory Search Validation"

    if [ -f ~/.openclaw/openclaw.json ]; then
        # Check each configured path
        PATHS=$(jq -r '.agents.defaults.memorySearch.extraPaths[]?' ~/.openclaw/openclaw.json)

        if [ -z "$PATHS" ]; then
            fail "No memory search paths configured"
            return
        fi

        TOTAL_PATHS=0
        VALID_PATHS=0
        TOTAL_FILES=0

        while IFS= read -r path; do
            ((TOTAL_PATHS++))

            if [ -e "$path" ]; then
                ((VALID_PATHS++))

                # Count files if it's a directory
                if [ -d "$path" ]; then
                    FILE_COUNT=$(find "$path" -name "*.md" 2>/dev/null | wc -l)
                    TOTAL_FILES=$((TOTAL_FILES + FILE_COUNT))
                    pass "$path ($FILE_COUNT markdown files)"
                else
                    TOTAL_FILES=$((TOTAL_FILES + 1))
                    pass "$path (file)"
                fi
            else
                fail "$path (missing)"
            fi
        done <<< "$PATHS"

        info "Total: $VALID_PATHS/$TOTAL_PATHS paths valid, $TOTAL_FILES documents"

        # Check if vector database exists
        if [ -d ~/.openclaw/memory ]; then
            VECTOR_DB=$(find ~/.openclaw/memory -name "*.sqlite" 2>/dev/null | head -1)
            if [ -n "$VECTOR_DB" ]; then
                DB_SIZE=$(du -h "$VECTOR_DB" | cut -f1)
                pass "Vector database exists ($DB_SIZE)"
            else
                warn "No vector database found (will be created on first query)"
            fi
        else
            warn "Memory directory doesn't exist yet (created on first use)"
        fi
    fi
}

validate_system_prompt() {
    section "5. System Prompt Validation"

    SYSTEM_PROMPT=~/.openclaw/agents/main/agent/system.md

    if [ -f "$SYSTEM_PROMPT" ]; then
        pass "System prompt exists: $SYSTEM_PROMPT"

        # Check for key directives
        if grep -qi "memory_search" "$SYSTEM_PROMPT"; then
            pass "System prompt mentions memory_search tool"
        else
            warn "System prompt may not instruct agent to use memory search"
        fi

        if grep -qi "cite\|source" "$SYSTEM_PROMPT"; then
            pass "System prompt mentions citing sources"
        else
            warn "System prompt may not instruct agent to cite sources"
        fi

        SIZE=$(wc -l < "$SYSTEM_PROMPT")
        info "System prompt: $SIZE lines"

    else
        fail "System prompt missing: $SYSTEM_PROMPT"
        info "Create system prompt to guide agent behavior"
        cat << 'EOF'

Recommended system prompt content:
-----------------------------------
# Tenstorrent Expert Assistant

You are an expert AI assistant specializing in Tenstorrent hardware and software.

## Tools Available

- **memory_search**: Search indexed documentation for relevant information

## Guidelines

1. **Use memory search proactively**: When asked about Tenstorrent, always search for relevant documentation
2. **Synthesize information**: Don't just say "I found info", actually answer the question using what you found
3. **Cite sources**: Mention the document/lesson name where information came from
4. **Be comprehensive**: Include technical details and examples
5. **Be direct**: Give clear, actionable answers

## Knowledge Base

Your memory includes:
- 46+ interactive lessons from tt-vscode-toolkit
- TT-Metal framework documentation
- TT-Inference-Server deployment guides
- OpenClaw integration documentation

Always search before answering Tenstorrent-related questions!
EOF
    fi
}

validate_services() {
    section "6. Services Validation"

    # Check vLLM health
    if curl -s http://localhost:8000/health >/dev/null 2>&1; then
        pass "vLLM health endpoint responding"
    elif port_listening 8000; then
        warn "vLLM port open but health endpoint not responding"
    else
        fail "vLLM service not available"
    fi

    # Check proxy (if configured to use it)
    if [ -f ~/.openclaw/openclaw.json ]; then
        BASE_URL=$(jq -r '.models.providers.vllm.baseUrl // empty' ~/.openclaw/openclaw.json)
        if [[ "$BASE_URL" == *":8001"* ]]; then
            if port_listening 8001; then
                pass "Proxy running on port 8001"
            else
                fail "Config uses port 8001 but proxy not running"
                info "Start with: cd ~/openclaw && python3 vllm-proxy.py &"
            fi
        fi
    fi

    # Check gateway
    if process_running "openclaw.*gateway"; then
        pass "OpenClaw gateway process running"

        if port_listening 18789; then
            pass "Gateway WebSocket listening on port 18789"
        else
            warn "Gateway process exists but port 18789 not listening"
        fi
    else
        warn "OpenClaw gateway not running"
        info "Start with: cd ~/openclaw && ./openclaw.sh gateway run &"
    fi

    # Check for log files
    if [ -f /tmp/openclaw-gateway.log ]; then
        LOG_SIZE=$(du -h /tmp/openclaw-gateway.log | cut -f1)
        LOG_LINES=$(wc -l < /tmp/openclaw-gateway.log)
        pass "Gateway log exists ($LOG_SIZE, $LOG_LINES lines)"

        # Check for recent errors
        RECENT_ERRORS=$(tail -100 /tmp/openclaw-gateway.log 2>/dev/null | grep -i "error" | wc -l)
        if [ "$RECENT_ERRORS" -gt 0 ]; then
            warn "Found $RECENT_ERRORS errors in recent gateway logs"
            info "Check logs: tail -f /tmp/openclaw-gateway.log"
        fi
    else
        info "No gateway log file yet"
    fi
}

validate_lesson_alignment() {
    section "7. Lesson Alignment Check"

    LESSON_PATH=~/code/tt-vscode-toolkit/content/lessons/qb2-openclaw-adventures.md

    if [ -f "$LESSON_PATH" ]; then
        pass "Lesson file exists: qb2-openclaw-adventures.md"

        # Check if lesson mentions current model
        if grep -q "Llama-3.3-70B" "$LESSON_PATH"; then
            pass "Lesson references 70B model"
        elif grep -q "Llama-3.1-8B" "$LESSON_PATH"; then
            warn "Lesson still references 8B model (needs update)"
        fi

        # Check scripts mentioned in lesson
        SCRIPT_DIR=~/tt-claw/adventure-games/scripts

        for script in install-openclaw.sh configure-memory-search.sh start-services.sh; do
            if [ -f "$SCRIPT_DIR/$script" ]; then
                pass "Script exists: $script"
            else
                fail "Script missing: $script (referenced in lesson)"
            fi
        done
    else
        warn "Lesson file not found: $LESSON_PATH"
    fi
}

generate_report() {
    section "Validation Summary"

    TOTAL=$((PASS + FAIL + WARN))

    echo ""
    echo "Results:"
    echo "  ✅ Passed:  $PASS"
    echo "  ❌ Failed:  $FAIL"
    echo "  ⚠️  Warnings: $WARN"
    echo "  ━━━━━━━━━━━━━━"
    echo "  📊 Total:   $TOTAL checks"
    echo ""

    # Overall status
    if [ $FAIL -eq 0 ] && [ $WARN -eq 0 ]; then
        echo -e "${GREEN}🎉 PRODUCTION READY! All checks passed.${NC}"
        return 0
    elif [ $FAIL -eq 0 ]; then
        echo -e "${YELLOW}⚠️  MOSTLY READY - $WARN warnings to address${NC}"
        return 0
    else
        echo -e "${RED}❌ NOT READY - $FAIL critical issues found${NC}"
        echo ""
        echo "Fix critical issues before demo. Run with fixes applied:"
        echo "  ./demo-verification.sh"
        return 1
    fi
}

# Main execution
main() {
    clear
    echo -e "${BLUE}"
    cat << "EOF"
╔═══════════════════════════════════════════════╗
║   OpenClaw Demo Production Readiness Check   ║
║          Tenstorrent Expert Layer            ║
╚═══════════════════════════════════════════════╝
EOF
    echo -e "${NC}"

    validate_prerequisites
    validate_configuration
    validate_security
    validate_memory_search
    validate_system_prompt
    validate_services
    validate_lesson_alignment

    generate_report
}

# Run main function
main
