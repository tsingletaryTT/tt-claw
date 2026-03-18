# Context Window Fix for Adventure Games

## The Problem (Discovered 2026-03-10)

User enabled verbose mode and discovered:
```
tokens 69k/16k (423%)
NO_REPLY
```

Terminal Dungeon's SOUL was 69K tokens but context window was capped at 16K!

## Root Causes

1. **Context window too small**: Setup script capped 8B models at 16K "for quality"
2. **SOUL files too large**: Adventure game SOULs are 1300+ lines (69K tokens)
3. **Agent tried memory tools first**: Before it could even read its full SOUL

## The Fix

### 1. Increased Context Window
Changed from 16K to 65K (full vLLM capacity) for 8B models.

**File**: `adventure-games/scripts/setup-game-agents.sh`

**Before** (line 143-145):
```python
if model_size < 30:
    # Small models (8B, 27B): cap at 16K for better quality
    context_window = min(vllm_max, 16384)
```

**After**:
```python
if model_size < 30:
    # Small models (8B, 27B): use vLLM's max (adventure game SOULs need 65K+)
    context_window = vllm_max
```

### 2. Copy models.json to Game Agents
Setup script now copies models.json from main agent to each game agent.

**File**: `adventure-games/scripts/setup-game-agents.sh` (line 54-59)

```bash
# Copy models.json from main agent (has correct context window)
if [ -f "$OPENCLAW_AGENTS/main/agent/models.json" ]; then
    cp "$OPENCLAW_AGENTS/main/agent/models.json" "$OPENCLAW_AGENTS/$game/agent/"
    echo "  ✓ Copied models.json from main agent"
fi
```

## How to Test

### 1. Restart Gateway
```bash
cd ~/openclaw
./openclaw.sh gateway run
```

Wait for: `[gateway] listening on ws://127.0.0.1:18789`

### 2. Launch Terminal Dungeon
```bash
# In another terminal
cd ~/openclaw
./openclaw.sh tui --session "agent:terminal-dungeon:main" --message "start the adventure"
```

### 3. Check Token Count
Enable verbose mode (press 'v' in TUI) and look for token count in footer.

**Should show**: `tokens X/65k` where X < 65k

### 4. Verify Game Starts
Should see ASCII art banner and character creation, NOT "NO_REPLY"

## Verification

```bash
# Check all agents have 65K context
for agent in main chip-quest terminal-dungeon conference-chaos; do
    echo -n "$agent: "
    cat ~/.openclaw/agents/$agent/agent/models.json | jq -r '.providers.vllm.models[0].contextWindow'
done
```

**Expected output**:
```
main: 65536
chip-quest: 65536
terminal-dungeon: 65536
conference-chaos: 65536
```

## Commits

- `c97799f` - Fix adventure game agent invocation and startup behavior
- `19a808e` - Fix context window size for adventure games

## Related Issues

The memory tool issue (agent searching memory before reading SOUL) is a separate OpenClaw behavior. The SOUL context guidance helps but isn't perfect. With 65K context window, the full SOUL can at least fit!

## Success Criteria

- [ ] No token overflow errors (< 100% of 65K)
- [ ] Games start with opening narrative
- [ ] No "NO_REPLY" messages
- [ ] Verbose mode shows reasonable token usage
- [ ] All three games playable

## Future Improvements

1. **Trim SOUL files**: 1300+ lines might be excessive, could optimize
2. **Tool prioritization**: OpenClaw could defer memory tools until after reading SOUL
3. **Context monitoring**: Add warnings if SOUL approaches token limits
