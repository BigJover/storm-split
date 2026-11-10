"""A Campsite's Hatchling Pen (Server/Outpost HatchlingPen 7 x 0.25 x 7 + 4 PenPosts 0.5 x 2, at
facing * (-6, 0, 5)). Origin = the pen's centre on the Campsite ground, in the Campsite's frame
(front -Z = toward the camp centre). A plank floor (top y 0.3, as the blocky one: Server/Pets stands
up to 3 pets on it at x -2.2 / 0 / 2.2), a low post-and-rail fence with a gate at the front, straw
patches, a water trough at the back. Keep the blocky HatchlingPen part (invisible) as the pets' and
owner sign's anchor."""

import importlib.util
import math
from pathlib import Path

_s = importlib.util.spec_from_file_location("_camp", Path(__file__).with_name("_camp.py"))
C = importlib.util.module_from_spec(_s)
_s.loader.exec_module(C)

def build(lp):
    k = C.Camp(lp)
    k.add("wood", *C.plank_floor((0, 0.3, 0), 7.0, 7.0, h=0.28, n=7, along_x=False))
    for x in (-3.5, 3.5):
        for z in (-3.5, 3.5):
            k.add("dark", C.rod((x, 0, z), (x, 2.0, z), 0.24, segments=8), C.ell((x, 2.02, z), (0.24, 0.1, 0.24), 8, 3))
    for x in (-3.5, 3.5):  # side rails
        for y in (0.95, 1.65):
            k.add("wood", C.bar((x, y, -3.5), (x, y, 3.5), 0.14, 0.2))
    for y in (0.95, 1.65):  # back rail, front rails either side of the gate
        k.add("wood", C.bar((-3.5, y, 3.5), (3.5, y, 3.5), 0.14, 0.2),
              C.bar((-3.5, y, -3.5), (-1.0, y, -3.5), 0.14, 0.2),
              C.bar((1.0, y, -3.5), (3.5, y, -3.5), 0.14, 0.2))
    for x in (-1.0, 1.0):
        k.add("dark", C.rod((x, 0.3, -3.5), (x, 1.85, -3.5), 0.14, segments=7))
    # the gate, ajar
    k.add("wood", C.bar((-0.95, 0.85, -3.5), (0.3, 0.85, -4.0), 0.14, 0.18),
          C.bar((-0.95, 1.5, -3.5), (0.3, 1.5, -4.0), 0.14, 0.18),
          C.bar((-0.7, 0.75, -3.6), (0.1, 1.6, -3.92), 0.1, 0.14))
    # straw patches + trough
    for x, z, r in ((-1.8, 1.4, 0.9), (1.5, -0.8, 0.7), (2.1, 2.2, 0.6)):
        k.add("straw", C.ell((x, 0.33, z), (r, 0.08, r * 0.8), 10, 3))
    k.add("dark", C.rbox((0.0, 0.62, 2.85), (2.2, 0.6, 0.7), bevel=0.08))
    k.add("water", C.rbox((0.0, 0.88, 2.85), (1.9, 0.06, 0.45), bevel=0.0))
    colors = {"wood": (150, 120, 80), "dark": (120, 84, 52), "straw": (214, 186, 110), "water": (90, 150, 190)}
    return k.model("11f", colors, 2500, (3.8, 4.1, 2.2),
                   meta={"prop": "camp", "replaces": "Server/Outpost HatchlingPen + PenPost x4 (per Campsite)"})
