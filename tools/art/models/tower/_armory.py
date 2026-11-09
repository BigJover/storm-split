"""ARMORY - Armory (TowerLook plate-steel grey): a plank floor, a dark plank back wall with a
shingle overhang and a rack of rifles, and a big steel plate shield on a stand at the front.
It doesn't shoot: no muzzle piece. The back wall stops short of the back-right corner (the
owner flag's). Authored from the base (y 0) in Roblox studs; front = -Z (_kit conventions).

Stage 0 (tiers 0-2): floor, back wall + overhang, three racked rifles, the shield on its stand.
Stage 1 (tier 3):    a roofed shed (a taller back wall, a side wall, front posts and a deep
                     shingle roof), a wall of three riveted plate shields across the front, a
                     fourth rifle.
Stage 2 (tier 5):    a big round crest with crossed rifles and a glowing boss on the roof (the crown), brass rims,
                     bosses and rivets on the shields, a stone forge of glowing coals under a
                     brass hood and chimney, a lantern.
"""

import importlib.util
import math
from pathlib import Path

_spec = importlib.util.spec_from_file_location("_kit", Path(__file__).with_name("_kit.py"))
K = importlib.util.module_from_spec(_spec)
_spec.loader.exec_module(K)

STEEL = (115, 125, 140)  # TowerLook.COLORS.ARMORY
WALL_Z, WALL_X0, WALL_X1, WALL_TOP = 1.28, -1.42, 0.95, 3.1


def shield_point(sc, tilt, yaw, x, y, z):
    """A point in a shield's frame (x across, y up its face, z < 0 = in front) -> the tower's."""
    t, w = math.radians(tilt), math.radians(yaw)
    y2, z2 = y * math.cos(t) - z * math.sin(t), y * math.sin(t) + z * math.cos(t)
    x3, z3 = x * math.cos(w) + z2 * math.sin(w), -x * math.sin(w) + z2 * math.cos(w)
    return (sc[0] + x3, sc[1] + y2, sc[2] + z3)


