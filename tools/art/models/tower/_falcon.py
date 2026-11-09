"""FALCON - Falcon Roost (TowerLook falcon brown): a falconer's plank mews at the back-left and a
tall perch at the front-right with a falcon on its crossbar. Authored from the base (y 0) in
Roblox studs; front = -Z (_kit conventions). The roost can't be damaged.

Stage 0 (tiers 0-2): the mews (plank walls, sloped shingle roof, a door), the perch pole with
                     a padded crossbar and the falcon, a leather glove on a stump.
Stage 1 (tier 3):    a BIGGER AVIARY - a barred aviary loft built on top of the mews with its
                     own gable roof and a second falcon inside, a ladder up to it.
Stage 2 (tier 5):    the tall perch is crowned by a big falcon with its wings spread wide
                     (gold-tipped), a brass hoop round it, brass caps, bells and a weather vane,
                     and a big glowing lantern hung in the aviary's gable.
"""

import importlib.util
import math
from pathlib import Path

_spec = importlib.util.spec_from_file_location("_kit", Path(__file__).with_name("_kit.py"))
K = importlib.util.module_from_spec(_spec)
_spec.loader.exec_module(K)

BROWN = (150, 105, 60)  # TowerLook.COLORS.FALCON
CREAM = (230, 220, 195)
BEAK = (232, 186, 70)
LEATHER = (96, 62, 38)
PLANK = (138, 100, 64)
SHINGLE = (84, 62, 44)

MX, MZ, MW, MD, MH = -0.5, 0.45, 1.8, 1.7, 1.55  # the mews: centre x/z, width, depth, wall height
PX, PZ, PH = 0.85, -0.65, 4.0  # the tall perch: x, z, crossbar height


def falcon(k, at, scale=1.0, hooded=False, stage=0):
    """A perched falcon facing front (-Z), feet on `at`."""
    x, y, z = at
    s = scale
    body, cream, dark = [], [], []
    body.append(K.ell((x, y + 0.36 * s, z + 0.04 * s), (0.16 * s, 0.31 * s, 0.17 * s), 10, 6, rot=(-22, 0, 0)))
    cream.append(K.ell((x, y + 0.38 * s, z - 0.08 * s), (0.12 * s, 0.22 * s, 0.08 * s), 8, 5, rot=(-22, 0, 0)))
    for sx in (-1, 1):  # folded wings, tips crossing past the tail
        body.append(K.ell((x + sx * 0.13 * s, y + 0.3 * s, z + 0.14 * s), (0.055 * s, 0.34 * s, 0.13 * s), 8, 5, rot=(-30, 0, sx * 5)))
    body.append(K.rbox((x, y + 0.02 * s, z + 0.3 * s), (0.14 * s, 0.04 * s, 0.34 * s), bevel=0.015, rot=(-50, 0, 0), taper=(1.4, 1.0)))  # tail
    head = (x, y + 0.7 * s, z - 0.08 * s)
    (dark if hooded else body).append(K.ell(head, (0.12 * s, 0.12 * s, 0.13 * s), 8, 6))
    if not hooded:  # dark cap and "moustache" stripes
        dark.append(K.ell((head[0], head[1] + 0.05 * s, head[2] + 0.02 * s), (0.11 * s, 0.07 * s, 0.11 * s), 8, 4))
    k.add("beak", K.rod((x, head[1] - 0.02 * s, head[2] - 0.12 * s), (x, head[1] - 0.06 * s, head[2] - 0.22 * s), 0.04 * s, 6, top=0.2))
    if hooded:
        dark.append(K.rod((x, head[1] + 0.1 * s, head[2]), (x, head[1] + 0.22 * s, head[2]), 0.03 * s, 6))  # hood plume
    else:
        k.add("eye", *[K.ell((x + sx * 0.08 * s, head[1] + 0.01 * s, head[2] - 0.09 * s), (0.03 * s, 0.03 * s, 0.03 * s), 6, 4) for sx in (-1, 1)])
    k.add("body", *body)
    k.add("cream", *cream)
    if dark:
        k.add("leather", *dark)
    if stage >= 2:  # brass bells on the legs
        k.add("brass", *[K.ell((x + sx * 0.08 * s, y + 0.05 * s, z - 0.06 * s), (0.04 * s, 0.04 * s, 0.04 * s), 6, 4) for sx in (-1, 1)])


