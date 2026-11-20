"""SET_GOLD_RUSH_HOSPITAL - the Gold Rush set piece for the Field Hospital (11e2, #457): a tall timber pole at the tent's
left edge flying a gold pennant over the ridge, a gold-leaf crest and a miner's lantern hung on it
above the slope (the Rescue Beacon corner and both crosses stay clear).
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
    G.pennant(k, (-1.4, 0.0, -0.15), 3.75, yaw=0, length=0.8)
    G.crest(k, (-1.06, 2.62, -0.24), yaw=0, s=1.0)
    k.add("iron", G.K.bar((-1.4, 3.0, -0.15), (-1.06, 3.0, -0.2), 0.03, 0.03, 0.0))
    G.lantern(k, (-1.4, 1.5, -0.32), s=1.0)
    k.add("iron", G.K.bar((-1.4, 1.72, -0.15), (-1.4, 1.72, -0.32), 0.03, 0.03, 0.0))


def build(lp):
    return G.build(lp, "HOSPITAL", design, "Gold Rush")
