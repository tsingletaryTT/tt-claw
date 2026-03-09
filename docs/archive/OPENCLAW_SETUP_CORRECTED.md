# OpenClaw Setup - Corrected Instructions

## What We Learned

OpenClaw v2026.3.2 is a **full agent framework** with:
- Gateway service (WebSocket server)
- Agent workspace with skills
- Channel integrations (WhatsApp, Telegram, Discord, etc.)
- Complex configuration managed by wizards

It's NOT a simple LLM client - it's much more powerful!

## Current Status (2026-03-06)

✅ **Already Installed:**
- OpenClaw v2026.3.2 at `/home/ttclaw/openclaw/node_modules/`
- Node.js v24.14.0 and npm 11.9.0
- Wrapper script at `/home/ttclaw/openclaw/openclaw.sh`
- vLLM server running at http://127.0.0.1:8000
- JWT bearer token in `/home/ttclaw/openclaw/.env`

⚠️ **Configuration Issue:**
- The `openclaw.json` file we created has incorrect format
- OpenClaw expects configuration to be created by its onboarding wizard
- Need to run the proper setup process

## Correct Setup Process

### Step 1: Switch to ttclaw User

```bash
sudo -u ttclaw -i
cd /home/ttclaw/openclaw
```

### Step 2: Load the Bearer Token

```bash
# Get the bearer token
source /home/ttclaw/openclaw/.env
echo $VLLM_API_KEY
```

Copy this token - you'll need it during onboarding.

### Step 3: Run the Onboarding Wizard

#### Option A: Interactive Onboarding (Recommended)

```bash
./openclaw.sh onboard --install-daemon
```

When prompted:
1. **Auth choice**: Select "Custom API endpoint" or enter `custom-api-key`
2. **Custom base URL**: `http://127.0.0.1:8000/v1`
3. **Custom API key**: Paste the JWT bearer token from .env file
4. **Custom model ID**: `meta-llama/Llama-3.1-8B-Instruct`
5. **API compatibility**: `openai`
6. **Workspace**: `/home/ttclaw/openclaw/workspace` (or accept default `~/.openclaw/workspace`)
7. **Install daemon**: Yes (to run as background service)

#### Option B: Non-Interactive Onboarding

```bash
# Set the bearer token first
source /home/ttclaw/openclaw/.env

# Run onboarding with all parameters
./openclaw.sh onboard \
  --non-interactive \
  --accept-risk \
  --auth-choice custom-api-key \
  --custom-base-url http://127.0.0.1:8000/v1 \
  --custom-api-key "$VLLM_API_KEY" \
  --custom-model-id "meta-llama/Llama-3.1-8B-Instruct" \
  --custom-compatibility openai \
  --workspace /home/ttclaw/openclaw/workspace \
  --install-daemon
```

### Step 4: Verify Setup

```bash
# Check configuration
./openclaw.sh config status

# Check if gateway is running
./openclaw.sh gateway status

# Check configured models
./openclaw.sh models status
```

### Step 5: Test with Agent

OpenClaw doesn't have a simple "ask" command. Instead, it uses:

```bash
# Option 1: Terminal UI (interactive)
./openclaw.sh tui

# Option 2: Agent command (one-shot)
./openclaw.sh agent --message "Hello, what is 2+2?"

# Option 3: Start gateway and use message command
./openclaw.sh gateway start
./openclaw.sh message send --target @self --message "What is 2+2?"
```

## How OpenClaw Works

### Architecture

```
┌─────────────────┐
│   OpenClaw CLI  │  (openclaw.sh)
└────────┬────────┘
         │
         ▼
┌─────────────────┐
│  Gateway Server │  (WebSocket on port 18000)
│   (daemon/node) │
└────────┬────────┘
         │
         ├─────► Agent Workspace (/home/ttclaw/openclaw/workspace)
         │         • Skills (code execution, file ops, etc.)
         │         • Memory
         │         • Sessions
         │
         ├─────► LLM Provider (vLLM at http://127.0.0.1:8000/v1)
         │         • Llama-3.1-8B-Instruct
         │         • OpenAI-compatible API
         │
         └─────► Channels (optional)
                   • WhatsApp
                   • Telegram
                   • Discord
                   • etc.
```

### Key Components

