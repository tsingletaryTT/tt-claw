# TT-CLAW Adventure Game Skills

OpenClaw skill wrappers for adventure game tools. These scripts connect the Python tools to OpenClaw agents.

## Installation

Automatically installed by `setup-game-agents.sh`:
```bash
cd ~/tt-claw/adventure-games/scripts
./setup-game-agents.sh
```

Or manually:
```bash
cd ~/tt-claw/adventure-games/scripts
./install-skills.sh
```

Skills are installed to: `~/.openclaw/skills/`

## Available Skills

### roll-dice
Roll dice using standard notation.

**Usage:**
```bash
~/.openclaw/skills/roll-dice 3d6
~/.openclaw/skills/roll-dice 2d6+3
~/.openclaw/skills/roll-dice 1d20
```

**Output:**
```
3d6: [4, 5, 2] = 11
Total: 11
```

---

### skill-check
GURPS skill check (roll 3d6 vs target skill value).

**Usage:**
```bash
~/.openclaw/skills/skill-check 12
~/.openclaw/skills/skill-check 15
```

**Output:**
```
3d6 vs 12: 8 → Success by 4 → HIT!
```

---

### combat-turn
Resolve a complete combat turn (attack, defense, damage).

**Usage:**
```bash
~/.openclaw/skills/combat-turn <attacker_skill> <defender_dodge> <weapon_damage>
~/.openclaw/skills/combat-turn 12 8 "2d6+2"
```

**Output:**
```
Attack: 3d6 vs 12: 8 → Success by 4 → HIT!
Defense: 3d6 vs 8: 11 → Failure by 3 → FAILED!
Damage: 2d6+2: [3, 5] = 8 + 2 = 10 damage
```

---

### generate-loot
Generate loot by rarity tier.

**Usage:**
```bash
~/.openclaw/skills/generate-loot common
~/.openclaw/skills/generate-loot rare
~/.openclaw/skills/generate-loot legendary
```

**Output:**
```
Loot (rare):
  • Overclocked Tensix Core (+20 processing)
  • Cache Block Fragment (5 EP restore)
  • NoC Routing Map (reveals shortcuts)
```

---

### create-character
Create GURPS character with attributes, skills, and advantages.

**Usage:**
```bash
~/.openclaw/skills/create-character create "Hero Name"
~/.openclaw/skills/create-character create "Netrunner"
```

**Output:**
```
╔══════════════════════════════════════════╗
║              Hero Name                   ║
╠══════════════════════════════════════════╣
║  ATTRIBUTES                              ║
║  ST: 11  DX: 12  IQ: 13  HT: 10          ║
║                                          ║
║  DERIVED STATS                           ║
║  HP: 11  Will: 13  Per: 13  FP: 10      ║
...
```

**Other commands:**
```bash
# Level up (add XP and improve stats)
~/.openclaw/skills/create-character level-up '<character_json>' 150

# Show character sheet
~/.openclaw/skills/create-character show '<character_json>'
```

---

### save-game
Save/load game state to disk.

**Usage:**
```bash
# Save game
~/.openclaw/skills/save-game save <game_name> <slot> '<json_data>' "description"
~/.openclaw/skills/save-game save chip-quest slot1 '{"hp": 80, "location": "DRAM"}' "Before grue fight"

# Load game
~/.openclaw/skills/save-game load <game_name> <slot>
~/.openclaw/skills/save-game load chip-quest slot1

# List saves
~/.openclaw/skills/save-game list <game_name>
~/.openclaw/skills/save-game list chip-quest

# Autosave
~/.openclaw/skills/save-game autosave <game_name> '<json_data>'
```

**Output:**
```
Game saved to slot1 at 2026-03-10T15:30:00
```

Save location: `~/.openclaw/saves/adventure-games/`

---

### inventory
Manage inventory (add, remove, equip items).

**Usage:**
```bash
# Create inventory
~/.openclaw/skills/inventory create [capacity] [weight_limit]
~/.openclaw/skills/inventory create 10 100.0

# Add item
~/.openclaw/skills/inventory add '<inventory_json>' '<item_json>' [quantity]

# Remove item
~/.openclaw/skills/inventory remove '<inventory_json>' "item_name" [quantity]

# Equip item
~/.openclaw/skills/inventory equip '<inventory_json>' "item_name" <slot>
~/.openclaw/skills/inventory equip '<inv>' "Debugger Sword" weapon

# Show inventory
~/.openclaw/skills/inventory show '<inventory_json>'
```

