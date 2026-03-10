#!/usr/bin/env python3
"""
Inventory management for adventure games.
Handles items, weight, capacity, stacking, and equipment.
"""

import json
import sys
from typing import Dict, List, Any, Optional

def create_inventory(capacity: int = 10, weight_limit: float = 100.0) -> Dict[str, Any]:
    """
    Create new inventory.

    Args:
        capacity: Maximum number of item slots
        weight_limit: Maximum weight in pounds/kg

    Returns:
        Empty inventory structure
    """
    return {
        "capacity": capacity,
        "weight_limit": weight_limit,
        "items": [],
        "equipped": {
            "weapon": None,
            "armor": None,
            "accessory": None
        }
    }

def add_item(
    inventory: Dict[str, Any],
    item: Dict[str, Any],
    quantity: int = 1
) -> Dict[str, Any]:
    """
    Add item to inventory.

    Args:
        inventory: Inventory dict
        item: Item dict with name, weight, stackable, etc.
        quantity: Number to add

    Returns:
        Result with success/failure and updated inventory
    """
    # Check if stackable and already exists
    if item.get("stackable", False):
        for inv_item in inventory["items"]:
            if inv_item["name"] == item["name"]:
                inv_item["quantity"] += quantity
                return {
                    "success": True,
                    "message": f"Added {quantity}x {item['name']} (now {inv_item['quantity']})",
                    "inventory": inventory
                }

    # Check capacity
    current_slots = sum(1 for i in inventory["items"] if not i.get("stackable", False))
    if current_slots >= inventory["capacity"]:
        return {
            "success": False,
            "error": "Inventory full",
            "message": f"❌ Cannot add {item['name']}: inventory full ({current_slots}/{inventory['capacity']} slots)",
            "inventory": inventory
        }

    # Check weight
    current_weight = sum(i.get("weight", 0) * i.get("quantity", 1) for i in inventory["items"])
    item_weight = item.get("weight", 0) * quantity
    if current_weight + item_weight > inventory["weight_limit"]:
        return {
            "success": False,
            "error": "Too heavy",
            "message": f"❌ Cannot add {item['name']}: too heavy ({current_weight + item_weight:.1f}/{inventory['weight_limit']} lbs)",
            "inventory": inventory
        }

    # Add item
    new_item = item.copy()
    new_item["quantity"] = quantity
    inventory["items"].append(new_item)

    return {
        "success": True,
        "message": f"✓ Added {quantity}x {item['name']}",
        "inventory": inventory
    }

def remove_item(
    inventory: Dict[str, Any],
    item_name: str,
    quantity: int = 1
) -> Dict[str, Any]:
    """
    Remove item from inventory.

    Args:
        inventory: Inventory dict
        item_name: Name of item to remove
        quantity: Number to remove

    Returns:
        Result with updated inventory
    """
    for i, item in enumerate(inventory["items"]):
        if item["name"] == item_name:
            if item.get("quantity", 1) > quantity:
                item["quantity"] -= quantity
                return {
                    "success": True,
                    "message": f"✓ Removed {quantity}x {item_name} ({item['quantity']} remaining)",
                    "inventory": inventory
                }
            else:
                inventory["items"].pop(i)
                return {
                    "success": True,
                    "message": f"✓ Removed {item_name}",
                    "inventory": inventory
                }

    return {
        "success": False,
        "error": "Item not found",
        "message": f"❌ {item_name} not in inventory",
        "inventory": inventory
    }

def equip_item(
    inventory: Dict[str, Any],
    item_name: str,
    slot: str
) -> Dict[str, Any]:
    """
    Equip item from inventory.

    Args:
        inventory: Inventory dict
        item_name: Name of item to equip
        slot: Equipment slot (weapon, armor, accessory)

    Returns:
        Result with updated inventory
    """
    # Find item
    item = None
    for inv_item in inventory["items"]:
        if inv_item["name"] == item_name:
            item = inv_item
            break

    if not item:
        return {
            "success": False,
            "error": "Item not found",
            "message": f"❌ {item_name} not in inventory",
            "inventory": inventory
        }

    # Check if item can be equipped in this slot
    if item.get("type") != slot:
        return {
            "success": False,
            "error": "Wrong slot",
            "message": f"❌ {item_name} cannot be equipped as {slot} (it's a {item.get('type', 'unknown')})",
            "inventory": inventory
        }

    # Unequip current item in slot
    if inventory["equipped"][slot]:
        old_item = inventory["equipped"][slot]
        message = f"✓ Unequipped {old_item['name']}, equipped {item_name}"
    else:
        message = f"✓ Equipped {item_name}"

    # Equip new item
    inventory["equipped"][slot] = item

    return {
        "success": True,
        "message": message,
        "inventory": inventory
    }

