from __future__ import annotations
from ..tlobject import TLObject

class TLMessage(TLObject):
    """
    https://core.telegram.org/mtproto/service_messages#simple-container
    """

    SIZE_OVERHEAD = 12

    def __init__(self, msg_id: int, seq_no: int, obj) -> None:
        self.msg_id = msg_id
        self.seq_no = seq_no
        self.obj = obj

    def to_dict(self):
        return {
            "_": "TLMessage",
            "msg_id": self.msg_id,
            "seq_no": self.seq_no,
            "obj": self.obj,
        }
