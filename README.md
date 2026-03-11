# OpenClaw on Tenstorrent 🦞⚡

**AI-powered expert assistant and interactive experiences running on Tenstorrent hardware**

## What This Is

OpenClaw configured as a **Tenstorrent expert assistant** that can answer questions about hardware, software stack, and deployment using semantic search over 46+ interactive lessons and documentation. Also includes optional text adventure games for demos and education.

## Primary Use Case: TT Expert Assistant

OpenClaw uses **memory search** with local embeddings to index and search:
- **46+ interactive lessons** from tt-vscode-toolkit
- **TT-Metal documentation** (METALIUM_GUIDE, releases, contributing)
- **TT-Inference-Server guides** (deployment, model bringup, workflows)
- **Hardware specs** (P300C, P150, N300, QB2, etc.)
- **This integration journey** (70B deployment, vLLM setup, troubleshooting)

### Example Queries

```
What is QB2?
How do I deploy vLLM on Tenstorrent?
Tell me about the cores in a TT-Quietbox 2
What cookbook examples are available?
What's the difference between N300 and P150?
```

OpenClaw answers directly with citations:
> "QuietBox 2 (QB2) is TT-QuietBox™ 2, a liquid-cooled, desk-friendly AI workstation that runs models up to 120 billion parameters locally with a fully open-source software stack. It's the industry's first desktop AI workstation built on RISC-V architecture. [Source: qb2-faq.md]"

## Quick Start: Expert Assistant

### 1. Install OpenClaw

```bash
cd ~/tt-claw/adventure-games/scripts
./install-openclaw.sh
```

### 2. Configure Memory Search

```bash
./configure-memory-search.sh
```

This indexes all Tenstorrent documentation for semantic search.

### 3. Install vLLM Proxy

```bash
./install-proxy.sh
```

Compatibility layer between OpenClaw v2026.3.2 and vLLM.

### 4. Start Services

```bash
# Terminal 1: Start vLLM with tool calling (if not already running)
# See: docs/openclaw/VLLM_TOOL_CALLING_COMMAND.md

# Terminal 2: Start proxy
cd ~/openclaw && python3 vllm-proxy.py

# Terminal 3: Start gateway
cd ~/openclaw && ./openclaw.sh gateway run

# Terminal 4: Start TUI
cd ~/openclaw && ./openclaw.sh tui
```

### 5. Verify System Prompt

```bash
check-openclaw-prompt        # Quick status
check-openclaw-prompt --show # See full prompt
```

The agent should answer questions directly, NOT narrate tool usage.

## Secondary Feature: Adventure Games 🎮

Three AI-powered text adventures for demos and education:

### 🧩 Chip Quest (Educational Zork)
Journey inside a Tenstorrent chip. Battle Memory Grues, solve puzzles about Tensix cores, NoC routing, and parallel processing.
- **Playtime:** 30-45 min
- **Learn:** TT architecture through gameplay

### ⚔️ Terminal Dungeon (NetHack Roguelike)
ASCII dungeon crawler with procedural generation. Fight TT-Grues, collect artifacts, master tactical combat.
- **Playtime:** 30-60 min (replayable)
- **Features:** Permadeath, GURPS mechanics

### 🎪 Conference Chaos (Trade Wars Trading)
Navigate EAC 2026 as a trader. Buy low, sell high, corner markets, survive Vogon poetry panels.
- **Playtime:** 30-45 min
- **Features:** 5 endings, economic simulation

**Launch games:**
```bash
cd adventure-games/scripts
./adventure-menu.sh
```

## How It Works

### Memory Search System

```
User question → OpenClaw Gateway → Memory Search → Vector DB (46+ lessons)
                                 ↓
                               LLM (vLLM on TT hardware)
                                 ↓
                            Answer with citations
```

**Architecture:**
1. **Local embeddings** - node-llama-cpp (no external APIs)
2. **Vector database** - SQLite + sqlite-vec
3. **Semantic search** - Finds relevant info even with different wording
4. **Source citations** - Shows file paths and line numbers

**First query:** 30-60 seconds (downloads embedding models ~300MB)
**Subsequent queries:** <1 second

### vLLM Compatibility

OpenClaw v2026.3.2 sends newer OpenAI API fields (`strict`, `store`) that vLLM doesn't support. The included proxy strips these fields transparently:

```
OpenClaw → Proxy (port 8001) → vLLM (port 8000) → Tenstorrent
```

## Requirements

