# OpenClaw Troubleshooting - 400 & Menu Errors

## Errors You're Seeing

### Error 1: `-m, --message <text>` not specified
This happens when OpenClaw tries to invoke a CLI command that needs a message parameter.

### Error 2: `400 "auto" tool choice requires...`
This happens when OpenClaw tries to use tool/function calling, which vLLM doesn't support.

## ✅ Complete Fix Applied

I've updated your config to:
1. ✅ Disable `supportsToolUse` on the model
2. ✅ Disable all web tools (fetch, search)
3. ✅ Set `api: "openai-completions"` (text-only mode)
4. ✅ Disable tools at agent level

## 🔄 Clean Restart Procedure

**As ttclaw user:**

### Step 1: Clean restart
```bash
sudo su - ttclaw
~/restart-openclaw.sh
```

This will:
- Stop the gateway
- Clear old sessions
- Verify config
- Start fresh gateway

### Step 2: In NEW terminal, start TUI
```bash
sudo su - ttclaw
cd ~/openclaw
./openclaw.sh tui
```

### Step 3: Using the TUI Correctly

**When you see the menu:**
1. Use arrow keys to select an agent (e.g., "Chip Quest")
2. Press Enter to select
3. **Wait for the agent to load**
4. You should see a prompt like: `>`
5. **Type your message directly** (don't use menu commands)
6. Press Enter

**Example conversation:**
```
> Hello, what is this place?
[LLM generates response]

> Look around
[LLM generates response]

> Go north
[LLM generates response]
```

## Alternative: Use Direct Chat Mode

If the TUI menu still causes issues, try the direct chat command:

```bash
cd ~/openclaw
./openclaw.sh chat -a chip-quest -m "Hello, describe this place"
```

This bypasses the menu and sends a message directly.

## Verify Config is Loaded

```bash
cat ~/.openclaw/openclaw.json | jq '.models.providers.vllm.models[0].supportsToolUse'
# Should output: false

cat ~/.openclaw/openclaw.json | jq '.tools.web.fetch.enabled'
# Should output: false
```

## Check Logs

If still having issues, check the gateway logs:
```bash
cd ~/openclaw
./openclaw.sh gateway logs
```

Look for errors about:
- Tool calling
- Function calling
- API mode mismatches

## Manual Test (Without OpenClaw)

Verify vLLM is working directly:
```bash
curl -sS http://localhost:8000/v1/completions \
  -H "Content-Type: application/json" \
  -d '{
    "model": "meta-llama/Llama-3.1-8B-Instruct",
    "prompt": "You are in a dark dungeon.",
    "max_tokens": 50
  }' | jq -r '.choices[0].text'
```

Should generate text without errors.

## Still Not Working?

Try the most minimal setup:
1. Stop everything: `~/openclaw/openclaw.sh gateway stop`
2. Start gateway manually: `cd ~/openclaw && ./openclaw.sh gateway run`
3. In NEW terminal: `./openclaw.sh chat -a main -m "test message"`

This uses the default 'main' agent with a simple message.

## Nuclear Option: Fresh Config

If all else fails, we can regenerate the OpenClaw config from scratch:
```bash
# Backup current config
cp ~/.openclaw/openclaw.json ~/.openclaw/openclaw.json.backup

# Run OpenClaw wizard to reconfigure
cd ~/openclaw
./openclaw.sh configure
```

During wizard:
- Choose "local" mode
- Select vLLM provider
- Set URL: `http://127.0.0.1:8000/v1`
- Set API mode: `openai-completions`
- API key: `sk-no-auth`

Let me know which step fails and I'll help debug further! 🔧
