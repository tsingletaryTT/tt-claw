# Deploy Llama-3.3-70B on QB2 - CORRECTED APPROACH

**Date:** 2026-03-10
**Status:** Ready for deployment after system reboot

---

## What We Fixed

### Issue: Trace Region Size Override Not Applied

**Problem:** 70B model needs 56MB trace buffer but spec had 30MB hardcoded.

**Root Cause:** The `default_model_spec.json` had 30MB in multiple locations that needed to be updated.

**Solution Applied:** ✅
1. Edited `default_model_spec.json` to set `trace_region_size: 56000000` in ALL locations for P150X4 Llama-3.3-70B
2. Verified CLI flag syntax: `--override-tt-config '{"trace_region_size": 56000000}'`
3. Confirmed override is correctly merged into runtime spec

**Verified Working:**
```bash
jq '.runtime_model_spec.device_model_spec.override_tt_config.trace_region_size' \
  workflow_logs/runtime_model_specs/runtime_model_spec_*.json
# Returns: 56000000 ✅
```

---

## Current Blocker: Hardware State

**Issue:** Ethernet core timeout during fabric initialization
```
Device 0: Timed out while waiting for active ethernet core (x=24,y=25) to become active
```

**Cause:** Multiple failed deployment attempts exhausted hardware state

**Fix Required:** Full system reboot to reset ethernet cores

---

## Deployment Command (READY TO USE)

After reboot, use this exact command:

```bash
cd /home/ttuser/code/tt-inference-server

python3 run.py \
  --model Llama-3.3-70B-Instruct \
  --tt-device p150x4 \
  --workflow server \
  --docker-server \
  --override-docker-image "ghcr.io/tenstorrent/tt-inference-server/vllm-tt-metal-src-dev-ubuntu-22.04-amd64:0.10.0-84b4c53-222ee06" \
  --host-hf-cache /home/ttuser/.cache/huggingface \
  --no-auth \
  --override-tt-config '{"trace_region_size": 56000000}' \
  --vllm-override-args '{"enable_auto_tool_choice": true, "tool_call_parser": "llama3_json"}'
```