### Hardware
- Tenstorrent device (N150, N300, P150, P300C, etc.)
- Minimum 8GB RAM for 8B models
- 236GB+ RAM for 70B models

### Software
- OpenClaw v2026.3.2+
- vLLM on Tenstorrent (via tt-inference-server)
- Python 3.8+
- Node.js v24+ (for OpenClaw)

### Models
- **Minimum:** Llama-3.1-8B-Instruct (fast, good for queries)
- **Recommended:** Llama-3.3-70B-Instruct (better reasoning)

## Project Structure

```
tt-claw/
├── adventure-games/           # Games and setup scripts
│   ├── games/                # Game definitions (SOUL.md)
│   └── scripts/              # Installation and setup
│       ├── install-openclaw.sh
│       ├── configure-memory-search.sh
│       ├── install-proxy.sh
│       ├── check-openclaw-prompt
│       └── adventure-menu.sh
├── docs/                     # Complete documentation
│   ├── openclaw/            # OpenClaw-specific docs
│   │   ├── OPENCLAW_MEMORY_SEARCH_SETUP.md
│   │   ├── SYSTEM_PROMPT_CONFIGURATION.md
│   │   ├── SYSTEM_PROMPT_FIX_V2.md
│   │   ├── SYSTEM_PROMPT_FIX_V3.md
│   │   ├── VLLM_TOOL_CALLING_COMMAND.md
│   │   ├── system-prompt-v2.md
│   │   └── system-prompt-v3.md
│   └── archive/             # Historical docs
├── CLAUDE.md                # Complete development journey
└── README.md                # You are here
```

## Documentation

### Expert Assistant Setup
- **[Memory Search Setup](docs/openclaw/OPENCLAW_MEMORY_SEARCH_SETUP.md)** - Complete configuration guide
- **[Quick Reference](docs/openclaw/OPENCLAW_MEMORY_QUICK_REF.md)** - Common commands and queries
- **[System Prompt Config](docs/openclaw/SYSTEM_PROMPT_CONFIGURATION.md)** - Agent behavior configuration
- **[System Prompt Fix v2](docs/openclaw/SYSTEM_PROMPT_FIX_V2.md)** - Preventing tool narration
- **[System Prompt Fix v3](docs/openclaw/SYSTEM_PROMPT_FIX_V3.md)** - Ultra-direct prompt for 8B model limitations
- **[vLLM Tool Calling](docs/openclaw/VLLM_TOOL_CALLING_COMMAND.md)** - Docker command with tool support

### Integration Journey
- **[CLAUDE.md](CLAUDE.md)** - Complete development history
  - OpenClaw installation and architecture
  - 70B model deployment attempts
  - vLLM compatibility proxy solution
  - Memory search configuration
  - System prompt evolution

### Adventure Games
- **[Adventure Games README](adventure-games/README.md)** - Game setup and gameplay
- **[TUI Optimization](docs/TUI_OPTIMIZATION.md)** - Terminal experience tips

## Verification & Testing

### Check Configuration

```bash
# Verify system prompt version
check-openclaw-prompt

# Check memory indexing
ls -lh ~/.openclaw/memory/main.sqlite
# Should be ~31MB after indexing 46+ lessons

# Test vLLM health
curl http://localhost:8000/health

# Test proxy
curl http://localhost:8001/v1/models
```

### Test Queries

Start fresh TUI session and try:
```
What is QB2?
How do I detect Tenstorrent hardware?
What's the largest model I can run on P150X4?
What cookbook examples are available?
```

Agent should answer directly, NOT say:
- ❌ "The memory_get function has returned..."
- ❌ "I found information in my memory..."

## Troubleshooting

### Gateway won't start
```bash
pkill -f openclaw-gateway
cd ~/openclaw && ./openclaw.sh gateway run
```

### No memory search results
```bash
# Restart gateway to trigger re-indexing
pkill -f openclaw-gateway
cd ~/openclaw && ./openclaw.sh gateway run
# Wait 1-2 minutes for indexing
```

### Vague answers ("I found information...")
```bash
# Check system prompt version
check-openclaw-prompt
# Should show "Enhanced v2 prompt detected"

# If v1, update to v2
sudo cp /tmp/openclaw-system-prompt-v2.md ~/.openclaw/agents/main/agent/system.md

# Restart gateway
pkill -f openclaw-gateway
cd ~/openclaw && ./openclaw.sh gateway run

# Start FRESH TUI (old sessions keep old prompt)
./openclaw.sh tui
```

