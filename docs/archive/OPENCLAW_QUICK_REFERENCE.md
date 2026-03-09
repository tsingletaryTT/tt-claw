# OpenClaw Quick Reference

## Installation Status

✅ **OpenClaw v2026.3.2** installed at `/home/ttclaw/openclaw/`

## Quick Commands (as ttclaw user)

```bash
# Switch to ttclaw user
sudo -u ttclaw -i

# Check version
cd /home/ttclaw/openclaw
./openclaw.sh --version

# Test with a simple query
./openclaw.sh ask "What is 2+2?"

# Interactive chat mode
./openclaw.sh chat

# Show configuration
./openclaw.sh config show

# Run onboarding wizard
./openclaw.sh onboard --install-daemon
```

## Prerequisites Checklist

Before using OpenClaw, ensure:

1. ✅ **vLLM server running**: `curl http://127.0.0.1:8000/health`
2. ✅ **Bearer token set**: `source /home/ttclaw/openclaw/.env`
3. ✅ **Config path set**: Automatically set by wrapper script
4. ✅ **Permissions correct**: ttclaw owns all files

## Start vLLM Server (as ttuser)

```bash
# Using tt-cli (recommended)
tt run Llama-3.1-8B-Instruct

# Or manually with vLLM
source ~/activate-vllm-env.sh
python3 -m vllm.entrypoints.openai.api_server \
  --model /home/ttuser/models/models--meta-llama--Llama-3.1-8B-Instruct/snapshots/<hash>/ \
  --port 8000 \
  --api-key "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJ0ZWFtX2lkIjoidGVuc3RvcnJlbnQiLCJ0b2tlbl9pZCI6ImRlYnVnLXRlc3QifQ.1lld0aSjreLgWYQfNCSHZOBfw0uPiQU5hGCc9SUgBVA"
```

## Test OpenClaw End-to-End

```bash
# 1. Start vLLM (as ttuser)
tt run Llama-3.1-8B-Instruct

# 2. In another terminal, test as ttclaw
sudo -u ttclaw -i
cd /home/ttclaw/openclaw
./openclaw.sh ask "Hello, introduce yourself"
```

## Configuration Files

- **Main config**: `/home/ttclaw/openclaw/openclaw.json`
  - Provider: vLLM at http://127.0.0.1:8000/v1
  - Model: meta-llama/Llama-3.1-8B-Instruct
  - Workspace: /home/ttclaw/openclaw/workspace

- **Environment**: `/home/ttclaw/openclaw/.env`
  - Contains: VLLM_API_KEY (JWT bearer token)

- **Wrapper**: `/home/ttclaw/openclaw/openclaw.sh`
  - Sets OPENCLAW_CONFIG_PATH automatically
  - Makes OpenClaw commands simple

## Troubleshooting

### OpenClaw can't connect to vLLM

```bash
# Check if vLLM is running
curl http://127.0.0.1:8000/health

# Check if bearer token works
source /home/ttclaw/openclaw/.env
curl -H "Authorization: Bearer $VLLM_API_KEY" \
  http://127.0.0.1:8000/v1/models
```

### Permission errors

```bash
# Check file ownership
ls -la /home/ttclaw/openclaw/

# Fix if needed (as root or ttuser with sudo)
sudo chown -R ttclaw:ttclaw /home/ttclaw/openclaw/
sudo chmod 700 /home/ttclaw/openclaw/
```

### Command not found

```bash
# Make sure you're in the right directory
cd /home/ttclaw/openclaw

# Use npx directly if wrapper doesn't work
npx openclaw --version

# Or add to PATH
echo 'export PATH="/home/ttclaw/openclaw:$PATH"' >> ~/.bashrc
source ~/.bashrc
```

## Next Steps

1. **Test basic functionality**: `./openclaw.sh ask "Hello"`
2. **Try interactive mode**: `./openclaw.sh chat`
3. **Customize workspace**: Edit files in `/home/ttclaw/openclaw/workspace/`
4. **Set up daemon mode**: `./openclaw.sh onboard --install-daemon`
5. **Add channels**: Configure WhatsApp, Slack, Discord (optional)

## Resources

- Full guide: `/home/ttuser/OPENCLAW_INSTALLATION_GUIDE.md`
- OpenClaw docs: https://docs.openclaw.ai
- npm package: https://www.npmjs.com/package/openclaw

---

**Last updated**: 2026-03-06
