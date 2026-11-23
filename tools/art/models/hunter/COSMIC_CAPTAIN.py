"""COSMIC_CAPTAIN - Big Game Hunter premium skin (Nebula theme, PREMIUM_SKINS.md, batch 11p5, #462: its own
silhouette, element cosmic / void). The star-ship captain of the hunt:

  * a big open-faced space helm: a round indigo shell over the back of the head, a thick silver face
    ring with a starlight line inside it, a tall antenna with a star on top and a planet crest; a
    tilted orbit ring circles the helm with two tiny moons riding it
  * the ORBITAL PAULDRON on the right shoulder: a nebula-pink planet with a starlight ring round it;
    a stepped indigo plate pauldron with star rivets on the left
  * a star-captain's double-breasted indigo coat: a starburst emblem in a ring on the chest, two rows
    of star buttons, a silver collar seal round the neck
  * a long star-map cape: deep violet, three panels, constellations (lines + star points) and a
    crescent moon across its back, pink nebula swirls, star clasps
  * silver gauntlet cuffs with starlight rings, indigo greaves with star knee guards, a crescent buckle

Starlight (lines, points, rings) is paint group `glow` (Neon in game; Shared/SkinFx pulses /
twinkles it). Built on the shared R15 figure (_body.py), same R15 envelope (#434: helm, ring, planet
and cape extend modestly past the parts).
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

SHELL = ((0, 1.72, 0.26), (0.8, 0.8, 0.66))


def helm(body):
    c, r = SHELL
    body.add("Head", "plate",
             B.ell(c, r, 14, 9),
             # ear pods (comms) on both sides
             *[B.cyl((0.8 * k, 1.6, 0.0), 0.2, 0.16, 10, bevel=0.03, rot=(0, 0, 90)) for k in (-1, 1)])
    # the face ring: a thick silver frame round the open face, a starlight line inside it
    body.add("Head", "metal",
             N.torus(B, (0, 1.6, -0.36), (0.64, 0.68), 0.1, 18, 5, rot=(90, 0, 0)),
             *[B.cyl((0.8 * k, 1.6, 0.0), 0.12, 0.2, 8, bevel=0.0, rot=(0, 0, 90)) for k in (-1, 1)],
             B.cyl((0.18, 2.5, 0.3), 0.035, 0.5, 6, bevel=0.0))  # antenna mast
    body.add("Head", "glow",
             N.torus(B, (0, 1.6, -0.43), (0.56, 0.6), 0.03, 18, 3, rot=(90, 0, 0)),
             *[B.cyl((0.9 * k, 1.6, 0.0), 0.08, 0.04, 8, bevel=0.0, rot=(0, 0, 90)) for k in (-1, 1)],
             N.star(B, (0.18, 2.8, 0.3), 0.09),
             *N.sparkle(B, (0.18, 2.8, 0.3), 0.2, rot=(0, 30, 0)),
             # the orbit ring round the helm, tilted, with two tiny moons on it
             N.torus(B, (0, 1.95, 0.2), (1.05, 0.95), 0.035, 22, 3, rot=(14, 0, -16)))
    moons = [B.ell(N.ring_point((0, 1.95, 0.2), (1.05, 0.95), a, (14, 0, -16)), (0.11, 0.11, 0.11), 8, 5) for a in (20, 200)]
    body.add("Head", "nebula", *moons)
    # planet crest on top of the helm (a small ringed planet)
    body.add("Head", "nebula", B.ell((-0.2, 2.6, 0.36), (0.17, 0.17, 0.17), 10, 6))
    body.add("Head", "glow", N.torus(B, (-0.2, 2.6, 0.36), 0.27, 0.025, 14, 3, rot=(0, 0, 20)))
    # star speckles on the shell
    body.add("Head", "star", *[N.star(B, N.on_ell(c, r, yaw, p, 1.01), 0.04)
                               for yaw, p in ((40, 40), (-50, 30), (120, 20), (-140, 50), (170, 10), (80, 62), (-100, 70))])
    # the captain's moustache (the Big Game Hunter's, kept)
    body.add("Head", "hair", *[B.ell((0.15 * k, 1.37, -0.535), (0.18, 0.07, 0.06), 8, 5, rot=(0, 0, 18 * k)) for k in (-1, 1)])


def coat(body):
    f = -0.54
    body.add("UpperTorso", "plate",
             B.rbox((0, 0.36, -0.4), (1.86, 1.24, 0.24), bevel=0.1, segments=1, taper=(1.05, 1.0)),
             B.rbox((0, 0.36, 0.4), (1.82, 1.2, 0.22), bevel=0.1, segments=1))
    # collar seal (silver ring round the neck), the chest emblem's ring
    body.add("UpperTorso", "metal",
             N.torus(B, (0, 1.0, 0.02), (0.56, 0.48), 0.09, 16, 4),
             N.torus(B, (0, 0.5, f - 0.02), 0.3, 0.05, 14, 4, rot=(90, 0, 0)))
    body.add("UpperTorso", "glow",
             *N.sparkle(B, (0, 0.5, f - 0.05), 0.26),
             N.star(B, (0, 0.5, f - 0.06), 0.09),
             # two rows of star buttons
             *[N.star(B, (0.42 * k, y, f + 0.02), 0.05) for k in (-1, 1) for y in (0.72, 0.42, 0.12)])
    # pink nebula swirl across the coat front, star speckles
    body.add("UpperTorso", "nebula",
             *N.cloud(B, (-0.55, 0.06, f + 0.02), 0.16, tilt=30, n=3), *N.cloud(B, (0.58, 0.88, f + 0.02), 0.13, tilt=-20, n=3))
    body.add("UpperTorso", "star", *[N.star(B, (x, y, f + 0.04), 0.03) for x, y in ((0.7, 0.86), (0.66, 0.2), (-0.72, 0.0), (0.22, 0.92))])
    # belt with a crescent buckle
    body.add("LowerTorso", "metal", B.rbox((0, -0.63, -0.53), (0.36, 0.26, 0.06), bevel=0.03, segments=1))
    body.add("LowerTorso", "glow", N.torus(B, (0, -0.63, -0.57), 0.09, 0.025, 10, 3, rot=(90, 0, 0)))
    # coat skirt panels hanging from the belt (front + sides)
    body.add("LowerTorso", "plate",
             *[B.rbox((0.42 * k, -1.08, -0.5), (0.62, 0.62, 0.06), bevel=0.02, segments=1, rot=(4, 0, -4 * k), taper=(1.2, 1.0)) for k in (-1, 1)])
    body.add("LowerTorso", "glow", *[B.rbox((0.42 * k, -1.38, -0.535), (0.66, 0.035, 0.02), bevel=0.0, segments=1, rot=(4, 0, -4 * k)) for k in (-1, 1)])


def pauldrons(body):
    # RIGHT: the orbital pauldron - a ringed planet on the shoulder
    x = 1.5
    body.add("RightUpperArm", "nebula", B.ell((x, 0.95, 0), (0.5, 0.46, 0.5), 12, 8))
    body.add("RightUpperArm", "plate", B.ell((x, 0.96, 0), (0.505, 0.12, 0.505), 12, 3, rot=(0, 0, -12)))  # a dark band round it
    body.add("RightUpperArm", "glow",
             N.torus(B, (x, 0.95, 0), 0.82, 0.05, 20, 3, rot=(18, 0, -22), squash=0.6),
             N.star(B, (x + 0.3, 1.3, -0.2), 0.05), N.star(B, (x - 0.1, 1.38, 0.24), 0.04))
    body.add("RightUpperArm", "star", B.ell(N.ring_point((x, 0.95, 0), 0.82, 150, (18, 0, -22)), (0.08, 0.08, 0.08), 6, 4))  # a moonlet on the ring
    # LEFT: stepped indigo plates with star rivets
    x = -1.42
    body.add("LeftUpperArm", "plate",
             B.ell((x, 0.98, 0), (0.56, 0.2, 0.56), 10, 4, rot=(0, 0, 16)),
             B.ell((x - 0.12, 0.76, 0), (0.5, 0.16, 0.52), 10, 4, rot=(0, 0, 26)))
    body.add("LeftUpperArm", "glow",
             B.ell((x - 0.06, 0.87, 0), (0.5, 0.04, 0.52), 10, 2, rot=(0, 0, 21)),
             *[N.star(B, (x + dx, 1.17, dz), 0.05) for dx, dz in ((-0.2, -0.2), (0.0, 0.0), (-0.2, 0.2))])


def cape(body):
    """A long star-map cape: three panels from the shoulders, constellations and a crescent moon."""
    z0 = 0.6
    back = math.sin(math.radians(4))
    panels = []
    for x, length in ((-0.64, 2.6), (0.0, 2.8), (0.64, 2.6)):
        panels.append(B.rbox((x * 1.02, 1.0 - length / 2, z0 + length / 2 * back), (0.7, length, 0.05), bevel=0.02,
                             segments=1, rot=(-4, 0, -x * 5), taper=(1 / 1.2, 1.0)))
    body.add("UpperTorso", "cape", *panels)
    z = z0 + 0.04

    def on(x, y):
        return (x, y, z + (1.0 - y) * back)

    body.add("UpperTorso", "glow",
             *N.constellation(B, [on(-0.6, 0.6), on(-0.3, 0.3), on(-0.45, -0.1), on(-0.1, -0.35), on(0.2, -0.1)], big=(1, 3)),
             *N.constellation(B, [on(0.35, 0.55), on(0.6, 0.2), on(0.42, -0.62), on(0.68, -1.0)], big=(1,)),
             *N.constellation(B, [on(-0.62, -0.9), on(-0.3, -1.15), on(0.0, -0.95)], big=(1,)),
             # the hem: a starlight line
             *[B.rbox((x * 1.02 + 0.0, 1.0 - length + 0.06, z0 + length * back + 0.03), (0.74, 0.04, 0.02), bevel=0.0,
                      segments=1, rot=(-4, 0, -x * 5)) for x, length in ((-0.64, 2.6), (0.0, 2.8), (0.64, 2.6))])
    # crescent moon high on the back (two offset discs: pale moon, cape-coloured bite)
    body.add("UpperTorso", "star", B.cyl(on(0.1, 0.78), 0.2, 0.03, 12, bevel=0.0, rot=(90, 0, 0)))
    body.add("UpperTorso", "cape", B.cyl((0.18, 0.82, z + 0.035), 0.17, 0.03, 12, bevel=0.0, rot=(90, 0, 0)))
    body.add("UpperTorso", "nebula",
             *N.cloud(B, (0.1, -0.5, z + 0.03 + 1.5 * back), 0.3, tilt=-20),
             *N.cloud(B, (-0.3, 0.25, z + 0.03 + 0.75 * back), 0.2, tilt=25, n=3))
    body.add("UpperTorso", "star", *[N.star(B, on(x, y), 0.035) for x, y in
                                      ((0.0, 0.3), (-0.15, -0.7), (0.5, -0.3), (-0.6, -0.4), (0.25, -1.3), (-0.4, -1.45), (0.62, 0.86))])
    # star clasps at the shoulders
    body.add("UpperTorso", "metal", *[B.cyl((0.72 * k, 0.98, 0.56), 0.1, 0.08, 8, bevel=0.02, rot=(90, 0, 0)) for k in (-1, 1)])
    body.add("UpperTorso", "glow", *[N.star(B, (0.72 * k, 0.98, 0.51), 0.06) for k in (-1, 1)])


def arms(body):
    for k, side in B.SIDES:
        x = 1.38 * k
        body.add(f"{side}LowerArm", "metal", B.cyl((x, -0.42, 0), 0.34, 0.44, 10, bevel=0.04, top=0.82))
        body.add(f"{side}LowerArm", "glow", B.cyl((x, -0.56, 0), 0.35, 0.04, 12, bevel=0.0),
                 B.cyl((x, -0.3, 0), 0.315, 0.03, 12, bevel=0.0))


def legs(body):
    for k, side in B.SIDES:
        lx = 0.5 * k
        body.add(f"{side}LowerLeg", "plate",
                 B.cyl((lx, -2.14, -0.02), 0.39, 0.52, 10, bevel=0.04, top=1.08),
                 B.ell((lx, -1.86, -0.3), (0.24, 0.24, 0.12), 8, 4))
        body.add(f"{side}LowerLeg", "glow",
                 *N.sparkle(B, (lx, -1.86, -0.43), 0.17),
                 B.cyl((lx, -2.42, -0.02), 0.41, 0.03, 12, bevel=0.0))
        body.add(f"{side}Foot", "metal", B.rbox((lx, -2.68, -0.48), (0.7, 0.14, 0.34), bevel=0.05, segments=1, rot=(-14, 0, 0)))
        body.add(f"{side}Foot", "glow", N.star(B, (lx, -2.62, -0.66), 0.05))
        body.add(f"{side}UpperLeg", "glow", B.rbox((lx + 0.36 * k, -1.4, 0), (0.03, 0.62, 0.05), bevel=0.0, segments=1))


def build(lp):
    plp = N.protect(lp)
    body = B.Body(plp)
    B.base(body, plp, {
        "arm": 0.38, "fore": 0.33, "leg": 0.42, "shin": 0.36, "torso": (2.0, 1.55, 1.0),
        "taper": 1.08, "sleeve": "long", "hands": "glove", "boot": -2.36, "bootr": 0.38,
        "shorts": False, "armx": 1.38, "brow": 0.08,
    })
    helm(body)
    coat(body)
    pauldrons(body)
    cape(body)
    arms(body)
    legs(body)
    return {
        "batch": "11p5",
        "budget": "hero",
        "rig": "r15",
        "pieces": body.finish(2400, 110),
        "colors": {
            "skin": (236, 188, 150),
            "eye": (32, 26, 40),
            "hair": (226, 226, 240),   # silver moustache and brows
            "shirt": (34, 32, 70),     # navy under-suit
            "pants": (30, 28, 62),
            "dark": (24, 22, 46),
            "glove": (196, 194, 226),  # silver-lilac gloves
            "plate": (38, 36, 100),    # deep indigo
            "metal": (186, 182, 220),  # silver-lilac
            "cape": (62, 30, 104),     # deep violet
            "nebula": (214, 88, 184),  # nebula pink
            "star": (244, 244, 255),   # star speckles (white)
            "glow": (150, 236, 240),   # starlight (Neon in game)
        },
        "meta": {"skin": "COSMIC_CAPTAIN", "hero": "RIFLE", "display": "Cosmic Captain", "base": "hunter/RIFLE",
                 "theme": "NEBULA", "premium": True},
    }