### Still getting 400 errors from vLLM
```bash
# Verify proxy is running BEFORE gateway
ps aux | grep vllm-proxy

# If not running
cd ~/openclaw && python3 vllm-proxy.py &
sleep 2
pkill -f openclaw-gateway
./openclaw.sh gateway run
```

## Known Limitations

### 8B Model Meta-Narration Issue ⚠️

**Problem:** Llama-3.1-8B-Instruct may narrate tool usage instead of answering directly.

**Example of the issue:**
```
User: "Tell me about compiling tt-metal"

Agent (8B, incorrect): "Based on the memory search results, it seems that
the user is looking for information about compiling tt-metal. To provide
a more direct answer, you could use the memory_get function..."

Agent (70B, correct): "To compile tt-metal, you need Python 3.11 and
clang-17 as prerequisites. First install these dependencies, then run
the build command. [Source: forge-image-classification.md]"
```

**Why this happens:**
- 8B models struggle with complex behavioral constraints
- They often **describe** what they should do rather than just doing it
- This is a documented limitation of smaller instruction-tuned models
- The agent meta-analyzes the task instead of executing it

**What we've tried:**
- ✅ v1 system prompt with examples
- ✅ v2 prompt with explicit "NEVER say X" anti-patterns
- ✅ v3 ultra-direct prompt with behavioral imperatives and mental model framing
- ⚠️ 8B model may simply lack capacity for this constraint

**Solution: Use 70B Model for Production**

For booth demos and production use, **strongly recommend Llama-3.3-70B-Instruct**:
- ✅ Reliable instruction following
- ✅ No meta-narration issues
- ✅ Better answer quality
- ✅ More comprehensive responses
- ✅ Handles complex behavioral constraints

See **[CLAUDE.md](CLAUDE.md)** section "Llama-3.3-70B Upgrade" for deployment instructions.

**Workaround for 8B (if needed):**
```bash
# Install v3 ultra-direct prompt
sudo cp /tmp/openclaw-system-prompt-v3.md ~/.openclaw/agents/main/agent/system.md

# Restart gateway
sudo pkill -f openclaw-gateway
sudo -u ttclaw bash -c 'cd ~/openclaw && ./openclaw.sh gateway run &'

# Start FRESH TUI
sudo -u ttclaw ~/openclaw/openclaw.sh tui
```

**Check prompt version:**
```bash
check-openclaw-prompt
```

**Acceptance:** If 8B still narrates after v3 prompt, this is a model limitation. Upgrade to 70B or brief presenters on this behavior.

## Related Repositories

- **[tt-vscode-toolkit](https://github.com/tenstorrent/tt-vscode-toolkit)** - 46+ lessons that OpenClaw indexes
- **[tt-inference-server](https://github.com/tenstorrent/tt-inference-server)** - vLLM deployment on Tenstorrent
- **[tt-metal](https://github.com/tenstorrent/tt-metal)** - Core framework

## Credits

**Created for:** GDC 2026 Demo Booth
**Hardware:** Tenstorrent P300C (4x Blackhole chips)
**Framework:** OpenClaw v2026.3.2
**AI:** vLLM + Llama-3.1-8B-Instruct / Llama-3.3-70B-Instruct
**Documentation:** tt-vscode-toolkit (46+ lessons)

## FAQ

**Q: What's the primary use case?**
A: OpenClaw as a Tenstorrent expert assistant that can answer questions about hardware, deployment, and lessons. Games are a bonus demo feature.

**Q: How does memory search work?**
A: OpenClaw indexes Markdown documentation using local embeddings (no external APIs). When you ask a question, it performs semantic search and synthesizes an answer with citations.

**Q: Why do I need the proxy?**
A: OpenClaw v2026.3.2 uses newer OpenAI API fields that the Docker-locked vLLM doesn't support. The proxy strips incompatible fields transparently.

**Q: Can I use a different model?**
A: Yes! Any vLLM-compatible model works. 8B for speed, 70B for quality. Update the model in `~/.openclaw/openclaw.json`.

**Q: Do I need to clone tt-vscode-toolkit?**
A: **YES!** OpenClaw's memory search indexes the lessons in that repo. Without it, you'll get "no results found" errors. The `configure-memory-search.sh` script will clone it automatically if missing.

**Q: How do I update the indexed documentation?**
A: Just restart the gateway. It automatically re-indexes on startup if files have changed.

---

**🦞 OpenClaw: Your gateway to Tenstorrent expertise** ⚡
**🐉 Watch out for Memory Grues!**
