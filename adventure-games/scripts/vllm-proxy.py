#!/usr/bin/env python3
"""
OpenClaw-to-vLLM Compatibility Proxy

Strips unsupported OpenAI API fields that OpenClaw sends but vLLM doesn't support:
- tool_choice
- tools (when empty)
- parallel_tool_calls
- Other OpenClaw-specific fields

Usage:
    python3 vllm-openclaw-proxy.py

Then point OpenClaw to: http://localhost:8001/v1
"""

from flask import Flask, request, Response
import requests
import json

app = Flask(__name__)

VLLM_URL = "http://localhost:8000"

# Fields to strip from requests
STRIP_FIELDS = [
    'tool_choice',
    'parallel_tool_calls',
    'tools',  # Only strip if empty
]

@app.route('/v1/<path:path>', methods=['GET', 'POST', 'PUT', 'DELETE', 'PATCH'])
def proxy(path):
    """Proxy requests to vLLM, stripping unsupported fields"""

    # Build target URL
    url = f"{VLLM_URL}/v1/{path}"

    # Get request data
    if request.method == 'POST' and request.is_json:
        data = request.get_json()

        # Strip problematic fields
        for field in STRIP_FIELDS:
            if field in data:
                # Special case: only strip 'tools' if it's empty
                if field == 'tools' and data[field]:
                    continue
                print(f"[STRIP] Removing field: {field} = {data[field]}")
                del data[field]

        # Forward to vLLM
        response = requests.request(
            method=request.method,
            url=url,
            headers={k: v for k, v in request.headers if k.lower() != 'host'},
            json=data,
            allow_redirects=False
        )
    else:
        # Forward other requests as-is
        response = requests.request(
            method=request.method,
            url=url,
            headers={k: v for k, v in request.headers if k.lower() != 'host'},
            data=request.get_data(),
            allow_redirects=False
        )

    # Return response
    return Response(
        response.content,
        status=response.status_code,
        headers=dict(response.headers)
    )

@app.route('/health')
def health():
    """Health check endpoint"""
    try:
        resp = requests.get(f"{VLLM_URL}/health", timeout=2)
        if resp.status_code == 200:
            return {"status": "healthy", "vllm": "ok"}
        else:
            return {"status": "degraded", "vllm": f"HTTP {resp.status_code}"}, 503
    except Exception as e:
        return {"status": "unhealthy", "vllm": str(e)}, 503

if __name__ == '__main__':
    print("=" * 60)
    print("OpenClaw-to-vLLM Compatibility Proxy")
    print("=" * 60)
    print(f"Listening on:  http://localhost:8001")
    print(f"Forwarding to: {VLLM_URL}")
    print(f"")
    print("Configure OpenClaw to use: http://127.0.0.1:8001/v1")
    print("=" * 60)
    print("")

    app.run(host='127.0.0.1', port=8001, debug=False)
