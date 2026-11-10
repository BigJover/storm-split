"""Campsite decoration Fire Pit (Decor FIRE_PIT, 4 x 4): a ring of round stones (body), a log tepee
(wood), flames (accent, as Decor's Flame) round a small Neon ember core (glow).
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
    for i in range(9):
        a = i * 2 * math.pi / 9
        r = 1.5 + (0.08 if i % 2 else -0.05)
        k.add("body", C.ell((math.cos(a) * r, 0.28 + 0.04 * (i % 3), math.sin(a) * r), (0.42, 0.28 + 0.04 * (i % 3), 0.36), 8, 5,
                            rot=(0, -math.degrees(a), 0)))
    k.add("dark", C.cyl((0, 0.06, 0), 1.15, 0.1, segments=14, bevel=0.0))  # ash bed
    for i in range(4):  # tepee logs
        a = i * math.pi / 2 + 0.4
        k.add("wood", C.rod((math.cos(a) * 0.95, 0.12, math.sin(a) * 0.95), (math.cos(a) * 0.1, 1.15, math.sin(a) * 0.1), 0.13, segments=7))
    k.add("wood", C.rod((-0.9, 0.18, 0.6), (0.85, 0.18, 0.75), 0.16, segments=7))
    k.add("glow", C.ell((0, 0.35, 0), (0.45, 0.3, 0.45), 8, 5))
    k.add("accent", *C.flame((0, 0.3, 0), r=0.5, h=1.6))
    colors = {"body": (128, 124, 116), "accent": (255, 140, 50), "wood": (100, 70, 45), "dark": (60, 52, 46), "glow": (255, 200, 90)}
    return k.model("11f", colors, 1200, (2.0, 2.0, 2.0), budget="mid",
                   meta={"prop": "decor", "decor": "FIRE_PIT", "replaces": "Shared/Decor FIRE_PIT"})
