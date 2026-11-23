"""MOON_MEDIC - Field Medic premium skin (Nebula theme, PREMIUM_SKINS.md, batch 11p5, #462: its own
silhouette, element cosmic / void). A celestial healer who carries starlight in bottles:

  * a STARLIGHT HALO floating over the head with four star points riding it, a soft moon-silver hood
    framing the face and a crescent-moon circlet on the brow
  * a long moon-silver healer's coat with indigo trim, split skirt panels to the knees and a
    starlight hem; on the chest a big crescent moon cradling a four-point star cross (the medic's
    cross, in starlight)
  * the STAR-VIAL PACK: an indigo frame on the back holding three tall vials of glowing starlight
    with silver caps and a star on each, a small ringed moon on top of the frame
  * two little cratered moons as epaulettes, starlight cuffs, a belt of small star pouches

Starlight is paint group `glow` (Neon in game; Shared/SkinFx pulses / twinkles it). Built on the
shared R15 figure (_body.py) with Field Medic proportions, same R15 envelope (#434: the halo and the
pack extend modestly past the parts).
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

HOOD = ((0, 1.8, 0.16), (0.68, 0.6, 0.62))


def crescent(body, part, c, r, face=-1, bite=(0.32, 0.18), group="glow", backing="robe", t=0.04):
    """A crescent moon on a surface facing -Z (face=-1) or +Z (face=1): a disc in `group` with an
    offset disc in `backing` biting it, standing a hair proud."""
    body.add(part, group, B.cyl(c, r, t, 14, bevel=0.0, rot=(90, 0, 0)))
    bc = (c[0] + r * bite[0], c[1] + r * bite[1], c[2] + face * t * 0.6)
    body.add(part, backing, B.cyl(bc, r * 0.86, t, 14, bevel=0.0, rot=(90, 0, 0)))


def head(body):
    c, r = HOOD
    body.add("Head", "robe",
             B.ell(c, r, 12, 7),
             B.ell((0, 1.48, 0.32), (0.66, 0.5, 0.44), 10, 6),
             *[B.rbox((0.58 * k, 1.42, -0.06), (0.1, 0.78, 0.6), bevel=0.04, segments=1, rot=(-6, 0, -5 * k), taper=(1.0, 0.7))
               for k in (-1, 1)])
    body.add("Head", "plate", N.torus(B, (0, 1.6, -0.36), (0.62, 0.64), 0.06, 16, 4, rot=(90, 0, 0)))  # the hood's indigo rim
    # crescent circlet on the brow (stands proud of the hood's front)
    crescent(body, "Head", (0, 2.08, -0.58), 0.16, face=-1, bite=(0.35, 0.3), backing="plate")
    # the halo, floating above
    halo_c, halo_r, halo_rot = (0, 2.64, 0.16), 0.5, (-12, 0, 0)
    body.add("Head", "glow", N.torus(B, halo_c, halo_r, 0.05, 20, 4, rot=halo_rot),
             *[N.star(B, N.ring_point(halo_c, halo_r, a, halo_rot), 0.09) for a in (0, 90, 180, 270)])
    body.add("Head", "star", *[N.star(B, N.on_ell(c, r, yaw, p, 1.01), 0.035) for yaw, p in ((60, 30), (-60, 40), (130, 30), (-140, 20), (180, 60))])


def coat(body):
    f = -0.52
    body.add("UpperTorso", "robe", B.rbox((0, 0.34, -0.38), (1.78, 1.22, 0.2), bevel=0.08, segments=1, taper=(1.05, 1.0)))
    body.add("UpperTorso", "plate",
             B.rbox((0, 0.34, f + 0.04), (0.14, 1.2, 0.05), bevel=0.0, segments=1),  # the coat's front edge
             N.torus(B, (0, 1.0, 0.02), (0.52, 0.44), 0.08, 14, 4))  # collar
    # the crescent cradling a star cross
    crescent(body, "UpperTorso", (-0.12, 0.5, f - 0.02), 0.42, face=-1, bite=(0.5, 0.22), backing="robe")
    body.add("UpperTorso", "glow", *N.sparkle(B, (0.2, 0.54, f - 0.08), 0.3), N.star(B, (0.2, 0.54, f - 0.09), 0.08))
    body.add("UpperTorso", "star", *[N.star(B, (x, y, f + 0.02), 0.03) for x, y in ((0.62, 0.86), (-0.6, 0.06), (0.6, 0.02), (-0.66, 0.86))])
    # a nebula sash from the right shoulder to the left hip
    body.add("UpperTorso", "nebula", N.ribbon(B, [(0.66, 0.92, f - 0.02), (0.3, 0.6, f - 0.04), (-0.3, 0.0, f - 0.04), (-0.72, -0.42, -0.48)],
                                              (0.22, 0.22, 0.22, 0.22), t=0.04, side=(0, 0, 1)))
    # belt of star pouches
    body.add("LowerTorso", "plate", *[B.rbox((x, -0.66, -0.52), (0.22, 0.2, 0.1), bevel=0.04, segments=1) for x in (-0.6, 0.6)])
    body.add("LowerTorso", "glow", *[N.star(B, (x, -0.64, -0.58), 0.045) for x in (-0.6, 0.6)],
             N.torus(B, (0, -0.63, -0.52), 0.09, 0.025, 10, 3, rot=(90, 0, 0)))
    # coat skirt: front split panels + a back panel, starlight hem
    body.add("LowerTorso", "cape",
             *[B.rbox((0.44 * k, -1.28, -0.48), (0.66, 1.1, 0.06), bevel=0.02, segments=1, rot=(5, 0, -4 * k), taper=(1.2, 1.0)) for k in (-1, 1)],
             B.rbox((0, -1.3, 0.52), (1.6, 1.1, 0.06), bevel=0.02, segments=1, rot=(-5, 0, 0), taper=(1.2, 1.0)))
    body.add("LowerTorso", "glow",
             *[B.rbox((0.46 * k, -1.81, -0.53), (0.76, 0.04, 0.03), bevel=0.0, segments=1, rot=(5, 0, -4 * k)) for k in (-1, 1)],
             B.rbox((0, -1.83, 0.57), (1.84, 0.04, 0.03), bevel=0.0, segments=1, rot=(-5, 0, 0)))
    body.add("LowerTorso", "plate", *[B.rbox((0.12 * k, -1.28, -0.52), (0.06, 1.06, 0.05), bevel=0.0, segments=1, rot=(5, 0, 0)) for k in (-1, 1)])


def pack(body):
    z = 0.62
    body.add("UpperTorso", "plate",
             B.rbox((0, 0.3, z), (1.2, 1.3, 0.14), bevel=0.04, segments=1),
             B.rbox((0, 1.0, z + 0.2), (1.2, 0.08, 0.36), bevel=0.02, segments=1),
             B.rbox((0, -0.36, z + 0.2), (1.2, 0.1, 0.36), bevel=0.02, segments=1))
    for x in (-0.38, 0.0, 0.38):
        h = 1.16 if x == 0 else 1.0
        body.add("UpperTorso", "glow", B.cyl((x, 0.3 + (h - 1.0) / 2, z + 0.24), 0.13, h, 8, bevel=0.0))
        body.add("UpperTorso", "metal", B.cyl((x, 0.36 + h / 2 + (h - 1.0) / 2, z + 0.24), 0.15, 0.1, 8, bevel=0.02),
                 B.cyl((x, 0.3 + (h - 1.0) / 2, z + 0.24), 0.145, 0.05, 8, bevel=0.0))
        body.add("UpperTorso", "glow", N.star(B, (x, 0.48 + h / 2 + (h - 1.0) / 2, z + 0.24), 0.07))
    # a little ringed moon on top of the frame
    body.add("UpperTorso", "moon", B.ell((0.46, 1.22, z + 0.2), (0.14, 0.14, 0.14), 8, 5))
    body.add("UpperTorso", "glow", N.torus(B, (0.46, 1.22, z + 0.2), 0.24, 0.02, 14, 3, rot=(20, 0, 20)))
    # straps over the shoulders
    body.add("UpperTorso", "plate", *[B.rbox((0.46 * k, 0.9, -0.1), (0.16, 0.06, 1.2), bevel=0.02, segments=1) for k in (-1, 1)])


def arms(body):
    for k, side in B.SIDES:
        x = 1.36 * k
        body.add(f"{side}UpperArm", "moon", B.ell((x, 0.96, 0), (0.36, 0.3, 0.36), 10, 6))
        body.add(f"{side}UpperArm", "crater", *[N.seg(B, p, (p[0] * 1.03, p[1] + 0.03, p[2] * 1.1), 0.07, 0.08, 6) for p in
                                                ((x + 0.12 * k, 1.2, -0.12), (x + 0.26 * k, 0.94, 0.16))])
        body.add(f"{side}LowerArm", "plate", B.cyl((x, -0.5, 0), 0.32, 0.18, 10, bevel=0.03))
        body.add(f"{side}LowerArm", "glow", B.cyl((x, -0.4, 0), 0.325, 0.03, 12, bevel=0.0))


def legs(body):
    for k, side in B.SIDES:
        lx = 0.5 * k
        body.add(f"{side}LowerLeg", "plate", B.cyl((lx, -2.38, -0.02), 0.38, 0.1, 10, bevel=0.02))
        body.add(f"{side}Foot", "glow", N.star(B, (lx, -2.66, -0.68), 0.05))


def build(lp):
    plp = N.protect(lp)
    body = B.Body(plp)
    B.base(body, plp, {
        "arm": 0.33, "fore": 0.3, "leg": 0.39, "shin": 0.34, "torso": (1.9, 1.5, 0.95),
        "taper": 1.02, "sleeve": "long", "hands": "glove", "boot": -2.38, "bootr": 0.36,
    })
    head(body)
    coat(body)
    pack(body)
    arms(body)
    legs(body)
    return {
        "batch": "11p5",
        "budget": "hero",
        "rig": "r15",
        "pieces": body.finish(2600, 110),
        "colors": {
            "skin": (240, 196, 164),
            "eye": (32, 26, 40),
            "hair": (70, 50, 110),
            "shirt": (196, 192, 228),   # moon-silver sleeves
            "pants": (52, 46, 110),
            "dark": (30, 28, 64),
            "glove": (226, 224, 244),
            "robe": (220, 208, 248),    # moon-silver (lilac) coat and hood
            "cape": (98, 62, 172),      # violet skirt panels
            "nebula": (214, 88, 184),   # sash
            "plate": (44, 42, 108),     # indigo trim, pack frame
            "metal": (176, 172, 214),
            "moon": (196, 192, 214),    # little moons
            "crater": (140, 132, 176),
            "star": (120, 110, 200),    # star speckles (violet on the pale hood)
            "glow": (150, 236, 240),
        },
        "meta": {"skin": "MOON_MEDIC", "hero": "MEDIC", "display": "Moon Medic", "base": "hunter/MEDIC",
                 "theme": "NEBULA", "premium": True},
    }
