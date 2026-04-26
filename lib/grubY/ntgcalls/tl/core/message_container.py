from __future__ import annotations

from .tlmessage import TLMessage
from ..tlobject import TLObject


class MessageContainer(TLObject):
    CONSTRUCTOR_ID = 0x73F1F8DC

    MAXIMUM_SIZE = 1044456 - 8
    MAXIMUM_LENGTH = 100

    def __init__(self, messages):
        self.messages = messages

    def to_dict(self):
        return {
            "_": "MessageContainer",
            "messages": []
            if self.messages is None
            else [None if x is None else x.to_dict() for x in self.messages],
        }

    @classmethod
    def from_reader(cls, reader):
        messages = []
        for _ in range(reader.read_int()):
            msg_id = reader.read_long()
            seq_no = reader.read_int()
            length = reader.read_int()
            before = reader.tell_position()
            obj = reader.tgread_object()
            reader.set_position(before + length)
            messages.append(TLMessage(msg_id, seq_no, obj))
        return MessageContainer(messages)
