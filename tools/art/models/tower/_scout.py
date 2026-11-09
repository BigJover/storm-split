"""SCOUT - Hunting Blind (TowerLook camo green): a low canvas hide with viewing slits all
round, a thatch-and-leaf roof, a canvas awning over the front slit and a rifle poking out of
it. Authored from the base (y 0) in Roblox studs; front = -Z (_kit conventions).

Stage 0 (tiers 0-2): the hide, camo patches, slits, corner poles, awning, thatch, one rifle.
Stage 1 (tier 3):    a second storey - a camo lookout box on the roof with its own slit,
                     rifle, ladder and thatch roof; sandbags banked along the front, a second
                     rifle out of the left slit.
Stage 2 (tier 5):    a taller lookout under a peaked brass-trimmed thatch roof crowned by a
                     glowing signal brazier, a big horned dino skull on its front, brass-framed
                     slits and brass scopes.
"""

import importlib.util
from pathlib import Path

_spec = importlib.util.spec_from_file_location("_kit", Path(__file__).with_name("_kit.py"))
K = importlib.util.module_from_spec(_spec)
_spec.loader.exec_module(K)

GREEN = (100, 140, 70)  # TowerLook.COLORS.SCOUT
CAMO = (62, 88, 46)
SLIT = (30, 30, 24)
THATCH = (178, 154, 96)
LEAF = (74, 116, 50)
BONE = (228, 218, 192)

W, D, H, Z0, TAPER = 2.6, 2.3, 2.1, 0.12, 0.88  # the hide: width (x), depth (z), height, centre z


def shrink(y):
    return 1 - (1 - TAPER) * min(1.0, max(0.0, y / H))


def side_x(y):
    return W / 2 * shrink(y)


def front_z(y):
    return Z0 - D / 2 * shrink(y)


def back_z(y):
    return Z0 + D / 2 * shrink(y)


