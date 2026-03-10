# TT-CLAW Adventure Games - Installation Guide

**For:** Fresh checkout as `ttclaw` user
**Prerequisites:** vLLM server running on localhost (port 8000/8001)
**Time:** ~5 minutes

---

## Quick Setup

```bash
# 1. Clone repository (as ttclaw user)
cd ~
git clone https://github.com/tsingletaryTT/tt-claw.git
cd tt-claw

# 2. Setup OpenClaw agents
cd adventure-games/scripts
./setup-game-agents.sh

# 3. Launch adventure menu
./adventure-menu.sh
```

---

## Detailed Instructions

### Step 1: Clone Repository

```bash
# Switch to ttclaw user (if not already)
sudo -u ttclaw bash

# Clone the repository
cd /home/ttclaw
git clone https://github.com/tsingletaryTT/tt-claw.git
cd tt-claw
```

**Verification:**
```bash
ls -l adventure-games/games/
# Should show: chip-quest/ conference-chaos/ terminal-dungeon/

ls -l adventure-games/tools/
# Should show: dice.py character_gen.py save_game.py inventory.py npc_memory.py
```

### Step 2: Setup OpenClaw Agents

The `setup-game-agents.sh` script will:
- Create OpenClaw agents from SOUL files
- Set up tool integration
- Configure game settings

```bash
cd adventure-games/scripts
./setup-game-agents.sh
```

**What this creates:**
```
~/.openclaw/agents/
├── chip-quest/
│   ├── SOUL.md
│   └── agent/
├── terminal-dungeon/
│   ├── SOUL.md
│   └── agent/
└── conference-chaos/
    ├── SOUL.md
    └── agent/
```

**Expected output:**
```
Setting up OpenClaw adventure game agents...
✓ Created chip-quest agent
✓ Created terminal-dungeon agent
✓ Created conference-chaos agent
✓ All agents ready!
```

### Step 3: Verify Skills Are Available

The skill wrappers should already be installed in `/home/ttclaw/.openclaw/skills/`. Verify:

```bash
ls -l ~/.openclaw/skills/
```

**Expected files:**
- `roll-dice` - Dice rolling (3d6, 2d6+3, etc.)
- `skill-check` - GURPS skill checks
- `combat-turn` - Full combat resolution
- `generate-loot` - Loot generation by rarity
- `create-character` - GURPS character creation
- `save-game` - Save/load game state
- `inventory` - Item management
- `npc-memory` - NPC relationship tracking

**Test a skill:**
```bash
~/.openclaw/skills/roll-dice 3d6
# Should output: 3d6: [X, Y, Z] = Total
```

If skills are missing, recreate them:
```bash
cd ~/tt-claw/adventure-games/scripts
sudo bash  # Temporarily escalate to create in /home/ttclaw/
# Then manually copy skill scripts or run individual skill setup commands
```

### Step 4: Launch Adventure Menu

```bash
cd ~/tt-claw/adventure-games/scripts
./adventure-menu.sh
```

**You'll see:**
```
-=| TT-CLAW |=-
Tenstorrent Adventure Games on OpenClaw

Choose your adventure:
1. Chip Quest (Educational Zork)
2. Terminal Dungeon (NetHack Roguelike)
3. Conference Chaos (Trade Wars Trading)
4. Quit

Enter choice (1-4):
```

### Step 5: Start Playing!

**Choose a game** (enter 1, 2, or 3)

The game will:
1. Start OpenClaw gateway (WebSocket on port 18789)
2. Launch TUI (Terminal User Interface)
3. Begin the adventure!

**Gameplay:**
- Read the story and status
- Type the **number** of your choice (e.g., `1`, `2`, `3`)
- Press Enter
- The AI will process your action and respond

**Example:**
```
What do you do?
1. Explore the Tensix cores
2. Check the NoC status
3. Look for memory grues
4. Open inventory

You: 2 [Enter]

You check the NoC status...
[AI generates response with vibrant ASCII art and storytelling]
```

---

## Prerequisites (Already Configured)

These should already be set up if you're following the main installation:

### ✅ vLLM Server Running
```bash
# Check vLLM is available:
curl http://localhost:8000/v1/models

# Should return model info (Llama-3.1-8B-Instruct or similar)
```

### ✅ vLLM Proxy Running
```bash
# Check proxy is available:
curl http://localhost:8001/v1/models

# Should return same model info
```

### ✅ OpenClaw Installed
```bash
ls -l ~/openclaw/openclaw.sh
# Should exist and be executable
```

If any of these are missing, see the main **`OPENCLAW_FINAL_INSTRUCTIONS.md`** in the root directory.

---

## Troubleshooting

### Problem: "Command not found" when running scripts

**Solution:** Make scripts executable:
```bash
cd ~/tt-claw/adventure-games/scripts
chmod +x setup-game-agents.sh adventure-menu.sh
```

### Problem: Skills not working

**Solution:** Verify skill wrappers exist and are executable:
```bash
ls -l ~/.openclaw/skills/
chmod +x ~/.openclaw/skills/*
```

Test individually:
```bash
~/.openclaw/skills/roll-dice 3d6
```

### Problem: OpenClaw gateway won't start

