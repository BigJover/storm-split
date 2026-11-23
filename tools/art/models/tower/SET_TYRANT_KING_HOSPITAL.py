"""SET_TYRANT_KING_HOSPITAL - the Tyrant King set piece for this tower (premium, batch 11p4): the design is
_setpieces_tyrant.hospital (rex skulls, a crimson-draped skull monument, bone banner poles, tooth palisades,
rex-jaw arches, bone thrones). Worn over the tower's art at every stage, on top of the Tyrant King trim.
"""
# art-sources: variants/_setpieces_tyrant.py variants/_setpiece_common.py variants/_sets.py SET_TYRANT_KING.py

import importlib.util
from pathlib import Path

_spec = importlib.util.spec_from_file_location("_setpieces_tyrant", Path(__file__).with_name("variants") / "_setpieces_tyrant.py")
L = importlib.util.module_from_spec(_spec)
_spec.loader.exec_module(L)


def build(lp):
    return L.build(lp, "HOSPITAL")
