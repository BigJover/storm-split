"""SET_GOLD_RUSH_BALLISTA - the Gold Rush set piece for the Harpoon Ballista (11e2, #457): a gold-
leaf crest on the pedestal's left face, an ore cart heaped with glowing gold on the turntable at
the back right, and a nugget heap with a gold pickaxe on the left.
Worn over the tower's art at every stage, on top of the Gold Rush trim
(variants/_setpieces_goldrush.py has the props and the build checks).
"""
# art-sources: variants/_setpieces_goldrush.py variants/_sets.py SET_GOLD_RUSH.py

import importlib.util
from pathlib import Path

_spec = importlib.util.spec_from_file_location("_setpieces_goldrush", Path(__file__).with_name("variants") / "_setpieces_goldrush.py")
G = importlib.util.module_from_spec(_spec)
_spec.loader.exec_module(G)


def design(k):
    G.crest(k, (-0.4, 1.0, 0.0), yaw=90, s=0.8)
    G.cart(k, (0.68, 0.36, 0.62), yaw=45, s=1.0)
    G.pile(k, (-0.98, 0.34, 0.42), r=0.32, n=6)
    G.pickaxe(k, (-1.2, 0.36, 0.62), (-0.95, 0.85, 0.42), (0.0, 0.0, -1.0), head="gold")


def build(lp):
    return G.build(lp, "BALLISTA", design, "Gold Rush")
