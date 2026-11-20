"""SET_GOLD_RUSH_GRENADIER - the Gold Rush set piece for the Mortar Pit (11e2, #457): a gold-leaf crest on two posts
behind the front sandbags, a tall pole at the left edge flying a gold pennant over the pit with a
miner's lantern hung on it, and a glowing nugget heap with a pickaxe at the back of the pit.
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
    G.crest(k, (-0.62, 1.3, -1.26), yaw=0, s=1.05)
    for x in (-0.84, -0.4):
        k.add("timber", G.K.rod((x, 0.0, -1.2), (x, 1.12, -1.2), 0.03, 5))
    G.pennant(k, (-1.36, 0.0, 0.1), 3.1, yaw=0, length=0.75)
    G.lantern(k, (-1.22, 2.25, 0.1), s=1.1)
    k.add("iron", G.K.bar((-1.36, 2.5, 0.1), (-1.2, 2.5, 0.1), 0.03, 0.03, 0.0))
    G.pile(k, (0.2, 0.02, 0.95), r=0.36, n=6)
    G.pickaxe(k, (0.55, 0.02, 0.7), (0.35, 0.55, 0.92), (0.0, 0.0, -1.0), head="gold")


def build(lp):
    return G.build(lp, "GRENADIER", design, "Gold Rush")
