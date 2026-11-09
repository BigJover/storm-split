"""TOTEM - Bone Totem (TowerLook bleached bone; a 4x tower): a carved and painted wooden pole on a
ring of stones, rib bones arching out of it, a great horned frilled skull on top with eye
sockets. Authored from the base (y 0) in Roblox studs; front = -Z (_kit conventions). The base
stays low (under 0.35 studs) so setCharge's ring round the foot still reads.

Stage 0 (tiers 0-2): the stone ring, the carved pole (faces, painted bands), two pairs of ribs
                     with feathers, the skull (frill, brow and nose horns, sockets).
Stage 1 (tier 3):    SPREAD WINGS and a SECOND HEAD - a pair of great feathered wings on bone
                     struts spread wide from the top of the pole, and a horned second skull
                     carved on the lower pole.
Stage 2 (tier 5):    MORE HEADS - two more skulls on a crossbar look out to the sides, a second,
                     lower pair of wings, brass-tipped feathers, brass bands and horn caps,
                     every skull's eyes glowing, glowing runes and a glowing brow crystal.
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


def wing(k, brass, y0, span, rise, n, flen, hot):
    """A pair of spread wings off the pole at y0: a bone strut out to x = +-span (rising `rise`),
    n long feathers hanging from it, longest outermost; painted ochre / teal, brass-tipped when hot."""
    for sx in (-1, 1):
        a, b = (sx * 0.28, y0, 0.08), (sx * span, y0 + rise, 0.12)
        k.add("body", K.rod(a, b, 0.08, 6, top=0.5))
        for i in range(n):
            t = (i + 1) / n
            base = K.along(a, b, t * 0.97)
            ln = flen * (0.55 + 0.45 * t)
            tip = (base[0] + sx * 0.08 * t, base[1] - ln, base[2] + 0.03)
            k.add("ochre" if i % 2 else "paint", K.bar(base, tip, 0.2 + 0.04 * t, 0.035, bevel=0, up=(0, 0, 1)),
                  piece="feathers2" if i % 2 else "feathers")
            if hot and flen > 0.7:
                brass.append(K.bar(K.along(base, tip, 0.86), K.along(base, tip, 1.06), 0.2 + 0.04 * t, 0.05, bevel=0, up=(0, 0, 1)))


def head(k, at, s, hot, yaw=0, horns=False):
    """A smaller horned skull (cranium, snout, beak, horns, eyes) facing -Z turned by yaw."""
    x, y, z = at
    ca, sa = math.cos(math.radians(yaw)), math.sin(math.radians(yaw))

    def p(dx, dy, dz):  # local (front = -z) -> world, turned by yaw about y
        return (x + dx * ca - dz * sa, y + dy, z + dx * sa + dz * ca)
    k.add("body", K.ell(p(0, 0, 0), (0.42 * s, 0.36 * s, 0.5 * s), 7, 4, rot=(0, -yaw, 0)),
          K.ell(p(0, -0.14 * s, -0.5 * s), (0.24 * s, 0.22 * s, 0.3 * s), 6, 3, rot=(0, -yaw, 0)),
          K.rod(p(0, -0.18 * s, -0.72 * s), p(0, -0.32 * s, -0.88 * s), 0.11 * s, 5, top=0.2))
    if horns:
        k.add("horn", *[K.rod(p(sx * 0.22 * s, 0.24 * s, -0.22 * s), p(sx * 0.42 * s, 0.78 * s, -0.72 * s), 0.1 * s, 6, top=0.12)
                        for sx in (-1, 1)])
    k.add("glow" if hot else "socket", *[K.ell(p(sx * 0.2 * s, 0.08 * s, -0.4 * s), (0.1 * s, 0.09 * s, 0.07 * s), 5, 3)
                                         for sx in (-1, 1)], piece="eyes")


def build(lp, stage):
    k = K.Kit(lp)
    hot = stage >= 2
    lean = stage >= 1  # the upgrades spend their triangles on wings and heads: plainer base parts
    bv = 0 if lean else 1

    # ring of stones and a low earth mound
    k.add("earth", K.cyl((0, 0.08, 0), 1.0, 0.16, 16, top=0.85, bevel=0.05 * bv))
    k.add("stone", *[K.ell((math.cos(a) * 1.08, 0.13, math.sin(a) * 1.08), (0.24, 0.15, 0.19), 6 if lean else 7, 3, rot=(0, -math.degrees(a), 0))
                     for a in (i * 2 * math.pi / 9 + 0.2 for i in range(9))])

    # the carved pole: fat carved sections and thin necks, painted bands
    segs = [(0.16, 0.7, 0.36), (0.86, 0.22, 0.27), (1.08, 0.66, 0.4), (1.74, 0.2, 0.27), (1.94, 0.62, 0.36), (2.56, 0.22, 0.26), (2.78, 0.7, 0.32)]
    fat, thin = [], []
    for y, h, r in segs:
        (fat if h > 0.5 else thin).append(K.cyl((0, y + h / 2, 0), r, h, 10, top=0.94, bevel=0.06 * bv))
    k.add("pole", *fat, *thin)
    if not hot:  # painted bands on the necks (stage 2: brass bands instead)
        k.add("paint", *[K.ring((0, y + h / 2, 0), r - 0.02, 0.05, 10, 3) for y, h, r in segs if h < 0.5], piece="bands")
    # a carved face on each fat section: brow ridge, eye slits, a nose, painted cheeks
    faces, eyes, cheeks = [], [], []
    for y, h, r in segs:
        if h < 0.5:
            continue
        fy = y + h * 0.6
        faces += [K.rbox((0, fy + 0.1, -r + 0.02), (r * 1.3, 0.08, 0.1), bevel=0.03 * bv),
                  K.rod((0, fy, -r + 0.04), (0, fy - 0.15, -r - 0.02), 0.075, 6, top=0.7)]
        eyes += [K.rbox((sx * r * 0.38, fy, -r + 0.03), (r * 0.36, 0.07, 0.06), bevel=0.0) for sx in (-1, 1)]
        cheeks += [K.ell((sx * r * 0.55, fy - 0.22, -r * 0.82), (0.07, 0.05, 0.03), 5, 3) for sx in (-1, 1)] if not hot else []
    k.add("pole", *faces)
    k.add("glow" if hot else "socket", *eyes, piece="runes")
    if not hot:
        k.add("ochre", *cheeks)

    # rib bones arching out of the pole, feathers on cords at their tips
    ribs, feathers, cords = [], [], []
    for y, yaw in ((1.4, 0), (2.25, 90)) if not lean else ():
        for s in (-1, 1):
            a = math.radians(yaw)
            out = (math.cos(a) * s, math.sin(a) * s)
            p0 = (out[0] * 0.3, y, out[1] * 0.3)
            p1 = (out[0] * 0.85, y + 0.35, out[1] * 0.85)
            p2 = (out[0] * 1.05, y + 0.95, out[1] * 1.05)
            ribs += [K.rod(p0, p1, 0.07, 6), K.rod(p1, p2, 0.06, 6, top=0.5)]
            cords.append(K.rod(p1, (p1[0], p1[1] - 0.35, p1[2]), 0.012, 4))
            feathers.append(K.ell((p1[0], p1[1] - 0.48, p1[2]), (0.05, 0.14, 0.025), 6, 3, rot=(0, yaw, 0)))
    if not lean:  # (the upgrades' wings take the ribs' place)
        k.add("body", *ribs)
        k.add("rope", *cords)
        k.add("feather", *feathers)

    # the great skull: cranium, beak, frill, horns, sockets
    x, y, z = SKULL
    k.add("pole", K.cyl((0, 3.55, 0), 0.24, 0.3, 8))  # neck stub under the skull
    skull = [K.ell((x, y, z), (0.42, 0.36, 0.5), 10 if lean else 12, 6 if lean else 7),
             K.ell((x, y - 0.14, z - 0.5), (0.24, 0.22, 0.3), 10, 5),  # snout
             K.rod((x, y - 0.18, z - 0.72), (x, y - 0.32, z - 0.88), 0.11, 6, top=0.2)]  # beak
    frill = K.cyl((x, y + 0.32, z + 0.38), 0.72, 0.12, 14, rot=(70, 0, 0), bevel=0.04)
    skull.append(frill)
    k.add("body", *skull)
    s70, c70 = math.sin(math.radians(70)), math.cos(math.radians(70))
    spots = []
    for t in (-2.6, -2.1, -1.57, -1.05, -0.55) if not hot else ():  # the upper rim
        px, py, pz = 0.58 * math.cos(t), -0.58 * math.sin(t) * s70, 0.58 * math.sin(t) * c70
        spots.append(K.ell((x + px, y + 0.32 + py - 0.34 * 0.07, z + 0.38 + pz - 0.94 * 0.07), (0.08, 0.08, 0.08), 6, 3))
    if not hot:
        k.add("ochre", *spots, piece="frillspots")  # painted dots on the frill rim  # painted dots on the frill rim
    horns = [K.rod((sx * 0.22, y + 0.24, z - 0.22), (sx * 0.42, y + 0.78, z - 0.72), 0.1, 8, top=0.12) for sx in (-1, 1)]
    horns.append(K.rod((x, y + 0.02, z - 0.62), (x, y + 0.3, z - 0.86), 0.08, 6, top=0.15))
    k.add("horn", *horns)
    k.add("glow" if hot else "socket", *[K.ell((sx * 0.2, y + 0.08, z - 0.4), (0.09, 0.08, 0.06), 8, 4) for sx in (-1, 1)], piece="eyes")

    brass = []
    if stage >= 1:
        # the great wings: a bone strut out and up, long painted feathers hanging from it
        wing(k, brass, 2.75, 1.25, 0.75, 5, 0.95, hot)
        # a second, horned head carved on the lower pole
        head(k, (0.0, 0.92, -0.44), 0.62, hot, horns=True)
    if stage >= 2:
        wing(k, brass, 1.55, 1.05, 0.4, 4, 0.6, hot)  # a lower pair of wings
        # a crossbar with two more skulls looking out to the sides
        cy = 3.1
        k.add("pole", K.rod((-1.0, cy, 0.05), (1.0, cy, 0.05), 0.08, 6))
        for sx in (-1, 1):
            head(k, (sx * 0.98, cy + 0.2, 0.05), 0.5, hot, yaw=sx * 90, horns=True)
        brass += [K.cyl((0, y0 + h / 2, 0), r + 0.04, 0.12, 10, bevel=0) for y0, h, r in segs if h < 0.5]
        brass += [K.ell((sx * 0.42, y + 0.8, z - 0.74), (0.06, 0.06, 0.06), 6, 4) for sx in (-1, 1)]  # horn caps
        k.add("glow", K.rod((0, y + 0.3, z - 0.3), (0, y + 0.62, z - 0.38), 0.1, 6, top=0.2), piece="crystal")
        brass.append(K.ring((0, y + 0.3, z - 0.3), 0.11, 0.025, 8, 3))
    if brass:
        k.add("brass", *brass)

    colors = {
        "body": BONE, "horn": (216, 200, 168), "stone": STONE, "earth": (100, 80, 58), "pole": POLE,
        "paint": TEAL, "ochre": OCHRE, "socket": SOCKET, "rope": K.ROPE, "feather": FEATHER,
        "brass": K.BRASS, "glow": GLOW,
    }
    return k.model("11d", colors, "TOTEM", stage)
