# OpenClaw Memory Search - Quick Reference

**Status:** ✅ Configured (March 10, 2026)

## What It Does

OpenClaw can now search and reference:
- **45 interactive lessons** from tt-vscode-toolkit
- **TT-Metal documentation** (METALIUM, releases, contributing)
- **TT-Inference-Server guides** (deployment, models, workflows)
- **OpenClaw on Tenstorrent journey** (70B deployment, vLLM setup)

## Quick Start

### 1. Start Gateway (picks up memory search config)

```bash
cd ~/code/tt-vscode-toolkit
./openclaw.sh gateway run
```

First startup may take 1-2 minutes to:
- Download embedding models (~500MB)
- Index documentation (~45 lessons + docs)

### 2. Start TUI

```bash
# In another terminal
cd ~/code/tt-vscode-toolkit
./openclaw.sh tui
```

### 3. Test Memory Search

Try these queries in the TUI:

```
search memory for hardware detection
```

```
How do I deploy vLLM on Tenstorrent?
```

```
What cookbook examples are available?
```

```
What is METALIUM?
```

## Test Script

Run diagnostic tests:

```bash
~/test-openclaw-memory.sh
```

Checks:
- Gateway running
- Configuration present
- Documentation paths exist
- Vector database created
- Embedding models downloaded

## Expected Behavior

When you ask a question:
1. ✅ OpenClaw searches indexed documentation
2. ✅ Finds relevant snippets
3. ✅ Synthesizes answer with context
4. ✅ Cites sources (file:line)

**Example:**
```
User: How do I check if my Tenstorrent device is working?

OpenClaw: You can use tt-smi to check your Tenstorrent devices...

          Source: tt-vscode-toolkit/content/lessons/hardware-detection.md#L15
```

## Documentation Indexed

**tt-vscode-toolkit** (45 lessons, 1.1MB)
- Hardware detection, device info
- vLLM deployment, API servers
- TT-Forge, TT-XLA, TT-Metal
- Custom training, multi-device
- Cookbook examples (Game of Life, Mandelbrot, audio, image processing)

**tt-metal** (core docs)
- METALIUM_GUIDE.md
- Release notes
- Contributing guides

**tt-inference-server** (deployment docs)
- README.md
- Development guide
- Model bringup guide
- Workflow documentation

**tt-claw** (integration)
- CLAUDE.md - Complete OpenClaw journey
  - 70B model deployment
  - vLLM compatibility proxy
  - Production setup

## Troubleshooting

### Gateway won't start
```bash
# Check for errors in openclaw.json
cat ~/.openclaw/openclaw.json | jq .

# Check logs in terminal
```

### No memory search results
```bash
# Verify configuration
grep "memorySearch" ~/.openclaw/openclaw.json

# Check vector database exists
ls -lh ~/.openclaw/memory/*.sqlite
```

### First search is slow
**Expected!** First search downloads models (~500MB).
Subsequent searches are fast (<1 second).

### Permission errors
```bash
# Fix ownership
sudo chown -R ttuser:ttuser ~/.openclaw/
```

## Configuration Files

**Main config:** `~/.openclaw/openclaw.json`

**Memory search section:**
```json
{
  "agents": {
    "defaults": {
      "memorySearch": {
        "provider": "local",
        "extraPaths": [
          "/home/ttuser/code/tt-vscode-toolkit/content/lessons",
          "/home/ttuser/tt-metal/METALIUM_GUIDE.md",
          "/home/ttuser/tt-metal/releases",
          "/home/ttuser/tt-metal/contributing",
          "/home/ttuser/code/tt-inference-server/README.md",
          "/home/ttuser/code/tt-inference-server/docs",
          "/home/ttuser/tt-claw/CLAUDE.md"
        ]
      }
    }
  }
}
```

## For Booth Demo

### Practice Questions

**Hardware:**
- "What Tenstorrent devices are supported?"
- "How do I detect my Tenstorrent hardware?"
- "What's the difference between N300 and P150?"

**Deployment:**
- "How do I deploy a model on Tenstorrent?"
- "What's the largest model I can run?"
- "How do I set up vLLM?"

**Examples:**
- "What cookbook examples can I try?"
- "Show me how to run Game of Life on Tenstorrent"
- "What audio processing examples are there?"

**Technical:**
- "What is METALIUM?"
- "How does TT-Forge work?"
- "What's the difference between TT-XLA and TT-Forge?"

### Expected Performance

- **First query:** 30-60 seconds (downloads models)
- **Subsequent queries:** <1 second
- **Citation accuracy:** File paths and line numbers
- **Answer quality:** Synthesized from multiple docs

## Files

**Documentation:** `/home/ttuser/OPENCLAW_MEMORY_SEARCH_SETUP.md`
**Test script:** `/home/ttuser/test-openclaw-memory.sh`
**Quick ref:** `/home/ttuser/OPENCLAW_MEMORY_QUICK_REF.md` (this file)

**Configs:**
- ttuser: `/home/ttuser/.openclaw/openclaw.json`
- ttclaw: `/home/ttclaw/.openclaw/openclaw.json`

**Gateway:**
- ttuser: `cd ~/code/tt-vscode-toolkit && ./openclaw.sh gateway run`
- ttclaw: `cd ~/openclaw && ./openclaw.sh gateway run`

## Status Checklist

- [x] Configuration added to openclaw.json
- [x] Documentation paths verified (45 lessons + docs)
- [x] Test script created
- [ ] Gateway restarted (run: `./openclaw.sh gateway run`)
- [ ] Indexing complete (check gateway logs)
- [ ] Memory search tested (try test queries)
- [ ] Citations verified (show correct file paths)

## Next Steps

1. **Restart gateway** with new config
2. **Monitor indexing** in gateway logs
3. **Test queries** from list above
4. **Verify citations** show file paths
5. **Practice** for booth demo
