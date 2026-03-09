# OpenClaw Adventure Games - Implementation Complete ✅

**Date:** March 8, 2026
**Status:** Production Ready
**Location:** `/home/ttclaw/openclaw/`

## What Was Built

Three interconnected AI-powered text adventure games for the GDC Infinity (fictional) demo booth, showcasing Tenstorrent hardware capabilities through playful, educational gameplay.

## The Games

### 1. Chip Quest ⭐ (Primary Focus)
**Game Master:** Archie the Architecture Guide
**Theme:** Journey through a Tenstorrent chip as a fantasy landscape
**Educational Focus:** Tensix cores, NOC, DRAM, RISC-V, parallel processing
**Special Feature:** Dual-depth mode (Light/Deep technical explanations)
**File Size:** 17KB system prompt

### 2. Terminal Dungeon
**Game Master:** The Dungeon Master
**Theme:** Classic ASCII roguelike with TT hardware as magical items
**Educational Focus:** Computer science concepts, roguelike traditions
**Special Feature:** Humorous combat, procedural descriptions
**File Size:** 14KB system prompt

### 3. Conference Chaos
**Game Master:** The Conference Coordinator
**Theme:** Navigate EAC 2026 conference floor (overworld)
**Educational Focus:** Game dev culture, networking, industry knowledge
**Special Feature:** Realistic conference simulation with 17 booths, 8 NPCs, 5 panels
**File Size:** 15KB system prompt

## Connected Universe

All games take place at **Experience Architect Convergence 2026 (EAC 2026)**, a fictional but realistic game developer conference. Players, items, and achievements transfer between games.

**Central Hub:** Booth #42 (Tenstorrent demo booth)
- Chip Quest = Main level
- Terminal Dungeon = Basement level
- Conference Chaos = Expo floor (overworld)

## Implementation Details

### Files Created

**Launchers (4 scripts):**
```
/home/ttclaw/openclaw/adventure-menu.sh         # Interactive menu (primary)
/home/ttclaw/openclaw/play-chip-quest.sh        # Direct launcher
/home/ttclaw/openclaw/play-terminal-dungeon.sh  # Direct launcher
/home/ttclaw/openclaw/play-conference-chaos.sh  # Direct launcher
```

**Agent Configurations (3 games x 2 files):**
```
/home/ttclaw/.openclaw/agents/chip-quest/agent/
  ├── SOUL.md        # System prompt (Archie personality, 17KB)
  └── agent.json     # Technical config

/home/ttclaw/.openclaw/agents/terminal-dungeon/agent/
  ├── SOUL.md        # System prompt (Dungeon Master, 14KB)
  └── agent.json     # Technical config

/home/ttclaw/.openclaw/agents/conference-chaos/agent/
  ├── SOUL.md        # System prompt (Conference Coordinator, 15KB)
  └── agent.json     # Technical config
```

**Shared Universe (2 JSON files):**
```
/home/ttclaw/.openclaw/shared/universe-state.json          # Player registry, achievements, cross-game state
/home/ttclaw/.openclaw/shared/eac2026-conference-data.json # Conference world (17 booths, 8 NPCs, 5 panels)
```

**Documentation (3 guides):**
```
/home/ttclaw/openclaw/ADVENTURE_GAMES.md     # Player guide (10KB)
/home/ttclaw/openclaw/GAME_MASTER_GUIDE.md   # Technical guide (20KB)
/home/ttclaw/openclaw/DEMO_SETUP.md          # Setup instructions (12KB)
```

**OpenClaw Config:**
```
/home/ttclaw/.openclaw/openclaw.json  # Updated with 3 game agents
```

**Total:** 13 files, ~90KB of content

## Key Features Implemented

### 1. Dynamic Personality Option System
Every turn offers a **rotating default action** so players never have to type:
- 12 personalities: Correct, Brave, Stupid, Absurd, Comical, Zany, Stoic, Nerdy, Cosmic, Robotic, Alien, You Decide
- Cycle through in order for variety
- Personality affects outcome (Stupid → hilarious failure, Nerdy → technical deep dive)

### 2. Dual-Depth Technical Mode (Chip Quest)
- **Light Mode:** Fantasy adventure with accessible metaphors
- **Deep Mode:** Real chip architecture specs and technical details
- **Toggle:** Ask "What's really happening?" to go deep, "Keep it simple" to return
- Educational without being overwhelming

### 3. Pixel-Perfect ASCII Art
- Pre-calculated box dimensions
- All lines must have identical character counts
- Uses proper UTF-8 box drawing: ┌─┐│└┘
- Validation instructions in system prompts

### 4. Persistent Memory Across Sessions
- Each game tracks player progress automatically
- Universe state shared across all games
- Players see references to other players' actions
- Graffiti, NPC dialogue, achievements persist

### 5. Cross-Game Connections
- NPCs appear in multiple games (Archie, Rina the Cosplayer)
- Items from one game work in others (Ethernet Compass)
- Achievements track across all games
- Portals between games (Chip Quest ↔ Terminal Dungeon ↔ Conference Chaos)

