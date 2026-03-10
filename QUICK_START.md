# Quick Start - Play the Games!

## 🚀 Launch the Adventure Menu

```bash
cd ~/tt-claw/adventure-games/scripts
./adventure-menu.sh
```

## 🎮 How to Play

1. **Menu appears** with 3 game choices
2. **Type a number** (1, 2, or 3) and press Enter
3. **Game starts** - read the opening scene
4. **Make choices** by typing numbers when prompted
5. **Progress through the adventure!**

## 💡 Example Gameplay

```
What do you do?
1. Enter the cave
2. Talk to the wizard
3. Check inventory
```

→ Type `1` and press Enter

```
You enter the dark cave. A Memory Grue blocks your path!

What do you do?
1. Fight the grue
2. Run away
3. Use magic
```

→ Type `1` and press Enter

... and so on!

## 📖 The Three Games

- **Chip Quest** (30-45 min) - Learn TT architecture through puzzles
- **Terminal Dungeon** (30-60 min) - Roguelike dungeon crawler
- **Conference Chaos** (30-45 min) - Trading and networking sim

## ⚙️ Terminal Tips

**For best experience:**
- Make terminal window large (120x40 recommended)
- Use dark theme
- Monospace font (Fira Code, JetBrains Mono, etc.)

See [TUI_OPTIMIZATION.md](docs/TUI_OPTIMIZATION.md) for details.

## 🔧 Troubleshooting

**Menu doesn't start:**
```bash
# Check if services are running
cd ~/tt-claw/adventure-games/scripts
./adventure-menu.sh
# Choose option 0 → Service Management → Check status
```

**No response after choosing:**
- Wait 2-5 seconds (AI is thinking)
- Check vLLM is running: `curl http://localhost:8000/health`
- Check gateway: `netstat -tlnp | grep 18789`

**Garbled output:**
- Resize terminal to at least 80 columns wide
- Check UTF-8 encoding: `echo $LANG` (should show UTF-8)

## ✅ First Time Setup

**If this is your first time:**
1. Make sure vLLM is running on port 8000
2. Make sure OpenClaw gateway is running (port 18789)
3. Run the adventure menu (it auto-detects everything)

**Need to start services:**
```bash
cd ~/tt-claw/adventure-games/scripts
./adventure-menu.sh
# Choose option 0 → Service Management → Start all services
```

## 📚 Learn More

- **[README.md](README.md)** - Full overview
- **[TUI_OPTIMIZATION.md](docs/TUI_OPTIMIZATION.md)** - Make it beautiful
- **[adventure-games/README.md](adventure-games/README.md)** - Game details

---

**That's it! Have fun!** 🎉
