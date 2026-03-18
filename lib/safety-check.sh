#!/bin/bash
# Safety Check for tt-claw OpenClaw Configuration
# Ensures no accidental remote LLM usage

# Note: Not using 'set -e' because grep returns 1 when no match (which is often good!)

# Determine script and repo locations
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

# Runtime directory
OPENCLAW_STATE_DIR="${OPENCLAW_STATE_DIR:-$REPO_ROOT/openclaw-runtime}"
CONFIG_FILE="$OPENCLAW_STATE_DIR/openclaw.json"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

error() { echo -e "${RED}❌ FAIL: $1${NC}"; return 1; }
success() { echo -e "${GREEN}✅ PASS: $1${NC}"; }
warn() { echo -e "${YELLOW}⚠️  WARN: $1${NC}"; }
info() { echo -e "${BLUE}ℹ️  $1${NC}"; }

CHECKS_PASSED=0
CHECKS_FAILED=0
WARNINGS=0

echo "=== OpenClaw Safety Check ==="
echo
info "Checking: $CONFIG_FILE"
echo

# Check 1: Config file exists
echo "1. Configuration File"
if [ -f "$CONFIG_FILE" ]; then
    success "Config file exists"
    ((CHECKS_PASSED++))
else
    error "Config file not found"
    ((CHECKS_FAILED++))
    echo
    info "Run 'tt-claw setup' to create configuration"
    exit 1
fi

# Check 2: Only localhost providers
echo
echo "2. Provider URLs (Must be localhost only)"

REMOTE_PROVIDERS=$(grep -o '"baseUrl"[[:space:]]*:[[:space:]]*"[^"]*"' "$CONFIG_FILE" | grep -v "127.0.0.1\|localhost" || echo "")

if [ -z "$REMOTE_PROVIDERS" ]; then
    success "All providers are localhost"
    ((CHECKS_PASSED++))
else
    error "Remote providers detected!"
    echo "$REMOTE_PROVIDERS" | sed 's/^/  /'
    ((CHECKS_FAILED++))
fi

# Check 3: No real API keys
echo
echo "3. API Keys (Should be dummy values for localhost)"

# Look for patterns that might be real API keys
SUSPICIOUS_KEYS=$(grep -o '"apiKey"[[:space:]]*:[[:space:]]*"[^"]*"' "$CONFIG_FILE" | grep -v "sk-no-auth\|sk-dummy\|sk-not-needed" || echo "")

if [ -z "$SUSPICIOUS_KEYS" ]; then
    success "No real API keys found"
    ((CHECKS_PASSED++))
else
    warn "Possible real API keys detected"
    echo "$SUSPICIOUS_KEYS" | sed 's/^/  /'
    ((WARNINGS++))
    info "If these are real API keys, they might enable remote LLM usage"
fi

# Check 4: Memory search fallback
echo
echo "4. Memory Search Fallback (Must be 'none')"

FALLBACK=$(grep -o '"fallback"[[:space:]]*:[[:space:]]*"[^"]*"' "$CONFIG_FILE" | head -1)

if echo "$FALLBACK" | grep -q "none"; then
    success "Memory search has no remote fallback"
    ((CHECKS_PASSED++))
elif [ -z "$FALLBACK" ]; then
    warn "Memory search fallback not configured (defaults may apply)"
    ((WARNINGS++))
else
    error "Memory search has remote fallback enabled"
    echo "  $FALLBACK"
    ((CHECKS_FAILED++))
fi

# Check 5: Memory search provider is local
echo
echo "5. Memory Search Provider (Must be 'local')"

# Extract the memorySearch section and check its provider field
MEMORY_SECTION=$(grep -A 10 '"memorySearch"' "$CONFIG_FILE" | grep -o '"provider"[[:space:]]*:[[:space:]]*"[^"]*"' | head -1)

if echo "$MEMORY_SECTION" | grep -q "local"; then
    success "Memory search uses local provider"
    ((CHECKS_PASSED++))
elif [ -z "$MEMORY_SECTION" ]; then
    warn "Memory search provider not found (may use defaults)"
    ((WARNINGS++))
else
    error "Memory search may use remote provider"
    echo "  $MEMORY_SECTION"
    ((CHECKS_FAILED++))
fi

# Check 6: No OpenAI/Anthropic/remote providers by name
echo
echo "6. Remote Provider Names (OpenAI, Anthropic, etc.)"

REMOTE_NAMES=$(grep -E '"(openai|anthropic|cohere|gemini|claude)"[[:space:]]*:' "$CONFIG_FILE" || echo "")

if [ -z "$REMOTE_NAMES" ]; then
    success "No remote provider names found"
    ((CHECKS_PASSED++))
else
    warn "Remote provider configurations detected"
    echo "$REMOTE_NAMES" | sed 's/^/  /'
    ((WARNINGS++))
    info "These might be for future use, but verify they're not active"
fi

# Check 7: vLLM is running and accessible
echo
echo "7. vLLM Accessibility"

if curl -s http://localhost:8001/v1/models >/dev/null 2>&1; then
    success "vLLM proxy accessible on port 8001"
    ((CHECKS_PASSED++))
elif curl -s http://localhost:8000/v1/models >/dev/null 2>&1; then
    success "vLLM accessible on port 8000"
    ((CHECKS_PASSED++))
else
    error "vLLM not accessible on ports 8000 or 8001"
    ((CHECKS_FAILED++))
    info "Start vLLM before running OpenClaw"
fi

# Check 8: Runtime directory isolation
echo
echo "8. Runtime Directory Isolation"

if [ -d "$OPENCLAW_STATE_DIR" ]; then
    success "Runtime directory exists: $OPENCLAW_STATE_DIR"
    ((CHECKS_PASSED++))

    # Check it's not the default ~/.openclaw
    if [ "$OPENCLAW_STATE_DIR" = "$HOME/.openclaw" ]; then
        warn "Using default OpenClaw directory (not isolated)"
        ((WARNINGS++))
    else
        success "Using isolated runtime directory"
    fi
else
    error "Runtime directory not found"
    ((CHECKS_FAILED++))
fi

# Summary
echo
echo "=== Summary ==="
echo
echo "Checks passed: $CHECKS_PASSED"
echo "Checks failed: $CHECKS_FAILED"
echo "Warnings: $WARNINGS"
echo

if [ $CHECKS_FAILED -eq 0 ]; then
    if [ $WARNINGS -eq 0 ]; then
        success "All safety checks passed! ✨"
        echo
        info "Configuration is safe for local-only operation"
    else
        warn "Safety checks passed with warnings"
        echo
        info "Review warnings above to ensure they're not issues"
    fi
    exit 0
else
    error "Safety checks failed!"
    echo
    info "Fix the issues above before using OpenClaw"
    exit 1
fi
