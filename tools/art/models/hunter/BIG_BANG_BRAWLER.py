"""BIG_BANG_BRAWLER - Brush Beater premium skin (Nebula theme, PREMIUM_SKINS.md, batch 11p5, #462: its own
silhouette, element cosmic / void). A meteor brute who hits like a collapsing star:

  * an ASTEROID HELM: a lumpy cratered rock cap split open on top, a starlight core blazing out of the
    crack, three small meteors orbiting it on a tilted starlight ring; a short beard, open friendly face
  * crater-rock armour: a heavy faceted rock breastplate pocked with craters, starlight cracks running
    out from a BIG BANG at its centre (a starburst in a ring)
  * huge meteor pauldrons, each a cratered boulder with a starlight comet trail streaming behind
  * PLANET FISTS: the hands are two little planets - a ringed nebula-pink one and a cratered teal
    one - on bare brawler's arms with rock bracers
  * a rock belt with a meteor buckle, cratered rock greaves and heavy rock boots with glowing cracks

Starlight is paint group `glow` (Neon in game; Shared/SkinFx pulses / twinkles it). Built on the
shared R15 figure (_body.py) with bulky Brush Beater proportions, same R15 envelope (#434: the
pauldrons, fists and ring extend modestly past the parts).
"""
# art-sources: _body.py variants/_nebula.py

import importlib.util
import math
from pathlib import Path

_here = Path(__file__).parent
_spec = importlib.util.spec_from_file_location("_body", _here / "_body.py")
B = importlib.util.module_from_spec(_spec)
_spec.loader.exec_module(B)
_spec = importlib.util.spec_from_file_location("_nebula", _here / "variants" / "_nebula.py")
N = importlib.util.module_from_spec(_spec)
_spec.loader.exec_module(N)


def rock(c, r, rot=None, seg=7, rings=5):
    return B.ell(c, r, seg, rings, rot=rot)


def craters(points, r=0.07):
    """Short dark discs standing out of a surface: (point, normal)."""
    return [N.seg(B, p, tuple(a + b * 0.05 for a, b in zip(p, n)), r, r * 1.15, 7) for p, n in points]


def helm(body):
    # lumpy rock cap: two halves either side of a glowing split on top
    body.add("Head", "rock",
             rock((-0.26, 2.08, 0.16), (0.46, 0.38, 0.6), rot=(0, 0, 14)),
             rock((0.28, 2.08, 0.14), (0.46, 0.4, 0.6), rot=(0, 0, -16)),
             rock((0, 1.7, 0.34), (0.62, 0.42, 0.4)),  # the back, down to the nape
             rock((-0.58, 1.6, 0.0), (0.12, 0.3, 0.34)), rock((0.58, 1.6, 0.0), (0.12, 0.3, 0.34)))
    body.add("Head", "crater", *craters([((-0.36, 2.3, -0.14), (-0.4, 0.7, -0.5)), ((0.4, 2.18, 0.3), (0.5, 0.6, 0.4)),
                                         ((0.3, 2.14, -0.38), (0.3, 0.5, -0.8))], 0.08))
    body.add("Head", "glow",
             B.ell((0, 2.32, 0.14), (0.14, 0.2, 0.48), 8, 4),  # the core blazing out of the split
             *N.sparkle(B, (0, 2.6, -0.02), 0.28, rot=(0, 0, 0)),
             N.star(B, (0, 2.58, -0.02), 0.08),
             N.torus(B, (0, 2.12, 0.12), (0.86, 0.82), 0.03, 20, 3, rot=(-8, 0, 10)))
    for a in (30, 150, 260):
        body.add("Head", "crater", rock(N.ring_point((0, 2.12, 0.12), (0.86, 0.82), a, (-8, 0, 10)), (0.1, 0.09, 0.1), seg=6, rings=4))
    body.add("Head", "hair", B.rbox((0, 1.2, -0.46), (0.6, 0.24, 0.16), bevel=0.07, segments=2, taper=(1.3, 1.0)))  # short beard


