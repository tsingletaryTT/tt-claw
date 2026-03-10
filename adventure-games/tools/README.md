# Adventure Game Tools

Executable tools for OpenClaw adventure games. These provide deterministic dice rolls, character generation, and more.

## Tools

### dice.py
Dice rolling, GURPS skill checks, combat resolution, loot generation.

**Usage:**
```bash
# Roll dice
python3 dice.py roll 3d6
python3 dice.py roll 2d6+3

# Skill check (GURPS: roll under)
python3 dice.py check 12        # vs skill 12
python3 dice.py check 12 -2     # with -2 difficulty

# Damage
python3 dice.py damage "2d6+2"
python3 dice.py damage "1d6" 2.0  # 2x multiplier (critical)

# Full combat turn
python3 dice.py combat 12 8 "2d6+2"
# Args: attacker_skill defender_dodge weapon_damage

# Generate loot
python3 dice.py loot common
python3 dice.py loot rare
```

### character_gen.py
GURPS character creation and management.

**Usage:**
```bash
# Create character
python3 character_gen.py create "HeroName"

# Level up (add XP)
python3 character_gen.py level-up '<character_json>' 150

# Display sheet
python3 character_gen.py show '<character_json>'
```

## Integration

See `../TOOL_INTEGRATION.md` for how to integrate these with OpenClaw.

**Quick test:**
```bash
cd /home/ttuser/tt-claw/adventure-games/tools
python3 dice.py roll 3d6
python3 character_gen.py create "TestHero"
```

## Requirements

- Python 3.8+
- No external dependencies (uses stdlib only)
- Works offline (no network access)

## License

MIT
