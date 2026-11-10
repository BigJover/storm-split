"""Campsite decoration Wanted Poster (Decor WANTED_POSTER, 3 x 1): two posts (accent), a framed board
(body) under a little plank roof, and the poster sheet = piece `face` (group face): a flat 2.1 x 2.0
plate at the board's centre (0, 2.3, 0). Put Decor's SurfaceGuis (Front and Back, CanvasSize 230 x 220)
on `face`; its Front is -Z, as the blocky Board's.
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
    for x in (-1.3, 1.3):
        k.add("accent", C.rod((x, 0, 0), (x, 3.75, 0), 0.15, segments=8))
        k.add("dark", C.ell((x, 0.1, 0), (0.19, 0.12, 0.28), 7, 3))
    k.add("body", C.rbox((0, 2.3, 0), (2.4, 2.3, 0.12), bevel=0.03))  # backing board
    for y in (1.12, 3.48):  # frame rails
        k.add("accent", C.rbox((0, y, 0), (2.75, 0.16, 0.2), bevel=0.04))
    # little plank roof
    k.add("accent", C.rbox((0, 3.85, -0.18), (2.85, 0.08, 0.6), bevel=0.02, rot=(-22, 0, 0)),
          C.rbox((0, 3.85, 0.18), (2.85, 0.08, 0.6), bevel=0.02, rot=(22, 0, 0)))
    k.add("face", C.face((0, 2.3, 0), 2.1, 2.0, t=0.16))  # both sides proud of the board
    for x, y in ((-0.95, 3.2), (0.95, 3.2), (-0.95, 1.4), (0.95, 1.4)):  # nails, both faces
        for zz in (-0.09, 0.09):
            k.add("dark", C.ell((x, y, zz), (0.05, 0.05, 0.03), 6, 3))
    colors = {"body": (150, 110, 70), "accent": (110, 76, 46), "face": (232, 214, 170), "dark": (60, 50, 40)}
    return k.model("11f", colors, 1200, (1.5, 0.5, 4.2), budget="mid",
                   meta={"prop": "decor", "decor": "WANTED_POSTER", "replaces": "Shared/Decor WANTED_POSTER",
                         "faces": {"face": "Front + Back: Decor's poster SurfaceGuis (CanvasSize 230 x 220)"}})