def spread_falcon(k, at, s=1.0):
    """A falcon on the perch with its wings spread wide (the stage-2 crown), feet on `at`."""
    x, y, z = at
    k.add("body", K.ell((x, y + 0.4 * s, z), (0.19 * s, 0.36 * s, 0.19 * s), 8, 5, rot=(-12, 0, 0)))
    k.add("cream", K.ell((x, y + 0.42 * s, z - 0.11 * s), (0.14 * s, 0.26 * s, 0.09 * s), 8, 5, rot=(-12, 0, 0)))
    head = (x, y + 0.86 * s, z - 0.06 * s)
    k.add("body", K.ell(head, (0.14 * s, 0.14 * s, 0.15 * s), 8, 6))
    k.add("leather", K.ell((head[0], head[1] + 0.06 * s, head[2] + 0.02 * s), (0.13 * s, 0.08 * s, 0.13 * s), 8, 4))
    k.add("beak", K.rod((x, head[1] - 0.02 * s, head[2] - 0.13 * s), (x, head[1] - 0.07 * s, head[2] - 0.25 * s), 0.045 * s, 6, top=0.2))
    k.add("eye", *[K.ell((x + sx * 0.09 * s, head[1] + 0.01 * s, head[2] - 0.1 * s), (0.035 * s,) * 3, 6, 4) for sx in (-1, 1)])
    k.add("body", K.rbox((x, y + 0.08 * s, z + 0.3 * s), (0.2 * s, 0.05 * s, 0.4 * s), bevel=0, rot=(-40, 0, 0), taper=(1.6, 1.0)))
    for sx in (-1, 1):  # two wing panels per side, raised in a wide shallow V, gold-tipped
        sh = (x + sx * 0.12 * s, y + 0.62 * s, z + 0.05 * s)  # shoulder
        a1, a2, l1, l2 = 6, 22, 0.64 * s, 0.5 * s
        d1 = (math.cos(math.radians(a1)), math.sin(math.radians(a1)))
        d2 = (math.cos(math.radians(a2)), math.sin(math.radians(a2)))
        c1 = (sh[0] + sx * d1[0] * l1 / 2, sh[1] + d1[1] * l1 / 2, sh[2])
        e1 = (sh[0] + sx * d1[0] * l1, sh[1] + d1[1] * l1, sh[2])
        c2 = (e1[0] + sx * d2[0] * l2 / 2, e1[1] + d2[1] * l2 / 2, sh[2] + 0.03 * s)
        e2 = (e1[0] + sx * d2[0] * l2, e1[1] + d2[1] * l2, sh[2] + 0.03 * s)
        k.add("body", K.rbox(c1, (l1 + 0.06 * s, 0.08 * s, 0.5 * s), bevel=0, rot=(0, 0, sx * a1), taper=(1.0, 0.85)))
        k.add("cream", K.rbox((c1[0], c1[1] - 0.05 * s, c1[2] - 0.04 * s), (l1, 0.03 * s, 0.38 * s), bevel=0, rot=(0, 0, sx * a1)))
        k.add("body", K.rbox(c2, (l2 + 0.04 * s, 0.07 * s, 0.42 * s), bevel=0, rot=(0, 0, sx * a2), taper=(0.75, 0.7)))
        k.add("brass", K.rbox((e2[0] + sx * 0.07 * s, e2[1] + 0.06 * s, e2[2]), (0.22 * s, 0.06 * s, 0.32 * s), bevel=0,
                              rot=(0, 0, sx * 48), taper=(0.4, 0.5)))


