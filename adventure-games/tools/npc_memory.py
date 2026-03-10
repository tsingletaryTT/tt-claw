#!/usr/bin/env python3
"""
NPC memory and relationship tracking for adventure games.
Tracks conversations, reputation, promises, and trades.
"""

import json
import sys
from datetime import datetime
from typing import Dict, List, Any, Optional

def create_npc(
    name: str,
    npc_type: str = "neutral",
    location: str = "unknown"
) -> Dict[str, Any]:
    """
    Create new NPC.

    Args:
        name: NPC name
        npc_type: Type (vendor, quest_giver, enemy, ally, etc.)
        location: Current location

    Returns:
        NPC data structure
    """
    return {
        "name": name,
        "type": npc_type,
        "location": location,
        "relationship": 0,  # -100 to +100
        "mood": "neutral",  # happy, neutral, angry, sad
        "conversations": [],
        "trades": [],
        "promises": [],
        "quests_given": [],
        "met_at_turn": 0,
        "last_seen_turn": 0,
        "notes": []
    }

def record_conversation(
    npc: Dict[str, Any],
    topic: str,
    player_said: str,
    npc_said: str,
    turn: int,
    relationship_change: int = 0
) -> Dict[str, Any]:
    """
    Record a conversation with NPC.

    Args:
        npc: NPC dict
        topic: Conversation topic
        player_said: Player's dialogue
        npc_said: NPC's response
        turn: Game turn number
        relationship_change: How much relationship changed

    Returns:
        Updated NPC
    """
    npc["conversations"].append({
        "turn": turn,
        "topic": topic,
        "player": player_said,
        "npc": npc_said,
        "timestamp": datetime.now().isoformat()
    })

    npc["relationship"] += relationship_change
    npc["relationship"] = max(-100, min(100, npc["relationship"]))  # Clamp

    npc["last_seen_turn"] = turn

    # Update mood based on relationship
    if npc["relationship"] > 50:
        npc["mood"] = "happy"
    elif npc["relationship"] < -50:
        npc["mood"] = "angry"
    else:
        npc["mood"] = "neutral"

    return npc

def record_trade(
    npc: Dict[str, Any],
    item: str,
    price: int,
    fair: bool,
    turn: int
) -> Dict[str, Any]:
    """
    Record a trade with NPC.

    Args:
        npc: NPC dict
        item: Item traded
        price: Price paid
        fair: Was the trade fair?
        turn: Game turn

    Returns:
        Updated NPC
    """
    npc["trades"].append({
        "turn": turn,
        "item": item,
        "price": price,
        "fair": fair,
        "timestamp": datetime.now().isoformat()
    })

    # Update relationship
    if fair:
        npc["relationship"] += 5
    else:
        npc["relationship"] -= 10

    npc["relationship"] = max(-100, min(100, npc["relationship"]))

    return npc

def make_promise(
    npc: Dict[str, Any],
    promise: str,
    turn: int
) -> Dict[str, Any]:
    """
    Make a promise to NPC.

    Args:
        npc: NPC dict
        promise: What was promised
        turn: Game turn

    Returns:
        Updated NPC
    """
    npc["promises"].append({
        "promise": promise,
        "made_at_turn": turn,
        "kept": None,  # None = pending, True = kept, False = broken
        "timestamp": datetime.now().isoformat()
    })

    return npc

def keep_promise(
    npc: Dict[str, Any],
    promise_index: int
) -> Dict[str, Any]:
    """
    Mark promise as kept.

    Args:
        npc: NPC dict
        promise_index: Index in promises list

    Returns:
        Updated NPC
    """
    if 0 <= promise_index < len(npc["promises"]):
        npc["promises"][promise_index]["kept"] = True
        npc["relationship"] += 15
        npc["relationship"] = min(100, npc["relationship"])

    return npc

def break_promise(
    npc: Dict[str, Any],
    promise_index: int
) -> Dict[str, Any]:
    """
    Mark promise as broken.

    Args:
        npc: NPC dict
        promise_index: Index in promises list

    Returns:
        Updated NPC
    """
    if 0 <= promise_index < len(npc["promises"]):
        npc["promises"][promise_index]["kept"] = False
        npc["relationship"] -= 30
        npc["relationship"] = max(-100, npc["relationship"])
        npc["mood"] = "angry"

    return npc

def add_note(npc: Dict[str, Any], note: str) -> Dict[str, Any]:
    """
    Add a note about the NPC.

    Args:
        npc: NPC dict
        note: Note text

    Returns:
        Updated NPC
    """
    npc["notes"].append({
        "note": note,
        "timestamp": datetime.now().isoformat()
    })

    return npc

