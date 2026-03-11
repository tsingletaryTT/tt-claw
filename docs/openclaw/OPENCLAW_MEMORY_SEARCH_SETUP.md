# OpenClaw Memory Search - TT Expert Configuration

**Date:** March 10, 2026
**Status:** ✅ Configured
**Purpose:** Make OpenClaw an expert on Tenstorrent hardware, tt-vscode-toolkit, and deployment guides

## What Was Done

### 1. Configuration Updates

Updated OpenClaw's memory search system to index external Tenstorrent documentation:

**Files Modified:**
- `/home/ttuser/.openclaw/openclaw.json`
- `/home/ttclaw/.openclaw/openclaw.json`

**Configuration Added:**
```json
{
  "agents": {
    "defaults": {
      "memorySearch": {
        "provider": "local",
        "fallback": "none",
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

### 2. Documentation Indexed

**Total Documentation:**
- **45 interactive lessons** from tt-vscode-toolkit (1.1MB)
- **TT-Metal guides** (METALIUM, releases, contributing)
- **TT-Inference-Server docs** (deployment, models, workflows)
- **OpenClaw integration journey** (CLAUDE.md)

**Topics Covered:**
- Hardware detection (tt-smi, device info)
- vLLM production deployment
- TT-Forge, TT-XLA, TT-Metal frameworks
- Custom training and datasets
- Multi-device configurations
- Cookbook examples (Game of Life, Mandelbrot, audio, image processing)
- API servers and interactive chat
- Model bringup and optimization
- 70B model deployment on P150X4

### 3. Memory Search Provider

**Provider:** `local` (built-in node-llama-cpp)
- No external API dependencies
- No cost
- Runs on-device with local embeddings
- Auto-downloads models on first use

**Backend:** SQLite with sqlite-vec for vector search
- Fast semantic search
- Automatically indexes Markdown files
- Updates when files change

## How to Use

### Starting OpenClaw with Memory Search

**For ttuser:**
```bash
cd ~/code/tt-vscode-toolkit
./openclaw.sh gateway run
```

**For ttclaw (production):**
```bash
cd ~/openclaw
./openclaw.sh gateway run
```

**First startup may take longer** as it:
1. Downloads local embedding models (~500MB)
2. Indexes all documentation (~45 lesson files + docs)
3. Creates vector database

### Testing Memory Search

Start the TUI in a separate terminal:
```bash
./openclaw.sh tui
```

**Test queries:**

1. **Hardware Detection:**
   ```
   search memory for hardware detection
   ```
   Expected: Snippets from hardware-detection.md lesson

2. **vLLM Deployment:**
   ```
   How do I deploy a 70B model on Tenstorrent?
   ```
   Expected: Info from CLAUDE.md about P150X4 deployment

3. **TT-Metal:**
   ```
   What is METALIUM?
   ```
   Expected: Info from METALIUM_GUIDE.md

4. **Cookbook Examples:**
   ```
   What cookbook examples are available?
   ```
   Expected: List of lessons (Game of Life, Mandelbrot, etc.)

5. **Technical Details:**
   ```
   What are the supported hardware devices?
   ```
   Expected: Info from lessons about n150, n300, t3k, p100, p150

### Expected Behavior

When you ask a question:
1. OpenClaw automatically searches memory
2. Finds relevant snippets from indexed documentation
3. Synthesizes answer using retrieved context
4. Cites sources (file paths and line numbers)

**Example output:**
```
The hardware detection lesson shows how to use tt-smi...

