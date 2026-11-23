"""SET_LAVA_LORD_CHILLER - the Lava Lord set piece for this tower (premium, batch 11p2, #462): see the design
in variants/_setpieces_lava2.py (erupting cones, lava falls, basalt columns, magma braziers, obsidian
spires, lava pools). Worn over the tower's art at every stage, on top of the Lava Lord trim.
"""
# art-sources: variants/_setpieces_lava2.py variants/_setpieces_lava.py variants/_setpiece_common.py variants/_sets.py SET_LAVA_LORD.py

import importlib.util
from pathlib import Path

_spec = importlib.util.spec_from_file_location("_setpieces_lava2", Path(__file__).with_name("variants") / "_setpieces_lava2.py")
P = importlib.util.module_from_spec(_spec)
_spec.loader.exec_module(P)


def build(lp):
    return P.build(lp, "CHILLER")
