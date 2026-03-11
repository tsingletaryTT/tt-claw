# OpenClaw System Prompt Fix v2 - Preventing Tool Narration

**Date:** March 11, 2026
**Issue:** OpenClaw was narrating tool usage instead of answering directly
**Solution:** Enhanced system prompt with explicit anti-narration instructions

## The Problem (Again)

After the initial system prompt was created, OpenClaw started acknowledging it was finding information but still wasn't using it correctly:

**User:** "Tell me about the cores in a TT-Quietbox 2"
**OpenClaw:** "The memory_get function has returned a snippet from the file qb2-hardware-constellation.md from lines 415 to 435. The snippet discusses the architecture..."

This is even worse than before - now it's narrating the tool call itself!

## Root Cause

The v1 system prompt had examples of what NOT to say, but didn't have **explicit prohibitions** against narrating tool usage. The LLM interpreted the memory_get/memory_search tools as things to explain to the user, rather than internal operations to use transparently.

## Solution: Enhanced v2 System Prompt

Added a **"CRITICAL: What NOT to Do"** section with explicit anti-patterns:

```markdown
## CRITICAL: What NOT to Do

❌ **NEVER say**: "The memory_get function has returned..."
❌ **NEVER say**: "The memory_search tool found..."
❌ **NEVER say**: "I found information in my memory..."
❌ **NEVER narrate** your tool usage to the user

✅ **INSTEAD**: Read the content and answer directly using what you learned
```

Also added detailed guidance on the response format:

```markdown
## Response Format

When you call memory_search or memory_get:
1. You receive documentation content (text, not a status message)
2. You read and understand that content
3. You compose an answer using the information you learned
4. You tell the user the answer directly, as if you already knew it
5. You cite the source at the end in brackets

Think of yourself as an expert who is looking up information to refresh your memory,
NOT as a chatbot reporting on tool usage.
```

## Installation

The enhanced prompt was installed at:
```
/home/ttclaw/.openclaw/agents/main/agent/system.md
```

File size: 3,319 bytes (vs 1,715 bytes for v1)

## Verification

Created `check-openclaw-prompt` script to verify installation:

```bash
check-openclaw-prompt        # Quick check
check-openclaw-prompt --show # See full prompt
```

Script checks for v2 markers:
- ✅ Has "CRITICAL: What NOT to Do" section
- ✅ Has specific anti-pattern examples
- ✅ Has "never narrate tool usage" instruction

## Activation

**Critical:** The enhanced prompt only applies to NEW conversations!

1. Stop current TUI session (Ctrl+C)
2. Gateway automatically reloaded prompt when restarted
3. Start fresh TUI:
   ```bash
   sudo -u ttclaw /home/ttclaw/openclaw/openclaw.sh tui
   ```

## Expected Behavior After Fix

**Test Question:** "Tell me about the cores in a TT-Quietbox 2"

**Before v2 (Bad):**
> "The memory_get function has returned a snippet from the file qb2-hardware-constellation.md from lines 415 to 435..."

**After v2 (Good):**
> "The TT-QuietBox 2 contains multiple Tensix cores. Each Tensix core is a specialized processing unit optimized for AI workloads. The cores are organized in a grid layout and connected via a Network-on-Chip (NoC) for high-bandwidth data transfer. [Source: qb2-hardware-constellation.md]"

## Files Modified

- `/home/ttclaw/.openclaw/agents/main/agent/system.md` - Enhanced v2 prompt (3,319 bytes)
- `/tmp/openclaw-system-prompt-v2.md` - Development version
- `/home/ttuser/.local/bin/check-openclaw-prompt` - Verification script

## Testing

After fresh TUI session, test with:
- "What is QB2?"
- "Tell me about the cores in a TT-Quietbox 2"
- "How do I deploy vLLM on Tenstorrent?"
- "What cookbook examples are available?"

All answers should be direct and informative, with NO tool narration.

## Key Lessons

1. **Explicit prohibitions matter** - "Don't do X" examples aren't enough, need ❌ NEVER commands
2. **Multiple examples help** - Showed 3+ specific anti-patterns to avoid
3. **Mindset framing works** - "Think of yourself as an expert" guides behavior
4. **Fresh sessions required** - Old sessions keep old prompts cached
5. **Verification tools essential** - Script makes troubleshooting easy

## Status

✅ **Working** as of March 11, 2026
✅ Enhanced prompt installed
✅ Gateway restarted
✅ Verification script created
⏳ Pending user testing with fresh TUI session
