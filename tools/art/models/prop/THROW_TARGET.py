"""Coconut Toss target (training station `throw`): a bullseye board on an A-frame stand, propped with a
back leg; a few coconuts that missed lie around it. Origin = the ground under the board's centre; the
board faces +Z (back toward the throwing line), its centre at y 2 like the blocky Target cylinder
(3 across). The runtime places three: base * (-3, 0, -10), (0, 0, -16), (3, 0, -22)."""

import importlib.util
from pathlib import Path

_s = importlib.util.spec_from_file_location("_camp", Path(__file__).with_name("_camp.py"))
C = importlib.util.module_from_spec(_s)
_s.loader.exec_module(C)



def build(lp):
    k = C.Camp(lp)
    c = (0.0, 2.0, 0.0)
    k.add("target", C.cyl(c, 1.5, 0.28, segments=18, bevel=0.0, rot=(90, 0, 0)))
    for r, g, dz in ((1.15, "white", 0.15), (0.78, "target", 0.18), (0.42, "white", 0.21), (0.16, "target", 0.24)):
        for side in (1, -1):  # painted both sides (reads from the line and from behind)
            k.add(g, C.cyl((0, 2.0, dz * side), r, 0.04, segments=16, bevel=0.0, rot=(90, 0, 0)))
    k.add("wood", C.ring(c, 1.52, 0.1, 20, 5, rot=(90, 0, 0)))
    for s in (-1, 1):  # A-frame legs behind the board, a cross bar, the back prop
        k.add("wood", C.rod((s * 1.05, 0, -0.25), (s * 0.15, 3.55, -0.25), 0.11, segments=7))
    k.add("wood", C.rod((0, 2.6, -0.3), (0, 0, -1.6), 0.11, segments=7),
          C.bar((-1.0, 0.75, -0.3), (1.0, 0.75, -0.3), 0.14, 0.14))
    k.add("rope", C.ring((0, 3.45, -0.25), 0.2, 0.06, 10, 4, rot=(90, 0, 0)))
    # coconuts that missed + a dented one stuck in the bottom of the board
    for x, z in ((1.1, 0.9), (-1.2, 0.6), (0.4, 1.5)):
        k.add("nut", C.ell((x, 0.27, z), (0.3, 0.27, 0.3), 8, 6))
    colors = {"wood": C.WOOD, "rope": C.ROPE, "nut": (110, 76, 44), "dark": (100, 80, 60),
              "target": (220, 70, 60), "white": (240, 234, 220)}
    return k.model("11f", colors, 1500, (1.7, 1.9, 3.8), budget="mid",
                   meta={"prop": "station", "station": "throw", "display": "Coconut Toss target",
                         "replaces": "Server/Outpost buildStation throw: Target (x3, one model each)"})
