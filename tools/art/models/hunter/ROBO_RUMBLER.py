"""ROBO_RUMBLER - Brush Beater premium skin (Cyber Raptor theme, PREMIUM_SKINS.md, batch 11p3, #462:
its own silhouette, element electric / digital glitch). The brawler: a stocky mech with huge arms.

  * hydraulic gauntlets: the forearms in big black-chrome housings, gunmetal pistons running from
    the elbow, a glowing power cell in each, oversized fists with three raptor knuckle claws
  * dome shoulders with twin exhaust stacks behind them (glowing tips)
  * a barrel chest plate with a round reactor ring and a vent grille
  * an open, low raptor-skull helmet: a heavy brow ridge, two big raptor claws hooking back over the skull (glowing tips), glowing goggles
    pushed up on the forehead, a chin guard below the smile (the face stays open and friendly)
  * hydraulic knees (a piston down each shin) and heavy raptor-claw boots

Every cell, ring, vent and goggle is group `glow` (Neon; SkinFx cycles cyan -> magenta).
Built on the shared R15 figure (_body.py) with its own style; same R15 hit envelope (#434).
"""
# art-sources: _body.py variants/_cyber.py

import importlib.util
from pathlib import Path

_here = Path(__file__).parent
_spec = importlib.util.spec_from_file_location("_body", _here / "_body.py")
B = importlib.util.module_from_spec(_spec)
_spec.loader.exec_module(B)
_spec = importlib.util.spec_from_file_location("_cyber", _here / "variants" / "_cyber.py")
C = importlib.util.module_from_spec(_spec)
_spec.loader.exec_module(C)


def helmet(body):
    body.add("Head", "plate",
             B.rbox((0, 2.06, 0.1), (1.22, 0.42, 1.12), bevel=0.18, segments=1),  # skull cap
             B.rbox((0, 1.88, -0.52), (1.2, 0.18, 0.2), bevel=0.06, segments=1, rot=(-12, 0, 0)),  # brow ridge
             B.rbox((0, 1.56, 0.56), (1.0, 0.7, 0.16), bevel=0.06, segments=1),  # back guard
             B.rbox((0, 1.06, -0.4), (0.62, 0.16, 0.26), bevel=0.05, segments=1, rot=(-18, 0, 0)))  # chin guard
    body.add("Head", "chrome",
             *[B.rbox((0.6 * k, 1.6, 0.04), (0.12, 0.42, 0.42), bevel=0.03, segments=1) for k in (-1, 1)],  # ear plates
             *[C.seg(B, (0.66 * k, 1.7, 0.1), (0.8 * k, 2.08, 0.24), 0.05, 0.03, 4) for k in (-1, 1)],  # ear antennas
             B.rbox((0, 2.2, -0.42), (0.9, 0.12, 0.2), bevel=0.03, segments=1))  # goggle strap front
    body.add("Head", "glow",
             *[B.cyl((0.22 * k, 2.2, -0.54), 0.15, 0.1, 8, bevel=0.0, rot=(90, 0, 0)) for k in (-1, 1)],  # goggles up
             *[B.ell((0.8 * k, 2.1, 0.24), (0.05, 0.05, 0.05), 6, 3) for k in (-1, 1)])
    # two big raptor claws hooking back over the skull cap, glowing tips
    for k in (-1, 1):
        cb, ct = C.claw(B, [(0.34 * k, 2.2, -0.2), (0.4 * k, 2.52, 0.0), (0.42 * k, 2.6, 0.34), (0.4 * k, 2.44, 0.66)], 0.13, 5)
        body.add("Head", "chrome", *cb)
        body.add("Head", "glow", ct)
    body.add("Head", "hair", *[B.rbox((0.21 * k, 1.8, -0.53), (0.28, 0.09, 0.06), bevel=0.02, segments=1, rot=(0, 0, -14 * k)) for k in (-1, 1)])