def unequip_item(inventory: Dict[str, Any], slot: str) -> Dict[str, Any]:
    """
    Unequip item from slot.

    Args:
        inventory: Inventory dict
        slot: Equipment slot

    Returns:
        Result with updated inventory
    """
    if not inventory["equipped"][slot]:
        return {
            "success": False,
            "error": "Nothing equipped",
            "message": f"❌ No {slot} equipped",
            "inventory": inventory
        }

    item = inventory["equipped"][slot]
    inventory["equipped"][slot] = None

    return {
        "success": True,
        "message": f"✓ Unequipped {item['name']}",
        "inventory": inventory
    }

def show_inventory(inventory: Dict[str, Any]) -> str:
    """
    Format inventory as readable text.

    Args:
        inventory: Inventory dict

    Returns:
        Formatted string
    """
    lines = []
    lines.append("╔════════════════════════════════════════╗")
    lines.append("║           INVENTORY                    ║")
    lines.append("╠════════════════════════════════════════╣")

    # Equipped items
    lines.append("║  EQUIPPED                              ║")
    for slot, item in inventory["equipped"].items():
        if item:
            lines.append(f"║  {slot.capitalize():<10}: {item['name']:<24} ║")
        else:
            lines.append(f"║  {slot.capitalize():<10}: (none)                  ║")

    # Inventory items
    lines.append("║                                        ║")
    lines.append("║  ITEMS                                 ║")

    if not inventory["items"]:
        lines.append("║  (empty)                               ║")
    else:
        for item in inventory["items"]:
            qty = f"x{item.get('quantity', 1)}" if item.get('stackable') else ""
            weight = f"{item.get('weight', 0):.1f}lb" if item.get('weight') else ""
            name = item['name'][:25]  # Truncate long names
            lines.append(f"║  • {name:<25} {qty:>4} {weight:>6} ║")

    # Stats
    lines.append("║                                        ║")
    current_slots = len([i for i in inventory["items"] if not i.get("stackable", False)])
    current_weight = sum(i.get("weight", 0) * i.get("quantity", 1) for i in inventory["items"])
    lines.append(f"║  Capacity: {current_slots}/{inventory['capacity']} slots               ║")
    lines.append(f"║  Weight: {current_weight:.1f}/{inventory['weight_limit']} lbs                ║")

    lines.append("╚════════════════════════════════════════╝")

    return "\n".join(lines)

if __name__ == "__main__":
    if len(sys.argv) < 2:
        print("Usage:")
        print("  inventory.py create [capacity] [weight_limit]")
        print("  inventory.py add <inventory_json> <item_json> [quantity]")
        print("  inventory.py remove <inventory_json> <item_name> [quantity]")
        print("  inventory.py equip <inventory_json> <item_name> <slot>")
        print("  inventory.py unequip <inventory_json> <slot>")
        print("  inventory.py show <inventory_json>")
        sys.exit(1)

    command = sys.argv[1]

    if command == "create":
        capacity = int(sys.argv[2]) if len(sys.argv) > 2 else 10
        weight_limit = float(sys.argv[3]) if len(sys.argv) > 3 else 100.0

        inventory = create_inventory(capacity, weight_limit)
        print(json.dumps(inventory, indent=2))

    elif command == "add":
        inventory = json.loads(sys.argv[2])
        item = json.loads(sys.argv[3])
        quantity = int(sys.argv[4]) if len(sys.argv) > 4 else 1

        result = add_item(inventory, item, quantity)
        print(result["message"])
        print("\nUpdated inventory:")
        print(json.dumps(result["inventory"], indent=2))

    elif command == "remove":
        inventory = json.loads(sys.argv[2])
        item_name = sys.argv[3]
        quantity = int(sys.argv[4]) if len(sys.argv) > 4 else 1

        result = remove_item(inventory, item_name, quantity)
        print(result["message"])

    elif command == "equip":
        inventory = json.loads(sys.argv[2])
        item_name = sys.argv[3]
        slot = sys.argv[4]

        result = equip_item(inventory, item_name, slot)
        print(result["message"])

    elif command == "unequip":
        inventory = json.loads(sys.argv[2])
        slot = sys.argv[3]

        result = unequip_item(inventory, slot)
        print(result["message"])

    elif command == "show":
        inventory = json.loads(sys.argv[2])
        print(show_inventory(inventory))

    else:
        print(f"Unknown command: {command}")
        sys.exit(1)
