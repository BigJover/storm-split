"""TOTEM - Bone Totem (TowerLook bleached bone; a 4x tower): a carved and painted wooden pole on a
ring of stones, rib bones arching out of it, a great horned frilled skull on top with eye
sockets. Authored from the base (y 0) in Roblox studs; front = -Z (_kit conventions). The base
stays low (under 0.35 studs) so setCharge's ring round the foot still reads.

Stage 0 (tiers 0-2): the stone ring, the carved pole (faces, painted bands), two pairs of ribs
                     with feathers, the skull (frill, brow and nose horns, sockets).
Stage 1 (tier 3):    a crossbar hung with bone charms on cords, a small second skull on the
                     pole, a ring of tusks round the stones.
Stage 2 (tier 5):    brass bands on the pole and brass horn caps, glowing eyes and a glowing
                     crystal on the brow, glowing rune marks on the carved faces.
"""

import importlib.util
import math
from pathlib import Path

_spec = importlib.util.spec_from_file_location("_kit", Path(__file__).with_name("_kit.py"))
K = importlib.util.module_from_spec(_spec)
_spec.loader.exec_module(K)

BONE = (235, 225, 200)  # TowerLook.COLORS.TOTEM
STONE = (110, 104, 96)
POLE = (118, 86, 56)
OCHRE = (176, 74, 50)
TEAL = (60, 140, 136)
SOCKET = (36, 32, 30)
FEATHER = (210, 70, 50)
GLOW = (150, 230, 255)  # TowerLook TOTEM eye

SKULL = (0.0, 4.0, -0.02)


