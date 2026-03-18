#!/bin/bash
# Start Llama-3.3-70B with tool calling support (Direct Docker method)
# Based on successful configuration from CLAUDE.md

set -e

echo "🛑 Stopping current vLLM containers..."
docker stop tt-inference-server-94e13703 2>/dev/null || true
docker rm tt-inference-server-94e13703 2>/dev/null || true
sleep 2

echo "🚀 Starting vLLM with direct Docker command..."

# Model weights location (from current running container)
WEIGHTS_PATH="/home/ttuser/.cache/huggingface/hub/models--meta-llama--Llama-3.3-70B-Instruct"
WEIGHTS_SNAPSHOT="$WEIGHTS_PATH/snapshots/6f6073b423013f6a7d4d9f39144961bfbfbc386b"

# Volume for cached weights
VOLUME_NAME="volume_id_tt_transformers-Llama-3.3-70B-Instruct"

docker run \
  --rm \
  --name tt-inference-server-70b \
  --env-file /home/ttuser/code/tt-inference-server/.env \
  --ipc host \
  --publish 8000:8000 \
  --device /dev/tenstorrent:/dev/tenstorrent \
  --mount type=bind,src=/dev/hugepages-1G,dst=/dev/hugepages-1G \
  --volume "$VOLUME_NAME:/home/container_app_user/cache_root" \
  -e CACHE_ROOT=/home/container_app_user/cache_root \
  -d \
  ghcr.io/tenstorrent/tt-inference-server/vllm-tt-metal-src-dev-ubuntu-22.04-amd64:0.9.0-e867533-22be241 \
  --model meta-llama/Llama-3.3-70B-Instruct \
  --tt-device p300x2 \
  --no-auth \
  --enable-auto-tool-choice \
  --tool-call-parser llama3_json

echo ""
echo "✅ vLLM container started!"
echo "   Container: tt-inference-server-70b"
echo "   Model: Llama-3.3-70B-Instruct"
echo "   Tool calling: ENABLED (llama3_json)"
echo "   Port: 8000"
echo ""
echo "Monitor logs with:"
echo "  docker logs -f tt-inference-server-70b"
echo ""
echo "Wait 10-30 minutes for model warmup before using."
