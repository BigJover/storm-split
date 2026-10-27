"""CHILLER - Tranq Station (TowerLook tranquilizer teal): a teal tranq tank lying on a wooden
cradle, a rack of darts with glowing tips on top and a dart launcher pipe out of the front.
Authored from the base (y 0) in Roblox studs; front = -Z (_kit conventions).

Stage 0 (tiers 0-2): tank with steel bands and domed ends, cradle, a glowing vial window,
                     three darts in the rack, the launcher pipe.
Stage 1 (tier 3):    five darts, a canvas cover strapped over the tank's back, a hand pump,
                     a coil of hose, a crate of spare darts.
Stage 2 (tier 5):    brass bands and fittings, a brass pressure gauge and valve wheel, a rack
                     of glowing vials, ice crystals frosting the base.
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


def build(lp, stage):
    k = K.Kit(lp)
    band_group = []

    # the tank (along x) with domed ends
    k.add("body", K.rod((-TL / 2, TY, TZ), (TL / 2, TY, TZ), TR, 16),
          *[K.ell((sx * TL / 2, TY, TZ), (0.2, TR, TR), 16, 8) for sx in (-1, 1)])
    band_group += [K.ring_along((sx * 0.7, TY, TZ), (sx * 0.7 + 1, TY, TZ), TR, 0.06, 16, 5) for sx in (-1, 1)]

    # wooden cradle: two saddles on two skids
    k.add("wood", *[K.rbox((sx * 0.7, 0.33, TZ), (0.32, 0.5, 1.5), bevel=0.06) for sx in (-1, 1)],
          *[K.rbox((0, 0.07, TZ + sz * 0.62), (2.7, 0.14, 0.24), bevel=0.05) for sz in (-1, 1)])

    # a vial window on the tank's front, glowing teal
    front = TZ - TR
    k.add("glow", K.rbox((0.5, TY + 0.05, front + 0.02), (0.55, 0.36, 0.08), bevel=0.04))
    k.add("dark", K.rbox((0.5, TY + 0.05, front + 0.05), (0.66, 0.47, 0.06), bevel=0.04))

    # dart rack on top
    rack_y = TY + TR + 0.05
    k.add("dark", K.rbox((0, rack_y, TZ - 0.1), (2.0, 0.14, 0.3), bevel=0.04))
    xs = (-0.6, 0.0, 0.6) if stage == 0 else (-0.8, -0.4, 0.0, 0.4, 0.8)
    shafts, tips, fl = [], [], []
    for x in xs:
        z = TZ - 0.1
        shafts.append(K.rod((x, rack_y - 0.05, z), (x, rack_y + 1.05, z), 0.045, 6))
        tips.append(K.rod((x, rack_y + 1.0, z), (x, rack_y + 1.32, z), 0.08, 8, top=0.1))
        fl += [K.rbox((x, rack_y + 0.22, z), (0.34, 0.24, 0.03), bevel=0.01, taper=(0.4, 1.0)),
               K.rbox((x, rack_y + 0.22, z), (0.03, 0.24, 0.34), bevel=0.01, taper=(1.0, 0.4))]
    k.add("wood", *shafts)
    k.add("glow", *tips)
    k.add("fletch", *fl)

    # the dart launcher: a pipe out of the tank's front; its mouth is the firing point
    a, b = (-0.45, TY - 0.15, front + 0.05), (-0.45, TY - 0.05, -1.4)
    k.add("metal", K.rod(a, b, 0.11, 10), K.cyl((a[0], a[1], front + 0.02), 0.18, 0.12, 10, rot=(90, 0, 0)))
    k.add("dark", K.ring_along(b, K.along(b, a, -1), 0.11, 0.035, 10, 4), piece="muzzle", role="muzzle")

    brass = []
    if stage >= 1:
        # canvas cover strapped over the tank's back half
        k.add("canvas", K.ell((0, TY + 0.05, TZ + 0.22), (TL / 2 + 0.08, TR + 0.06, TR * 0.85), 16, 8))
        # hand pump at the left end
        k.add("metal", K.rbox((-1.15, 0.35, -0.9), (0.35, 0.5, 0.35), bevel=0.06),
              K.rod((-1.15, 0.6, -0.9), (-1.15, 1.25, -0.9), 0.04, 6),
              K.rod((-1.32, 1.25, -0.9), (-0.98, 1.25, -0.9), 0.04, 6))
        # a coil of hose lying in front, a crate of spare darts at the front-right
        k.add("dark", K.ring((-0.2, 0.08, -1.0), 0.28, 0.07, 14, 5),
              K.rod((-0.48, 0.08, -1.0), (-1.0, 0.3, -0.9), 0.05, 6))
        k.add("wood", K.rbox((0.85, 0.22, -1.05), (0.7, 0.44, 0.5), bevel=0.05))
        k.add("fletch", *[K.rod((0.65 + 0.13 * i, 0.4, -1.05), (0.65 + 0.13 * i, 0.72, -1.05), 0.03, 5) for i in range(4)])

    if stage >= 2:
        brass += band_group
        band_group = []
        # brass pressure gauge on top-left, a valve wheel at the right end
        brass += [K.cyl((-0.85, rack_y + 0.12, TZ + 0.3), 0.2, 0.08, 12, rot=(90, 0, 0)),
                  K.rod((-0.85, rack_y - 0.05, TZ + 0.3), (-0.85, rack_y + 0.05, TZ + 0.3), 0.05, 6),
                  K.ring((TL / 2 + 0.12, TY + 0.2, TZ), 0.22, 0.04, 12, 4, rot=(0, 0, 90)),
                  K.cyl((-0.45, TY - 0.13, front - 0.15), 0.14, 0.1, 10, rot=(90, 0, 0))]
        k.add("glass", K.cyl((-0.85, rack_y + 0.12, TZ + 0.255), 0.15, 0.02, 12, rot=(90, 0, 0), bevel=0))
        # a rack of glowing vials behind the crate
        k.add("dark", K.rbox((0.85, 0.5, -0.68), (0.7, 0.08, 0.16), bevel=0.02))
        k.add("glow", *[K.rod((0.62 + 0.15 * i, 0.55, -0.68), (0.62 + 0.15 * i, 0.82, -0.68), 0.045, 6) for i in range(4)])
        # ice crystals frosting the base
        ice = []
        for x, z, h, lean in ((-1.3, 0.9, 0.55, 0.15), (-1.1, 1.15, 0.4, -0.1), (1.3, -0.4, 0.5, 0.12),
                              (1.1, 0.95, 0.35, 0.1), (-0.95, -1.25, 0.45, -0.12)):
            ice.append(K.rod((x, 0.06, z), (x + lean, h, z + lean * 0.5), 0.13, 5, top=0.05))
        k.add("ice", *ice)
    if band_group:
        k.add("metal", *band_group)
    if brass:
        k.add("brass", *brass)

    colors = {
        "body": TEAL, "wood": K.WOOD, "dark": (50, 54, 58), "metal": K.METAL, "glow": TIP,
        "fletch": FLETCH, "canvas": K.CANVAS, "brass": K.BRASS, "glass": (235, 240, 235), "ice": ICE,
    }
    return k.model("11d", colors, "CHILLER", stage)
