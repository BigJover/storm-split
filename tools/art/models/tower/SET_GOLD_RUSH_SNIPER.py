"""SET_GOLD_RUSH_SNIPER - the Gold Rush set piece for the Sniper Tower (11e2, #457): an ore cart heaped
with glowing gold on a mine track running under the platform between the stilts, a nugget heap with
a pickaxe beside it, and a gold-leaf crest hung on chains under the platform's front.
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
    G.rails(k, (0.2, 0.0, -1.05), (0.2, 0.0, 1.0), gauge=0.34, sleepers=4)
    G.cart(k, (0.2, 0.0, 0.05), yaw=90, s=1.25)
    G.pile(k, (-0.62, 0.0, -0.2), r=0.42, n=6)
    G.pickaxe(k, (-0.95, 0.02, 0.15), (-0.66, 0.62, -0.12), (0.0, 0.0, 1.0), head="gold")
    G.crest(k, (0.55, 2.45, -1.26), yaw=0, s=0.9)
    for x in (0.32, 0.78):
        k.add("iron", G.K.rod((x, 2.66, -1.24), (x, 3.25, -1.24), 0.018, 4))


def build(lp):
    return G.build(lp, "SNIPER", design, "Gold Rush")
