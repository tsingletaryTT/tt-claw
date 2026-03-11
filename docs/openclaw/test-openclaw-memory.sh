#!/bin/bash
# Test OpenClaw Memory Search Configuration
# Tests that memory search can find Tenstorrent documentation

set -e

BOLD='\033[1m'
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo -e "${BOLD}OpenClaw Memory Search Test${NC}"
echo "=========================================="
echo ""

# Check if gateway is running
echo -e "${BOLD}1. Checking Gateway Status...${NC}"
if pgrep -f "openclaw-gateway" > /dev/null; then
    echo -e "${GREEN}✅ Gateway is running${NC}"
else
    echo -e "${RED}❌ Gateway is NOT running${NC}"
    echo ""
    echo "Start the gateway with:"
    echo "  cd ~/code/tt-vscode-toolkit"
    echo "  ./openclaw.sh gateway run"
    exit 1
fi
echo ""

# Check configuration
echo -e "${BOLD}2. Checking Configuration...${NC}"
if grep -q "memorySearch" ~/.openclaw/openclaw.json; then
    echo -e "${GREEN}✅ Memory search configured in openclaw.json${NC}"
else
    echo -e "${RED}❌ Memory search NOT configured${NC}"
    exit 1
fi

if grep -q "extraPaths" ~/.openclaw/openclaw.json; then
    echo -e "${GREEN}✅ Extra paths configured${NC}"
else
    echo -e "${RED}❌ Extra paths NOT configured${NC}"
    exit 1
fi
echo ""

# Count documentation paths
echo -e "${BOLD}3. Verifying Documentation Paths...${NC}"
paths=(
    "/home/ttuser/code/tt-vscode-toolkit/content/lessons"
    "/home/ttuser/tt-metal/METALIUM_GUIDE.md"
    "/home/ttuser/tt-metal/releases"
    "/home/ttuser/tt-metal/contributing"
    "/home/ttuser/code/tt-inference-server/README.md"
    "/home/ttuser/code/tt-inference-server/docs"
    "/home/ttuser/tt-claw/CLAUDE.md"
)

all_exist=true
for path in "${paths[@]}"; do
    if [ -e "$path" ]; then
        echo -e "${GREEN}✅${NC} $path"
    else
        echo -e "${RED}❌${NC} $path (NOT FOUND)"
        all_exist=false
    fi
done

if $all_exist; then
    echo -e "${GREEN}✅ All documentation paths exist${NC}"
else
    echo -e "${RED}❌ Some paths are missing${NC}"
    exit 1
fi
echo ""

# Count lessons
echo -e "${BOLD}4. Counting Documentation Files...${NC}"
lesson_count=$(ls /home/ttuser/code/tt-vscode-toolkit/content/lessons/*.md 2>/dev/null | wc -l)
echo "   tt-vscode-toolkit lessons: $lesson_count"

metal_docs=$(find /home/ttuser/tt-metal -name "*.md" -type f | wc -l)
echo "   tt-metal docs: $metal_docs"

inference_docs=$(find /home/ttuser/code/tt-inference-server/docs -name "*.md" -type f 2>/dev/null | wc -l)
echo "   tt-inference-server docs: $inference_docs"

total_docs=$((lesson_count + metal_docs + inference_docs + 1))
echo -e "${GREEN}✅ Total documentation files: $total_docs${NC}"
echo ""

# Check for vector database
echo -e "${BOLD}5. Checking Vector Database...${NC}"
if [ -d ~/.openclaw/memory ]; then
    db_files=$(find ~/.openclaw/memory -name "*.sqlite" 2>/dev/null | wc -l)
    if [ $db_files -gt 0 ]; then
        echo -e "${GREEN}✅ Vector database exists ($db_files files)${NC}"

        # Show database sizes
        for db in ~/.openclaw/memory/*.sqlite; do
            if [ -f "$db" ]; then
                size=$(du -h "$db" | cut -f1)
                echo "   $(basename $db): $size"
            fi
        done
    else
        echo -e "${YELLOW}⚠️  Vector database not yet created${NC}"
        echo "   This is normal on first run - gateway will create it during indexing"
    fi
else
    echo -e "${YELLOW}⚠️  Memory directory doesn't exist yet${NC}"
    echo "   Gateway will create it on first run"
fi
echo ""

# Check for embedding models
echo -e "${BOLD}6. Checking Embedding Models...${NC}"
if [ -d ~/.cache/node-llama-cpp ]; then
    model_count=$(find ~/.cache/node-llama-cpp -name "*.gguf" 2>/dev/null | wc -l)
    if [ $model_count -gt 0 ]; then
        echo -e "${GREEN}✅ Embedding models downloaded ($model_count models)${NC}"

        # Show model sizes
        for model in ~/.cache/node-llama-cpp/*.gguf; do
            if [ -f "$model" ]; then
                size=$(du -h "$model" | cut -f1)
                echo "   $(basename $model): $size"
            fi
        done
    else
        echo -e "${YELLOW}⚠️  Embedding models not yet downloaded${NC}"
        echo "   Gateway will download them on first memory search (~500MB)"
    fi
else
    echo -e "${YELLOW}⚠️  Model cache directory doesn't exist yet${NC}"
    echo "   Gateway will create and populate it on first use"
fi
echo ""

# Test queries to try
echo -e "${BOLD}7. Suggested Test Queries${NC}"
echo ""
echo "Start the TUI in another terminal:"
echo -e "${YELLOW}  ./openclaw.sh tui${NC}"
echo ""
echo "Then try these queries:"
echo ""
echo "  1. ${YELLOW}search memory for hardware detection${NC}"
echo "     Expected: Snippets from hardware-detection.md"
echo ""
echo "  2. ${YELLOW}How do I check if my Tenstorrent device is working?${NC}"
echo "     Expected: Info about tt-smi command"
echo ""
echo "  3. ${YELLOW}How do I deploy a 70B model on Tenstorrent?${NC}"
echo "     Expected: Info from CLAUDE.md about P150X4"
echo ""
echo "  4. ${YELLOW}What is METALIUM?${NC}"
echo "     Expected: Info from METALIUM_GUIDE.md"
echo ""
echo "  5. ${YELLOW}What cookbook examples are available?${NC}"
echo "     Expected: List of cookbook lessons"
echo ""
echo "  6. ${YELLOW}What are the supported hardware devices?${NC}"
echo "     Expected: Info about n150, n300, t3k, p100, p150"
echo ""

# Summary
echo -e "${BOLD}=========================================="
echo "Summary"
echo "==========================================${NC}"
echo ""

if $all_exist; then
    echo -e "${GREEN}✅ Configuration: READY${NC}"
    echo -e "${GREEN}✅ Documentation: READY ($total_docs files)${NC}"
    echo -e "${GREEN}✅ Gateway: RUNNING${NC}"
    echo ""
    echo -e "${BOLD}Next Steps:${NC}"
    echo "1. Start TUI: ./openclaw.sh tui"
    echo "2. Try test queries above"
    echo "3. Verify citations show correct file paths"
    echo "4. Check gateway logs for indexing progress"
    echo ""
    echo -e "${YELLOW}Note: First memory search may be slow (~30-60 seconds)${NC}"
    echo "      Gateway needs to download embedding models and index docs"
    echo "      Subsequent searches will be fast (<1 second)"
else
    echo -e "${RED}❌ Configuration incomplete${NC}"
    echo "Fix issues above and try again"
fi
