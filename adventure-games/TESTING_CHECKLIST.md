# Adventure Games Testing Checklist

## Complete Fresh Start

```bash
# 1. Run the restart script (in project now!)
cd ~/tt-claw/adventure-games/scripts
./restart-games.sh
```

This script:
- ✅ Stops gateway
- ✅ Clears old sessions (they cache old SOUL files)
- ✅ **Seeds initial memory** (adventure already begun!)
- ✅ Verifies all configs (65K context, CRITICAL section)

## What Was Seeded

Each game now has memory at `~/.openclaw/workspace-<game>/memory/2026-03-10.md`:

### Chip Quest
- Location: Miniaturization chamber (just shrunk)
- Ready to enter the chip
- Inventory empty, full health

### Terminal Dungeon
- Location: Top of stairs to Booth #42's basement
- About to begin character creation
- Permadeath active

### Conference Chaos
- Location: Badge registration (just got badge)
- 1000 credits, zero reputation
- Ready to enter expo floor

## How to Test

### Terminal 1: Proxy (if not already running)
```bash
cd ~/openclaw
python3 vllm-proxy.py
```

### Terminal 2: Gateway (FRESH START)
```bash
cd ~/openclaw
./openclaw.sh gateway run
```

Wait for: `[gateway] listening on ws://127.0.0.1:18789`

### Terminal 3: Test Each Game

#### Test 1: Chip Quest
```bash
cd ~/openclaw
./openclaw.sh tui --session 'agent:chip-quest:main' --message 'start the adventure'
```

**Expected:**
- ✅ Agent reads memory (finds miniaturization scene)
- ✅ Responds with opening narrative and location description
- ✅ Shows numbered choices
- ❌ NO "writes to memory file"
- ❌ NO "no relevant information"

**Token count:** Should show `tokens X/65k` (NOT 16k!)

#### Test 2: Terminal Dungeon
```bash
cd ~/openclaw
./openclaw.sh tui --session 'agent:terminal-dungeon:main' --message 'start the adventure'
```

**Expected:**
- ✅ Character creation prompt
- ✅ GURPS attribute allocation
- ❌ NO "no relevant information"

#### Test 3: Conference Chaos
```bash
cd ~/openclaw
./openclaw.sh tui --session 'agent:conference-chaos:main' --message 'start the adventure'
```

**Expected:**
- ✅ Badge registration scene
- ✅ Conference floor description
- ❌ NO "no relevant information"

### Or Use the Menu
```bash
cd ~/tt-claw/adventure-games/scripts
./adventure-menu.sh
```

## Troubleshooting

### Still seeing 16K context window
- Gateway is using cached session
- Run `./restart-games.sh` again
- Make sure gateway fully stopped before restarting

### Still seeing "writes to memory"
- Check if CRITICAL section is in SOUL:
  ```bash
  grep "CRITICAL: Tool Usage" ~/.openclaw/agents/chip-quest/agent/SOUL.md
  ```
- Should output the line. If not, run setup again:
  ```bash
  cd ~/tt-claw/adventure-games/scripts
  ./setup-game-agents.sh --force
  ```

### Memory not seeded
- Check if templates exist:
  ```bash
  ls ~/tt-claw/adventure-games/memory-templates/*.md
  ```
- Manually seed if needed:
  ```bash
  DATE=$(date +%Y-%m-%d)
  cd ~/tt-claw/adventure-games/memory-templates
  cp chip-quest-start.md ~/.openclaw/workspace-chip-quest/memory/$DATE.md
  cp terminal-dungeon-start.md ~/.openclaw/workspace-terminal-dungeon/memory/$DATE.md
  cp conference-chaos-start.md ~/.openclaw/workspace-conference-chaos/memory/$DATE.md
  ```

### Gateway won't start
- Check port 18789:
  ```bash
  netstat -tlnp | grep 18789
  ```
- Kill existing:
  ```bash
  pkill -f openclaw-gateway
  ```

## Success Criteria

- [ ] All three games start with narrative (not "no information")
- [ ] Context window shows 65K (not 16K)
- [ ] No "writes to memory" messages on first response
- [ ] Games are playable (can make choices)
- [ ] Token count under 100% of available context
- [ ] Verbose mode shows reasonable tool usage

## What's Different Now

### Before (Broken)
1. User: "start the adventure"
2. Agent: `memory_search("start the adventure")`
3. Memory: Empty
4. Agent: "No relevant information in memory files"
5. User: 😞

### After (Fixed)
1. User: "start the adventure"
2. Agent: `memory_search("start the adventure")`
3. Memory: "The adventure just began! I'm at the miniaturization chamber..."
4. Agent: "You've just been shrunk down... [continues with opening narrative]"
5. User: 🎮

## Commits Applied

- `c97799f` - Fixed session key format (agent routing)
- `19a808e` - Fixed context window (16K → 65K)
- `3165ae7` - Added CRITICAL tool usage policy to SOULs
- `8bf6f6a` - Added memory templates and restart script

## Philosophy

**Work WITH OpenClaw's defaults, not against them:**
- OpenClaw agents check memory first? Give them useful memory!
- Default tools can't be disabled? Seed the data they look for!
- Agent wants context? Memory says "adventure just began, here's where you are!"
