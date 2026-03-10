#!/usr/bin/env python3
"""
Dice rolling tools for adventure games.
Provides deterministic dice rolls with proper randomization.
"""

import random
import json
import sys
from typing import List, Dict, Any

def roll_dice(num_dice: int, sides: int, modifier: int = 0) -> Dict[str, Any]:
    """
    Roll dice and return detailed results.

    Args:
        num_dice: Number of dice to roll
        sides: Number of sides per die
        modifier: Modifier to add to total

    Returns:
        Dictionary with rolls, total, and formatted string
    """
    rolls = [random.randint(1, sides) for _ in range(num_dice)]
    total = sum(rolls) + modifier

    return {
        "rolls": rolls,
        "total": total,
        "modifier": modifier,
        "notation": f"{num_dice}d{sides}" + (f"+{modifier}" if modifier > 0 else f"{modifier}" if modifier < 0 else ""),
        "formatted": f"{num_dice}d{sides}: [{', '.join(map(str, rolls))}] = {sum(rolls)}" + (f" + {modifier} = {total}" if modifier else "")
    }

def skill_check(skill_value: int, difficulty: int = None) -> Dict[str, Any]:
    """
    GURPS-style skill check: roll 3d6, succeed if under skill value.

    Args:
        skill_value: Target number (10-20 typically)
        difficulty: Optional difficulty modifier

    Returns:
        Dictionary with success/failure and margin
    """
    if difficulty:
        skill_value += difficulty

    roll = roll_dice(3, 6)
    total = roll["total"]

    # GURPS critical success/failure
    is_critical_success = (total <= 4)
    is_critical_failure = (total >= 17)
    is_success = (total <= skill_value) and not is_critical_failure

    margin = skill_value - total if is_success else total - skill_value

    return {
        "roll": roll,
        "skill_value": skill_value,
        "success": is_success,
        "critical_success": is_critical_success,
        "critical_failure": is_critical_failure,
        "margin": margin,
        "formatted": f"3d6 vs {skill_value}: {total} → " +
                    ("CRITICAL SUCCESS!" if is_critical_success else
                     "CRITICAL FAILURE!" if is_critical_failure else
                     f"Success by {margin}" if is_success else
                     f"Failure by {margin}")
    }

def damage_roll(weapon_damage: str, multiplier: float = 1.0) -> Dict[str, Any]:
    """
    Roll weapon damage (e.g., "2d6+3" or "1d6").

    Args:
        weapon_damage: Dice notation (e.g., "2d6+3")
        multiplier: Damage multiplier (e.g., 2.0 for critical)

    Returns:
        Dictionary with damage rolls and total
    """
    # Parse notation like "2d6+3"
    import re
    match = re.match(r'(\d+)d(\d+)([+-]\d+)?', weapon_damage)
    if not match:
        return {"error": f"Invalid damage notation: {weapon_damage}"}

    num_dice = int(match.group(1))
    sides = int(match.group(2))
    modifier = int(match.group(3) or 0)

    roll = roll_dice(num_dice, sides, modifier)
    final_damage = int(roll["total"] * multiplier)

    return {
        "roll": roll,
        "multiplier": multiplier,
        "final_damage": final_damage,
        "formatted": f"{weapon_damage} × {multiplier}: {roll['formatted']} → {final_damage} damage" if multiplier != 1.0 else f"{weapon_damage}: {roll['formatted']}"
    }

def combat_turn(attacker_skill: int, defender_dodge: int, weapon_damage: str) -> Dict[str, Any]:
    """
    Full combat turn: attack roll, defense roll, damage.

    Args:
        attacker_skill: Attacker's weapon skill
        defender_dodge: Defender's dodge value
        weapon_damage: Weapon damage notation

    Returns:
        Complete combat resolution
    """
    # Attack roll
    attack = skill_check(attacker_skill)

    if not attack["success"]:
        return {
            "attack": attack,
            "hit": False,
            "damage": 0,
            "formatted": f"Attack: {attack['formatted']} → MISS!"
        }

    # Defense roll
    defense = skill_check(defender_dodge)

    if defense["success"]:
        return {
            "attack": attack,
            "defense": defense,
            "hit": False,
            "damage": 0,
            "formatted": f"Attack: {attack['formatted']} → HIT!\n" +
                        f"Defense: {defense['formatted']} → DODGED!"
        }

    # Damage roll
    multiplier = 3.0 if attack["critical_success"] else 1.0
    damage = damage_roll(weapon_damage, multiplier)

    return {
        "attack": attack,
        "defense": defense,
        "hit": True,
        "damage": damage["final_damage"],
        "formatted": f"Attack: {attack['formatted']} → HIT!\n" +
                    f"Defense: {defense['formatted']} → FAILED!\n" +
                    f"Damage: {damage['formatted']}"
    }