def show_npc(npc: Dict[str, Any]) -> str:
    """
    Format NPC data as readable text.

    Args:
        npc: NPC dict

    Returns:
        Formatted string
    """
    lines = []
    lines.append("╔════════════════════════════════════════╗")
    lines.append(f"║  {npc['name']:^36}  ║")
    lines.append("╠════════════════════════════════════════╣")
    lines.append(f"║  Type: {npc['type']:<30} ║")
    lines.append(f"║  Location: {npc['location']:<26} ║")
    lines.append(f"║  Relationship: {npc['relationship']:>4}/100 ({npc['mood']}){'':>10} ║")

    lines.append("║                                        ║")
    lines.append("║  HISTORY                               ║")
    lines.append(f"║  Conversations: {len(npc['conversations']):>2}                     ║")
    lines.append(f"║  Trades: {len(npc['trades']):>2}                            ║")

    pending_promises = sum(1 for p in npc["promises"] if p["kept"] is None)
    kept_promises = sum(1 for p in npc["promises"] if p["kept"] is True)
    broken_promises = sum(1 for p in npc["promises"] if p["kept"] is False)

    if npc["promises"]:
        lines.append(f"║  Promises: {pending_promises} pending, {kept_promises} kept, {broken_promises} broken  ║")

    if npc["quests_given"]:
        lines.append("║                                        ║")
        lines.append("║  QUESTS GIVEN                          ║")
        for quest in npc["quests_given"]:
            lines.append(f"║  • {quest[:36]:<36} ║")

    if npc["notes"]:
        lines.append("║                                        ║")
        lines.append("║  NOTES                                 ║")
        for note_data in npc["notes"][-3:]:  # Last 3 notes
            note = note_data["note"][:36]
            lines.append(f"║  • {note:<36} ║")

    lines.append("╚════════════════════════════════════════╝")

    return "\n".join(lines)

def get_relationship_description(relationship: int) -> str:
    """Get text description of relationship level."""
    if relationship >= 75:
        return "Best Friends"
    elif relationship >= 50:
        return "Friends"
    elif relationship >= 25:
        return "Friendly"
    elif relationship >= -25:
        return "Neutral"
    elif relationship >= -50:
        return "Unfriendly"
    elif relationship >= -75:
        return "Hostile"
    else:
        return "Enemies"

if __name__ == "__main__":
    if len(sys.argv) < 2:
        print("Usage:")
        print("  npc_memory.py create <name> [type] [location]")
        print("  npc_memory.py conversation <npc_json> <topic> <player_text> <npc_text> <turn> [rel_change]")
        print("  npc_memory.py trade <npc_json> <item> <price> <fair> <turn>")
        print("  npc_memory.py promise <npc_json> <promise_text> <turn>")
        print("  npc_memory.py keep-promise <npc_json> <promise_index>")
        print("  npc_memory.py break-promise <npc_json> <promise_index>")
        print("  npc_memory.py note <npc_json> <note_text>")
        print("  npc_memory.py show <npc_json>")
        sys.exit(1)

    command = sys.argv[1]

    if command == "create":
        name = sys.argv[2]
        npc_type = sys.argv[3] if len(sys.argv) > 3 else "neutral"
        location = sys.argv[4] if len(sys.argv) > 4 else "unknown"

        npc = create_npc(name, npc_type, location)
        print(json.dumps(npc, indent=2))

    elif command == "conversation":
        npc = json.loads(sys.argv[2])
        topic = sys.argv[3]
        player_said = sys.argv[4]
        npc_said = sys.argv[5]
        turn = int(sys.argv[6])
        rel_change = int(sys.argv[7]) if len(sys.argv) > 7 else 0

        npc = record_conversation(npc, topic, player_said, npc_said, turn, rel_change)
        print(f"✓ Recorded conversation with {npc['name']}")
        print(f"  Relationship: {npc['relationship']} ({get_relationship_description(npc['relationship'])})")
        print("\nUpdated NPC:")
        print(json.dumps(npc, indent=2))

    elif command == "trade":
        npc = json.loads(sys.argv[2])
        item = sys.argv[3]
        price = int(sys.argv[4])
        fair = sys.argv[5].lower() in ("true", "yes", "1")
        turn = int(sys.argv[6])

        npc = record_trade(npc, item, price, fair, turn)
        print(f"✓ Recorded trade with {npc['name']}")
        print(f"  Relationship: {npc['relationship']}")

    elif command == "promise":
        npc = json.loads(sys.argv[2])
        promise = sys.argv[3]
        turn = int(sys.argv[4])

        npc = make_promise(npc, promise, turn)
        print(f"✓ Promised to {npc['name']}: {promise}")

    elif command == "keep-promise":
        npc = json.loads(sys.argv[2])
        index = int(sys.argv[3])

        npc = keep_promise(npc, index)
        print(f"✓ Kept promise to {npc['name']}")
        print(f"  Relationship: {npc['relationship']} (+15)")

    elif command == "break-promise":
        npc = json.loads(sys.argv[2])
        index = int(sys.argv[3])

        npc = break_promise(npc, index)
        print(f"✗ Broke promise to {npc['name']}")
        print(f"  Relationship: {npc['relationship']} (-30)")

    elif command == "note":
        npc = json.loads(sys.argv[2])
        note = sys.argv[3]

        npc = add_note(npc, note)
        print(f"✓ Added note about {npc['name']}")

    elif command == "show":
        npc = json.loads(sys.argv[2])
        print(show_npc(npc))

    else:
        print(f"Unknown command: {command}")
        sys.exit(1)
