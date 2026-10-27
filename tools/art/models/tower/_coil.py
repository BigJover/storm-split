"""COIL - Storm Coil (TowerLook copper): a copper coil wound up a steel column on a splayed
tripod, a steel storm-ring and a spark ball on top where the lightning leaves. Authored from the
base (y 0) in Roblox studs; front = -Z (_kit conventions).

Stage 0 (tiers 0-2): plank pad, tripod with insulator feet, the coil (copper rings), the
                     storm-ring, the spark ball, a cable to a battery crate.
Stage 1 (tier 3):    a taller coil with a second storm-ring, porcelain insulators on the legs,
                     three lightning-rod spikes round the ring, a cable drum.
Stage 2 (tier 5):    brass bands and a brass crown on the column, a glowing spark ball, glowing
                     arc crystals on the rods and a glowing charge gauge on the battery.
"""

import importlib.util
import math
from pathlib import Path

_spec = importlib.util.spec_from_file_location("_kit", Path(__file__).with_name("_kit.py"))
K = importlib.util.module_from_spec(_spec)
_spec.loader.exec_module(K)

COPPER = (190, 110, 50)  # TowerLook.COLORS.COIL
SPARK = (78, 98, 128)  # the spark ball, unlit (stage 2 lights it)
PORCELAIN = (226, 222, 210)
GLOW = (110, 225, 255)

HUB = 1.45  # tripod hub height
LEG_ANGLES = (-90, 30, 150)  # front, back-right-ish (kept low), back-left