def chest(body):
    f = -0.6
    body.add("UpperTorso", "plate",
             B.rbox((0, 0.36, -0.36), (2.0, 1.2, 0.42), bevel=0.2, segments=1, taper=(1.08, 1.0)),
             B.rbox((0, 0.38, 0.38), (1.9, 1.16, 0.34), bevel=0.14, segments=1))
    body.add("UpperTorso", "chrome",
             B.cyl((0, 0.5, f), 0.36, 0.1, 10, bevel=0.02, rot=(90, 0, 0)),
             *[B.rbox((0, y, f + 0.02), (0.8, 0.05, 0.05), bevel=0.0, segments=1) for y in (-0.02, -0.12)],  # grille bars
             B.rbox((0, 0.38, 0.6), (1.0, 0.8, 0.14), bevel=0.04, segments=1))  # back battery
    body.add("UpperTorso", "glow",
             B.cyl((0, 0.5, f - 0.05), 0.26, 0.04, 10, bevel=0.0, rot=(90, 0, 0)),
             B.rbox((0, -0.07, f + 0.03), (0.76, 0.14, 0.02), bevel=0.0, segments=1),  # behind the grille
             *[B.rbox((x, 0.38, 0.68), (0.14, 0.6, 0.02), bevel=0.0, segments=1) for x in (-0.3, 0.0, 0.3)],  # battery cells
             *C.trace(B, [(0.36, 0.5, f + 0.02), (0.7, 0.5, f + 0.04), (0.82, 0.74, f + 0.06)]),
             *C.trace(B, [(-0.36, 0.5, f + 0.02), (-0.7, 0.5, f + 0.04), (-0.82, 0.74, f + 0.06)]))
    body.add("LowerTorso", "chrome", B.rbox((0, -0.63, -0.52), (0.52, 0.32, 0.1), bevel=0.03, segments=1))
    body.add("LowerTorso", "glow", B.cyl((0, -0.63, -0.58), 0.09, 0.03, 8, bevel=0.0, rot=(90, 0, 0)))


def arms(body):
    for k, side in B.SIDES:
        x = 1.44 * k
        up = f"{side}UpperArm"
        body.add(up, "plate", B.ell((x, 0.84, 0), (0.6, 0.48, 0.6), 10, 6))  # dome shoulder
        body.add(up, "chrome",
                 *[B.cyl((x - 0.08 * k, 1.2, dz), 0.09, 0.5, 6, bevel=0.0) for dz in (0.22, 0.44)],  # exhaust stacks
                 B.rbox((x, 0.62, 0), (0.7, 0.08, 0.66), bevel=0.02, segments=1))
        body.add(up, "glow", *[B.cyl((x - 0.08 * k, 1.47, dz), 0.07, 0.04, 6, bevel=0.0) for dz in (0.22, 0.44)],
                 B.cyl((x, 0.73, 0), (0.56, 0.56), 0.04, 10, bevel=0.0))
        lo = f"{side}LowerArm"
        # the hydraulic housing round the forearm
        body.add(lo, "plate", B.rbox((x, -0.32, 0), (0.86, 0.72, 0.86), bevel=0.12, segments=1, taper=(0.86, 0.86)))
        body.add(lo, "chrome",
                 *[B.cyl((x + dx, -0.05, dz), 0.06, 0.44, 6, bevel=0.0) for dx, dz in ((0.36 * k, -0.24), (0.36 * k, 0.24))],
                 *[B.cyl((x + dx, 0.2, dz), 0.035, 0.3, 5, bevel=0.0) for dx, dz in ((0.36 * k, -0.24), (0.36 * k, 0.24))])
        body.add(lo, "glow",
                 B.rbox((x + 0.44 * k, -0.34, 0), (0.03, 0.34, 0.2), bevel=0.0, segments=1),  # power cell window
                 B.rbox((x, -0.34, -0.44), (0.4, 0.06, 0.02), bevel=0.0, segments=1),
                 B.rbox((x, -0.66, 0), (0.78, 0.04, 0.78), bevel=0.0, segments=1))  # cuff seam
        # oversized fist with three knuckle claws
        hand = f"{side}Hand"
        body.add(hand, "plate", B.rbox((x, -0.94, -0.04), (0.72, 0.5, 0.74), bevel=0.14, segments=1))
        claws = []
        for dx in (-0.2, 0.0, 0.2):
            cb, ct = C.claw(B, [(x + dx, -0.86, -0.38), (x + dx, -0.82, -0.6), (x + dx, -0.92, -0.76)], 0.07)
            claws += cb + [ct]
        body.add(hand, "chrome", *claws)
        body.add(hand, "glow", B.rbox((x, -0.8, -0.415), (0.5, 0.05, 0.02), bevel=0.0, segments=1))


