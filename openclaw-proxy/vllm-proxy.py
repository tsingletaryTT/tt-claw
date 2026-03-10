#!/usr/bin/env python3
"""
vLLM Compatibility Proxy for OpenClaw

OpenClaw v2026.3.2 sends newer OpenAI API fields (strict, store, prompt_cache_key)
that the vLLM Docker version doesn't support. This proxy strips those fields before
forwarding to vLLM.

Architecture:
  OpenClaw (8001) → Proxy (strips fields) → vLLM (8000) → Tenstorrent
"""

import json
import requests
from http.server import HTTPServer, BaseHTTPRequestHandler
import sys

VLLM_BASE_URL = "http://localhost:8000"
PROXY_PORT = 8001

class ProxyHandler(BaseHTTPRequestHandler):
    def log_message(self, format, *args):
        # Suppress default logging (use --debug for verbose)
        pass

    def do_GET(self):
        """Forward GET requests (health checks, model list)"""
        try:
            url = f"{VLLM_BASE_URL}{self.path}"
            response = requests.get(url, timeout=30)

            self.send_response(response.status_code)
            for header, value in response.headers.items():
                if header.lower() not in ['content-encoding', 'transfer-encoding']:
                    self.send_header(header, value)
            self.end_headers()
            self.wfile.write(response.content)
        except Exception as e:
            self.send_error(502, f"Proxy error: {e}")

    def do_POST(self):
        """Forward POST requests with field stripping"""
        try:
            # Read request body
            content_length = int(self.headers.get('Content-Length', 0))
            body = self.rfile.read(content_length)

            # Parse JSON
            try:
                data = json.loads(body)
            except json.JSONDecodeError:
                # Not JSON, forward as-is
                url = f"{VLLM_BASE_URL}{self.path}"
                response = requests.post(url, data=body, headers=dict(self.headers), timeout=60)
                self.send_response(response.status_code)
                for header, value in response.headers.items():
                    if header.lower() not in ['content-encoding', 'transfer-encoding']:
                        self.send_header(header, value)
                self.end_headers()
                self.wfile.write(response.content)
                return

            # Strip incompatible fields
            data.pop('strict', None)
            data.pop('store', None)
            data.pop('prompt_cache_key', None)

            # Clean messages array
            if 'messages' in data and isinstance(data['messages'], list):
                for message in data['messages']:
                    if isinstance(message, dict):
                        message.pop('strict', None)

            # Forward to vLLM
            url = f"{VLLM_BASE_URL}{self.path}"
            headers = {
                'Content-Type': 'application/json',
            }

            response = requests.post(url, json=data, headers=headers, timeout=60)

            # Send response back to client
            self.send_response(response.status_code)
            for header, value in response.headers.items():
                if header.lower() not in ['content-encoding', 'transfer-encoding']:
                    self.send_header(header, value)
            self.end_headers()
            self.wfile.write(response.content)

        except Exception as e:
            self.send_error(502, f"Proxy error: {e}")

if __name__ == "__main__":
    server = HTTPServer(('127.0.0.1', PROXY_PORT), ProxyHandler)
    print(f"vLLM Compatibility Proxy listening on port {PROXY_PORT}")
    print(f"Forwarding to: {VLLM_BASE_URL}")
    print(f"Stripping fields: strict, store, prompt_cache_key")
    print("")
    print("Press Ctrl+C to stop")

    try:
        server.serve_forever()
    except KeyboardInterrupt:
        print("\nShutting down proxy...")
        server.shutdown()