def chest(body):
    f = -0.56
    body.add("UpperTorso", "rock",
             rock((-0.48, 0.5, -0.4), (0.56, 0.62, 0.22), rot=(0, 0, 8)),
             rock((0.48, 0.5, -0.4), (0.56, 0.62, 0.22), rot=(0, 0, -8)),
             rock((0, -0.12, -0.42), (0.7, 0.32, 0.2)),
             rock((0, 0.36, 0.42), (0.96, 0.8, 0.22)))
    body.add("UpperTorso", "crater", *craters([((-0.62, 0.72, -0.6), (0, 0, -1)), ((0.66, 0.28, -0.6), (0, 0, -1)),
                                               ((-0.3, -0.14, -0.6), (0, 0, -1)), ((0.5, 0.5, 0.62), (0, 0, 1)),
                                               ((-0.4, 0.1, 0.62), (0, 0, 1))], 0.09))
    # the big bang: a starburst in a ring, cracks running out from it
    body.add("UpperTorso", "dark", N.torus(B, (0, 0.42, f - 0.04), 0.27, 0.06, 14, 4, rot=(90, 0, 0)))
    body.add("UpperTorso", "glow",
             B.ell((0, 0.42, f - 0.06), (0.16, 0.16, 0.08), 8, 4),
             *N.sparkle(B, (0, 0.42, f - 0.1), 0.44), *N.sparkle(B, (0, 0.42, f - 0.1), 0.26, rot=(0, 0, 45)),
             *[N.rod(B, a, b, 0.03, 4, 0.7) for a, b in (((0.28, 0.6, f), (0.62, 0.92, f + 0.04)), ((-0.28, 0.6, f), (-0.7, 0.86, f + 0.04)),
                                                         ((0.26, 0.24, f), (0.7, -0.02, f + 0.04)), ((-0.24, 0.22, f), (-0.5, -0.12, f + 0.06)))])
    # back: a crack network
    b = 0.65
    body.add("UpperTorso", "glow", *[N.rod(B, p, q, 0.03, 4, 0.7) for p, q in
                                     (((0, 0.9, b), (0.12, 0.5, b)), ((0.12, 0.5, b), (-0.1, 0.1, b)), ((0.12, 0.5, b), (0.55, 0.36, b - 0.04)))])
    # belt with a meteor buckle
    body.add("LowerTorso", "crater", rock((0, -0.63, -0.56), (0.2, 0.16, 0.1), seg=6, rings=4))
    body.add("LowerTorso", "glow", N.star(B, (0, -0.6, -0.66), 0.06))


def pauldrons(body):
    for k, side in B.SIDES:
        x = 1.5 * k
        part = f"{side}UpperArm"
        body.add(part, "rock",
                 rock((x, 0.92, 0.0), (0.62, 0.5, 0.6), rot=(0, 20 * k, -14 * k), seg=8, rings=5),
                 rock((x + 0.3 * k, 0.66, -0.1), (0.3, 0.26, 0.3), seg=6, rings=4))
        body.add(part, "crater", *craters([((x + 0.1 * k, 1.38, -0.1), (0, 1, 0)), ((x + 0.56 * k, 0.98, -0.2), (k, 0.2, -0.2)),
                                           ((x - 0.1 * k, 1.12, -0.46), (0, 0.4, -1))], 0.09))
        # the comet trail streaming back off the boulder
        trail = [(x + 0.1 * k, 1.16, 0.4), (x + 0.16 * k, 1.36, 0.82), (x + 0.2 * k, 1.5, 1.14)]
        body.add(part, "glow", N.seg(B, trail[0], trail[1], 0.24, 0.14, 7, cap=False), N.seg(B, trail[1], trail[2], 0.14, 0.0, 7),
                 )


