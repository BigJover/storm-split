"""SCOUT - Hunting Blind (TowerLook camo green): a low canvas hide with viewing slits all
round, a thatch-and-leaf roof, a canvas awning over the front slit and a rifle poking out of
it. Authored from the base (y 0) in Roblox studs; front = -Z (_kit conventions).

Stage 0 (tiers 0-2): the hide, camo patches, slits, corner poles, awning, thatch, one rifle.
Stage 1 (tier 3):    sandbags banked along the front, a second rifle out of the left slit,
                     branch bundles lashed to the front corners, a roof hatch with a periscope,
                     a coil of rope.
Stage 2 (tier 5):    brass-framed slits, brass scopes on three rifles, a horned dino-skull
                     trophy on the roof's front edge, a glowing lantern on the front-left pole.
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
    clumps = ((-0.62, -0.55, 0.46), (0.55, -0.45, 0.42), (-0.6, 0.65, 0.4), (0.15, 0.15, 0.36))
    k.add("leaf", *[K.ell((x, roof_y + 0.14, Z0 + z), (s, s * 0.5, s * 0.85), 10, 5) for x, z, s in clumps])

    # rifles poking out of the slits; the first one's muzzle is the firing point
    rifles = [((0.42, sy, front_z(sy) + 0.4), (0.42, sy + 0.03, -1.4))]
    if stage >= 1:
        rifles.append(((-side_x(sy) + 0.4, sy, Z0 - 0.25), (-1.42, sy + 0.03, Z0 - 0.25)))
    if stage >= 2:
        rifles.append(((-0.42, sy, front_z(sy) + 0.4), (-0.42, sy + 0.03, -1.4)))
    k.add("metal", *[K.rod(a, b, 0.06, 8) for a, b in rifles])
    stocks = [K.rod(K.along(a, b, 0.35), K.along(a, b, 0.62), 0.085, 8) for a, b in rifles]  # forestocks
    k.add("wood", *stocks)
    a, b = rifles[0]
    k.add("metal", K.ring_along(b, K.along(b, a, -1), 0.065, 0.028, 8, 4), piece="muzzle", role="muzzle")

    brass = []
    if stage >= 1:
        # sandbags banked along the front wall, two courses
        bags = [K.sandbag((x, 0.13, -1.28), 0.6, yaw=(i % 2) * 8 - 4) for i, x in enumerate((-0.96, -0.32, 0.32, 0.96))]
        bags += [K.sandbag((x, 0.36, -1.22), 0.58, yaw=4 - 4 * i) for i, x in enumerate((-0.64, 0.0, 0.64))]
        k.add("sand", *bags)
        # branch bundles lashed to the front corners, rope ties
        sticks, tufts, ties = [], [], []
        for sx in (-1, 1):
            for dx in (-0.07, 0.07):
                sticks.append(K.rod((sx * 1.38 + dx, 0.02, -1.0), (sx * 1.2 + dx, 2.5, -0.92), 0.05, 6))
            tufts.append(K.ell((sx * 1.2, 2.5, -0.92), (0.24, 0.2, 0.22), 8, 5))
            ties.append(K.ring((sx * 1.29, 1.2, -0.96), 0.12, 0.03, 8, 4))
        k.add("wood", *sticks)
        k.add("leaf", *tufts)
        # a coil of rope hung on the left wall
        ties.append(K.ring((-side_x(0.9) - 0.03, 0.9, Z0 + 0.55), 0.22, 0.05, 12, 5, rot=(0, 0, 90)))
        k.add("rope", *ties)
        # roof hatch with a periscope
        k.add("dark", K.rbox((0.45, roof_y + 0.2, Z0 + 0.1), (0.7, 0.22, 0.7), bevel=0.07))
        k.add("metal", K.rod((0.45, roof_y + 0.28, Z0 + 0.1), (0.45, roof_y + 0.72, Z0 + 0.1), 0.07, 8),
              K.rbox((0.45, roof_y + 0.74, Z0 + 0.02), (0.18, 0.18, 0.3), bevel=0.05))

    if stage >= 2:
        # brass frames round the slits
        for zf, w in ((front_z(sy) - 0.02, 1.8), (back_z(sy) + 0.02, 1.4)):
            brass += [K.rbox((0, sy + dy, zf), (w, 0.06, 0.06), bevel=0.02) for dy in (-0.18, 0.18)]
        for sx in (-1, 1):
            brass += [K.rbox((sx * (side_x(sy) + 0.02), sy + dy, Z0), (0.06, 0.06, 1.4), bevel=0.02) for dy in (-0.18, 0.18)]
        # brass scopes on every rifle
        for a, b in rifles:
            lift = (0, 0.12, 0)
            pa = tuple(p + q for p, q in zip(K.along(a, b, 0.3), lift))
            pb = tuple(p + q for p, q in zip(K.along(a, b, 0.7), lift))
            brass.append(K.rod(pa, pb, 0.045, 8))
        brass.append(K.ring((0.45, roof_y + 0.5, Z0 + 0.1), 0.08, 0.025, 8, 4))  # periscope band
        # horned skull trophy on the roof's front edge
        sz = front_z(H) - 0.02
        k.add("bone",
              K.ell((0, roof_y + 0.22, sz), (0.28, 0.2, 0.2), 10, 6),
              K.ell((0, roof_y + 0.14, sz - 0.14), (0.18, 0.1, 0.12), 8, 4),
              K.rod((-0.2, roof_y + 0.32, sz), (-0.5, roof_y + 0.6, sz - 0.08), 0.055, 6, top=0.2),
              K.rod((0.2, roof_y + 0.32, sz), (0.5, roof_y + 0.6, sz - 0.08), 0.055, 6, top=0.2))
        k.add("slit", *[K.ell((s * 0.11, roof_y + 0.25, sz - 0.18), (0.06, 0.05, 0.03), 6, 4) for s in (-1, 1)])
        # a lantern on the front-left pole (the flag owns the back-right)
        lx, lz = -side_x(1.9) - 0.12, front_z(1.9) + 0.02
        brass += [K.cyl((lx, 2.02, lz), 0.1, 0.06, 8), K.rod((lx, 2.05, lz), (lx + 0.12, 2.05, lz + 0.05), 0.02, 6)]
        k.add("glow", K.ell((lx, 1.86, lz), (0.11, 0.14, 0.11), 8, 5))
    if brass:
        k.add("brass", *brass)

    colors = {
        "body": GREEN, "camo": CAMO, "slit": SLIT, "wood": K.WOOD, "thatch": THATCH, "leaf": LEAF,
        "canvas": K.CANVAS, "metal": K.METAL, "sand": K.SAND, "rope": K.ROPE, "dark": K.DARK,
        "brass": K.BRASS, "bone": BONE, "glow": K.GLOW,
    }
    return k.model("11d", colors, "SCOUT", stage)
