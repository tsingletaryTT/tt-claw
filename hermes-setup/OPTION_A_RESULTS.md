# Option A Results: Instruction-Based Skills

**Date**: March 25, 2026
**Approach**: Rewrite skills as pure instructions (no Python code)
**Status**: ❌ Blocked by architectural constraints

---

## What We Built

### Rewritten Skills (Instruction Format)

1. **game_master_narrate** - Self-contained narrative generator
   - Includes full opening narrative
   - Descriptions of all 7 regions
   - Example interactions
   - No required tool calls

2. **tech_deep_dive** - Documentation search instructions
   - Step-by-step search procedure
   - Uses `search_files` and `read_file`
   - Single tool call approach

---

## Test Results

### Test 1: Skill Detection ✅
```bash
hermes chat -s game_master_narrate -q "Start Chip Quest!"
```

**Result**: Skill loaded successfully
- Skill count increased from 90 → 92
- Hermes recognized `game_master_narrate` skill
- Showed "⚡ preparing game_master_narrate..." spinner

### Test 2: vLLM Tool Calling Configuration ✅
```bash
docker logs tt-inference-server | grep tool
```

**Result**: Tool calling properly configured
```
vllm_args: {
    "enable_auto_tool_choice": true,
    "tool_call_parser": "llama3_json"
}
```

Flags from `8b-openclaw.sh` ARE being passed correctly.

### Test 3: Skill Execution ❌
```bash
hermes chat -s game_master_narrate -q "Start Chip Quest!"
```

**Result**: LLM tried to use tools instead of following instructions
- Attempted `skill_view` tool call
- Attempted `browser_navigate` to "www.chipquest.com"
- Did NOT generate narrative directly

### Test 4: Multiple Tool Calls ❌
```bash
hermes chat -s game_master_narrate -q "Start Chip Quest!"
```

**Result**: vLLM rejected multiple simultaneous tool calls
```
Error 400: This model only supports single tool-calls at once!
```

Hermes tried to make 3 tool calls in parallel:
```
┊ 📖 preparing read_file…
┊ 📖 preparing read_file…
┊ ⚡ preparing game_master_narrate…
```

### Test 5: Direct Narrative Prompting ⏱️
```bash
hermes chat -q "You are Game Master. Just narrate, don't use tools. Start!"
```

**Result**: Timeout (90 seconds)
- Model struggled to generate without tool usage
- Hermes's tool-first architecture conflicts with pure text generation

---

## Root Cause Analysis

### Constraint #1: Single Tool Call Limitation

**Llama-3.1-8B with llama3_json parser**:
- ✅ Tool calling IS enabled
- ❌ Can only make ONE tool call per turn
- ❌ Cannot make parallel tool calls

This is NOT a configuration issue - it's a model/parser limitation.

### Constraint #2: Hermes's Tool-First Architecture

**Hermes Agent behavior**:
- Always tries to accomplish tasks via tool calls
- Skills are reference material, not strict directives
- LLM interprets "Start Chip Quest" as a task requiring tools
- Even with explicit "don't use tools" instructions, still tries

**Evidence**:
1. Tried to navigate to website instead of narrating
2. Tried to use `skill_view` to "load" the skill
3. Tried to make multiple tool calls for file reading
4. Timed out when asked to generate without tools

### Constraint #3: Architectural Mismatch

**Narrative generation requirements**:
- Pure text output
- No tools needed
- Just follow story guidelines

**Hermes Agent design**:
- Tool-first execution
- Tasks accomplished via tool orchestration
- Text generation seen as tool result, not primary output

**Conclusion**: Hermes is designed for tasks like "deploy a model" (execute commands, read files, monitor logs), NOT for pure narrative generation.

---

## Comparison to OpenClaw POC

### Hermes POC Results

**Attempted**: "Start the adventure"

**What happened**:
1. Tried to execute `python adventure_game.py`
2. Used `clarify` tool to ask questions (timed out)
3. Could not generate narrative without trying to execute something

**Diagnosis**: Tool-first architecture fights narrative-first task

### OpenClaw Behavior

