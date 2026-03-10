# TT-CLAW Adventure Games - Installation Guide

**For:** Fresh checkout as `ttclaw` user
**Time:** ~15 minutes (including OpenClaw installation)

---

## Quick Setup (All-in-One)

```bash
# 1. Clone repository (as ttclaw user)
cd ~
git clone https://github.com/tsingletaryTT/tt-claw.git
cd tt-claw

# 2. Install OpenClaw (if not already installed)
cd adventure-games/scripts
./install-openclaw.sh

# 3. Setup game agents and skills
./setup-game-agents.sh

# 4. Launch adventure menu
./adventure-menu.sh
```

---

## Detailed Instructions

### Prerequisites Check

Before starting, verify you have:

**Required:**
- ✅ **Node.js 18+** - For OpenClaw
- ✅ **Python 3.8+** - For adventure game tools
- ✅ **Git** - For cloning repository

**Optional but recommended:**
- ✅ **vLLM server** - For AI inference (can install later)
- ✅ **vLLM proxy** - For OpenClaw compatibility (can install later)

Check Node.js:
```bash
node --version  # Should be v18.0.0 or higher
npm --version   # Should be 8.0.0 or higher
```

If Node.js not installed:
```bash
curl -fsSL https://deb.nodesource.com/setup_18.x | sudo -E bash -
sudo apt-get install -y nodejs
```

---

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

ls -l adventure-games/skills/
# Should show: roll-dice skill-check combat-turn generate-loot create-character save-game inventory npc-memory
```

---

### Step 2: Install OpenClaw

**If OpenClaw is already installed**, skip to Step 3.

Run the installation script:
```bash
cd ~/tt-claw/adventure-games/scripts
./install-openclaw.sh
```

**What this does:**
- Downloads OpenClaw v2026.3.2
- Installs to `~/openclaw/`
- Runs `npm install` to get dependencies
- Creates wrapper script `~/openclaw/openclaw.sh`

**Expected output:**
```
✓ Node.js v18.x.x found
✓ npm 8.x.x found

Downloading OpenClaw v2026.3.2...
Installing dependencies (this may take a few minutes)...

✓ OpenClaw v2026.3.2 installed successfully!

Installation directory: /home/ttclaw/openclaw
```

**Time:** ~5-10 minutes (npm install takes time)

**Verification:**
```bash
ls -l ~/openclaw/openclaw.sh
# Should exist and be executable

~/openclaw/openclaw.sh --version
# Should show: OpenClaw v2026.3.2
```

---

### Step 3: Setup Game Agents and Skills

This single script does **both** agent setup and skill installation:

```bash
cd ~/tt-claw/adventure-games/scripts
./setup-game-agents.sh
```

**What this does:**

1. **Installs skills** to `~/.openclaw/skills/`:
   - roll-dice, skill-check, combat-turn, generate-loot
   - create-character, save-game, inventory, npc-memory

2. **Creates game agents** in `~/.openclaw/agents/`:
   - chip-quest (818 lines)
   - terminal-dungeon (1323 lines)
   - conference-chaos (1288 lines)

**Expected output:**
```
🎮 Setting up OpenClaw Adventure Game Agents...

📦 Installing skills...
  Installing: roll-dice
  Installing: skill-check
  Installing: combat-turn
  Installing: generate-loot
  Installing: create-character
  Installing: save-game
  Installing: inventory
  Installing: npc-memory

✓ Skills installed to: /home/ttclaw/.openclaw/skills

📦 Creating chip-quest agent...
  ✓ Copied SOUL.md (818 lines)
  ✓ Copied tools.json
  ✓ chip-quest agent created

📦 Creating terminal-dungeon agent...
  ✓ Copied SOUL.md (1323 lines)
  ✓ Copied tools.json
  ✓ terminal-dungeon agent created

📦 Creating conference-chaos agent...
  ✓ Copied SOUL.md (1288 lines)
  ✓ Copied tools.json
  ✓ conference-chaos agent created

✅ All game agents created!
```

**Verification:**
```bash
# Check skills installed
ls -1 ~/.openclaw/skills/
# Should show 8 scripts

# Test a skill
~/.openclaw/skills/roll-dice 3d6
# Should output: 3d6: [X, Y, Z] = Total

# Check agents created
ls -1 ~/.openclaw/agents/
# Should show: chip-quest/ terminal-dungeon/ conference-chaos/

