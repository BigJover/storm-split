"""ROYAL_REMEDY - Field Medic premium skin (Tyrant King theme, PREMIUM_SKINS.md, batch 11p4): the tyrant's
court shaman-healer, its own long-coated silhouette (not the medic outfit repainted):

  * a bone headdress: a fan of rex fangs rising behind the head like a halo, on a crimson band
    with gold trim and a glowing red rune-stone on the brow; two braids at the sides (no mask:
    the face stays open and friendly)
  * a long crimson coat to the knees (front split into two panels, gold hem trim), wide bone cuffs,
    a column of glowing red runes down the front
  * a bone totem staff on the back rising above the head: a small rex skull at the top with glowing
    eyes, bone rings with rune bands, hanging fang charms
  * a satchel at the hip (bone-white leather, gold clasp) with two glowing red remedy vials, and a
    bone-charm necklace with a small rex skull pendant
  * no red cross anywhere (protected emblem): the healer reads through the vials, satchel and staff

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
    body.add("Head", "hair",
             B.rbox((0, 1.74, 0.1), (1.16, 0.86, 1.0), bevel=0.4, segments=3),
             *[B.capsule(None, (0.56 * k, 1.5, 0.05), (0.6 * k, 0.86, 0.02), 0.11, 0.08, subdiv=1) for k in (-1, 1)])
    body.add("Head", "gold", *[B.cyl((0.6 * k, 0.86, 0.02), 0.1, 0.08, 6, bevel=0.0) for k in (-1, 1)])  # braid ties
    # a thin bone circlet with gold trim, the rune-stone on the brow
    body.add("Head", "bone2", B.cyl((0, 1.96, 0.04), (0.6, 0.56), 0.1, 14, bevel=0.02))
    body.add("Head", "gold", B.cyl((0, 1.9, 0.04), (0.61, 0.57), 0.03, 14, bevel=0.0))
    body.add("Head", "glow", B.ell((0, 1.98, -0.56), (0.08, 0.1, 0.05), 6, 3))
    # the fang halo behind the head: a bone ring, fangs fanning out round its top (a sun crown)
    cy, R, z = 1.7, 0.74, 0.46
    ring = [(R * math.cos(math.radians(a)), cy + R * math.sin(math.radians(a)), z) for a in range(-20, 201, 20)]
    body.add("Head", "bone2", *[T.seg(B, p, q, 0.07, 0.07, 5) for p, q in zip(ring, ring[1:])])
    fangs = []
    for a in range(0, 181, 20):
        r = math.radians(a)
        L = 0.62 - 0.34 * abs(a - 90) / 90
        fangs.append(T.tooth(B, (R * math.cos(r), cy + R * math.sin(r), z), ((R + L) * math.cos(r), cy + (R + L) * math.sin(r), z + 0.04), 0.075, 4))
    body.add("Head", "bone", *fangs)
    body.add("Head", "glow", *[B.ell((R * math.cos(math.radians(a)), cy + R * math.sin(math.radians(a)), z - 0.06), (0.05, 0.05, 0.03), 5, 3)
                               for a in (30, 70, 110, 150)])

def coat(body):
    f = -0.53
    # long coat skirt: two front panels split in the middle, a back panel, sides
    body.add("LowerTorso", "cloth",
             *[B.rbox((0.48 * k, -1.36, -0.54), (0.88, 1.36, 0.06), bevel=0.02, segments=1, rot=(4, 0, -4 * k), taper=(1 / 1.3, 1.0)) for k in (-1, 1)],
             B.rbox((0, -1.36, 0.56), (1.9, 1.36, 0.06), bevel=0.02, segments=1, rot=(-4, 0, 0), taper=(1 / 1.25, 1.0)),
             *[B.rbox((1.02 * k, -1.36, 0), (0.06, 1.36, 1.0), bevel=0.02, segments=1, rot=(0, 0, 4 * k)) for k in (-1, 1)])
    body.add("LowerTorso", "gold",
             *[B.rbox((0.5 * k, -2.02, -0.58), (0.98, 0.06, 0.06), bevel=0.0, segments=1) for k in (-1, 1)],
             B.rbox((0, -2.02, 0.61), (2.1, 0.06, 0.06), bevel=0.0, segments=1))
    # the coat's front edges + collar in deep crimson, runes down the front
    body.add("UpperTorso", "cloth2", *[B.rbox((0.12 * k, 0.24, f - 0.01), (0.12, 1.5, 0.05), bevel=0.01, segments=1) for k in (-1, 1)],
             B.cyl((0, 0.98, 0.02), (0.6, 0.5), 0.26, 12, top=0.9, bevel=0.05))
    runes = []
    for i in range(4):
        y = 0.8 - 0.36 * i
        runes += T.crack(B, [(-0.3, y, f - 0.01), (-0.42, y - 0.12, f - 0.01), (-0.3, y - 0.24, f - 0.01)], r=0.026)
    body.add("UpperTorso", "glow", *runes)
    # bone cuffs
    for k, side in B.SIDES:
        body.add(f"{side}LowerArm", "bone", B.cyl((1.36 * k, -0.46, 0), 0.36, 0.24, 8, bevel=0.03, top=1.12))
        body.add(f"{side}LowerArm", "glow", B.cyl((1.36 * k, -0.46, 0), 0.37, 0.04, 8, bevel=0.0))
    # small bone shoulder caps
    for k, side in B.SIDES:
        body.add(f"{side}UpperArm", "bone", B.ell((1.36 * k, 0.86, 0), (0.42, 0.16, 0.44), 7, 3, rot=(0, 0, -18 * k)))


def staff(body):
    x, z = 0.56, 0.66
    body.add("UpperTorso", "dark", T.seg(B, (x, -1.6, z), (x - 0.12, 2.4, z), 0.065, 0.065, 6),
             B.cyl((x - 0.02, 0.6, z), 0.1, 0.1, 6, bevel=0.0))  # binding
    body.add("UpperTorso", "bone", *[B.cyl((x - 0.12 * (y + 1.6) / 4.0, y, z), 0.095, 0.08, 6, bevel=0.0) for y in (1.4, 1.7, 2.0)])
    body.add("UpperTorso", "glow", *[B.cyl((x - 0.12 * (y + 1.6) / 4.0, y, z), 0.085, 0.14, 6, bevel=0.0) for y in (1.55, 1.85)])
    sk = T.skull(B, w=1.0, length=0.85, h=1.0, teeth=3, jaw=18)
    T.place_groups(sk, at=(x - 0.12, 2.62, z), s=0.62, pitch=8)
    T.add_groups(body, "UpperTorso", sk)
    # hanging fang charms under the skull
    body.add("UpperTorso", "bone", *[T.tooth(B, (x - 0.12 + dx, 2.26, z - 0.05), (x - 0.12 + dx, 1.98, z - 0.07), 0.04, 4) for dx in (-0.14, 0.14)])


def satchel(body):
    body.add("RightUpperLeg", "bone2", B.rbox((1.14, -1.2, -0.16), (0.26, 0.52, 0.58), bevel=0.06))
    body.add("RightUpperLeg", "gold", B.rbox((1.2, -1.06, -0.16), (0.2, 0.2, 0.52), bevel=0.03), B.rbox((1.29, -1.14, -0.16), (0.05, 0.12, 0.12), bevel=0.0))
    body.add("RightUpperLeg", "glow", *[T.seg(B, (1.1, -0.97, dz), (1.1, -0.68, dz), 0.065, 0.055, 6) for dz in (-0.32, -0.04)])
    # bone totem charms hanging from the belt (left): three short bones with glowing beads
    body.add("LowerTorso", "bone", *[T.seg(B, (-0.55 + 0.16 * i, -0.72, -0.6), (-0.55 + 0.16 * i, -1.08 - 0.08 * i, -0.62), 0.04, 0.035, 5) for i in range(3)])
    body.add("LowerTorso", "glow", *[B.ell((-0.55 + 0.16 * i, -1.1 - 0.08 * i, -0.62), (0.05, 0.05, 0.05), 5, 3) for i in range(3)])
    # strap across the chest to the left shoulder
    body.add("UpperTorso", "dark", B.rbox((0, 0.22, -0.5), (0.13, 1.6, 0.05), bevel=0.02, rot=(0, 0, 34)))
    # bone-charm necklace with a skull pendant
    body.add("UpperTorso", "bone", *[B.ell((0.36 * math.sin(math.radians(a)), 0.86 - 0.2 * math.cos(math.radians(a)), -0.56), (0.05, 0.07, 0.04), 5, 3)
                                     for a in (-60, -35, 35, 60)])
    sk = T.skull(B, w=1.0, length=0.7, h=1.0, teeth=2)
    sk["bone2"] = []
    T.place_groups(sk, at=(0, 0.6, -0.66), s=0.26, pitch=-70)
    T.add_groups(body, "UpperTorso", sk)


def build(lp):
    plp = T.protect(lp)
    body = B.Body(plp)
    B.base(body, plp, {
        "arm": 0.33, "fore": 0.3, "leg": 0.39, "shin": 0.34, "torso": (1.9, 1.5, 0.95),
        "taper": 1.02, "sleeve": "long", "hands": "glove", "boot": -2.38, "bootr": 0.36,
    })
    head(body)
    coat(body)
    staff(body)
    satchel(body)
    return {
        "batch": "11p4",
        "budget": "hero",
        "rig": "r15",
        "pieces": body.finish(2400, 110),
        "colors": {
            "skin": (226, 176, 136),
            "eye": (32, 26, 26),
            "hair": (40, 30, 30),
            "shirt": (150, 22, 36),    # crimson coat body + sleeves
            "pants": (60, 30, 32),
            "dark": T.LEATHER,
            "glove": (234, 224, 198),  # bone-white gloves
            "cloth": T.CRIMSON,
            "cloth2": T.CRIMSON2,
            "bone": T.BONE,
            "bone2": T.BONE2,
            "gold": T.GOLD,
            "glow": T.GLOW,
        },
        "meta": {"skin": "ROYAL_REMEDY", "hero": "MEDIC", "display": "Royal Remedy", "base": "hunter/MEDIC",
                 "theme": "TYRANT_KING", "premium": True},
    }
