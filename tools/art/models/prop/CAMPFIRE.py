"""The Outpost's camp fire (Server/Outpost CampFire: a 3 x 1.2 x 3 Neon ball at CENTRE + (0, 0.7, 12),
its PointLight and the Outpost name sign). Origin = CENTRE + (0, 0, 12) on the floor. A wide stone ring,
a log tepee, Neon flames (glow) and a cooking tripod with a kettle. Hang the PointLight / sign on the
`glow` piece (its centre is about y 1.2)."""

import importlib.util
import math
from pathlib import Path

_s = importlib.util.spec_from_file_location("_camp", Path(__file__).with_name("_camp.py"))
C = importlib.util.module_from_spec(_s)
_s.loader.exec_module(C)

def build(lp):
    k = C.Camp(lp)
    for i in range(12):
        a = i * 2 * math.pi / 12
        r = 2.3 + 0.08 * (i % 2)
        ry = 0.36 + 0.05 * (i % 3)
        k.add("stone", C.ell((math.cos(a) * r, ry, math.sin(a) * r), (0.55, ry, 0.45), 8, 5, rot=(0, -math.degrees(a), 0)))
    k.add("dark", C.cyl((0, 0.06, 0), 1.9, 0.12, segments=18, bevel=0.0))
    for i in range(6):
        a = i * math.pi / 3 + 0.3
        k.add("wood", C.rod((math.cos(a) * 1.5, 0.15, math.sin(a) * 1.5), (math.cos(a) * 0.15, 1.9, math.sin(a) * 0.15), 0.17, segments=7))
    for a in (0.2, 2.3):
        k.add("wood", C.rod((math.cos(a) * 1.6, 0.2, math.sin(a) * 1.6), (math.cos(a + 1.3) * 1.6, 0.2, math.sin(a + 1.3) * 1.6), 0.2, segments=7))
    k.add("glow", C.ell((0, 0.5, 0), (0.85, 0.45, 0.85), 10, 5), *C.flame((0, 0.4, 0), r=0.8, h=2.6),
          *C.flame((0.3, 0.4, 0.2), r=0.45, h=1.6, yaw=60))
    # cooking tripod + kettle
    for i in range(3):
        a = i * 2 * math.pi / 3 + 0.5
        k.add("dark", C.rod((math.cos(a) * 2.0, 0, math.sin(a) * 2.0), (0, 4.1, 0), 0.08, segments=6))
    k.add("metal", C.rod((0, 4.0, 0), (0, 3.3, 0), 0.03, segments=4),
          C.ell((0, 3.0, 0), (0.42, 0.36, 0.42), 10, 6), C.cyl((0, 3.38, 0), 0.22, 0.12, segments=8),
          C.rod((0.4, 3.05, 0), (0.7, 3.25, 0), 0.06, segments=5))
    colors = {"stone": C.STONE, "dark": (60, 52, 46), "wood": (100, 70, 45), "glow": (255, 140, 50), "metal": C.METAL}
    return k.model("11f", colors, 2500, (3.0, 3.0, 4.3),
                   meta={"prop": "camp", "replaces": "Server/Outpost CampFire (Neon ball)"})
