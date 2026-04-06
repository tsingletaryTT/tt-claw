# Hermes Custom Skills Reference

## Overview

Custom skills created for Chip Quest adventure game that package **prompting strategies as tools**.

**Philosophy**: "Sometimes a tool is just a short prompt" - these skills work WITH Hermes's tool-first architecture instead of fighting it.

---

## Installation

All skills installed in `~/.hermes/skills/`:

```
~/.hermes/skills/
├── adventure/
│   ├── game_master_narrate.py
│   ├── tech_deep_dive.py
│   ├── roll_dice.py
│   ├── manage_universe_state.py
│   ├── personality_mode.py
│   └── __init__.py
└── tenstorrent/
    ├── tt_smi_monitor.py
    └── __init__.py
```

---

## Skills

### 1. game_master_narrate (Prompt-Based)

**Purpose**: Generate atmospheric narrative descriptions

**Type**: Meta-prompt - returns structured prompts for LLM

**Usage**:
```python
game_master_narrate(location, mood="mysterious", detail_level="medium")
```

**Parameters**:
- `location` - Where the player is (e.g., "Tensix Core Gardens")
- `mood` - Atmosphere: mysterious, welcoming, dangerous, technical
- `detail_level` - low/medium/high (controls verbosity)

**Example**:
```
game_master_narrate("Entry Port", "welcoming", "high")
→ Returns detailed prompt for generating 2-4 paragraph scene description
```

---

### 2. tech_deep_dive (Hybrid)

**Purpose**: Search TT documentation and explain concepts

**Type**: Hybrid - file search (code) + synthesis (prompt)

**Usage**:
```python
tech_deep_dive(concept, context="gameplay")
```

**Parameters**:
- `concept` - Technical term (e.g., "Tensix core", "NoC routing")
- `context` - "gameplay" (fun) or "technical" (detailed)

**Example**:
```
tech_deep_dive("Tensix core", "gameplay")
→ Searches ~/.hermes/memories/tt-docs/ for "Tensix core"
→ Finds references in metalium.md
→ Returns prompt to synthesize fun explanation
```

**Searches**: 2.9 MB of indexed TT documentation (160 markdown files)

---

### 3. roll_dice (Hybrid)

**Purpose**: Handle game mechanics (combat, skill checks, randomness)

**Type**: Hybrid - random generation (code) + narration (prompt)

**Usage**:
```python
roll_dice(num_dice=3, sides=6, target=None, skill_name="unknown")
```

**Parameters**:
- `num_dice` - Number of dice (default 3)
- `sides` - Sides per die (default 6)
- `target` - Target number to roll under (None = just roll)
- `skill_name` - What skill is being tested

**Example**:
```
roll_dice(3, 6, target=12, skill_name="Circuit Navigation")
→ Rolls: [4, 3, 2] = 9
→ Success: True (9 ≤ 12)
→ Returns prompt to narrate success cinematically
```

---

### 4. manage_universe_state (Code-Based)

**Purpose**: Track cross-game state (achievements, discoveries, NPCs)

**Type**: Pure code - JSON file manipulation

**Usage**:
```python
update_universe(game, event_type, data)
check_universe(game, query_type)
```

**Parameters**:
- `game` - "chip-quest", "terminal-dungeon", "conference-chaos"
- `event_type` - "achievement", "discovery", "npc_met", "graffiti"
- `query_type` - "achievements", "other_players", "npc_status"

**Example**:
```
update_universe("chip-quest", "achievement", {
    "timestamp": "2026-03-25",
    "description": "Defeated first Memory Grue"
})
→ Updates ~/.hermes/memories/universe-state.json
```

**Cross-Game Features**:
- Achievements shared across all 3 games
- Graffiti left by one player visible to another
- NPC states persist (who has met whom)

---

### 5. personality_mode (Prompt-Based)

**Purpose**: Switch narrative tone/personality dynamically

**Type**: Meta-prompt - returns system-level personality adjustments

**Usage**:
```python
personality_mode(mode_name)
```

**Available Modes**:

1. **archie_welcoming** (default)
   - Warm, encouraging tone
   - Architecture puns
   - Patient explanations

2. **archie_mysterious**
   - Lower descriptive "lighting"
   - Hint at secrets
   - Ominous foreshadowing
   - Memory Grues lurking

3. **archie_technical**
   - Cite specific documentation
   - Precise terminology (Tensix, NoC, RISC-V)
   - Include numbers (bandwidth, latency)
   - Reference METALIUM_GUIDE sections

4. **dungeon_master**
   - Zork-style wit
   - "It is pitch dark. You are likely to be eaten by a grue."
   - Deadpan delivery of absurd situations
   - Punish foolish actions, reward creativity

