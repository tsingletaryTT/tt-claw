#!/bin/bash
# Start Llama-3.3-70B with tool calling support for OpenClaw

set -e

echo "🛑 Stopping current vLLM server..."
pkill -f "run_vllm_api_server" || true
sleep 3

echo "🚀 Starting vLLM with tool calling enabled..."

cd /home/ttuser/code/tt-inference-server

# Run with the required tool calling flags
python3 run.py \
  --model Llama-3.3-70B-Instruct \
  --device p300x2 \
  --workflow server \
  --docker-server \
  --no-auth \
  --skip-system-sw-validation \
  --vllm-override-args '["--enable-auto-tool-choice", "--tool-call-parser", "llama3_json"]'

echo "✅ vLLM server started with tool calling support"
echo "   Model: Llama-3.3-70B-Instruct"
echo "   Tool calling: ENABLED"
echo "   Parser: llama3_json"
