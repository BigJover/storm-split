"""COIL - Storm Coil (TowerLook copper): a copper coil wound up a steel column on a splayed
tripod, a steel storm-ring and a spark ball on top where the lightning leaves. Authored from the
base (y 0) in Roblox studs; front = -Z (_kit conventions).

Stage 0 (tiers 0-2): plank pad, tripod with insulator feet, the coil (copper rings), the
                     storm-ring, the spark ball, a cable to a battery crate.
Stage 1 (tier 3):    TWIN COILS - the main coil grows taller with a wide arcing ring (three
                     lightning rods) round it, and a second, smaller coil tower stands at the
                     back-left with its own spark ball, cabled to the hub.
Stage 2 (tier 5):    a THIRD coil at the front-right, a big glowing spark ball in a brass crown,
                     brass rings and flanges, and glowing lightning arcs jumping from both side
                     coils to the main column.
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


def side_coil(k, cx, cz, h, stage):
    """A smaller coil tower: a copper drum wound with dark bands, a toroid and a spark ball."""
    k.add("dark", K.cyl((cx, 0.1, cz), 0.38, 0.2, 8, bevel=0))
    k.add("body", K.cyl((cx, 0.2 + (h - 0.2) / 2, cz), 0.3, h - 0.2, 10, top=0.7, bevel=0))
    k.add("dark", *[K.cyl((cx, 0.6 + i * (h - 0.95) / 2, cz), 0.33 - 0.03 * i, 0.09, 10, top=0.95, bevel=0)
                    for i in range(3)])
    k.add("metal", K.ring((cx, h + 0.02, cz), 0.25, 0.08, 8, 3), K.rod((cx, h, cz), (cx, h + 0.15, cz), 0.06, 6))
    k.add("brass" if stage >= 2 else "metal", K.cyl((cx, 0.24, cz), 0.42, 0.06, 10, bevel=0))
    k.add("glow" if stage >= 2 else "spark", K.ell((cx, h + 0.3, cz), (0.21, 0.21, 0.21), 8, 5), piece="ball")
    return (cx, h + 0.3, cz)


def zigzag(a, b, n=4, amp=0.16):
    """A lightning bolt from a to b: a jagged chain of thin rods."""
    pts = [a]
    for i in range(1, n):
        t = i / n
        p = K.along(a, b, t)
        s = amp if i % 2 else -amp
        pts.append((p[0] + s * 0.6, p[1] + s, p[2] - s * 0.6))
    pts.append(b)
    return [K.rod(pts[i], pts[i + 1], 0.065, 5) for i in range(n)]


def build(lp, stage):
    k = K.Kit(lp)
    lean = stage >= 1  # the upgrades spend their triangles on big shapes: plain edges on the small base parts
    top = (3.65, 3.95, 3.8)[stage]  # top of the coil
    ball_r = (0.34, 0.34, 0.42)[stage]
    ball_y = top + 0.3 + ball_r * 0.85

    # plank pad under the tripod
    k.add("wood", *[K.rbox((x, 0.05, 0.0), (0.42, 0.1, 2.5), bevel=0 if lean else 0.03) for x in (-0.88, -0.44, 0.0, 0.44, 0.88)])
    k.add("dark", *[K.rbox((0, 0.12, z), (2.2, 0.06, 0.16), bevel=0 if lean else 0.02) for z in (-0.85, 0.85)])

    # tripod legs from the hub to insulator feet
    metal, porcelain = [], []
    for a in LEG_ANGLES:
        fx, fz = math.cos(math.radians(a)) * 1.15, math.sin(math.radians(a)) * 1.15
        metal.append(K.rod((fx, 0.22, fz), (fx * 0.22, HUB, fz * 0.22), 0.07 if stage == 0 else 0.09, 8))
        porcelain.append(K.cyl((fx, 0.17, fz), 0.16, 0.14, 8, top=0.8, bevel=0 if lean else 0.03))
    metal.append(K.cyl((0, HUB, 0), 0.42, 0.26, 12, bevel=0 if lean else 0.06))  # hub
    metal.append(K.rod((0, HUB, 0), (0, top + 0.1, 0), 0.2 if stage == 0 else 0.24, 10))  # the column
    k.add("metal", *metal)
    k.add("porcelain", *porcelain)

    # the copper coil: tight rings up the column, narrowing toward the top
    n = 8
    r0 = 0.62 if stage == 0 else 0.7
    coil = []
    for i in range(n):
        t = i / (n - 1)
        y = HUB + 0.3 + t * (top - HUB - 0.45)
        coil.append(K.ring((0, y, 0), r0 - 0.24 * t, 0.08 if stage == 0 else 0.09, 8 if lean else 10, 3 if lean else 4))
    flange = K.cyl((0, HUB + 0.2, 0), r0 + 0.08, 0.1, 12, bevel=0 if lean else 0.03)  # coil base flange
    k.add("body", *coil)
    k.add("brass" if stage >= 2 else "metal", flange)

    # storm-ring (toroid) at the top, the spark ball above it; the muzzle cap on the ball
    tor = K.ring((0, top + 0.15, 0), 0.5 if stage == 0 else 0.56, 0.15 if stage == 0 else 0.17, 14, 5 if stage == 0 else 4)
    k.add("metal", tor, K.rod((0, top + 0.1, 0), (0, ball_y - 0.2, 0), 0.08, 8))
    k.add("glow" if stage >= 2 else "spark", K.ell((0, ball_y, 0), (ball_r,) * 3, 10 if lean else 12, 6 if lean else 7), piece="ball")
    k.add("metal", K.ring((0, ball_y + ball_r - 0.01, 0), 0.1, 0.04, 8, 4), piece="muzzle", role="muzzle")

    # battery crate at the front-left, cable up to the hub
    bx, bz = -0.85, -0.75
    k.add("wood", K.rbox((bx, 0.36, bz), (0.62, 0.5, 0.48), bevel=0.05, rot=(0, 10, 0)))
    k.add("dark", *[K.rbox((bx, y, bz), (0.66, 0.07, 0.52), bevel=0.02, rot=(0, 10, 0)) for y in (0.2, 0.52)])
    k.add("metal", *[K.cyl((bx + dx, 0.66, bz), 0.07, 0.1, 8, bevel=0 if lean else 0.03) for dx in (-0.15, 0.15)])  # terminals
    cable = [K.rod((bx + 0.15, 0.7, bz), (-0.35, 0.18, -0.35), 0.035, 6),
             K.rod((-0.35, 0.18, -0.35), (-0.1, HUB - 0.05, -0.1), 0.035, 6)]

    if stage >= 1:
        # the wide arcing ring on three spokes, three lightning rods standing up from it
        ry, rr = top - 0.7, 1.12
        trim = "brass" if stage >= 2 else "metal"
        k.add(trim, K.ring((0, ry, 0), rr, 0.07, 16, 3))
        spokes, rods = [], []
        for a in (-90, 30, 150):
            ca, sa = math.cos(math.radians(a)), math.sin(math.radians(a))
            spokes.append(K.rod((ca * 0.3, ry, sa * 0.3), (ca * rr, ry, sa * rr), 0.04, 5))
            rods.append(K.rod((ca * rr, ry, sa * rr), (ca * rr * 1.06, ry + 0.95, sa * rr * 1.06), 0.06, 6, top=0.2))
        k.add("metal", *spokes, *rods)
        # the twin coil at the back-left, cabled to the hub
        sb = side_coil(k, -0.92, 0.88, 2.55 if stage == 1 else 2.85, stage)
        cable.append(K.rod((-0.92, 0.3, 0.6), (-0.15, HUB - 0.05, 0.15), 0.04, 6))
        balls = [sb]
        if stage >= 2:
            sf = side_coil(k, 0.95, -0.92, 2.5, stage)
            cable.append(K.rod((0.92, 0.3, -0.62), (0.15, HUB - 0.05, -0.15), 0.04, 6))
            balls.append(sf)
            # lightning arcs from each side coil's ball to the main column
            arcs = []
            for b in balls:
                arcs += zigzag(b, (0.0, top - 0.25, 0.0), 4, 0.17)
            # glowing tips on the three lightning rods
            for a in (-90, 30, 150):
                ca, sa = math.cos(math.radians(a)), math.sin(math.radians(a))
                arcs.append(K.ell((ca * rr * 1.06, ry + 1.0, sa * rr * 1.06), (0.1, 0.16, 0.1), 6, 4))
            k.add("glow", *arcs, piece="arcs")
            # the brass crown: a band round the column top and claws round the big ball
            brass = [K.cyl((0, top + 0.02, 0), 0.32, 0.12, 10, bevel=0)]
            brass += [K.rod((math.cos(math.radians(a)) * 0.45, top + 0.2, math.sin(math.radians(a)) * 0.45),
                            (math.cos(math.radians(a)) * 0.3, ball_y + 0.05, math.sin(math.radians(a)) * 0.3), 0.045, 6)
                      for a in (0, 90, 180, 270)]
            k.add("brass", *brass)
    k.add("cable", *cable)

    colors = {
        "body": COPPER, "metal": K.METAL, "spark": SPARK, "wood": K.WOOD, "dark": K.DARK,
        "porcelain": PORCELAIN, "cable": (40, 40, 42), "brass": K.BRASS, "glow": GLOW,
    }
    return k.model("11d", colors, "COIL", stage)