**Example**:
```
personality_mode("archie_technical")
→ Returns system prompt: "You are Archie in deep technical mode. Cite specific documentation..."
```

---

### 6. tt_smi_monitor (Code-Based)

**Purpose**: Integrate real Tenstorrent hardware status into narrative

**Type**: Hybrid - tt-smi execution (code) + narrative hooks (prompt)

**Usage**:
```python
tt_smi_status()
integrate_hardware_state(game_context)
```

**Example**:
```
tt_smi_status()
→ Runs: tt-smi -s (JSON mode)
→ Returns: {
    "metrics": {"temperatures": [65], "utilization": [80]},
    "narrative_hook": "The chip hums with activity, warm but stable..."
}

integrate_hardware_state("exploring the NoC highways")
→ Returns prompt that incorporates real metrics:
   "The Tensix cores around you pulse with activity - you sense 80% throughput..."
```

---

## Tool Combination Patterns

### Pattern 1: Enter New Area

```
1. check_universe("chip-quest", "other_players")
   → Check if other players left discoveries here

2. game_master_narrate("DRAM Caverns", mood="dangerous", detail_level="high")
   → Set atmospheric scene

3. [If player asks about hardware]
   tech_deep_dive("DRAM latency", context="gameplay")
   → Ground explanation in documentation
```

### Pattern 2: Combat/Challenge

```
1. game_master_narrate(location, mood="tense")
   → Build tension

2. roll_dice(3, 6, target=player_dex, skill_name="Circuit Navigation")
   → Resolve action

3. game_master_narrate(outcome, mood="triumphant" or "ominous")
   → Describe results cinematically
```

### Pattern 3: Discovery

```
1. update_universe("chip-quest", "discovery", {"location": "...", "what": "..."})
   → Record in universe state

2. game_master_narrate(discovery_scene, mood="triumphant", detail_level="high")
   → Celebrate the discovery

3. [If technical]
   tech_deep_dive(discovered_concept, context="technical")
   → Deep explanation
```

### Pattern 4: Teaching Moment

```
1. tech_deep_dive("NoC routing", context="gameplay")
   → Search docs and synthesize explanation

2. game_master_narrate(scene_with_concept, mood="welcoming")
   → Integrate knowledge into story

3. [Optional]
   integrate_hardware_state("learning about NoC")
   → Connect to real hardware
```

---

## Testing

### Python Unit Tests (✅ Passed)

```bash
cd ~/.hermes/skills
python3 -c "from adventure.game_master_narrate import game_master_narrate; print(game_master_narrate('Entry Port'))"
python3 -c "from adventure.tech_deep_dive import tech_deep_dive; print(tech_deep_dive('Tensix'))"
python3 -c "from adventure.roll_dice import roll_dice; print(roll_dice(3, 6, 12, 'DEX'))"
python3 -c "from adventure.manage_universe_state import check_universe; print(check_universe('chip-quest', 'achievements'))"
python3 -c "from adventure.personality_mode import personality_mode; print(personality_mode('archie_welcoming'))"
python3 -c "from tenstorrent.tt_smi_monitor import tt_smi_status; print(tt_smi_status())"
```

All skills import successfully and execute without errors.

### Full Integration Test

```bash
cd ~/tt-claw/hermes-setup
./play-with-tools.sh
```

---

## Success Criteria

Hermes is "smarter" than OpenClaw if:
- ✅ Proactively searches documentation when relevant (tech_deep_dive)
- ✅ Generates narrative while grounding in technical reality (game_master_narrate + tech_deep_dive)
- ✅ Uses dice rolls for game mechanics (roll_dice, not arbitrary outcomes)
- ✅ Tracks cross-game state automatically (manage_universe_state)
- ✅ Balances fun (narrative) with utility (technical accuracy)
- ✅ Doesn't overuse tools (knows when to just narrate)

---

## Files

**Skills**: `~/.hermes/skills/adventure/` (5 files), `~/.hermes/skills/tenstorrent/` (1 file)
**Persona**: `~/.hermes/personas/game-master.md` (6.5 KB)
**Launcher**: `~/tt-claw/hermes-setup/play-with-tools.sh`
**Documentation**: `~/.hermes/memories/tt-docs/` (2.9 MB, 160 files)
**State**: `~/.hermes/memories/universe-state.json`
**Game Definition**: `~/tt-claw/adventure-games/games/chip-quest/SOUL.md` (840 lines)

---

## Philosophy Validation

**"Sometimes a tool is just a short prompt"** - Proven!

These skills demonstrate:
- ✅ Tools don't have to execute code (prompt-based tools work)
- ✅ Prompting strategies can be packaged as tools
- ✅ Hermes's tool-first architecture CAN work for narrative games
- ✅ The framework isn't the problem - it's how we use it

**Result**: We worked WITH Hermes's tool-first nature instead of fighting it.
