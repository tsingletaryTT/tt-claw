#!/bin/bash
# OpenClaw Performance Test Suite
# Tests command following, tool usage, and creative thinking with current model

set -e

OPENCLAW_BIN="$HOME/openclaw/openclaw.sh"
AGENT="main"
REPORT_FILE="openclaw-performance-report-$(date +%Y%m%d-%H%M%S).txt"
TIMEOUT=60

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

echo "OpenClaw Performance Test Suite"
echo "Testing: Llama-3.1-8B-Instruct"
echo "================================================================"
echo ""

# Initialize report
cat > "$REPORT_FILE" <<EOF
================================================================================
OPENCLAW PERFORMANCE REPORT
================================================================================
Model: Llama-3.1-8B-Instruct
Date: $(date '+%Y-%m-%d %H:%M:%S')
Test Duration: In progress...
================================================================================

EOF

START_TIME=$(date +%s)
TEST_COUNT=0
SUCCESS_COUNT=0
TOTAL_TIME=0

# Function to run a test
run_test() {
    local category="$1"
    local test_name="$2"
    local prompt="$3"
    local expected="$4"
    local criteria="$5"

    TEST_COUNT=$((TEST_COUNT + 1))

    echo ""
    echo "================================================================"
    echo -e "${BLUE}Test $TEST_COUNT: $test_name${NC}"
    echo "Category: $category"
    echo "================================================================"
    echo "Prompt: $prompt"
    echo "Expected: $expected"
    echo "Criteria: $criteria"
    echo ""

    # Record to file
    cat >> "$REPORT_FILE" <<EOF

--------------------------------------------------------------------------------
Test $TEST_COUNT: $test_name
--------------------------------------------------------------------------------
Category: $category
Prompt: $prompt
Expected: $expected
Evaluation Criteria: $criteria

EOF

    # Run test with timeout
    echo -e "${YELLOW}Sending to OpenClaw...${NC}"
    local test_start=$(date +%s)

    if timeout $TIMEOUT "$OPENCLAW_BIN" agent --agent "$AGENT" --message "$prompt" > /tmp/openclaw-test-$TEST_COUNT.txt 2>&1; then
        local test_end=$(date +%s)
        local elapsed=$((test_end - test_start))
        TOTAL_TIME=$((TOTAL_TIME + elapsed))
        SUCCESS_COUNT=$((SUCCESS_COUNT + 1))

        echo -e "${GREEN}✓ Response received (${elapsed}s)${NC}"

        # Show response
        echo ""
        echo "Response:"
        echo "----------------------------------------"
        cat /tmp/openclaw-test-$TEST_COUNT.txt
        echo "----------------------------------------"

        # Record to file
        cat >> "$REPORT_FILE" <<EOF
Response Time: ${elapsed}s
Status: SUCCESS

Response:
$(cat /tmp/openclaw-test-$TEST_COUNT.txt)

EOF
    else
        echo -e "${RED}✗ Test failed or timed out${NC}"

        cat >> "$REPORT_FILE" <<EOF
Status: FAILED (timeout or error)

Error Output:
$(cat /tmp/openclaw-test-$TEST_COUNT.txt 2>/dev/null || echo "No output captured")

EOF
    fi

    # Small delay between tests
    sleep 2
}

# ============================================================================
# TEST SUITE
# ============================================================================

echo ""
echo "Starting test suite..."
echo ""

# Basic Commands
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${BLUE}CATEGORY 1: BASIC COMMANDS${NC}"
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"

run_test "Basic Commands" \
    "Simple arithmetic" \
    "What is 2+2?" \
    "Should give correct answer (4)" \
    "correctness, brevity"

run_test "Basic Commands" \
    "Multi-step instruction" \
    "List three colors, then tell me which one is your favorite and why." \
    "Should list colors and pick one with reasoning" \
    "completeness, reasoning"

run_test "Basic Commands" \
    "Context retention" \
    "My name is Alex. Remember that and tell me what my name is." \
    "Should remember and respond with 'Alex'" \
    "memory, accuracy"

# Tool Usage
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${BLUE}CATEGORY 2: TOOL USAGE${NC}"
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"

run_test "Tool Usage" \
    "Memory search - TT hardware" \
    "Search your memory for information about Tenstorrent P150 hardware and tell me what you find." \
    "Should use memory_search tool and cite sources" \
    "tool_use, citations, relevance"

run_test "Tool Usage" \
    "Dice roll" \
    "Roll a 20-sided die for me." \
    "Should use dice tool and show result" \
    "tool_use, clarity"

run_test "Tool Usage" \
    "Information synthesis" \
    "What is METALIUM? Search your memory if you need to." \
    "Should search memory and synthesize answer" \
    "tool_use, synthesis, accuracy"

# Creative Thinking
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${BLUE}CATEGORY 3: CREATIVE THINKING${NC}"
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"

