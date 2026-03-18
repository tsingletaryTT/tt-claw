# Memory Tool Usage Fix

## The Problem (Discovered 2026-03-10)

When launching conference-chaos, the agent called `memory_search("start the adventure")`, found nothing, and reported:

```
The memory_search function is called with the query "start the adventure" and returns an empty result set,
indicating that there is no relevant information in the memory files.
```

Instead of continuing to read the SOUL and start the game!

## Root Cause

1. **Default OpenClaw behavior**: All agents get built-in memory tools (memory_search, memory_get, memory_write)
2. **Agent prioritizes memory**: OpenClaw's default behavior searches memory for context before responding
3. **Soft guidance wasn't enough**: Our "Context for you" section in Starting Scenario was too far down and too gentle

## The Fix

Added **CRITICAL: Tool Usage Policy** section at the TOP of each SOUL (before Core Identity).

### Example from conference-chaos/SOUL.md:

```markdown
## 🎯 CRITICAL: Tool Usage Policy

**When player says "start the adventure", "begin", "new game" or similar:**

1. **DO NOT** call memory_search, memory_get, or memory_write
2. **DO NOT** check for existing story or context
3. **IMMEDIATELY** jump to the "Starting Scenario" section below and respond with the opening narrative
4. The game IS the context - start playing NOW

**During gameplay (after first response):**
- Use game tools naturally: show_floor_map, npc_conversation, collect_card
- Memory tools are optional and only if they genuinely help gameplay
- Focus on the story and player choices, not metadata
```

### Why This Should Work

1. **Position**: At the very top of SOUL (read first)
2. **Clarity**: Numbered steps, explicit DO NOT commands
3. **Visual**: 🎯 emoji and CRITICAL in heading
4. **Specific**: Names the exact tools to avoid (memory_search, memory_get, memory_write)
5. **Actionable**: "IMMEDIATELY jump to Starting Scenario"

## Files Modified

All three game SOUL templates:
- `adventure-games/games/chip-quest/SOUL.md`
- `adventure-games/games/terminal-dungeon/SOUL.md`
- `adventure-games/games/conference-chaos/SOUL.md`

## Deployment

Setup script re-run automatically copies updated SOULs to workspace:
- `~/.openclaw/agents/chip-quest/agent/SOUL.md`
- `~/.openclaw/agents/terminal-dungeon/agent/SOUL.md`
- `~/.openclaw/agents/conference-chaos/agent/SOUL.md`

## Testing

### 1. Restart Gateway
```bash
cd ~/openclaw
./openclaw.sh gateway run
```

### 2. Launch Game
```bash
cd ~/openclaw
./openclaw.sh tui --session "agent:conference-chaos:main" --message "start the adventure"
```

Or use menu:
```bash
cd ~/tt-claw/adventure-games/scripts
./adventure-menu.sh
```

### 3. What You Should See

**Before** (broken):
```
The memory_search function is called with the query "start the adventure"
and returns an empty result set...
```

**After** (fixed):
```
# 🎪 CONFERENCE CHAOS: EAC 2026
## A Hitchhiker's Guide to Trading, Networking, and Bureaucracy

[ASCII art banner]

WELCOME TO THE EXPERIENCE ARCHITECT CONVERGENCE 2026
...
```

### 4. Enable Verbose Mode (Optional)

Press 'v' in TUI to see tool calls. You should NOT see memory_search on first message.

## Alternative Solutions Considered

### Option 1: Disable Memory Tools (REJECTED)
- **Idea**: Configure agent to not have memory tools at all
- **Why rejected**:
  - No clear way to disable default tools in OpenClaw config
  - Memory tools might be useful during long campaigns
  - Better to guide behavior than restrict capabilities

### Option 2: Pre-fill Memory (REJECTED - User's Question)
- **Idea**: Pre-populate memory with story content
- **Why rejected**:
  - Doesn't solve root problem (agent checking memory instead of starting)
  - Memory is for gameplay state, not game definition
  - SOUL is the source of truth for game rules

### Option 3: Modify tools.json (INSUFFICIENT)
- **Idea**: Add tool restrictions in tools.json
- **Why rejected**:
  - tools.json only defines game-specific tools
  - Can't override OpenClaw's built-in tools
  - Memory tools are built-in, not in tools.json

## Success Criteria

- [ ] No memory_search calls on "start the adventure"
- [ ] Game starts immediately with opening narrative
- [ ] ASCII art banners display correctly
- [ ] All three games exhibit fixed behavior
- [ ] Verbose mode shows no memory tools on first message

## Commits

- `c97799f` - Fix session key format
- `19a808e` - Fix context window size
- `3165ae7` - Add explicit tool usage policy

## Related Files

- `CONTEXT_WINDOW_FIX.md` - Previous fix for 69K/16K token overflow
- `OPENCLAW_FINAL_INSTRUCTIONS.md` - General setup guide
