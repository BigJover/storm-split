"""SET_GOLD_RUSH_VENT - the Gold Rush set piece for the Volcano Vent (11e2, #457): everything
round the edge (the basalt column and the Fire Mountain cone keep the middle): a gold-leaf crest
on two posts at the left edge, an ore cart heaped with glowing gold on a mine track along the
front, and a nugget heap on the right.
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
    G.crest(k, (-1.36, 0.95, 0.42), yaw=90, s=0.85)
    for z in (0.22, 0.62):
        k.add("timber", G.K.rod((-1.32, 0.0, z), (-1.32, 0.75, z), 0.03, 5))
    G.rails(k, (-0.55, 0.17, -1.3), (0.6, 0.17, -1.3), gauge=0.24, sleepers=3)
    G.cart(k, (0.0, 0.17, -1.3), yaw=0, s=0.75)
    G.pile(k, (1.25, 0.2, 0.5), r=0.22, n=5)


def build(lp):
    return G.build(lp, "VENT", design, "Gold Rush")
