"""SET_BRASS_GEAR - the Brass Gear tower set's trim (600K Amber, Brass Gear Bundle): a brass
plate edge round the footprint, a big cog standing on the front-left corner and a steam pipe
with a valve wheel on the back-left. Over any tower's art (variants/_sets.py).
"""
# art-sources: variants/_sets.py

import importlib.util
import math
from pathlib import Path

_spec = importlib.util.spec_from_file_location("_sets", Path(__file__).with_name("variants") / "_sets.py")
S = importlib.util.module_from_spec(_spec)
_spec.loader.exec_module(S)


def design(k, K):
    S.rim(k, K, "brass", h=0.18, w=0.14)
    cx, cy, cz = -0.92, 0.56, -1.3
    k.add("brass2", K.cyl((cx, cy, cz), 0.4, 0.12, 12, bevel=0.0, rot=(90, 0, 0)))
    k.add("brass", *[K.rbox((cx + 0.46 * math.cos(a), cy + 0.46 * math.sin(a), cz), (0.14, 0.14, 0.12), bevel=0.0,
                            rot=(0, 0, math.degrees(a))) for a in [i * 2 * math.pi / 8 + 0.2 for i in range(8)]
                     if cy + 0.46 * math.sin(a) > 0.1])
    k.add("metal", K.cyl((cx, cy, cz - 0.02), 0.12, 0.16, 6, bevel=0.0, rot=(90, 0, 0)),
          K.rod((-1.25, 0.0, 1.2), (-1.25, 0.9, 1.2), 0.1, 6),
          K.rod((-1.25, 0.82, 1.2), (-0.9, 0.82, 1.2), 0.08, 6))
    k.add("brass2", K.ring((-1.25, 0.6, 1.2), 0.16, 0.03, 8, 3))


def build(lp):
    return S.trim(
        lp, "BRASS_GEAR", "Brass Gear", design,
        colors={"brass": (196, 154, 66), "brass2": (226, 182, 82), "metal": (90, 90, 95)},
        look=((180, 140, 60), (90, 90, 95)), show="COIL")
