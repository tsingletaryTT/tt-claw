# Memory Templates for Adventure Games

## Purpose

These templates provide **initial memory state** for each adventure game. Instead of fighting OpenClaw's default behavior (check memory first), we work WITH it by seeding memory with starter content.

## How It Works

When `restart-games.sh` runs, it:
1. Clears old sessions (stale SOUL cache)
2. **Copies these templates** into each game's memory directory
3. Uses today's date as filename (e.g., `2026-03-10.md`)

Now when the agent checks memory on "start the adventure", it finds relevant context that says the adventure has JUST BEGUN.

## Templates

### chip-quest-start.md
- **Location**: Miniaturization chamber (just shrunk)
- **State**: Ready to enter the chip
- **Tone**: Zork-style, educational

### terminal-dungeon-start.md
- **Location**: Top of stairs to Booth #42's basement
- **State**: About to begin character creation
- **Tone**: NetHack-inspired roguelike

### conference-chaos-start.md
- **Location**: Badge registration (just arrived)
- **State**: Fresh badge, ready to enter expo floor
- **Tone**: Trade Wars meets Hitchhiker's Guide

## Design Philosophy

Each template:
- **Establishes location** (where adventure begins)
- **Sets initial state** (inventory, status)
- **Provides just enough context** to continue naturally
- **Feels like "resume"** not "start from scratch"

The memory says: *"The adventure has already begun. You're at the starting location. Here's what just happened..."*

## Usage

### Manual Seeding
```bash
# Seed all games
DATE=$(date +%Y-%m-%d)
cp chip-quest-start.md ~/.openclaw/workspace-chip-quest/memory/$DATE.md
cp terminal-dungeon-start.md ~/.openclaw/workspace-terminal-dungeon/memory/$DATE.md
cp conference-chaos-start.md ~/.openclaw/workspace-conference-chaos/memory/$DATE.md
```

### Automatic (Recommended)
```bash
cd ~/tt-claw/adventure-games/scripts
./restart-games.sh
```

The restart script seeds memory automatically.

## Why This Works

OpenClaw agents have built-in memory tools that activate automatically:
1. Agent sees "start the adventure"
2. Agent calls `memory_search("start the adventure")`
3. Finds THIS memory (today's date)
4. Reads: "The adventure just began, I'm at the starting location..."
5. Continues naturally from there ✅

Instead of:
1. Agent calls `memory_search("start the adventure")`
2. Finds nothing
3. Says "No relevant information in memory files" ❌

## Updating Templates

To modify starter content:
1. Edit the template files here
2. Run `restart-games.sh` to apply changes
3. Or manually copy to workspace memory directories

Templates should:
- Be concise (1-2 paragraphs of context)
- Establish location clearly
- Avoid spoilers (don't reveal puzzles)
- Match the game's tone and style
- Feel like natural memory notes

## Related

- `restart-games.sh` - Complete restart with memory seeding
- `../games/*/SOUL.md` - Game definitions
- `MEMORY_TOOL_FIX.md` - Documentation of memory tool issues
