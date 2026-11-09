"""METEOR - Meteor Beacon (TowerLook radio-dish steel blue; a 4x tower): a radio mast on an
octagonal stone footing, a big tracking dish on a yoke pointed at the sky, a red flare cage on
the mast top, a signal console and a meteorite fragment on a plinth. Authored from the base
(y 0) in Roblox studs; front = -Z (_kit conventions). Premium: dish, console and the fragment
are there from stage 0.

Stage 0 (tiers 0-2): the footing and step, the mast with braces, the dish (concave face, feed
                     horn on three struts) on its yoke, the flare cage, the console, the
                     meteorite on its plinth.
Stage 1 (tier 3):    a BIGGER DISH and a SECOND DISH - the tracking dish grows much wider and rides
                     higher on a heavier yoke, and a second dish stands on its own braced pylon
                     at the back-left; an aerial array on the mast.
Stage 2 (tier 5):    both dishes brass-rimmed, a brass gimbal ring, and the crown: a brass cage on
                     the mast top holding a big glowing beacon orb; the meteorite splits into a
                     glowing crystal cluster in a brass cradle; a brass band and glowing landing
                     lights round the footing; brass console trim.
"""

import importlib.util
import math
from pathlib import Path

_spec = importlib.util.spec_from_file_location("_kit", Path(__file__).with_name("_kit.py"))
K = importlib.util.module_from_spec(_spec)
_spec.loader.exec_module(K)

BLUE = (70, 95, 130)  # TowerLook.COLORS.METEOR
STONE = (100, 96, 90)
STEEL = (78, 82, 88)
DISH_IN = (150, 162, 176)
FLARE = (150, 52, 40)  # the flare pot, unlit (stage 2 lights it)
ROCK = (52, 46, 44)
CRACK = (120, 60, 34)
GLOW = (255, 90, 50)  # TowerLook METEOR flare

MX, MZ, MTOP = 0.25, 0.3, 4.15  # the mast


def add(a, b, s=1.0):
    return tuple(x + y * s for x, y in zip(a, b))


