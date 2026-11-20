"""SET_GOLD_RUSH_TOTEM - the Gold Rush set piece for the Bone Totem (11e2, #457): a gold-leaf
crest with crossed pickaxes on the pole's front, and round its foot (kept low, under the charge
ring's height) a ring of gold ingot offerings with glowing nuggets between them.
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
    G.crest(k, (0.0, 1.62, -0.5), yaw=0, s=0.85)
    for i in range(6):
        a = 360 * i / 6 + 30
        r = G._rot((0.0, 0.0, -0.74), a)
        G.ingots(k, (r[0], 0.04, r[2]), yaw=a + 90, rows=((0, 0, -0.05), (0, 0, 0.12), (0, 0.13, 0.035)), glow_top=False)
        n = G._rot((0.0, 0.0, -0.74), a + 30)
        G.nugget(k, (n[0], 0.17, n[2]), 0.1, glow=True, seed=i)


def build(lp):
    return G.build(lp, "TOTEM", design, "Gold Rush")
