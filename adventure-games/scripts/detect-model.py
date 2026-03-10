#!/usr/bin/env python3
"""
Auto-detect available vLLM models and configure OpenClaw

Queries localhost:8000 or 8001 for available models and automatically
configures OpenClaw to use the first available model.

Features:
- Adapts to any model (8B, 70B, Qwen, Llama, DeepSeek, etc.)
- Auto-detects context window size
- Can be overridden via environment variable
- Updates OpenClaw config automatically

Usage:
    python3 detect-model.py                    # Auto-detect and update config
    python3 detect-model.py --dry-run          # Just show what would be detected
    OPENCLAW_MODEL="specific/model" python3 detect-model.py  # Override
"""

import json
import os
import sys
import argparse
import urllib.request
import urllib.error
from pathlib import Path

# Configuration
VLLM_PORTS = [8001, 8000]  # Try proxy first, then direct
OPENCLAW_CONFIG = Path("/home/ttclaw/.openclaw/openclaw.json")
BACKUP_SUFFIX = ".backup"

# Model context window defaults (if not provided by API)
DEFAULT_CONTEXT_WINDOWS = {
    "llama-3.1": 65536,    # Llama 3.1 has 128K but use conservative 64K
    "llama-3.2": 32768,
    "llama-3.3": 131072,   # Llama 3.3 has 128K
    "deepseek": 131072,    # DeepSeek-R1 has 128K
    "qwen": 32768,         # Qwen 2.5 varies, use conservative
    "mistral": 32768,
    "default": 32768       # Safe default
}

def query_vllm_models(port=8001):
    """Query vLLM for available models"""
    url = f"http://127.0.0.1:{port}/v1/models"

    try:
        with urllib.request.urlopen(url, timeout=5) as response:
            data = json.loads(response.read())
            if "data" in data and len(data["data"]) > 0:
                return data["data"]
    except (urllib.error.URLError, urllib.error.HTTPError, TimeoutError) as e:
        pass

    return None

def detect_available_model():
    """Detect first available model from vLLM"""
    # Check for override
    override = os.environ.get("OPENCLAW_MODEL")
    if override:
        print(f"🎯 Using override model: {override}")
        return {"id": override, "source": "environment"}

    # Try both ports
    for port in VLLM_PORTS:
        print(f"🔍 Checking localhost:{port}/v1/models...")
        models = query_vllm_models(port)

        if models:
            model = models[0]
            model_id = model.get("id")
            print(f"✅ Found model: {model_id}")

            # Extract info
            info = {
                "id": model_id,
                "port": port,
                "source": "detected",
                "raw": model
            }

            return info

    return None

def guess_context_window(model_id):
    """Guess context window size based on model name"""
    model_lower = model_id.lower()

    for key, window in DEFAULT_CONTEXT_WINDOWS.items():
        if key in model_lower:
            return window

    return DEFAULT_CONTEXT_WINDOWS["default"]

