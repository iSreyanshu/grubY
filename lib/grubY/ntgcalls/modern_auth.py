from __future__ import annotations

import inspect
from dataclasses import dataclass
from typing import Any

from telethon import TelegramClient
from telethon.sessions import StringSession


@dataclass(slots=True)
class AuthSnapshot:
    connected: bool
    authorized: bool
    user_id: int | None
    username: str | None
    phone: str | None
    is_bot: bool

    def to_dict(self) -> dict[str, Any]:
        return {
            "connected": self.connected,
            "authorized": self.authorized,
            "user_id": self.user_id,
            "username": self.username,
            "phone": self.phone,
            "is_bot": self.is_bot,
        }


class ModernAuth:
    """Non-interactive auth helper for bridge-friendly Telethon flows."""

    def __init__(self, client: TelegramClient) -> None:
        self.client = client

    async def status(self) -> AuthSnapshot:
        connected = self.client.is_connected()
        if not connected:
            await self.client.connect()
            connected = True

        me = await self.client.get_me()
        if me is None:
            return AuthSnapshot(
                connected=connected,
                authorized=False,
                user_id=None,
                username=None,
                phone=None,
                is_bot=False,
            )

        return AuthSnapshot(
            connected=connected,
            authorized=True,
            user_id=me.id,
            username=getattr(me, "username", None),
            phone=getattr(me, "phone", None),
            is_bot=bool(getattr(me, "bot", False)),
        )

    async def send_code(self, phone: str, force_sms: bool = False) -> dict[str, Any]:
        sent = await self.client.send_code_request(phone=phone, force_sms=force_sms)
        return {
            "type": sent.__class__.__name__,
            "phone_code_hash": getattr(sent, "phone_code_hash", None),
            "next_type": getattr(getattr(sent, "next_type", None), "__class__", type(None)).__name__,
        }

    async def sign_in(
        self,
        *,
        phone: str | None = None,
        code: str | int | None = None,
        password: str | None = None,
        bot_token: str | None = None,
        phone_code_hash: str | None = None,
    ) -> dict[str, Any]:
        if bot_token:
            me = await self.client.sign_in(bot_token=bot_token)
        elif password is not None:
            me = await self.client.sign_in(phone=phone, password=password)
        elif code is not None:
            me = await self.client.sign_in(phone=phone, code=code, phone_code_hash=phone_code_hash)
        elif phone:
            return {
                "authorized": False,
                "code_sent": True,
                "sent": await self.send_code(phone),
            }
        else:
            raise ValueError("Provide bot_token, or phone+code, or password.")

        me = me or await self.client.get_me()
        return {
            "authorized": me is not None,
            "user": {
                "id": None if me is None else me.id,
                "username": None if me is None else getattr(me, "username", None),
                "phone": None if me is None else getattr(me, "phone", None),
                "is_bot": False if me is None else bool(getattr(me, "bot", False)),
            },
        }

    async def start(
        self,
        *,
        bot_token: str | None = None,
        phone: str | None = None,
        code: str | int | None = None,
        password: str | None = None,
        phone_code_hash: str | None = None,
    ) -> dict[str, Any]:
        if not self.client.is_connected():
            await self.client.connect()

        me = await self.client.get_me()
        if me is not None:
            return {
                "authorized": True,
                "user": {
                    "id": me.id,
                    "username": getattr(me, "username", None),
                    "phone": getattr(me, "phone", None),
                    "is_bot": bool(getattr(me, "bot", False)),
                },
            }

        result = await self.sign_in(
            phone=phone,
            code=code,
            password=password,
            bot_token=bot_token,
            phone_code_hash=phone_code_hash,
        )
        return result

    async def export_session_string(self) -> str:
        return StringSession.save(self.client.session)

    async def call_maybe_async(self, fn, *args, **kwargs):
        value = fn(*args, **kwargs)
        if inspect.isawaitable(value):
            return await value
        return value
