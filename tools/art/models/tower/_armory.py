"""ARMORY - Armory (TowerLook plate-steel grey): a plank floor, a dark plank back wall with a
shingle overhang and a rack of rifles, and a big steel plate shield on a stand at the front.
It doesn't shoot: no muzzle piece. The back wall stops short of the back-right corner (the
owner flag's). Authored from the base (y 0) in Roblox studs; front = -Z (_kit conventions).

Stage 0 (tiers 0-2): floor, back wall + overhang, three racked rifles, the shield on its stand.
Stage 1 (tier 3):    a fourth rifle, an anvil on a stump with a hammer, a
                     crate of spare plates, rivets on the shield.
Stage 2 (tier 5):    a brass-rimmed shield with a brass boss, pith helmets with brass bands on
                     wall pegs, a glowing forge brazier, a brass lantern on the wall.
"""

import importlib.util
import math
from pathlib import Path

_spec = importlib.util.spec_from_file_location("_kit", Path(__file__).with_name("_kit.py"))
K = importlib.util.module_from_spec(_spec)
_spec.loader.exec_module(K)

STEEL = (115, 125, 140)  # TowerLook.COLORS.ARMORY
WALL_Z, WALL_X0, WALL_X1, WALL_TOP = 1.28, -1.42, 0.95, 3.1


