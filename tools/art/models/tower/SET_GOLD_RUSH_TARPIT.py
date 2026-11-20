"""SET_GOLD_RUSH_TARPIT - the Gold Rush set piece for the Tar Pit (11e2, #457): a gold strike in
the tar, all of it low (it lies on the track): an ore cart heaped with glowing gold sunk to its
axles at the back right on a mine track running into the pit, a sluice box lying in the tar on the
left with gold riffles, a pickaxe dropped beside it and a prospector's pan at the front.
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
    G.rails(k, (0.75, 0.1, 0.95), (0.0, 0.1, -0.05), gauge=0.32, sleepers=4)
    G.cart(k, (0.52, 0.0, 0.62), yaw=-53, s=1.0)
    G.sluice(k, (-1.0, 0.2, 0.55), (-0.85, 0.13, -0.55), w=0.32, legs=False)
    G.pickaxe(k, (-0.35, 0.16, -0.75), (-0.5, 0.18, -0.2), (0.96, 0.0, 0.28))
    G.pan(k, (0.45, 0.16, -0.75), r=0.28)


def build(lp):
    return G.build(lp, "TARPIT", design, "Gold Rush")
