# SPDX-License-Identifier: Apache-2.0
#
# vLLM ASGI middleware: strips OpenClaw-specific fields before Pydantic validation.
#
# Install via vLLM's --middleware flag:
#   --middleware openclaw_compat_middleware.strip_openclaw_fields
#
# The module must be importable from inside the container. Mount it to a path on
# PYTHONPATH (e.g. TT_METAL_HOME = /home/container_app_user/tt-metal):
#
#   --mount type=bind,\
#     src=/home/ttuser/tt-claw/proxy/openclaw_compat_middleware.py,\
#     dst=/home/container_app_user/tt-metal/openclaw_compat_middleware.py,\
#     readonly
#
# Then add to vllm_override_args in model_spec.py (or run.py --vllm-override-args):
#   "middleware": ["openclaw_compat_middleware.strip_openclaw_fields"]
#
# Fields stripped (OpenClaw v2026.3.2 sends these; vLLM ignores them anyway with
# extra="allow", but this middleware provides explicit, version-proof removal):
#
#   strict           — OpenAI strict JSON schema flag; not a top-level chat field
#   store            — OpenAI Responses API field; not in ChatCompletionRequest
#   prompt_cache_key — OpenAI prompt caching key; not in vLLM's model
#
# Handles streaming responses correctly: body modification is done before the
# request body is read, so it's transparent to the inference path.

from __future__ import annotations

import json
from starlette.types import ASGIApp, Message, Receive, Scope, Send

_STRIP_FIELDS = frozenset({"strict", "store", "prompt_cache_key"})
_CHAT_PATH_SUFFIX = b"/chat/completions"


class _BufferedReceive:
    """Wraps the ASGI receive channel with a modified body."""

    __slots__ = ("_body", "_sent")

    def __init__(self, body: bytes) -> None:
        self._body = body
        self._sent = False

    async def __call__(self) -> Message:
        if not self._sent:
            self._sent = True
            return {"type": "http.request", "body": self._body, "more_body": False}
        # Signal no more body after the first message
        return {"type": "http.request", "body": b"", "more_body": False}


class OpenClawCompatMiddleware:
    """Pure ASGI middleware: strips unsupported top-level fields from chat requests.

    Use with vLLM's --middleware flag:
        --middleware openclaw_compat_middleware.OpenClawCompatMiddleware
    """

    def __init__(self, app: ASGIApp) -> None:
        self.app = app

    async def __call__(self, scope: Scope, receive: Receive, send: Send) -> None:
        if scope["type"] != "http":
            await self.app(scope, receive, send)
            return

        # Only intercept POST requests to */chat/completions
        if scope.get("method") != "POST":
            await self.app(scope, receive, send)
            return
        path: bytes = scope.get("path", "").encode()
        if not path.endswith(_CHAT_PATH_SUFFIX):
            await self.app(scope, receive, send)
            return

        # Buffer the request body
        body_parts: list[bytes] = []
        while True:
            message: Message = await receive()
            body_parts.append(message.get("body", b""))
            if not message.get("more_body", False):
                break
        raw_body = b"".join(body_parts)

        # Strip incompatible fields
        modified_body = _strip_fields(raw_body)

        # Replace receive with one that yields the modified body
        await self.app(scope, _BufferedReceive(modified_body), send)


async def strip_openclaw_fields(request, call_next):
    """HTTP middleware function variant for use with @app.middleware('http').

    Use with vLLM's --middleware flag:
        --middleware openclaw_compat_middleware.strip_openclaw_fields

    Note: this variant requires starlette's Request body buffering, which works
    fine for vLLM's typical request sizes but adds one extra read/re-serialize
    round-trip. Prefer OpenClawCompatMiddleware (the class variant) for
    production deployments.
    """
    from starlette.requests import Request
    from starlette.datastructures import Headers

    req = Request(request.scope, request.receive)
    if req.method == "POST" and req.url.path.endswith("/chat/completions"):
        raw = await req.body()
        modified = _strip_fields(raw)
        if modified is not raw:
            # Re-wrap request so FastAPI reads the modified body
            req._body = modified

    return await call_next(req)


def _strip_fields(raw_body: bytes) -> bytes:
    """Return a JSON body with _STRIP_FIELDS removed, or raw_body unchanged."""
    if not raw_body:
        return raw_body
    try:
        data: dict = json.loads(raw_body)
    except (ValueError, TypeError):
        return raw_body

    removed = [f for f in _STRIP_FIELDS if f in data]
    if not removed:
        return raw_body

    for field in removed:
        del data[field]
    return json.dumps(data, separators=(",", ":")).encode()
