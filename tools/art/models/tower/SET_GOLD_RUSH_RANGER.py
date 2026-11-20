"""SET_GOLD_RUSH_RANGER - the Gold Rush set piece for the Ranger Station (11e2, #457): a gold-
framed claim board along the porch roof's front edge, a gold-leaf crest on the cabin's left wall,
and an ore cart heaped with glowing gold on a short track in front of the porch.
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
    G.plaque(k, (-0.35, 1.08, -1.08), yaw=0, w=0.9, h=0.24)
    G.crest(k, (-1.38, 1.2, -0.05), yaw=90, s=0.85)
    G.rails(k, (-0.66, 0.0, -1.27), (-0.14, 0.0, -1.27), gauge=0.26, sleepers=2)
    G.cart(k, (-0.4, 0.0, -1.27), yaw=0, s=0.8)


def build(lp):
    return G.build(lp, "RANGER", design, "Gold Rush")
