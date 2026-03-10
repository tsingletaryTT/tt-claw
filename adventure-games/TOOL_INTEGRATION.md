# Tool Integration Guide
## Making Adventure Games Interactive with Executable Tools

## Current State vs. Desired State

### ❌ Current: Declarative Tools (AI Simulation)
The `tools.json` files tell the AI what it CAN do, but it simulates everything:

```json
{
  "name": "roll_combat",
  "description": "Handle turn-based combat with dice rolls",
  "enabled": true
}
```

The AI then writes: *"You roll 3d6... (simulates) ...you got an 11!"*

### ✅ Desired: Executable Tools (Real Computation)
Tools run actual code and return deterministic results:

```bash
$ python3 dice.py combat 12 8 "2d6+2"
Attack: 3d6 vs 12: 7 → Success by 5 → HIT!
Defense: 3d6 vs 8: 11 → Failure by 3 → FAILED!
Damage: 2d6+2: [3, 2] = 5 + 2 = 7
```

The AI uses this **real output** in its response.

## Available Tools

Located in `/home/ttuser/tt-claw/adventure-games/tools/`:

### 1. **dice.py** - Dice Rolling & Combat
```bash
# Roll dice
python3 dice.py roll 3d6        → [4, 5, 2] = 11
python3 dice.py roll 2d6+3      → [3, 5] = 8 + 3 = 11

# GURPS skill check (roll under)
python3 dice.py check 12        → 3d6 vs 12: 8 → Success by 4

# Damage roll
python3 dice.py damage "2d6+2"  → 2d6+2: [5, 3] = 8 + 2 = 10 damage

# Full combat turn
python3 dice.py combat 12 8 "2d6+2"
→ Attack, defense, and damage resolved

# Generate loot
python3 dice.py loot rare       → List of rare items
```

### 2. **character_gen.py** - Character Creation
```bash
# Create character
python3 character_gen.py create "HeroName"
→ Full GURPS character sheet with stats, skills, advantages

# Level up
python3 character_gen.py level-up '<json>' 150
→ Add XP, grant attribute/skill increases

# Display sheet
python3 character_gen.py show '<json>'
→ Pretty-print character sheet with box drawing
```

### 3. **ascii_art.py** (TO CREATE)
```bash
# Generate dungeon map
python3 ascii_art.py dungeon 20x20 --player-pos 10,10 --enemies 3

# Generate chip diagram
python3 ascii_art.py chip tensix-core

# Generate conference floor
python3 ascii_art.py conference --booths 10
```

## Integration Options

### Option 1: MCP (Model Context Protocol) Server 🏆 BEST
OpenClaw supports MCP for tool integration. This is the **official** way.

**How it works:**
1. Create MCP server that exposes tools
2. OpenClaw connects to MCP server
3. AI can call tools and get real results

**Benefits:**
- ✅ Official OpenClaw integration
- ✅ Tools are discoverable by AI
- ✅ Proper request/response flow
- ✅ Can run on separate process/machine

**Implementation:**
```python
# mcp_server.py
from mcp import MCPServer, Tool

server = MCPServer("adventure-tools")

@server.tool("roll_dice")
def roll_dice(notation: str):
    """Roll dice using standard notation (e.g., '3d6', '2d6+3')"""
    # Call dice.py
    import subprocess
    result = subprocess.run(
        ["python3", "dice.py", "roll", notation],
        capture_output=True, text=True
    )
    return result.stdout

@server.tool("combat_turn")
def combat_turn(attacker_skill: int, defender_dodge: int, weapon: str):
    """Resolve a complete combat turn"""
    import subprocess
    result = subprocess.run(
        ["python3", "dice.py", "combat", str(attacker_skill), str(defender_dodge), weapon],
        capture_output=True, text=True
    )
    return result.stdout

server.run()
```

**OpenClaw config:**
```json
{
  "mcp": {
    "servers": {
      "adventure-tools": {
        "command": "python3",
        "args": ["/home/ttuser/tt-claw/adventure-games/tools/mcp_server.py"]
      }
    }
  }
}
```

### Option 2: OpenClaw Skills (Simpler, Limited)
Create skills that wrap the tools.

**How it works:**
1. Create skill files in OpenClaw
2. Skills call tool scripts
3. Return results to agent

**Implementation:**
```bash
# In /home/ttclaw/.openclaw/skills/

# roll-dice.sh
#!/bin/bash
python3 /home/ttuser/tt-claw/adventure-games/tools/dice.py roll "$@"

# create-character.sh
#!/bin/bash
python3 /home/ttuser/tt-claw/adventure-games/tools/character_gen.py create "$@"
```

**Benefits:**
- ✅ Simple to implement
- ✅ Works immediately
- ✅ No MCP server needed

**Limitations:**
- ❌ Not as discoverable
- ❌ Requires manual skill invocation
- ❌ Less flexible

### Option 3: Direct Tool Calls in SOUL (Current State)
The SOUL prompts tell the AI to call tools, but tools are simulated.

