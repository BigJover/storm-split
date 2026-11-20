"""SET_GOLD_RUSH_RESIN - the Gold Rush set piece for the Amber Resin Cannon (11e2, #457): a tall
pole at the back right flying a gold pennant, an ore cart heaped with glowing gold on a short
track at the front left, and a nugget heap with a gold pickaxe at the front right (clear of the
barrel and the wheels).
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
    G.pennant(k, (0.78, 0.0, 0.92), 2.7, yaw=180, length=0.75)
    G.rails(k, (-0.95, 0.0, -1.05), (-0.15, 0.0, -1.05), gauge=0.32, sleepers=3)
    G.cart(k, (-0.55, 0.0, -1.05), yaw=0, s=1.0)
    G.pile(k, (0.62, 0.0, -0.82), r=0.3, n=6)
    G.pickaxe(k, (0.85, 0.0, -0.6), (0.62, 0.5, -0.8), (1.0, 0.0, 0.0), head="gold")


def build(lp):
    return G.build(lp, "RESIN", design, "Gold Rush")