def build(lp, stage):
    k = K.Kit(lp)
    big = stage >= 1  # stage 1+: a roofed shed (side wall, deep roof) and a wall of shields
    wall_top = WALL_TOP if not big else 3.6

    # plank floor
    k.add("deck", *[K.rbox((0, 0.07, z), (2.84, 0.12, 0.54), bevel=0.03 if not big else 0.0) for z in (-1.14, -0.57, 0.0, 0.57, 1.14)])
    # back wall: upright planks, a top beam, a shingle overhang sloping forward
    n = 6
    w = (WALL_X1 - WALL_X0) / n
    planks = [K.rbox((WALL_X0 + w * (i + 0.5), (0.13 + wall_top) / 2, WALL_Z), (w - 0.03, wall_top - 0.13, 0.16), bevel=0.03)
              for i in range(n)]
    mid = (WALL_X0 + WALL_X1) / 2
    if not big:
        k.add("wall", *planks)
        k.add("dark", K.rbox((mid, wall_top, WALL_Z), (WALL_X1 - WALL_X0 + 0.06, 0.18, 0.24), bevel=0.04),
              K.bar((mid, wall_top + 0.15, WALL_Z + 0.12), (mid, 2.82, 0.55), WALL_X1 - WALL_X0 + 0.1, 0.08, bevel=0.03))
    else:
        # a side wall on the left, posts at the front corners, a deep shingle roof over all of it
        def roof_y(z):  # the roof's underside over z (it slopes from the wall top down to the front)
            return wall_top + 0.06 + (2.72 - wall_top - 0.06) * (WALL_Z + 0.14 - z) / (WALL_Z + 0.14 + 0.55)

        for z in (-0.05, 0.45, 0.95):
            top = roof_y(z - 0.25) - 0.03  # its front edge, where the roof is lowest
            planks.append(K.rbox((-1.36, (0.13 + top) / 2, z), (0.14, top - 0.13, 0.5), bevel=0.03))
        k.add("wall", *planks)
        k.add("dark", K.rbox((mid, wall_top, WALL_Z), (WALL_X1 - WALL_X0 + 0.06, 0.18, 0.24), bevel=0.04),
              *[K.rod((x, 0.13, -0.3), (x, 2.75, -0.3), 0.08, 6) for x in (-1.36, 0.88)],
              K.rbox(((-1.36 + 0.88) / 2, 2.78, -0.3), (0.88 + 1.36 + 0.12, 0.16, 0.16), bevel=0.03))
        k.add("roof", K.bar((mid, wall_top + 0.12, WALL_Z + 0.14), (mid, 2.78, -0.55), WALL_X1 - WALL_X0 + 0.16, 0.12, bevel=0.03))

    # the rack: two rails and the rifles (stock on the floor, barrel up, leaning on the wall)
    rz = WALL_Z - 0.2
    k.add("dark", *[K.rbox((mid, y, rz), (WALL_X1 - WALL_X0 - 0.3, 0.12, 0.12), bevel=0.03) for y in (0.95, 2.25)])
    xs = (-1.05, -0.55, -0.05) if stage == 0 else (-1.1, -0.65, -0.2, 0.25)
    k.add("wood", *[K.rbox((x, 0.45, rz - 0.06), (0.16, 0.6, 0.24), bevel=0.05, taper=(0.8, 0.7)) for x in xs])
    k.add("metal", *[K.rod((x, 0.72, rz - 0.06), (x, 2.5, rz + 0.02), 0.045, 6) for x in xs])

    brass = []
    if not big:
        # the plate shield, tilted back on a wooden stand
        sc, tilt = (-0.15, 1.2, -0.95), 12
        k.add("body", K.rbox(sc, (1.5, 1.9, 0.14), bevel=0.25, segments=2, rot=(tilt, 0, 0)))
        k.add("wood", *[K.rod((sc[0] + sx * 0.5, 0.13, -0.35), (sc[0] + sx * 0.5, 1.7, -0.74), 0.06, 6) for sx in (-1, 1)],
              K.rod((sc[0] - 0.5, 0.6, -0.55), (sc[0] + 0.5, 0.6, -0.55), 0.05, 6))
        k.add("metal", K.ell(shield_point(sc, tilt, 0, 0, 0.05, -0.08), (0.24, 0.24, 0.12), 10, 6, rot=(tilt, 0, 0)))
    else:
        # a wall of three big plate shields across the front, the middle one tallest
        shields = (((-0.2, 1.25, -1.0), 1.3, 2.2, 0), ((-0.97, 1.0, -0.82), 0.85, 1.7, 30), ((0.72, 1.0, -0.88), 0.85, 1.7, -30))
        plates, bosses, rivets, rims = [], [], [], []
        for sc, sw, sh, yaw in shields:
            tilt = 10
            plates.append(K.rbox(sc, (sw, sh, 0.14), bevel=0.2, segments=1, rot=(tilt, yaw, 0)))
            bosses.append(K.ell(shield_point(sc, tilt, yaw, 0, 0.05, -0.08), (0.2 * sw / 0.85, 0.2 * sw / 0.85, 0.1), 8, 4, rot=(tilt, yaw, 0)))
            rivets += [K.ell(shield_point(sc, tilt, yaw, x * sw / 2 * 0.75, y * sh / 2 * 0.8, -0.08), (0.05, 0.05, 0.035), 6, 3)
                       for x, y in ((-1, 1), (1, 1), (-1, -1), (1, -1))]
            if stage >= 2:
                rims.append(K.rbox(shield_point(sc, tilt, yaw, 0, 0, 0.03), (sw + 0.12, sh + 0.12, 0.08), bevel=0.2, segments=1, rot=(tilt, yaw, 0)))
        k.add("body", *plates)
        k.add("wood", K.rod((-1.1, 0.75, -0.45), (0.8, 0.75, -0.5), 0.06, 6),
              *[K.rod((x, 0.13, -0.4), (x, 1.9, -0.62), 0.06, 6) for x in (-0.65, 0.25)])
        if stage >= 2:
            brass += bosses + rivets + rims
        else:
            k.add("metal", *bosses, *rivets)

    if stage >= 2:
        # the crest on the roof: a big round brass-rimmed shield with crossed rifles - the crown
        cc = (mid, wall_top + 0.72, WALL_Z - 0.05)
        k.add("body", K.cyl(cc, 0.62, 0.12, 14, rot=(90, 0, 0), bevel=0.03))
        brass += [K.ring(cc, 0.62, 0.07, 14, 4, rot=(90, 0, 0)), K.ring((cc[0], cc[1], cc[2] - 0.07), 0.27, 0.05, 12, 3, rot=(90, 0, 0))]
        k.add("glow", K.ell((cc[0], cc[1], cc[2] - 0.09), (0.25, 0.25, 0.1), 10, 4), piece="gem")  # a glowing boss
        k.add("metal", *[K.rod((cc[0] - sx * 0.8, cc[1] - 0.6, cc[2] - 0.12), (cc[0] + sx * 0.8, cc[1] + 0.6, cc[2] - 0.12), 0.05, 6) for sx in (-1, 1)])
        k.add("wood", *[K.rod((cc[0] - sx * 0.8, cc[1] - 0.6, cc[2] - 0.12), (cc[0] - sx * 0.5, cc[1] - 0.38, cc[2] - 0.12), 0.08, 6) for sx in (-1, 1)])
        # a stone forge at the front-right, its coals glowing, a brass-hooded chimney
        fx, fz = 1.05, -0.95
        k.add("stone", K.rbox((fx, 0.4, fz), (0.8, 0.7, 0.8), bevel=0.08, taper=(0.9, 0.9)))
        k.add("glow", K.rbox((fx, 0.76, fz), (0.6, 0.08, 0.6), bevel=0.03),
              *[K.ell((fx + dx, 0.82, fz + dz), (0.15, 0.1, 0.15), 6, 3) for dx, dz in ((-0.12, -0.1), (0.13, 0.05), (-0.05, 0.15))], piece="coals")
        brass += [K.rbox((fx + 0.05, 1.55, fz + 0.15), (0.6, 0.3, 0.6), bevel=0.04, taper=(0.4, 0.4)),
                  *[K.rod((fx + sx * 0.33, 0.75, fz + sz * 0.33), (fx + sx * 0.25, 1.42, fz + sz * 0.25 + 0.1), 0.03, 4) for sx in (-1, 1) for sz in (-1, 1)]]
        k.add("metal", K.rod((fx + 0.05, 1.68, fz + 0.15), (fx + 0.05, 2.6, fz + 0.15), 0.12, 8))
        # a lantern under the roof
        brass += [K.cyl((0.6, 2.42, WALL_Z - 0.2), 0.09, 0.06, 8), K.rod((0.6, 2.45, WALL_Z - 0.2), (0.6, 2.45, WALL_Z - 0.06), 0.02, 5)]
        k.add("glow", K.ell((0.6, 2.27, WALL_Z - 0.2), (0.12, 0.15, 0.12), 8, 4), piece="lantern")
    if brass:
        k.add("brass", *brass)

    colors = {
        "body": STEEL, "deck": (150, 112, 72), "wall": (92, 66, 44), "dark": (60, 44, 30), "wood": K.WOOD,
        "metal": (78, 82, 88), "roof": (84, 70, 58), "stone": (128, 124, 116), "brass": K.BRASS, "glow": (255, 140, 50),
    }
    return k.model("11d", colors, "ARMORY", stage)
