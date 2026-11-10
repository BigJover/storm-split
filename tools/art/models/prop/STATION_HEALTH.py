"""Herb Kitchen (training station `health`): a camp kitchen table (top 6 x 3 at y 3.25, centred z -4
as the blocky Table) with the fern-smoothie cauldron (where the blocky Pot was, x -1), fern bunches
(x 1.6), jars, a mortar and pestle and a drying rack of herbs behind it. Frame = buildStation's `base`."""

import importlib.util
from pathlib import Path

_s = importlib.util.spec_from_file_location("_camp", Path(__file__).with_name("_camp.py"))
C = importlib.util.module_from_spec(_s)
_s.loader.exec_module(C)



def build(lp):
    k = C.Camp(lp)
    z = -4.0
    k.add("wood", *C.plank_floor((0, 3.4, z), 6.0, 3.0, h=0.3, n=4))
    for x in (-2.5, 2.5):
        for dz in (-1.1, 1.1):
            k.add("wood", C.rod((x, 0, z + dz), (x, 3.1, z + dz), 0.2, segments=8))
        k.add("dark", C.bar((x, 0.8, z - 1.1), (x, 0.8, z + 1.1), 0.14, 0.14))
    k.add("dark", C.bar((-2.5, 0.8, z), (2.5, 0.8, z), 0.14, 0.14),
          C.rbox((0, 3.08, z - 1.42), (6.0, 0.18, 0.12), bevel=0.04),
          C.rbox((0, 3.08, z + 1.42), (6.0, 0.18, 0.12), bevel=0.04))
    # cauldron on three stubby feet
    cx = -1.0
    k.add("metal", C.ell((cx, 4.25, z), (0.95, 0.8, 0.95), 12, 7),
          C.ring((cx, 4.85, z), 0.82, 0.1, 16, 5))
    for i in range(3):
        import math
        a = i * 2 * math.pi / 3
        k.add("metal", C.rod((cx + math.cos(a) * 0.6, 3.75, z + math.sin(a) * 0.6),
                             (cx + math.cos(a) * 0.7, 3.4, z + math.sin(a) * 0.7), 0.1, segments=6))
    k.add("smoothie", C.cyl((cx, 4.82, z), 0.74, 0.06, segments=16, bevel=0.0))
    for dx, dz, r in ((-0.2, 0.15, 0.14), (0.25, -0.2, 0.1), (0.05, -0.35, 0.08)):
        k.add("leaf", C.ell((cx + dx, 4.87, z + dz), (r, 0.05, r), 6, 3))
    k.add("wood", C.rod((cx + 0.3, 4.75, z + 0.1), (cx + 0.95, 5.85, z + 0.55), 0.06, segments=6),
          C.ell((cx + 0.22, 4.7, z + 0.05), (0.22, 0.08, 0.18), 8, 4))
    # fern bunches + cutting board
    k.add("wood", C.rbox((1.6, 3.6, z + 0.1), (1.7, 0.1, 1.1), bevel=0.04))
    for dx, dz, lean in ((1.2, -0.1, -20), (1.6, 0.2, 0), (2.0, -0.05, 20), (1.45, 0.4, 10), (1.85, 0.45, -12)):
        k.add("leaf", C.ell((dx, 3.65, z + dz), (0.5, 0.06, 0.16), 6, 3, rot=(0, lean * 3, 0)))
    # jars along the back edge + mortar and pestle at the front
    for dx, h, g in ((0.4, 0.55, "jarg"), (0.85, 0.45, "jarr"), (2.5, 0.6, "jarg")):
        k.add(g, C.cyl((dx, 3.55 + h / 2, z - 1.05), 0.2, h, segments=7))
        k.add("cork", C.cyl((dx, 3.6 + h, z - 1.05), 0.13, 0.12, segments=5))
    k.add("stone", C.cyl((0.6, 3.75, z + 0.95), 0.32, 0.4, segments=10, top=0.75),
          C.rod((0.6, 3.85, z + 0.95), (0.85, 4.3, z + 0.75), 0.06, segments=6))
    # drying rack behind the table, herb bundles hanging
    for x in (-2.8, 2.8):
        k.add("wood", C.rod((x, 0, z - 1.7), (x, 6.2, z - 1.7), 0.16, segments=8))
    k.add("wood", C.rod((-3.0, 6.0, z - 1.7), (3.0, 6.0, z - 1.7), 0.12, segments=8))
    for i, x in enumerate((-2.1, -1.2, -0.3, 0.6, 1.5, 2.3)):
        k.add("rope", C.rod((x, 6.0, z - 1.7), (x, 5.4, z - 1.7), 0.04, segments=4))
        k.add("herb" if i % 2 else "leaf", C.ell((x, 5.05, z - 1.7), (0.26, 0.42, 0.2), 7, 5))
    # a basket of ferns under the table
    k.add("rope", C.cyl((1.4, 0.35, z + 0.3), 0.55, 0.7, segments=10, top=1.15))
    for dx in (-0.2, 0.15):
        k.add("leaf", C.cyl((1.4 + dx, 0.95, z + 0.3), (0.12, 0.25), 0.7, segments=6, top=0.1, bevel=0.0, rot=(0, 0, dx * 80)))
    colors = {"wood": C.WOOD, "dark": C.DARK, "metal": (80, 80, 90), "smoothie": (120, 200, 90),
              "leaf": (60, 140, 70), "herb": (150, 160, 80), "jarg": (120, 170, 120), "jarr": (190, 90, 80),
              "cork": (190, 150, 100), "stone": C.STONE, "rope": C.ROPE}
    return k.model("11f", colors, 2500, (3.2, 6.0, 6.5),
                   meta={"prop": "station", "station": "health", "display": "Herb Kitchen",
                         "replaces": "Server/Outpost buildStation health: Table, Leg x2, Pot, Ferns"})
