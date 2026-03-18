# Superior Memory Implementations for OpenClaw

**Research Date:** 2026-03-18
**Current Status:** Built-in memory search not working reliably

## Current Problem

OpenClaw's built-in memory search:
- ✅ Has 1,217 chunks indexed from 174 files
- ✅ Database exists (51MB main.sqlite)
- ❌ **Agent doesn't actually use it** - returns general knowledge instead
- ❌ No reliable way to force agent to search before answering

## Superior Alternatives (2026)

### 1. **memsearch** - Extracted OpenClaw Memory (Recommended) ⭐

**What it is:** Fully independent long-term memory library implementing OpenClaw's memory architecture without the rest of the stack.

**Key Features:**
- Hybrid search (vector + keyword) via SQLite
- Temporal decay (recent memories rank higher)
- MMR (Maximum Marginal Relevance) for diverse results
- Can be plugged into any agent framework
- Same proven architecture as OpenClaw, but standalone

**Why choose this:**
- ✅ Drop-in replacement for OpenClaw's memory
- ✅ More reliable than built-in
- ✅ Actively maintained
- ✅ Can debug/customize easily

**Implementation:**
```python
from memsearch import MemoryStore

store = MemoryStore("~/tt-claw/runtime/memory/memsearch.db")
store.index_directory("/home/ttuser/code/tt-vscode-toolkit/content/lessons")
results = store.search("What is QB2?", top_k=5)
```

