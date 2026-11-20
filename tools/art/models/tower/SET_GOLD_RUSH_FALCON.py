"""SET_GOLD_RUSH_FALCON - the Gold Rush set piece for the Falcon Roost (11e2, #457): a gold-leaf
crest on the mews' front wall, and an ore cart heaped with glowing gold on a mine track in the
open front yard.
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
    G.crest(k, (-0.62, 1.15, -0.46), yaw=0, s=1.1)
    G.rails(k, (-0.38, 0.0, -1.42), (-0.38, 0.0, -0.66), gauge=0.32, sleepers=3)
    G.cart(k, (-0.38, 0.0, -1.0), yaw=90, s=1.0)


def build(lp):
    return G.build(lp, "FALCON", design, "Gold Rush")
