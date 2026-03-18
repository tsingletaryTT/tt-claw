# tt-claw Safety Guarantees

This document explains the security guarantees and local-only architecture of tt-claw.

## Table of Contents

1. [Security Goals](#security-goals)
2. [Local-Only Architecture](#local-only-architecture)
3. [Safety Mechanisms](#safety-mechanisms)
4. [Audit Commands](#audit-commands)
5. [Threat Model](#threat-model)
6. [Verification](#verification)

## Security Goals

### What tt-claw Guarantees

✅ **Local-only LLM inference** - All AI processing happens on your Tenstorrent hardware
✅ **No remote API calls** - No data sent to OpenAI, Anthropic, or other cloud services
✅ **Local embeddings** - Memory search uses local models (node-llama-cpp)
✅ **No remote fallbacks** - If local fails, operation fails (no silent fallback to cloud)
✅ **Configuration transparency** - All configs visible in `openclaw-runtime/`
✅ **Automated validation** - Safety checks run automatically during setup

### What tt-claw Does NOT Guarantee

❌ **Physical security** - Protects network, not physical access to machine
❌ **vLLM vulnerabilities** - vLLM security is out of scope
❌ **User modifications** - Users can edit configs (trust but verify)
❌ **Network segmentation** - Assumes localhost is safe

## Local-Only Architecture

### Network Topology

```
┌─────────────────────────────────────────────────┐
│ Local Machine (127.0.0.1)                       │
│                                                  │
│  ┌──────────┐    ┌──────────┐    ┌───────────┐ │
│  │   User   │◄──►│ OpenClaw │◄──►│   vLLM    │ │
│  │   TUI    │    │ Gateway  │    │ :8000/8001│ │
│  └──────────┘    │ :18790   │    └─────┬─────┘ │
│                  └──────────┘          │        │
│                       │                │        │
│                  ┌────▼─────┐    ┌─────▼──────┐ │
│                  │ Memory   │    │Tenstorrent │ │
│                  │ Search   │    │ Hardware   │ │
│                  │ (local)  │    │ (TT-Metal) │ │
│                  └──────────┘    └────────────┘ │
│                                                  │
└─────────────────────────────────────────────────┘
         │
         │ ❌ NO NETWORK CONNECTIONS
         │
      Internet
```

### Component Security

**OpenClaw Gateway** (port 18790):
- Binds to `127.0.0.1` only (not `0.0.0.0`)
- No remote channel integrations configured
- WebSocket only accessible locally

**vLLM** (port 8000 or 8001):
- Running in Docker or local Python environment
- Configured with `--no-auth` (localhost only, no public exposure)
- No outbound network calls

**Memory Search**:
- Provider: `local` (node-llama-cpp)
- Fallback: `none` (never tries remote services)
- Embedding models: Downloaded once, cached locally (~500MB)
- Vector database: SQLite with sqlite-vec (local file)

## Safety Mechanisms

### Layer 1: Configuration Generation (Preventive)

When you run `tt-claw setup`, the generated config:

**Enforces localhost providers**:
```json
{
  "models": {
    "providers": {
      "vllm": {
        "baseUrl": "http://127.0.0.1:8000/v1",  // ✅ Localhost only
        "apiKey": "sk-no-auth-required"          // ✅ Dummy key
      }
    }
  }
}
```

**Disables remote memory search**:
```json
{
  "agents": {
    "defaults": {
      "memorySearch": {
        "provider": "local",     // ✅ Local embeddings
        "fallback": "none"       // ✅ No cloud fallback
      }
    }
  }
}
```

**Validation checks** (in `lib/openclaw-setup.sh`):
- Rejects non-localhost URLs
- Verifies memory fallback is "none"
- Confirms provider is "local"
- Displays safety summary after setup

### Layer 2: Runtime Checks (Detective)

When you run `tt-claw start`, checks:
- vLLM is accessible on localhost
- Config file exists and is readable
- Gateway port is available

When you run `tt-claw doctor`, validates:
- All provider URLs are localhost
- No real API keys present
- Memory search settings are safe
- vLLM is running and accessible
- Runtime directory is isolated

### Layer 3: User Audit (Transparency)

All configuration is visible:
```bash
# Explore directory structure
tt-claw explore

# View main config
cat openclaw-runtime/openclaw.json

# Check provider URLs
grep baseUrl openclaw-runtime/openclaw.json

# Check memory settings
grep -A 5 memorySearch openclaw-runtime/openclaw.json
```

## Audit Commands

### Quick Safety Check

```bash
# Run full safety check
tt-claw doctor
```

Expected output:
```
=== OpenClaw Safety Check ===

1. Configuration File
✅ PASS: Config file exists

2. Provider URLs (Must be localhost only)
✅ PASS: All providers are localhost

3. API Keys (Should be dummy values for localhost)
✅ PASS: No real API keys found

4. Memory Search Fallback (Must be 'none')
✅ PASS: Memory search has no remote fallback

5. Memory Search Provider (Must be 'local')
✅ PASS: Memory search uses local provider

6. Remote Provider Names (OpenAI, Anthropic, etc.)
✅ PASS: No remote provider names found

7. vLLM Accessibility
✅ PASS: vLLM accessible on port 8000

8. Runtime Directory Isolation
✅ PASS: Runtime directory exists: /home/ttuser/tt-claw/openclaw-runtime

=== Summary ===
Checks passed: 8
Checks failed: 0
Warnings: 0

✅ All safety checks passed! ✨
```

### Manual Verification

**Check provider URLs**:
```bash
grep -E '"baseUrl"' openclaw-runtime/openclaw.json
```

Expected (SAFE):
```json
"baseUrl": "http://127.0.0.1:8000/v1",
```

Dangerous (UNSAFE):
```json
"baseUrl": "https://api.openai.com/v1",  // ❌ Remote!
```

**Check API keys**:
```bash
grep -E '"apiKey"' openclaw-runtime/openclaw.json
```

Expected (SAFE):
```json
"apiKey": "sk-no-auth-required",
"apiKey": "sk-dummy",
```

Dangerous (UNSAFE):
```json
"apiKey": "sk-proj-abc123...",  // ❌ Real key!
```

**Check memory fallback**:
```bash
grep -E '"fallback"' openclaw-runtime/openclaw.json
```

Expected (SAFE):
```json
"fallback": "none",
```

Dangerous (UNSAFE):
```json
"fallback": "openai",      // ❌ Remote fallback!
"fallback": "anthropic",   // ❌ Remote fallback!
```

**Check memory provider**:
```bash
grep -E '"provider".*local' openclaw-runtime/openclaw.json
```

Expected (SAFE):
```json
"provider": "local",
```

### Network Verification

**No outbound connections during operation**:
```bash
# Start tt-claw
tt-claw start

# In another terminal, monitor network connections
lsof -iTCP -sTCP:ESTABLISHED | grep -E 'openclaw|vllm'
```

Expected: Only localhost connections:
```
node    12345  ttuser  TCP 127.0.0.1:18790->127.0.0.1:xxxxx (ESTABLISHED)
python  12346  ttuser  TCP 127.0.0.1:8000->127.0.0.1:xxxxx (ESTABLISHED)
```

Dangerous: External connections:
```
python  12346  ttuser  TCP 192.168.1.100:xxxxx->1.2.3.4:443 (ESTABLISHED)  // ❌ Outbound!
```

**Test query without internet**:
```bash
# Disable network (requires sudo)
sudo ifconfig eth0 down  # or: sudo ip link set eth0 down

# Use tt-claw (should still work!)
tt-claw tui
# Ask: "What is QB2?"
# Should get answer from local memory search

# Re-enable network
sudo ifconfig eth0 up  # or: sudo ip link set eth0 up
```

If tt-claw works without network, it's truly local!

## Threat Model

### Threats We Mitigate

✅ **Accidental cloud usage** - User thinks it's local but config has OpenAI key
✅ **Silent fallback** - Local fails, system falls back to cloud without warning
✅ **Configuration drift** - Starts safe, becomes unsafe over time through modifications
✅ **Copy-paste errors** - User copies config from internet that includes cloud providers

### Threats Out of Scope

❌ **Malicious modifications** - User intentionally adds cloud providers
❌ **Physical access** - Attacker with physical access can change anything
❌ **vLLM vulnerabilities** - Security bugs in vLLM itself
❌ **Model extraction** - Protecting model weights from extraction
❌ **Prompt injection** - Malicious prompts to vLLM

### Trust Boundary

We trust:
- User's machine (if compromised, all bets are off)
- Localhost networking (127.0.0.1 is safe)
- OpenClaw software (not malicious)
- vLLM software (not malicious)

We don't trust:
- User's config edits (verify with `tt-claw doctor`)
- Network (never use it)
- External services (never call them)

## Verification

### Continuous Verification

Run safety check regularly:
```bash
# Daily check
tt-claw doctor

# Before important demos
tt-claw doctor && tt-claw start

# After config changes
nano openclaw-runtime/openclaw.json
tt-claw doctor  # Verify still safe
```

### Automated Verification

Add to cron or systemd timer:
```bash
# Daily safety check at 9 AM
0 9 * * * cd ~/tt-claw && ./bin/tt-claw doctor || notify-send "tt-claw Safety Check Failed"
```

### Git Tracking (Optional)

Track runtime for change detection:
```bash
# Initialize git in runtime (optional)
cd openclaw-runtime
git init
git add -A
git commit -m "Initial safe config"

# After any change, check diff
git diff openclaw.json

# Revert unsafe changes
git checkout openclaw.json
```

## Incident Response

### If Safety Check Fails

1. **Stop using tt-claw immediately**:
   ```bash
   tt-claw stop
   ```

2. **Review what changed**:
   ```bash
   cat openclaw-runtime/openclaw.json
   ```

3. **Regenerate safe config**:
   ```bash
   tt-claw clean     # Remove current runtime
   tt-claw setup     # Generate fresh config
   tt-claw doctor    # Verify safe
   ```

4. **Or restore from backup**:
   ```bash
   # If you backed up your runtime
   rm -rf openclaw-runtime
   cp -r openclaw-runtime.backup openclaw-runtime
   tt-claw doctor  # Verify safe
   ```

### If You Suspect Remote Usage

1. **Check active connections**:
   ```bash
   lsof -iTCP -sTCP:ESTABLISHED | grep -E 'openclaw|vllm'
   ```

2. **Review recent queries**:
   ```bash
   # Check OpenClaw logs
   tail -n 100 openclaw-runtime/gateway.log
   ```

3. **Verify no remote providers**:
   ```bash
   tt-claw doctor
   ```

4. **Test without network** (as shown above)

## Best Practices

### Secure Configuration Management

✅ **DO**:
- Run `tt-claw doctor` after any config change
- Use `tt-claw setup` to regenerate safe configs
- Keep `tt-claw` updated (git pull)
- Review configs before demos
- Test without network occasionally

❌ **DON'T**:
- Copy configs from internet without reviewing
- Add cloud API keys "just in case"
- Disable safety checks
- Assume config is safe without verification
- Share runtime directory publicly (may contain session data)

### Operational Security

✅ **DO**:
- Use different OpenClaw instances for different purposes (personal vs tt-claw)
- Keep vLLM on localhost only (don't expose to network)
- Review `tt-claw doctor` output regularly
- Update OpenClaw and vLLM for security patches
- Use firewall rules to block outbound if paranoid

❌ **DON'T**:
- Expose OpenClaw gateway to public internet
- Share API keys even if "dummy" (bad habit)
- Run as root (use regular user)
- Disable firewall on demo machines
- Mix production API keys with local configs

## FAQ

**Q: How do I know tt-claw is really local-only?**

A: Multiple ways to verify:
1. Run `tt-claw doctor` - automated safety checks
2. Review `openclaw-runtime/openclaw.json` - all URLs should be 127.0.0.1
3. Monitor network with `lsof` - only localhost connections
4. Test without internet - should still work

**Q: Can I add a remote provider "just in case"?**

A: **No.** This defeats the security guarantee. If you need remote access, use a separate OpenClaw instance (not tt-claw).

**Q: What if I modify the config and break safety?**

A: `tt-claw doctor` will detect and warn you. Regenerate with `tt-claw clean && tt-claw setup`.

**Q: Is memory search truly local?**

A: Yes. Uses node-llama-cpp (local embeddings) with SQLite (local database). First run downloads models (~500MB) once, then fully offline.

**Q: What data is stored locally?**

A:
- `openclaw-runtime/openclaw.json` - configuration
- `openclaw-runtime/agents/` - agent configs and prompts
- `openclaw-runtime/workspace/` - agent work areas
- `openclaw-runtime/memory/` - vector database (indexed docs)
- `openclaw-runtime/gateway.log` - operation logs

**Q: Can I audit what queries were made?**

A: Check `openclaw-runtime/gateway.log` for query/response logs.

**Q: Is this safe for corporate/sensitive use?**

A: Safety is guaranteed for network isolation (no remote calls). However:
- Data is stored unencrypted locally
- Logs contain query history
- No access control between users on same machine
- Consider full-disk encryption for sensitive environments

---

**Last Updated**: March 16, 2026
**Security Version**: 1.0
**Threat Model**: Local-only, no remote API calls

**Report security issues**: Document in CLAUDE.md or create issue
