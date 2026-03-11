#!/bin/bash
# Configure OpenClaw Memory Search for Tenstorrent Documentation
# Indexes tt-vscode-toolkit lessons, TT-Metal docs, and more

set -e

BOLD='\033[1m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo -e "${BOLD}Configuring OpenClaw Memory Search${NC}"
echo "=========================================="
echo ""

# Check if OpenClaw is installed
if [ ! -f ~/openclaw/openclaw.sh ]; then
    echo -e "${YELLOW}❌ OpenClaw not found${NC}"
    echo ""
    echo "Please run ./install-openclaw.sh first"
    exit 1
fi

# Create .openclaw directory if it doesn't exist
mkdir -p ~/.openclaw
echo -e "${GREEN}✅ OpenClaw config directory ready${NC}"

# Check if tt-vscode-toolkit is cloned
if [ ! -d ~/code/tt-vscode-toolkit/content/lessons ]; then
    echo -e "${YELLOW}⚠️  tt-vscode-toolkit not found${NC}"
    echo ""
    echo "Cloning tt-vscode-toolkit (required for lessons)..."
    mkdir -p ~/code
    cd ~/code
    git clone https://github.com/tenstorrent/tt-vscode-toolkit.git
    echo -e "${GREEN}✅ tt-vscode-toolkit cloned${NC}"
else
    echo -e "${GREEN}✅ tt-vscode-toolkit found ($(ls ~/code/tt-vscode-toolkit/content/lessons/*.md | wc -l) lessons)${NC}"
fi

# Create memory search configuration
echo ""
echo "Creating memory search configuration..."

cat > ~/.openclaw/openclaw.json << 'EOF'
{
  "models": {
    "providers": {
      "vllm": {
        "baseUrl": "http://127.0.0.1:8001/v1",
        "api": "openai-completions",
        "apiKey": "sk-no-auth",
        "models": [
          {
            "id": "meta-llama/Llama-3.1-8B-Instruct",
            "name": "Llama 3.1 8B Instruct",
            "reasoning": false,
            "input": ["text"],
            "contextWindow": 65536,
            "maxTokens": 8192
          }
        ]
      }
    }
  },
  "agents": {
    "defaults": {
      "model": {
        "primary": "vllm/meta-llama/Llama-3.1-8B-Instruct"
      },
      "compaction": {
        "mode": "safeguard"
      },
      "memorySearch": {
        "provider": "local",
        "fallback": "none",
        "extraPaths": [
          "/home/$USER/code/tt-vscode-toolkit/content/lessons",
          "/home/$USER/tt-metal/METALIUM_GUIDE.md",
          "/home/$USER/tt-metal/releases",
          "/home/$USER/tt-metal/contributing",
          "/home/$USER/code/tt-inference-server/README.md",
          "/home/$USER/code/tt-inference-server/docs",
          "/home/$USER/tt-claw/CLAUDE.md"
        ]
      }
    }
  },
  "commands": {
    "native": "auto",
    "nativeSkills": "auto",
    "restart": true,
    "ownerDisplay": "raw"
  },
  "gateway": {
    "mode": "local",
    "auth": {
      "mode": "token",
      "token": "$(openssl rand -hex 24)"
    }
  }
}
EOF

# Replace $USER with actual username
sed -i "s/\$USER/$USER/g" ~/.openclaw/openclaw.json

echo -e "${GREEN}✅ Memory search configuration created${NC}"

# Create agent directory
mkdir -p ~/.openclaw/agents/main/agent

# Create system prompt for direct answers
echo ""
echo "Creating agent system prompt..."

cat > ~/.openclaw/agents/main/agent/system.md << 'EOF'
# Tenstorrent Expert Assistant

You are a helpful AI assistant with expert knowledge about Tenstorrent hardware, software, and demonstrations.

## Your Knowledge Base

You have access to comprehensive documentation through memory search, including:
- 46+ interactive lessons about Tenstorrent hardware and software
- QuietBox 2 (QB2) specifications and FAQ
- Hardware architecture (P300C, P150, N300, etc.)
- Software stack (TT-Metal, TT-Forge, TT-XLA, vLLM)
- Deployment guides and cookbook examples
- GDC 2026 booth demonstrations

## How to Help Users

When users ask questions about Tenstorrent, QB2, or related topics:

1. **Use memory_search** to find relevant information
2. **Synthesize the information** into a clear, direct answer
3. **Cite your sources** by mentioning which lesson or document you found it in
4. **Be comprehensive** - if you find multiple relevant details, include them

## Example Interactions

**Good:**
- User: "What is QB2?"
- You: "QuietBox 2 (QB2) is TT-QuietBox™ 2, a liquid-cooled, desk-friendly AI workstation that runs models up to 120 billion parameters locally with a fully open-source software stack. It's also the industry's first desktop AI workstation built on RISC-V architecture. [Source: qb2-faq.md]"

**Bad:**
- User: "What is QB2?"
- You: "I found information about QB2 in my memory."
- ❌ Don't just acknowledge you found information - USE IT to answer!

## Important

- **Always answer questions directly** using the information from memory search
- Don't just say "I found this" - actually tell the user what you found
- Be specific and include technical details when relevant
- If you don't find information, say so and suggest what you can help with instead
EOF

echo -e "${GREEN}✅ Agent system prompt created${NC}"

# Summary
echo ""
echo -e "${BOLD}=========================================="
echo "Configuration Complete!"
echo "==========================================${NC}"
echo ""
echo -e "${GREEN}✅ Memory search enabled${NC}"
echo -e "${GREEN}✅ Documentation paths configured:${NC}"
echo "   - tt-vscode-toolkit lessons (46+ files)"
echo "   - TT-Metal documentation"
echo "   - TT-Inference-Server guides"
echo "   - tt-claw journey (CLAUDE.md)"
echo ""
echo -e "${GREEN}✅ Agent system prompt configured${NC}"
echo "   - Direct answers instead of acknowledgments"
echo "   - Source citations included"
echo ""
echo -e "${BOLD}Next Steps:${NC}"
echo ""
echo "1. Start vLLM with tool calling:"
echo "   See: docs/openclaw/VLLM_TOOL_CALLING_COMMAND.md"
echo ""
echo "2. Start services:"
echo "   cd ~/openclaw"
echo "   python3 vllm-proxy.py > /tmp/vllm-proxy.log 2>&1 &"
echo "   ./openclaw.sh gateway run > /tmp/openclaw-gateway.log 2>&1 &"
echo ""
echo "3. Start TUI and ask questions:"
echo "   ./openclaw.sh tui"
echo ""
echo -e "${YELLOW}Note: First query will take 30-60 seconds to:${NC}"
echo "   - Download embedding models (~300MB)"
echo "   - Index all documentation (~46+ lessons)"
echo "   - Create vector database (~31MB)"
echo ""
echo "   Subsequent queries are instant (<1 second)!"
echo ""
