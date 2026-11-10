"""The Outpost Shop (Server/Outpost ShopCounter 8 x 3 x 2.5, at CENTRE + SHOP; Counter.client opens it with E
within SHOP_RADIUS). Origin = that spot on the floor; customers at the front (-Z). A plank market counter
(8 x 3 x 2.5, as the blocky one), a striped awning on four posts, goods (skin cloth rolls, crates, an egg
basket, a lantern) and a sign: piece `face` (Front = -Z, 5 x 1.2 on the awning's front at y 6.3) for a
SurfaceGui "Outpost Shop". Keep the blocky ShopCounter as the invisible collider + sign adornee."""

import importlib.util
import math
from pathlib import Path

_s = importlib.util.spec_from_file_location("_camp", Path(__file__).with_name("_camp.py"))
C = importlib.util.module_from_spec(_s)
_s.loader.exec_module(C)

def build(lp):
    k = C.Camp(lp)
    # counter: front planks, top, base
    k.add("wood", *C.plank_floor((0, 3.0, 0), 8.0, 2.5, h=0.25, n=3))
    for i in range(8):
        x = -3.5 + i
        k.add("wood" if i % 2 else "dark", C.rbox((x, 1.4, -1.15), (0.96, 2.75, 0.2), bevel=0.04))
    k.add("dark", C.rbox((0, 1.4, 0.1), (7.8, 2.75, 2.2), bevel=0.05))
    # awning posts + striped canvas
    for x in (-3.8, 3.8):
        for z in (-1.1, 2.3):
            k.add("dark", C.rod((x, 0, z), (x, 6.0 if z < 0 else 6.6, z), 0.14, segments=7))
    for i in range(8):
        x = -3.5 + i
        g = "accent" if i % 2 else "canvas"
        k.add(g, C.rbox((x, 6.3, 0.6), (1.0, 0.1, 4.2), bevel=0.02, rot=(-8, 0, 0)))
        k.add(g, C.rbox((x, 5.7, -1.55), (1.0, 0.7, 0.06), bevel=0.0, taper=(1, 1)))  # scalloped valance
    k.add("dark", C.rbox((0, 6.95, -1.62), (5.4, 1.4, 0.16), bevel=0.05))
    k.add("face", C.face((0, 6.95, -1.72), 5.0, 1.1))
    # goods on the counter
    for x, g in ((-2.8, "accent"), (-2.2, "cloth2"), (-1.6, "canvas")):
        k.add(g, C.cyl((x, 3.4, 0.2), 0.28, 1.6, segments=8, rot=(90, 0, 0)))
    k.add("rope", C.cyl((1.2, 3.45, 0.1), 0.6, 0.5, segments=10, top=1.2))
    for dx, dz in ((-0.2, 0.0), (0.25, 0.15), (0.0, -0.25)):
        k.add("egg", C.ell((1.2 + dx, 3.85, 0.1 + dz), (0.2, 0.28, 0.2), 7, 5))
    # crates beside, a hanging lantern
    core, frame = C.crate((-4.2 + 0.4, 0.5, 1.7), (1.0, 1.0, 1.0), yaw=-10)
    k.add("wood", core)
    k.add("dark", *frame)
    k.add("metal", C.rod((3.3, 5.95, -1.1), (3.3, 5.5, -1.1), 0.03, segments=4),
          C.cyl((3.3, 5.4, -1.1), 0.18, 0.08, segments=8), C.cyl((3.3, 4.95, -1.1), 0.2, 0.1, segments=8))
    k.add("glow", C.cyl((3.3, 5.17, -1.1), 0.15, 0.38, segments=8, bevel=0.0))
    colors = {"wood": (150, 110, 70), "dark": (110, 76, 46), "canvas": C.CANVAS, "accent": (200, 90, 60),
              "cloth2": (80, 120, 170), "rope": C.ROPE, "egg": (240, 226, 190), "metal": C.METAL,
              "glow": (255, 200, 110), "face": C.PAPER}
    return k.model("11f", colors, 2500, (4.5, 2.9, 7.7),
                   meta={"prop": "camp", "replaces": "Server/Outpost ShopCounter",
                         "faces": {"face": "Front: 'Outpost Shop' sign"}})
