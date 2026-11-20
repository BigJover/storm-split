"""SET_GOLD_RUSH_QUARTERMASTER - the Gold Rush set piece for the Supply Camp (11e2, #457): a gold-
leaf crest on the left face of the tall crate stack, the supply barrel brimming with glowing gold,
and an ore cart heaped with gold on a short mine track along the front.
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
    G.crest(k, (-1.29, 1.3, 0.25), yaw=90, s=1.1)
    k.add("gold", G.K.ell((-0.75, 0.86, -0.85), (0.2, 0.09, 0.2), 8, 3))
    G.nugget(k, (-0.7, 0.96, -0.9), 0.08, glow=True, seed=1)
    G.nugget(k, (-0.84, 0.95, -0.78), 0.07, glow=True, seed=4)
    G.rails(k, (-0.66, 0.0, -1.25), (0.02, 0.0, -1.25), gauge=0.3, sleepers=3)
    G.cart(k, (-0.33, 0.0, -1.25), yaw=0, s=0.85)


def build(lp):
    return G.build(lp, "QUARTERMASTER", design, "Gold Rush")
