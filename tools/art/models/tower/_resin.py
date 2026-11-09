"""RESIN - Amber Resin Cannon (TowerLook amber; a 4x tower): a field cannon on a spoked-wheel
carriage, an amber-glass resin reservoir on its breech fed by a hose from a resin keg, a glob
of amber in the mouth. Authored from the base (y 0) in Roblox studs; front = -Z (_kit
conventions). Premium: the carriage, reservoir and keg are there from stage 0.

Stage 0 (tiers 0-2): spoked wheels, carriage cheeks and split trail, the barrel (steel bands,
                     muzzle swell; the muzzle ring), the amber reservoir, the keg and hose,
                     the amber glob, drips.
Stage 1 (tier 3):    a BIG AMBER TANK - the sphere becomes a tall amber-glass tank in a steel frame
                     on the breech, a heavier barrel, a riveted gun shield, a big resin vat at
                     the back-left with a fat hose.
Stage 2 (tier 5):    a SECOND BARREL - twin cannons side by side, each with its amber glob; the
                     tank glows inside a brass cage, crowned by a brass dome and a glowing amber
                     crystal spire; brass hubs, bands, shield rim and a pressure gauge.
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
GLOW_HOT = (255, 160, 40)  # the upgrades' glow: deeper amber, apart from the brass
GUN = (64, 68, 74)

AX_Y, AX_Z, WR = 0.64, 0.05, 0.62  # axle height, axle z, wheel radius
BREECH, MOUTH = (0.0, 1.12, 0.5), (0.0, 1.78, -1.22)


def wheel(sx, stage):
    """A spoked wheel at x = sx * 1.2, axle along x (the upgrades: fewer, plainer facets)."""
    x = sx * 1.2
    lean = stage >= 1
    rim = K.ring((x, AX_Y, AX_Z), WR - 0.06, 0.075 if not lean else 0.085, 16 if lean else 18, 3 if lean else 4, rot=(0, 0, 90))
    ns = 6 if lean else 8
    spokes = [K.rod((x, AX_Y, AX_Z), (x, AX_Y + math.sin(a) * (WR - 0.08), AX_Z + math.cos(a) * (WR - 0.08)), 0.035 if not lean else 0.045, 5)
              for a in (i * 2 * math.pi / ns for i in range(ns))]
    hub = K.cyl((x, AX_Y, AX_Z), 0.13 if not lean else 0.15, 0.22, 10, rot=(0, 0, 90), bevel=0 if lean else 0.03)
    return rim, spokes, hub


def build(lp, stage):
    if stage == 0:
        return build0(lp)
    k = K.Kit(lp)
    hot = stage >= 2
    trim = "brass" if hot else "metal"

    # wheels, axle, carriage cheeks, split trail
    hubs = []
    for sx in (-1, 1):
        rim, spokes, hub = wheel(sx, stage)
        k.add("dark", rim)
        k.add("wood", *spokes)
        hubs.append(hub)
    k.add(trim, *hubs, piece="hubs")
    k.add("metal", K.rod((-1.12, AX_Y, AX_Z), (1.12, AX_Y, AX_Z), 0.06, 6))
    k.add("wood", *[K.bar((sx * 0.48, AX_Y + 0.15, -0.45), (sx * 0.48, AX_Y + 0.5, 0.7), 0.14, 0.5, bevel=0) for sx in (-1, 1)])
    k.add("wood", *[K.bar((sx * 0.42, AX_Y + 0.05, 0.5), (sx * 0.22, 0.1, 1.38), 0.16, 0.18, bevel=0) for sx in (-1, 1)])
    k.add("metal", K.rbox((0, 0.12, 1.36), (0.6, 0.08, 0.16), bevel=0))  # trail spade

    # the barrel(s): one heavier barrel, or twin barrels at stage 2
    xs = (0.0,) if stage == 1 else (-0.27, 0.27)
    br = 0.34 if stage == 1 else 0.25
    muzzles, globs = [], []
    for x in xs:
        breech, mouth = (x, BREECH[1], BREECH[2]), (x, MOUTH[1], MOUTH[2])
        k.add("gun", K.rod(breech, mouth, br, 12, top=0.82), K.ell(breech, (br, br, br), 10, 5))
        swell = K.along(breech, mouth, 0.94)
        k.add("gun", K.rod(swell, mouth, br, 12, top=1.05))
        k.add(trim, *[K.ring_along(K.along(breech, mouth, t), mouth, br - 0.07 * t + 0.02, 0.045, 12, 3) for t in (0.18, 0.55)]
              + ([K.ring_along(swell, mouth, br + 0.01, 0.045, 12, 3)] if not hot else []), piece="bands")
        d = [m - b for m, b in zip(mouth, breech)]
        n = math.sqrt(sum(c * c for c in d))
        d = [c / n for c in d]
        muzzles.append(K.ring_along(mouth, tuple(m + c for m, c in zip(mouth, d)), br * 0.8, 0.05, 12, 3))
        globs += [K.ell(tuple(m + c * 0.04 for m, c in zip(mouth, d)), (br * 0.7,) * 3, 10 if not hot else 8, 5 if not hot else 4),
                  K.ell((x, mouth[1] - 0.3, mouth[2] + 0.08), (0.06, 0.12, 0.06), 6, 3)]
    k.add("metal", K.rod((-0.56, AX_Y + 0.5, 0.15), (0.56, AX_Y + 0.5, 0.15), 0.08, 8))  # trunnion bar
    k.add("dark", *muzzles, piece="muzzle", role="muzzle")
    k.add("glow" if hot else "body", *globs, piece="glob")

    # the big amber tank on the breech, in a frame of four posts with top and bottom rings
    tc = (0.0, BREECH[1] + 0.32, BREECH[2] + 0.05)  # tank bottom centre
    tr, th = (0.44, 0.95) if stage == 1 else (0.5, 1.05)
    k.add("metal", K.cyl(tc, tr + 0.06, 0.14, 12, bevel=0))  # base collar
    k.add("glow" if hot else "body", K.cyl((tc[0], tc[1] + 0.07 + th / 2, tc[2]), tr, th, 14, bevel=0.08), piece="tank")
    frame = [K.rod((math.cos(a) * (tr + 0.04), tc[1], tc[2] + math.sin(a) * (tr + 0.04)),
                   (math.cos(a) * (tr + 0.04), tc[1] + th + 0.12, tc[2] + math.sin(a) * (tr + 0.04)), 0.045, 5)
             for a in (0.785, 2.356, 3.927, 5.498)]
    frame += [K.ring((tc[0], tc[1] + y, tc[2]), tr + 0.04, 0.04, 14, 3) for y in ((0.4, th + 0.1) if not hot else (0.35, 0.75, th + 0.1))]
    k.add(trim, *frame, piece="frame")
    top = tc[1] + th + 0.14
    if not hot:
        k.add("metal", K.cyl((tc[0], top, tc[2]), tr * 0.8, 0.1, 12, bevel=0), K.cyl((tc[0], top + 0.1, tc[2]), 0.1, 0.12, 8, bevel=0))
    else:  # the crown: a brass dome and a glowing amber crystal spire
        k.add("brass", K.ell((tc[0], top, tc[2]), (tr * 0.92, 0.26, tr * 0.92), 12, 4),
              K.cyl((tc[0], top + 0.27, tc[2]), 0.16, 0.12, 8, bevel=0))
        spire = [K.rod((0, top + 0.3, tc[2]), (0, top + 1.05, tc[2]), 0.16, 6, top=0.1)]
        spire += [K.rod((sx * 0.1, top + 0.3, tc[2] + sz * 0.06), (sx * 0.32, top + 0.75, tc[2] + sz * 0.18), 0.08, 5, top=0.15)
                  for sx, sz in ((-1, 1), (1, -1), (0.4, 1.4))]
        k.add("glow", *spire, piece="spire")

    # the resin vat at the back-left, a fat hose up to the tank
    kx, kz, kr = -0.92, 0.95, 0.42
    k.add("wood", K.cyl((kx, 0.45, kz), kr, 0.9, 12, top=0.9, bevel=0))
    k.add(trim, *[K.ring((kx, y, kz), kr - (y - 0.1) * 0.07 + 0.01, 0.035, 12, 3) for y in (0.16, 0.78)])
    k.add("body", K.ell((kx, 0.9, kz), (kr * 0.85, 0.06, kr * 0.85), 10, 3),
          *[K.ell((kx + kr * math.cos(a), 0.74 - 0.12 * i, kz + kr * math.sin(a)), (0.06, 0.13, 0.06), 6, 3)
            for i, a in enumerate((-0.9, -0.2, 0.6))])  # brim and drips
    k.add("hose", K.rod((kx, 0.92, kz), (-0.7, 1.55, 0.75), 0.08, 6), K.rod((-0.7, 1.55, 0.75), (-0.3, tc[1] + 0.5, tc[2] + 0.25), 0.08, 6))

    # a riveted gun shield in front of the cheeks, a slot for the barrel(s)
    for sx in (-1, 1):
        k.add("metal", K.rbox((sx * 0.72, AX_Y + 0.55, -0.6), (0.66, 0.95, 0.07), bevel=0, rot=(-8, sx * -12, 0)))
        if not hot:
            k.add("dark", *[K.ell((sx * 0.72 + dx, AX_Y + 0.55 + dy, -0.66), (0.035, 0.035, 0.02), 4, 3) for dx, dy in ((-0.22, 0.32), (0.22, -0.32))])
        else:  # brass rim along the shield's top
            k.add("brass", K.rbox((sx * 0.72, AX_Y + 1.03, -0.57), (0.7, 0.07, 0.11), bevel=0, rot=(-8, sx * -12, 0)))

    if hot:  # a brass pressure gauge on the tank's collar
        k.add("brass", K.rod((0.4, tc[1] + 0.05, tc[2] - 0.2), (0.62, tc[1] + 0.2, tc[2] - 0.3), 0.03, 5),
              K.cyl((0.66, tc[1] + 0.22, tc[2] - 0.32), 0.12, 0.05, 10, rot=(90, 0, 0), bevel=0))
        k.add("dark", K.cyl((0.66, tc[1] + 0.22, tc[2] - 0.35), 0.09, 0.02, 10, rot=(90, 0, 0), bevel=0))

    colors = {
        "body": AMBER, "deep": AMBER_DEEP, "gun": GUN, "metal": K.METAL, "dark": K.DARK, "wood": K.WOOD,
        "hose": (58, 46, 36), "brass": K.BRASS, "glow": GLOW_HOT,
    }
    return k.model("11d", colors, "RESIN", stage)


def build0(lp):
    """Stage 0 (tiers 0-2)."""
    stage = 0
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

    colors = {
        "body": AMBER, "deep": AMBER_DEEP, "gun": GUN, "metal": K.METAL, "dark": K.DARK, "wood": K.WOOD,
        "hose": (58, 46, 36), "brass": K.BRASS, "glow": GLOW,
    }
    return k.model("11d", colors, "RESIN", stage)
