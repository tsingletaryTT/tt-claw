# TT-Claw Architecture - Clean Unified Setup

**Last Updated:** 2026-03-18  
**Status:** Production Ready

## Directory Structure (New Clean Layout)

```
~/tt-claw/                        # Everything visible here!
├── bin/                          # All commands (ONE place)
│   ├── openclaw                  # Main wrapper
│   ├── services                  # Start/stop services
│   └── adventure-menu            # Game launcher
├── runtime/                      # All state & data
│   ├── openclaw.json             # Configuration
│   ├── agents/                   # 4 agents (main + 3 games)
│   ├── memory/main.sqlite        # 174 files, 1,217 chunks
│   └── logs/                     # All logs here
├── proxy/vllm-proxy.py           # Compatibility layer
├── adventure-games/              # Game content
├── config/                       # Templates
└── docs/                         # Documentation

~/openclaw/                       # Software (separate)
```

## Usage

```bash
# Start everything
~/tt-claw/bin/services

# Use OpenClaw
~/tt-claw/bin/openclaw tui
~/tt-claw/bin/openclaw status

# Adventure games
~/tt-claw/bin/adventure-menu
```

## What Changed Today (2026-03-18)

**CLEANUP COMPLETED:**
- ✅ Renamed `openclaw-runtime/` → `runtime/`
- ✅ All commands now in `bin/`
- ✅ Deleted `~/.openclaw/` (backed up to /tmp)
- ✅ Deleted `/home/ttclaw/.openclaw/` (backed up)
- ✅ No more hidden directories!
- ✅ One clear way to do things

## Services Architecture

```
User → bin/openclaw tui
     → Gateway (port 18789)
     → Proxy (port 8001) strips API fields
     → vLLM (port 8000)
     → Tenstorrent Hardware
```

## Key Points

1. **Everything visible** in `~/tt-claw/`
2. **One command location:** `bin/`
3. **One runtime location:** `runtime/`
4. **Unified logs:** `runtime/logs/`
5. **Git-friendly:** Can commit entire project
6. **No ttclaw user:** Unnecessary complexity removed

## Known Issues

- **Memory search not working:** Agent doesn't call memory_search tool
- **Agent timeouts:** Using 70B model is slower
- **Need better memory system:** Local search unreliable

---

See CLAUDE.md for complete history and troubleshooting.