Source: tt-vscode-toolkit/content/lessons/hardware-detection.md#L15
```

## Verification Checklist

After restarting gateway, verify:

- [ ] Gateway starts without errors
- [ ] Gateway logs show "indexing memory" messages
- [ ] Memory search returns results for test queries
- [ ] Citations show correct file paths
- [ ] Agent can answer hardware questions
- [ ] Agent can answer deployment questions
- [ ] Agent references specific lessons

## Troubleshooting

### Gateway won't start

**Check JSON syntax:**
```bash
cat ~/.openclaw/openclaw.json | jq . > /dev/null
echo "JSON is valid: $?"
```

**Check logs:**
```bash
# Look for errors in terminal where gateway is running
# Common issues: path typos, permission errors
```

### Memory search returns no results

**Verify indexing:**
```bash
# Check if vector database was created
ls -lh ~/.openclaw/memory/*.sqlite
```

**Check documentation paths:**
```bash
# All paths should exist
ls -la /home/ttuser/code/tt-vscode-toolkit/content/lessons | wc -l
# Should show 45+ lessons
```

### First search is slow

**Expected behavior:**
- First search downloads embedding models (~500MB)
- Subsequent searches are fast (<1 second)
- Models cached in `~/.cache/node-llama-cpp/`

### Permission errors

**Fix ownership:**
```bash
sudo chown -R ttclaw:ttclaw /home/ttclaw/.openclaw/
sudo chown -R ttuser:ttuser /home/ttuser/.openclaw/
```

### Need to approve builds

If you see "pnpm approve-builds" warning:
```bash
cd ~/openclaw  # or ~/code/tt-vscode-toolkit
pnpm approve-builds
```

## Advanced Configuration

### Increase Result Limits

Edit `openclaw.json`:
```json
"memorySearch": {
  "provider": "local",
  "limits": {
    "maxResults": 10,
    "maxSnippetChars": 1000
  }
}
```

### Enable Citations in Responses

```json
"memory": {
  "citations": "auto"
}
```

### Upgrade to QMD Backend (Better Search)

**Install QMD:**
```bash
bun install -g https://github.com/tobi/qmd
```

**Update config:**
```json
"memory": {
  "backend": "qmd",
  "qmd": {
    "includeDefaultMemory": true,
    "searchMode": "search",
    "paths": [
      {
        "name": "tt-vscode-toolkit",
        "path": "/home/ttuser/code/tt-vscode-toolkit/content/lessons",
        "pattern": "**/*.md"
      }
    ]
  }
}
```

## Documentation Structure

### tt-vscode-toolkit Lessons

45 lessons organized by category:

**First Inference:**
- hardware-detection.md
- install-tt-smi.md
- model-download.md
- vllm-deployment.md

**Frameworks:**
- tt-forge-intro.md
- tt-xla-intro.md
- tt-metal-intro.md

**Advanced:**
- custom-training.md
- multi-device.md
- model-optimization.md

**Cookbook:**
- game-of-life.md
- mandelbrot-set.md
- audio-processing.md
- image-filters.md

**API Servers:**
- api-server-setup.md
- interactive-chat.md
- image-generation.md
- video-generation.md

### TT-Metal Documentation

- METALIUM_GUIDE.md - Core framework guide
- releases/ - Version history and changes
- contributing/ - Development best practices

### TT-Inference-Server Documentation

- README.md - Project overview
- docs/development.md - Development guide
- docs/add_support_for_new_model.md - Model bringup
- docs/workflows_user_guide.md - Workflow documentation

### OpenClaw Integration

- CLAUDE.md - Complete OpenClaw on Tenstorrent journey
  - Installation and configuration
  - 70B model deployment
  - vLLM compatibility
  - Production setup

## Benefits

1. ✅ **Expert Knowledge** - OpenClaw knows about all TT hardware, lessons, and deployment
2. ✅ **Always Current** - Documentation updates automatically re-indexed
3. ✅ **Semantic Search** - Finds relevant info even with different wording
4. ✅ **Citations** - Shows where information came from
5. ✅ **Zero Maintenance** - No manual updates needed
6. ✅ **Local First** - No external API dependencies
7. ✅ **Booth Ready** - Can answer visitor questions about hardware and lessons
8. ✅ **Scalable** - Easy to add more documentation

## Next Steps

### For Booth Demo

1. **Start gateway** with memory search
2. **Test queries** about hardware, lessons, deployment
3. **Verify citations** show correct file paths
4. **Practice common questions** visitors might ask

### For Production Use

1. **Monitor indexing** - Check logs for completion
2. **Test thoroughly** - Try various technical questions
3. **Optimize if needed** - Adjust result limits, try QMD backend
4. **Add more docs** - SDK references, API docs, troubleshooting guides

### Future Enhancements

- Create skills to run tt-smi and store output
- Add hardware monitoring skills
- Index past conversations (session indexing)
- Create specialized agents for different topics
- Add SDK and API reference documentation

## Status

- ✅ Configuration added to both ttuser and ttclaw
- ✅ All documentation paths verified
- ✅ Gateway ready to restart with new config
- ⏳ Pending: Gateway restart and indexing
- ⏳ Pending: Testing and verification

## Support

**Documentation:**
- This file: `/home/ttuser/OPENCLAW_MEMORY_SEARCH_SETUP.md`
- Test script: `/home/ttuser/test-openclaw-memory.sh`
- Source plan: Plan in conversation history

**Key Files:**
- Config: `~/.openclaw/openclaw.json`
- Vector DB: `~/.openclaw/memory/*.sqlite`
- Gateway: `./openclaw.sh gateway run`
- TUI: `./openclaw.sh tui`