def build(lp, stage):
    k = K.Kit(lp)
    hot = stage >= 2

    # ring of stones and a low earth mound
    k.add("earth", K.cyl((0, 0.08, 0), 1.0, 0.16, 16, top=0.85, bevel=0.05))
    k.add("stone", *[K.ell((math.cos(a) * 1.08, 0.13, math.sin(a) * 1.08), (0.24, 0.15, 0.19), 7, 3, rot=(0, -math.degrees(a), 0))
                     for a in (i * 2 * math.pi / 9 + 0.2 for i in range(9))])

    # the carved pole: fat carved sections and thin necks, painted bands
    segs = [(0.16, 0.7, 0.36), (0.86, 0.22, 0.27), (1.08, 0.66, 0.4), (1.74, 0.2, 0.27), (1.94, 0.62, 0.36), (2.56, 0.22, 0.26), (2.78, 0.7, 0.32)]
    fat, thin = [], []
    for y, h, r in segs:
        (fat if h > 0.5 else thin).append(K.cyl((0, y + h / 2, 0), r, h, 10, top=0.94, bevel=0.06))
    k.add("pole", *fat, *thin)
    k.add("paint", *[K.ring((0, y + h / 2, 0), r - 0.02, 0.05, 10, 3) for y, h, r in segs if h < 0.5], piece="bands")
    # a carved face on each fat section: brow ridge, eye slits, a nose, painted cheeks
    faces, eyes, cheeks = [], [], []
    for y, h, r in segs:
        if h < 0.5:
            continue
        fy = y + h * 0.6
        faces += [K.rbox((0, fy + 0.1, -r + 0.02), (r * 1.3, 0.08, 0.1), bevel=0.03),
                  K.rod((0, fy, -r + 0.04), (0, fy - 0.15, -r - 0.02), 0.075, 6, top=0.7)]
        eyes += [K.rbox((sx * r * 0.38, fy, -r + 0.03), (r * 0.36, 0.07, 0.06), bevel=0.0) for sx in (-1, 1)]
        cheeks += [K.ell((sx * r * 0.55, fy - 0.22, -r * 0.82), (0.07, 0.05, 0.03), 5, 3) for sx in (-1, 1)]
    k.add("pole", *faces)
    k.add("glow" if hot else "socket", *eyes, piece="runes")
    k.add("ochre", *cheeks)

    # rib bones arching out of the pole, feathers on cords at their tips
    ribs, feathers, cords = [], [], []
    for y, yaw in ((1.4, 0), (2.25, 90)):
        for s in (-1, 1):
            a = math.radians(yaw)
            out = (math.cos(a) * s, math.sin(a) * s)
            p0 = (out[0] * 0.3, y, out[1] * 0.3)
            p1 = (out[0] * 0.85, y + 0.35, out[1] * 0.85)
            p2 = (out[0] * 1.05, y + 0.95, out[1] * 1.05)
            ribs += [K.rod(p0, p1, 0.07, 6), K.rod(p1, p2, 0.06, 6, top=0.5)]
            cords.append(K.rod(p1, (p1[0], p1[1] - 0.35, p1[2]), 0.012, 4))
            feathers.append(K.ell((p1[0], p1[1] - 0.48, p1[2]), (0.05, 0.14, 0.025), 6, 3, rot=(0, yaw, 0)))
    k.add("body", *ribs)
    k.add("rope", *cords)
    k.add("feather", *feathers)

    # the great skull: cranium, beak, frill, horns, sockets
    x, y, z = SKULL
    k.add("pole", K.cyl((0, 3.55, 0), 0.24, 0.3, 8))  # neck stub under the skull
    skull = [K.ell((x, y, z), (0.42, 0.36, 0.5), 12, 7),
             K.ell((x, y - 0.14, z - 0.5), (0.24, 0.22, 0.3), 10, 5),  # snout
             K.rod((x, y - 0.18, z - 0.72), (x, y - 0.32, z - 0.88), 0.11, 6, top=0.2)]  # beak
    frill = K.cyl((x, y + 0.32, z + 0.38), 0.72, 0.12, 14, rot=(70, 0, 0), bevel=0.04)
    skull.append(frill)
    k.add("body", *skull)
    s70, c70 = math.sin(math.radians(70)), math.cos(math.radians(70))
    spots = []
    for t in (-2.6, -2.1, -1.57, -1.05, -0.55):  # the upper rim
        px, py, pz = 0.58 * math.cos(t), -0.58 * math.sin(t) * s70, 0.58 * math.sin(t) * c70
        spots.append(K.ell((x + px, y + 0.32 + py - 0.34 * 0.07, z + 0.38 + pz - 0.94 * 0.07), (0.08, 0.08, 0.08), 6, 3))
    k.add("ochre", *spots, piece="frillspots")  # painted dots on the frill rim  # painted dots on the frill rim
    horns = [K.rod((sx * 0.22, y + 0.24, z - 0.22), (sx * 0.42, y + 0.78, z - 0.72), 0.1, 8, top=0.12) for sx in (-1, 1)]
    horns.append(K.rod((x, y + 0.02, z - 0.62), (x, y + 0.3, z - 0.86), 0.08, 6, top=0.15))
    k.add("horn", *horns)
    k.add("glow" if hot else "socket", *[K.ell((sx * 0.2, y + 0.08, z - 0.4), (0.09, 0.08, 0.06), 8, 4) for sx in (-1, 1)], piece="eyes")

    brass = []
    if stage >= 1:
        # a crossbar hung with bone charms
        cy = 3.05
        k.add("pole", K.rod((-0.95, cy, 0.05), (0.95, cy, 0.05), 0.07, 6))
        charms, strings = [], []
        for cx in (-0.85, -0.55, 0.55, 0.85):
            strings.append(K.rod((cx, cy, 0.05), (cx, cy - 0.35, 0.05), 0.012, 4))
            charms.append(K.rod((cx - 0.08, cy - 0.42, 0.05), (cx + 0.08, cy - 0.42, 0.05), 0.03, 5))
            charms += [K.ell((cx + sx * 0.09, cy - 0.42, 0.05), (0.04, 0.04, 0.04), 5, 3) for sx in (-1, 1)]
        k.add("rope", *strings)
        k.add("body", *charms)
        # a small skull on the lower carved section
        k.add("body", K.ell((0, 0.78, -0.42), (0.17, 0.14, 0.15), 8, 5), K.ell((0, 0.73, -0.56), (0.1, 0.08, 0.08), 6, 4))
        k.add("socket", *[K.ell((sx * 0.07, 0.8, -0.55), (0.035, 0.035, 0.02), 4, 3) for sx in (-1, 1)])
        # a ring of tusks round the stones
        k.add("body", *[K.rod((math.cos(a) * 1.25, 0.12, math.sin(a) * 1.25), (math.cos(a) * 1.35, 0.6, math.sin(a) * 1.35), 0.06, 5, top=0.15)
                        for a in (i * 2 * math.pi / 8 + 0.6 for i in range(8)) if not (0.4 < a % (2 * math.pi) < 1.2)])

    if stage >= 2:
        brass += [K.ring((0, y0, 0), r + 0.01, 0.04, 10, 3) for y0, r in ((0.2, 0.36), (1.12, 0.4), (1.98, 0.36), (2.82, 0.32))]
        brass += [K.ell((sx * 0.42, y + 0.8, z - 0.74), (0.05, 0.05, 0.05), 6, 4) for sx in (-1, 1)]  # horn caps
        k.add("glow", K.rod((0, y + 0.34, z - 0.3), (0, y + 0.56, z - 0.36), 0.07, 6, top=0.2), piece="crystal")
        brass.append(K.ring((0, y + 0.34, z - 0.3), 0.08, 0.02, 8, 3))
        k.add("brass", *brass)

    colors = {
        "body": BONE, "horn": (216, 200, 168), "stone": STONE, "earth": (100, 80, 58), "pole": POLE,
        "paint": TEAL, "ochre": OCHRE, "socket": SOCKET, "rope": K.ROPE, "feather": FEATHER,
        "brass": K.BRASS, "glow": GLOW,
    }
    return k.model("11d", colors, "TOTEM", stage)
