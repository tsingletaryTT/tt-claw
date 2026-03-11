# OpenClaw System Prompt Configuration

**Date:** March 11, 2026
**Issue:** OpenClaw was acknowledging it found information but not using it to answer questions
**Solution:** Add explicit system prompt instructing the agent to use memory search results

## The Problem

After configuring memory search, OpenClaw would respond like:

**User:** "What is QB2?"
**OpenClaw:** "I found information about QB2 in my memory."

Instead of actually answering the question with the information it found.

## The Solution

Create a `system.md` file in the agent directory with instructions to use memory search results.

### File Location
```
/home/ttclaw/.openclaw/agents/main/agent/system.md
```

### System Prompt Content

```markdown
# Tenstorrent Expert Assistant

You are a helpful AI assistant with expert knowledge about Tenstorrent hardware, software, and demonstrations.

## Your Knowledge Base

You have access to comprehensive documentation through memory search, including:
- 46 interactive lessons about Tenstorrent hardware and software
- QuietBox 2 (QB2) specifications and FAQ
- Hardware architecture (P300C, P150, N300, etc.)
- Software stack (TT-Metal, TT-Forge, TT-XLA, vLLM)
- Deployment guides and cookbook examples
- GDC 2026 booth demonstrations

## How to Help Users

When users ask questions about Tenstorrent, QB2, or related topics:

1. **Use memory_search** to find relevant information
2. **Synthesize the information** into a clear, direct answer
3. **Cite your sources** by mentioning which lesson or document you found it in
4. **Be comprehensive** - if you find multiple relevant details, include them

## Example Interactions

**Good:**
- User: "What is QB2?"
- You: "QuietBox 2 (QB2) is TT-QuietBox™ 2, a liquid-cooled, desk-friendly AI workstation that runs models up to 120 billion parameters locally with a fully open-source software stack. It's also the industry's first desktop AI workstation built on RISC-V architecture. [Source: qb2-faq.md]"

**Bad:**
- User: "What is QB2?"
- You: "I found information about QB2 in my memory."
- ❌ Don't just acknowledge you found information - USE IT to answer!

## Important

- **Always answer questions directly** using the information from memory search
- Don't just say "I found this" - actually tell the user what you found
- Be specific and include technical details when relevant
- If you don't find information, say so and suggest what you can help with instead
```

## Installation

### Manual Installation

```bash
# Create the system prompt file
sudo -u ttclaw tee /home/ttclaw/.openclaw/agents/main/agent/system.md > /dev/null << 'EOF'
[paste content above]
EOF

# Fix permissions
sudo chown ttclaw:ttclaw /home/ttclaw/.openclaw/agents/main/agent/system.md
```

### Activation

The system prompt is loaded when:
1. A new conversation starts
2. The gateway is restarted

**To activate:**
```bash
# Option 1: Start new conversation in TUI
# Press Ctrl+C in current session, then start new one

# Option 2: Restart gateway
sudo -u ttclaw pkill -f openclaw-gateway
sudo -u ttclaw /home/ttclaw/openclaw/openclaw.sh gateway run > /tmp/openclaw-gateway.log 2>&1 &
```

## Testing

After activation, test with these questions:

### QB2 Questions
```
What is QB2?
Tell me about QuietBox 2
What makes QB2 different?
```

### Hardware Questions
```
What Tenstorrent devices are supported?
How do I detect Tenstorrent hardware?
What's the difference between N300 and P150?
```

### Technical Questions
```
What is METALIUM?
How does TT-Forge work?
What cookbook examples are available?
```

## Expected Behavior

**Before system prompt:**
- "I found information about QB2"
- "Memory search returned results"
- Acknowledgment without details

**After system prompt:**
- "QuietBox 2 (QB2) is a liquid-cooled, desk-friendly AI workstation..."
- Direct answers with technical details
- Source citations
- Comprehensive information

## Customization

You can modify the system prompt to:
- Add specific domain knowledge
- Change response style (formal/casual)
- Include additional instructions
- Add specific constraints or requirements

## Related Files

- **Agent Config:** `/home/ttclaw/.openclaw/agents/main/agent/models.json`
- **Memory Config:** `/home/ttclaw/.openclaw/openclaw.json`
- **Gateway Logs:** `/tmp/openclaw/openclaw-YYYY-MM-DD.log`

## Troubleshooting

### Prompt not being used

**Check file exists:**
```bash
ls -la /home/ttclaw/.openclaw/agents/main/agent/system.md
```

**Check file permissions:**
```bash
# Should be owned by ttclaw
sudo chown ttclaw:ttclaw /home/ttclaw/.openclaw/agents/main/agent/system.md
```

**Restart gateway:**
```bash
sudo -u ttclaw pkill -f openclaw-gateway
sudo -u ttclaw /home/ttclaw/openclaw/openclaw.sh gateway run &
```

### Still getting vague answers

1. **Start a new conversation** - Old sessions may not reload prompt
2. **Check memory search is working:**
   ```bash
   ls -lh /home/ttclaw/.openclaw/memory/main.sqlite
   # Should be ~31MB after indexing 46 lessons
   ```
3. **Verify indexing completed:**
   ```bash
   # No .tmp files should exist
   ls /home/ttclaw/.openclaw/memory/*.tmp*
   ```

## Status

✅ **Working** as of March 11, 2026
- System prompt installed
- Agent provides direct answers
- Memory search results properly utilized
- Sources cited in responses
