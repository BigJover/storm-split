"""CHILLER - Tranq Station (TowerLook tranquilizer teal): a teal tranq tank lying on a wooden
cradle, a rack of darts with glowing tips on top and a dart launcher pipe out of the front.
Authored from the base (y 0) in Roblox studs; front = -Z (_kit conventions).

Stage 0 (tiers 0-2): tank with steel bands and domed ends, cradle, a glowing vial window,
                     three darts in the rack, the launcher pipe.
Stage 1 (tier 3):    a second tank stacked on top (saddles, steel bands, a feed pipe) carrying
                     the dart rack with five darts, twin launcher pipes.
Stage 2 (tier 5):    a cluster of big glowing ice crystals growing out of the upper tank in a
                     brass collar (the crown), brass bands and fittings, a brass gauge and
                     valve wheel, ice crystals frosting the base.
"""

import importlib.util
from pathlib import Path

_spec = importlib.util.spec_from_file_location("_kit", Path(__file__).with_name("_kit.py"))
K = importlib.util.module_from_spec(_spec)
_spec.loader.exec_module(K)

TEAL = (70, 190, 180)  # TowerLook.COLORS.CHILLER
TIP = (60, 210, 190)  # TowerLook DART_TIP
FLETCH = (230, 225, 210)
ICE = (190, 232, 240)

TY, TZ, TR, TL = 1.05, 0.2, 0.8, 2.3  # tank: axis height, axis z, radius, length (along x)


UR, UL = 0.52, 1.9  # stage 1+: the upper tank's radius and length
UY = TY + TR + 0.14 + UR  # its axis height (it rests on two saddles on the lower tank)


def darts(k, xs, base_y, z, bev=0.01):
    shafts, tips, fl = [], [], []
    for x in xs:
        shafts.append(K.rod((x, base_y - 0.05, z), (x, base_y + 1.05, z), 0.045, 6))
        tips.append(K.rod((x, base_y + 1.0, z), (x, base_y + 1.32, z), 0.08, 8, top=0.1))
        fl += [K.rbox((x, base_y + 0.22, z), (0.34, 0.24, 0.03), bevel=bev, taper=(0.4, 1.0)),
               K.rbox((x, base_y + 0.22, z), (0.03, 0.24, 0.34), bevel=bev, taper=(1.0, 0.4))]
    k.add("wood", *shafts)
    k.add("glow", *tips)
    k.add("fletch", *fl)


