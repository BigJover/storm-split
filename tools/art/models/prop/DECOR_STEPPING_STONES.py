"""Campsite decoration Stepping Stones (Decor STEPPING_STONES, 3 x 5): four flat rounded stones on
Decor's spots, alternating body / accent like the blocks, with grass tufts (leaf) between.
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
    spots = ((-0.6, -1.8, 10), (0.6, -0.6, -15), (-0.5, 0.6, 25), (0.5, 1.8, -5))
    for i, (x, z, yaw) in enumerate(spots):
        g = "accent" if (i + 1) % 2 == 0 else "body"
        k.add(g, C.cyl((x, 0.1, z), (0.72, 0.56), 0.2, segments=12, bevel=0.07, rot=(0, yaw, 0)))
        k.add(g, C.ell((x + 0.15, 0.2, z - 0.05), (0.38, 0.06, 0.3), 8, 3))  # a worn dip on top
    for x, z in ((0.55, -1.6), (-0.6, -0.5), (0.6, 0.6), (-0.6, 1.8), (0.0, 0.0), (1.0, 2.2), (-1.0, -2.2)):
        for j in range(3):
            a = j * 2.1
            k.add("leaf", C.cyl((x + math.cos(a) * 0.08, 0.16, z + math.sin(a) * 0.08), 0.06, 0.32, segments=4, top=0.1,
                                bevel=0.0, rot=(math.cos(a) * 25, 0, math.sin(a) * 25)))
    colors = {"body": (128, 124, 116), "accent": (150, 140, 120), "leaf": (88, 128, 60)}
    return k.model("11f", colors, 1200, (1.5, 2.5, 0.6), budget="mid",
                   meta={"prop": "decor", "decor": "STEPPING_STONES", "replaces": "Shared/Decor STEPPING_STONES"})