**Key Points:**
- Uses 56MB trace region (Glean's recommendation)
- Reuses downloaded 132GB model weights from HF cache
- Tool calling enabled with `llama3_json` parser
- No authentication required

---

## Expected Timeline

**First-time deployment (model cached):**
1. Docker pull: ~30 seconds (image already cached)
2. Hardware init: ~30 seconds (4 chips, fabric)
3. Model loading: ~15 minutes (132GB weights)
4. KV cache allocation: ~2 seconds
5. Trace compilation: **~40-60 minutes** (THIS IS THE TEST)
6. Server startup: ~5 seconds

**Total: 55-75 minutes** (most time in trace compilation)

---

## What to Monitor

### 1. Verify Trace Region Size is Applied

After container starts, check logs:
```bash
CONTAINER_ID=$(docker ps --filter ancestor=*tt-inference-server* --format "{{.ID}}")
docker logs $CONTAINER_ID 2>&1 | grep "override_tt_config"
```

**Expected:** `'override_tt_config': {'trace_region_size': 56000000}`
**If you see 30000000:** Spec override didn't apply, stop and investigate

### 2. Watch for Trace Buffer Error

```bash
docker logs -f $CONTAINER_ID 2>&1 | grep -E "Creating trace buffers|trace_region_size"
```

**Success:** No "Creating trace buffers" error
**Failure:** `Creating trace buffers of size 56164352B, but only 30000000B allocated`

### 3. Monitor Progress

The deployment will be **silent for ~40-60 minutes** during trace compilation. This is normal!

```bash
# Check every 5 minutes
docker logs $CONTAINER_ID 2>&1 | tail -20
```

**Milestones:**
- ✅ "Fabric initialized on all 4 devices"
- ✅ "Loading checkpoint shards: 100%|██████████| 30/30"
- ✅ "Allocated TT kv caches"
- ✅ "Warming up prefill for sequence length: 128"
- ⏳ **LONG SILENCE HERE** (trace compilation happening)
- ✅ "Application startup complete"

### 4. Health Check

When logs show "Application startup complete":
```bash
curl http://localhost:8000/health
```

**Expected:** `{"status":"ok"}` or 200 OK

---

## Troubleshooting

### If Ethernet Core Timeout Persists

```bash
# Check device status
tt-smi -s | jq '.device_info[] | {board: .board_type, fw: .fw_bundle_version}'

# If any devices show null, reboot didn't fully clear state
# Try: sudo reboot
```

### If Trace Buffer Error Still Occurs

```bash
# Verify spec has 56MB
jq '.runtime_model_spec.device_model_spec.override_tt_config.trace_region_size' \
  workflow_logs/runtime_model_specs/runtime_model_spec_*.json | tail -1

# If 30000000: The override didn't apply
# Check default_model_spec.json and verify ALL locations have 56000000
```

### If Initialization Hangs >60 Minutes

Check logs for last output:
```bash
docker logs $CONTAINER_ID 2>&1 | grep -E "Warming up|decode_forward|prefill" | tail -10
```

If stuck at "Warming up prefill" with no progress, the trace compilation may be hung. This is a known issue with 70B models on some hardware configurations.

---

## Success Criteria

✅ Container starts without errors
✅ All 4 chips detected and fabric initialized
✅ Model weights loaded (132GB)
✅ Trace compilation completes (no buffer error)
✅ `/health` returns 200 OK
✅ Test prompt generates response:

```bash
curl http://localhost:8000/v1/completions \
  -H "Content-Type: application/json" \
  -d '{
    "model": "meta-llama/Llama-3.3-70B-Instruct",
    "prompt": "What is 2+2?",
    "max_tokens": 50,
    "temperature": 0
  }'
```

✅ OpenClaw can use it (no config changes needed - same port 8000)

---

## Rollback Plan

If 70B deployment fails or performance is poor, rollback to 8B:

```bash
# Stop 70B
docker stop $(docker ps --filter ancestor=*tt-inference-server* --format "{{.ID}}")

# Start 8B (known working)
cd /home/ttuser/code/tt-inference-server
python3 run.py \
  --model Llama-3.1-8B-Instruct \
  --tt-device p150 \
  --workflow server \
  --docker-server \
  --override-docker-image "ghcr.io/tenstorrent/tt-inference-server/vllm-tt-metal-src-dev-ubuntu-22.04-amd64:0.10.0-84b4c53-222ee06" \
  --no-auth \
  --vllm-override-args '{"enable_auto_tool_choice": true, "tool_call_parser": "llama3_json"}'
```

8B model deploys in ~10 minutes and is fully working with OpenClaw.

---

## Files Modified

**`default_model_spec.json`** (P150X4 Llama-3.3-70B section):
- `override_tt_config.trace_region_size`: 30000000 → 56000000
- `device_model_spec.override_tt_config.trace_region_size`: 30000000 → 56000000
- `device_model_spec.vllm_args.override_tt_config`: Updated to include 56000000

**Changes are persistent** and will apply to all future deployments.

---

## Notes from Glean

Per Glean's guidance on tt-inference-server:
- ✅ Use `--override-tt-config` (hyphens, not underscores)
- ✅ Value must be single JSON string with single quotes outside, double quotes inside
- ✅ 56MB is the tested value for 70B on Blackhole configs
- ✅ Override merges into model spec via `ModelSpec.apply_runtime_args()`
- ✅ tt_vllm_plugin reads from `override_tt_config["trace_region_size"]` and passes to ttnn.open_mesh_device()

**We followed all these guidelines correctly.**

---

## What's Next

1. **Reboot system** to clear ethernet core timeout
2. **Verify hardware** with `tt-smi -s` (all 4 devices show fw: 19.6.0.0)
3. **Run deployment command** from this document
4. **Monitor logs** for 55-75 minutes
5. **Test inference** with health check and sample prompt
6. **Update OpenClaw** if needed (should just work on same port)

If successful, you'll have a much more capable 70B model running on all 4 chips! 🚀

Good luck!
