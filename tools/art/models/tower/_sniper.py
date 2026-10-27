"""SNIPER - Longshot Perch (TowerLook khaki): a tree stand on four log stilts with a ladder,
a plank deck railed on three sides, a khaki canvas roof and a long rifle over the front rail.
Authored from the base (y 0) in Roblox studs; front = -Z (_kit conventions).

Stage 0 (tiers 0-2): stilts with cross braces, ladder, deck, rails, canvas roof, one rifle.
Stage 1 (tier 3):    canvas side screens on the rails, sandbags on the deck's front edge, rope
                     lashings on the stilts, an ammo box, a bipod under the rifle.
Stage 2 (tier 5):    a brass spotting telescope on a tripod, a brass-scoped rifle, brass bands
                     on the stilts, a brass roof finial, a glowing lantern under the roof.
"""

import importlib.util
from pathlib import Path

_spec = importlib.util.spec_from_file_location("_kit", Path(__file__).with_name("_kit.py"))
K = importlib.util.module_from_spec(_spec)
_spec.loader.exec_module(K)

KHAKI = (200, 180, 130)  # TowerLook.COLORS.SNIPER
DECK_Y = 3.45  # top of the deck
ROOF_Y = 4.55  # bottom of the roof


def stilt(sx, sz, y):
    """Where a stilt is at height y (they splay a little toward the ground)."""
    t = y / DECK_Y
    return sx * (1.32 - 0.14 * t), sz * (1.32 - 0.14 * t)


SLOPE = 17.2  # roof slope, degrees: 0.4 rise over (1.475 - 0.18) run


def roof_at(x):
    """The roof's surface height at |x| (the ridge runs front to back at x 0)."""
    return ROOF_Y + 0.4 * (1 - (abs(x) - 0.18) / (1.475 - 0.18))


