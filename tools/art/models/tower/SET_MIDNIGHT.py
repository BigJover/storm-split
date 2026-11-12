"""SET_MIDNIGHT - the Midnight tower set's trim (800K Amber, Midnight Bundle): a dark stone edge
round the footprint studded with ice-blue stars, a cluster of ice-blue crystals on the front-left
corner and a crystal lantern on a post at the back-left. SmoothPlastic like every skin: no Neon,
no glow (#381). Over any tower's art (variants/_sets.py).
"""
# art-sources: variants/_sets.py

import importlib.util
import math
from pathlib import Path

_spec = importlib.util.spec_from_file_location("_sets", Path(__file__).with_name("variants") / "_sets.py")
S = importlib.util.module_from_spec(_spec)
_spec.loader.exec_module(S)


def design(k, K):
    S.rim(k, K, "dark", h=0.2, w=0.16)
    k.add("crystal",
          *[K.ell((x, 0.21, z), (0.05, 0.03, 0.05), 6, 3) for x, z in ((0.0, -1.42), (1.42, 0.0), (0.0, 1.42))],
          K.rod((-1.1, 0.1, -1.1), (-1.15, 1.05, -1.15), 0.18, 6, top=0.1),
          K.rod((-0.9, 0.1, -1.2), (-0.7, 0.72, -1.3), 0.13, 6, top=0.1),
          K.rod((-1.25, 0.1, -0.85), (-1.38, 0.55, -0.7), 0.09, 6, top=0.1),
          K.ell((-1.2, 0.68, 1.2), (0.09, 0.14, 0.09), 6, 3))
    k.add("rock", K.ell((-1.08, 0.14, -1.08), (0.36, 0.14, 0.34), 8, 3))
    k.add("metal", K.rod((-1.2, 0.0, 1.2), (-1.2, 0.5, 1.2), 0.06, 6),
          K.rbox((-1.2, 0.68, 1.2), (0.26, 0.36, 0.26), bevel=0.0, taper=(0.7, 0.7)),
          K.rbox((-1.2, 0.9, 1.2), (0.3, 0.08, 0.3), bevel=0.0))


def build(lp):
    return S.trim(
        lp, "MIDNIGHT", "Midnight", design,
        colors={"dark": (30, 30, 44), "crystal": (120, 220, 255), "rock": (56, 56, 74), "metal": (82, 84, 104)},
        look=((35, 35, 50), (120, 220, 255)), show="SNIPER")