**Causes:**
1. Port 18789 already in use
2. Previous gateway still running

**Solution:**
```bash
# Kill existing gateway
pkill -f openclaw-gateway

# Check port is free
netstat -tlnp | grep 18789

# Try again
cd ~/openclaw && ./openclaw.sh gateway run
```

### Problem: "No model found" or authentication errors

**Solution:** Verify OpenClaw configuration:
```bash
cat ~/.openclaw/openclaw.json | grep -A 10 "vllm"
```

Should show:
```json
"vllm": {
  "baseUrl": "http://127.0.0.1:8001/v1",
  "apiKey": "sk-no-auth",
  "models": [
    {
      "id": "meta-llama/Llama-3.1-8B-Instruct",
      ...
    }
  ]
}
```

If wrong, see **`OPENCLAW_FINAL_INSTRUCTIONS.md`** for configuration steps.

### Problem: Games feel slow or unresponsive

**Solution:** Optimize terminal settings (see `docs/TUI_OPTIMIZATION.md`):
- Use a modern terminal (Alacritty, Kitty, iTerm2)
- Use a monospace font (Fira Code, JetBrains Mono)
- Increase font size to 14-16pt
- Use a dark color scheme

### Problem: ASCII art looks broken

**Solution:** Ensure terminal supports Unicode:
```bash
echo $LANG
# Should be: en_US.UTF-8 or similar

# If not, set it:
export LANG=en_US.UTF-8
```

---

## Game Overview

### Chip Quest 🗺️
**Genre:** Educational Zork-style Adventure
**Length:** 30-40 minutes
**Features:**
- Explore TT chip architecture (Tensix, NoC, DRAM, caches)
- Solve logic puzzles (gates, parallel processing, routing)
- Fight Memory Grues (3 types)
- Learn chip design concepts while adventuring
- 4 endings, 6 easter eggs

### Terminal Dungeon ⚔️
**Genre:** NetHack-style Roguelike
**Length:** 30-45 minutes
**Features:**
- Full GURPS character system (ST, DX, IQ, HT + 10 skills)
- 5 character classes (Sysadmin, Netrunner, Cyber-Warrior, TT-Mage, Scout)
- Turn-based tactical combat with action points
- 6 TT-Grues with unique abilities
- Equipment system with legendary TT hardware
- Permadeath mode with meta-progression
- Procedurally generated dungeons

### Conference Chaos 💼
**Genre:** Trade Wars 2002 Trading Sim + Hitchhiker's Guide
**Length:** 30-45 minutes
**Features:**
- Trading system (8 goods, dynamic pricing, supply/demand)
- NPC traders with perfect memory
- Reputation progression (Nobody → Legend)
- Vogon Poetry panels (bureaucracy puzzles)
- Towel mechanic (most important item, 7 uses)
- 5 distinct endings (Mogul, Job, Set, Conspiracy, Survive)

---

## Advanced: Manual Agent Setup

If `setup-game-agents.sh` doesn't work, create agents manually:

```bash
# For each game (chip-quest, terminal-dungeon, conference-chaos):

# 1. Create agent directory
mkdir -p ~/.openclaw/agents/<GAME_NAME>

# 2. Copy SOUL file
cp ~/tt-claw/adventure-games/games/<GAME_NAME>/SOUL.md \
   ~/.openclaw/agents/<GAME_NAME>/

# 3. Create agent config
mkdir -p ~/.openclaw/agents/<GAME_NAME>/agent
cat > ~/.openclaw/agents/<GAME_NAME>/agent/agent.json << 'EOF'
{
  "name": "<GAME_NAME>",
  "description": "TT-CLAW Adventure Game",
  "soul_path": "../SOUL.md",
  "model": {
    "provider": "vllm",
    "model": "meta-llama/Llama-3.1-8B-Instruct"
  }
}
EOF
```

Replace `<GAME_NAME>` with: `chip-quest`, `terminal-dungeon`, or `conference-chaos`.

---

## Documentation

- **`README.md`** - Project overview
- **`QUICK_START.md`** - 2-minute quick start guide
- **`docs/TUI_OPTIMIZATION.md`** - Terminal setup for best experience
- **`docs/ENHANCING_TUI_OUTPUT.md`** - How games generate vibrant output
- **`adventure-games/TOOL_INTEGRATION.md`** - Tool integration details
- **`TOOLS_STATUS.md`** - Tool implementation status

---

## Getting Help

**Game stuck?** Type `help` or `?` in the game for hints.

**Technical issues?** Check:
1. Is vLLM running? `curl http://localhost:8000/v1/models`
2. Is proxy running? `curl http://localhost:8001/v1/models`
3. Is gateway running? `netstat -tlnp | grep 18789`
4. Check logs: `~/.openclaw/logs/`

**Want to contribute?** See the GitHub repository: https://github.com/tsingletaryTT/tt-claw

---

## What's Next?

After playing the games:
- Try different strategies and choices (multiple solutions to puzzles!)
- Experiment with different character classes (Terminal Dungeon)
- Corner different markets (Conference Chaos)
- Look for easter eggs (all games have hidden content)
- Save your progress and resume later

**Have fun exploring Tenstorrent hardware through adventure games!**
