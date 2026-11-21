"""SET_LAVA_LORD_SCOUT - the Lava Lord set piece for this tower (premium, batch 11p1): see the design
below - obsidian spire(s), a magma brazier and / or a lava pool (variants/_setpieces_lava.py). Worn over
the tower's art at every stage, on top of the Lava Lord trim.
"""
# art-sources: variants/_setpieces_lava.py variants/_setpiece_common.py variants/_sets.py SET_LAVA_LORD.py

import importlib.util
from pathlib import Path

_spec = importlib.util.spec_from_file_location("_setpieces_lava", Path(__file__).with_name("variants") / "_setpieces_lava.py")
L = importlib.util.module_from_spec(_spec)
_spec.loader.exec_module(L)


def design(k, K):
    L.spire(k, K, (-1.16, 0.55, 0.15), h=1.3, w=0.34, yaw=90)
    L.brazier(k, K, (0.85, 2.42, -0.8), s=1.1)


def build(lp):
    return L.build(lp, "SCOUT", design)
