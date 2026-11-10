"""Campsite decoration Dino Statue (Decor DINO_STATUE, 3 x 4): a carved raptor-ish sauropod (body) on a
stepped plinth (body), mossy top (accent, Decor's Moss); neck / head forward (-Z), tail back (+Z),
as Decor's blocks.
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
    k.add("body", C.rbox((0, 0.25, 0), (3.0, 0.5, 3.0), bevel=0.08, segments=2),
          C.rbox((0, 0.65, 0), (2.6, 0.32, 2.6), bevel=0.06))
    k.add("accent", C.ell((0.3, 0.82, 0.2), (1.2, 0.08, 1.15), 12, 3),
          C.ell((-0.95, 0.5, 1.2), (0.45, 0.14, 0.3), 8, 3), C.ell((1.2, 0.4, -0.8), (0.3, 0.12, 0.5), 8, 3))
    # the dino: body, legs, neck, head, tail
    k.add("body", C.ell((0, 2.05, 0.3), (0.72, 0.75, 1.15), 12, 8),
          C.rod((0, 2.4, -0.4), (0, 3.6, -0.85), 0.36, segments=10, top=0.75),
          C.ell((0, 3.85, -1.05), (0.4, 0.36, 0.6), 10, 6),
          C.ell((0, 3.72, -1.55), (0.28, 0.22, 0.35), 8, 5),
          C.rod((0, 2.1, 1.25), (0, 1.55, 1.8), 0.42, segments=10, top=0.25),
          C.ell((0, 1.45, 1.85), (0.1, 0.1, 0.1), 6, 4))
    for x in (-1, 1):
        for z in (-0.2, 0.8):
            k.add("body", C.rod((x * 0.42, 1.6, z), (x * 0.45, 0.82, z), 0.2, segments=7))
        k.add("dark", C.ell((x * 0.3, 3.95, -1.3), (0.06, 0.07, 0.07), 6, 3))
    for i in range(4):  # back ridge
        k.add("body", C.ell((0, 2.82 - abs(i - 1.5) * 0.12, -0.1 + i * 0.4), (0.07, 0.2, 0.14), 6, 3))
    colors = {"body": (150, 146, 138), "accent": (88, 128, 60), "dark": (70, 66, 60)}
    return k.model("11f", colors, 1200, (1.5, 2.0, 4.4), budget="mid",
                   meta={"prop": "decor", "decor": "DINO_STATUE", "replaces": "Shared/Decor DINO_STATUE"})