def build(lp, stage):
    k = K.Kit(lp)
    top = 3.65 if stage == 0 else 3.85  # top of the coil
    ball_y = top + 0.58

    # plank pad under the tripod
    k.add("wood", *[K.rbox((x, 0.05, 0.0), (0.42, 0.1, 2.5), bevel=0.03) for x in (-0.88, -0.44, 0.0, 0.44, 0.88)])
    k.add("dark", *[K.rbox((0, 0.12, z), (2.2, 0.06, 0.16), bevel=0.02) for z in (-0.85, 0.85)])

    # tripod legs from the hub to insulator feet
    metal, porcelain = [], []
    feet = []
    for a in LEG_ANGLES:
        fx, fz = math.cos(math.radians(a)) * 1.15, math.sin(math.radians(a)) * 1.15
        feet.append((fx, fz))
        metal.append(K.rod((fx, 0.22, fz), (fx * 0.22, HUB, fz * 0.22), 0.07, 8))
        porcelain.append(K.cyl((fx, 0.17, fz), 0.16, 0.14, 10, top=0.8))
        if stage >= 1:  # porcelain insulator stack on each leg
            m = K.along((fx, 0.22, fz), (fx * 0.22, HUB, fz * 0.22), 0.45)
            porcelain.append(K.cyl(m, 0.13, 0.24, 8, top=0.7, bevel=0.04))
    metal.append(K.cyl((0, HUB, 0), 0.42, 0.26, 12, bevel=0.06))  # hub
    metal.append(K.rod((0, HUB, 0), (0, top + 0.1, 0), 0.2, 12))  # the column
    k.add("metal", *metal)
    k.add("porcelain", *porcelain)

    # the copper coil: tight rings up the column, narrowing toward the top
    n = 8
    coil = []
    for i in range(n):
        t = i / (n - 1)
        y = HUB + 0.3 + t * (top - HUB - 0.45)
        coil.append(K.ring((0, y, 0), 0.62 - 0.22 * t, 0.08, 10, 4))
    flange = K.cyl((0, HUB + 0.2, 0), 0.7, 0.1, 14, bevel=0.03)  # coil base flange
    k.add("body", *coil)
    k.add("brass" if stage >= 2 else "metal", flange)

    # storm-ring (toroid) at the top, the spark ball above it; the muzzle cap on the ball
    rings = [K.ring((0, top + 0.15, 0), 0.5, 0.15, 14, 5)]
    if stage >= 1:
        k.add("brass" if stage >= 2 else "metal", K.ring((0, top - 0.55, 0), 0.72, 0.08, 14, 4))
    k.add("metal", *rings, K.rod((0, top + 0.1, 0), (0, ball_y - 0.2, 0), 0.08, 8))
    k.add("glow" if stage >= 2 else "spark", K.ell((0, ball_y, 0), (0.34, 0.34, 0.34), 12, 7), piece="ball")
    k.add("metal", K.ring((0, ball_y + 0.33, 0), 0.1, 0.04, 8, 4), piece="muzzle", role="muzzle")

    # battery crate at the front-left, cable up to the hub
    bx, bz = -0.85, -0.75
    k.add("wood", K.rbox((bx, 0.36, bz), (0.62, 0.5, 0.48), bevel=0.05, rot=(0, 10, 0)))
    k.add("dark", *[K.rbox((bx, y, bz), (0.66, 0.07, 0.52), bevel=0.02, rot=(0, 10, 0)) for y in (0.2, 0.52)])
    k.add("metal", *[K.cyl((bx + dx, 0.66, bz), 0.07, 0.1, 8) for dx in (-0.15, 0.15)])  # terminals
    cable = [K.rod((bx + 0.15, 0.7, bz), (-0.35, 0.18, -0.35), 0.035, 6),
             K.rod((-0.35, 0.18, -0.35), (-0.1, HUB - 0.05, -0.1), 0.035, 6)]
    k.add("cable", *cable)

    brass = []
    if stage >= 1:
        # lightning-rod spikes on the lower ring
        rods = []
        for a in (-90, 30, 150):
            cx, cz = math.cos(math.radians(a)) * 0.72, math.sin(math.radians(a)) * 0.72
            y0 = top - 0.55
            rods.append(K.rod((cx, y0, cz), (cx * 1.3, y0 + 0.7, cz * 1.3), 0.045, 6, top=0.25))
        k.add("metal", *rods)
        # a cable drum at the back-left
        k.add("wood", *[K.cyl((-0.95, 0.42, 0.75 + dz), 0.36, 0.06, 10, rot=(90, 0, 0)) for dz in (-0.2, 0.2)])
        k.add("cable", K.cyl((-0.95, 0.42, 0.75), 0.24, 0.36, 10, rot=(90, 0, 0)))
        k.add("dark", K.rbox((-0.95, 0.07, 0.75), (0.5, 0.14, 0.6), bevel=0.04))

    if stage >= 2:
        brass += [K.ring((0, y, 0), 0.24, 0.05, 12, 4) for y in (HUB + 0.12, top + 0.02)]
        brass += [K.rod((math.cos(math.radians(a)) * 0.38, top + 0.2, math.sin(math.radians(a)) * 0.38),
                        (math.cos(math.radians(a)) * 0.2, ball_y - 0.1, math.sin(math.radians(a)) * 0.2), 0.035, 6)
                  for a in (0, 120, 240)]  # brass crown claws round the ball
        brass.append(K.cyl((-0.85, 0.66, -0.98), 0.12, 0.05, 10, rot=(90, 0, 0)))  # gauge bezel
        k.add("glow", K.cyl((-0.85, 0.66, -1.0), 0.09, 0.03, 10, rot=(90, 0, 0)), piece="gauge")
        crystals = []
        for a in (-90, 30, 150):
            cx, cz = math.cos(math.radians(a)) * 0.72 * 1.3, math.sin(math.radians(a)) * 0.72 * 1.3
            crystals.append(K.ell((cx, top + 0.18, cz), (0.08, 0.13, 0.08), 6, 4))
        k.add("glow", *crystals, piece="arcs")
        k.add("brass", *brass)

    colors = {
        "body": COPPER, "metal": K.METAL, "spark": SPARK, "wood": K.WOOD, "dark": K.DARK,
        "porcelain": PORCELAIN, "cable": (40, 40, 42), "brass": K.BRASS, "glow": GLOW,
    }
    return k.model("11d", colors, "COIL", stage)
