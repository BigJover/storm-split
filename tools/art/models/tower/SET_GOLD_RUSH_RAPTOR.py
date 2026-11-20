"""SET_GOLD_RUSH_RAPTOR - the Gold Rush set piece for the Raptor Pen (11e2, #457): a gold-leaf
crest on the front palisade, and inside the pen an ore cart heaped with glowing gold on a mine
track and a nugget heap with a gold pickaxe.
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
    G.crest(k, (-0.55, 1.55, -1.36), yaw=0, s=1.05)
    G.rails(k, (-0.95, 0.08, -0.45), (0.55, 0.08, -0.45), gauge=0.34, sleepers=4)
    G.cart(k, (-0.15, 0.08, -0.45), yaw=0, s=1.2)
    G.pile(k, (0.62, 0.08, 0.15), r=0.36, n=6)
    G.pickaxe(k, (0.9, 0.08, 0.35), (0.66, 0.62, 0.12), (0.0, 0.0, 1.0), head="gold")


def build(lp):
    return G.build(lp, "RAPTOR", design, "Gold Rush")