def build(lp, stage):
    k = K.Kit(lp)
    corners = [(sx, sz) for sx in (-1, 1) for sz in (-1, 1)]

    # stilts (logs) and cross braces on the left, right and back
    logs = []
    for sx, sz in corners:
        x0, z0 = stilt(sx, sz, 0)
        x1, z1 = stilt(sx, sz, DECK_Y)
        logs.append(K.rod((x0, 0, z0), (x1, DECK_Y - 0.05, z1), 0.12, 8))
    k.add("wood", *logs)
    braces = []
    for (ax, az), (bx, bz) in (((-1, -1), (-1, 1)), ((1, -1), (1, 1)), ((-1, 1), (1, 1))):
        pa, pb = stilt(ax, az, 0.5), stilt(bx, bz, 2.9)
        qa, qb = stilt(bx, bz, 0.5), stilt(ax, az, 2.9)
        braces.append(K.bar((pa[0], 0.5, pa[1]), (pb[0], 2.9, pb[1]), 0.14, 0.08))
        braces.append(K.bar((qa[0], 0.5, qa[1]), (qb[0], 2.9, qb[1]), 0.14, 0.08))
    # ladder up the front, off-centre to the left
    for x in (-0.6, -0.05):
        braces.append(K.rod((x, 0, -1.42), (x, DECK_Y, -1.32), 0.05, 6))
    for i in range(6):
        y = 0.45 + i * 0.5
        z = -1.42 + 0.1 * y / DECK_Y
        braces.append(K.rod((-0.6, y, z), (-0.05, y, z), 0.04, 6))
    k.add("dark", *braces)

    # deck: planks running front to back, with a beam under the front and back edges
    planks = [K.rbox((x, DECK_Y - 0.09, 0), (0.52, 0.16, 2.8), bevel=0.04) for x in (-1.12, -0.56, 0.0, 0.56, 1.12)]
    planks += [K.rbox((0, DECK_Y - 0.24, z), (2.8, 0.16, 0.18), bevel=0.04) for z in (-1.2, 1.2)]
    k.add("deck", *planks)

    # rails (left, right, back) on short posts; the front stays open for the rifle
    rails = []
    for sx, sz in corners:
        x, z = stilt(sx, sz, DECK_Y)
        rails.append(K.rod((x, DECK_Y, z), (x, ROOF_Y, z), 0.07, 6))  # roof posts
    rails += [K.rod((sx * 1.2, DECK_Y + 0.5, -1.2), (sx * 1.2, DECK_Y + 0.5, 1.2), 0.07, 6) for sx in (-1, 1)]
    rails.append(K.rod((-1.2, DECK_Y + 0.5, 1.2), (1.2, DECK_Y + 0.5, 1.2), 0.07, 6))
    k.add("wood", *rails)

    # canvas roof: a low pitched tent, ridge front to back
    k.add("body", K.rbox((0, ROOF_Y + 0.2, 0), (2.95, 0.4, 2.95), bevel=0.1, segments=2, taper=(0.12, 1.0)))
    k.add("dark", K.rod((0, ROOF_Y + 0.37, -1.45), (0, ROOF_Y + 0.37, 1.45), 0.05, 6))  # ridge pole

    # the rifle over the front rail, angled down at the ground; its muzzle is the firing point
    rear, tip = (0.35, DECK_Y + 0.62, 0.3), (0.4, DECK_Y + 0.42, -1.45)
    k.add("metal", K.rod(K.along(rear, tip, 0.35), tip, 0.07, 8))
    k.add("wood", K.bar(rear, K.along(rear, tip, 0.45), 0.14, 0.2, bevel=0.05))  # stock
    k.add("metal", K.ring_along(tip, K.along(tip, rear, -1), 0.08, 0.03, 8, 4), piece="muzzle", role="muzzle")
    scope_a = tuple(p + q for p, q in zip(K.along(rear, tip, 0.32), (0, 0.13, 0)))
    scope_b = tuple(p + q for p, q in zip(K.along(rear, tip, 0.55), (0, 0.13, 0)))
    scope = K.rod(scope_a, scope_b, 0.05 if stage < 2 else 0.065, 8)

    brass = []
    if stage < 2:
        k.add("metal", scope)
    else:
        brass.append(scope)

    if stage >= 1:
        # canvas screens on the side and back rails
        screens = [K.rbox((sx * 1.22, DECK_Y + 0.3, 0.05), (0.06, 0.5, 2.3), bevel=0.02) for sx in (-1, 1)]
        screens.append(K.rbox((-0.2, DECK_Y + 0.3, 1.22), (1.9, 0.5, 0.06), bevel=0.02))
        k.add("canvas", *screens)
        # sandbags along the deck's front edge either side of the rifle
        k.add("sand", *[K.sandbag((x, DECK_Y + 0.12, -1.18), 0.55, yaw=y) for x, y in ((-0.85, 4), (-0.32, -3), (0.95, 3))])
        # rope lashings where the braces meet the stilts
        ropes = []
        for sx, sz in corners:
            for y in (0.5, 2.9):
                x, z = stilt(sx, sz, y)
                ropes.append(K.ring((x, y, z), 0.14, 0.035, 8, 4))
        k.add("rope", *ropes)
        # leafy camo patches tied onto both roof slopes (they read from the top-down camera)
        k.add("leaf", *[K.ell((sx * x, roof_at(x) + 0.03, z), (0.36, 0.06, r), 8, 4, rot=(0, 0, -sx * SLOPE))
                        for sx in (-1, 1) for x, z, r in ((0.75, -0.7, 0.42), (0.95, 0.55, 0.36))])
        # an ammo box on the deck, a bipod under the barrel
        k.add("dark", K.rbox((-0.6, DECK_Y + 0.15, 0.55), (0.5, 0.3, 0.35), bevel=0.05))
        bip = K.along(rear, tip, 0.72)
        k.add("metal", *[K.rod(bip, (bip[0] + d, DECK_Y, bip[2] - 0.12), 0.025, 6) for d in (-0.15, 0.15)])

    if stage >= 2:
        # brass spotting telescope on a tripod at the back-left of the deck
        base = (-0.65, DECK_Y + 0.55, 0.45)
        k.add("dark", *[K.rod(base, (base[0] + dx, DECK_Y, base[2] + dz), 0.025, 5)
                        for dx, dz in ((-0.2, 0.1), (0.2, 0.1), (0, -0.2))])
        brass.append(K.rod((base[0], base[1] + 0.05, base[2] + 0.25), (base[0] + 0.05, base[1] + 0.2, base[2] - 0.5), 0.07, 8, top=0.7))
        # brass bands on the stilts, a finial on the ridge
        for sx, sz in corners:
            for y in (1.7,):
                x, z = stilt(sx, sz, y)
                brass.append(K.ring((x, y, z), 0.125, 0.035, 10, 4))
        brass.append(K.ell((0, ROOF_Y + 0.33, -1.3), (0.1, 0.1, 0.1), 8, 5))
        # brass trim along the eaves and the ridge
        brass += [K.rod((sx * 1.44, ROOF_Y + 0.04, -1.45), (sx * 1.44, ROOF_Y + 0.04, 1.45), 0.045, 6) for sx in (-1, 1)]
        brass.append(K.rod((0, ROOF_Y + 0.39, -1.42), (0, ROOF_Y + 0.39, 1.42), 0.055, 6))
        # a horned trophy skull on the front gable
        k.add("bone",
              K.ell((0, ROOF_Y + 0.16, -1.42), (0.24, 0.17, 0.07), 10, 6),
              K.ell((0, ROOF_Y + 0.04, -1.44), (0.15, 0.08, 0.05), 8, 4),
              K.rod((-0.17, ROOF_Y + 0.22, -1.44), (-0.46, ROOF_Y + 0.42, -1.45), 0.045, 6, top=0.2),
              K.rod((0.17, ROOF_Y + 0.22, -1.44), (0.46, ROOF_Y + 0.42, -1.45), 0.045, 6, top=0.2))
        # a lantern hanging under the roof at the front-left post
        lx, lz = stilt(-1, -1, DECK_Y)
        lx, lz = lx + 0.2, lz + 0.2
        brass += [K.cyl((lx, ROOF_Y - 0.12, lz), 0.09, 0.06, 8), K.rod((lx, ROOF_Y - 0.1, lz), (lx, ROOF_Y, lz), 0.015, 5)]
        k.add("glow", K.ell((lx, ROOF_Y - 0.3, lz), (0.1, 0.13, 0.1), 8, 5))
    if brass:
        k.add("brass", *brass)

    colors = {
        "body": KHAKI, "wood": K.WOOD, "dark": K.DARK, "deck": (150, 112, 72), "metal": K.METAL,
        "canvas": (150, 140, 96), "leaf": (88, 128, 60), "bone": (228, 218, 192), "sand": K.SAND, "rope": K.ROPE, "brass": K.BRASS, "glow": K.GLOW,
    }
    return k.model("11d", colors, "SNIPER", stage)
