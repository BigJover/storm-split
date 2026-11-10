"""Campsite decoration Hunter's Flag (Decor HUNTERS_FLAG, 2.5 x 1): a pole (body; Decor's Pole is wood
material) on a little cairn of stones, a brass finial, and the cloth (group cloth = the player's worn
Tower flag colour, else the accent, as Decor's Cloth) in a gentle wave.
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
    px = -1.0
    k.add("body", C.rod((px, 0, 0), (px, 6.2, 0), 0.13, segments=8, top=0.8))
    k.add("brass", C.ell((px, 6.3, 0), (0.18, 0.2, 0.18), 8, 5),
          C.ring((px, 5.9, 0), 0.13, 0.04, 8, 3), C.ring((px, 4.5, 0), 0.14, 0.04, 8, 3))
    for i, (dx, dz, r) in enumerate(((-0.04, 0.12, 0.2), (0.25, -0.1, 0.24), (0.1, 0.28, 0.2), (0.12, -0.25, 0.2), (0.1, 0.02, 0.18))):
        k.add("stone", C.ell((px + dx, 0.18 + (0.2 if i == 4 else 0), dz), (r, r * 0.7, r * 0.85), 7, 4))
    # cloth: one waving strip of 5 joined segments (height tapers a little toward the fly end)
    n, w0 = 5, 2.0
    pts = [(px + 0.1 + i * w0 / n, 5.2 - 0.05 * i, 0.12 * math.sin(i * 1.7)) for i in range(n + 1)]
    for i in range(n):
        k.add("cloth", C.bar(pts[i], pts[i + 1], 1.3 - 0.05 * i, 0.06, bevel=0.025, up=(0, 0, 1)))
    k.add("rope", C.ring((px, 5.82, 0), 0.16, 0.035, 8, 3), C.ring((px, 4.6, 0), 0.16, 0.035, 8, 3))
    colors = {"body": C.WOOD, "accent": (200, 60, 50), "cloth": (200, 60, 50), "brass": C.BRASS, "stone": C.STONE, "rope": C.ROPE}
    return k.model("11f", colors, 1200, (1.25, 0.5, 6.6), budget="mid",
                   meta={"prop": "decor", "decor": "HUNTERS_FLAG", "replaces": "Shared/Decor HUNTERS_FLAG"})