def build(lp, stage):
    k = K.Kit(lp)
    hot = stage >= 2
    lean = stage >= 1
    DR = (0.92, 1.18, 1.18)[stage]  # the dish's radius

    # octagonal stone footing and a step at the front
    k.add("stone", K.cyl((0, 0.17, 0), 1.42, 0.34, 8, bevel=0.06, rot=(0, 22.5, 0)),
          K.rbox((0, 0.08, -1.25), (1.0, 0.16, 0.3), bevel=0.04))
    k.add("dark", *[K.rbox((math.cos(a) * 1.0, 0.345, math.sin(a) * 1.0), (0.05, 0.02, 0.7), bevel=0.0, rot=(0, -math.degrees(a), 0))
                    for a in (i * math.pi / 4 for i in range(8))])  # slab joints

    # the mast: a steel pipe with three braces to the footing
    k.add("steel", K.rod((MX, 0.34, MZ), (MX, MTOP, MZ), 0.11, 10), K.cyl((MX, 0.42, MZ), 0.25, 0.16, 10, bevel=0.04))
    k.add("steel", *[K.rod((MX + math.cos(a) * 0.75, 0.36, MZ + math.sin(a) * 0.75), (MX, 1.9, MZ), 0.045, 5)
                     for a in (math.radians(d) for d in (100, 220, 340))])
    k.add("metal", *[K.rod((MX - 0.14, y, MZ), (MX - 0.14, y, MZ - 0.12), 0.025, 4) for y in (0.8, 1.15, 1.5, 1.85, 2.2, 2.55)])  # climbing pegs

    # the flare cage on top
    if not hot:
        k.add("steel", K.cyl((MX, MTOP + 0.04, MZ), 0.24, 0.08, 10))
        k.add("steel", *[K.rod((MX + math.cos(a) * 0.2, MTOP + 0.06, MZ + math.sin(a) * 0.2), (MX + math.cos(a) * 0.16, MTOP + 0.6, MZ + math.sin(a) * 0.16), 0.022, 4)
                         for a in (i * math.pi / 2 for i in range(4))], K.ring((MX, MTOP + 0.6, MZ), 0.17, 0.03, 10, 3))
        k.add("flare", K.cyl((MX, MTOP + 0.3, MZ), 0.12, 0.42, 8, bevel=0.04), K.ell((MX, MTOP + 0.52, MZ), (0.12, 0.08, 0.12), 8, 4),
              piece="flarepot")
    else:  # the crown: a brass cage on the mast top holding a big glowing beacon orb
        k.add("brass", K.cyl((MX, MTOP + 0.04, MZ), 0.3, 0.1, 10, bevel=0),
              *[K.rod((MX + math.cos(a) * 0.27, MTOP + 0.08, MZ + math.sin(a) * 0.27), (MX + math.cos(a) * 0.2, MTOP + 0.8, MZ + math.sin(a) * 0.2), 0.035, 4)
                for a in (i * 2 * math.pi / 5 for i in range(5))],
              K.ring((MX, MTOP + 0.8, MZ), 0.2, 0.04, 10, 3))
        k.add("glow", K.ell((MX, MTOP + 0.42, MZ), (0.3, 0.32, 0.3), 10, 6), piece="flarepot")

    # the dish on its yoke: facing up and to the front
    tilt = math.radians(42)
    n = (0.0, math.sin(tilt), -math.cos(tilt))  # the dish's facing
    u = (0.0, math.cos(tilt), math.sin(tilt))  # the dish's "up" in its plane
    C = (MX - 0.15, 2.95 if stage == 0 else 3.05, MZ - 0.62)
    rot = (-(90 - 42), 0, 0)  # Y axis -> n
    k.add("body", K.ell(C, (DR, 0.17 * DR / 0.92, DR), 16, 6, rot=rot))
    k.add("dishin", K.ell(add(C, n, 0.08 * DR / 0.92), (DR - 0.12, 0.1, DR - 0.12), 16, 4, rot=rot))
    k.add("brass" if hot else "steel", K.ring(add(C, n, 0.02), DR - 0.02, 0.04 if stage == 0 else 0.06, 18, 3, rot=rot), piece="dishrim")
    F = add(C, n, 0.85 * DR / 0.92)
    side = (1.0, 0.0, 0.0)
    rims = [add(add(C, side, (DR - 0.14) * math.cos(a)), u, (DR - 0.14) * math.sin(a)) for a in (math.radians(d) for d in (90, 210, 330))]
    k.add("steel", *[K.rod(add(r, n, 0.08), F, 0.025, 4) for r in rims])
    k.add("metal", K.rod(add(F, n, -0.12), add(F, n, 0.1), 0.08, 8, top=1.4))  # the feed horn
    # yoke: a fork from the mast to the dish's back, and the back mount
    back = add(C, n, -0.22)
    k.add("steel", K.rod(back, (MX, 2.6, MZ), 0.07 if stage == 0 else 0.11, 6), K.rod(back, add(back, n, -0.22), 0.15 if stage == 0 else 0.22, 8))

    # the signal console at the left
    cx, cz = -0.9, 0.3
    k.add("body", K.rbox((cx, 0.72, cz), (0.5, 0.75, 0.9), bevel=0.06), K.rbox((cx + 0.1, 1.12, cz), (0.32, 0.12, 0.92), bevel=0.04, rot=(0, 0, -25)))
    k.add("dial", *[K.cyl((cx + 0.26, 0.85, cz + dz), 0.09, 0.03, 10, rot=(0, 0, 90), bevel=0 if lean else 0.03) for dz in (-0.25, 0.0, 0.25)], piece="dials")
    k.add("dark", *[K.rbox((cx + 0.26, 0.6, cz + dz), (0.03, 0.06, 0.08), bevel=0.0) for dz in (-0.3, -0.1, 0.1, 0.3)],
          K.rod((cx + 0.15, 0.36, cz - 0.3), (MX - 0.2, 0.36, MZ - 0.1), 0.03, 4))  # switches, cable

    # a meteorite fragment on a plinth at the front-right
    px, pz = 0.85, -0.75
    k.add("stone", K.rbox((px, 0.5, pz), (0.42, 0.32, 0.42), bevel=0.05))
    if not hot:
        k.add("rock", K.ell((px, 0.84, pz), (0.27, 0.22, 0.24), 8, 5, rot=(10, 30, 15)))
        cracks = [K.rbox((px + dx, 0.84 + dy, pz - 0.2), (0.04, 0.16, 0.04), bevel=0.0, rot=(0, 0, r)) for dx, dy, r in ((-0.08, 0.02, 25), (0.07, -0.03, -30))]
        k.add("crack", *cracks, piece="cracks")
    else:  # the meteorite split open: a glowing crystal cluster in a brass cradle
        k.add("rock", K.ell((px, 0.76, pz), (0.3, 0.14, 0.28), 8, 4, rot=(0, 30, 0)))
        k.add("brass", *[K.rod((px + math.cos(a) * 0.24, 0.66, pz + math.sin(a) * 0.24), (px + math.cos(a) * 0.36, 1.05, pz + math.sin(a) * 0.36), 0.035, 4)
                         for a in (i * 2 * math.pi / 3 + 0.5 for i in range(3))])
        k.add("glow", *[K.rod((px + dx, 0.8, pz + dz), (px + dx * 3.2, h, pz + dz * 3.2), 0.11 if h > 1.4 else 0.08, 5, top=0.15)
                        for dx, dz, h in ((0.0, 0.0, 1.62), (0.07, 0.05, 1.28), (-0.07, 0.04, 1.2), (0.02, -0.08, 1.24))], piece="cracks")

    if stage >= 1:
        # an aerial array on the mast
        k.add("metal", K.rod((MX, 3.75, MZ), (MX + 0.6, 3.75, MZ + 0.3), 0.03, 4),
              *[K.rod((MX + x, 3.5, MZ + x * 0.5), (MX + x, 4.0, MZ + x * 0.5), 0.022, 4) for x in (0.2, 0.38, 0.56)])
    if stage >= 1:
        # the second dish on its own pylon at the back-left, facing up and back-left
        bx, bz, by = -0.78, 0.82, 2.05
        k.add("steel", K.rod((bx, 0.34, bz), (bx, by - 0.2, bz), 0.09, 8), K.cyl((bx, 0.42, bz), 0.24, 0.16, 8, bevel=0),
              *[K.rod((bx + math.cos(a) * 0.45, 0.36, bz + math.sin(a) * 0.45), (bx, 1.2, bz), 0.04, 4) for a in (math.radians(d) for d in (60, 180, 300))])
        t2 = math.radians(50)
        n2 = (-math.cos(t2) * 0.6, math.sin(t2), math.cos(t2) * 0.8)
        nl = math.sqrt(sum(c * c for c in n2))
        n2 = tuple(c / nl for c in n2)
        rot2 = (math.degrees(math.atan2(n2[2], n2[1])), 0, -math.degrees(math.asin(n2[0])))
        c2 = (bx, by, bz)
        k.add("body", K.ell(c2, (0.72, 0.13, 0.72), 14, 5, rot=rot2))
        k.add("dishin", K.ell(add(c2, n2, 0.07), (0.62, 0.08, 0.62), 14, 3, rot=rot2))
        k.add("brass" if hot else "steel", K.ring(add(c2, n2, 0.02), 0.7, 0.05, 16, 3, rot=rot2), piece="dishrim")
        k.add("steel", K.rod(add(c2, n2, 0.05), add(c2, n2, 0.6), 0.03, 4))
        k.add("metal", K.rod(add(c2, n2, 0.5), add(c2, n2, 0.7), 0.07, 6, top=1.4))
    if hot:
        # a brass band round the footing's edge, glowing landing lights at its corners
        k.add("brass", K.ring((0, 0.33, 0), 1.36, 0.05, 8, 3, rot=(0, 22.5, 0)))
        k.add("glow", *[K.ell((math.cos(a) * 1.25, 0.36, math.sin(a) * 1.25), (0.08, 0.06, 0.08), 6, 3)
                        for a in (i * math.pi / 4 + math.pi / 8 for i in range(8)) if math.cos(a) < 0.5 or math.sin(a) < 0.5],
              piece="lights")
        k.add("brass", K.ring_along((MX, 2.6, MZ), (MX, 3.6, MZ), 0.24, 0.06, 12, 3),
              K.rbox((cx + 0.26, 1.02, cz), (0.04, 0.05, 0.9), bevel=0), K.rbox((cx + 0.26, 0.42, cz), (0.04, 0.05, 0.9), bevel=0))

    colors = {
        "body": BLUE, "stone": STONE, "dark": (44, 46, 50), "steel": STEEL, "metal": K.METAL, "dishin": DISH_IN,
        "flare": FLARE, "rock": ROCK, "crack": CRACK, "dial": (232, 226, 200), "gen": (92, 104, 72), "wood": K.WOOD,
        "chart": (34, 42, 70), "brass": K.BRASS, "glow": GLOW,
    }
    return k.model("11d", colors, "METEOR", stage)
