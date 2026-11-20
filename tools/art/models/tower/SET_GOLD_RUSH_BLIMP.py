"""SET_GOLD_RUSH_BLIMP - the Gold Rush set piece for the Spotter Blimp's ground mast (11e2, #457): a
 gold-leaf crest on two posts at the front of the deck, and an ore cart heaped with glowing gold
on a mine track at the back right with a nugget heap and a gold pickaxe beside it.
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
    G.crest(k, (-0.3, 0.95, -1.25), yaw=0, s=1.1)
    for x in (-0.52, -0.08):
        k.add("timber", G.K.rod((x, 0.16, -1.2), (x, 0.75, -1.2), 0.03, 5))
    G.rails(k, (0.62, 0.16, -0.15), (0.62, 0.16, 0.85), gauge=0.34, sleepers=3)
    G.cart(k, (0.62, 0.16, 0.38), yaw=90, s=1.15)
    G.pile(k, (-0.15, 0.16, 0.6), r=0.32, n=6)


def build(lp):
    return G.build(lp, "BLIMP", design, "Gold Rush")
