"""SET_GOLD_RUSH_CHILLER - the Gold Rush set piece for the Chiller (11e2, #457): a gold-leaf crest bolted on the tank's
front, an ore cart heaped with glowing gold on a mine track at the front right, and a sluice box on
legs along the back with gold riffles.
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
    G.crest(k, (0.55, 1.08, -0.7), yaw=0, s=0.85)
    G.rails(k, (0.15, 0.0, -1.05), (0.98, 0.0, -1.05), gauge=0.34, sleepers=3)
    G.cart(k, (0.55, 0.0, -1.05), yaw=0, s=1.05)
    G.sluice(k, (-0.65, 0.6, 1.22), (0.65, 0.32, 1.22), w=0.3)


def build(lp):
    return G.build(lp, "CHILLER", design, "Gold Rush")
