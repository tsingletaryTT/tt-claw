# tt-claw: Tenstorrent + OpenClaw Integration

tt-claw integrates [OpenClaw](https://openclaw.ai) with Tenstorrent hardware to provide an expert AI assistant and interactive adventure games, all running locally on your Tenstorrent accelerators.

## Features

✨ **Tenstorrent Expert** - Ask questions about QB2, TT-Metal, model deployment, and more
🎮 **Adventure Games** - Play interactive text adventures (Chip Quest, Terminal Dungeon, Conference Chaos)
🔒 **Local-Only** - No remote API calls, all inference on your Tenstorrent hardware
📚 **Documentation Search** - 46+ interactive lessons indexed and searchable
🚀 **Auto-Configuration** - Detects your vLLM setup automatically
👀 **Visible Runtime** - All configs in `openclaw-runtime/` directory (not hidden!)

## Quick Start

### Prerequisites

- Tenstorrent hardware (QB2, N300, P150, P300)
- vLLM running on Tenstorrent (see [tt-inference-server](https://github.com/tenstorrent/tt-inference-server))
- Node.js ≥22 (for OpenClaw)

### Installation

```bash
# 1. Install OpenClaw (if not already installed)
cd ~/tt-claw/adventure-games/scripts
./install-openclaw.sh

# 2. Start vLLM (if not already running)
# Option A: Docker (recommended)
cd ~/code/tt-inference-server
python3 run.py --model Llama-3.1-8B-Instruct --workflow server --docker-server

# Option B: Direct vLLM (for 70B models)
# See: ~/tt-claw/docs/VLLM_DIRECT_70B_SOLUTION.md

# 3. Setup tt-claw (auto-detects vLLM and creates configs)
cd ~/tt-claw
./bin/tt-claw setup

# 4. Start expert agent
./bin/tt-claw start

# 5. Ask questions!
./bin/tt-claw tui
```

### Example Queries

```
What is QB2?
How do I check if my Tenstorrent device is working?
Show me how to deploy a model with vLLM
What cookbook examples are available?
What's the difference between TT-Metal and TT-Forge?
```

## Commands

### Setup & Management

```bash
tt-claw setup           # Auto-detect vLLM and generate configs
tt-claw start [agent]   # Start OpenClaw gateway (default: expert)
tt-claw stop            # Stop OpenClaw gateway
tt-claw restart         # Restart OpenClaw gateway
tt-claw status          # Show gateway and vLLM status
```

### Interaction

```bash
tt-claw tui [agent]     # Launch interactive terminal UI
tt-claw explore         # Show runtime directory structure
tt-claw doctor          # Verify configuration and safety
```

### Maintenance

```bash
tt-claw clean           # Remove runtime directory (fresh start)
tt-claw help            # Show command help
```

## Agents

### Expert (default)

Tenstorrent documentation expert with indexed knowledge:
- 46+ interactive lessons (tt-vscode-toolkit)
- TT-Metal framework docs (METALIUM_GUIDE)
- tt-inference-server deployment guides
- OpenClaw integration documentation

```bash
tt-claw start           # or: tt-claw start expert
tt-claw tui
```

### Adventure Games

Interactive text adventures for demos and fun:

**Chip Quest** - 31K lines, GURPS-Lite character system, 7 regions
```bash
tt-claw start chip-quest
tt-claw tui
```

**Terminal Dungeon** - Classic dungeon crawl
```bash
tt-claw start terminal-dungeon
tt-claw tui
```

**Conference Chaos** - Navigate a tech conference
```bash
tt-claw start conference-chaos
tt-claw tui
```

## Architecture

### Visible Runtime Directory

Unlike traditional hidden directories (`~/.openclaw`), tt-claw uses a **visible** runtime directory:

```
tt-claw/
├── openclaw-runtime/        # ← VISIBLE! (not hidden)
│   ├── openclaw.json        # Main configuration
│   ├── agents/              # Agent configs
│   │   ├── main/            # Expert agent
│   │   ├── chip-quest/      # Game agents
│   │   ├── terminal-dungeon/
│   │   └── conference-chaos/
│   ├── workspace/           # Agent workspaces
│   ├── memory/              # Vector database (local embeddings)
│   └── gateway.log          # Latest logs
├── config/                  # Templates (version controlled)
├── bin/tt-claw             # Main CLI
└── lib/                     # Libraries
```

**Why visible?**
- Easy to explore and understand
- Great for demos ("here's what it created!")
- Transparent configuration
- Educational value

View it anytime:
```bash
tt-claw explore
```

### Isolation from Personal OpenClaw

tt-claw uses `OPENCLAW_STATE_DIR` environment variable to isolate from your personal OpenClaw:

- Personal OpenClaw: `~/.openclaw/` (port 18789)
- tt-claw: `~/tt-claw/openclaw-runtime/` (port 18790)

Both can run simultaneously without conflicts!

### Local-Only Architecture

```
User ←→ OpenClaw TUI ←→ Gateway ←→ vLLM ←→ Tenstorrent Hardware
                        (port 18790)  (localhost:8000/8001)

All components:
✅ Local only (127.0.0.1)
✅ No remote API calls
✅ Local embeddings (node-llama-cpp)
✅ No remote fallbacks
```

Safety is verified automatically:
```bash
tt-claw doctor
```

## Configuration

### Auto-Detection

Running `tt-claw setup` automatically:
- Detects vLLM on port 8000 or 8001
- Discovers available models
- Selects best model (prefers instruct/chat, larger sizes)
- Determines context window
- Validates for use cases (expert needs ≥32K, games need ≥64K)
- Generates safe configuration (local-only)
- Sets up all agents with appropriate prompts

### Manual Configuration

Edit `openclaw-runtime/openclaw.json` to:
- Add custom models
- Adjust context windows
- Modify memory search paths
- Change agent settings

After editing, verify safety:
```bash
tt-claw doctor
```

## Troubleshooting

### Gateway won't start

```bash
# Check status
tt-claw status

# View logs
tail -f openclaw-runtime/gateway.log

# Restart
tt-claw restart
```

### vLLM not detected

```bash
# Check vLLM is running
curl http://localhost:8000/v1/models
# or
curl http://localhost:8001/v1/models

# Check tt-inference-server container
docker ps | grep tt-inference-server
```

### No responses in TUI

Check context window is large enough:
```bash
cat openclaw-runtime/openclaw.json | grep contextWindow
```

Should be:
- Expert agent: ≥32,768
- Adventure games: ≥65,536

### Memory search is slow

First search downloads embedding models (~500MB), takes 30-60 seconds.
Subsequent searches are fast (<2 seconds).

### Configuration issues

Run full diagnostics:
```bash
tt-claw doctor
```

Fix automatically detected issues or manually edit:
```bash
nano openclaw-runtime/openclaw.json
```

## Performance

### Expert Agent

- **First query**: 30-60s (downloads embedding models)
- **Subsequent queries**: <2s (local vector search)
- **Answer generation**: Depends on model (8B: ~2-5s, 70B: ~10-30s)

### Adventure Games

- **Turn response**: 2-10s (depends on model and complexity)
- **Game state**: Tracked in conversation context
- **SOUL loading**: Automatic (included in system context)

## Next Steps

- **Try different models**: Edit `openclaw-runtime/openclaw.json`
- **Add more documentation**: Edit `memorySearch.extraPaths`
- **Create custom agents**: Copy agent structure in `openclaw-runtime/agents/`
- **Join discussions**: [OpenClaw Discord](https://discord.gg/clawd)

## Documentation

- [Architecture Design](ARCHITECTURE.md) - Technical details and design decisions
- [Safety Guarantees](SAFETY.md) - Security and local-only verification
- [OpenClaw Docs](https://docs.openclaw.ai) - Official OpenClaw documentation

## Support

- **tt-claw Issues**: Use existing CLAUDE.md or create issues
- **OpenClaw Issues**: https://github.com/openclaw/openclaw/issues
- **Tenstorrent Support**: https://github.com/tenstorrent/tt-inference-server

---

Made with ❤️ for Tenstorrent QB2 users