def legs(body):
    for k, side in B.SIDES:
        lx = 0.5 * k
        body.add(f"{side}UpperLeg", "plate", B.rbox((lx, -1.3, -0.04), (0.74, 0.58, 0.78), bevel=0.1, segments=1))
        body.add(f"{side}UpperLeg", "glow", B.rbox((lx + 0.38 * k, -1.3, -0.04), (0.02, 0.3, 0.4), bevel=0.0, segments=1))
        body.add(f"{side}LowerLeg", "plate",
                 B.cyl((lx, -2.18, -0.02), 0.43, 0.54, 8, bevel=0.03, top=1.1),
                 B.ell((lx, -1.84, -0.24), (0.3, 0.22, 0.22), 8, 4))  # knee cap
        body.add(f"{side}LowerLeg", "chrome",
                 B.cyl((lx + 0.36 * k, -1.96, 0.1), 0.05, 0.5, 6, bevel=0.0))  # knee piston
        body.add(f"{side}LowerLeg", "glow", B.cyl((lx, -1.92, -0.24), (0.31, 0.23), 0.04, 8, bevel=0.0))
        part = f"{side}Foot"
        body.add(part, "plate", B.rbox((lx, -2.7, -0.28), (0.86, 0.24, 0.86), bevel=0.06, segments=1))
        claws = []
        for dx in (-0.26, 0.0, 0.26):
            cb, ct = C.claw(B, [(lx + dx, -2.72, -0.64), (lx + dx * 1.1, -2.74, -0.86), (lx + dx * 1.15, -2.88, -0.96)], 0.08)
            claws += cb + [ct]
        body.add(part, "chrome", *claws)
        body.add(part, "glow", B.rbox((lx, -2.6, -0.715), (0.6, 0.05, 0.02), bevel=0.0, segments=1))


def build(lp):
    plp = C.protect(lp)
    body = B.Body(plp)
    B.base(body, plp, {
        "arm": 0.38, "fore": 0.36, "leg": 0.44, "shin": 0.38, "torso": (2.1, 1.5, 1.05),
        "taper": 1.08, "sleeve": "long", "hands": "gaunt", "boot": -2.36, "bootr": 0.4,
        "shorts": False, "armx": 1.4, "brow": 0.08,
    })
    helmet(body)
    chest(body)
    arms(body)
    legs(body)
    return {
        "batch": "11p3",
        "budget": "hero",
        "rig": "r15",
        "pieces": body.finish(2400, 110),
        "colors": {
            "skin": (226, 172, 132),
            "eye": (26, 24, 34),
            "hair": (52, 40, 36),
            "shirt": (44, 46, 60),
            "pants": (40, 42, 56),
            "dark": (24, 26, 34),
            "gaunt": (30, 32, 44),
            **C.COLORS,
        },
        "meta": {"skin": "ROBO_RUMBLER", "hero": "SHOTGUN", "display": "Robo Rumbler", "base": "hunter/SHOTGUN",
                 "theme": "CYBER_RAPTOR", "premium": True},
    }
