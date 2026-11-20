"""SET_GOLD_RUSH_COIL - the Gold Rush set piece for the Storm Coil (11e2, #457): a gold-leaf crest
on two posts at the deck's left edge, an ore cart heaped with glowing gold on a mine track at the
back right, and a prospector's pan glinting at the front.
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
    G.crest(k, (-1.3, 0.95, -0.05), yaw=90, s=1.1)
    for z in (-0.3, 0.2):
        k.add("timber", G.K.rod((-1.26, 0.0, z), (-1.26, 0.75, z), 0.03, 5))
    G.rails(k, (-0.05, 0.1, 0.75), (0.95, 0.1, 0.75), gauge=0.34, sleepers=3)
    G.cart(k, (0.45, 0.1, 0.75), yaw=0, s=1.1)
    G.pan(k, (0.3, 0.16, -1.12), r=0.28, tilt=(-8, 0, 6))


def build(lp):
    return G.build(lp, "COIL", design, "Gold Rush")