def fists(body):
    # left: a ringed nebula-pink planet; right: a cratered teal planet
    xl, xr = -1.42, 1.42
    body.add("LeftHand", "planet", B.ell((xl, -0.86, -0.02), (0.42, 0.42, 0.42), 12, 8))
    body.add("LeftHand", "dark", B.ell((xl, -0.86, -0.02), (0.425, 0.08, 0.425), 12, 2, rot=(0, 0, 20)))
    body.add("LeftHand", "glow", N.torus(B, (xl, -0.86, -0.02), 0.64, 0.035, 18, 3, rot=(20, 0, 24)))
    body.add("RightHand", "planet2", B.ell((xr, -0.86, -0.02), (0.42, 0.42, 0.42), 12, 8))
    body.add("RightHand", "crater", *craters([((xr + 0.3, -0.7, -0.24), (0.7, 0.4, -0.6)), ((xr, -0.6, -0.32), (0, 0.5, -0.9)),
                                              ((xr + 0.1, -1.1, -0.3), (0.2, -0.5, -0.8)), ((xr + 0.34, -0.9, 0.2), (0.8, 0, 0.5))], 0.08))
    body.add("RightHand", "glow", *[N.star(B, p, 0.04) for p in ((xr - 0.2, -0.5, -0.32), (xr + 0.4, -0.62, 0.0), (xr - 0.1, -1.2, 0.1))])
    for k, side in B.SIDES:
        x = 1.42 * k
        body.add(f"{side}LowerArm", "rock", B.cyl((x, -0.38, 0), 0.38, 0.4, 7, bevel=0.0, top=1.12))
        body.add(f"{side}LowerArm", "glow", N.rod(B, (x + 0.2 * k, -0.24, -0.36), (x + 0.06 * k, -0.52, -0.4), 0.028, 4, 0.7))


def legs(body):
    for k, side in B.SIDES:
        lx = 0.5 * k
        body.add(f"{side}LowerLeg", "rock", B.cyl((lx, -2.1, -0.02), 0.44, 0.56, 7, bevel=0.0, top=1.1),
                 rock((lx, -1.82, -0.32), (0.3, 0.24, 0.16), seg=6, rings=4))
        body.add(f"{side}LowerLeg", "glow", N.rod(B, (lx - 0.12, -1.94, -0.46), (lx + 0.06, -2.3, -0.46), 0.028, 4, 0.7))
        body.add(f"{side}Foot", "rock", rock((lx, -2.72, -0.36), (0.46, 0.2, 0.42), seg=7, rings=4))
        body.add(f"{side}Foot", "glow", N.rod(B, (lx - 0.2, -2.6, -0.7), (lx + 0.18, -2.62, -0.66), 0.026, 4, 0.7))
        body.add(f"{side}UpperLeg", "rock", rock((lx + 0.14 * k, -1.16, -0.1), (0.36, 0.26, 0.42), rot=(0, 0, -8 * k), seg=6, rings=4))


def build(lp):
    plp = N.protect(lp)
    body = B.Body(plp)
    B.base(body, plp, {
        "arm": 0.4, "fore": 0.36, "leg": 0.44, "shin": 0.38, "torso": (2.1, 1.55, 1.06),
        "taper": 1.1, "sleeve": "none", "hands": "skin", "hand": 0.8, "boot": -2.2,
        "bootr": 0.43, "foot": 1.0, "armx": 1.42, "brow": 0.1,
    })
    helm(body)
    chest(body)
    pauldrons(body)
    fists(body)
    legs(body)
    return {
        "batch": "11p5",
        "budget": "hero",
        "rig": "r15",
        "pieces": body.finish(2600, 110),
        "colors": {
            "skin": (198, 140, 104),
            "eye": (32, 26, 40),
            "hair": (70, 46, 90),
            "shirt": (52, 40, 100),
            "pants": (44, 36, 88),
            "dark": (28, 24, 52),
            "rock": (88, 78, 124),      # violet-grey meteor rock
            "crater": (52, 44, 86),
            "planet": (214, 88, 184),   # nebula pink fist
            "planet2": (70, 176, 196),  # teal fist
            "star": (244, 244, 255),
            "glow": (150, 236, 240),
        },
        "meta": {"skin": "BIG_BANG_BRAWLER", "hero": "SHOTGUN", "display": "Big Bang Brawler", "base": "hunter/SHOTGUN",
                 "theme": "NEBULA", "premium": True},
    }
