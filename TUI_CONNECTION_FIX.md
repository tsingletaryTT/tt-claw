# TUI Connection Fix - Using Default Port 18789

## What Was Fixed

The TUI connection issue was caused by the gateway running on a custom port (18790) while the TUI tried to connect to OpenClaw's default port (18789).

**Solution:** Use OpenClaw's default port 18789 for both gateway and TUI.

## Changes Made (2026-03-17)

### 1. Removed Custom Port Variable (line 13-14)

**Removed:**
```bash
# Gateway port (different from personal OpenClaw default of 18789)
GATEWAY_PORT="${TT_CLAW_PORT:-18790}"
```

### 2. Updated `cmd_start()` Function (lines 150-159)

**Changed from:**
```bash
info "Starting OpenClaw gateway (agent: $agent, port: $GATEWAY_PORT)..."
nohup env OPENCLAW_STATE_DIR="$OPENCLAW_STATE_DIR" "$openclaw_cmd" gateway run \
    --port "$GATEWAY_PORT" \
    > "$OPENCLAW_STATE_DIR/gateway.log" 2>&1 &
```

**Changed to:**
```bash
info "Starting OpenClaw gateway (agent: $agent, port: 18789)..."
# Start in background with explicit OPENCLAW_STATE_DIR
# Using default port 18789 (OpenClaw default) for TUI compatibility
nohup env OPENCLAW_STATE_DIR="$OPENCLAW_STATE_DIR" "$openclaw_cmd" gateway run \
    > "$OPENCLAW_STATE_DIR/gateway.log" 2>&1 &
```

### 3. Updated `is_gateway_running()` Function (lines 101-108)

**Changed from:**
```bash
if lsof -iTCP:$GATEWAY_PORT -sTCP:LISTEN >/dev/null 2>&1; then
```

**Changed to:**
```bash
# Check if default port 18789 is being listened on by openclaw process
if lsof -iTCP:18789 -sTCP:LISTEN >/dev/null 2>&1; then
```

### 4. Updated `cmd_status()` Function (lines 205-207)

**Changed from:**
```bash
echo "  Port: $GATEWAY_PORT"
```

**Changed to:**
```bash
echo "  Port: 18789 (OpenClaw default)"
```

### 5. Updated `usage()` Function (lines 70-72)

**Changed from:**
```bash
Environment:
  OPENCLAW_STATE_DIR=${OPENCLAW_STATE_DIR}
  TT_CLAW_PORT=${GATEWAY_PORT}
```

**Changed to:**
```bash
Environment:
  OPENCLAW_STATE_DIR=${OPENCLAW_STATE_DIR}
  Gateway Port: 18789 (OpenClaw default)
```

## Why This Fix Works

### Automatic TUI Connection

OpenClaw's TUI automatically connects to `ws://127.0.0.1:18789` by default. By using the default port, no explicit connection configuration is needed.

### Configuration Isolation Still Maintained

Even though we're using the default port, tt-claw remains completely isolated via `OPENCLAW_STATE_DIR`:
- ✅ Separate `openclaw.json` configuration
- ✅ Separate agent definitions
- ✅ Separate workspace directories
- ✅ Separate memory databases
- ✅ Separate logs

### Simplicity

No custom port configuration means fewer moving parts and less chance of misconfiguration.

## Verification Steps

### 1. Stop Any Running Gateway

```bash
./bin/tt-claw stop
# Or manually: pkill -f openclaw-gateway
```

### 2. Start Gateway with New Code

```bash
./bin/tt-claw start
```

**Expected output:**
```
ℹ️  Starting OpenClaw gateway (agent: expert, port: 18789)...
ℹ️  Using runtime: /home/ttuser/tt-claw/openclaw-runtime
✅ Gateway started (PID: XXXXX)
ℹ️  Logs: /home/ttuser/tt-claw/openclaw-runtime/gateway.log
ℹ️  Use 'tt-claw tui' to interact
```

### 3. Check Status

```bash
./bin/tt-claw status
```

**Expected output:**
```
tt-claw Status:
  Runtime: /home/ttuser/tt-claw/openclaw-runtime
  Port: 18789 (OpenClaw default)

✅ Gateway: Running
ℹ️    PID: XXXXX
ℹ️    Logs: /home/ttuser/tt-claw/openclaw-runtime/gateway.log

✅ vLLM: Running on port 8000

✅ Runtime directory exists
✅ Configuration found
```

### 4. Verify Gateway Logs

```bash
tail openclaw-runtime/gateway.log
```

**Look for:**
```
[gateway] listening on ws://127.0.0.1:18789, ws://[::1]:18789
[gateway] agent model: vllm/meta-llama/Llama-3.3-70B-Instruct
```

### 5. Test TUI Connection

```bash
./bin/tt-claw tui
```

