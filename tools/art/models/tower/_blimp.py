"""BLIMP - Spotter Blimp's mooring mast (TowerLook canvas envelope; a 4x tower): a steel lattice
mast on a diamond-plate pad, a canvas mooring cone on top, guy lines, a cable winch, hydrogen
cylinders and a windsock. The blimp itself flies (TowerLook.buildBlimp); its model is
BLIMP_AIR (_blimp_air.py). Authored from the base (y 0) in Roblox studs; front = -Z (_kit
conventions). The back-right corner (the owner flag's) has no guy line or gear.

Stage 0 (tiers 0-2): pad, footings, the lattice mast with a ladder, the mooring cone, three
                     guy lines, the winch and its cable, two hydrogen cylinders, the windsock.
Stage 1 (tier 3):    an OBSERVATION DECK - a wide railed octagonal deck ringing the mast halfway
                     up, a big searchlight drum on its front, the guy lines run to its rim, a
                     third gas cylinder.
Stage 2 (tier 5):    a second searchlight on the deck's back, a brass deck rail and mast bands,
                     a brass mooring cone wreathed in a big glowing beacon halo (the crown),
                     both searchlight lenses glowing.
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
DECK = 2.45  # the upgrades' observation deck
B0, B1 = 0.48, 0.16  # lattice half width at the base / top


def half(y):
    return B0 + (B1 - B0) * (y / MAST_TOP)


def build(lp, stage):
    k = K.Kit(lp)
    hot = stage >= 2
    lean = stage >= 1  # the upgrades spend their triangles on the deck: plainer base parts
    bv = 0 if lean else 1

    # diamond-plate pad with a raised rim, concrete footings under the mast legs
    k.add("plate", K.rbox((0, 0.08, 0), (2.7, 0.16, 2.7), bevel=0.06 * bv))
    k.add("metal", *[K.rbox((0, 0.17, sz * 1.3), (2.6, 0.05, 0.1), bevel=0.02 * bv) for sz in (-1, 1)],
          *[K.rbox((sx * 1.3, 0.17, 0), (0.1, 0.05, 2.6), bevel=0.02 * bv) for sx in (-1, 1)])
    k.add("dark", *[K.rbox((sx * 0.38 * dz + sx * 0.0, 0.17, 0), (0.05, 0.02, 2.4), bevel=0.0) for sx in (-1, 1) for dz in (1, 2)])  # plate tread lines
    k.add("concrete", *[K.rbox((sx * B0, 0.26, sz * B0), (0.34, 0.2, 0.34), bevel=0.05 * bv) for sx in (-1, 1) for sz in (-1, 1)])

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
    k.add("steel", K.cyl((0, MAST_TOP + 0.05, 0), 0.28, 0.1, 10, bevel=0.03 * bv))
    k.add("brass" if hot else "body", K.cyl((0, MAST_TOP + 0.3, 0), 0.22, 0.4, 12, top=2.1, bevel=0.04), piece="cone")
    if not hot:  # (stage 2: the beacon halo instead)
        k.add("metal", K.ring((0, MAST_TOP + 0.5, 0), 0.46, 0.04, 12, 3), piece="conering")

    # guy lines from the top level to the pad (none to the back-right)
    anchors = [(-1.2, -1.2), (1.2, -1.2), (-1.2, 1.2)]
    if not lean:
        k.add("rope", *[K.rod((ax * 0.15, 3.7, az * 0.15), (ax, 0.24, az), 0.018, 4) for ax, az in anchors])
    else:  # the guy lines run from the top to the deck's rim, then down to the pad
        k.add("rope", *[K.rod((ax * 0.15, 3.7, az * 0.15), (ax * 0.53, DECK + 0.05, az * 0.53), 0.02, 4) for ax, az in anchors],
              *[K.rod((ax * 0.53, DECK - 0.05, az * 0.53), (ax, 0.24, az), 0.02, 4) for ax, az in anchors])
    if not lean:
        k.add("metal", *[K.ring((ax, 0.22, az), 0.07, 0.025, 8, 3) for ax, az in anchors])

    # cable winch at the right-front, cable up the mast to the cone
    wx, wz = 0.95, -0.55
    k.add("canvasdark", K.rbox((wx, 0.42, wz), (0.5, 0.5, 0.6), bevel=0.06 * bv))
    k.add("rope", K.cyl((wx, 0.52, wz), 0.16, 0.56, 10, rot=(90, 0, 0)))
    k.add("metal", *[K.cyl((wx, 0.52, wz + sz * 0.31), 0.22, 0.04, 10, rot=(90, 0, 0), bevel=0.03 * bv) for sz in (-1, 1)])
    k.add("cable", K.rod((wx - 0.1, 0.62, wz), (0.12, 2.4, -0.1), 0.02, 4), K.rod((0.12, 2.4, -0.1), (0.05, MAST_TOP + 0.1, 0), 0.02, 4))

    # hydrogen cylinders at the back-left, a windsock off the mast top
    gas = [(-1.0, 0.75), (-0.7, 1.0)] + ([(-1.05, 0.35)] if stage >= 1 else [])
    k.add("gas", *[K.cyl((x, 0.62, z), 0.15, 0.85, 10, bevel=0.06 * bv) for x, z in gas],
          *[K.ell((x, 1.05, z), (0.15, 0.08, 0.15), 8, 3) for x, z in gas])
    k.add("metal", *[K.cyl((x, 1.16, z), 0.05, 0.1, 6, bevel=0.03 * bv) for x, z in gas])
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
        # the observation deck: an octagonal plate ringing the mast, struts, a railing
        k.add("deck", K.cyl((0, DECK, 0), 0.98, 0.12, 8, bevel=0, rot=(0, 22.5, 0)))
        k.add("steel", *[K.rod((math.cos(a) * half(1.6) * 1.3, 1.6, math.sin(a) * half(1.6) * 1.3),
                               (math.cos(a) * 0.85, DECK - 0.05, math.sin(a) * 0.85), 0.035, 4)
                         for a in (i * math.pi / 2 + math.pi / 4 for i in range(4))])
        rail = [K.ring((0, DECK + 0.38, 0), 0.92, 0.035, 8, 3, rot=(0, 22.5, 0))]
        rail += [K.rod((math.cos(a) * 0.92, DECK, math.sin(a) * 0.92), (math.cos(a) * 0.92, DECK + 0.38, math.sin(a) * 0.92), 0.025, 4)
                 for a in (i * math.pi / 4 for i in range(8))]
        k.add("brass" if hot else "metal", *rail, piece="rail")
        # a big searchlight drum on the deck's front (and one on its back at stage 2)
        lights = [(-0.62, -1)] + ([(0.62, 1)] if hot else [])
        lenses = []
        for lz, fz in lights:
            k.add("steel", K.rod((0, DECK, lz), (0, DECK + 0.3, lz), 0.05, 6),
                  K.rod((0, DECK + 0.45, lz - fz * 0.12), (0, DECK + 0.62, lz + fz * 0.3), 0.27, 10, top=1.12))
            k.add("dark", K.rbox((0, DECK + 0.32, lz), (0.66, 0.06, 0.12), bevel=0),
                  *[K.rbox((sx * 0.31, DECK + 0.45, lz), (0.05, 0.3, 0.1), bevel=0) for sx in (-1, 1)])
            lenses.append(K.cyl((0, DECK + 0.63, lz + fz * 0.31), 0.27, 0.04, 10, rot=(fz * 60, 0, 0), bevel=0))
        k.add("glow" if hot else "lens", *lenses, piece="lens")

    if hot:
        brass += [K.ring((0, y, 0), half(y) * 1.42, 0.035, 4, 3, rot=(0, 45, 0)) for y in (1.6, 3.7)]
        # the crown: a big glowing beacon halo round the brass mooring cone
        k.add("glow", K.ring((0, MAST_TOP + 0.42, 0), 0.62, 0.08, 16, 4), piece="beacon")
        brass += [K.rod((math.cos(a) * 0.3, MAST_TOP + 0.36, math.sin(a) * 0.3), (math.cos(a) * 0.56, MAST_TOP + 0.42, math.sin(a) * 0.56), 0.03, 4)
                  for a in (i * math.pi / 2 for i in range(4))]
        k.add("brass", *brass)

    colors = {
        "body": CANVAS, "canvas": (236, 232, 222), "canvasdark": (120, 112, 88), "plate": PLATE, "metal": K.METAL,
        "steel": STEEL, "dark": K.DARK, "concrete": (150, 146, 138), "rope": K.ROPE, "cable": (40, 40, 42),
        "sock": SOCK, "gas": GAS, "deck": (150, 108, 64), "lens": (220, 220, 200), "sand": K.SAND, "brass": K.BRASS, "glow": GLOW,
    }
    return k.model("11d", colors, "BLIMP", stage)
