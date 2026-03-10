#!/usr/bin/env python3
"""
Character generation tools for adventure games.
Creates GURPS-style characters with attributes, skills, advantages/disadvantages.
"""

import random
import json
import sys
from typing import Dict, List, Any

ATTRIBUTES = ["ST", "DX", "IQ", "HT"]

ADVANTAGES = {
    "Combat Reflexes": {"cost": 15, "description": "+1 to all active defenses, +2 initiative"},
    "High Pain Threshold": {"cost": 10, "description": "Ignore wound penalties"},
    "Luck": {"cost": 15, "description": "Reroll one failed roll per session"},
    "Weapon Master": {"cost": 20, "description": "+2 to hit with all weapons, +2 melee damage"},
    "Cybernetic Enhancements": {"cost": 10, "description": "Install TT chips directly"},
    "Eidetic Memory": {"cost": 5, "description": "Perfect recall of information"},
    "Charismatic": {"cost": 5, "description": "+2 to all social interactions"},
    "Lucky": {"cost": 15, "description": "+1 to all rolls"},
}

DISADVANTAGES = {
    "Bad Temper": {"value": -10, "description": "Must resist frenzy in combat"},
    "Curious": {"value": -5, "description": "Must investigate interesting things"},
    "Overconfidence": {"value": -5, "description": "Underestimate dangers"},
    "Code of Honor": {"value": -10, "description": "Won't attack helpless foes"},
    "Fragile": {"value": -10, "description": "-3 HP per ST"},
    "Phobia (Grues)": {"value": -10, "description": "-2 to all rolls when grues present"},
}

SKILLS = [
    "Melee Weapon", "Ranged Weapon", "Brawling",
    "Hacking", "Engineering", "Computer Operation",
    "TT-Sorcery", "Cyberware",
    "Stealth", "Survival", "First Aid",
    "Intimidation", "Fast-Talk", "Negotiation",
    "Market Analysis", "Networking", "Tech Talk"
]

def generate_character(
    name: str = "Adventurer",
    points: int = 100,
    attribute_points: int = 4,
    skill_points: int = 10
) -> Dict[str, Any]:
    """
    Generate a complete GURPS character.

    Args:
        name: Character name
        points: Total character points budget
        attribute_points: Points to distribute to attributes
        skill_points: Points to distribute to skills

    Returns:
        Complete character sheet
    """
    # Base attributes (10)
    attributes = {attr: 10 for attr in ATTRIBUTES}

    # Distribute attribute points randomly
    for _ in range(attribute_points):
        attr = random.choice(ATTRIBUTES)
        attributes[attr] += 1

    # Derived stats
    hp = attributes["ST"] * 3 + attributes["HT"] * 2
    ep = attributes["IQ"] * 3 + (attributes["IQ"] + 2) * 2  # IQ * 3 + Will * 2
    speed = (attributes["DX"] + attributes["HT"]) / 4
    dodge = speed + 3

    # Random advantages (spend ~20 points)
    advantage_budget = 20
    selected_advantages = []
    available_advantages = list(ADVANTAGES.items())
    random.shuffle(available_advantages)

    for adv_name, adv_data in available_advantages:
        if advantage_budget >= adv_data["cost"]:
            selected_advantages.append(adv_name)
            advantage_budget -= adv_data["cost"]

    # Random disadvantages (gain ~10-20 points)
    disadvantage_gain = random.randint(10, 20)
    selected_disadvantages = []
    available_disadvantages = list(DISADVANTAGES.items())
    random.shuffle(available_disadvantages)

    current_gain = 0
    for disadv_name, disadv_data in available_disadvantages:
        if current_gain < disadvantage_gain:
            selected_disadvantages.append(disadv_name)
            current_gain += abs(disadv_data["value"])

    # Distribute skill points
    skills = {}
    remaining_skill_points = skill_points
    available_skills = SKILLS.copy()
    random.shuffle(available_skills)

    while remaining_skill_points > 0 and available_skills:
        skill = available_skills.pop(0)
        allocation = random.randint(1, min(5, remaining_skill_points))
        skills[skill] = allocation
        remaining_skill_points -= allocation

    return {
        "name": name,
        "attributes": attributes,
        "derived_stats": {
            "HP": hp,
            "max_HP": hp,
            "EP": ep,
            "max_EP": ep,
            "Will": attributes["IQ"] + 2,
            "Perception": attributes["IQ"] + 1,
            "Speed": round(speed, 1),
            "Move": int(speed),
            "Dodge": int(dodge)
        },
        "advantages": selected_advantages,
        "disadvantages": selected_disadvantages,
        "skills": skills,
        "inventory": [],
        "experience": 0,
        "level": 1
    }

