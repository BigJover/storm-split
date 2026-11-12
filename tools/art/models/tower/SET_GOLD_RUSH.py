"""SET_GOLD_RUSH - the Gold Rush tower set's trim (1.5M Amber, Gold Rush Bundle; the top set): a
gold-capped timber edge round the footprint, a stack of gold ingots on the front-left corner and
a pile of nuggets with a pickaxe leaning on it at the back-left. Over any tower's art
(variants/_sets.py).
"""
# art-sources: variants/_sets.py

import importlib.util
import math
from pathlib import Path

_spec = importlib.util.spec_from_file_location("_sets", Path(__file__).with_name("variants") / "_sets.py")
S = importlib.util.module_from_spec(_spec)
_spec.loader.exec_module(S)


def design(k, K):
    S.rim(k, K, "timber", h=0.16, w=0.2)
    S.rim(k, K, "gold", h=0.24, w=0.08)
    k.add("gold",
          *[K.rbox((x, y, z), (0.36, 0.14, 0.2), bevel=0.0, taper=(0.8, 0.75)) for x, y, z in
            ((-1.15, 0.07, -1.2), (-1.15, 0.07, -0.96), (-0.85, 0.07, -1.2), (-1.0, 0.21, -1.08), (-1.15, 0.35, -1.12))],
          *[K.ell((x, y, z), (0.12, 0.1, 0.11), 6, 3) for x, y, z in
            ((-1.2, 0.08, 1.15), (-1.0, 0.08, 1.28), (-1.3, 0.08, 0.92), (-1.12, 0.22, 1.08))])
    k.add("timber", K.rod((-0.86, 0.02, 1.05), (-1.28, 0.95, 1.18), 0.04, 6))
    k.add("metal", K.bar((-1.36, 0.92, 0.98), (-1.18, 0.92, 1.4), 0.07, 0.07, 0.0))


def build(lp):
    return S.trim(
        lp, "GOLD_RUSH", "Gold Rush", design,
        colors={"gold": (232, 186, 70), "timber": (110, 76, 46), "metal": (92, 94, 98)},
        look=((215, 175, 60), (235, 225, 200)), show="QUARTERMASTER")