def build(lp, stage):
    k = K.Kit(lp)
    band_group = []

    # the tank (along x) with domed ends
    k.add("body", K.rod((-TL / 2, TY, TZ), (TL / 2, TY, TZ), TR, 16),
          *[K.ell((sx * TL / 2, TY, TZ), (0.2, TR, TR), 16, 8) for sx in (-1, 1)])
    seg = (16, 5) if stage < 2 else (14, 3)  # (stage 2's brass bands: lighter)
    band_group += [K.ring_along((sx * 0.7, TY, TZ), (sx * 0.7 + 1, TY, TZ), TR, 0.06, *seg) for sx in (-1, 1)]

    # wooden cradle: two saddles on two skids
    k.add("wood", *[K.rbox((sx * 0.7, 0.33, TZ), (0.32, 0.5, 1.5), bevel=0.06) for sx in (-1, 1)],
          *[K.rbox((0, 0.07, TZ + sz * 0.62), (2.7, 0.14, 0.24), bevel=0.05) for sz in (-1, 1)])

    # a vial window on the tank's front, glowing teal
    front = TZ - TR
    k.add("glow", K.rbox((0.5, TY + 0.05, front + 0.02), (0.55, 0.36, 0.08), bevel=0.04))
    k.add("dark", K.rbox((0.5, TY + 0.05, front + 0.05), (0.66, 0.47, 0.06), bevel=0.04))

    if stage == 0:
        # dart rack on top
        rack_y = TY + TR + 0.05
        k.add("dark", K.rbox((0, rack_y, TZ - 0.1), (2.0, 0.14, 0.3), bevel=0.04))
        darts(k, (-0.6, 0.0, 0.6), rack_y, TZ - 0.1)
    else:
        # a second, smaller tank stacked on top on two saddles, banded; the dart rack on it
        k.add("body", K.rod((-UL / 2, UY, TZ), (UL / 2, UY, TZ), UR, 12),
              *[K.ell((sx * UL / 2, UY, TZ), (0.14, UR, UR), 10, 5) for sx in (-1, 1)])
        k.add("wood", *[K.rbox((sx * 0.55, TY + TR + 0.1, TZ), (0.26, 0.3, 0.9), bevel=0.05) for sx in (-1, 1)])
        band_group += [K.ring_along((sx * 0.55, UY, TZ), (sx * 0.55 + 1, UY, TZ), UR, 0.05, 10, 3) for sx in (-1, 1)]
        rack_y = UY + UR + 0.04
        k.add("dark", K.rbox((0, rack_y, TZ - 0.05), (1.9, 0.14, 0.3), bevel=0.04))
        darts(k, (-0.8, -0.4, 0.0, 0.4, 0.8) if stage == 1 else (-0.85, -0.55, 0.55, 0.85), rack_y, TZ - 0.05, bev=0)
        # a feed pipe from the upper tank down into the lower one
        k.add("metal", K.rod((-UL / 2 - 0.02, UY - 0.1, TZ - 0.25), (-TL / 2 + 0.1, TY + 0.3, TZ - 0.45), 0.07, 6))

    # the dart launcher: a pipe out of the tank's front (stage 1+: twin pipes); the first
    # one's mouth is the firing point
    pipes = [-0.45] if stage == 0 else [-0.45, -0.05]
    for i, x in enumerate(pipes):
        a, b = (x, TY - 0.15, front + 0.05), (x, TY - 0.05, -1.4)
        r = 0.11 if stage == 0 else 0.13
        k.add("metal", K.rod(a, b, r, 10), K.cyl((a[0], a[1], front + 0.02), r + 0.07, 0.12, 10, rot=(90, 0, 0)))
        ring = K.ring_along(b, K.along(b, a, -1), r, 0.035, 10, 4)
        if i == 0:
            k.add("dark", ring, piece="muzzle", role="muzzle")
        else:
            k.add("dark", ring)

    brass = []
    if stage >= 2:
        brass += band_group
        band_group = []
        # the crown: a cluster of big glowing ice crystals growing out of the upper tank
        cy = UY + UR - 0.05
        k.add("glow", K.rod((0, cy, TZ - 0.05), (0.0, 4.95, TZ - 0.05), 0.32, 6, top=0.06),
              K.rod((0.05, cy, TZ - 0.05), (-0.4, 4.25, TZ - 0.25), 0.22, 6, top=0.08),
              K.rod((0.0, cy, TZ - 0.05), (0.4, 4.15, TZ + 0.15), 0.21, 6, top=0.08),
              K.rod((0.0, cy, TZ), (0.08, 3.9, TZ + 0.45), 0.17, 5, top=0.1),
              K.rod((0.0, cy, TZ - 0.1), (-0.05, 3.8, TZ - 0.55), 0.16, 5, top=0.1), piece="crystal")
        brass.append(K.cyl((0, cy, TZ - 0.05), 0.44, 0.16, 10, bevel=0.03))  # its brass collar
        # brass pressure gauge on the lower tank's top-left, a valve wheel at the right end
        brass += [K.cyl((-1.0, TY + TR + 0.12, TZ - 0.3), 0.2, 0.08, 10, rot=(90, 0, 0)),
                  K.ring((TL / 2 + 0.12, TY + 0.2, TZ), 0.22, 0.04, 10, 3, rot=(0, 0, 90))]
        # ice crystals frosting the base
        ice = []
        for x, z, h, lean in ((-1.3, 0.9, 0.75, 0.15), (-1.1, 1.15, 0.5, -0.1), (1.3, -0.4, 0.7, 0.12),
                              (-0.95, -1.25, 0.6, -0.12), (0.9, -1.2, 0.5, 0.1)):
            ice.append(K.rod((x, 0.06, z), (x + lean, h, z + lean * 0.5), 0.15, 5, top=0.05))
        k.add("ice", *ice)
    if band_group:
        k.add("metal", *band_group)
    if brass:
        k.add("brass", *brass)

    colors = {
        "body": TEAL, "wood": K.WOOD, "dark": (50, 54, 58), "metal": K.METAL, "glow": TIP,
        "fletch": FLETCH, "canvas": K.CANVAS, "brass": K.BRASS, "glass": (235, 240, 235), "ice": ICE,
    }
    if stage >= 2:
        colors["glow"] = (150, 236, 255)  # the tier-5 frost: icy white-blue glow (tips and crystals)
    return k.model("11d", colors, "CHILLER", stage)