def format_character_sheet(character: Dict[str, Any]) -> str:
    """Format character as readable text."""
    lines = []
    lines.append(f"╔══════════════════════════════════════════╗")
    lines.append(f"║  {character['name']:^38}  ║")
    lines.append(f"╠══════════════════════════════════════════╣")
    lines.append(f"║  ATTRIBUTES                              ║")

    attrs = character['attributes']
    lines.append(f"║  ST: {attrs['ST']:2d}  DX: {attrs['DX']:2d}  IQ: {attrs['IQ']:2d}  HT: {attrs['HT']:2d}           ║")

    lines.append(f"║                                          ║")
    lines.append(f"║  DERIVED STATS                           ║")

    stats = character['derived_stats']
    lines.append(f"║  HP: {stats['HP']:3d}/{stats['max_HP']:3d}   EP: {stats['EP']:3d}/{stats['max_EP']:3d}          ║")
    lines.append(f"║  Speed: {stats['Speed']:4.1f}   Move: {stats['Move']:2d}   Dodge: {stats['Dodge']:2d}     ║")
    lines.append(f"║  Will: {stats['Will']:2d}    Perception: {stats['Perception']:2d}             ║")

    if character['advantages']:
        lines.append(f"║                                          ║")
        lines.append(f"║  ADVANTAGES                              ║")
        for adv in character['advantages']:
            lines.append(f"║  • {adv:<36} ║")

    if character['disadvantages']:
        lines.append(f"║                                          ║")
        lines.append(f"║  DISADVANTAGES                           ║")
        for disadv in character['disadvantages']:
            lines.append(f"║  • {disadv:<36} ║")

    lines.append(f"║                                          ║")
    lines.append(f"║  SKILLS                                  ║")
    for skill, level in sorted(character['skills'].items()):
        lines.append(f"║  {skill:<28} {level:2d}         ║")

    lines.append(f"╚══════════════════════════════════════════╝")

    return "\n".join(lines)

def level_up(character: Dict[str, Any], xp_gained: int = 100) -> Dict[str, Any]:
    """
    Level up character with gained XP.

    Args:
        character: Character dict
        xp_gained: XP to add

    Returns:
        Updated character with level-up benefits
    """
    character["experience"] += xp_gained
    xp_per_level = 100
    new_levels = character["experience"] // xp_per_level

    if new_levels > character["level"]:
        levels_gained = new_levels - character["level"]
        character["level"] = new_levels

        # Grant benefits per level
        for _ in range(levels_gained):
            # +1 attribute every 2 levels
            if character["level"] % 2 == 0:
                attr = random.choice(ATTRIBUTES)
                character["attributes"][attr] += 1

                # Recalculate derived stats
                attrs = character["attributes"]
                character["derived_stats"]["HP"] = attrs["ST"] * 3 + attrs["HT"] * 2
                character["derived_stats"]["max_HP"] = character["derived_stats"]["HP"]
                character["derived_stats"]["EP"] = attrs["IQ"] * 3 + (attrs["IQ"] + 2) * 2
                character["derived_stats"]["max_EP"] = character["derived_stats"]["EP"]

            # +2 skill points every level
            available_skills = [s for s in SKILLS if s not in character["skills"] or character["skills"][s] < 10]
            if available_skills:
                skill1 = random.choice(available_skills)
                character["skills"][skill1] = character["skills"].get(skill1, 0) + 1

                available_skills2 = [s for s in available_skills if s != skill1]
                if available_skills2:
                    skill2 = random.choice(available_skills2)
                    character["skills"][skill2] = character["skills"].get(skill2, 0) + 1

    return character

if __name__ == "__main__":
    if len(sys.argv) < 2:
        print("Usage:")
        print("  character_gen.py create [name]        # Create new character")
        print("  character_gen.py level-up <json>      # Level up from JSON")
        print("  character_gen.py show <json>          # Show character sheet")
        sys.exit(1)

    command = sys.argv[1]

    if command == "create":
        name = sys.argv[2] if len(sys.argv) > 2 else "Adventurer"
        character = generate_character(name)
        print(format_character_sheet(character))
        print("\nJSON:")
        print(json.dumps(character, indent=2))

    elif command == "show":
        character = json.loads(sys.argv[2])
        print(format_character_sheet(character))

    elif command == "level-up":
        character = json.loads(sys.argv[2])
        xp = int(sys.argv[3]) if len(sys.argv) > 3 else 100
        character = level_up(character, xp)
        print(f"Leveled up to level {character['level']}!")
        print(format_character_sheet(character))

    else:
        print(f"Unknown command: {command}")
        sys.exit(1)
