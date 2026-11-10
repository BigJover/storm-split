"""One span of the Outpost fence between two posts (Server/Outpost Rail: chord x 0.4 x 0.4 at y 3.5, chord =
2 (RADIUS - 1) sin(pi / 48) + 1 ~ 15.25). Origin = the span's middle on the floor, the span along X (the
Rail's own X: CFrame.lookAt(mid, centre) faces the camp, -Z inward). Two log rails (y 3.5 and 1.8)
lashed at the ends, sagging slightly. The invisible Fence wall stays the collision."""

import importlib.util
import math
from pathlib import Path

_s = importlib.util.spec_from_file_location("_camp", Path(__file__).with_name("_camp.py"))
C = importlib.util.module_from_spec(_s)
_s.loader.exec_module(C)

def build(lp):
    k = C.Camp(lp)
    L = 7.55
    for y, r in ((3.5, 0.2), (1.8, 0.18)):
        k.add("wood", C.rod((-L, y, 0), (0, y - 0.12, 0), r, segments=7), C.rod((0, y - 0.12, 0), (L, y, 0), r, segments=7))
    for x in (-L + 0.5, L - 0.5):
        k.add("rope", C.ring_along((x, 3.5, 0), (x + 1, 3.5, 0), 0.24, 0.05, 8, 3),
              C.ring_along((x, 1.8, 0), (x + 1, 1.8, 0), 0.22, 0.05, 8, 3))
    colors = {"wood": (120, 84, 52), "rope": (196, 170, 120)}
    return k.model("11f", colors, 400, (7.7, 0.4, 3.8), budget="small",
                   meta={"prop": "camp", "replaces": "Server/Outpost Rail (x48)", "length": 15.25})
