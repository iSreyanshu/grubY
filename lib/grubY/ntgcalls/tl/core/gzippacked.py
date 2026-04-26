from __future__ import annotations

import struct

try:
    from isal import igzip as gzip
except ImportError:
    import gzip

from ..tlobject import TLObject


class GzipPacked(TLObject):
    CONSTRUCTOR_ID = 0x3072CFA1

    def __init__(self, data: bytes):
        self.data = data

    @staticmethod
    def gzip_if_smaller(content_related: bool, data: bytes) -> bytes:
        if content_related and len(data) > 512:
            gzipped = bytes(GzipPacked(data))
            return gzipped if len(gzipped) < len(data) else data
        return data

    def __bytes__(self) -> bytes:
        return struct.pack("<I", GzipPacked.CONSTRUCTOR_ID) + TLObject.serialize_bytes(
            gzip.compress(self.data)
        )

    @staticmethod
    def read(reader):
        constructor = reader.read_int(signed=False)
        assert constructor == GzipPacked.CONSTRUCTOR_ID
        return gzip.decompress(reader.tgread_bytes())

    @classmethod
    def from_reader(cls, reader):
        return GzipPacked(gzip.decompress(reader.tgread_bytes()))

    def to_dict(self):
        return {"_": "GzipPacked", "data": self.data}
