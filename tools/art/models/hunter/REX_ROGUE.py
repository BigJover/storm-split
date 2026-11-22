"""REX_ROGUE - Tracker premium skin (Tyrant King theme, PREMIUM_SKINS.md, batch 11p4): the tyrant's scout,
its own lean silhouette (not the field outfit repainted):

  * a crimson hood with a raptor skull worn on top: long, narrow and low, its toothy snout jutting out
    over the brow, glowing red eyes; a crest of bone quills down the back of the hood. The face stays
    open and friendly under it.
  * a short crimson capelet over the shoulders with ragged points at the back and a red rune hem
  * a fang necklace (a row of rex teeth on a cord) with a big glowing red fang-gem in the middle
  * ONE bone pauldron (left) with three sickle claws - a rogue's asymmetry
  * dark leather jerkin with criss-cross straps, bone bracers with red runes, a bone sickle-claw
    dagger sheathed on the left thigh, a skull belt buckle, wrapped calves

`glow` = Neon in game (Shared/SkinFx). Built on the shared R15 figure (_body.py), same R15 envelope (#434).
"""
# art-sources: _body.py variants/_tyrant.py

import importlib.util
import math
from pathlib import Path

_here = Path(__file__).parent
_spec = importlib.util.spec_from_file_location("_body", _here / "_body.py")
B = importlib.util.module_from_spec(_spec)
_spec.loader.exec_module(B)
_spec = importlib.util.spec_from_file_location("_tyrant", _here / "variants" / "_tyrant.py")
T = importlib.util.module_from_spec(_spec)
_spec.loader.exec_module(T)


def hood(body):
    # the hood: a soft shell round the back and top of the head, open at the face
    body.add("Head", "cloth",
             B.ell((0, 1.72, 0.14), (0.66, 0.66, 0.62), 12, 7),
             B.ell((0, 1.32, 0.3), (0.6, 0.36, 0.42), 10, 5))  # drape at the nape
    # the raptor skull on top: narrow, long, low; snout out over the brow
    sk = T.skull(B, w=0.8, length=1.3, h=0.85, teeth=5)
    T.place_groups(sk, at=(0, 2.24, 0.04), s=1.0, pitch=6)
    # the Fang Mark: three glowing claw slashes on each side of the hood
    for k in (-1, 1):
        body.add("Head", "glow", *[T.rod(B, (0.67 * k, 1.9 - 0.02 * i, -0.05 + 0.16 * i), (0.6 * k, 1.42 - 0.02 * i, 0.12 + 0.16 * i), 0.028, 4) for i in range(3)])
    T.add_groups(body, "Head", sk)
    # bone quills down the back of the hood
    body.add("Head", "bone", *[T.tooth(B, (0, 2.25 - 0.22 * i, 0.62 + 0.1 * i), (0, 2.45 - 0.24 * i, 0.98 + 0.08 * i), 0.07, 4)
                               for i in range(4)])
    # hair fringe under the hood
    body.add("Head", "hair", B.rbox((0, 1.92, -0.36), (0.9, 0.18, 0.3), bevel=0.08))


def capelet(body):
    body.add("UpperTorso", "cloth",
             B.cyl((0, 0.86, 0.04), (1.08, 0.66), 0.42, 12, top=0.62, bevel=0.04),
             # ragged points at the back
             *[B.rbox((x, 0.38, 0.64), (0.32, 0.5, 0.05), bevel=0.0, segments=1, rot=(-12, 0, 180), taper=(0.08, 1.0))
               for x in (-0.5, 0.0, 0.5)])
    body.add("UpperTorso", "glow", B.cyl((0, 0.655, 0.04), (1.11, 0.69), 0.05, 12, bevel=0.0),
             *[T.rod(B, (x, 0.5, 0.52), (x + 0.3, 0.0, 0.5), 0.03, 4) for x in (-0.46, -0.3, -0.14)])  # claw slashes on the back


def necklace(body):
    pts = []
    for i in range(7):
        a = math.radians(-60 + 20 * i)
        x, y, z = 0.48 * math.sin(a), 0.62 - 0.22 * math.cos(a), -0.56
        if i == 3:
            continue
        pts.append(T.tooth(B, (x, y, z), (x * 1.05, y - 0.2, z - 0.02), 0.045, 4))
    body.add("UpperTorso", "bone", *pts)
    body.add("UpperTorso", "dark", *T.crack(B, [(0.48 * math.sin(math.radians(a)), 0.62 - 0.22 * math.cos(math.radians(a)), -0.55)
                                               for a in range(-70, 71, 20)], r=0.018))
    body.add("UpperTorso", "glow", T.seg(B, (0, 0.42, -0.58), (0, 0.06, -0.62), 0.1, 0.0, 5))  # the fang-gem