# Check SOUL files
wc -l ~/.openclaw/agents/*/agent/SOUL.md
# Should show line counts: 818, 1323, 1288
```

---

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

---

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

## Optional: vLLM Server Setup

**If vLLM is not already running**, you'll need to set it up for AI inference.

### Option 1: Use Existing vLLM Installation

If vLLM is already installed on the system:
```bash
# Check if vLLM server is running
curl http://localhost:8000/v1/models

# If not running, start it (example)
python3 -m vllm.entrypoints.openai.api_server \
  --model meta-llama/Llama-3.1-8B-Instruct \
  --port 8000
```

### Option 2: Install vLLM (if needed)

See main OpenClaw documentation for vLLM installation:
- `~/tt-claw/OPENCLAW_FINAL_INSTRUCTIONS.md`
- `~/tt-claw/CLAUDE.md`

### Option 3: Use Different AI Provider

OpenClaw supports multiple providers. Edit `~/.openclaw/openclaw.json`:
```json
{
  "models": {
    "providers": {
      "openai": {
        "apiKey": "sk-your-key",
        "models": [...]
      }
    }
  }
}
```

---

## Troubleshooting

### Problem: "Command not found" when running scripts

**Solution:** Make scripts executable:
```bash
cd ~/tt-claw/adventure-games/scripts
chmod +x *.sh
```

### Problem: Skills not working

**Solution 1:** Reinstall skills:
```bash
cd ~/tt-claw/adventure-games/scripts
./install-skills.sh
```

**Solution 2:** Verify permissions:
```bash
ls -l ~/.openclaw/skills/
chmod +x ~/.openclaw/skills/*
```

**Solution 3:** Test individually:
```bash
~/.openclaw/skills/roll-dice 3d6
```

### Problem: OpenClaw gateway won't start

**Causes:**
1. Port 18789 already in use
2. Previous gateway still running
3. OpenClaw not installed correctly

**Solution:**
```bash
# Kill existing gateway
pkill -f openclaw-gateway

# Check port is free
netstat -tlnp | grep 18789

# Verify OpenClaw installation
~/openclaw/openclaw.sh --version

# Try again
cd ~/openclaw && ./openclaw.sh gateway run
```

### Problem: "No model found" or authentication errors

**Solution:** Configure OpenClaw for vLLM:

1. Check vLLM is running:
```bash
curl http://localhost:8000/v1/models
```

2. Update OpenClaw config:
```bash
nano ~/.openclaw/openclaw.json
```

Add vLLM provider:
```json
{
  "models": {
    "providers": {
      "vllm": {
        "baseUrl": "http://127.0.0.1:8000/v1",
        "api": "openai-completions",
        "apiKey": "sk-no-auth",
        "models": [
          {
            "id": "meta-llama/Llama-3.1-8B-Instruct",
            "name": "Llama 3.1 8B Instruct",
            "contextWindow": 65536,
            "maxTokens": 8192
          }
        ]
      }
    }
  },
  "agents": {
    "defaults": {
      "model": {
        "primary": "vllm/meta-llama/Llama-3.1-8B-Instruct"
      }
    }
  }
}
```

See `OPENCLAW_FINAL_INSTRUCTIONS.md` for full configuration guide.

### Problem: Node.js version too old

**Solution:** Upgrade Node.js:
```bash
# Remove old Node.js
sudo apt-get remove nodejs

# Install Node.js 18 LTS
curl -fsSL https://deb.nodesource.com/setup_18.x | sudo -E bash -
sudo apt-get install -y nodejs

# Verify
node --version  # Should be v18+
```

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

### Problem: Python tools don't work

**Solution:** Check Python version:
```bash
python3 --version  # Should be 3.8+

# Test a tool directly
python3 ~/tt-claw/adventure-games/tools/dice.py roll 3d6
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

## Advanced: Manual Installation

If automated scripts don't work, you can install manually:

### Manual OpenClaw Installation

```bash
cd ~
curl -L "https://github.com/openclaw/openclaw/archive/refs/tags/v2026.3.2.tar.gz" -o openclaw.tar.gz
mkdir openclaw
cd openclaw
tar -xzf ../openclaw.tar.gz --strip-components=1
npm install
```

### Manual Skills Installation

```bash
mkdir -p ~/.openclaw/skills
cp ~/tt-claw/adventure-games/skills/* ~/.openclaw/skills/
chmod +x ~/.openclaw/skills/*
```

### Manual Agent Setup

```bash
# For each game:
mkdir -p ~/.openclaw/agents/chip-quest/agent
cp ~/tt-claw/adventure-games/games/chip-quest/SOUL.md \
   ~/.openclaw/agents/chip-quest/agent/
cp ~/tt-claw/adventure-games/games/chip-quest/tools.json \
   ~/.openclaw/agents/chip-quest/agent/

# Repeat for terminal-dungeon and conference-chaos
```

---

## Documentation

- **`README.md`** - Project overview
- **`QUICK_START.md`** - 2-minute quick start guide
- **`docs/TUI_OPTIMIZATION.md`** - Terminal setup for best experience
- **`docs/ENHANCING_TUI_OUTPUT.md`** - How games generate vibrant output
- **`adventure-games/TOOL_INTEGRATION.md`** - Tool integration details
- **`TOOLS_STATUS.md`** - Tool implementation status
- **`OPENCLAW_FINAL_INSTRUCTIONS.md`** - OpenClaw + vLLM setup
- **`CLAUDE.md`** - Complete project journey and technical details

---

## Getting Help

**Game stuck?** Type `help` or `?` in the game for hints.

**Technical issues?** Check:
1. Is OpenClaw installed? `~/openclaw/openclaw.sh --version`
2. Are skills installed? `ls ~/.openclaw/skills/`
3. Are agents created? `ls ~/.openclaw/agents/`
4. Is vLLM running? `curl http://localhost:8000/v1/models`
5. Check logs: `~/.openclaw/logs/`

**Want to contribute?** See the GitHub repository:
https://github.com/tsingletaryTT/tt-claw

---

## What's Next?

After playing the games:
- Try different strategies and choices (multiple solutions to puzzles!)
- Experiment with different character classes (Terminal Dungeon)
- Corner different markets (Conference Chaos)
- Look for easter eggs (all games have hidden content)
- Save your progress and resume later
- Explore the tools: `~/.openclaw/skills/`

**Have fun exploring Tenstorrent hardware through adventure games!**
