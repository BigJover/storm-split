"""SET_GOLD_RUSH_METEOR - the Gold Rush set piece for the Meteor Beacon (11e2, #457): a gold-leaf
crest on two posts at the front of the stone footing, an ore cart heaped with glowing gold on a
mine track along the back, and a nugget heap with a gold pickaxe on the right.
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
    G.crest(k, (-0.42, 1.05, -1.25), yaw=0, s=1.05)
    for x in (-0.62, -0.22):
        k.add("timber", G.K.rod((x, 0.34, -1.2), (x, 0.85, -1.2), 0.03, 5))
    G.rails(k, (-0.25, 0.34, 1.12), (0.8, 0.34, 1.12), gauge=0.32, sleepers=3)
    G.cart(k, (0.3, 0.34, 1.12), yaw=0, s=1.0)
    G.pile(k, (1.12, 0.34, 0.05), r=0.3, n=6)
    G.pickaxe(k, (1.3, 0.36, 0.3), (1.12, 0.85, 0.08), (0.0, 0.0, 1.0), head="gold")


def build(lp):
    return G.build(lp, "METEOR", design, "Gold Rush")
