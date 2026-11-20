"""SET_GOLD_RUSH_SCOUT - the Gold Rush set piece for the Hunting Blind (11e2, #457): a gold-leaf
crest with crossed pickaxes on the hide's left wall and, on the right half of the roof (the lookout
of stages 1-2 sits on the left half), an ore cart heaped with glowing gold on a short mine track,
a gold pickaxe leaning on it.
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
    G.crest(k, (-1.28, 1.15, 0.05), yaw=90, s=1.3)
    G.rails(k, (0.98, 2.4, -0.88), (0.98, 2.4, 0.78), gauge=0.32, sleepers=3)
    G.cart(k, (0.98, 2.4, -0.12), yaw=90, s=1.15)
    G.pickaxe(k, (0.98, 2.45, 0.62), (0.98, 3.0, 0.3), (1.0, 0.0, 0.0), head="gold")


def build(lp):
    return G.build(lp, "SCOUT", design, "Gold Rush")