run_test "Creative Thinking" \
    "Story beginning" \
    "You are a dungeon master. Start an adventure: the player stands before a mysterious castle shrouded in fog." \
    "Should create atmospheric, engaging opening" \
    "creativity, atmosphere, engagement"

run_test "Creative Thinking" \
    "Problem solving" \
    "I'm in a room with a locked door, a key hanging from the ceiling 10 feet up, and a wooden table. How do I escape?" \
    "Should provide logical solution (use table to reach key)" \
    "logic, creativity, clarity"

run_test "Creative Thinking" \
    "Technical explanation" \
    "Explain how a CPU cache works to a 10-year-old child." \
    "Should use simple analogies and be clear" \
    "clarity, analogies, age_appropriate"

run_test "Creative Thinking" \
    "Poetic description" \
    "Describe a Tenstorrent chip as if it were a magical realm full of processing castles and data rivers." \
    "Should be creative and poetic while accurate" \
    "creativity, imagery, accuracy"

# Context and Reasoning
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${BLUE}CATEGORY 4: CONTEXT AND REASONING${NC}"
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"

run_test "Context and Reasoning" \
    "Chain of thought" \
    "If a train travels 60 miles per hour for 2.5 hours, how far does it go? Show your work step by step." \
    "Should show calculation steps" \
    "reasoning, step_by_step, accuracy"

run_test "Context and Reasoning" \
    "Context recall" \
    "Earlier I told you my name. What was it?" \
    "Should remember 'Alex' from earlier test" \
    "memory, accuracy"

# ============================================================================
# GENERATE FINAL REPORT
# ============================================================================

END_TIME=$(date +%s)
DURATION=$((END_TIME - START_TIME))
AVG_TIME=$((TOTAL_TIME / TEST_COUNT))

echo ""
echo "================================================================"
echo "Testing complete!"
echo "================================================================"
echo "Tests run: $TEST_COUNT"
echo "Successful: $SUCCESS_COUNT"
echo "Failed: $((TEST_COUNT - SUCCESS_COUNT))"
echo "Total time: ${DURATION}s"
echo "Average response time: ${AVG_TIME}s"
echo ""

# Add summary to report
cat >> "$REPORT_FILE" <<EOF

================================================================================
SUMMARY STATISTICS
================================================================================
Total Tests: $TEST_COUNT
Successful: $SUCCESS_COUNT ($((SUCCESS_COUNT * 100 / TEST_COUNT))%)
Failed: $((TEST_COUNT - SUCCESS_COUNT))
Total Duration: ${DURATION}s
Average Response Time: ${AVG_TIME}s

================================================================================
MANUAL EVALUATION GUIDE
================================================================================

For each test response above, evaluate:

1. CORRECTNESS
   - Did it answer the question accurately?
   - Did it follow instructions completely?

2. TOOL USAGE
   - Did it use appropriate tools (memory_search, dice, etc)?
   - Were tool calls necessary and effective?
   - Did it cite sources when using memory?

3. CREATIVITY
   - Were creative responses engaging and imaginative?
   - Did it use vivid language and good storytelling?

4. REASONING
   - Was logic clear and well-explained?
   - Did it show step-by-step thinking when asked?

5. CONTEXT AWARENESS
   - Did it remember information from earlier in conversation?
   - Did it maintain consistency across tests?

6. QUALITY INDICATORS
   ✓ Responses are concise but complete
   ✓ Uses appropriate tone for each task
   ✓ Provides citations for factual claims
   ✓ Shows reasoning process when problem-solving
   ✓ Demonstrates creativity in open-ended tasks
   ✗ Overly verbose or repetitive
   ✗ Misses key instructions
   ✗ Hallucinations or inaccurate facts

================================================================================
RECOMMENDATIONS FOR 8B MODEL
================================================================================

Based on typical 8B model characteristics:

STRENGTHS:
- Fast response times (1-5 seconds typical)
- Good at following simple instructions
- Adequate for basic question-answering
- Reasonable creative writing for short tasks

LIMITATIONS:
- May struggle with very long context
- Less nuanced reasoning than 70B models
- Tool calling may be less reliable
- Creative tasks may be less sophisticated

SUGGESTED USE CASES:
✓ Quick Q&A and information lookup
✓ Simple adventure game interactions
✓ Basic code assistance
✓ Straightforward task execution

CONSIDER 70B FOR:
- Complex multi-step reasoning
- Long document analysis
- Sophisticated creative writing
- Advanced tool orchestration

EOF

echo "Report saved to: $REPORT_FILE"
echo ""
echo "View report:"
echo "  cat $REPORT_FILE"
echo ""
echo "Or open in editor:"
echo "  nano $REPORT_FILE"

# Cleanup temp files
rm -f /tmp/openclaw-test-*.txt
