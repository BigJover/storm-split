"""BLIMP - Spotter Blimp's mooring mast (TowerLook canvas envelope; a 4x tower): a steel lattice
mast on a diamond-plate pad, a canvas mooring cone on top, guy lines, a cable winch, hydrogen
cylinders and a windsock. The blimp itself flies (TowerLook.buildBlimp); its model is
BLIMP_AIR (_blimp_air.py). Authored from the base (y 0) in Roblox studs; front = -Z (_kit
conventions). The back-right corner (the owner flag's) has no guy line or gear.

Stage 0 (tiers 0-2): pad, footings, the lattice mast with a ladder, the mooring cone, three
                     guy lines, the winch and its cable, two hydrogen cylinders, the windsock.
Stage 1 (tier 3):    a searchlight on a mast platform, a radio crate with an aerial, a third
                     cylinder, a sandbag row along the front.
Stage 2 (tier 5):    brass bands on the mast, brass cone ring and fittings, a glowing beacon
                     on the mast top and a glowing searchlight lens.
"""

import importlib.util
import math
from pathlib import Path

_spec = importlib.util.spec_from_file_location("_kit", Path(__file__).with_name("_kit.py"))
K = importlib.util.module_from_spec(_spec)
_spec.loader.exec_module(K)

CANVAS = (205, 195, 170)  # TowerLook.COLORS.BLIMP
STEEL = (78, 84, 92)
PLATE = (118, 122, 126)
SOCK = (230, 120, 40)
GAS = (170, 60, 50)
GLOW = (255, 90, 60)

MAST_TOP = 4.25
B0, B1 = 0.48, 0.16  # lattice half width at the base / top


def half(y):
    return B0 + (B1 - B0) * (y / MAST_TOP)


