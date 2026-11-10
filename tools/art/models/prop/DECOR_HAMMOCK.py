"""Campsite decoration Hammock (Decor HAMMOCK, 2 x 5): two posts (accent) at z -2.3 / +2.3 like Decor's,
ropes (rope) to a sagging cloth sling (body) with a striped edge and a rolled pillow.
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
    for s in (-1, 1):
        k.add("accent", C.rod((0, 0, s * 2.3), (0, 3.0, s * 2.3), 0.2, segments=8, top=0.85),
              C.ell((0, 3.02, s * 2.3), (0.18, 0.1, 0.18), 7, 3))
        k.add("dark", C.ell((0, 0.1, s * 2.3), (0.35, 0.12, 0.2), 7, 3))
        k.add("rope", C.rod((0, 2.6, s * 2.25), (0.0, 1.7, s * 1.6), 0.04, segments=4),
              C.rod((0, 2.6, s * 2.25), (0.45, 1.6, s * 1.55), 0.035, segments=4),
              C.rod((0, 2.6, s * 2.25), (-0.45, 1.6, s * 1.55), 0.035, segments=4),
              C.ring_along((0, 2.6, s * 2.25), (0, 2.6, s * 2.35), 0.22, 0.04, 8, 3))
    # sling: segments along a sag curve
    n = 6
    for i in range(n):
        t0, t1 = i / n, (i + 1) / n
        za, zb = -1.6 + 3.2 * t0, -1.6 + 3.2 * t1
        ya = 1.6 - 0.55 * math.sin(math.pi * t0)
        yb = 1.6 - 0.55 * math.sin(math.pi * t1)
        k.add("body", C.bar((0, ya, za), (0, yb, zb), 1.15 - 0.25 * abs(0.5 - (t0 + t1) / 2), 0.07, bevel=0.03))
        for x in (-1, 1):
            k.add("accent", C.bar((x * (0.6 - 0.12 * abs(0.5 - (t0 + t1) / 2)), ya + 0.07, za), (x * (0.6 - 0.12 * abs(0.5 - (t0 + t1) / 2)), yb + 0.07, zb), 0.1, 0.1, bevel=0.0))
    k.add("canvas", C.rod((-0.4, 1.5, -1.25), (0.4, 1.5, -1.25), 0.17, segments=8))
    colors = {"body": (200, 90, 60), "accent": C.WOOD, "rope": C.ROPE, "dark": (90, 80, 70), "canvas": C.CANVAS}
    return k.model("11f", colors, 1200, (1.0, 2.5, 3.2), budget="mid",
                   meta={"prop": "decor", "decor": "HAMMOCK", "replaces": "Shared/Decor HAMMOCK"})
