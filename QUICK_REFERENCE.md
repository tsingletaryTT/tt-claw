# tt-claw Quick Reference Card

**OpenClaw + Tenstorrent Integration**
**Version:** 1.0 | **Date:** March 16, 2026

## First-Time Setup

```bash
cd ~/tt-claw
./bin/tt-claw setup      # Auto-detect vLLM and configure
./bin/tt-claw doctor     # Verify safety
./bin/tt-claw start      # Start expert agent
./bin/tt-claw tui        # Ask questions
```

## Common Commands

| Command | Description |
|---------|-------------|
| `tt-claw setup` | Auto-detect vLLM and generate configs |
| `tt-claw start [agent]` | Start gateway (default: expert) |
| `tt-claw stop` | Stop gateway |
| `tt-claw restart` | Restart gateway |
| `tt-claw status` | Show gateway & vLLM status |
| `tt-claw tui` | Launch interactive terminal UI |
| `tt-claw explore` | Show directory structure |
| `tt-claw doctor` | Run safety checks |
| `tt-claw clean` | Remove runtime (fresh start) |
| `tt-claw help` | Show help |

## Agents

| Agent | Command | Purpose |
|-------|---------|---------|
| **expert** (default) | `tt-claw start` | Tenstorrent Q&A (46+ lessons) |
| **chip-quest** | `tt-claw start chip-quest` | Adventure game (31K lines) |
| **terminal-dungeon** | `tt-claw start terminal-dungeon` | Dungeon crawler |
| **conference-chaos** | `tt-claw start conference-chaos` | Conference sim |

## Example Queries (Expert Agent)

```
What is QB2?
How do I check if my Tenstorrent device is working?
Show me how to deploy a model with vLLM
What cookbook examples are available?
What's the difference between TT-Metal and TT-Forge?
How do I use tt-smi?
What models can run on P150X4?
```

## Files & Directories

```
tt-claw/
├── openclaw-runtime/        # Generated configs (VISIBLE!)
│   ├── openclaw.json        # Main config
│   ├── agents/              # Agent configs
│   ├── workspace/           # Agent work areas
│   ├── memory/              # Vector database
│   └── gateway.log          # Latest logs
├── config/                  # Templates (version-controlled)
├── bin/tt-claw             # Main CLI
├── lib/                     # Libraries
└── docs/                    # Documentation
```

## Troubleshooting

| Problem | Solution |
|---------|----------|
| Gateway won't start | `tt-claw status` → check logs: `tail -f openclaw-runtime/gateway.log` |
| vLLM not detected | Verify: `curl http://localhost:8000/v1/models` |
| Safety check fails | `tt-claw doctor` → read errors → `tt-claw clean && tt-claw setup` |
| Slow first query | Normal! Downloads embedding models (~500MB) once |
| No responses | Check context window: `grep contextWindow openclaw-runtime/openclaw.json` |

## Safety Quick Check

```bash
# Full safety audit
tt-claw doctor

# Manual checks
grep baseUrl openclaw-runtime/openclaw.json        # Should only show 127.0.0.1
grep fallback openclaw-runtime/openclaw.json       # Should be "none"
grep -A 5 memorySearch openclaw-runtime/openclaw.json  # Should be "local"
```

## Configuration

### Edit Model
```bash
nano openclaw-runtime/openclaw.json
# Edit models array under providers.vllm
tt-claw doctor    # Verify safety
tt-claw restart   # Apply changes
```

### Add Documentation
```bash
nano openclaw-runtime/openclaw.json
# Edit agents.defaults.memorySearch.extraPaths
tt-claw restart   # Re-index
```

### Change Port
```bash
export TT_CLAW_PORT=18791
tt-claw start
```

## Environment Variables

| Variable | Default | Description |
|----------|---------|-------------|
| `OPENCLAW_STATE_DIR` | `~/tt-claw/openclaw-runtime` | Runtime directory |
| `TT_CLAW_PORT` | `18790` | Gateway port |

## Port Reference

| Port | Service | Used By |
|------|---------|---------|
| 8000 | vLLM | Direct model inference |
| 8001 | vLLM Proxy | Compatibility layer (optional) |
| 18789 | Personal OpenClaw | User's personal instance |
| 18790 | tt-claw | Tenstorrent integration |

## Performance Expectations

| Operation | Time |
|-----------|------|
| Setup (first time) | ~5s |
| Gateway startup | 2-5s |
| First query (with memory search) | 30-60s (downloads models) |
| Subsequent queries | <2s |
| Answer generation (8B model) | 2-5s |
| Answer generation (70B model) | 10-30s |

## Safety Guarantees

✅ **Local-only LLM inference** - All AI on Tenstorrent hardware
✅ **No remote API calls** - No data sent to cloud services
✅ **Local embeddings** - Memory search uses local models
✅ **No remote fallbacks** - Fails safe, never uses cloud
✅ **Transparent config** - All configs visible in `openclaw-runtime/`
✅ **Automated validation** - Safety checks run automatically

## Common Workflows

### Daily Use
```bash
tt-claw start
tt-claw tui
# Ask questions...
# Ctrl+C to exit TUI
tt-claw stop
```

### Demo Preparation
```bash
tt-claw doctor          # Verify safety
tt-claw explore         # Show structure
tt-claw start chip-quest  # Start game
tt-claw tui             # Demo
```

### Maintenance
```bash
tt-claw status          # Check health
tail -f openclaw-runtime/gateway.log  # Watch logs
tt-claw restart         # Fix issues
```

### Fresh Start
```bash
tt-claw clean           # Remove runtime
tt-claw setup           # Regenerate
```

## Getting Help

| Resource | Location |
|----------|----------|
| **Quick start** | `docs/README.md` |
| **Technical details** | `docs/ARCHITECTURE.md` |
| **Security** | `docs/SAFETY.md` |
| **OpenClaw docs** | https://docs.openclaw.ai |
| **Tenstorrent docs** | tt-vscode-toolkit lessons |

## Keyboard Shortcuts (TUI)

| Key | Action |
|-----|--------|
| **Ctrl+C** | Exit TUI |
| **Enter** | Send message |
| **Up/Down** | History navigation |

## Version Info

```bash
# Check OpenClaw version
~/openclaw/openclaw.sh --version

# Check tt-claw version
cat ~/tt-claw/IMPLEMENTATION_SUMMARY.md | grep "Date:"

# Check vLLM
curl -s http://localhost:8000/v1/models | python3 -m json.tool
```

## Emergency Commands

```bash
# Stop everything
tt-claw stop
pkill -f openclaw

# Reset everything
tt-claw clean
rm -rf openclaw-runtime
tt-claw setup

# Check network (should show only localhost)
lsof -iTCP -sTCP:ESTABLISHED | grep -E 'openclaw|vllm'
```

## Pro Tips

💡 **Use `tt-claw explore`** to see exactly what was created
💡 **Run `tt-claw doctor`** before important demos
💡 **First memory search is slow** (downloads models) - run once ahead of time
💡 **Context window matters** - 70B models have 128K, 8B have 64K
💡 **Gateway logs are helpful** - `tail -f openclaw-runtime/gateway.log`
💡 **Safety is multi-layer** - preventive, detective, and audit
💡 **Visible is better than hidden** - configs are educational
💡 **Test without network** - verify true local-only operation

---

**Print this card** and keep it handy!

For complete documentation, see `docs/README.md`
