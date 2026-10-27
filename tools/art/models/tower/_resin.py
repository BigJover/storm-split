"""RESIN - Amber Resin Cannon (TowerLook amber; a 4x tower): a field cannon on a spoked-wheel
carriage, an amber-glass resin reservoir on its breech fed by a hose from a resin keg, a glob
of amber in the mouth. Authored from the base (y 0) in Roblox studs; front = -Z (_kit
conventions). Premium: the carriage, reservoir and keg are there from stage 0.

Stage 0 (tiers 0-2): spoked wheels, carriage cheeks and split trail, the barrel (steel bands,
                     muzzle swell; the muzzle ring), the amber reservoir, the keg and hose,
                     the amber glob, drips.
Stage 1 (tier 3):    a riveted gun shield, a rack of amber shot, amber crystal clusters, a
                     second keg on the trail.
Stage 2 (tier 5):    brass bands, hubs and reservoir cage, a brass pressure gauge, the
                     reservoir and glob glowing.
"""

import importlib.util
import math
from pathlib import Path

_spec = importlib.util.spec_from_file_location("_kit", Path(__file__).with_name("_kit.py"))
K = importlib.util.module_from_spec(_spec)
_spec.loader.exec_module(K)

AMBER = (240, 150, 40)  # TowerLook.COLORS.RESIN
AMBER_DEEP = (196, 104, 24)
GLOW = (255, 214, 110)
GUN = (64, 68, 74)

AX_Y, AX_Z, WR = 0.64, 0.05, 0.62  # axle height, axle z, wheel radius
BREECH, MOUTH = (0.0, 1.12, 0.5), (0.0, 1.78, -1.22)


def wheel(sx, stage):
    """A spoked wheel at x = sx * 1.2, axle along x."""
    x = sx * 1.2
    rim = K.ring((x, AX_Y, AX_Z), WR - 0.06, 0.075, 18, 4, rot=(0, 0, 90))
    spokes = [K.rod((x, AX_Y, AX_Z), (x, AX_Y + math.sin(a) * (WR - 0.08), AX_Z + math.cos(a) * (WR - 0.08)), 0.035, 5)
              for a in (i * math.pi / 4 for i in range(8))]
    hub = K.cyl((x, AX_Y, AX_Z), 0.13, 0.22, 10, rot=(0, 0, 90))
    return rim, spokes, hub