def straps(body):
    body.add("UpperTorso", "dark", B.rbox((0, 0.2, -0.5), (0.16, 1.5, 0.06), bevel=0.02, rot=(0, 0, -36)),
             B.rbox((0, 0.2, 0.5), (0.16, 1.5, 0.06), bevel=0.02, rot=(0, 0, 36)))
    # skull buckle
    sk = T.skull(B, w=1.0, length=0.7, h=1.0, teeth=2, eyes=True)
    sk["bone2"] = []
    T.place_groups(sk, at=(0, -0.6, -0.56), s=0.22, pitch=-70)
    T.add_groups(body, "LowerTorso", sk)


def pauldron(body):
    x = -1.38
    body.add("LeftUpperArm", "bone",
             B.ell((x, 0.96, 0), (0.5, 0.2, 0.52), 8, 4, rot=(0, 0, 16)),
             B.ell((x - 0.1, 0.76, 0), (0.44, 0.15, 0.46), 8, 3, rot=(0, 0, 28)),
             # three sickle claws curving up off the top
             *[T.seg(B, (x - 0.05 + dx, 1.1, z), (x - 0.25 + dx, 1.42, z), 0.08, 0.0, 4) for dx, z in ((0.1, -0.22), (0.0, 0.0), (0.1, 0.22))])
    body.add("LeftUpperArm", "glow", *T.crack(B, [(x + 0.2, 1.12, -0.25), (x + 0.05, 1.14, 0.0), (x + 0.2, 1.12, 0.25)], r=0.026))


def arms(body):
    for k, side in B.SIDES:
        x = 1.36 * k
        body.add(f"{side}LowerArm", "bone", B.cyl((x, -0.34, 0), 0.3, 0.46, 8, bevel=0.03, top=0.86))
        body.add(f"{side}LowerArm", "glow", *T.crack(B, [(x, -0.18, -0.3), (x + 0.07 * k, -0.32, -0.3), (x - 0.03 * k, -0.46, -0.28)], r=0.024))


def legs(body):
    for k, side in B.SIDES:
        lx = 0.5 * k
        # wrapped calves (crimson bands)
        body.add(f"{side}LowerLeg", "cloth", *[B.cyl((lx, -1.98 - 0.13 * i, 0), 0.345, 0.07, 10, bevel=0.0, rot=(8 * (-1) ** i, 0, 0)) for i in range(3)])
    # sickle-claw dagger on the left thigh (sheath + bone claw)
    body.add("LeftUpperLeg", "dark", B.rbox((-0.9, -1.3, 0.0), (0.12, 0.56, 0.22), bevel=0.04, rot=(0, 0, -6)))
    body.add("LeftUpperLeg", "bone", T.seg(B, (-0.9, -1.02, 0.0), (-0.92, -0.82, -0.2), 0.07, 0.0, 4))


def build(lp):
    plp = T.protect(lp)
    body = B.Body(plp)
    B.base(body, plp, {
        "arm": 0.31, "fore": 0.28, "leg": 0.37, "shin": 0.32, "torso": (1.85, 1.5, 0.92),
        "taper": 1.0, "sleeve": "long", "hands": "dark", "boot": -2.32, "bootr": 0.35,
    })
    hood(body)
    capelet(body)
    necklace(body)
    straps(body)
    pauldron(body)
    arms(body)
    legs(body)
    return {
        "batch": "11p4",
        "budget": "hero",
        "rig": "r15",
        "pieces": body.finish(2400, 110),
        "colors": {
            "skin": (205, 150, 108),
            "eye": (32, 26, 26),
            "hair": (60, 36, 30),
            "shirt": (58, 40, 40),     # dark leather jerkin + sleeves
            "pants": (84, 24, 30),     # deep crimson
            "dark": T.LEATHER,         # gloves, boots, straps, sheath
            "cloth": T.CRIMSON,        # the hood, capelet, wraps
            "bone": T.BONE,
            "bone2": T.BONE2,
            "glow": T.GLOW,
        },
        "meta": {"skin": "REX_ROGUE", "hero": "PISTOL", "display": "Rex Rogue", "base": "hunter/PISTOL",
                 "theme": "TYRANT_KING", "premium": True},
    }