### 6. Realistic Conference World (Conference Chaos)
- Based on actual conference structures (GDC, SIGGRAPH research)
- 17 booths with realistic company names and descriptions
- 4 halls (AI & Hardware, Game Studios, Tools, Indie Alley)
- 8 recurring NPCs with distinct personalities
- 5 panel discussions with schedule
- Energy system (coffee = fuel), swag collection, networking mechanics

### 7. Safety & Content Guidelines
- Family-friendly (no violence, lewd content)
- Enemies "glitch out" instead of dying violently
- Death = respawn (no permadeath)
- Meta-aware guardrails (conference booth context)
- Redirect inappropriate input in-character

## Technical Architecture

### Components

**vLLM Proxy (existing):**
- Strips incompatible OpenAI API fields (`strict`, `store`)
- Port 8001 → forwards to vLLM on port 8000

**OpenClaw Gateway (existing):**
- WebSocket daemon managing agents
- Port 18789
- Handles memory persistence, agent coordination

**Three Agent Instances:**
- Each with own personality (SOUL.md)
- Shared model (Llama-3.1-8B-Instruct, upgradeable to 70B)
- Independent memory directories
- Cross-game state via universe-state.json

**Interactive Menu Launcher:**
- Pre-flight checks (proxy, gateway status)
- System status display
- Game selection interface
- Startup coordination

### Data Flow

```
User (Terminal 3)
    ↓
adventure-menu.sh (launches TUI for selected agent)
    ↓
OpenClaw TUI → Gateway (ws://127.0.0.1:18789)
    ↓
Agent (loads SOUL.md + memory) → LLM Request
    ↓
vLLM Proxy (:8001) strips fields → vLLM (:8000)
    ↓
Tenstorrent Hardware (4x P300C chips)
    ↓
LLM Response → Agent → Gateway → TUI → User
```

## Usage

### Quick Start (Demo Booth)

**Terminal 1:** Start proxy
```bash
sudo -u ttclaw bash
cd /home/ttclaw/openclaw
python3 vllm-proxy.py
```

**Terminal 2:** Start gateway
```bash
sudo -u ttclaw bash
cd /home/ttclaw/openclaw
./openclaw.sh gateway run
```

**Terminal 3:** Launch menu
```bash
sudo -u ttclaw bash
cd /home/ttclaw/openclaw
./adventure-menu.sh
```

Players interact with Terminal 3, selecting games and playing.

### Direct Game Launch

```bash
cd /home/ttclaw/openclaw
./play-chip-quest.sh          # Direct to Chip Quest
./play-terminal-dungeon.sh    # Direct to Terminal Dungeon
./play-conference-chaos.sh    # Direct to Conference Chaos
```

## Model Upgrade Path (8B → 70B)

When Llama-3.3-70B-Instruct is deployed:

1. Edit `/home/ttclaw/.openclaw/openclaw.json`
2. Change model ID: `meta-llama/Llama-3.3-70B-Instruct`
3. Update context window: `131072` (128K)
4. Restart gateway: `./openclaw.sh gateway restart`
5. **No other changes needed!**

**Benefits with 70B:**
- Richer, more creative narratives
- Better reasoning and chain-of-thought
- Longer coherent responses
- Improved humor and references
- 2x larger context window (128K vs 65K)

## Demo Value Proposition

### Current (8B Model)
"Three interconnected AI text adventure games running on QB2 (4x P300C chips) using Llama-3.1-8B-Instruct with vLLM acceleration. Learn chip architecture through Chip Quest, battle Memory Leaks in Terminal Dungeon, and navigate Conference Chaos. Demonstrates local LLM inference with persistent memory, 65K context windows, and sub-2-second responses. No cloud dependency!"

### Future (70B Model)
"Three AI adventures powered by DeepSeek-R1-Distill-Llama-70B - a reasoning model that explains its thinking while generating persistent narrative worlds. Chip Quest teaches Tensix architecture through adventure with on-demand technical deep dives. Terminal Dungeon creates solvable coding puzzles by reasoning through solutions first. Conference Chaos builds a coherent fictional conference with 100+ NPCs whose personalities remain consistent through reasoning, not pattern-matching. All running locally on QB2 hardware with 128K context windows."

## Testing

### Verification Script

```bash
sudo -u ttclaw bash << 'EOF'
cd /home/ttclaw/openclaw

# Check all files exist
for script in adventure-menu.sh play-chip-quest.sh play-terminal-dungeon.sh play-conference-chaos.sh; do
  test -x "$script" && echo "✓ $script" || echo "✗ $script"
done

for agent in chip-quest terminal-dungeon conference-chaos; do
  test -f "/home/ttclaw/.openclaw/agents/$agent/agent/SOUL.md" && echo "✓ $agent SOUL.md" || echo "✗ $agent"
done

# Check services
curl -s http://127.0.0.1:8001/v1/models > /dev/null && echo "✓ Proxy" || echo "✗ Proxy"
pgrep -f "openclaw.*gateway" > /dev/null && echo "✓ Gateway" || echo "✗ Gateway"

echo "Verification complete!"
EOF
```

