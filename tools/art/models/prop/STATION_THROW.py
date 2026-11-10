"""Coconut Toss (training station `throw`), the throwing end: a log throwing line on stakes at z 2 (the
blocky Line), a basket of coconuts at (-3, 3) (the blocky Coconut) and a crate of spares. Frame =
buildStation's `base`. The three far targets are model THROW_TARGET, placed by the runtime at the
blocky Targets' spots (x -3 / 0 / 3, z -10 / -16 / -22)."""

import importlib.util
from pathlib import Path

_s = importlib.util.spec_from_file_location("_camp", Path(__file__).with_name("_camp.py"))
C = importlib.util.module_from_spec(_s)
_s.loader.exec_module(C)



def build(lp):
    k = C.Camp(lp)
    # throwing line: a log on two stakes + chalk strip
    k.add("chalk", C.rbox((0, 0.03, 2.0), (8.0, 0.06, 0.5), bevel=0.0))
    k.add("wood", C.rod((-4.0, 0.3, 2.0), (4.0, 0.3, 2.0), 0.2, segments=8))
    for x in (-4.1, 4.1):
        k.add("dark", C.rod((x, 0, 2.0), (x, 0.9, 2.0), 0.12, segments=6))
    # coconut basket
    bx, bz = -3.0, 3.0
    k.add("rope", C.cyl((bx, 0.35, bz), 0.75, 0.7, segments=12, top=1.2),
          C.ring((bx, 0.72, bz), 0.88, 0.07, 14, 4))
    for dx, dy, dz in ((-0.3, 0.85, -0.2), (0.3, 0.85, 0.1), (-0.05, 0.85, 0.4), (0.0, 1.25, 0.05)):
        k.add("nut", C.ell((bx + dx, dy, bz + dz), (0.33, 0.3, 0.33), 8, 6))
    k.add("nut", C.ell((bx + 1.0, 0.3, bz - 0.4), (0.33, 0.3, 0.33), 8, 6))
    # a crate of spare coconuts at the right end of the line
    core, frame = C.crate((3.2, 0.45, 3.1), (1.2, 0.9, 0.9), yaw=12)
    k.add("wood", core)
    k.add("dark", *frame)
    for dx, dz in ((-0.25, -0.15), (0.25, 0.15)):
        k.add("nut", C.ell((3.2 + dx, 1.08, 3.1 + dz), (0.3, 0.27, 0.3), 8, 6))
    colors = {"chalk": (236, 230, 214), "wood": C.WOOD, "dark": C.DARK, "rope": C.ROPE,
              "nut": (110, 76, 44)}
    return k.model("11f", colors, 2500, (4.6, 4.0, 2.0),
                   meta={"prop": "station", "station": "throw", "display": "Coconut Toss",
                         "replaces": "Server/Outpost buildStation throw: Line, Coconut (Targets = THROW_TARGET x3)"})