def build(lp, stage):
    k = K.Kit(lp)
    # stage 2 moves the tall perch toward the middle and lowers it a little: room for the spread wings
    px, ph = (PX, PH) if stage < 2 else (0.27, 3.62)

    # the mews: a plank box with corner posts, a sloped shingle roof falling to the left
    k.add("plank", K.rbox((MX, MH / 2, MZ), (MW, MH, MD), bevel=0.06))
    k.add("dark", *[K.rbox((MX, y, MZ), (MW + 0.04, 0.04, MD + 0.04), bevel=0.01) for y in (0.45, 0.9)])  # plank seams
    posts = [K.rbox((MX + sx * (MW / 2 - 0.02), (MH + 0.2) / 2, MZ + sz * (MD / 2 - 0.02)), (0.16, MH + 0.2, 0.16), bevel=0.04 if stage == 0 else 0)
             for sx in (-1, 1) for sz in (-1, 1)]
    k.add("wood", *posts)
    if stage == 0:
        k.add("roof", K.rbox((MX, MH + 0.28, MZ), (MW + 0.18, 0.14, MD + 0.25), bevel=0.05, rot=(0, 0, 12)))
        k.add("dark", *[K.rbox((MX + u * 0.98, MH + 0.28 + u * 0.21 + 0.07, MZ), (0.1, 0.06, MD + 0.27), bevel=0.02, rot=(0, 0, 12))
                        for u in (-0.6, 0.0, 0.6)])  # shingle battens
    else:  # the aviary loft: a floor, corner posts, bars on every side, a gable roof (ridge front-back)
        fy, ly = MH + 0.06, MH + 1.35  # loft floor / eaves
        k.add("roof", K.rbox((MX, fy, MZ), (MW + 0.2, 0.14, MD + 0.2), bevel=0.04))
        lw, ld = MW - 0.1, MD - 0.1
        k.add("wood", *[K.rbox((MX + sx * lw / 2, (fy + ly) / 2, MZ + sz * ld / 2), (0.14, ly - fy, 0.14), bevel=0)
                        for sx in (-1, 1) for sz in (-1, 1)])
        k.add("wood", *[K.rbox((MX, ly, MZ + sz * ld / 2), (lw + 0.14, 0.12, 0.12), bevel=0) for sz in (-1, 1)],
              *[K.rbox((MX + sx * lw / 2, ly, MZ), (0.12, 0.12, ld), bevel=0) for sx in (-1, 1)])
        bars = []
        for i in range(1, 5):  # front and back bars
            bx = MX - lw / 2 + i * lw / 5
            bars += [K.rbox((bx, (fy + ly) / 2, MZ + sz * ld / 2), (0.04, ly - fy, 0.04), bevel=0) for sz in (-1, 1)]
        for i in range(1, 4):  # side bars
            bz = MZ - ld / 2 + i * ld / 4
            bars += [K.rbox((MX + sx * lw / 2, (fy + ly) / 2, bz), (0.04, ly - fy, 0.04), bevel=0) for sx in (-1, 1)]
        k.add("dark", *bars)
        # gable roof: two slopes meeting in a ridge that runs front to back
        half = MW / 2
        for sx in (-1, 1):
            k.add("roof", K.rbox((MX + sx * half / 2, ly + 0.36, MZ), (half / math.cos(math.radians(32)) + 0.08, 0.12, MD + 0.3),
                                 bevel=0.03, rot=(0, 0, -sx * 32)))
        k.add("brass" if stage >= 2 else "dark", K.rbox((MX, ly + 0.66, MZ), (0.16, 0.14, MD + 0.34), bevel=0))  # ridge beam
        falcon(k, (MX - 0.35, fy + 0.07, MZ - 0.1), 0.85)  # a falcon in the aviary
        k.add("wood", K.rod((MX - 0.75, fy + 0.07, MZ - 0.1), (MX + 0.2, fy + 0.07, MZ - 0.1), 0.05, 6))
    # door and a small barred window on the front
    fz = MZ - MD / 2
    lean = 0 if stage else 1
    k.add("dark", K.rbox((MX + 0.25, 0.55, fz - 0.02), (0.6, 1.1, 0.06), bevel=0.03 * lean),
          K.rbox((MX - 0.5, 1.1, fz - 0.02), (0.4, 0.3, 0.05), bevel=0.02 * lean))
    k.add("wood", *[K.rbox((MX - 0.5 + dx, 1.1, fz - 0.05), (0.04, 0.32, 0.04), bevel=0.01) for dx in (-0.1, 0.0, 0.1)])
    k.add("metal", K.ell((MX + 0.47, 0.6, fz - 0.06), (0.04, 0.04, 0.04), 6, 4))  # door knob

    # the tall perch: pole, padded crossbar, the falcon; a stump with a glove beside it
    k.add("wood", K.rod((px, 0, PZ), (px, ph, PZ), 0.12, 10), K.rod((px - 0.45, ph, PZ), (px + 0.45, ph, PZ), 0.07, 8))
    k.add("leather", K.rod((px - 0.22, ph, PZ), (px + 0.22, ph, PZ), 0.095, 8))  # padded grip
    k.add("dark", *[K.rod((px, 0.12, PZ), (px + dx, 0.06, PZ + dz), 0.06, 6) for dx, dz in ((0.35, 0.0), (-0.3, -0.2), (0.0, 0.35))])  # pole feet
    if stage >= 2:
        spread_falcon(k, (px, ph + 0.08, PZ), 0.86)
    else:
        falcon(k, (px, ph + 0.08, PZ), 1.0, stage=stage)
    k.add("wood", K.cyl((0.0, 0.22, -1.1), 0.26, 0.44, 10, bevel=0.04 if stage == 0 else 0))
    k.add("leather", K.rbox((0.03, 0.52, -1.1), (0.22, 0.16, 0.3), bevel=0.06 if stage == 0 else 0, rot=(0, 25, 0)))

    brass = []
    if stage >= 1:
        # a ladder against the mews' right wall, up to the aviary
        rx = MX + MW / 2 + 0.08
        k.add("wood", *[K.rod((rx, 0, MZ + dz), (rx, MH + 0.3, MZ + dz), 0.05, 6) for dz in (-0.22, 0.22)],
              *[K.rod((rx, y, MZ - 0.22), (rx, y, MZ + 0.22), 0.035, 6) for y in (0.35, 0.75, 1.15, 1.55)])

    if stage >= 2:
        brass += [K.cyl((px + sx * 0.47, ph, PZ), 0.09, 0.1, 8, bevel=0, rot=(0, 0, 90)) for sx in (-1, 1)]  # perch caps
        brass.append(K.cyl((px, 0.15, PZ), 0.17, 0.12, 10, bevel=0))  # pole collar
        # a brass hoop round the crown falcon's perch, a weather vane on the aviary ridge
        brass.append(K.ring((px, ph - 0.25, PZ), 0.3, 0.05, 12, 4))
        vy = MH + 1.35 + 0.72
        brass += [K.rod((MX, vy, MZ + 0.4), (MX, vy + 0.75, MZ + 0.4), 0.035, 6),
                  K.rod((MX - 0.3, vy + 0.55, MZ + 0.4), (MX + 0.3, vy + 0.55, MZ + 0.4), 0.03, 6),
                  K.rbox((MX + 0.32, vy + 0.55, MZ + 0.4), (0.14, 0.18, 0.04), bevel=0.01, taper=(0.3, 1.0))]
        brass += [K.rbox((MX, MH + 1.35, MZ + sz * (MD - 0.1) / 2), (MW + 0.1, 0.06, 0.16), bevel=0) for sz in (-1, 1)]  # brass eaves
        # a big lantern hung in the aviary's front gable
        lz = MZ - MD / 2 - 0.12
        brass += [K.rod((MX, MH + 1.75, lz + 0.1), (MX, MH + 1.58, lz), 0.03, 6), K.cyl((MX, MH + 1.55, lz), 0.17, 0.07, 8, bevel=0),
                  K.cyl((MX, MH + 1.05, lz), 0.19, 0.06, 8, bevel=0)]
        k.add("glow", K.cyl((MX, MH + 1.3, lz), 0.15, 0.44, 8, bevel=0.03))
        k.add("brass", *brass)

    colors = {
        "body": BROWN, "cream": CREAM, "beak": BEAK, "eye": (24, 22, 20), "leather": LEATHER,
        "plank": PLANK, "roof": SHINGLE, "wood": K.WOOD, "dark": K.DARK, "metal": K.METAL,
        "rope": K.ROPE, "meat": (160, 60, 50), "brass": K.BRASS, "glow": K.GLOW,
    }
    return k.model("11d", colors, "FALCON", stage)
