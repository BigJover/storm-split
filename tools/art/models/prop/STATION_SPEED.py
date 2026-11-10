"""Raptor Chase (training station `speed`): a running lane edged with logs and distance stakes,
the wind-up tin raptor at its +Z end facing down the lane (-Z), its key on the right (+X).
Frame = buildStation's `base`: lane 4 x 14 centred, raptor at z 6.5 (as the blocky build)."""

import importlib.util
from pathlib import Path

_s = importlib.util.spec_from_file_location("_camp", Path(__file__).with_name("_camp.py"))
C = importlib.util.module_from_spec(_s)
_s.loader.exec_module(C)



def build(lp):
    k = C.Camp(lp)
    k.add("dirt", C.rbox((0, 0.15, 0), (4.0, 0.3, 14.0), bevel=0.12, segments=2))
    for x in (-1, 1):  # edge logs
        k.add("wood", C.rod((x * 2.2, 0.2, -7.0), (x * 2.2, 0.2, 7.0), 0.2, segments=8))
        for zz in (-6.5, -3.0, 0.5, 4.0):  # distance stakes with pennants
            k.add("dark", C.rod((x * 2.55, 0.0, zz), (x * 2.55, 1.3, zz), 0.07, segments=6))
            k.add("flag", C.rbox((x * 2.55 + x * 0.25, 1.12, zz), (0.5, 0.32, 0.03), bevel=0.0, taper=(0.3, 1)))
    k.add("chalk", C.rbox((0, 0.31, -6.3), (3.8, 0.03, 0.25), bevel=0.0),
          C.rbox((0, 0.31, -2.8), (3.8, 0.03, 0.12), bevel=0.0),
          C.rbox((0, 0.31, 0.7), (3.8, 0.03, 0.12), bevel=0.0))
    # wind-up raptor on a wheeled base, facing -Z
    z = 6.5
    k.add("metal", C.rbox((0, 0.48, z), (1.6, 0.22, 2.6), bevel=0.08))
    for x in (-1, 1):
        for zz in (z - 0.9, z + 0.9):
            k.add("dark", C.cyl((x * 0.85, 0.4, zz), 0.3, 0.16, segments=10, rot=(0, 0, 90)))
        k.add("body", C.rod((x * 0.45, 0.6, z - 0.2), (x * 0.5, 1.35, z + 0.1), 0.2, segments=8),
              C.rod((x * 0.3, 1.9, z - 0.8), (x * 0.4, 1.55, z - 1.15), 0.09, segments=6))
        k.add("eye", C.ell((x * 0.32, 2.72, z - 1.65), (0.1, 0.12, 0.12), 8, 5))
    k.add("body", C.ell((0, 1.7, z), (0.8, 0.75, 1.15), 12, 8),
          C.rod((0, 2.0, z - 0.7), (0, 2.45, z - 1.25), 0.38, segments=10, top=0.8),
          C.ell((0, 2.6, z - 1.5), (0.45, 0.42, 0.6), 10, 6),
          C.ell((0, 2.45, z - 2.0), (0.32, 0.25, 0.45), 8, 5),
          C.rod((0, 1.8, z + 0.95), (0, 2.1, z + 1.95), 0.42, segments=10, top=0.15))
    k.add("brass", C.ring((0, 1.7, z), 0.8, 0.06, 16, 4, rot=(90, 0, 0)),
          C.ring((0, 1.7, z), 0.81, 0.06, 16, 4, rot=(0, 0, 90)))
    for i in range(6):  # rivets along the seam
        zz = z - 0.8 + i * 0.32
        k.add("brass", C.ell((0, 2.44 - abs(zz - z) * 0.3, zz), (0.07, 0.07, 0.07), 6, 4))
    k.add("dark", C.ell((0, 2.34, z - 2.0), (0.3, 0.04, 0.4), 8, 4))
    # the key (+X side), as the blocky build's Key part
    k.add("brass", C.rod((0.72, 1.6, z + 0.35), (1.2, 1.6, z + 0.35), 0.07, segments=6),
          C.ring((1.25, 1.6, z - 0.05), 0.3, 0.08, 10, 4, rot=(0, 0, 90)),
          C.ring((1.25, 1.6, z + 0.75), 0.3, 0.08, 10, 4, rot=(0, 0, 90)))
    colors = {"dirt": (128, 98, 66), "wood": C.WOOD, "dark": C.DARK, "flag": (220, 90, 60),
              "chalk": (236, 230, 214), "metal": C.METAL, "body": (150, 170, 80), "eye": (240, 236, 220),
              "brass": C.BRASS}
    return k.model("11f", colors, 2500, (3.1, 8.5, 3.5),
                   meta={"prop": "station", "station": "speed", "display": "Raptor Chase",
                         "replaces": "Server/Outpost buildStation speed: Lane, Raptor, Key"})
