# Hermes Custom Skills Integration Test Results

**Date**: March 25, 2026
**Test**: Hermes Agent + Custom Skills for Chip Quest

---

## Discoveries

### ✅ What Worked

1. **Skill Detection**: Hermes successfully detected our custom skills
   - Before: 90 skills
   - After: 92 skills (+2 from our adventure category)
   - Skills appear in the skills count at startup

2. **Skill Recognition**: Hermes recognizes skill names when referenced
   - Shows "⚡ preparing game_master_narrate..." spinner
   - Understands these are skills (not random text)

3. **Python Implementation**: All Python modules work correctly
   - ✅ `game_master_narrate.py` - Returns meta-prompts
   - ✅ `tech_deep_dive.py` - Searches docs successfully
   - ✅ `roll_dice.py` - Generates random rolls
   - ✅ `manage_universe_state.py` - Reads/writes JSON
   - ✅ `personality_mode.py` - Switches modes
   - ✅ `tt_smi_monitor.py` - Handles tt-smi

4. **SKILL.md Format**: Markdown skill files are correctly formatted
   - ✅ YAML frontmatter (name, description, tags)
   - ✅ When to use section
   - ✅ Detailed instructions
   - ✅ Examples

### ❌ What Didn't Work

1. **Skills as Tools**: Hermes treats skills as documentation, not executable functions
   - Skills are instructions for the LLM to follow
   - Skills are NOT callable tools/functions
   - The LLM must use existing Hermes tools (file_read, execute_code, etc.) to implement skill instructions

2. **Architecture Mismatch**: Our approach was partially wrong
   - We created Python functions thinking they'd be callable
   - Hermes skills are actually **instruction manuals**, not code
   - The LLM reads the skill instructions and then uses built-in tools

3. **Missing Integration**: Skills need to map to existing tools
   - `game_master_narrate` skill says "generate narrative" but doesn't tell HOW
   - Should instruct LLM to use `read_file` to load SOUL.md, then generate from that
   - Should instruct LLM to use `execute_code` to run Python helpers if needed

---

## Root Cause Analysis

**The Problem**: We created two types of artifacts that don't connect:

1. **Python modules** (`~/.hermes/skills/adventure/*.py`)
   - These are standalone functions
   - Hermes doesn't call Python directly
   - These would need to be invoked via `execute_code` tool

2. **SKILL.md files** (`~/.hermes/skills/adventure/*/SKILL.md`)
   - These are instructions for the LLM
   - Tell the LLM WHAT to do, not HOW to do it with existing tools
   - Missing the bridge between intent and execution

**What we needed**: SKILL.md files that tell the LLM:
1. Read this instruction
2. Use `read_file` to load X
3. Use `execute_code` to run Y
4. Use `write_file` to save Z
5. Synthesize and respond

---

## Comparison to Pokemon Player Skill

**Pokemon Player** (working skill):
```markdown
### Step 1: OBSERVE
GET /state for position, HP, battle, dialog.
GET /screenshot and save to /tmp/pokemon.png, then use vision_analyze.
```

This tells the LLM exactly which tools to use (API calls via execute_code, vision_analyze).

**Our game_master_narrate** (not working):
```markdown
Generate a vivid, atmospheric description that:
1. Uses second-person ("You see...", "You hear...")
2. Includes sensory details (visual, audio, feeling)
```

This tells the LLM WHAT to generate, but not HOW to use tools to do it.

---

## Lessons Learned

### "Sometimes a tool is just a short prompt"

**This was RIGHT philosophically, but WRONG architecturally for Hermes.**

✅ **Right**: Tools don't have to execute code - they can be prompting strategies
❌ **Wrong for Hermes**: Hermes skills aren't "tools" - they're instruction manuals

### What We Should Have Built

**Option 1: Pure Instruction Skills**
- SKILL.md tells LLM: "Read SOUL.md, then generate narrative following these rules..."
- No Python code needed
- LLM uses existing tools (read_file) to access game data

**Option 2: Python Helper + Instructions**
- SKILL.md tells LLM: "Use execute_code to run ~/hermes-skills/adventure/narrate.py"
- Python script does the work
- LLM calls it via execute_code tool

**Option 3: Hybrid**
- SKILL.md gives instructions
- For complex logic, tells LLM to use execute_code with Python helpers
- Best of both worlds

---

## What Actually Works in Hermes

Based on testing and examining working skills:

1. **Skills are documentation** that the LLM reads
2. **Skills give step-by-step instructions** using existing Hermes tools
3. **Tools are the execution layer** (file, code_execution, browser, etc.)
4. **Skills orchestrate tools** to accomplish complex tasks

**Example flow**:
```
User: "Play Pokemon"
→ Hermes loads pokemon-player skill (SKILL.md)
→ LLM reads instructions: "Clone repo, setup venv, run server..."
→ LLM uses execute_code tool to run bash commands
→ LLM uses browser_vision tool to see game state
→ LLM uses execute_code to send API requests
```

---

## Recommended Next Steps

### Option A: Rewrite Skills as Pure Instructions (Fastest)

Convert SKILL.md files to tell the LLM how to use existing tools:

```markdown
---
name: game_master_narrate
---
# Game Master Narrate

## When to Use
- Player enters new area in Chip Quest

## Procedure

1. **Load game definition**:
   Use `read_file` tool to load:
   `/home/ttuser/tt-claw/adventure-games/games/chip-quest/SOUL.md`

2. **Find relevant section** for the location

3. **Generate narrative** following these rules:
   - Use second-person perspective
   - Include sensory details
   - 2-4 paragraphs for medium detail
   - [rest of guidelines...]

4. **Respond** with generated narrative
```

### Option B: Keep Python + Add Execution Instructions (More Powerful)

Keep Python modules but update SKILL.md to tell LLM how to call them:

```markdown
## Procedure

1. Use `execute_code` tool with Python:
   ```python
   import sys
   sys.path.insert(0, '/home/ttuser/.hermes/skills')
   from adventure.game_master_narrate import game_master_narrate
   result = game_master_narrate("Entry Port", "welcoming", "medium")
   print(result['prompt'])
   ```

2. Follow the generated prompt instructions to create narrative
```

### Option C: Abandon Hermes Custom Skills (Nuclear Option)

- Hermes's skill system is complex and fighting its architecture
- Use OpenClaw with our existing improvements instead
- Or create a simpler Python wrapper around vLLM

---

## Time Investment

**What we built**:
- 6 Python modules (functional)
- 2 SKILL.md files (partially functional)
- 2 __init__.py manifests
- 1 game-master persona (6.5 KB)
- 1 launcher script
- Documentation

**Total time**: ~2 hours

**ROI**: Learned Hermes architecture deeply, validated "prompt-as-tool" philosophy, but discovered architectural mismatch

---

## Recommendation

**Short-term**: Test Option A (pure instruction skills) with 1-2 skills to validate approach

**Medium-term**: If Option A works, convert remaining skills. Otherwise, return to OpenClaw with improvements.

**Long-term**: The philosophy "sometimes a tool is just a short prompt" is VALID and should be applied to whatever framework we use. The issue isn't the philosophy, it's the execution within Hermes's specific architecture.

---

## Status: BLOCKED

**Blocker**: Need to decide on approach before continuing integration test.

**Question for user**:
1. Try Option A (rewrite skills as pure instructions)?
2. Try Option B (keep Python, add execution instructions)?
3. Abandon Hermes custom skills and return to OpenClaw?
4. Other approach?
