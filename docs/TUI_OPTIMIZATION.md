# TUI Optimization Guide
## Making OpenClaw Adventure Games Vibrant and Informative

The games are designed to work beautifully in a terminal. Here's how to get the best experience.

## Terminal Setup

### Recommended Terminals
- **Linux:** Alacritty, Kitty, GNOME Terminal, Konsole
- **macOS:** iTerm2, Alacritty, Kitty
- **Windows:** Windows Terminal, WSL2 + any Linux terminal

### Terminal Size
**Minimum:** 80x24 (standard)
**Recommended:** 120x40 or larger
**Why:** Games use ASCII art, stat displays, and formatted text that look best with room to breathe

### Font Recommendations
**Monospace fonts with good Unicode support:**
- **Fira Code** (has ligatures, looks great)
- **JetBrains Mono** (clean, readable)
- **Cascadia Code** (Microsoft's coding font)
- **Hack** (designed for source code)
- **Source Code Pro** (Adobe's open-source font)

**Font size:** 12-14pt for desktop, 10-12pt for laptop

### Colors
The games use ANSI color codes:
- `\033[0;36m` = Cyan (headers, titles)
- `\033[0;32m` = Green (success, good options)
- `\033[1;33m` = Yellow (warnings, important)
- `\033[0;31m` = Red (danger, combat, errors)

**Enable true color** if your terminal supports it (most modern terminals do).

## What the Games Display

### Typical Turn Structure
```
## Location Name 🗺️

[Vivid 2-3 paragraph description of the scene]

[Optional ASCII art for dramatic moments]

---

Status:
- HP: 80/80 | EP: 45/50 | Level: 2
- Location: DRAM Cavern
- Inventory: 4/10 slots

---

What do you do?
1. Fight the grue
2. Evade and escape
3. Use item
4. Cast spell
0. Menu
```

### ASCII Art Examples

The games include:
- **Chip Quest:** Circuit diagrams, chip layouts, grue encounters
- **Terminal Dungeon:** Dungeon maps, combat scenes, treasure chests
- **Conference Chaos:** Conference floor plans, booth layouts, traders

### Rich Text Formatting

Games use:
- **Bold headers** for locations
- **Italic text** for NPC dialogue (if terminal supports)
- **Color coding** for different types of information
- **Tables** for stats and inventory
- **Progress bars** for HP/EP/XP

## Optimizing Your Experience

### 1. Terminal Configuration

**Enable 256-color mode:**
```bash
export TERM=xterm-256color
```

**Check color support:**
```bash
echo $COLORTERM  # Should show "truecolor" or "24bit"
```

**Test colors:**
```bash
for i in {0..255}; do
    printf "\x1b[38;5;${i}mcolor%-5i\x1b[0m" $i
    (( $i % 8 == 7 )) && echo
done
```

### 2. Font Rendering

**macOS/Linux:**
```bash
# Install recommended font
# For Fira Code:
sudo apt install fonts-firacode  # Debian/Ubuntu
brew install font-fira-code      # macOS
```

**Windows:**
Download from [Nerd Fonts](https://www.nerdfonts.com/) for best Unicode support.

### 3. OpenClaw TUI Settings

The TUI respects your terminal's color scheme and capabilities. To enhance output:

**Set thinking level** (controls response detail):
```bash
cd ~/tt-claw/adventure-games/scripts
./adventure-menu.sh
# Games use detailed responses by default
```

**Adjust history** (for faster loading):
```bash
# Edit adventure-menu.sh if needed
# Default: --history-limit 200 (works well)
```

### 4. Gameplay Tips

**For best visual experience:**
1. **Maximize terminal window** - More room for ASCII art
2. **Use dark theme** - Most ASCII art designed for dark backgrounds
3. **Enable scrollback** - Review previous turns easily
4. **Use tmux/screen** - Keep sessions persistent

**Reading responses:**
- Don't rush - responses are detailed and rich
- ASCII art aligns best at 80+ columns width
- Status bars update with each turn
- NPC dialogue is quoted and distinct

### 5. Performance

**If responses are slow:**
- Check vLLM server status: `curl http://localhost:8000/health`
- Verify gateway is running: `netstat -tlnp | grep 18789`
- Use smaller model (8B faster than 70B)

**If display is garbled:**
- Check terminal encoding: `echo $LANG` (should be UTF-8)
- Resize terminal to at least 80 columns
- Try different terminal emulator

## Sample Output

### Good Terminal Setup (120x40, Fira Code, Dark Theme)
```
## DRAM Cavern - Southern Passage 🗺️

You step cautiously into the vast, dark chamber. The walls here are
made of thousands of tiny memory cells, each flickering with stored
data. The air feels thick—you can almost sense the latency, the delay
between thought and action. This is the realm of main memory.

A low growl echoes from the shadows ahead.

     🐉
    /|\
   / | \
  👁️ 👁️

The Memory Grue snarls: "Prove you understand memory hierarchy, tiny
program, or be thrashed into oblivion!"

---

Status:
- HP: 80/80 | EP: 45/50 | Level: 2 | XP: 45/100
- Location: DRAM Cavern - Southern Passage
- Inventory: 4/10 slots (Debugger Probe, Profiler Lens, 2x Cache Blocks)

Grue Status:
- Memory Grue HP: 40/40
- Attack ready: "Cache Miss" (15 damage)

---

What do you do?
1. Fight the grue head-on (3d6 vs DEX, deal 10-20 damage)
2. Evade and try to escape back the way you came (3d6 vs DEX)
3. Use Profiler Lens to analyze its weakness (costs 10 EP, reveals strategy)
4. Answer the grue's challenge (show understanding of cache optimization)
5. Use Grue Whispering skill to calm it (3d6 vs INT, requires skill 1+)
6. Use Cache Block consumable to distract it
0. Open menu
```

### Poor Terminal Setup (80x24, Default Font, Light Theme)
- ASCII art may be cramped
- Colors hard to read on light background
- Status bars may wrap awkwardly
- Less immersive

## Troubleshooting

### Colors don't work
```bash
# Check terminal type
echo $TERM  # Should be xterm-256color or similar

# Force color support
export TERM=xterm-256color
export COLORTERM=truecolor
```

### ASCII art is broken
- **Issue:** Terminal too narrow
- **Fix:** Resize to at least 80 columns
- **Check:** `tput cols` (should be 80+)

### Text is hard to read
- **Issue:** Terminal color scheme
- **Fix:** Use dark theme (ASCII art designed for it)
- **Alternative:** Manually adjust terminal colors

### Emojis don't render
- **Issue:** Font lacks Unicode support
- **Fix:** Install Nerd Font or font with emoji support
- **Workaround:** Games use emoji sparingly, not critical

## Advanced: Customizing Response Format

The SOUL files control how games format responses. To modify:

```bash
cd ~/tt-claw/adventure-games/games/chip-quest
sudo nano SOUL.md  # Edit the game's behavior
```

Look for the "Response Format" section to tweak:
- How verbose descriptions are
- ASCII art frequency
- Status display layout
- Number of choices presented

## Best Practices

1. **Start with Chip Quest** - Good introduction, validates terminal setup
2. **Use full screen** - Games designed for immersion
3. **Take your time** - Read descriptions, they're rich and detailed
4. **Experiment** - Multiple solutions to most challenges
5. **Save sessions** - OpenClaw persists state, you can continue later

## Comparison: TUI vs. Web UI

**TUI Advantages:**
- ✅ Native terminal colors and formatting
- ✅ Fast (no web rendering overhead)
- ✅ Works over SSH
- ✅ Hacker aesthetic (fits the theme)
- ✅ Better for ASCII art

**TUI Limitations:**
- ❌ No clickable buttons (type numbers instead)
- ❌ No images/graphics (ASCII art only)
- ❌ Requires terminal know-how

**For now, TUI is the best option** - it's fast, immersive, and works great with proper terminal setup.

## Getting Help

If something doesn't look right:
1. Check this guide's terminal setup section
2. Test with a simple echo: `echo -e "\033[0;32mGreen text\033[0m"`
3. Try a different terminal emulator
4. Ask in the OpenClaw Discord or GitHub issues

---

**Happy adventuring!** The games are designed to be vibrant and informative in a terminal. With the right setup, they're a joy to play. 🎮
