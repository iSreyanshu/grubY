#!/usr/bin/env python
import asyncio
import inspect
import json
import os
import sys
import traceback
from typing import Any
from typing import Dict

from telethon import TelegramClient
from telethon.sessions import StringSession
from pytgcalls import PyTgCalls
from pytgcalls.types import GroupCallConfig


class BridgeState:
    def __init__(self) -> None:
        self.client: TelegramClient | None = None
        self.calls: PyTgCalls | None = None
        self.initialized = False


def to_jsonable(value: Any) -> Any:
    if value is None:
        return None
    if isinstance(value, (str, int, float, bool)):
        return value
    if isinstance(value, dict):
        return {str(k): to_jsonable(v) for k, v in value.items()}
    if isinstance(value, (list, tuple, set)):
        return [to_jsonable(v) for v in value]
    if hasattr(value, "model_dump"):
        try:
            return to_jsonable(value.model_dump())
        except Exception:
            pass
    if hasattr(value, "__dict__"):
        return to_jsonable(vars(value))
    return str(value)


async def do_init(state: BridgeState, payload: Dict[str, Any]) -> Dict[str, Any]:
    if state.initialized:
        return {"ok": True, "data": {"already_initialized": True}}

    session_name = payload.get("session_name") or "gruby_ntgcalls"
    api_id = int(payload["api_id"])
    api_hash = str(payload["api_hash"])
    session_string = payload.get("session_string") or ""
    bot_token = payload.get("bot_token")
    workdir = payload.get("workdir") or "storage/ntgcalls"

    # Telethon backend:
    # If session_string is empty, Telethon stores session file in workdir/session_name.
    session_obj: StringSession | str
    if session_string:
        session_obj = StringSession(session_string)
    else:
        os.makedirs(workdir, exist_ok=True)
        session_obj = os.path.join(workdir, session_name)

    state.client = TelegramClient(session_obj, api_id, api_hash)
    if bot_token:
        await state.client.start(bot_token=bot_token)
    else:
        await state.client.start()

    state.calls = PyTgCalls(state.client)
    await state.calls.start()
    state.initialized = True
    return {"ok": True, "data": {"initialized": True, "backend": "telethon"}}


async def ensure_ready(state: BridgeState) -> None:
    if not state.initialized or state.calls is None:
        raise RuntimeError("Bridge is not initialized; call init first.")


async def do_play(state: BridgeState, payload: Dict[str, Any]) -> Dict[str, Any]:
    await ensure_ready(state)
    chat_id = payload["chat_id"]
    stream = payload["stream"]
    config = GroupCallConfig(
        invite_hash=payload.get("invite_hash"),
        join_as=payload.get("join_as"),
        auto_start=bool(payload.get("auto_start", True)),
    )
    result = await state.calls.play(chat_id, stream=stream, config=config)
    return {"ok": True, "data": to_jsonable(result)}


async def do_call_method(state: BridgeState, payload: Dict[str, Any]) -> Dict[str, Any]:
    await ensure_ready(state)
    method = str(payload["method"])
    args = payload.get("args") or []
    kwargs = payload.get("kwargs") or {}
    fn = getattr(state.calls, method)
    result = fn(*args, **kwargs)
    if inspect.isawaitable(result):
        result = await result
    return {"ok": True, "data": to_jsonable(result)}


async def do_call_ntg(state: BridgeState, payload: Dict[str, Any]) -> Dict[str, Any]:
    await ensure_ready(state)
    method = str(payload["method"])
    args = payload.get("args") or []
    kwargs = payload.get("kwargs") or {}
    binding = getattr(state.calls, "_binding")
    fn = getattr(binding, method)
    result = fn(*args, **kwargs)
    if inspect.isawaitable(result):
        result = await result
    return {"ok": True, "data": to_jsonable(result)}


async def do_list_methods(state: BridgeState) -> Dict[str, Any]:
    await ensure_ready(state)
    methods = sorted(
        name
        for name in dir(state.calls)
        if callable(getattr(state.calls, name, None)) and not name.startswith("_")
    )
    return {"ok": True, "data": methods}


async def do_list_ntg_methods(state: BridgeState) -> Dict[str, Any]:
    await ensure_ready(state)
    binding = getattr(state.calls, "_binding")
    methods = sorted(
        name
        for name in dir(binding)
        if callable(getattr(binding, name, None)) and not name.startswith("_")
    )
    return {"ok": True, "data": methods}


async def do_shutdown(state: BridgeState) -> Dict[str, Any]:
    if state.calls is not None:
        try:
            await state.calls.stop()
        except Exception:
            pass
    if state.client is not None:
        try:
            await state.client.stop()
        except Exception:
            pass
    state.initialized = False
    return {"ok": True, "data": {"stopped": True}}


async def dispatch(state: BridgeState, action: str, payload: Dict[str, Any]) -> Dict[str, Any]:
    action_map = {
        "init": do_init,
        "play": do_play,
        "pause": lambda s, p: do_call_method(s, {"method": "pause", "args": [p["chat_id"]]}),
        "resume": lambda s, p: do_call_method(s, {"method": "resume", "args": [p["chat_id"]]}),
        "mute": lambda s, p: do_call_method(s, {"method": "mute", "args": [p["chat_id"]]}),
        "unmute": lambda s, p: do_call_method(s, {"method": "unmute", "args": [p["chat_id"]]}),
        "get_participants": lambda s, p: do_call_method(
            s, {"method": "get_participants", "args": [p["chat_id"]]}
        ),
        "change_volume_call": lambda s, p: do_call_method(
            s, {"method": "change_volume_call", "args": [p["chat_id"], p["volume"]]}
        ),
        "leave_call": lambda s, p: do_call_method(
            s, {"method": "leave_call", "args": [p["chat_id"]], "kwargs": {"close": bool(p.get("close", False))}}
        ),
        "call_method": do_call_method,
        "call_ntg": do_call_ntg,
        "list_pytgcalls_methods": lambda s, _p: do_list_methods(s),
        "list_ntgcalls_methods": lambda s, _p: do_list_ntg_methods(s),
        "shutdown": lambda s, _p: do_shutdown(s),
    }

    if action not in action_map:
        raise ValueError(f"Unsupported action: {action}")

    return await action_map[action](state, payload)


async def main() -> None:
    state = BridgeState()

    while True:
        line = await asyncio.to_thread(sys.stdin.readline)
        if line == "":
            break
        line = line.strip()
        if not line:
            continue

        current_action = None
        try:
            req = json.loads(line)
            action = str(req.get("action", ""))
            current_action = action
            payload = req.get("payload") or {}
            response = await dispatch(state, action, payload)
        except Exception as exc:
            response = {
                "ok": False,
                "error": str(exc),
                "error_type": exc.__class__.__name__,
                "traceback": traceback.format_exc(limit=5),
            }

        sys.stdout.write(json.dumps(response, ensure_ascii=True) + "\n")
        sys.stdout.flush()

        if current_action == "shutdown" and response.get("ok"):
            break


if __name__ == "__main__":
    asyncio.run(main())