**Output:**
```
✓ Added 1x Debugger Sword

╔════════════════════════════════════════╗
║           INVENTORY                    ║
╠════════════════════════════════════════╣
║  EQUIPPED                              ║
║  Weapon    : Debugger Sword            ║
║  Armor     : (none)                    ║
...
```

---

### npc-memory
Track NPC conversations, trades, promises, and relationships.

**Usage:**
```bash
# Create NPC
~/.openclaw/skills/npc-memory create "NPC Name" [type] [location]
~/.openclaw/skills/npc-memory create "Trader Bob" vendor "Main Floor"

# Record conversation
~/.openclaw/skills/npc-memory conversation '<npc_json>' "topic" "player_text" "npc_text" <turn> [rel_change]

# Record trade
~/.openclaw/skills/npc-memory trade '<npc_json>' "item" <price> <fair> <turn>
~/.openclaw/skills/npc-memory trade '<npc>' "Swag Bag" 50 true 10

# Make promise
~/.openclaw/skills/npc-memory promise '<npc_json>' "promise_text" <turn>

# Keep/break promise
~/.openclaw/skills/npc-memory keep-promise '<npc_json>' <promise_index>
~/.openclaw/skills/npc-memory break-promise '<npc_json>' <promise_index>

# Add note
~/.openclaw/skills/npc-memory note '<npc_json>' "note_text"

# Show NPC
~/.openclaw/skills/npc-memory show '<npc_json>'
```

**Output:**
```
╔════════════════════════════════════════╗
║            Trader Bob                  ║
╠════════════════════════════════════════╣
║  Type: vendor                          ║
║  Location: Main Floor                  ║
║  Relationship: +15/100 (Friendly)      ║
...
```

## How Skills Work

Each skill is a bash wrapper that:
1. Finds the tool script using relative path from skill location
2. Calls the Python tool with arguments
3. Returns output to OpenClaw

**Example:**
```bash
#!/bin/bash
# roll-dice skill
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
python3 "$SCRIPT_DIR/../tools/dice.py" roll "$@"
```

## Using Skills in Games

OpenClaw agents can invoke skills during gameplay. The SOUL files instruct the AI when to use each skill.

**Example from Chip Quest:**
```markdown
When the player enters combat with a Memory Grue:
1. Use skill-check to roll attack
2. Use combat-turn for full resolution
3. Use generate-loot if player wins
```

## Debugging Skills

Test skills directly:
```bash
# Test dice rolling
~/.openclaw/skills/roll-dice 3d6

# Test combat
~/.openclaw/skills/combat-turn 12 8 "2d6+2"

# Test character creation
~/.openclaw/skills/create-character create "Test Hero"
```

Check logs:
```bash
# Python errors appear in stderr
~/.openclaw/skills/roll-dice 3d6 2>&1 | grep -i error
```

## Tool Source Code

Skills call Python tools in:
- `/home/ttuser/tt-claw/adventure-games/tools/dice.py`
- `/home/ttuser/tt-claw/adventure-games/tools/character_gen.py`
- `/home/ttuser/tt-claw/adventure-games/tools/save_game.py`
- `/home/ttuser/tt-claw/adventure-games/tools/inventory.py`
- `/home/ttuser/tt-claw/adventure-games/tools/npc_memory.py`

See `adventure-games/tools/README.md` for tool documentation.

## Troubleshooting

**Skill not found:**
```bash
ls -l ~/.openclaw/skills/
# Should show 8 executable scripts
```

**Permission denied:**
```bash
chmod +x ~/.openclaw/skills/*
```

**Python errors:**
```bash
# Test tool directly
python3 ~/tt-claw/adventure-games/tools/dice.py roll 3d6
```

**Skill output not appearing in game:**
- Check SOUL.md files are configured to use skills
- Verify OpenClaw gateway is running
- Check gateway logs: `~/.openclaw/logs/`
