#!/usr/bin/env python3
"""
Save/load game state for adventure games.
Handles character persistence, game state, and progress.
"""

import json
import os
import sys
from datetime import datetime
from pathlib import Path
from typing import Dict, Any, Optional

SAVE_DIR = Path.home() / ".openclaw" / "saves" / "adventure-games"

def ensure_save_dir():
    """Create save directory if it doesn't exist."""
    SAVE_DIR.mkdir(parents=True, exist_ok=True)

def save_game(
    game_name: str,
    slot: str,
    data: Dict[str, Any],
    description: str = ""
) -> Dict[str, Any]:
    """
    Save game state to disk.

    Args:
        game_name: Name of game (chip-quest, terminal-dungeon, conference-chaos)
        slot: Save slot name (e.g., "slot1", "autosave", "quicksave")
        data: Game state data (character, world state, etc.)
        description: Optional description of save

    Returns:
        Save metadata
    """
    ensure_save_dir()

    save_file = SAVE_DIR / f"{game_name}_{slot}.json"

    # Add metadata
    save_data = {
        "metadata": {
            "game": game_name,
            "slot": slot,
            "timestamp": datetime.now().isoformat(),
            "description": description,
            "version": "1.0"
        },
        "data": data
    }

    # Write to file
    with open(save_file, 'w') as f:
        json.dump(save_data, f, indent=2)

    return {
        "success": True,
        "file": str(save_file),
        "timestamp": save_data["metadata"]["timestamp"],
        "formatted": f"Game saved to {slot} at {save_data['metadata']['timestamp']}"
    }

def load_game(game_name: str, slot: str) -> Dict[str, Any]:
    """
    Load game state from disk.

    Args:
        game_name: Name of game
        slot: Save slot name

    Returns:
        Game state data or error
    """
    save_file = SAVE_DIR / f"{game_name}_{slot}.json"

    if not save_file.exists():
        return {
            "success": False,
            "error": f"Save file not found: {slot}",
            "formatted": f"❌ No save found in slot '{slot}'"
        }

    try:
        with open(save_file, 'r') as f:
            save_data = json.load(f)

        return {
            "success": True,
            "metadata": save_data["metadata"],
            "data": save_data["data"],
            "formatted": f"✓ Loaded save from {slot} ({save_data['metadata']['timestamp']})"
        }
    except Exception as e:
        return {
            "success": False,
            "error": str(e),
            "formatted": f"❌ Failed to load save: {e}"
        }

def list_saves(game_name: str) -> Dict[str, Any]:
    """
    List all saves for a game.

    Args:
        game_name: Name of game

    Returns:
        List of save metadata
    """
    ensure_save_dir()

    saves = []
    pattern = f"{game_name}_*.json"

    for save_file in SAVE_DIR.glob(pattern):
        try:
            with open(save_file, 'r') as f:
                save_data = json.load(f)
                saves.append({
                    "slot": save_data["metadata"]["slot"],
                    "timestamp": save_data["metadata"]["timestamp"],
                    "description": save_data["metadata"]["description"],
                    "file": str(save_file)
                })
        except Exception as e:
            print(f"Warning: Could not read {save_file}: {e}", file=sys.stderr)

    # Sort by timestamp (newest first)
    saves.sort(key=lambda x: x["timestamp"], reverse=True)

    formatted_lines = [f"Saves for {game_name}:"]
    for save in saves:
        formatted_lines.append(f"  • {save['slot']}: {save['timestamp']}")
        if save['description']:
            formatted_lines.append(f"    {save['description']}")

    return {
        "success": True,
        "saves": saves,
        "count": len(saves),
        "formatted": "\n".join(formatted_lines) if saves else f"No saves found for {game_name}"
    }

def delete_save(game_name: str, slot: str) -> Dict[str, Any]:
    """
    Delete a save file.

    Args:
        game_name: Name of game
        slot: Save slot name

    Returns:
        Success/failure
    """
    save_file = SAVE_DIR / f"{game_name}_{slot}.json"

    if not save_file.exists():
        return {
            "success": False,
            "error": "Save not found",
            "formatted": f"❌ No save found in slot '{slot}'"
        }

    try:
        save_file.unlink()
        return {
            "success": True,
            "formatted": f"✓ Deleted save: {slot}"
        }
    except Exception as e:
        return {
            "success": False,
            "error": str(e),
            "formatted": f"❌ Failed to delete save: {e}"
        }

def autosave(game_name: str, data: Dict[str, Any]) -> Dict[str, Any]:
    """
    Quick autosave (overwrites autosave slot).

    Args:
        game_name: Name of game
        data: Game state

    Returns:
        Save result
    """
    return save_game(game_name, "autosave", data, "Autosave")

if __name__ == "__main__":
    if len(sys.argv) < 2:
        print("Usage:")
        print("  save_game.py save <game> <slot> <json_data> [description]")
        print("  save_game.py load <game> <slot>")
        print("  save_game.py list <game>")
        print("  save_game.py delete <game> <slot>")
        print("  save_game.py autosave <game> <json_data>")
        print("")
        print("Games: chip-quest, terminal-dungeon, conference-chaos")
        sys.exit(1)

    command = sys.argv[1]

    if command == "save":
        if len(sys.argv) < 5:
            print("Usage: save_game.py save <game> <slot> <json_data> [description]")
            sys.exit(1)

        game = sys.argv[2]
        slot = sys.argv[3]
        data = json.loads(sys.argv[4])
        description = sys.argv[5] if len(sys.argv) > 5 else ""

        result = save_game(game, slot, data, description)
        print(result["formatted"])

    elif command == "load":
        if len(sys.argv) < 4:
            print("Usage: save_game.py load <game> <slot>")
            sys.exit(1)

        game = sys.argv[2]
        slot = sys.argv[3]

        result = load_game(game, slot)
        print(result["formatted"])
        if result["success"]:
            print("\nData:")
            print(json.dumps(result["data"], indent=2))

    elif command == "list":
        if len(sys.argv) < 3:
            print("Usage: save_game.py list <game>")
            sys.exit(1)

        game = sys.argv[2]
        result = list_saves(game)
        print(result["formatted"])

    elif command == "delete":
        if len(sys.argv) < 4:
            print("Usage: save_game.py delete <game> <slot>")
            sys.exit(1)

        game = sys.argv[2]
        slot = sys.argv[3]

        result = delete_save(game, slot)
        print(result["formatted"])

    elif command == "autosave":
        if len(sys.argv) < 4:
            print("Usage: save_game.py autosave <game> <json_data>")
            sys.exit(1)

        game = sys.argv[2]
        data = json.loads(sys.argv[3])

        result = autosave(game, data)
        print(result["formatted"])

    else:
        print(f"Unknown command: {command}")
        sys.exit(1)
