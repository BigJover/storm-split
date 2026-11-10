"""The Hatchery Hut (Server/Outpost HatcheryHut 10 x 7 x 8 + HutRoof 12 x 1 x 10, at CENTRE + HATCHERY_HUT;
Client/Pets opens it with E within HUT_RADIUS). Origin = that spot on the floor; front (door) = -Z,
toward the camp centre. Log walls, a thatched gable roof, a round door, warm windows (glow), a nest of
big speckled eggs by the door and a sign board: piece `face` over the door (Front = -Z, 4 x 1.0 at
(0, 4.75, -4.72)) for a SurfaceGui "Hatchery Hut". Keep the blocky HatcheryHut as the invisible collider."""

import importlib.util
import math
from pathlib import Path

_s = importlib.util.spec_from_file_location("_camp", Path(__file__).with_name("_camp.py"))
C = importlib.util.module_from_spec(_s)
_s.loader.exec_module(C)

def build(lp):
    k = C.Camp(lp)
    W, D, H = 10.0, 8.0, 6.0
    # log walls: front/back as stacked logs, sides as planks
    for i in range(6):
        y = 0.5 + i * 1.0
        for s in (-1, 1):
            k.add("wood", C.rod((-W / 2, y, s * D / 2), (W / 2, y, s * D / 2), 0.5, segments=8))
            k.add("wood", C.rod((s * W / 2, y + 0.5, -D / 2), (s * W / 2, y + 0.5, D / 2), 0.48, segments=8))
    # gable ends (planks) + thatch roof
    for s in (-1, 1):
        k.add("dark", C.rbox((0, H + 1.2, s * D / 2), (W - 0.6, 2.4, 0.3), bevel=0.05, taper=(0.08, 1)))
    k.add("leaf", C.rbox((-3.15, H + 1.55, 0), (7.0, 0.5, D + 2.0), bevel=0.2, segments=2, rot=(0, 0, 34)),
          C.rbox((3.15, H + 1.55, 0), (7.0, 0.5, D + 2.0), bevel=0.2, segments=2, rot=(0, 0, -34)))
    k.add("straw", C.rod((0, H + 3.4, -D / 2 - 1.0), (0, H + 3.4, D / 2 + 1.0), 0.35, segments=8))
    # big egg on the ridge
    k.add("egg", C.ell((0, H + 4.35, 0), (0.6, 0.85, 0.6), 10, 7))
    # door + frame, windows with shutters (all proud of the front logs, z < -4.5)
    f = -D / 2 - 0.5
    k.add("dark", C.rbox((0, 1.75, f - 0.05), (2.4, 3.5, 0.2), bevel=0.3, segments=3),
          C.rbox((0, 3.65, f - 0.15), (3.0, 0.35, 0.35), bevel=0.08))
    for x in (-1.35, 1.35):
        k.add("dark", C.rod((x, 0, f - 0.15), (x, 3.6, f - 0.15), 0.16, segments=6))
    k.add("brass", C.ell((0.75, 1.75, f - 0.2), (0.12, 0.12, 0.08), 6, 4))
    for x in (-3.2, 3.2):
        k.add("glow", C.rbox((x, 3.3, f - 0.02), (1.3, 1.1, 0.06), bevel=0.0))
        k.add("dark", C.rbox((x, 3.3, f - 0.1), (0.1, 1.2, 0.1), bevel=0.02),
              C.rbox((x - 1.05, 3.3, f - 0.12), (0.75, 1.3, 0.1), bevel=0.03),
              C.rbox((x + 1.05, 3.3, f - 0.12), (0.75, 1.3, 0.1), bevel=0.03),
              C.rbox((x, 2.65, f - 0.2), (1.6, 0.16, 0.36), bevel=0.04))
    # sign board over the door
    k.add("dark", C.rbox((0, 4.75, f - 0.1), (4.4, 1.3, 0.18), bevel=0.06))
    k.add("face", C.face((0, 4.75, f - 0.22), 4.0, 1.0))
    # straw nest of eggs by the door (front-left)
    k.add("straw", C.ring((-3.4, 0.3, -D / 2 - 1.3), 0.8, 0.3, 12, 5))
    for dx, dz, g in ((-0.25, 0.1, "egg"), (0.3, -0.1, "egg2"), (0.0, 0.35, "egg2")):
        k.add(g, C.ell((-3.4 + dx, 0.6, -D / 2 - 1.3 + dz), (0.32, 0.45, 0.32), 8, 6))
    colors = {"wood": (170, 130, 80), "dark": (110, 76, 46), "leaf": (110, 140, 70), "straw": (214, 186, 110),
              "egg": (240, 226, 190), "egg2": (170, 200, 150), "brass": C.BRASS, "glow": (255, 200, 110), "face": C.PAPER}
    return k.model("11f", colors, 2500, (6.2, 6.5, 11.3),
                   meta={"prop": "camp", "replaces": "Server/Outpost HatcheryHut + HutRoof",
                         "faces": {"face": "Front: 'Hatchery Hut' sign"}})
