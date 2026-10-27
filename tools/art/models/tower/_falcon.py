"""FALCON - Falcon Roost (TowerLook falcon brown): a falconer's plank mews at the back-left and a
tall perch at the front-right with a falcon on its crossbar. Authored from the base (y 0) in
Roblox studs; front = -Z (_kit conventions). The roost can't be damaged.

Stage 0 (tiers 0-2): the mews (plank walls, sloped shingle roof, a door), the perch pole with
                     a padded crossbar and the falcon, a leather glove on a stump.
Stage 1 (tier 3):    a second, lower perch with a hooded falcon, a feather pennant on the
                     tall pole, a ladder against the mews, a feeding block.
Stage 2 (tier 5):    brass bells on the falcons, brass caps on the perches, a brass weather
                     vane on the roof, a glowing lantern on the mews.
"""

import importlib.util
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


def build(lp, stage):
    k = K.Kit(lp)

    # the mews: a plank box with corner posts, a sloped shingle roof falling to the left
    k.add("plank", K.rbox((MX, MH / 2, MZ), (MW, MH, MD), bevel=0.06))
    k.add("dark", *[K.rbox((MX, y, MZ), (MW + 0.04, 0.04, MD + 0.04), bevel=0.01) for y in (0.45, 0.9)])  # plank seams
    posts = [K.rbox((MX + sx * (MW / 2 - 0.02), (MH + 0.2) / 2, MZ + sz * (MD / 2 - 0.02)), (0.16, MH + 0.2, 0.16), bevel=0.04)
             for sx in (-1, 1) for sz in (-1, 1)]
    k.add("wood", *posts)
    k.add("roof", K.rbox((MX, MH + 0.28, MZ), (MW + 0.18, 0.14, MD + 0.25), bevel=0.05, rot=(0, 0, 12)))
    k.add("dark", *[K.rbox((MX + u * 0.98, MH + 0.28 + u * 0.21 + 0.07, MZ), (0.1, 0.06, MD + 0.27), bevel=0.02, rot=(0, 0, 12))
                    for u in (-0.6, 0.0, 0.6)])  # shingle battens
    # door and a small barred window on the front
    fz = MZ - MD / 2
    k.add("dark", K.rbox((MX + 0.25, 0.55, fz - 0.02), (0.6, 1.1, 0.06), bevel=0.03),
          K.rbox((MX - 0.5, 1.1, fz - 0.02), (0.4, 0.3, 0.05), bevel=0.02))
    k.add("wood", *[K.rbox((MX - 0.5 + dx, 1.1, fz - 0.05), (0.04, 0.32, 0.04), bevel=0.01) for dx in (-0.1, 0.0, 0.1)])
    k.add("metal", K.ell((MX + 0.47, 0.6, fz - 0.06), (0.04, 0.04, 0.04), 6, 4))  # door knob

    # the tall perch: pole, padded crossbar, the falcon; a stump with a glove beside it
    k.add("wood", K.rod((PX, 0, PZ), (PX, PH, PZ), 0.12, 10), K.rod((PX - 0.45, PH, PZ), (PX + 0.45, PH, PZ), 0.07, 8))
    k.add("leather", K.rod((PX - 0.22, PH, PZ), (PX + 0.22, PH, PZ), 0.095, 8))  # padded grip
    k.add("dark", *[K.rod((PX, 0.12, PZ), (PX + dx, 0.06, PZ + dz), 0.06, 6) for dx, dz in ((0.35, 0.0), (-0.3, -0.2), (0.0, 0.35))])  # pole feet
    falcon(k, (PX, PH + 0.08, PZ), 1.0, stage=stage)
    k.add("wood", K.cyl((0.0, 0.22, -1.1), 0.26, 0.44, 10, bevel=0.04))
    k.add("leather", K.rbox((0.03, 0.52, -1.1), (0.22, 0.16, 0.3), bevel=0.06, rot=(0, 25, 0)))

    brass = []
    if stage >= 1:
        # a lower perch on the left with a hooded falcon
        lx, lz, lh = -1.12, -1.0, 2.1
        k.add("wood", K.rod((lx, 0, lz), (lx, lh, lz), 0.09, 8), K.rod((lx - 0.3, lh, lz), (lx + 0.3, lh, lz), 0.06, 8))
        falcon(k, (lx, lh + 0.06, lz), 0.8, hooded=True, stage=stage)
        # a pennant of feathers on the tall pole
        k.add("cream", *[K.ell((PX + 0.14, PH - 0.6 - i * 0.18, PZ), (0.04, 0.12, 0.03), 6, 3, rot=(0, 0, 25)) for i in range(3)])
        k.add("rope", K.ring((PX, PH - 0.5, PZ), 0.14, 0.03, 10, 4))
        # a ladder against the mews' right wall, a feeding block
        rx = MX + MW / 2 + 0.08
        k.add("wood", *[K.rod((rx, 0, MZ + dz), (rx, MH + 0.1, MZ + dz), 0.04, 6) for dz in (-0.22, 0.22)],
              *[K.rod((rx, y, MZ - 0.22), (rx, y, MZ + 0.22), 0.03, 6) for y in (0.35, 0.75, 1.15)])
        k.add("plank", K.rbox((0.35, 0.18, -0.15), (0.4, 0.36, 0.4), bevel=0.05))
        k.add("meat", K.ell((0.35, 0.4, -0.15), (0.13, 0.08, 0.1), 8, 4))

    if stage >= 2:
        brass += [K.cyl((PX + sx * 0.47, PH, PZ), 0.09, 0.1, 8, rot=(0, 0, 90)) for sx in (-1, 1)]  # perch caps
        brass.append(K.cyl((PX, 0.15, PZ), 0.17, 0.12, 10))  # pole collar
        # weather vane on the roof ridge
        vx = MX
        brass += [K.rod((vx, MH + 0.45, MZ), (vx, MH + 1.1, MZ), 0.03, 6),
                  K.rod((vx, MH + 0.95, MZ - 0.3), (vx, MH + 0.95, MZ + 0.3), 0.025, 6),
                  K.rbox((vx, MH + 0.95, MZ - 0.32), (0.04, 0.16, 0.12), bevel=0.01)]
        # a lantern on a bracket off the mews' front-left post
        lx, lz = MX - 0.55, MZ - MD / 2 - 0.16
        brass += [K.rod((lx, 1.45, lz + 0.16), (lx, 1.45, lz), 0.025, 6), K.cyl((lx, 1.42, lz), 0.09, 0.05, 8)]
        k.add("glow", K.ell((lx, 1.28, lz), (0.09, 0.12, 0.09), 8, 5))
        k.add("brass", *brass)

    colors = {
        "body": BROWN, "cream": CREAM, "beak": BEAK, "eye": (24, 22, 20), "leather": LEATHER,
        "plank": PLANK, "roof": SHINGLE, "wood": K.WOOD, "dark": K.DARK, "metal": K.METAL,
        "rope": K.ROPE, "meat": (160, 60, 50), "brass": K.BRASS, "glow": K.GLOW,
    }
    return k.model("11d", colors, "FALCON", stage)
