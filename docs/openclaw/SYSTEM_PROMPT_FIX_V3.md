# OpenClaw System Prompt Fix v3 - Extreme Anti-Narration

**Date:** March 11, 2026
**Issue:** Agent STILL narrating tool usage despite v2 prompt
**Root Cause:** 8B model may be too weak, or prompt structure needs to be more imperative
**Solution:** Ultra-direct v3 prompt with behavioral imperatives

## The Problem (Still Happening!)

Even after v2 with explicit anti-patterns, the agent continued to narrate:

**User:** "Tell me about compiling tt-metal"
**Agent:** "Based on the memory search results, it seems that the user is looking for information about compiling tt-metal. To provide a more direct answer, you could use the memory_get function..."

**User:** "Use that function then dude"
**Agent:** [Still narrating instead of just using it]

This is a **meta-cognitive failure** - the agent is analyzing what it SHOULD do rather than just doing it.

## Analysis

### Possible Causes

1. **8B Model Limitation**: Llama-3.1-8B-Instruct may not have enough capacity to:
   - Follow complex meta-instructions about NOT narrating
   - While also performing memory search tasks
   - While also following tool calling protocols
   - This is a known issue with smaller models - they struggle with behavioral constraints

2. **Prompt Structure**: Examples might not be enough. Need stronger imperative commands.

3. **Session Persistence**: Even fresh TUI sessions might be inheriting some cached behavior.

### Evidence This Might Be a Model Issue

- User frustration: "Use that function then dude" shows repeated failure
- Agent pattern: Consistently describes what it COULD do rather than doing it
- Similar behavior seen in other 8B models with complex meta-instructions
- 70B models handle this type of constraint much better

## Solution: v3 Ultra-Direct Prompt

Completely rewrote the system prompt with:

1. **Shorter, punchier rules** - No long explanations
2. **Behavioral imperatives** - "You ARE an expert" not "You should act like"
3. **Mental model framing** - "You are a human expert with perfect memory"
4. **Removed complexity** - Fewer words, stronger commands

### Key Changes from v2

**v2 style:**
```markdown
## CRITICAL: What NOT to Do

❌ **NEVER say**: "The memory_get function has returned..."
❌ **NEVER say**: "The memory_search tool found..."
[list of patterns]
```

**v3 style:**
```markdown
## Absolute Rules

**NEVER EVER do these things:**
- Don't say "The memory_get function has returned"
- Don't say "Based on the memory search results"
- Don't suggest tool calls to the user
- Don't narrate your internal process

**ALWAYS do these things:**
- Just answer the question directly
- Use memory tools silently (user never sees this)
- State facts you found as if you know them
```

### The Mental Model Shift

Added explicit framing:
> "You are a human expert who happens to have perfect memory of all Tenstorrent documentation. When someone asks you something, you mentally reference your knowledge and tell them the answer. You don't say 'let me check my notes' - you just know the answer because you're an expert."

This reframes the task as **being an expert** rather than **describing how to use tools**.

## Installation

```bash
sudo cp /tmp/openclaw-system-prompt-v3.md /home/ttclaw/.openclaw/agents/main/agent/system.md
sudo chown ttclaw:ttclaw /home/ttclaw/.openclaw/agents/main/agent/system.md
sudo pkill -f openclaw-gateway
sudo -u ttclaw bash -c 'cd /home/ttclaw/openclaw && ./openclaw.sh gateway run &'
```

Then start FRESH TUI:
```bash
sudo -u ttclaw /home/ttclaw/openclaw/openclaw.sh tui
```

## Testing

Try the same question that failed before:
```
Tell me about compiling tt-metal
```

**Expected (v3):**
> "To compile tt-metal, you need Python 3.11 and clang-17 as prerequisites. First install these dependencies, then run the build command with the appropriate flags. [Source: forge-image-classification.md]"

**Not this (v2 failure):**
> "Based on the memory search results, it seems that the user is looking for information about compiling tt-metal. To provide a more direct answer, you could use the memory_get function..."

## If This Still Doesn't Work

### Option 1: Upgrade to 70B Model

The **real solution** might be using Llama-3.3-70B-Instruct instead of 8B:
- Better instruction following
- Can handle complex behavioral constraints
- More reliable tool usage
- Better reasoning about meta-instructions

See: `~/tt-claw/CLAUDE.md` section "Llama-3.3-70B Upgrade"

### Option 2: Simplify System Prompt Further

Remove ALL examples and just use raw imperatives:
```markdown
You are an expert on Tenstorrent. Users ask you questions. You answer them directly using your indexed documentation. Never narrate your process. Never mention tools. Just answer.
```

### Option 3: Accept Model Limitations

8B models may simply not be capable of this level of behavioral constraint while also performing complex tasks. This is a known limitation of smaller models.

## Verification

```bash
check-openclaw-prompt --show
```

Should show v3 content with "You are a human expert who happens to have perfect memory" phrasing.

## Key Insights

1. **Smaller models struggle with meta-instructions** - 8B may not be enough
2. **Behavioral framing matters** - "You ARE" is stronger than "You should"
3. **Simplicity helps** - Shorter, punchier rules are clearer
4. **70B is likely needed** - For production use with complex constraints
5. **This is a known problem** - Not unique to OpenClaw or Tenstorrent

## Status

⏳ **Testing v3** - Prompt installed, gateway restarted
❓ **May require 70B** - If v3 still fails, model upgrade needed
📝 **Documented limitation** - 8B may not handle this constraint reliably

## Recommendation

For **production booth demos**, strongly recommend:
- ✅ Deploy Llama-3.3-70B-Instruct (better behavior, better quality)
- ⚠️ Keep 8B as fallback (faster, but may have narration issues)
- 📋 Brief presenters on potential "meta-narration" behavior with 8B
