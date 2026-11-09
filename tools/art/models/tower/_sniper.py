"""SNIPER - Longshot Perch (TowerLook khaki): a tree stand on four log stilts with a ladder,
a plank deck railed on three sides, a khaki canvas roof and a long rifle over the front rail.
Authored from the base (y 0) in Roblox studs; front = -Z (_kit conventions).

Stage 0 (tiers 0-2): stilts with cross braces, ladder, deck, rails, canvas roof, one rifle.
Stage 1 (tier 3):    an armoured cabin (plank walls round the deck, a riveted steel plate across
                     the front), a heavy elephant gun with a muzzle brake and bipod, a camo net
                     over the whole roof, rope lashings on the stilts.
Stage 2 (tier 5):    a hipped roof with brass hip ribs crowned by a glowing brass lantern
                     cupola, brass trim on the eaves and cabin walls,
                     a brass-scoped gun, a horned trophy skull on the front plate.
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

    # stage 2 lowers the roof a little for its hipped roof and lantern cupola (the 5-stud cap)
    roof_y = ROOF_Y if stage < 2 else 4.02

    # rails (left, right, back) on short posts; the front stays open for the rifle
    rails = []
    for sx, sz in corners:
        x, z = stilt(sx, sz, DECK_Y)
        rails.append(K.rod((x, DECK_Y, z), (x, roof_y, z), 0.07, 6))  # roof posts
    if stage == 0:
        rails += [K.rod((sx * 1.2, DECK_Y + 0.5, -1.2), (sx * 1.2, DECK_Y + 0.5, 1.2), 0.07, 6) for sx in (-1, 1)]
        rails.append(K.rod((-1.2, DECK_Y + 0.5, 1.2), (1.2, DECK_Y + 0.5, 1.2), 0.07, 6))
    k.add("wood", *rails)

    if stage < 2:
        # canvas roof: a low pitched tent, ridge front to back
        k.add("body", K.rbox((0, ROOF_Y + 0.2, 0), (2.95, 0.4, 2.95), bevel=0.1, segments=2, taper=(0.12, 1.0)))
        k.add("dark", K.rod((0, ROOF_Y + 0.37, -1.45), (0, ROOF_Y + 0.37, 1.45), 0.05, 6))  # ridge pole
    else:
        # a hipped roof (four slopes) with a glowing lantern cupola on its peak
        k.add("body", K.rbox((0, roof_y + 0.26, 0), (2.98, 0.52, 2.98), bevel=0.08, segments=1, taper=(0.22, 0.22)))
        # brass ribs down the four hips
        hips = [K.rod((sx * 1.4, roof_y + 0.08, sz * 1.4), (sx * 0.3, roof_y + 0.53, sz * 0.3), 0.05, 6) for sx in (-1, 1) for sz in (-1, 1)]

    # the rifle over the front rail, angled down at the ground; its muzzle is the firing point
    # (stage 1+: a heavy elephant gun - a fatter barrel with a muzzle brake)
    gy = DECK_Y + (0.0 if stage < 2 else -0.14)  # stage 2: the gun sits lower, under the lower roof
    rear, tip = (0.35, gy + 0.62, 0.3), (0.4, gy + 0.42, -1.45 if stage == 0 else -1.4)
    br = 0.07 if stage == 0 else 0.1
    k.add("metal", K.rod(K.along(rear, tip, 0.35), tip, br, 8))
    k.add("wood", K.bar(rear, K.along(rear, tip, 0.45), 0.14 if stage == 0 else 0.2, 0.2 if stage == 0 else 0.26, bevel=0.05))  # stock
    k.add("metal", K.ring_along(tip, K.along(tip, rear, -1), br + 0.01, 0.03 if stage == 0 else 0.05, 8, 4), piece="muzzle", role="muzzle")
    scope_a = tuple(p + q for p, q in zip(K.along(rear, tip, 0.32), (0, 0.13 if stage == 0 else 0.17, 0)))
    scope_b = tuple(p + q for p, q in zip(K.along(rear, tip, 0.55), (0, 0.13 if stage == 0 else 0.17, 0)))
    scope = K.rod(scope_a, scope_b, (0.05, 0.065, 0.085)[stage], 8)

    brass = []
    if stage < 2:
        k.add("metal", scope)
    else:
        brass.append(scope)

    if stage >= 1:
        # an armoured cabin: plank walls round the deck's sides and back, a steel plate across
        # the front with a notch for the gun
        wall_h = 0.85 if stage == 1 else 0.55
        ph = wall_h - 0.09  # the front plates
        wy = DECK_Y + wall_h / 2
        walls = [K.rbox((sx * 1.24, wy, 0.0), (0.12, wall_h, 2.6), bevel=0.04) for sx in (-1, 1)]
        walls.append(K.rbox((0.0, wy, 1.24), (2.6, wall_h, 0.12), bevel=0.04))
        k.add("wall", *walls)
        k.add("dark", *[K.rbox((sx * 1.31, DECK_Y + y, 0.0), (0.04, 0.06, 2.62), bevel=0) for sx in (-1, 1) for y in (0.28, 0.58)[:1 + (stage == 1)]],
              *[K.rbox((0.0, DECK_Y + y, 1.31), (2.62, 0.06, 0.04), bevel=0) for y in (0.28, 0.58)[:1 + (stage == 1)]])
        plates = [K.rbox((-0.62, DECK_Y + ph / 2, -1.27), (1.2, ph, 0.1), bevel=0.05),
                  K.rbox((1.0, DECK_Y + ph / 2, -1.27), (0.6, ph, 0.1), bevel=0.05)]
        k.add("plate", *plates)
        k.add("metal", *[K.ell((x, DECK_Y + y, -1.33), (0.045, 0.045, 0.03), 6, 3)
                         for x in (-1.1, -0.15, 0.82, 1.18) for y in (0.15, ph - 0.14)])
        # rope lashings where the braces meet the stilts
        ropes = []
        for sx, sz in corners:
            for y in (2.9,):
                x, z = stilt(sx, sz, y)
                ropes.append(K.ring((x, y, z), 0.14, 0.035, 8, 4))
        k.add("rope", *ropes)
        # a bipod under the barrel
        bip = K.along(rear, tip, 0.72)
        k.add("metal", *[K.rod(bip, (bip[0] + d, DECK_Y, bip[2] - 0.12), 0.03, 6) for d in (-0.15, 0.15)])

    if stage == 1:
        # a camo net thrown over the whole roof: big leafy patches down both slopes
        k.add("leaf", *[K.ell((sx * x, roof_at(x) + 0.03, z), (0.42, 0.07, r), 8, 4, rot=(0, 0, -sx * SLOPE))
                        for sx in (-1, 1) for x, z, r in ((0.62, -0.85, 0.5), (0.85, 0.1, 0.45), (0.6, 0.95, 0.42))])
        k.add("rope", *[K.rod((sx * 1.45, ROOF_Y + 0.02, z), (0, ROOF_Y + 0.41, z), 0.03, 4) for sx in (-1, 1) for z in (-0.4, 0.55)])

    if stage >= 2:
        # the lantern cupola: brass posts and cap round a glowing core, the crown
        brass += hips
        cy = roof_y + 0.5
        k.add("glow", K.rbox((0, cy + 0.22, 0), (0.7, 0.4, 0.7), bevel=0.08, taper=(0.85, 0.85)), piece="lantern")
        brass += [K.rbox((0, cy + 0.02, 0), (0.86, 0.06, 0.86), bevel=0),
                  *[K.bar((-0.38, cy + 0.38, sz * 0.38), (0.38, cy + 0.38, sz * 0.38), 0.07, 0.07, bevel=0) for sz in (-1, 1)],
                  *[K.bar((sx * 0.38, cy + 0.38, -0.38), (sx * 0.38, cy + 0.38, 0.38), 0.07, 0.07, bevel=0) for sx in (-1, 1)]]
        brass += [K.rod((sx * 0.37, cy, sz * 0.37), (sx * 0.37, cy + 0.36, sz * 0.37), 0.045, 5) for sx in (-1, 1) for sz in (-1, 1)]
        # brass eave trim round the roof, brass caps on the cabin walls
        e = 1.43
        brass += [K.rod((-e, roof_y + 0.03, sz * e), (e, roof_y + 0.03, sz * e), 0.05, 6) for sz in (-1, 1)]
        brass += [K.rod((sx * e, roof_y + 0.03, -e), (sx * e, roof_y + 0.03, e), 0.05, 6) for sx in (-1, 1)]
        brass += [K.rbox((sx * 1.24, DECK_Y + wall_h + 0.02, 0.0), (0.18, 0.06, 2.64), bevel=0) for sx in (-1, 1)]
        brass.append(K.rbox((0.0, DECK_Y + wall_h + 0.02, 1.24), (2.64, 0.06, 0.18), bevel=0))
        brass += [K.rbox((x, DECK_Y + ph + 0.02, -1.27), (w + 0.04, 0.06, 0.14), bevel=0) for x, w in ((-0.62, 1.2), (1.0, 0.6))]
        # a horned trophy skull on the front plate
        k.add("bone",
              K.ell((-0.62, DECK_Y + 0.26, -1.36), (0.26, 0.19, 0.08), 10, 6),
              K.ell((-0.62, DECK_Y + 0.14, -1.4), (0.16, 0.09, 0.06), 8, 4),
              K.rod((-0.8, DECK_Y + 0.34, -1.38), (-1.15, DECK_Y + 0.58, -1.42), 0.05, 6, top=0.2),
              K.rod((-0.44, DECK_Y + 0.34, -1.38), (-0.09, DECK_Y + 0.58, -1.42), 0.05, 6, top=0.2))
    if brass:
        k.add("brass", *brass)

    colors = {
        "body": KHAKI, "wood": K.WOOD, "dark": K.DARK, "deck": (150, 112, 72), "metal": K.METAL,
        "canvas": (150, 140, 96), "wall": (112, 82, 52), "plate": (96, 102, 108), "leaf": (88, 128, 60), "bone": (228, 218, 192), "sand": K.SAND, "rope": K.ROPE, "brass": K.BRASS, "glow": (255, 160, 50),
    }
    return k.model("11d", colors, "SNIPER", stage)