def build(lp, stage):
    k = K.Kit(lp)
    hot = stage >= 2

    # diamond-plate pad with a raised rim, concrete footings under the mast legs
    k.add("plate", K.rbox((0, 0.08, 0), (2.7, 0.16, 2.7), bevel=0.06))
    k.add("metal", *[K.rbox((0, 0.17, sz * 1.3), (2.6, 0.05, 0.1), bevel=0.02) for sz in (-1, 1)],
          *[K.rbox((sx * 1.3, 0.17, 0), (0.1, 0.05, 2.6), bevel=0.02) for sx in (-1, 1)])
    k.add("dark", *[K.rbox((sx * 0.38 * dz + sx * 0.0, 0.17, 0), (0.05, 0.02, 2.4), bevel=0.0) for sx in (-1, 1) for dz in (1, 2)])  # plate tread lines
    k.add("concrete", *[K.rbox((sx * B0, 0.26, sz * B0), (0.34, 0.2, 0.34), bevel=0.05) for sx in (-1, 1) for sz in (-1, 1)])

    # the lattice mast: four legs, X braces on every face, a ladder on the front face
    legs, braces = [], []
    for sx in (-1, 1):
        for sz in (-1, 1):
            legs.append(K.rod((sx * B0, 0.3, sz * B0), (sx * B1, MAST_TOP, sz * B1), 0.06, 6))
    levels = [0.3, 1.6, 2.75, 3.7, MAST_TOP]
    for a, b in zip(levels, levels[1:]):
        ha, hb = half(a), half(b)
        for (dx, dz) in ((1, 0), (-1, 0), (0, 1), (0, -1)):
            if dx:
                p, q = (dx * ha, a, -ha), (dx * hb, b, hb)
                r, s = (dx * ha, a, ha), (dx * hb, b, -hb)
            else:
                p, q = (-ha, a, dz * ha), (hb, b, dz * hb)
                r, s = (ha, a, dz * ha), (-hb, b, dz * hb)
            braces += [K.rod(p, q, 0.025, 4), K.rod(r, s, 0.025, 4)]
        braces += [K.rod((sx * hb, b, -hb), (sx * hb, b, hb), 0.03, 4) for sx in (-1, 1)]  # level rings
        braces += [K.rod((-hb, b, sz * hb), (hb, b, sz * hb), 0.03, 4) for sz in (-1, 1)]
    k.add("steel", *legs, *braces)
    ladder = [K.rod((sx * 0.14, 0.3, -half(0.3) - 0.12), (sx * 0.12, 3.7, -half(3.7) - 0.1), 0.025, 4) for sx in (-1, 1)]
    for i in range(9):
        y = 0.6 + i * 0.36
        z = -half(y) - 0.11
        ladder.append(K.rod((-0.13, y, z), (0.13, y, z), 0.02, 4))
    k.add("metal", *ladder)

    # the mooring cone on top (canvas over a steel cup) and its cap
    k.add("steel", K.cyl((0, MAST_TOP + 0.05, 0), 0.28, 0.1, 10))
    k.add("body", K.cyl((0, MAST_TOP + 0.3, 0), 0.22, 0.4, 12, top=2.1, bevel=0.04))
    k.add("brass" if hot else "metal", K.ring((0, MAST_TOP + 0.5, 0), 0.46, 0.04, 12, 3), piece="conering")

    # guy lines from the top level to the pad (none to the back-right)
    anchors = [(-1.2, -1.2), (1.2, -1.2), (-1.2, 1.2)]
    k.add("rope", *[K.rod((ax * 0.15, 3.7, az * 0.15), (ax, 0.24, az), 0.018, 4) for ax, az in anchors])
    k.add("metal", *[K.ring((ax, 0.22, az), 0.07, 0.025, 8, 3) for ax, az in anchors])

    # cable winch at the right-front, cable up the mast to the cone
    wx, wz = 0.95, -0.55
    k.add("canvasdark", K.rbox((wx, 0.42, wz), (0.5, 0.5, 0.6), bevel=0.06))
    k.add("rope", K.cyl((wx, 0.52, wz), 0.16, 0.56, 10, rot=(90, 0, 0)))
    k.add("metal", *[K.cyl((wx, 0.52, wz + sz * 0.31), 0.22, 0.04, 10, rot=(90, 0, 0)) for sz in (-1, 1)])
    k.add("cable", K.rod((wx - 0.1, 0.62, wz), (0.12, 2.4, -0.1), 0.02, 4), K.rod((0.12, 2.4, -0.1), (0.05, MAST_TOP + 0.1, 0), 0.02, 4))

    # hydrogen cylinders at the back-left, a windsock off the mast top
    gas = [(-1.0, 0.75), (-0.7, 1.0)] + ([(-1.05, 0.35)] if stage >= 1 else [])
    k.add("gas", *[K.cyl((x, 0.62, z), 0.15, 0.85, 10, bevel=0.06) for x, z in gas],
          *[K.ell((x, 1.05, z), (0.15, 0.08, 0.15), 8, 3) for x, z in gas])
    k.add("metal", *[K.cyl((x, 1.16, z), 0.05, 0.1, 6) for x, z in gas])
    k.add("steel", K.rod((-B1, MAST_TOP - 0.15, -B1), (-0.75, MAST_TOP - 0.05, -0.2), 0.03, 4))
    sock = []
    for i in range(3):
        a, b = 0.15 + i * 0.22, 0.15 + (i + 1) * 0.22
        sock.append((K.rod((-0.75 + a * 0.3, MAST_TOP - 0.05 - a * 0.25, -0.2 + a * 0.9),
                           (-0.75 + b * 0.3, MAST_TOP - 0.05 - b * 0.25, -0.2 + b * 0.9), 0.13 - i * 0.025, 8, top=0.82), i))
    k.add("sock", *[s for s, i in sock if i % 2 == 0])
    k.add("canvas", *[s for s, i in sock if i % 2 == 1], K.ring((-0.75 + 0.15 * 0.3, MAST_TOP - 0.05 - 0.15 * 0.25, -0.2 + 0.15 * 0.9), 0.13, 0.02, 8, 3))

    brass = []
    if stage >= 1:
        # a platform with a searchlight on the mast's front
        py = 2.75
        k.add("plate", K.rbox((0, py - 0.05, -0.55), (0.75, 0.06, 0.45), bevel=0.02))
        k.add("metal", K.rod((-0.3, py - 0.05, -0.75), (-0.3, py - 0.5, -0.38), 0.025, 4), K.rod((0.3, py - 0.05, -0.75), (0.3, py - 0.5, -0.38), 0.025, 4))
        k.add("steel", K.rod((0.0, py + 0.2, -0.62), (0.0, py + 0.48, -0.95), 0.18, 10, top=1.15),
              K.rod((0.0, py, -0.62), (0.0, py + 0.2, -0.62), 0.04, 4))
        k.add("glow" if hot else "lens", K.cyl((0.0, py + 0.5, -0.97), 0.18, 0.03, 10, rot=(-50, 0, 0)), piece="lens")
        # a radio crate with an aerial at the front-left
        k.add("canvasdark", K.rbox((-0.9, 0.42, -0.8), (0.55, 0.5, 0.45), bevel=0.05))
        k.add("metal", K.rbox((-0.9, 0.5, -1.03), (0.4, 0.22, 0.03), bevel=0.01), K.rod((-1.08, 0.67, -0.75), (-1.12, 1.6, -0.75), 0.015, 4))
        k.add("dark", *[K.cyl((-0.9 + dx, 0.5, -1.05), 0.04, 0.03, 6, rot=(90, 0, 0)) for dx in (-0.1, 0.05, 0.15)])
        # sandbags along the front edge
        k.add("sand", *[K.pillow((x, 0.3, -1.25), 0.5, 0.0) for x in (-0.25, 0.25)])

    if hot:
        brass += [K.ring((0, y, 0), half(y) * 1.42, 0.035, 4, 3, rot=(0, 45, 0)) for y in (1.6, 3.7)]
        brass += [K.cyl((sx * B0, 0.4, sz * B0), 0.09, 0.08, 6) for sx in (-1, 1) for sz in (-1, 1)]
        k.add("glow", K.ell((0, MAST_TOP + 0.6, 0), (0.11, 0.13, 0.11), 8, 5), piece="beacon")
        brass.append(K.rod((0, MAST_TOP + 0.5, 0), (0, MAST_TOP + 0.55, 0), 0.08, 6))
        k.add("brass", *brass)

    colors = {
        "body": CANVAS, "canvas": (236, 232, 222), "canvasdark": (120, 112, 88), "plate": PLATE, "metal": K.METAL,
        "steel": STEEL, "dark": K.DARK, "concrete": (150, 146, 138), "rope": K.ROPE, "cable": (40, 40, 42),
        "sock": SOCK, "gas": GAS, "lens": (220, 220, 200), "sand": K.SAND, "brass": K.BRASS, "glow": GLOW,
    }
    return k.model("11d", colors, "BLIMP", stage)
