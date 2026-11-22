"""REX_ROYAL - Big Game Hunter premium skin (Tyrant King theme, PREMIUM_SKINS.md, batch 11p4): the
tyrant monarch himself, its own silhouette (not the safari outfit repainted):

  * a full T. rex jaw-helm: the bone skull worn over the head, its long snout jutting out over the
    brow like a visor with a row of fangs hanging from it, the lower jaw bones framing the cheeks;
    the face (eyes, brows, moustache) stays readable and friendly under it. The skull's eyes glow red.
  * a bone crown on the skull: a gold band (trim) with a ring of tall fang points and red glowing gems
  * a dark fur mantle round the shoulders, a long crimson royal cape to the calves with a gold hem
    line and a glowing rex sigil (a skull with red eyes) on its back
  * bone pauldrons (three overlapping plates) with gold-edged epaulette fringe and fang spikes
  * a bone ribcage breastplate over a crimson tunic, a glowing red heart gem at its centre
  * bone vambraces with red runes, crimson leather gloves, a crimson tabard with a gold hem,
    bone greaves, claw-toed boots

`glow` = Neon in game (Shared/SkinFx: primal / roar element). Built on the shared R15 figure
(_body.py) directly, same R15 envelope (#434: hit parts unchanged; crown, mantle, cape extend modestly).
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

HELM_AT = (0, 2.26, 0.1)
HELM_S = 1.15


def helm(body):
    sk = T.skull(B, w=1.0, length=1.05, h=1.0, teeth=5)
    T.place_groups(sk, at=HELM_AT, s=HELM_S, pitch=9)
    T.add_groups(body, "Head", sk)
    # the lower jaw bones down the cheeks (hinge behind the ear -> chin), short fangs pointing up
    for k in (-1, 1):
        a, b = (0.6 * k, 1.86, 0.22), (0.5 * k, 1.22, -0.3)
        body.add("Head", "bone2", T.seg(B, a, b, 0.1, 0.07, 6))
        body.add("Head", "bone", *[T.tooth(B, (0.55 * k - 0.02 * k * i, 1.5 - 0.12 * i, -0.02 - 0.12 * i),
                                           (0.6 * k - 0.02 * k * i, 1.62 - 0.12 * i, -0.08 - 0.12 * i), 0.035) for i in range(2)])
    # the crown on the skull: a gold band and a ring of fang points, gems glowing between them
    cy = HELM_AT[1] + 0.5
    body.add("Head", "gold", B.cyl((0, cy, 0.12), (0.38, 0.38), 0.12, 12, bevel=0.0, top=1.08))
    pts, gems = [], []
    for i, yaw in enumerate(range(0, 360, 45)):
        a = math.radians(yaw)
        x, z = 0.38 * math.sin(a), 0.12 - 0.38 * math.cos(a)
        h = 0.42 if yaw == 0 else (0.32 if yaw in (45, 315) else 0.24)
        pts.append(T.tooth(B, (x, cy + 0.04, z), (x * 1.12, cy + 0.06 + h, z + (0.12 - z) * -0.12), 0.08, 5))
        b = math.radians(yaw + 22.5)
        gems.append(B.ell((0.4 * math.sin(b), cy, 0.12 - 0.4 * math.cos(b)), (0.045, 0.045, 0.045), 5, 3))
    body.add("Head", "bone", *pts)
    body.add("Head", "glow", *gems, B.ell((0, cy + 0.02, -0.28), (0.07, 0.08, 0.05), 6, 3))  # the front jewel
    # moustache + brows (kept, regal) and hair at the back under the skull
    body.add("Head", "hair", *[B.ell((0.15 * k, 1.37, -0.535), (0.18, 0.07, 0.06), 8, 5, rot=(0, 0, 18 * k)) for k in (-1, 1)],
             B.rbox((0, 1.55, 0.2), (1.12, 0.6, 0.8), bevel=0.3))


def mantle(body):
    """A dark fur mantle: a ring of shaggy lumps round the neck and over the shoulders."""
    lumps = []
    for yaw in range(-150, 181, 30):
        a = math.radians(yaw)
        x, z = 0.82 * math.sin(a), 0.02 - 0.5 * math.cos(a)
        lumps.append(B.ell((x, 1.0, z), (0.36, 0.2, 0.28), 7, 4, rot=(0, yaw, 0)))
    body.add("UpperTorso", "fur", *lumps)


def cape(body):
    """A long crimson cape hung from the mantle, flaring a little, gold hem, a rex sigil on the back."""
    top, bot = 0.95, -2.35
    h = top - bot
    zc, lean = 0.72, math.sin(math.radians(6))
    body.add("UpperTorso", "cloth",
             B.rbox((0, (top + bot) / 2, zc), (2.1, h, 0.08), bevel=0.03, segments=1, rot=(-6, 0, 0), taper=(1 / 1.3, 1.0)),
             # folds: soft ridges down the back
             *[B.rbox((x, (top + bot) / 2 - 0.1, zc + 0.05), (0.18, h * 0.88, 0.06), bevel=0.03, segments=1, rot=(-6, 0, 0))
               for x in (-0.62, 0.0, 0.62)])
    zb = zc + (h / 2) * lean
    body.add("UpperTorso", "gold", B.rbox((0, bot + 0.07, zb + 0.01), (2.14, 0.09, 0.1), bevel=0.0, segments=1, rot=(-6, 0, 0)))
    # the sigil: a rex skull in bone on the back, its eyes glowing red
    sk = T.skull(B, w=1.0, length=0.8, h=1.0, teeth=3)
    T.place_groups(sk, at=(0, 0.0, zc - 0.7 * lean + 0.2), s=0.48, yaw=180, pitch=-84)  # lying flat, snout down
    sk["bone2"] = []
    T.add_groups(body, "UpperTorso", sk)
    # clasps: gold discs with glowing gems at the cape's top corners (front of the shoulders)
    body.add("UpperTorso", "gold", *[B.cyl((0.62 * k, 0.86, -0.52), 0.11, 0.05, 8, bevel=0.0, rot=(90, 0, 0)) for k in (-1, 1)],
             B.rbox((0, 0.86, -0.53), (1.0, 0.04, 0.03), bevel=0.0, segments=1))
    body.add("UpperTorso", "glow", *[B.ell((0.62 * k, 0.86, -0.56), (0.05, 0.05, 0.03), 5, 3) for k in (-1, 1)])


def chest(body):
    f = -0.53
    # crimson tunic over the shirt (front), a bone ribcage plate on it, red heart gem
    body.add("UpperTorso", "bone",
             B.rbox((0, 0.62, f - 0.03), (0.16, 0.78, 0.07), bevel=0.03, segments=1),  # sternum
             *[B.rbox((0.3 * k, 0.8 - 0.2 * i, f - 0.03), (0.46 - 0.04 * i, 0.09, 0.07), bevel=0.02, segments=1,
                      rot=(0, 10 * k, -18 * k)) for k in (-1, 1) for i in range(3)])
    body.add("UpperTorso", "glow", B.ell((0, 0.4, f - 0.04), (0.12, 0.14, 0.05), 6, 3))
    # gold-buckled crimson belt, a tabard with a gold hem
    body.add("LowerTorso", "gold", B.rbox((0, -0.63, -0.52), (0.36, 0.24, 0.05), bevel=0.02, segments=1))
    body.add("LowerTorso", "glow", B.ell((0, -0.63, -0.555), (0.07, 0.07, 0.03), 5, 3))
    body.add("LowerTorso", "cloth", B.rbox((0, -1.12, -0.52), (0.72, 0.8, 0.05), bevel=0.02, segments=1, taper=(1 / 0.85, 1.0)))
    body.add("LowerTorso", "gold", B.rbox((0, -1.5, -0.53), (0.74, 0.05, 0.04), bevel=0.0, segments=1))


def pauldrons(body):
    for k, side in B.SIDES:
        x = 1.4 * k
        part = f"{side}UpperArm"
        body.add(part, "bone",
                 B.ell((x, 0.98, 0), (0.55, 0.2, 0.56), 8, 4, rot=(0, 0, -14 * k)),
                 B.ell((x + 0.12 * k, 0.78, 0), (0.5, 0.16, 0.52), 8, 3, rot=(0, 0, -26 * k)),
                 # fangs along the top plate
                 *[T.tooth(B, (x + dx * k, 1.12, z), (x + (dx + 0.14) * k, 1.46 - abs(z) * 0.3, z * 1.1), 0.07, 4)
                   for dx, z in ((-0.12, -0.24), (0.04, 0.0), (-0.12, 0.24))])
        # gold epaulette edge + fringe of short gold cords
        body.add(part, "gold", B.ell((x + 0.2 * k, 0.66, 0), (0.42, 0.04, 0.46), 8, 2, rot=(0, 0, -30 * k)),
                 )
        # a red rune across the top plate
        body.add(part, "glow", *T.crack(B, [(x - 0.22 * k, 1.13, -0.2), (x - 0.04 * k, 1.17, 0.0), (x - 0.22 * k, 1.13, 0.2)], r=0.03))
        # bone vambraces with a red rune
        body.add(f"{side}LowerArm", "bone", B.cyl((1.38 * k, -0.36, 0), 0.34, 0.46, 8, bevel=0.03, top=0.84))
        body.add(f"{side}LowerArm", "glow", *T.crack(B, [(1.38 * k, -0.2, -0.33), (1.38 * k + 0.08, -0.32, -0.33), (1.38 * k - 0.04, -0.46, -0.31)], r=0.026))


def legs(body):
    for k, side in B.SIDES:
        lx = 0.5 * k
        body.add(f"{side}LowerLeg", "bone",
                 B.cyl((lx, -2.12, -0.04), 0.39, 0.5, 8, bevel=0.03, top=1.08),
                 B.ell((lx, -1.86, -0.3), (0.24, 0.2, 0.12), 6, 3))
        # claw toes on the boots (three bone claws)
        body.add(f"{side}Foot", "bone", *[T.tooth(B, (lx + dx, -2.85, -0.62), (lx + dx * 1.2, -2.92, -0.86), 0.06, 4) for dx in (-0.22, 0.0, 0.22)])
        body.add(f"{side}Foot", "gold", B.rbox((lx, -2.68, -0.45), (0.7, 0.06, 0.1), bevel=0.0, segments=1, rot=(-14, 0, 0)))


def build(lp):
    plp = T.protect(lp)
    body = B.Body(plp)
    B.base(body, plp, {
        "arm": 0.37, "fore": 0.33, "leg": 0.42, "shin": 0.36, "torso": (2.0, 1.55, 1.0),
        "taper": 1.08, "sleeve": "long", "hands": "glove", "boot": -2.36, "bootr": 0.38,
        "shorts": False, "armx": 1.38, "brow": 0.08,
    })
    helm(body)
    mantle(body)
    cape(body)
    chest(body)
    pauldrons(body)
    legs(body)
    return {
        "batch": "11p4",
        "budget": "hero",
        "rig": "r15",
        "pieces": body.finish(2400, 110),
        "colors": {
            "skin": (236, 188, 150),
            "eye": (32, 26, 26),
            "hair": (150, 84, 46),     # russet moustache + brows
            "shirt": (120, 18, 30),    # crimson tunic + sleeves
            "pants": (70, 22, 28),     # deep crimson breeches
            "dark": (52, 34, 32),      # leather belt, boots
            "glove": (96, 16, 26),
            "cloth": T.CRIMSON,        # the royal cape + tabard
            "fur": T.FUR,              # the mantle
            "bone": T.BONE,
            "bone2": T.BONE2,
            "gold": T.GOLD,            # trim only
            "glow": T.GLOW,            # red eyes, gems, runes (Neon in game)
        },
        "meta": {"skin": "REX_ROYAL", "hero": "RIFLE", "display": "Rex Royal", "base": "hunter/RIFLE",
                 "theme": "TYRANT_KING", "premium": True},
    }
