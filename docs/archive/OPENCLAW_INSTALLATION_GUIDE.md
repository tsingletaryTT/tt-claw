# OpenClaw Installation Guide (Self-Service)

## Context

You want to install OpenClaw yourself for practice. The infrastructure is already complete:
- ✅ vLLM server running at http://127.0.0.1:8000 (Llama-3.1-8B-Instruct)
- ✅ ttclaw user configured with JWT bearer token authentication
- ✅ OpenClaw configuration ready at `/home/ttclaw/openclaw/openclaw.json`

Now you need to install the OpenClaw application itself as the ttclaw user.

## System Status

**Already Installed:**
- Node.js v24.14.0 ✅ (requirement: Node.js 22+)
- npm 11.9.0 ✅
- Both accessible by ttclaw user ✅

**References:**
- [OpenClaw npm package](https://www.npmjs.com/package/openclaw)
- [Official installation docs](https://docs.openclaw.ai/install)
- [Installation guide 2026](https://medium.com/@guljabeen222/how-to-install-openclaw-2026-the-complete-step-by-step-guide-516b74c163b9)

## Installation Steps

### Step 1: Switch to ttclaw User

```bash
sudo -u ttclaw -i
# OR
su - ttclaw  # if you have the password
```

You should now be at `/home/ttclaw` with the ttclaw shell prompt.

### Step 2: Navigate to OpenClaw Directory

```bash
cd /home/ttclaw/openclaw
```

This keeps all OpenClaw files (code, config, workspace) in one place.

### Step 3: Install OpenClaw Locally (Self-Contained)

Install OpenClaw as a local package within the openclaw directory:

```bash
# Initialize a minimal package.json if needed
npm init -y

# Install openclaw as a local dependency
npm install openclaw@latest

# Create a convenient wrapper script that includes config path
cat > openclaw.sh << 'EOF'
#!/bin/bash
cd /home/ttclaw/openclaw
export OPENCLAW_CONFIG_PATH=/home/ttclaw/openclaw/openclaw.json
exec npx openclaw "$@"
EOF

chmod +x openclaw.sh
```

**Expected output:**
- Download progress bars
- Installation to `/home/ttclaw/openclaw/node_modules/openclaw`
- Binary accessible via `npx openclaw` or `./openclaw.sh`

**Time estimate:** 1-3 minutes

**Benefits:**
- Everything in one directory: `/home/ttclaw/openclaw/`
- No PATH modifications needed
- Easy to remove (just delete the directory)
- No pollution of home directory

### Step 4: Verify Installation

```bash
# From within /home/ttclaw/openclaw directory:
npx openclaw --version

# Or using the wrapper:
./openclaw.sh --version
```

**Expected output:** Version number (e.g., `2026.3.2` or similar)

### Optional: Add to PATH (if you want to run from anywhere)

```bash
# Add openclaw directory to PATH
echo 'export PATH="/home/ttclaw/openclaw:$PATH"' >> ~/.bashrc
source ~/.bashrc

# Now you can run from anywhere:
openclaw.sh --version
```

### Step 5: Run Onboarding Wizard

```bash
# From /home/ttclaw/openclaw directory:
# Set config path and run onboarding
export OPENCLAW_CONFIG_PATH=/home/ttclaw/openclaw/openclaw.json
npx openclaw onboard --install-daemon

# Or using wrapper (config path already set):
./openclaw.sh onboard --install-daemon
```

This interactive wizard will ask you:

**A. LLM Provider Configuration:**
- **Provider**: Choose "Custom OpenAI-compatible endpoint" or "Other"
- **Base URL**: `http://127.0.0.1:8000/v1`
- **API Key**: The JWT bearer token from `/home/ttclaw/openclaw/.env`:
  ```
  eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJ0ZWFtX2lkIjoidGVuc3RvcnJlbnQiLCJ0b2tlbl9pZCI6ImRlYnVnLXRlc3QifQ.1lld0aSjreLgWYQfNCSHZOBfw0uPiQU5hGCc9SUgBVA
  ```
- **Model**: `meta-llama/Llama-3.1-8B-Instruct`

**B. Workspace Configuration:**
- **Workspace path**: `/home/ttclaw/openclaw/workspace`
- The wizard may create this directory or use an existing one

**C. Gateway/Channels (Optional for now):**
- You can skip channel setup (WhatsApp, Slack, etc.) initially
- Just configure the core LLM for testing

**D. Daemon Installation:**
- The `--install-daemon` flag will set up OpenClaw to run as a background service
- This allows it to be always available

### Step 6: Alternative - Manual Configuration

If the onboarding wizard doesn't support custom endpoints well, you can use the existing config file.

OpenClaw uses the **`OPENCLAW_CONFIG_PATH` environment variable** to specify a custom config location ([docs](https://docs.openclaw.ai/help/environment)):

```bash
# Option 1: Set environment variable and start OpenClaw
export OPENCLAW_CONFIG_PATH=/home/ttclaw/openclaw/openclaw.json
npx openclaw

# Option 2: Set it inline
OPENCLAW_CONFIG_PATH=/home/ttclaw/openclaw/openclaw.json npx openclaw

# Option 3: Add to bashrc for persistence
echo 'export OPENCLAW_CONFIG_PATH=/home/ttclaw/openclaw/openclaw.json' >> ~/.bashrc
source ~/.bashrc
npx openclaw
```

Update the wrapper script to use this:
```bash
# Update openclaw.sh to include config path
cat > openclaw.sh << 'EOF'
#!/bin/bash
cd /home/ttclaw/openclaw
export OPENCLAW_CONFIG_PATH=/home/ttclaw/openclaw/openclaw.json
exec npx openclaw "$@"
EOF

chmod +x openclaw.sh
```

### Step 7: Test OpenClaw

After installation, test that OpenClaw can communicate with the vLLM server:

```bash
# Make sure you're in /home/ttclaw/openclaw

# Option 1: Interactive mode
npx openclaw chat
# Or: ./openclaw.sh chat

# Then type something like: "Hello, what's 2+2?"
```

**Expected:** OpenClaw should respond using the local Llama model

```bash
# Option 2: Single query
npx openclaw ask "What is the capital of France?"
# Or: ./openclaw.sh ask "What is the capital of France?"
```

**Expected:** Response generated by your local Llama-3.1-8B-Instruct model

### Step 8: Verify Configuration

```bash
# Check which config OpenClaw is using
npx openclaw config show
# Or: ./openclaw.sh config show

# Or check the config file directly
cat /home/ttclaw/openclaw/openclaw.json
```

Verify it shows:
- Base URL: `http://127.0.0.1:8000/v1`
- API key is set (from environment variable)
- Model: `meta-llama/Llama-3.1-8B-Instruct`

## Troubleshooting

### Issue: "Command not found: openclaw"

**This should NOT happen** with the local installation approach.

**If using npx:**
```bash
# npx should always work from the openclaw directory
cd /home/ttclaw/openclaw
npx openclaw --version
```

**If using wrapper script:**
```bash
# Ensure script is executable
chmod +x /home/ttclaw/openclaw/openclaw.sh

# Run it
/home/ttclaw/openclaw/openclaw.sh --version
```

**If you want global access:**
```bash
# Add wrapper to PATH
echo 'export PATH="/home/ttclaw/openclaw:$PATH"' >> ~/.bashrc
source ~/.bashrc

# Now works from anywhere
openclaw.sh --version
```

### Issue: "Permission denied" during npm install

**This should NOT happen** with local installation (no `-g` flag).

**If it does:**
```bash
# Ensure you're in the openclaw directory
cd /home/ttclaw/openclaw

# Check directory ownership
ls -ld /home/ttclaw/openclaw
# Should show: drwx------ ttclaw ttclaw

# Try installation again (local, not global)
npm install openclaw@latest
```

### Issue: "Unauthorized" or API errors

**Solutions:**
1. Verify the vLLM server is still running:
   ```bash
   curl http://127.0.0.1:8000/health
   # Should return 200 OK
   ```

2. Verify the bearer token is correct:
   ```bash
   source /home/ttclaw/openclaw/.env
   curl -H "Authorization: Bearer $VLLM_API_KEY" http://127.0.0.1:8000/v1/models
   # Should return model list
   ```

3. Check OpenClaw is using the correct config:
   ```bash
   cat /home/ttclaw/openclaw/openclaw.json
   # Verify apiKey field uses ${VLLM_API_KEY} substitution
   ```

### Issue: Onboarding wizard doesn't support custom endpoints

**Solution:** Use the pre-configured `openclaw.json` file directly:
```bash
# Set environment variable for config path
echo 'export OPENCLAW_CONFIG=/home/ttclaw/openclaw/openclaw.json' >> ~/.bashrc
source ~/.bashrc

# Start OpenClaw
cd /home/ttclaw/openclaw
npx openclaw
# Or: ./openclaw.sh
```

### Issue: Node.js version too old

**Solution:**
```bash
# Update Node.js using nvm (Node Version Manager)
curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.0/install.sh | bash
source ~/.bashrc
nvm install 22
nvm use 22
```

## Directory Structure After Installation

```
/home/ttclaw/openclaw/
├── .env                      # JWT bearer token (already created)
├── openclaw.json             # vLLM config (already created)
├── README.md                 # Documentation (already created)
├── workspace/                # Agent workspace (already created)
├── node_modules/             # npm packages (created by npm install)
│   └── openclaw/            # OpenClaw installation
├── package.json              # npm metadata (created by npm init)
├── package-lock.json         # npm lock file (created by npm install)
└── openclaw.sh               # Convenience wrapper script
```

**Everything self-contained** in one directory!

## Verification Checklist

After installation, verify:

- [ ] `/home/ttclaw/openclaw/node_modules/openclaw` exists
- [ ] `npx openclaw --version` shows version number
- [ ] `OPENCLAW_CONFIG_PATH` environment variable is set
- [ ] Configuration points to http://127.0.0.1:8000/v1
- [ ] Bearer token is correctly set in config
- [ ] Model name matches server (meta-llama/Llama-3.1-8B-Instruct)
- [ ] Test with: `OPENCLAW_CONFIG_PATH=/home/ttclaw/openclaw/openclaw.json npx openclaw ask "Hello"`
- [ ] Verify response from local model (not API error)
- [ ] No authentication errors in logs

## What OpenClaw Does

OpenClaw is a personal AI assistant that:
- Runs locally on your machine
- Connects to your local vLLM server (Tenstorrent hardware)
- Can integrate with chat platforms (WhatsApp, Slack, Discord, etc.)
- Maintains conversation memory in the workspace directory
- Operates as the unprivileged ttclaw user for security

## Next Steps After Installation

1. **Test basic functionality**: Try a few chat queries
2. **Configure channels** (optional): Set up WhatsApp, Slack, etc. if desired
3. **Customize workspace**: Edit AGENTS.md, SOUL.md for agent personality
4. **Set up daemon**: Enable OpenClaw to run on system startup
5. **Monitor usage**: Check logs in workspace directory

## Important Notes

- **Security**: ttclaw user has NO sudo access (by design)
- **Model switching**: To use a different model, ask ttuser to restart the vLLM server with a different model, then update `/home/ttclaw/openclaw/openclaw.json`
- **Performance**: First queries may be slower (cache warming); subsequent queries faster
- **Workspace privacy**: Keep `/home/ttclaw/openclaw/workspace` private (700 permissions)

## Getting Help

- OpenClaw docs: https://docs.openclaw.ai
- npm package: https://www.npmjs.com/package/openclaw
- GitHub: https://github.com/openclaw/openclaw
- Installation guides: See references at top of this document

## Time Estimate

- Installation: 2-5 minutes
- Onboarding: 3-10 minutes
- Testing: 2-3 minutes
- **Total: 10-20 minutes**

---

## Current Status (as of 2026-03-06)

### ✅ Already Completed

1. **OpenClaw Installed**: v2026.3.2 in `/home/ttclaw/openclaw/node_modules/`
2. **Configuration File**: `/home/ttclaw/openclaw/openclaw.json` configured for vLLM
3. **Environment File**: `/home/ttclaw/openclaw/.env` with JWT bearer token
4. **Workspace**: `/home/ttclaw/openclaw/workspace/` directory created
5. **Wrapper Script**: `/home/ttclaw/openclaw/openclaw.sh` (needs OPENCLAW_CONFIG_PATH update)

### 🔧 Recommended Next Steps

1. **Update wrapper script** to include OPENCLAW_CONFIG_PATH (see Step 6 above)
2. **Start vLLM server** if not already running
3. **Test OpenClaw** with `./openclaw.sh ask "Hello"`
4. **Run onboarding** if you want daemon mode: `./openclaw.sh onboard --install-daemon`

**Ready to start!** Follow the steps above as the ttclaw user. Good luck! 🦞