def loot_roll(rarity: str = "common") -> List[str]:
    """
    Generate loot based on rarity.

    Args:
        rarity: "common", "uncommon", "rare", "legendary"

    Returns:
        List of loot items
    """
    loot_tables = {
        "common": [
            "Cache Block (heal 20 HP)",
            "Energy Cell (restore 20 EP)",
            "Business Card x5",
            "Swag x3",
            "Register Values x10"
        ],
        "uncommon": [
            "Tech Demo",
            "White Paper",
            "Health Packet (heal 2d6 HP)",
            "Stim-Pack (+3 to all attributes for 10 turns)",
            "NoC Router Token (teleport item)"
        ],
        "rare": [
            "Profiler Sword (2d6 damage)",
            "Memory Controller Key (quest item)",
            "Spell Chip: NoC Teleport",
            "Prototype (worth 250cr)",
            "TT Chip Blade (3d6 damage)"
        ],
        "legendary": [
            "Tensix Core Crystal (legendary consumable/cyberware)",
            "Memory Controller Artifact (4d6 damage weapon)",
            "DRAM Module (+50 HP max)",
            "L1 Cache Shard (+3 to all rolls)",
            "Overmind Grue Essence (game-winning item)"
        ]
    }

    table = loot_tables.get(rarity, loot_tables["common"])
    num_items = {
        "common": random.randint(2, 4),
        "uncommon": random.randint(1, 2),
        "rare": 1,
        "legendary": 1
    }.get(rarity, 1)

    return random.sample(table, min(num_items, len(table)))

if __name__ == "__main__":
    # CLI interface for testing
    if len(sys.argv) < 2:
        print("Usage:")
        print("  dice.py roll <num>d<sides>[+modifier]  # Roll dice")
        print("  dice.py check <skill> [difficulty]      # Skill check")
        print("  dice.py damage <notation> [multiplier]  # Damage roll")
        print("  dice.py combat <atk_skill> <def_dodge> <weapon>  # Combat turn")
        print("  dice.py loot [rarity]                   # Generate loot")
        sys.exit(1)

    command = sys.argv[1]

    if command == "roll":
        # Parse XdY+Z notation
        import re
        match = re.match(r'(\d+)d(\d+)([+-]\d+)?', sys.argv[2])
        if not match:
            print(f"Invalid notation: {sys.argv[2]}")
            sys.exit(1)
        result = roll_dice(
            int(match.group(1)),
            int(match.group(2)),
            int(match.group(3) or 0)
        )
        print(result["formatted"])
        print(f"Total: {result['total']}")

    elif command == "check":
        skill = int(sys.argv[2])
        difficulty = int(sys.argv[3]) if len(sys.argv) > 3 else None
        result = skill_check(skill, difficulty)
        print(result["formatted"])

    elif command == "damage":
        notation = sys.argv[2]
        multiplier = float(sys.argv[3]) if len(sys.argv) > 3 else 1.0
        result = damage_roll(notation, multiplier)
        print(result["formatted"])

    elif command == "combat":
        atk_skill = int(sys.argv[2])
        def_dodge = int(sys.argv[3])
        weapon = sys.argv[4]
        result = combat_turn(atk_skill, def_dodge, weapon)
        print(result["formatted"])

    elif command == "loot":
        rarity = sys.argv[2] if len(sys.argv) > 2 else "common"
        items = loot_roll(rarity)
        print(f"Loot ({rarity}):")
        for item in items:
            print(f"  - {item}")

    else:
        print(f"Unknown command: {command}")
        sys.exit(1)