**Source:** [Milvus Blog - We Extracted OpenClaw's Memory System](https://milvus.io/blog/we-extracted-openclaws-memory-system-and-opensourced-it-memsearch.md)

---

### 2. **OpenViking** - Directory-Based Context Database ⭐⭐

**What it is:** Open-source context database with filesystem-based memory using `viking://` protocol.

**Key Features:**
- Virtual filesystem: `viking://resources/`, `viking://user/`, `viking://agent/`
- Directory Recursive Retrieval (drill down into subdirectories)
- Hierarchical knowledge organization
- **Performance:** 52.08% task completion vs 35.65% for built-in
- **Efficiency:** 4.2M tokens vs 24.6M tokens (5.7x more efficient!)

**Why choose this:**
- ✅ **Dramatically better performance** (52% vs 36% completion)
- ✅ Human-editable directory structure
- ✅ Hierarchical organization matches our use case (lessons by topic)
- ✅ Available as OpenClaw plugin

**Implementation:**
```bash
# Install OpenViking plugin for OpenClaw
openclaw plugins install openviking

# Configure in openclaw.json
{
  "plugins": {
    "openviking": {
      "root": "~/tt-claw/knowledge",
      "enabled": true
    }
  }
}

# Organize knowledge
~/tt-claw/knowledge/
├── hardware/         # P300, QB2, etc.
├── software/         # tt-metal, vLLM, etc.
└── tutorials/        # Step-by-step guides
```

**Source:** [MarkTechPost - Meet OpenViking](https://www.marktechpost.com/2026/03/15/meet-openviking-an-open-source-context-database-that-brings-filesystem-based-memory-and-retrieval-to-ai-agent-systems-like-openclaw/)

---

### 3. **MCP Memory Server** - Standardized Protocol ⭐

**What it is:** Memory server using Model Context Protocol (MCP) - standard adopted by Anthropic, OpenAI, Block.

**Key Features:**
- Standardized JSON-RPC 2.0 protocol
- Global + per-project memory
- Structured storage (preferences, entities, journal)
- Multiple embedding providers (OpenAI, Ollama)
- OpenClaw communicates via MCP protocol

**Why choose this:**
- ✅ Industry standard (Linux Foundation)
- ✅ Works with Claude.ai, OpenClaw, custom agents
- ✅ Clean separation (memory server is separate process)
- ✅ Multiple implementations available

**Implementation:**
```yaml
# openclaw.yaml
mcpServers:
  memory:
    command: python
    args:
      - -m
      - mcp_memory_server
    env:
      MEMORY_DIR: /home/ttuser/tt-claw/runtime/memory
      EMBEDDING_PROVIDER: ollama
```

**Sources:**
- [OpenClaw Memory MCP Server](https://lobehub.com/mcp/liuhao6741-openclaw-memory)
- [How to Use MCP With OpenClaw](https://safeclaw.io/blog/openclaw-mcp)

---

### 4. **ZeroClaw** - SQLite-Native Hybrid Search

**What it is:** Lightweight memory using only SQLite extensions (FTS5 + sqlite-vec).

**Key Features:**
- Single binary (no Python dependencies)
- Hybrid search built-in
- Fast and minimal
- Good for embedded systems

**Why choose this:**
- ✅ Minimal dependencies
- ✅ Fast startup
- ✅ Self-contained

**Not ideal because:**
- ❌ Less feature-rich than memsearch/OpenViking
- ❌ Limited ecosystem

**Source:** [Local-First RAG with SQLite](https://www.pingcap.com/blog/local-first-rag-using-sqlite-ai-agent-memory-openclaw/)

---

## Recommendations by Use Case

### For TT-Claw Project (Best Choice): **OpenViking + memsearch**

**Why this combination:**
1. **OpenViking** for hierarchical knowledge organization
   - Lessons organized by topic
   - Hardware docs in `viking://hardware/`
   - Model deployment in `viking://deployment/`
   - 52% completion rate (vs 36%)

2. **memsearch** for reliable search
   - Fallback if OpenViking fails
   - Proven OpenClaw-compatible
   - Easy to debug

**Implementation Plan:**
```
~/tt-claw/knowledge/          # OpenViking root
├── hardware/
│   ├── qb2/                  # QB2 FAQs and specs
│   ├── p300/                 # P300 device info
│   └── architecture/         # Chip architecture
├── software/
│   ├── tt-metal/             # TT-Metal docs
│   ├── vllm/                 # vLLM deployment
│   └── openclaw/             # OpenClaw setup
└── lessons/                  # 45+ interactive lessons
    ├── beginner/
    ├── intermediate/
    └── advanced/
```

**Benefits:**
- ✅ 5.7x more token-efficient
- ✅ 46% better task completion
- ✅ Human-editable structure
- ✅ Easy to add new knowledge
- ✅ Works with existing indexed content

---

## Migration Path

### Phase 1: Test OpenViking (Recommended First)

1. **Install OpenViking plugin:**
   ```bash
   cd ~/openclaw
   ./openclaw.sh plugins install openviking
   ```

2. **Organize existing knowledge:**
   ```bash
   mkdir -p ~/tt-claw/knowledge/{hardware,software,lessons}
   ln -s /home/ttuser/code/tt-vscode-toolkit/content/lessons ~/tt-claw/knowledge/lessons/all
   ```

3. **Configure OpenClaw:**
   ```json
   {
     "plugins": {
       "openviking": {
         "root": "/home/ttuser/tt-claw/knowledge",
         "enabled": true
       }
     }
   }
   ```

4. **Test:**
   ```bash
   ~/tt-claw/bin/openclaw agent --message "What is QB2?"
   # Should now search viking://hardware/qb2/ first
   ```

### Phase 2: Add memsearch as Fallback (If Needed)

1. **Install memsearch:**
   ```bash
   pip install memsearch
   ```

2. **Configure dual memory:**
   ```json
   {
     "memorySearch": {
       "primary": "openviking",
       "fallback": "memsearch",
       "memsearch": {
         "db_path": "/home/ttuser/tt-claw/runtime/memory/memsearch.db"
       }
     }
   }
   ```

3. **Index existing content:**
   ```python
   from memsearch import MemoryStore
   store = MemoryStore("~/tt-claw/runtime/memory/memsearch.db")
   store.index_directory("~/tt-claw/knowledge")
   ```

### Phase 3: Consider MCP (Long-term)

If you want to use memory across multiple tools (Claude.ai + OpenClaw + custom scripts):

1. Set up MCP memory server
2. Configure all tools to use same MCP endpoint
3. Unified memory across entire ecosystem

---

## Key Insights from Research

### What's Working in 2026:

1. **Hybrid Search is King**
   - Vector search alone misses exact matches
   - Keyword search alone misses semantic matches
   - Hybrid gets both

2. **Temporal Decay Matters**
   - Recent memories should rank higher
   - Old info naturally fades (unless manually boosted)

3. **Human-Editable Storage**
   - Markdown files win over binary blobs
   - Easier to debug, edit, version control
   - Transparency builds trust

4. **Directory Hierarchy Works**
   - OpenViking's 52% vs 36% proves it
   - Natural for organizing technical docs
   - Recursive retrieval finds specific context

### What Doesn't Work:

1. **Pure Vector Search**
   - Misses exact string matches
   - Expensive to reindex
   - Black box results

2. **Built-in "Magic"**
   - OpenClaw's built-in memory is unreliable
   - Agent doesn't consistently use it
   - No forcing mechanism

3. **One-Size-Fits-All**
   - Different use cases need different strategies
   - Technical docs ≠ chat history ≠ preferences

---

## Next Steps for TT-Claw

1. **Immediate:** Install OpenViking plugin
2. **Test:** Verify it actually uses indexed knowledge
3. **Organize:** Structure knowledge into hierarchy
4. **Measure:** Compare completion rate vs built-in
5. **Document:** Update ARCHITECTURE.md with new memory system

**Expected Outcome:**
- Agent consistently uses indexed knowledge
- 46% better task completion
- 5.7x more token-efficient
- Human-editable knowledge base

---

## Sources

- [Milvus Blog - memsearch](https://milvus.io/blog/we-extracted-openclaws-memory-system-and-opensourced-it-memsearch.md)
- [MarkTechPost - OpenViking](https://www.marktechpost.com/2026/03/15/meet-openviking-an-open-source-context-database-that-brings-filesystem-based-memory-and-retrieval-to-ai-agent-systems-like-openclaw/)
- [OpenClaw Memory Docs](https://docs.openclaw.ai/concepts/memory)
- [OpenClaw Memory MCP Server](https://lobehub.com/mcp/liuhao6741-openclaw-memory)
- [SafeClaw - MCP Integration](https://safeclaw.io/blog/openclaw-mcp)
- [PingCAP - SQLite RAG](https://www.pingcap.com/blog/local-first-rag-using-sqlite-ai-agent-memory-openclaw/)
- [2026 Complete Guide to memorySearch](https://dev.to/czmilo/2026-complete-guide-to-openclaw-memorysearch-supercharge-your-ai-assistant-49oc)

---

**Status:** Ready to implement OpenViking for dramatically better memory performance!