def build(lp, stage):
    k = K.Kit(lp)
    hot = stage >= 2

    # wheels, axle, carriage cheeks, split trail
    hubs = []
    for sx in (-1, 1):
        rim, spokes, hub = wheel(sx, stage)
        k.add("dark", rim)
        k.add("wood", *spokes)
        hubs.append(hub)
    k.add("brass" if hot else "metal", *hubs, piece="hubs")
    k.add("metal", K.rod((-1.12, AX_Y, AX_Z), (1.12, AX_Y, AX_Z), 0.06, 8))
    k.add("wood", *[K.bar((sx * 0.36, AX_Y + 0.15, -0.45), (sx * 0.36, AX_Y + 0.5, 0.7), 0.14, 0.5, bevel=0.05) for sx in (-1, 1)])
    k.add("wood", *[K.bar((sx * 0.32, AX_Y + 0.05, 0.5), (sx * 0.22, 0.1, 1.38), 0.16, 0.18, bevel=0.05) for sx in (-1, 1)])
    k.add("metal", K.rbox((0, 0.12, 1.36), (0.6, 0.08, 0.16), bevel=0.03))  # trail spade

    # the barrel: steel with bands and a muzzle swell; trunnions on the cheeks
    k.add("gun", K.rod(BREECH, MOUTH, 0.3, 14, top=0.82),
          K.ell(BREECH, (0.3, 0.3, 0.3), 12, 6), K.ell(K.along(BREECH, MOUTH, -0.12), (0.1, 0.1, 0.1), 8, 4))
    swell = K.along(BREECH, MOUTH, 0.94)
    k.add("gun", K.rod(swell, MOUTH, 0.3, 14, top=1.05))
    bands = [K.ring_along(K.along(BREECH, MOUTH, t), MOUTH, 0.3 - 0.06 * t + 0.02, 0.04, 14, 4) for t in (0.18, 0.55)]
    k.add("brass" if hot else "metal", *bands, piece="bands")
    k.add("metal", K.rod((-0.42, AX_Y + 0.5, 0.15), (0.42, AX_Y + 0.5, 0.15), 0.08, 8))
    d = [m - b for m, b in zip(MOUTH, BREECH)]
    n = math.sqrt(sum(c * c for c in d))
    d = [c / n for c in d]
    k.add("dark", K.ring_along(MOUTH, tuple(m + c for m, c in zip(MOUTH, d)), 0.24, 0.05, 12, 4), piece="muzzle", role="muzzle")
    # the amber glob bulging out of the mouth; drips down the barrel
    glob = K.ell(tuple(m + c * 0.04 for m, c in zip(MOUTH, d)), (0.21, 0.21, 0.21), 10, 6)
    drips = [K.ell((0.0, MOUTH[1] - 0.3, MOUTH[2] + 0.08), (0.06, 0.12, 0.06), 6, 4)]
    k.add("glow" if hot else "body", glob, *drips, piece="glob")

    # the reservoir: an amber-glass sphere in a collar on the breech
    rc = (0.0, BREECH[1] + 0.52, BREECH[2] - 0.05)
    k.add("glow" if hot else "body", K.ell(rc, (0.3, 0.3, 0.3), 12, 7), piece="reservoir")
    k.add("metal", K.cyl((rc[0], rc[1] - 0.27, rc[2]), 0.2, 0.12, 10), K.cyl((rc[0], rc[1] + 0.3, rc[2]), 0.1, 0.08, 8))
    if hot:  # a brass cage round the glass
        k.add("brass", *[K.rod((math.cos(a) * 0.05, rc[1] - 0.26, rc[2] + math.sin(a) * 0.05),
                               (math.cos(a) * 0.31, rc[1], rc[2] + math.sin(a) * 0.31), 0.025, 5) for a in (0.6, 2.2, 3.8, 5.4)],
              *[K.rod((math.cos(a) * 0.31, rc[1], rc[2] + math.sin(a) * 0.31),
                      (math.cos(a) * 0.05, rc[1] + 0.27, rc[2] + math.sin(a) * 0.05), 0.025, 5) for a in (0.6, 2.2, 3.8, 5.4)],
              K.ring(rc, 0.31, 0.03, 14, 4))

    # the resin keg at the back-left, a hose up to the reservoir
    kx, kz = -0.85, 0.95
    k.add("wood", K.cyl((kx, 0.38, kz), (0.3, 0.3), 0.72, 12, top=0.9, bevel=0.05))
    k.add("metal", *[K.ring((kx, y, kz), 0.3 - (y - 0.1) * 0.06, 0.03, 12, 3) for y in (0.14, 0.62)])
    k.add("body", K.ell((kx, 0.74, kz), (0.24, 0.05, 0.24), 10, 3),
          *[K.ell((kx + 0.29 * math.cos(a), 0.6 - 0.12 * i, kz + 0.29 * math.sin(a)), (0.05, 0.11, 0.05), 6, 4)
            for i, a in enumerate((-0.9, -0.2, 0.6))])  # brim and drips
    k.add("hose", K.rod((kx, 0.76, kz), (-0.55, 1.3, 0.75), 0.05, 6), K.rod((-0.55, 1.3, 0.75), (rc[0] - 0.12, rc[1] - 0.05, rc[2] + 0.22), 0.05, 6))

    brass = []
    if stage >= 1:
        # a riveted gun shield in front of the cheeks, a slot for the barrel
        for sx in (-1, 1):
            k.add("metal", K.rbox((sx * 0.6, AX_Y + 0.5, -0.55), (0.62, 0.8, 0.06), bevel=0.03, rot=(-8, sx * -12, 0)))
            k.add("dark", *[K.ell((sx * 0.6 + dx, AX_Y + 0.5 + dy, -0.6), (0.03, 0.03, 0.02), 4, 3) for dx in (-0.22, 0.22) for dy in (-0.3, 0.3)])
        # a rack of amber shot at the front-right, crystal clusters at the front-left
        k.add("wood", K.rbox((0.95, 0.12, -1.1), (0.55, 0.12, 0.4), bevel=0.04))
        k.add("body", *[K.ell((0.95 + dx, 0.3, -1.1 + dz), (0.11, 0.11, 0.11), 8, 5) for dx in (-0.15, 0.15) for dz in (-0.09, 0.09)],
              K.ell((0.95, 0.47, -1.1), (0.11, 0.11, 0.11), 8, 5), piece="shot")
        crystals = [K.rod((-0.95 + dx, 0.06, -1.1 + dz), (-0.95 + dx * 2.2, h, -1.1 + dz * 2.2), 0.08, 6, top=0.15)
                    for dx, dz, h in ((0.0, 0.0, 0.55), (0.12, 0.08, 0.38), (-0.1, 0.1, 0.32), (0.06, -0.12, 0.3))]
        k.add("deep", *crystals)
        # a second, small keg on the trail
        k.add("wood", K.cyl((0.0, 0.5, 1.12), 0.18, 0.36, 10, rot=(0, 0, 90)))
        k.add("metal", *[K.ring_along((dx, 0.5, 1.12), (dx + 1, 0.5, 1.12), 0.18, 0.025, 10, 3) for dx in (-0.12, 0.12)])

    if stage >= 2:
        # a brass pressure gauge on the reservoir collar
        brass += [K.rod((0.12, rc[1] - 0.25, rc[2]), (0.32, rc[1] - 0.15, rc[2]), 0.025, 6),
                  K.cyl((0.36, rc[1] - 0.12, rc[2]), 0.1, 0.05, 10, rot=(0, 0, 90))]
        k.add("dark", K.cyl((0.39, rc[1] - 0.12, rc[2]), 0.075, 0.02, 10, rot=(0, 0, 90)))
        brass.append(K.ring_along(swell, MOUTH, 0.31, 0.04, 14, 4))
        k.add("brass", *brass)

    colors = {
        "body": AMBER, "deep": AMBER_DEEP, "gun": GUN, "metal": K.METAL, "dark": K.DARK, "wood": K.WOOD,
        "hose": (58, 46, 36), "brass": K.BRASS, "glow": GLOW,
    }
    return k.model("11d", colors, "RESIN", stage)