### Manual Testing

1. Launch menu: `./adventure-menu.sh`
2. Select option 4 (System Status) - verify all green
3. Play Chip Quest:
   - Introduce yourself
   - Explore Tensix Village
   - Ask "What's really happening?" (test deep mode)
   - Test personality options (Brave, Nerdy, etc.)
   - Exit and re-enter (test memory persistence)
4. Play Terminal Dungeon:
   - Enter dungeon, battle enemy
   - Collect item
   - Check ASCII art rendering
5. Play Conference Chaos:
   - Navigate to Booth #42
   - Talk to NPCs
   - Reference other games

## Documentation

**For Players:**
- `ADVENTURE_GAMES.md` - Gameplay guide, tips, commands, mechanics

**For Admins:**
- `GAME_MASTER_GUIDE.md` - Architecture, customization, troubleshooting
- `DEMO_SETUP.md` - Quick start, demo flow, talking points

**All docs located in:** `/home/ttclaw/openclaw/`

## Success Criteria ✅

- [x] Three games with distinct personalities
- [x] Connected universe with cross-game state
- [x] Persistent memory across sessions
- [x] Dynamic personality-based default actions
- [x] Dual-depth technical mode (Chip Quest)
- [x] Pixel-perfect ASCII art instructions
- [x] Realistic conference world (17 booths, 8 NPCs, 5 panels)
- [x] Safety guidelines and content filtering
- [x] Interactive menu launcher
- [x] Direct game launchers
- [x] Comprehensive documentation (42KB total)
- [x] Model upgrade path (8B → 70B)
- [x] Verification scripts

## Benefits

### Technical
- ✅ Demonstrates local LLM inference on Tenstorrent hardware
- ✅ Shows persistent memory and multi-agent coordination
- ✅ Proves vLLM acceleration works for interactive applications
- ✅ Validates 65K context windows (128K with 70B)

### Educational
- ✅ Teaches chip architecture through playful adventure
- ✅ Explains Tensix cores, NOC, DRAM, RISC-V concepts
- ✅ Demonstrates roguelike game design principles
- ✅ Simulates realistic conference culture

### User Experience
- ✅ Zero-friction startup (single command)
- ✅ Never need to type (personality options always available)
- ✅ Progressive depth (light → deep mode on demand)
- ✅ Persistent progress (return anytime)
- ✅ Social experience (shared universe)

### Demo & Marketing
- ✅ Memorable booth experience
- ✅ Natural conversation starter
- ✅ Shows AI capabilities creatively
- ✅ Technical depth for experts, accessibility for all
- ✅ Demonstrates unique Tenstorrent value proposition

## Next Steps (Optional Enhancements)

### Skills Integration
- Dice roller skill for combat/puzzles
- Inventory manager skill
- ASCII scene generator skill (validates boxes)
- Player registry skill (manage universe state)

### Additional Games
- "Stack Trace" - Debugging adventure
- "Network Protocol" - TCP/IP journey
- "Compiler Quest" - Code transformation adventure

### Advanced Features
- Multi-player concurrent sessions (multiple agent instances)
- Voice interaction mode
- Web interface version
- Achievement system with badges
- Leaderboards across sessions
- Quest tracker skill

## Support

**Quick Commands:**
```bash
cd /home/ttclaw/openclaw
./adventure-menu.sh              # Launch games
./openclaw.sh gateway logs       # View logs
./openclaw.sh gateway restart    # Reload changes
```

**Troubleshooting:**
- Check proxy: `curl http://127.0.0.1:8001/v1/models`
- Check gateway: `pgrep -f "openclaw.*gateway"`
- View docs: `cat ADVENTURE_GAMES.md`, `GAME_MASTER_GUIDE.md`

## Credits

**Implementation Date:** March 8, 2026
**Platform:** OpenClaw v2026.3.2 + vLLM + Tenstorrent QB2
**Model:** Llama-3.1-8B-Instruct (upgradeable to 70B)
**Hardware:** 4x P300C chips (Blackhole architecture)

**Purpose:** Demonstrate local AI inference capabilities through interactive, educational, and fun text adventures for demo booth at fictional GDC Infinity conference.

---

## Summary

**What:** Three interconnected AI text adventure games
**Where:** `/home/ttclaw/openclaw/`
**How:** OpenClaw agents with comprehensive system prompts
**Status:** ✅ Production ready
**Start:** `./adventure-menu.sh`
**Docs:** `ADVENTURE_GAMES.md`, `GAME_MASTER_GUIDE.md`, `DEMO_SETUP.md`

🎮 **Ready for demo! Let players explore the silicon realm!** 🚀