def build(lp, stage):
    k = K.Kit(lp)
    sy = 1.5  # slit height

    k.add("body", K.rbox((0, H / 2, Z0), (W, H, D), bevel=0.28, segments=2, taper=(TAPER, TAPER)))

    # camo patches pressed onto the walls
    patches = []
    for u, y, s in ((-0.7, 0.5, 0.36), (0.6, 0.75, 0.32), (0.05, 0.35, 0.26)):
        patches.append(K.ell((u, y, front_z(y) - 0.005), (s, s * 0.6, 0.05), 8, 3))
        patches.append(K.ell((-u, y + 0.15, back_z(y + 0.15) + 0.005), (s, s * 0.6, 0.05), 8, 3))
        for sx in (-1, 1):
            patches.append(K.ell((sx * (side_x(y + 0.1) + 0.005), y + 0.1, Z0 + u * sx), (0.05, s * 0.6, s), 8, 3))
    k.add("camo", *patches)

    # viewing slits all round (dark), the front one wider
    k.add("slit",
          K.rbox((0, sy, front_z(sy)), (1.7, 0.3, 0.1), bevel=0.04),
          K.rbox((0, sy, back_z(sy)), (1.3, 0.28, 0.1), bevel=0.04),
          *[K.rbox((sx * side_x(sy), sy, Z0), (0.1, 0.28, 1.3), bevel=0.04) for sx in (-1, 1)])

    # corner poles holding the roof
    poles = []
    for sx in (-1, 1):
        for zf in (front_z, back_z):
            x0, z0 = sx * (side_x(0) - 0.08), zf(0) + (0.08 if zf is front_z else -0.08)
            x1, z1 = sx * (side_x(H) - 0.06), zf(H) + (0.06 if zf is front_z else -0.06)
            poles.append(K.rod((x0, 0, z0), (x1, H + 0.15, z1), 0.085, 8))
    # awning sticks
    zf = front_z(sy)
    for sx in (-1, 1):
        poles.append(K.rod((sx * 0.95, sy + 0.25, zf), (sx * 0.95, 1.86, -1.36), 0.04, 6))
    k.add("wood", *poles)

    # canvas awning over the front slit, sloping down and out
    k.add("canvas", K.bar((0, 2.12, front_z(2.1) + 0.05), (0, 1.84, -1.42), 2.2, 0.07, bevel=0.03))

    # thatch roof with leafy clumps (kept off the back-right corner: the owner flag's)
    roof_y = H + 0.1
    k.add("thatch", K.rbox((0, roof_y, Z0), (2.72, 0.22, 2.5), bevel=0.1, segments=2))
    if stage == 0:
        clumps = ((-0.62, -0.55, 0.46), (0.55, -0.45, 0.42), (-0.6, 0.65, 0.4), (0.15, 0.15, 0.36))
    else:  # the lookout stands on the roof's left: the clumps go round it
        clumps = ((0.85, -0.55, 0.36), (0.8, 0.25, 0.3), (-1.0, 0.95, 0.3))
    seg = (10, 5) if stage == 0 else (8, 4)
    k.add("leaf", *[K.ell((x, roof_y + 0.14, Z0 + z), (s, s * 0.5, s * 0.85), *seg) for x, z, s in clumps])

    # rifles poking out of the slits; the first one's muzzle is the firing point
    rifles = [((0.42, sy, front_z(sy) + 0.4), (0.42, sy + 0.03, -1.4))]
    if stage >= 1:
        rifles.append(((-side_x(sy) + 0.4, sy, Z0 - 0.25), (-1.42, sy + 0.03, Z0 - 0.25)))

    # stage 1+: a second storey - a camo lookout box on the roof's left half, its own slit,
    # rifle and thatch roof; stage 2 builds it taller and crowns it with a peaked roof
    LX, LZ, LW, LD = -0.3, Z0 - 0.15, 1.5, 1.4
    ly0 = roof_y + 0.11
    LH = 1.05 if stage == 1 else 1.12
    ly1 = ly0 + LH
    if stage >= 1:
        k.add("body", K.rbox((LX, ly0 + LH / 2, LZ), (LW, LH, LD), bevel=0.14, segments=1, taper=(0.9, 0.9)))
        lsy = ly0 + LH * 0.62
        k.add("slit", K.rbox((LX, lsy, LZ - LD / 2 * 0.95), (1.1, 0.24, 0.1), bevel=0.04))
        rifles.append(((LX + 0.25, lsy, LZ - 0.2), (LX + 0.25, lsy + 0.02, -1.25)))
        # corner poles of the lookout, a ladder up its right side
        lp_ = []
        for sx in (-1, 1):
            for sz in (-1, 1):
                x, z = LX + sx * (LW / 2 - 0.02), LZ + sz * (LD / 2 - 0.02)
                lp_.append(K.rod((x, ly0 - 0.05, z), (x, ly1 + 0.1, z), 0.07, 6))
        for dz in (-0.25, 0.25):
            lp_.append(K.rod((LX + LW / 2 + 0.12, roof_y + 0.1, LZ + dz), (LX + LW / 2 + 0.12, ly1 - 0.1, LZ + dz), 0.035, 5))
        lp_ += [K.rod((LX + LW / 2 + 0.12, y, LZ - 0.25), (LX + LW / 2 + 0.12, y, LZ + 0.25), 0.03, 5)
                for y in (ly0 + 0.25, ly0 + 0.6, ly0 + 0.95)]
        k.add("wood", *lp_)
        # sandbags banked along the front wall, two courses
        bags = [K.sandbag((x, 0.13, -1.28), 0.6, yaw=(i % 2) * 8 - 4, segments=1) for i, x in enumerate((-0.96, -0.32, 0.32, 0.96))]
        bags += [K.sandbag((x, 0.36, -1.22), 0.58, yaw=4 - 4 * i, segments=1) for i, x in enumerate((-0.64, 0.0, 0.64))]
        k.add("sand", *bags)
    if stage == 1:
        # a flat thatch roof with a leafy clump
        k.add("thatch", K.rbox((LX, ly1 + 0.1, LZ), (LW + 0.3, 0.2, LD + 0.3), bevel=0.08, segments=1))
        k.add("leaf", K.ell((LX - 0.2, ly1 + 0.24, LZ - 0.1), (0.42, 0.2, 0.38), 10, 5),
              K.ell((LX + 0.35, ly1 + 0.22, LZ + 0.3), (0.3, 0.16, 0.28), 8, 4))

    k.add("metal", *[K.rod(a, b, 0.06, 8) for a, b in rifles])
    stocks = [K.rod(K.along(a, b, 0.35), K.along(a, b, 0.62), 0.085, 8) for a, b in rifles]  # forestocks
    k.add("wood", *stocks)
    a, b = rifles[0]
    k.add("metal", K.ring_along(b, K.along(b, a, -1), 0.065, 0.028, 8, 4), piece="muzzle", role="muzzle")

    brass = []
    if stage >= 2:
        # a peaked thatch roof on the lookout, brass-capped, a glowing signal brazier on its point
        ry = ly1 + 0.05
        k.add("thatch", K.rbox((LX, ry + 0.4, LZ), (LW + 0.4, 0.8, LD + 0.4), bevel=0.08, segments=1, taper=(0.12, 0.12)))
        tip = ry + 0.8
        brass += [K.rbox((LX, ry + 0.06, LZ), (LW + 0.46, 0.08, LD + 0.46), bevel=0.03),  # eave trim
                  K.rod((LX, tip - 0.05, LZ), (LX, tip + 0.15, LZ), 0.12, 8, top=1.0),
                  K.cyl((LX, tip + 0.2, LZ), 0.24, 0.16, 10, top=1.45, bevel=0.04)]  # brazier bowl
        k.add("glow", K.ell((LX, tip + 0.36, LZ), (0.3, 0.22, 0.3), 10, 5),
              K.rod((LX, tip + 0.4, LZ), (LX, tip + 0.68, LZ), 0.2, 8, top=0.1))
        # brass frames round the slits, upper and lower
        brass += [K.rbox((0, sy + dy, front_z(sy) - 0.02), (1.8, 0.06, 0.06), bevel=0) for dy in (-0.18, 0.18)]
        brass += [K.rbox((LX, lsy + dy, LZ - LD / 2 * 0.95 - 0.03), (1.2, 0.06, 0.06), bevel=0) for dy in (-0.16, 0.16)]
        # brass scopes on every rifle
        for a, b in rifles:
            lift = (0, 0.12, 0)
            pa = tuple(p + q for p, q in zip(K.along(a, b, 0.3), lift))
            pb = tuple(p + q for p, q in zip(K.along(a, b, 0.7), lift))
            brass.append(K.rod(pa, pb, 0.045, 8))
        # a big horned dino-skull trophy on the lookout's front
        sz, syk = LZ - LD / 2 - 0.12, ly0 + 0.2  # sits on the lower roof
        k.add("bone",
              K.ell((LX - 0.3, syk, sz), (0.3, 0.22, 0.2), 10, 6),
              K.ell((LX - 0.3, syk - 0.1, sz - 0.16), (0.2, 0.11, 0.13), 8, 4),
              K.rod((LX - 0.52, syk + 0.1, sz), (-1.35, syk + 0.45, sz - 0.1), 0.065, 6, top=0.2),
              K.rod((LX - 0.08, syk + 0.1, sz), (LX + 0.25, syk + 0.45, sz - 0.1), 0.065, 6, top=0.2))
        k.add("slit", *[K.ell((LX - 0.3 + s * 0.12, syk + 0.03, sz - 0.19), (0.065, 0.055, 0.03), 6, 4) for s in (-1, 1)])
    if brass:
        k.add("brass", *brass)

    colors = {
        "body": GREEN, "camo": CAMO, "slit": SLIT, "wood": K.WOOD, "thatch": THATCH, "leaf": LEAF,
        "canvas": K.CANVAS, "metal": K.METAL, "sand": K.SAND, "rope": K.ROPE, "dark": K.DARK,
        "brass": K.BRASS, "bone": BONE, "glow": (255, 160, 50),
    }
    return k.model("11d", colors, "SCOUT", stage)
