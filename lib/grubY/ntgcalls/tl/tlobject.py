from __future__ import annotations

import base64
import json
import struct
import time
from datetime import date, datetime, timedelta, timezone
from typing import Any

_EPOCH_NAIVE = datetime(*time.gmtime(0)[:6])
_EPOCH_NAIVE_LOCAL = datetime(*time.localtime(0)[:6])
_EPOCH = _EPOCH_NAIVE.replace(tzinfo=timezone.utc)


def _datetime_to_timestamp(dt: datetime) -> int:
    if dt.tzinfo is None:
        dt = dt.replace(tzinfo=timezone.utc)

    secs = int((dt - _EPOCH).total_seconds())
    return struct.unpack("i", struct.pack("I", secs & 0xFFFFFFFF))[0]


def _json_default(value: Any) -> str:
    if isinstance(value, bytes):
        return base64.b64encode(value).decode("ascii")
    if isinstance(value, datetime):
        return value.isoformat()
    return repr(value)


class TLObject:
    CONSTRUCTOR_ID = None
    SUBCLASS_OF_ID = None

    @staticmethod
    def pretty_format(obj: Any, indent: int | None = None) -> str:
        if indent is None:
            if isinstance(obj, TLObject):
                obj = obj.to_dict()

            if isinstance(obj, dict):
                return "{}({})".format(
                    obj.get("_", "dict"),
                    ", ".join(
                        "{}={}".format(k, TLObject.pretty_format(v))
                        for k, v in obj.items()
                        if k != "_"
                    ),
                )
            if isinstance(obj, (str, bytes)):
                return repr(obj)
            if hasattr(obj, "__iter__"):
                return "[{}]".format(", ".join(TLObject.pretty_format(x) for x in obj))
            return repr(obj)

        result: list[str] = []
        if isinstance(obj, TLObject):
            obj = obj.to_dict()

        if isinstance(obj, dict):
            result.append(obj.get("_", "dict"))
            result.append("(")
            if obj:
                result.append("\n")
                indent += 1
                for k, v in obj.items():
                    if k == "_":
                        continue
                    result.append("\t" * indent)
                    result.append(k)
                    result.append("=")
                    result.append(TLObject.pretty_format(v, indent))
                    result.append(",\n")
                result.pop()
                indent -= 1
                result.append("\n")
                result.append("\t" * indent)
            result.append(")")
        elif isinstance(obj, (str, bytes)):
            result.append(repr(obj))
        elif hasattr(obj, "__iter__"):
            result.append("[\n")
            indent += 1
            for x in obj:
                result.append("\t" * indent)
                result.append(TLObject.pretty_format(x, indent))
                result.append(",\n")
            indent -= 1
            result.append("\t" * indent)
            result.append("]")
        else:
            result.append(repr(obj))

        return "".join(result)

    @staticmethod
    def serialize_bytes(data: bytes | str) -> bytes:
        if not isinstance(data, bytes):
            if isinstance(data, str):
                data = data.encode("utf-8")
            else:
                raise TypeError(f"bytes or str expected, not {type(data)}")

        parts: list[bytes] = []
        if len(data) < 254:
            padding = (len(data) + 1) % 4
            if padding != 0:
                padding = 4 - padding

            parts.append(bytes([len(data)]))
            parts.append(data)
        else:
            padding = len(data) % 4
            if padding != 0:
                padding = 4 - padding

            parts.append(
                bytes(
                    [
                        254,
                        len(data) % 256,
                        (len(data) >> 8) % 256,
                        (len(data) >> 16) % 256,
                    ]
                )
            )
            parts.append(data)

        parts.append(bytes(padding))
        return b"".join(parts)

    @staticmethod
    def serialize_datetime(dt: datetime | date | float | int | timedelta | None) -> bytes:
        if not dt and not isinstance(dt, timedelta):
            return b"\0\0\0\0"

        if isinstance(dt, datetime):
            dt = _datetime_to_timestamp(dt)
        elif isinstance(dt, date):
            dt = _datetime_to_timestamp(datetime(dt.year, dt.month, dt.day))
        elif isinstance(dt, float):
            dt = int(dt)
        elif isinstance(dt, timedelta):
            dt = _datetime_to_timestamp(datetime.utcnow() + dt)

        if isinstance(dt, int):
            return struct.pack("<i", dt)

        raise TypeError(f"Cannot interpret {dt!r} as a date.")

    def __eq__(self, other: object) -> bool:
        return isinstance(other, type(self)) and self.to_dict() == other.to_dict()

    def __ne__(self, other: object) -> bool:
        return not isinstance(other, type(self)) or self.to_dict() != other.to_dict()

    def __str__(self) -> str:
        return TLObject.pretty_format(self)

    def stringify(self) -> str:
        return TLObject.pretty_format(self, indent=0)

    def to_dict(self) -> dict[str, Any]:
        raise NotImplementedError

    def to_json(self, fp=None, default=_json_default, **kwargs):
        d = self.to_dict()
        if fp:
            return json.dump(d, fp, default=default, **kwargs)
        return json.dumps(d, default=default, **kwargs)

    def __bytes__(self) -> bytes:
        try:
            return self._bytes()
        except AttributeError as exc:
            raise TypeError("a TLObject was expected but found something else") from exc

    def _bytes(self) -> bytes:
        raise NotImplementedError

    @classmethod
    def from_reader(cls, reader):
        raise NotImplementedError


class TLRequest(TLObject):
    @staticmethod
    def read_result(reader):
        return reader.tgread_object()

    async def resolve(self, client, utils):
        return None
