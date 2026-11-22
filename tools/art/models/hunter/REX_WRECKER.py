"""REX_WRECKER - Brush Beater premium skin (Tyrant King theme, PREMIUM_SKINS.md, batch 11p4): the tyrant's
barbarian warlord, its own heavy silhouette (not the brush outfit repainted):

  * bare, bulky arms; wild hair under a circlet made from a rex's lower jaw, its fangs standing up
    like a crown; red glowing war-paint stripes on the cheeks (the face stays friendly)
  * rex-head shoulder guards: a bone rex skull on each shoulder, jaws open, eyes glowing red
  * a dark fur vest over a crimson tunic, a bone breast-claw on a crossing strap
  * a heavy spiked belt (bone spikes, a big skull buckle with glowing eyes) over a fur kilt with
    crimson war-flaps
  * the jaw club slung across the back: a whole rex lower jaw full of teeth on a bone haft, red
    runes along it
  * spiked bone wristbands with runes, fur-topped boots

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


def head(body):
    # wild hair: a mane swept back, tufts
    body.add("Head", "hair",
             B.rbox((0, 1.98, 0.08), (1.16, 0.4, 1.06), bevel=0.18),
             B.rbox((0, 1.62, 0.3), (1.16, 0.7, 0.6), bevel=0.24),
             *[B.ell(c, (0.2, 0.34, 0.18), 7, 5, rot=r) for c, r in (
                 ((-0.36, 2.2, 0.2), (40, 0, 25)), ((0.0, 2.26, 0.26), (45, 0, 0)), ((0.36, 2.2, 0.2), (40, 0, -25)),
                 ((-0.2, 1.9, 0.62), (70, 0, 10)), ((0.2, 1.9, 0.62), (70, 0, -10)))])
    # the jaw circlet: a U of jawbone round the head, fangs standing up (bigger at the front)
    pts = []
    for yaw in range(-150, 151, 30):
        a = math.radians(yaw)
        pts.append((0.6 * math.sin(a), 1.92, 0.06 - 0.58 * math.cos(a)))
    body.add("Head", "bone2", *[T.seg(B, p, q, 0.075, 0.075, 6) for p, q in zip(pts, pts[1:])])
    body.add("Head", "bone", *[T.tooth(B, (p[0], 1.96, p[2]), (p[0] * 1.06, 1.96 + (0.36 if abs(p[0]) < 0.35 and p[2] < 0 else 0.24), p[2] * 1.06), 0.06, 4)
                               for p in pts[1:-1]])
    # war paint: two glowing stripes on each cheek
    body.add("Head", "glow", *[T.rod(B, (0.3 * k, 1.5 - 0.1 * i, -0.47), (0.44 * k, 1.44 - 0.1 * i, -0.38), 0.024, 4) for k in (-1, 1) for i in range(2)])


def shoulders(body):
    for k, side in B.SIDES:
        x = 1.42 * k
        part = f"{side}UpperArm"
        # a fur pad under the skull
        body.add(part, "fur", B.ell((x, 0.88, 0), (0.48, 0.2, 0.5), 7, 4))
        sk = T.skull(B, w=1.0, length=0.95, h=1.0, teeth=4, jaw=24)
        T.place_groups(sk, at=(x + 0.06 * k, 1.2, 0.02), s=0.86, yaw=-90 * k)
        T.add_groups(body, part, sk)
        # spiked bone wristbands
        body.add(f"{side}LowerArm", "bone", B.cyl((x, -0.42, 0), 0.38, 0.3, 8, bevel=0.03),
                 *[T.tooth(B, (x + 0.3 * k * math.cos(a), -0.42, 0.3 * math.sin(a)), (x + 0.5 * k * math.cos(a), -0.4, 0.5 * math.sin(a)), 0.06, 4)
                   for a in (-0.9, 0.0, 0.9)])
        body.add(f"{side}LowerArm", "glow", B.cyl((x, -0.42, 0), 0.39, 0.05, 8, bevel=0.0))


def torso(body):
    f = -0.54
    # fur vest: two front panels and the back
    body.add("UpperTorso", "fur",
             *[B.rbox((0.62 * k, 0.24, f + 0.06), (0.5, 1.4, 0.12), bevel=0.06, segments=1) for k in (-1, 1)],
             B.rbox((0, 0.3, 0.5), (1.9, 1.3, 0.12), bevel=0.06, segments=1))
    # crossing strap + a big bone claw on it
    body.add("UpperTorso", "dark", B.rbox((0, 0.2, f), (0.18, 1.7, 0.07), bevel=0.02, rot=(0, 0, 38)))
    body.add("UpperTorso", "bone", T.seg(B, (-0.16, 0.5, f - 0.06), (0.1, 0.02, f - 0.1), 0.12, 0.0, 5))
    body.add("UpperTorso", "glow", B.ell((-0.18, 0.54, f - 0.08), (0.07, 0.07, 0.04), 5, 3))
    # the jaw club across the back: a bone haft, a cleaver head made from a rex jaw (teeth out), runes
    club = {"bone2": [T.seg(B, (0, 0, 0), (0, 2.75, 0), 0.08, 0.08, 6), B.ell((0, 2.79, 0), (0.12, 0.1, 0.12), 6, 3)],
            "bone": [B.rbox((-0.36, 2.2, 0), (0.64, 1.04, 0.18), bevel=0.07, segments=1, taper=(1.25, 1.0)),
                     *[T.tooth(B, (-0.66, 1.78 + 0.17 * i, 0), (-0.98, 1.76 + 0.17 * i, 0), 0.07, 4) for i in range(6)]],
            "dark": [B.cyl((0, 0.3 + 0.12 * i, 0), 0.1, 0.08, 6, bevel=0.0) for i in range(3)],
            "glow": T.crack(B, [(-0.24, 1.8, 0.1), (-0.42, 2.06, 0.1), (-0.26, 2.32, 0.1), (-0.4, 2.56, 0.1)], r=0.03)}
    T.place_groups(club, at=(0.86, -0.5, 0.7), roll=24)
    T.add_groups(body, "UpperTorso", club)

def waist(body):
    # spiked belt + skull buckle
    body.add("LowerTorso", "dark", B.rbox((0, -0.62, 0), (2.02, 0.26, 1.08), bevel=0.06))
    spikes = []
    for yaw in range(-150, 181, 30):
        r = math.radians(yaw)
        x, z = 1.0 * math.sin(r), -0.54 * math.cos(r)
        if abs(yaw) < 20:
            continue
        spikes.append(T.tooth(B, (x, -0.62, z), (x * 1.18, -0.62, z * 1.3), 0.06, 4))
    body.add("LowerTorso", "bone", *spikes)
    sk = T.skull(B, w=1.0, length=0.7, h=1.0, teeth=3)
    sk["bone2"] = []
    T.place_groups(sk, at=(0, -0.54, -0.7), s=0.46, pitch=-60)
    T.add_groups(body, "LowerTorso", sk)
    # fur kilt + crimson war-flaps front and back
    body.add("LowerTorso", "fur", B.cyl((0, -1.0, 0), (1.04, 0.56), 0.5, 12, top=0.94, bevel=0.04))
    body.add("LowerTorso", "cloth", *[B.rbox((0, -1.28, z), (0.62, 0.66, 0.05), bevel=0.02, segments=1, taper=(1 / 0.8, 1.0)) for z in (-0.6, 0.6)])
    body.add("LowerTorso", "gold", *[B.rbox((0, -1.58, z), (0.66, 0.05, 0.06), bevel=0.0, segments=1) for z in (-0.61, 0.61)])


def boots(body):
    for k, side in B.SIDES:
        lx = 0.5 * k
        body.add(f"{side}LowerLeg", "fur", B.cyl((lx, -2.08, 0), 0.47, 0.22, 10, bevel=0.06))


def build(lp):
    plp = T.protect(lp)
    body = B.Body(plp)
    B.base(body, plp, {
        "arm": 0.39, "fore": 0.36, "leg": 0.43, "shin": 0.38, "torso": (2.05, 1.55, 1.02),
        "taper": 1.08, "sleeve": "none", "hands": "dark", "hand": 1.15, "boot": -2.12,
        "bootr": 0.43, "foot": 1.08, "armx": 1.42, "brow": 0.095,
    })
    head(body)
    shoulders(body)
    torso(body)
    waist(body)
    boots(body)
    return {
        "batch": "11p4",
        "budget": "hero",
        "rig": "r15",
        "pieces": body.finish(2400, 110),
        "colors": {
            "skin": (214, 158, 116),
            "eye": (32, 26, 26),
            "hair": (120, 34, 30),     # wild dark-red mane
            "shirt": (128, 20, 32),    # crimson tunic
            "pants": (60, 30, 30),
            "dark": T.LEATHER,
            "fur": (92, 84, 82),        # wolf-grey fur (reads against skin and leather)
            "cloth": T.CRIMSON,
            "bone": T.BONE,
            "bone2": T.BONE2,
            "gold": T.GOLD,
            "glow": T.GLOW,
        },
        "meta": {"skin": "REX_WRECKER", "hero": "SHOTGUN", "display": "Rex Wrecker", "base": "hunter/SHOTGUN",
                 "theme": "TYRANT_KING", "premium": True},
    }