1. **Gateway**: Background service that manages:
   - Agent execution
   - LLM requests
   - Channel integrations
   - Authentication

2. **Agent**: AI assistant with access to:
   - File system operations
   - Code execution
   - Web browsing (with browser command)
   - Custom skills

3. **Workspace**: Directory containing:
   - Agent configuration (AGENTS.md, SOUL.md)
   - Memory files
   - Session history
   - Custom skills

4. **Channels**: Optional integrations for:
   - WhatsApp (personal or business)
   - Telegram bots
   - Discord bots
   - Slack apps

## Common Commands

### Gateway Management

```bash
# Start gateway
./openclaw.sh gateway start

# Check status
./openclaw.sh gateway status

# View logs
./openclaw.sh logs

# Health check
./openclaw.sh health

# Stop gateway
./openclaw.sh gateway stop
```

### Agent Interaction

```bash
# Terminal UI (best for interactive use)
./openclaw.sh tui

# Single agent turn
./openclaw.sh agent --message "Your query here"

# Send message to yourself
./openclaw.sh message send --target @self --message "Hello"
```

### Configuration

```bash
# View current config
./openclaw.sh config status

# List configured models
./openclaw.sh models list

# Check model status
./openclaw.sh models status

# View workspace
ls -la ~/.openclaw/workspace/
# or
ls -la /home/ttclaw/openclaw/workspace/
```

### Skills & Capabilities

```bash
# List available skills
./openclaw.sh skills list

# Check agent capabilities
./openclaw.sh doctor
```

## Important Differences from Simple LLM Clients

| Feature | Simple LLM Client | OpenClaw |
|---------|-------------------|----------|
| Usage | `client ask "question"` | `openclaw tui` or `openclaw agent --message "..."` |
| Architecture | Direct API calls | Gateway + Agent + Skills |
| Configuration | Simple API key | Full onboarding wizard |
| Capabilities | Just LLM queries | File ops, code exec, web browsing, channels |
| Persistence | None | Sessions, memory, workspace |
| Background Service | No | Yes (gateway daemon) |

## Next Steps

1. **Run onboarding**: Use one of the methods in Step 3 above
2. **Start gateway**: `./openclaw.sh gateway start`
3. **Test in TUI**: `./openclaw.sh tui`
4. **Try agent commands**: Test file operations, code execution, etc.
5. **Configure channels** (optional): Set up WhatsApp, Telegram, etc.
6. **Customize workspace**: Edit AGENTS.md and SOUL.md to customize personality

## Troubleshooting

### "Invalid config" errors

**Solution**: Delete the old config and run onboarding:
```bash
rm /home/ttclaw/openclaw/openclaw.json
./openclaw.sh onboard
```

### Gateway won't start

**Check:**
1. Port 18000 is not already in use: `netstat -tlnp | grep 18000`
2. Workspace directory exists: `ls -la /home/ttclaw/openclaw/workspace/`
3. Node.js is accessible: `node --version`

### "Command not found: ask"

**Explanation**: OpenClaw doesn't have an `ask` command. Use:
- `./openclaw.sh tui` for interactive mode
- `./openclaw.sh agent --message "..."` for one-shot queries

### vLLM connection errors

**Check:**
1. vLLM server is running: `curl http://127.0.0.1:8000/health`
2. Bearer token is correct: Check `~/.openclaw/openclaw.json` or config
3. Model name matches: `meta-llama/Llama-3.1-8B-Instruct`

## Resources

- **OpenClaw Docs**: https://docs.openclaw.ai
- **CLI Reference**: https://docs.openclaw.ai/cli
- **Models Config**: https://docs.openclaw.ai/cli/models
- **Gateway**: https://docs.openclaw.ai/gateway
- **Agent Skills**: https://docs.openclaw.ai/skills

## Files Created

- `/home/ttuser/OPENCLAW_INSTALLATION_GUIDE.md` - Original guide (some info outdated)
- `/home/ttuser/OPENCLAW_QUICK_REFERENCE.md` - Quick reference (needs updating)
- `/home/ttuser/OPENCLAW_SETUP_CORRECTED.md` - This file (correct instructions)
- `/home/ttuser/.local/bin/test-openclaw` - Test script (needs updating for new commands)

---

**Updated**: 2026-03-06
**OpenClaw Version**: 2026.3.2