def create_model_config(model_info):
    """Create OpenClaw model configuration"""
    model_id = model_info["id"]

    # Guess context window
    context_window = guess_context_window(model_id)

    # Determine max tokens (typically 1/4 of context window for output)
    max_tokens = min(8192, context_window // 4)

    # Determine if it's a reasoning model
    is_reasoning = any(x in model_id.lower() for x in ["deepseek-r1", "o1", "reasoning"])

    # Friendly name
    name_parts = model_id.split("/")[-1].replace("-", " ").title()

    config = {
        "id": model_id,
        "name": name_parts,
        "reasoning": is_reasoning,
        "input": ["text"],
        "cost": {
            "input": 0,
            "output": 0
        },
        "contextWindow": context_window,
        "maxTokens": max_tokens
    }

    return config

def update_openclaw_config(model_config, dry_run=False):
    """Update OpenClaw configuration with detected model"""
    if not OPENCLAW_CONFIG.exists():
        print(f"❌ Config not found: {OPENCLAW_CONFIG}")
        return False

    # Read current config
    with open(OPENCLAW_CONFIG, 'r') as f:
        config = json.load(f)

    # Backup
    if not dry_run:
        backup_path = OPENCLAW_CONFIG.with_suffix(OPENCLAW_CONFIG.suffix + BACKUP_SUFFIX)
        with open(backup_path, 'w') as f:
            json.dump(config, f, indent=2)
        print(f"💾 Backed up config to: {backup_path}")

    # Update models
    if "models" not in config:
        config["models"] = {}
    if "providers" not in config["models"]:
        config["models"]["providers"] = {}
    if "vllm" not in config["models"]["providers"]:
        config["models"]["providers"]["vllm"] = {}

    # Set model
    config["models"]["providers"]["vllm"]["models"] = [model_config]

    # Update default agent model
    model_ref = f"vllm/{model_config['id']}"
    if "agents" not in config:
        config["agents"] = {}
    if "defaults" not in config["agents"]:
        config["agents"]["defaults"] = {}
    if "model" not in config["agents"]["defaults"]:
        config["agents"]["defaults"]["model"] = {}

    config["agents"]["defaults"]["model"]["primary"] = model_ref

    if dry_run:
        print("\n📋 Would update config to:")
        print(json.dumps(model_config, indent=2))
        return True

    # Write updated config
    with open(OPENCLAW_CONFIG, 'w') as f:
        json.dump(config, f, indent=2)

    print(f"✅ Updated config: {OPENCLAW_CONFIG}")
    return True

def main():
    parser = argparse.ArgumentParser(description="Auto-detect vLLM model for OpenClaw")
    parser.add_argument("--dry-run", action="store_true", help="Show detection without updating config")
    parser.add_argument("--port", type=int, help="Specific port to check (8000 or 8001)")
    parser.add_argument("--quiet", action="store_true", help="Minimal output (for scripts)")
    parser.add_argument("--progress", action="store_true", help="Show progress indicators")
    args = parser.parse_args()

    # Quiet mode: only errors
    quiet = args.quiet
    progress = args.progress

    if not quiet:
        print("🎮 OpenClaw Model Auto-Detection")
        print("=" * 50)

    # Override ports if specified
    if args.port:
        global VLLM_PORTS
        VLLM_PORTS = [args.port]

    # Detect model with progress
    if progress and not quiet:
        import time
        sys.stdout.write("🔍 Checking vLLM endpoints")
        sys.stdout.flush()
        for i in range(3):
            sys.stdout.write(".")
            sys.stdout.flush()
            time.sleep(0.3)
        sys.stdout.write("\n")

    model_info = detect_available_model()

    if not model_info:
        if not quiet:
            print("\n❌ No model detected!")
            print("\nTroubleshooting:")
            print("  1. Ensure vLLM is running: curl http://localhost:8000/v1/models")
            print("  2. Check proxy is running: curl http://localhost:8001/v1/models")
            print("  3. Override manually: OPENCLAW_MODEL='your/model' python3 detect-model.py")
        sys.exit(1)

    # Create config
    model_config = create_model_config(model_info)

    if not quiet:
        print("\n📊 Detected Model Configuration:")
        print(f"  Model: {model_config['name']}")
        print(f"  ID: {model_config['id']}")
        print(f"  Context Window: {model_config['contextWindow']:,} tokens")
        print(f"  Max Output: {model_config['maxTokens']:,} tokens")
        print(f"  Reasoning: {model_config['reasoning']}")
        if model_info.get("port"):
            print(f"  Port: {model_info['port']}")

    # Update config with progress
    if progress and not quiet:
        import time
        sys.stdout.write("💾 Updating configuration")
        sys.stdout.flush()
        for i in range(3):
            sys.stdout.write(".")
            sys.stdout.flush()
            time.sleep(0.2)
        sys.stdout.write("\n")

    if update_openclaw_config(model_config, dry_run=args.dry_run):
        if not args.dry_run:
            if quiet:
                print(model_config['id'])  # Just model ID for scripts
            else:
                print("\n✅ OpenClaw configured successfully!")
                print("\n🎯 Ready to play:")
                print("  cd /home/ttclaw/openclaw")
                print("  ./adventure-menu.sh")
    else:
        if not quiet:
            print("\n❌ Failed to update configuration")
        sys.exit(1)

if __name__ == "__main__":
    main()