def build(lp, stage):
    k = K.Kit(lp)

    # plank floor
    k.add("deck", *[K.rbox((0, 0.07, z), (2.84, 0.12, 0.54), bevel=0.03) for z in (-1.14, -0.57, 0.0, 0.57, 1.14)])
    # back wall: upright planks, a top beam, a shingle overhang sloping forward
    n = 6
    w = (WALL_X1 - WALL_X0) / n
    planks = [K.rbox((WALL_X0 + w * (i + 0.5), (0.13 + WALL_TOP) / 2, WALL_Z), (w - 0.03, WALL_TOP - 0.13, 0.16), bevel=0.03)
              for i in range(n)]
    k.add("wall", *planks)
    mid = (WALL_X0 + WALL_X1) / 2
    k.add("dark", K.rbox((mid, WALL_TOP, WALL_Z), (WALL_X1 - WALL_X0 + 0.06, 0.18, 0.24), bevel=0.04),
          K.bar((mid, WALL_TOP + 0.15, WALL_Z + 0.12), (mid, 2.82, 0.55), WALL_X1 - WALL_X0 + 0.1, 0.08, bevel=0.03))

    # the rack: two rails and the rifles (stock on the floor, barrel up, leaning on the wall)
    rz = WALL_Z - 0.2
    k.add("dark", *[K.rbox((mid, y, rz), (WALL_X1 - WALL_X0 - 0.3, 0.12, 0.12), bevel=0.03) for y in (0.95, 2.25)])
    xs = (-1.05, -0.55, -0.05) if stage == 0 else (-1.1, -0.65, -0.2, 0.25)
    k.add("wood", *[K.rbox((x, 0.45, rz - 0.06), (0.16, 0.6, 0.24), bevel=0.05, taper=(0.8, 0.7)) for x in xs])
    k.add("metal", *[K.rod((x, 0.72, rz - 0.06), (x, 2.5, rz + 0.02), 0.045, 6) for x in xs])

    # the plate shield, tilted back on a wooden stand
    sc, tilt = (-0.15, 1.2, -0.95), 12
    k.add("body", K.rbox(sc, (1.5, 1.9, 0.14), bevel=0.25, segments=2, rot=(tilt, 0, 0)))
    k.add("wood", *[K.rod((sc[0] + sx * 0.5, 0.13, -0.35), (sc[0] + sx * 0.5, 1.7, -0.74), 0.06, 6) for sx in (-1, 1)],
          K.rod((sc[0] - 0.5, 0.6, -0.55), (sc[0] + 0.5, 0.6, -0.55), 0.05, 6))
    def face(x, y, z):
        """A point in the shield's frame (z < 0 = in front of its face) -> the tower's."""
        t = math.radians(tilt)
        return (sc[0] + x, sc[1] + y * math.cos(t) - z * math.sin(t), sc[2] + y * math.sin(t) + z * math.cos(t))

    boss = face(0, 0.05, -0.08)
    boss_obj = K.ell(boss, (0.24, 0.24, 0.12), 10, 6, rot=(tilt, 0, 0))

    brass = []
    if stage >= 1:
        # rivets round the shield's face
        rv = [K.ell(face(x, y, -0.08), (0.055, 0.055, 0.04), 6, 4)
              for x, y in ((-0.55, 0.72), (0.55, 0.72), (-0.55, -0.72), (0.55, -0.72), (0, 0.8), (0, -0.8), (-0.62, 0), (0.62, 0))]
        if stage >= 2:
            brass += rv
        else:
            k.add("metal", *rv)
        # an anvil on a stump, a hammer leaning on it
        ax, az = 0.85, -0.2
        k.add("wood", K.cyl((ax, 0.4, az), 0.3, 0.55, 12, bevel=0.04))
        k.add("metal", K.rbox((ax, 0.8, az), (0.3, 0.22, 0.6), bevel=0.04, taper=(1.0, 1.1)),
              K.rod((ax, 0.86, az - 0.3), (ax, 0.82, az - 0.5), 0.09, 8, top=0.2),
              K.rbox((ax + 0.22, 0.35, az - 0.45), (0.16, 0.12, 0.26), bevel=0.03))
        k.add("wood", K.rod((ax + 0.22, 0.35, az - 0.45), (ax + 0.3, 0.92, az - 0.3), 0.03, 5))
        # a crate of spare plates by the wall's open end
        core, frame = K.crate((0.65, 0.42, 0.75), (0.62, 0.56, 0.52), -6)
        k.add("wood", core)
        k.add("dark", *frame)
        k.add("body", *[K.rbox((0.6 + d, 0.78, 0.75), (0.07, 0.42, 0.4), bevel=0.03, rot=(0, 0, 10 + d * 40)) for d in (-0.12, 0.0, 0.12)])

    if stage >= 2:
        brass.append(boss_obj)
        boss_obj = None
        brass.append(K.rbox(face(0, 0, 0.03), (1.62, 2.02, 0.1), bevel=0.28, segments=2, rot=(tilt, 0, 0)))  # rim
        # pith helmets on pegs on the wall
        for x in (-0.95, -0.25):
            k.add("dark", K.rod((x, 2.7, WALL_Z - 0.08), (x, 2.7, WALL_Z - 0.3), 0.03, 5))
            k.add("helmet", K.ell((x, 2.72, WALL_Z - 0.32), (0.26, 0.22, 0.28), 10, 6),
                  K.cyl((x, 2.62, WALL_Z - 0.32), (0.34, 0.38), 0.04, 14, bevel=0.015))
            brass.append(K.ring((x, 2.67, WALL_Z - 0.32), 0.255, 0.03, 12, 4))
        # a forge brazier by the anvil
        fx, fz = 1.05, -1.05
        k.add("metal", K.cyl((fx, 0.45, fz), 0.3, 0.2, 12, top=1.25), *[K.rod((fx + dx, 0.0, fz + dz), (fx + dx * 0.6, 0.35, fz + dz * 0.6), 0.03, 5)
                                                                     for dx, dz in ((0.25, 0), (-0.14, 0.2), (-0.14, -0.2))])
        k.add("glow", *[K.ell((fx + dx, 0.58, fz + dz), (0.13, 0.1, 0.13), 8, 4) for dx, dz in ((0, 0), (0.12, 0.1), (-0.1, 0.12), (0.06, -0.13))])
        # a lantern on the wall
        brass += [K.cyl((0.6, 2.42, WALL_Z - 0.2), 0.09, 0.06, 8), K.rod((0.6, 2.45, WALL_Z - 0.2), (0.6, 2.45, WALL_Z - 0.06), 0.02, 5)]
        k.add("glow", K.ell((0.6, 2.27, WALL_Z - 0.2), (0.1, 0.13, 0.1), 8, 5), piece="lantern")
    if boss_obj is not None:
        k.add("metal", boss_obj)
    if brass:
        k.add("brass", *brass)

    colors = {
        "body": STEEL, "deck": (150, 112, 72), "wall": (92, 66, 44), "dark": (60, 44, 30), "wood": K.WOOD,
        "metal": (78, 82, 88), "helmet": (226, 214, 180), "brass": K.BRASS, "glow": (255, 140, 50),
    }
    return k.model("11d", colors, "ARMORY", stage)
