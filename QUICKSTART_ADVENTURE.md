# TT-CLAW Adventure Games - Quick Start

**Status:** ✅ Validated and Ready for Demo

## Prerequisites

All components must be running. Check with:
```bash
curl http://localhost:8000/health          # vLLM backend
curl http://localhost:8001/v1/models       # Compatibility proxy
netstat -tlnp 2>/dev/null | grep 18789     # OpenClaw gateway
```

## Starting the Games

### Option 1: One Command (Recommended)

```bash
cd ~/tt-claw/adventure-games/scripts
./adventure-menu.sh
```

This shows you:
- ✓ Service status (vLLM, Proxy, Gateway)
- ✓ Current model name
- ✓ Game selection menu

### Option 2: Direct Game Launch

```bash
# Start specific game directly
cd ~/.openclaw
./openclaw.sh tui
# Then select your agent from the TUI
```

## Service Management

### Start All Services

```bash
cd ~/tt-claw/adventure-games/scripts
./start-adventure-services.sh
```

This automatically:
1. Verifies vLLM is running (port 8000)
2. Starts proxy if needed (port 8001)
3. Starts gateway if needed (port 18789)
4. Shows you service status and log locations

### Start Services Manually

**Terminal 1: Proxy** (must start first!)
```bash
cd ~/openclaw  # or wherever vllm-proxy.py is located
python3 vllm-proxy.py
```

**Terminal 2: Gateway**
```bash
cd ~/openclaw
./openclaw.sh gateway run
```

**Terminal 3: Adventure Menu**
```bash
cd ~/tt-claw/adventure-games/scripts
./adventure-menu.sh
```

### Stop Services

```bash
# Stop all
pkill -f vllm-proxy
pkill -f 'openclaw.*gateway'

# Or individually
pkill -f vllm-proxy          # Stop proxy
pkill -f openclaw-gateway    # Stop gateway
```

## Game Descriptions

### 1. Chip Quest ⭐ (Recommended Start)
**Genre:** Educational Zork-style adventure
**Location:** Booth #42 (Main Level)
**Length:** 30-40 minutes
**Features:**
- Explore Tenstorrent chip architecture (Tensix cores, NOC, DRAM)
- Solve logic puzzles (gates, parallel processing, routing)
- Fight Memory Grues (3 types) in dark DRAM caverns
- Learn chip design concepts through gameplay
- 4 endings, 6 easter eggs

**Why start here:** Most accessible, educational, and introduces TT-Grues.

### 2. Terminal Dungeon ⚔️
**Genre:** NetHack-style roguelike
**Location:** Booth #42 (Basement Level)
**Length:** 30-45 minutes
**Features:**
- Full GURPS character system (ST, DX, IQ, HT + 10 skills)
- 5 character classes (Sysadmin, Netrunner, Cyber-Warrior, TT-Mage, Scout)
- Turn-based tactical combat with action points
- 6 TT-Grues with unique abilities
- Equipment system with legendary TT hardware
- Permadeath mode with meta-progression
- Procedurally generated dungeons

**Difficulty:** Medium-Hard

### 3. Conference Chaos 💼
**Genre:** Trade Wars 2002 + Hitchhiker's Guide
**Location:** EAC 2026 Expo Floor (Overworld)
**Length:** 30-45 minutes
**Features:**
- Trading system (8 goods, dynamic pricing, supply/demand)
- NPC traders with perfect memory
- Reputation progression (Nobody → Legend)
- Vogon Poetry panels (bureaucracy puzzles)
- Towel mechanic (most important item, 7 uses)
- 5 distinct endings (Mogul, Job, Set, Conspiracy, Survive)

**Difficulty:** Medium

## Connected Universe

All three games share the **EAC 2026** (Experience Architect Convergence) setting:
- **Chip Quest** = Main booth demo (educational intro)
- **Terminal Dungeon** = Secret basement level (hardcore gameplay)
- **Conference Chaos** = Expo floor chaos (social/trading)

NPCs and events can reference other games!

## Troubleshooting

### "No services running"

Check each service individually:
```bash
# vLLM
curl http://localhost:8000/health
# If fails: Docker container isn't running (see OPENCLAW_FINAL_INSTRUCTIONS.md)

# Proxy
curl http://localhost:8001/v1/models
# If fails: cd ~/openclaw && python3 vllm-proxy.py

# Gateway
netstat -tlnp 2>/dev/null | grep 18789
# If fails: cd ~/openclaw && ./openclaw.sh gateway run
```

### "Gateway exits immediately"

Check configuration:
```bash
cat ~/.openclaw/openclaw.json | grep -A2 gateway
# Should show: "mode": "local"
```

Fix:
```bash
cd ~/openclaw
./openclaw.sh config set gateway.mode local
```

### "Model not responding"

1. Verify vLLM is healthy: `curl http://localhost:8000/v1/models`
2. Verify proxy is running: `curl http://localhost:8001/v1/models`
3. Check logs: `tail /tmp/vllm-proxy.log /tmp/openclaw-gateway.log`

### "Slow responses"

Normal for first response (model warmup). Subsequent responses should be 1-2 seconds.

## Testing the Stack

Run automated validation:
```bash
cd /tmp
bash ~/tt-claw/adventure-games/scripts/test-game-response.sh
bash ~/tt-claw/adventure-games/scripts/test-game-progression.sh
bash ~/tt-claw/adventure-games/scripts/test-grue-encounter.sh
```

Expected: All tests show ✓ SUCCESS

## What to Demo

**For technical audience:**
1. Start with Chip Quest (educational, shows TT concepts)
2. Mention Memory Grues (Zork reference)
3. Show service architecture (proxy solving compatibility)

**For gaming audience:**
1. Terminal Dungeon (roguelike, combat, procedural)
2. Show character creation with GURPS system
3. Demonstrate TT-Grues with unique abilities

**For business audience:**
1. Conference Chaos (trading, networking, reputation)
2. Show NPC memory (persistent conversations)
3. Multiple endings based on player choices

## Current Model

**Model:** meta-llama/Llama-3.1-8B-Instruct
**Context:** 65,536 tokens (64K)
**Hardware:** 4x Blackhole chips (P300C architecture)
**Performance:** ~1-2 seconds per response after warmup

## Next Steps

After playing:
- Try different strategies (multiple puzzle solutions!)
- Experiment with character classes (Terminal Dungeon)
- Corner different markets (Conference Chaos)
- Look for easter eggs (all games have hidden content)
- Save progress and resume later

---

**Last Updated:** March 10, 2026
**Validated:** All 3 test scenarios passing
**Status:** Production ready for EAC 2026 demo
