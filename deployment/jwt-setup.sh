#!/bin/bash
# JWT Authentication Setup for tt-inference-server + OpenClaw
# Created: 2026-03-09

# JWT Secret (shared between vLLM server and OpenClaw client)
export JWT_SECRET="testing"

# Generate JWT token for OpenClaw
JWT_TOKEN=$(python3 -c 'import jwt; print(jwt.encode({"team_id":"tenstorrent","token_id":"openclaw-qb2"}, "testing", algorithm="HS256"))')

echo "==================================================================="
echo "JWT Authentication Configuration"
echo "==================================================================="
echo ""
echo "JWT_SECRET: testing"
echo "JWT_TOKEN:  $JWT_TOKEN"
echo ""
echo "This token is valid for:"
echo "  - vLLM server: http://localhost:8000"
echo "  - OpenClaw API calls"
echo ""
echo "To update OpenClaw config:"
echo "  1. sudo su - ttclaw"
echo "  2. Edit ~/.openclaw/openclaw.json"
echo "  3. Update models.providers.vllm.apiKey to: $JWT_TOKEN"
echo ""
echo "To test authentication:"
echo "  curl -H 'Authorization: Bearer $JWT_TOKEN' http://localhost:8000/v1/models"
echo ""
echo "==================================================================="
