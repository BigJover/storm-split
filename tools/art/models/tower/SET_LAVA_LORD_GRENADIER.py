"""SET_LAVA_LORD_GRENADIER - the Lava Lord set piece for this tower (premium, batch 11p1): see the design
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
    L.spire(k, K, (-1.05, 0.0, -1.0), h=1.7, w=0.44, yaw=10)
    L.brazier(k, K, (-0.95, 0.0, 0.95), s=1.3, legs=0.6)
    L.pool(k, K, (0.8, 0.0, 0.6), r=0.5, rocks=2)
    L.spire(k, K, (0.2, 0.0, 1.15), h=0.9, w=0.3, yaw=180)


def build(lp):
    return L.build(lp, "GRENADIER", design)