**To make this work with real tools:**
Update SOUL files to instruct AI to request tool execution:

```markdown
When you need to roll dice, output:
TOOL_CALL: roll_dice(3d6)

The system will execute the tool and provide results.
```

**Limitation:** Requires custom gateway logic to intercept TOOL_CALL requests.

## Recommended Implementation Path

### Phase 1: Test Tools Locally ✅ DONE
```bash
cd /home/ttuser/tt-claw/adventure-games/tools
python3 dice.py roll 3d6
python3 character_gen.py create "Hero"
```

### Phase 2: Create MCP Server (RECOMMENDED)
```bash
# Install MCP SDK
pip install mcp

# Create server (see template above)
nano /home/ttuser/tt-claw/adventure-games/tools/mcp_server.py

# Test server
python3 mcp_server.py

# Configure OpenClaw to use it
sudo -u ttclaw nano /home/ttclaw/.openclaw/openclaw.json
# Add MCP server config
```

### Phase 3: Update SOUL Files
Tell agents about real tools:

```markdown
## Tools Available (REAL EXECUTION)

You have access to these tools via MCP:

- **roll_dice(notation)** - Roll dice (e.g., "3d6", "2d6+3")
  Returns: Detailed roll results with individual die values

- **skill_check(skill_value, difficulty)** - GURPS skill check
  Returns: Success/failure with margin, critical results

- **combat_turn(atk_skill, def_dodge, weapon)** - Full combat
  Returns: Complete combat resolution with rolls

- **generate_character(name)** - Create character
  Returns: Full character sheet JSON

- **generate_loot(rarity)** - Generate loot
  Returns: List of items based on rarity

Use tools like this:
Player: "I attack the grue!"
You: [Call combat_turn(12, 8, "2d6+2")]
System returns: "Attack: Success by 5 → HIT! Damage: 10"
You: "Your pointer strikes true! The grue takes 10 damage and roars in pain!"
```

### Phase 4: Test Integration
```bash
# Start MCP server
python3 adventure-games/tools/mcp_server.py &

# Start OpenClaw gateway
sudo -u ttclaw bash -c 'cd ~/openclaw && ./openclaw.sh gateway run'

# Start game
cd adventure-games/scripts && ./adventure-menu.sh

# In game, trigger tool usage
# AI should call real tools and get real results
```

## Non-Network Tools for OpenClaw

OpenClaw supports these types of tools **without network access**:

### 1. **Filesystem Tools** ✅
- Read/write files (character sheets, save games)
- Generate content (ASCII art, maps)

### 2. **Computation Tools** ✅
- Math (dice rolls, stat calculations)
- Random generation (loot, encounters)
- Character management

### 3. **Text Processing** ✅
- Format output (tables, character sheets)
- Parse player input
- State management

### 4. **Shell Commands** ✅
- Execute local scripts
- Process data
- File management

### Tools That DON'T Require Network:
- ✅ dice.py (pure computation)
- ✅ character_gen.py (pure computation)
- ✅ ascii_art.py (text generation)
- ✅ Game state persistence (file I/O)
- ✅ Save/load systems (JSON files)

## Example: Full Combat with Real Tools

**Before (AI Simulation):**
```
Player: "I attack the grue!"

AI simulates:
"You swing your pointer! Rolling 3d6 vs skill 12... (thinks) ...
I'll say you rolled an 8, that's a success! The grue tries to dodge,
rolling 3d6 vs 8... (thinks) ...I'll say 11, failure!
Damage: 2d6+2... (thinks) ...let's say 10 damage!"
```

**After (Real Tools):**
```
Player: "I attack the grue!"

AI requests: combat_turn(12, 8, "2d6+2")

Tool returns:
Attack: 3d6 vs 12: 8 → Success by 4 → HIT!
Defense: 3d6 vs 8: 11 → Failure by 3 → FAILED!
Damage: 2d6+2: [5, 3] = 8 + 2 = 10 damage

AI responds with real data:
"Your pointer strikes true! (Attack roll: 8 vs 12, success by 4)
The grue attempts to dodge but fails! (Defense: 11 vs 8)
Your weapon deals 10 damage! [5, 3] on the dice plus 2 modifier.
The grue roars in pain, its HP dropping to 30/40!"
```

## Next Steps

1. **Create MCP server** - Wrap dice.py and character_gen.py
2. **Configure OpenClaw** - Add MCP server to openclaw.json
3. **Test integration** - Verify tools are callable from agents
4. **Update SOUL files** - Document tool usage for AI
5. **Create ascii_art.py** - Visual generation tool
6. **Add save/load tools** - Character persistence

## Resources

- **MCP Documentation**: https://modelcontextprotocol.io/
- **OpenClaw MCP Guide**: https://docs.openclaw.ai/integrations/mcp
- **Tool examples**: `/home/ttuser/tt-claw/adventure-games/tools/`

---

**Status**: Tools created ✅, Integration needed ⏳
