"""Campsite decoration Rope Swing (Decor ROPE_SWING, 4 x 2): an A-frame (body: legs, beam) at x -1.7 /
+1.7 like Decor's posts, two ropes (accent) to a plank seat (body) at y 1.2.
Origin = the decoration spot (Shared/Decor.build `at`: base on the Campsite ground), front -Z.
`body` = the Skins look colour, `accent` = its accent (Decor's c / a); other groups authored."""

import importlib.util
import math
from pathlib import Path

_s = importlib.util.spec_from_file_location("_camp", Path(__file__).with_name("_camp.py"))
C = importlib.util.module_from_spec(_s)
_s.loader.exec_module(C)


def build(lp):
    k = C.Camp(lp)
    for x in (-1.7, 1.7):
        for s in (-1, 1):
            k.add("body", C.rod((x, 0, s * 0.85), (x, 4.45, 0), 0.15, segments=8))
        k.add("body", C.bar((x, 1.3, -0.63), (x, 1.3, 0.63), 0.1, 0.1))
        k.add("rope", C.ring_along((x, 4.2, 0), (x + 0.1, 4.2, 0), 0.2, 0.05, 8, 3))
    k.add("body", C.rod((-1.95, 4.5, 0), (1.95, 4.5, 0), 0.19, segments=10))
    for x in (-0.5, 0.5):
        k.add("accent", C.rod((x, 4.4, 0), (x, 1.3, 0), 0.05, segments=5),
              C.ring_along((x, 4.5, 0), (x + 0.1, 4.5, 0), 0.2, 0.05, 8, 3))
    k.add("body", C.rbox((0, 1.2, 0), (1.4, 0.16, 0.6), bevel=0.05))
    colors = {"body": C.WOOD, "accent": C.ROPE, "rope": C.ROPE}
    return k.model("11f", colors, 1200, (2.0, 1.0, 4.75), budget="mid",
                   meta={"prop": "decor", "decor": "ROPE_SWING", "replaces": "Shared/Decor ROPE_SWING"})
