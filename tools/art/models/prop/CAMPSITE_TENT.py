"""OPTIONAL Campsite ambience (no blocky counterpart today): a two-person A-frame hunter's tent with a
bedroll, a stack of gear and a lantern. Proposed spot: the Campsite frame's free corner (-6, 0, -5),
clear of the pen (-6, 5), the Display Tower spots (x 6) and the decoration spots (x 0). Origin = its
footprint centre on the ground, door -Z. Needs Jovan's OK before the runtime adds it."""

import importlib.util
import math
from pathlib import Path

_s = importlib.util.spec_from_file_location("_camp", Path(__file__).with_name("_camp.py"))
C = importlib.util.module_from_spec(_s)
_s.loader.exec_module(C)

def build(lp):
    k = C.Camp(lp)
    L, Wd, H = 4.2, 3.4, 2.7
    ang = math.degrees(math.atan2(H, Wd / 2))
    side = math.hypot(Wd / 2, H)
    for s in (-1, 1):  # canvas sides, each leaning from its ground edge up to the ridge
        k.add("canvas", C.rbox((s * Wd / 4, H / 2, 0.2), (side, 0.08, L), bevel=0.03, rot=(0, 0, -s * ang)))
    k.add("canvas2", C.rbox((0, H * 0.35, L / 2 + 0.18), (Wd * 0.55, H * 0.7, 0.06), bevel=0.0, taper=(0.12, 1)))  # back wall
    # door flaps folded open at the front
    for s in (-1, 1):
        k.add("canvas2", C.rbox((s * 0.75, H * 0.38, -L / 2 + 0.15), (0.9, H * 0.72, 0.06), bevel=0.0, taper=(0.2, 1), rot=(0, s * 35, 0)))
    # ridge pole + uprights + stakes and guy ropes
    k.add("wood", C.rod((0, H + 0.05, -L / 2 - 0.1), (0, H + 0.05, L / 2 + 0.4), 0.08, segments=6))
    for z in (-L / 2 - 0.05, L / 2 + 0.35):
        k.add("wood", C.rod((0, 0, z), (0, H + 0.25, z), 0.08, segments=6))
    for s in (-1, 1):
        for z in (-1.4, 1.6):
            k.add("rope", C.rod((s * (Wd / 2 - 0.05), 0.15, z), (s * (Wd / 2 + 0.25), 0.0, z), 0.04, segments=4))
            k.add("dark", C.rod((s * (Wd / 2 + 0.25), 0.0, z), (s * (Wd / 2 + 0.25), 0.3, z), 0.04, segments=4))
    # bedroll inside, gear outside
    k.add("accent", C.cyl((0.2, 0.25, 0.4), 0.25, 1.6, segments=8, rot=(90, 0, 0)))
    core, frame = C.crate((-1.7 + 0.1, 0.35, -L / 2 - 0.6), (0.8, 0.7, 0.7), yaw=15)
    k.add("wood", core)
    k.add("dark", *frame)
    k.add("metal", C.cyl((1.45, 0.08, -L / 2 - 0.5), 0.2, 0.1, segments=8), C.cyl((1.45, 0.55, -L / 2 - 0.5), 0.17, 0.1, segments=8),
          C.rod((1.45, 0.62, -L / 2 - 0.5), (1.45, 0.8, -L / 2 - 0.5), 0.03, segments=4))
    k.add("glow", C.cyl((1.45, 0.3, -L / 2 - 0.5), 0.14, 0.38, segments=8, bevel=0.0))
    colors = {"canvas": (196, 182, 140), "canvas2": (176, 160, 120), "wood": C.WOOD, "rope": C.ROPE, "dark": C.DARK,
              "accent": (200, 90, 60), "metal": C.METAL, "glow": (255, 200, 110)}
    return k.model("11f", colors, 2500, (2.2, 3.2, 3.0),
                   meta={"prop": "camp", "optional": True, "replaces": "(new) Campsite tent"})