**Attempted**: Same query

**What happened**:
1. Generated narrative directly
2. Tools optional, rarely used
3. Pure conversation mode

**Diagnosis**: Narrative-first architecture, but passive (doesn't proactively search docs or use tools)

---

## The Fundamental Tension

### Our Goal
Create agents that:
- Generate immersive narratives (like OpenClaw)
- Proactively search documentation (like Hermes)
- Ground responses in technical reality
- Use "tools as prompting strategies"

### The Reality

**Hermes**:
- ✅ Proactive tool use
- ✅ Excellent at orchestration
- ❌ Fights pure narrative generation
- ❌ Can't blend narrative + tools smoothly

**OpenClaw**:
- ✅ Excellent narrative generation
- ✅ Pure conversation mode
- ❌ Passive, doesn't use tools
- ❌ No documentation grounding

**Neither framework does what we want** because:
1. Hermes: Tool-first (wrong mode for narrative)
2. OpenClaw: Narrative-first but passive (right mode, wrong behavior)

---

## What We Learned

### ✅ Validated

1. **"Tools as prompts" philosophy is sound**
   - Prompting strategies CAN be packaged
   - Just not as Hermes skills for this use case

2. **vLLM tool calling works correctly**
   - Flags in `8b-openclaw.sh` are properly passed
   - `enable_auto_tool_choice: true` is active
   - `tool_call_parser: llama3_json` is working
   - Single tool call limitation is real

3. **Skill system architecture is clear**
   - Skills = instruction manuals (not executable code)
   - Skills orchestrate existing tools
   - Works great for task automation
   - Not suited for pure generation tasks

### ❌ Invalidated

1. **Hermes can do narrative games with custom skills**
   - Architecture mismatch too fundamental
   - Tool-first design conflicts with narrative-first content

2. **Option A (pure instructions) solves the problem**
   - Instructions ARE loaded correctly
   - LLM just doesn't follow them in the way we need
   - Still tries to use tools

---

## Recommendations

### Option 1: Return to OpenClaw ⭐ (Recommended)

**Why**:
- Already works for narrative generation
- Correct architecture (narrative-first)
- We can improve passivity without changing frameworks

**How to improve**:
1. Add system prompts that encourage proactive doc search
2. Configure tool usage thresholds
3. Apply "prompt-as-tool" philosophy within OpenClaw's system prompts

**Time**: Immediate (reuse existing setup)

### Option 2: Hybrid Approach

**Idea**: Use Hermes for research, OpenClaw for gameplay

- Hermes Agent: Technical deep dives, doc search, hardware monitoring
- OpenClaw: Chip Quest gameplay, narrative generation

**Time**: 2-3 hours to set up dual system

### Option 3: Custom Python Wrapper

**Idea**: Build our own framework around vLLM

- Direct vLLM API calls
- Custom prompt orchestration
- Our own "tool" system (actually just prompts)

**Time**: 1-2 days

### Option 4: Continue with Hermes (Not Recommended)

**Approach**: Fight the architecture harder

- Create even more explicit instructions
- Try different prompting strategies
- Maybe switch to a different model

**Why not**: Diminishing returns, still fighting fundamental mismatch

---

## Time Investment Summary

**Hermes Custom Skills Project**:
- Planning: 1 hour
- Python implementation: 1 hour
- Markdown skill conversion: 1 hour
- Testing and debugging: 2 hours
- **Total: ~5 hours**

**What we gained**:
- Deep understanding of Hermes architecture
- Validation of "prompt-as-tool" philosophy
- Clear diagnosis of why it won't work for this use case
- Confirmed vLLM tool calling works correctly

**What we lost**:
- 5 hours that could have been spent improving OpenClaw

---

## Final Verdict

**Option A (Pure Instruction Skills): ❌ FAILED**

**Reason**: Architectural mismatch is too fundamental. Hermes's tool-first design cannot be adapted for pure narrative generation without fighting the framework at every turn.

**Recommendation**: Return to OpenClaw and apply what we learned about prompting strategies within that framework.

---

**Next Action**: Wait for user decision on path forward.