**Expected behavior:**
- ✅ Shows "Launching TUI (agent: expert)..."
- ✅ Shows "Connecting to: /home/ttuser/tt-claw/openclaw-runtime"
- ✅ TUI interface loads without connection errors
- ✅ Shows agents from openclaw-runtime/agents/

### 6. Test End-to-End

In the TUI, type a query:
```
What is QB2?
```

**Expected behavior:**
- ✅ TUI sends message to gateway on port 18789
- ✅ Gateway processes with vllm provider (port 8000)
- ✅ Agent uses memory search (local)
- ✅ Response appears in TUI with QB2 information

### 7. Verify Correct Runtime

```bash
# Check gateway is using our config
grep "agent model" openclaw-runtime/gateway.log
# Should show: vllm/meta-llama/Llama-3.3-70B-Instruct

# Check WebSocket connections
tail -50 openclaw-runtime/gateway.log | grep -i "websocket\|connected"
# Should show successful connection from TUI
```

## Important Note: Can't Run Both Gateways Simultaneously

By using port 18789, you cannot run tt-claw gateway and personal OpenClaw gateway at the same time. This is fine because:

1. **Different use cases** - tt-claw is for Tenstorrent work, personal OpenClaw for general use
2. **Already conflicting** - Both would try to use the same vLLM on port 8000
3. **Easy switching** - Just stop one and start the other:

```bash
# Switch to tt-claw
pkill -f openclaw-gateway
./bin/tt-claw start

# Switch to personal OpenClaw
./bin/tt-claw stop
openclaw gateway run
```

## Testing Checklist

- [ ] Gateway starts without errors
- [ ] Gateway logs show correct runtime path (`openclaw-runtime/openclaw.json`)
- [ ] Gateway listens on port 18789
- [ ] `tt-claw status` shows "Port: 18789 (OpenClaw default)"
- [ ] `tt-claw status` shows "Gateway: Running"
- [ ] `tt-claw tui` shows "Connecting to: /home/ttuser/tt-claw/openclaw-runtime"
- [ ] TUI connects successfully (no connection errors)
- [ ] Query in TUI returns response from vLLM
- [ ] Logs show correct model configuration (Llama-3.3-70B)

## Troubleshooting

### TUI Still Not Connecting

1. **Check gateway is actually running:**
   ```bash
   lsof -iTCP:18789 -sTCP:LISTEN
   ```

2. **Check for errors in logs:**
   ```bash
   tail -f openclaw-runtime/gateway.log
   ```

3. **Verify runtime directory:**
   ```bash
   ./bin/tt-claw explore
   ```

### Port Already in Use

If another gateway is using port 18789:
```bash
# Find what's using it
lsof -iTCP:18789 -sTCP:LISTEN

# Kill it
pkill -f openclaw-gateway
```

### Configuration Not Loading

1. **Verify runtime directory exists:**
   ```bash
   ls -la openclaw-runtime/
   ```

2. **Check config file is valid:**
   ```bash
   cat openclaw-runtime/openclaw.json | jq .
   ```

3. **Re-run setup if needed:**
   ```bash
   ./bin/tt-claw setup
   ```

### Gateway Shows Wrong Configuration

If gateway logs show it's loading from `~/.openclaw/` instead of `openclaw-runtime/`:

```bash
# Verify OPENCLAW_STATE_DIR is set correctly in the script
grep "OPENCLAW_STATE_DIR=" bin/tt-claw

# Should show: export OPENCLAW_STATE_DIR="$REPO_ROOT/openclaw-runtime"
```

## Success Criteria

✅ **Before Fix (port 18790):**
- Gateway ran on port 18790
- TUI tried to connect to default port 18789
- Connection failed silently
- User had to manually check gateway status

✅ **After Fix (port 18789):**
- Gateway runs on default port 18789
- TUI connects automatically (default behavior)
- All messages processed by tt-claw configuration
- User sees responses from Tenstorrent expert agent
- Complete isolation from personal OpenClaw config maintained

## What's Next

Once verified working:
1. ✅ Document the fix in CLAUDE.md
2. Test with game agents (chip-quest, terminal-dungeon, conference-chaos)
3. Verify memory search still works
4. Test long-running sessions
5. Prepare demo for booth

## Reverting If Needed

If you need to go back to custom port 18790 (not recommended):

```bash
git diff bin/tt-claw  # See the changes
git checkout bin/tt-claw  # Revert to previous version
```

Or manually add back:
1. Line 13: `GATEWAY_PORT="${TT_CLAW_PORT:-18790}"`
2. Line 158: `--port "$GATEWAY_PORT" \`
3. Update port checks to use `$GATEWAY_PORT`

---

**Last Updated:** March 17, 2026
**Status:** ✅ Fix Applied - Ready for Testing
**Risk Level:** Very Low (simple port change)
**Breaking Changes:** None (fixes broken connection)
