"""SET_LAVA_LORD_VENT - the Lava Lord set piece for this tower (premium, batch 11p1): see the design
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
    L.erupting(k, K, (-1.08, 0.0, -1.06), h=1.2, r=0.38)  # v2: an erupting cone
    L.spire(k, K, (-1.2, 0.0, 1.05), h=1.2, w=0.34, yaw=-30)
    L.lavafall(k, K, (0.15, 0.0, -1.2), h=0.75, w=0.36, yaw=180)  # v2: a lava fall (pool inside, under the rim)
    L.brazier(k, K, (1.26, 0.0, -0.6), s=0.85, legs=0.5)


def build(lp):
    return L.build(lp, "VENT", design)
