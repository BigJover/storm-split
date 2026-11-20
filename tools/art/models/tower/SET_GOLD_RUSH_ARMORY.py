"""SET_GOLD_RUSH_ARMORY - the Gold Rush set piece for the Armory (11e2, #457): an ore cart heaped with glowing gold on a
mine track across the open deck in front of the shed, a nugget heap with a gold pickaxe, and a gold
pan propped against the cart.
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
    G.rails(k, (-1.25, 0.13, 0.12), (1.0, 0.13, 0.12), gauge=0.34, sleepers=5)
    G.cart(k, (0.3, 0.13, 0.12), yaw=0, s=1.25)
    G.pile(k, (-0.75, 0.13, 0.14), r=0.38, n=6)
    G.pickaxe(k, (-1.05, 0.15, 0.4), (-0.78, 0.7, 0.18), (1.0, 0.0, 0.0), head="gold")
    G.pan(k, (0.98, 0.35, -0.12), r=0.26, tilt=(60, 0, 0))


def build(lp):
    return G.build(lp, "ARMORY", design, "Gold Rush")
