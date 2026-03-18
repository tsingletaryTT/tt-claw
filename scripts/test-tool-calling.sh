#!/bin/bash
# Test if vLLM has tool calling enabled

echo "Testing vLLM tool calling support..."
echo ""

response=$(curl -s -X POST http://localhost:8000/v1/chat/completions \
  -H "Content-Type: application/json" \
  -d '{
    "model": "meta-llama/Llama-3.3-70B-Instruct",
    "messages": [{"role": "user", "content": "What is the weather in San Francisco?"}],
    "tools": [{
      "type": "function",
      "function": {
        "name": "get_weather",
        "description": "Get current weather",
        "parameters": {
          "type": "object",
          "properties": {
            "location": {"type": "string"}
          }
        }
      }
    }],
    "max_tokens": 100
  }' 2>&1)

# Check if response contains tool_calls (good) or plain text (bad)
if echo "$response" | grep -q '"tool_calls"'; then
    echo "✅ SUCCESS: vLLM is making proper tool calls!"
    echo ""
    echo "Response structure:"
    echo "$response" | jq '.choices[0].message' 2>/dev/null || echo "$response"
elif echo "$response" | grep -q '"content".*"type".*"function"'; then
    echo "❌ FAILED: vLLM is generating text that LOOKS like tool calls"
    echo ""
    echo "This means tool calling is NOT enabled."
    echo "The response contains JSON as text instead of structured tool calls."
    echo ""
    echo "Fix: Run ./scripts/start-vllm-70b-direct.sh"
elif echo "$response" | grep -q "error"; then
    echo "❌ ERROR: vLLM returned an error"
    echo ""
    echo "$response" | jq . 2>/dev/null || echo "$response"
else
    echo "⚠️  UNCLEAR: Response doesn't match expected patterns"
    echo ""
    echo "Full response:"
    echo "$response" | jq . 2>/dev/null || echo "$response"
fi

echo ""
