"""GEM_GAMEKEEPER - Big Game Hunter premium skin (Geode theme, PREMIUM_SKINS.md, batch 11p6): a crystal-crowned
rock knight, its own silhouette (not the safari outfit repainted):

  * an open-faced faceted rock helm with a CROWN of tall glowing amethyst crystals standing round it (tallest
    at the front), cheek guards; the face, brows and the Big Game Hunter's moustache stay friendly under it
  * a rock breastplate cracked open in the middle: a geode (rough stone rim round a glowing faceted gem bed
    with crystal points) with glowing cracks running out, front and back
  * boulder pauldrons with amethyst crystal clusters growing up out of them (a teal shard in each)
  * rock gauntlet cuffs with glowing crystal knuckle points, a geode belt buckle
  * a deep-violet cape of angular panels whose hem breaks into hanging crystal shards; a violet tabard
  * rock greaves, boulder knee plates sprouting small crystals, rock sabatons

`glow` = Neon in game (Shared/SkinFx). Built on the shared R15 figure (_body.py), same R15 envelope (#434:
hit parts never change; the crown, clusters and cape extend modestly past them).
"""
# art-sources: _body.py variants/_geode.py

import importlib.util
import math
from pathlib import Path

_here = Path(__file__).parent
_spec = importlib.util.spec_from_file_location("_body", _here / "_body.py")
B = importlib.util.module_from_spec(_spec)
_spec.loader.exec_module(B)
_spec = importlib.util.spec_from_file_location("_geode", _here / "variants" / "_geode.py")
G = importlib.util.module_from_spec(_spec)
_spec.loader.exec_module(G)

HELM = ((0, 2.04, 0.08), (0.66, 0.48, 0.67))


def helm(body):
    c, r = HELM
    body.add("Head", "rock",
             G.rock(B, c, r, segments=9, rings=5),
             *[G.rock(B, (0.58 * k, 1.62, 0.1), (0.1, 0.34, 0.4), rot=(0, 0, 8 * k), segments=6, rings=3) for k in (-1, 1)],
             G.rock(B, (0, 1.6, 0.52), (0.52, 0.32, 0.12), segments=6, rings=3))
    body.add("Head", "rock2", B.cyl((0, 1.97, 0.06), (0.69, 0.7), 0.12, 9, bevel=0.0))  # the crown's stone band
    glow, xt = [], []
    for yaw, h in ((0, 0.95), (-30, 0.72), (30, 0.72), (-60, 0.6), (60, 0.6), (-95, 0.48), (95, 0.48),
                   (180, 0.55), (-140, 0.45), (140, 0.45)):
        base = G.on_ell(c, r, yaw, 18, 0.96)
        out = Vector3(base[0] - c[0], 0, base[2] - c[2])
        tip = (base[0] + out[0] * 0.25, base[1] + h, base[2] + out[2] * 0.25)
        cr = G.crystal(B, base, tip, 0.1 if yaw == 0 else 0.08, 6, twist=yaw)
        (glow if abs(yaw) <= 60 or yaw == 180 else xt).append(cr)
    # little side crystals between the big front ones
    for yaw in (-15, 15, -45, 45):
        base = G.on_ell(c, r, yaw, 20, 0.97)
        xt.append(G.crystal(B, base, (base[0] * 1.2, base[1] + 0.38, base[2] * 1.08), 0.06, 6))
    body.add("Head", "glow", *glow)
    body.add("Head", "crystal", *xt)
    # a gem in the band's front
    body.add("Head", "teal", G.crystal(B, (0, 1.97, -0.66), (0, 1.97, -0.8), 0.08, 6))
    # moustache
    body.add("Head", "hair", *[B.ell((0.15 * k, 1.37, -0.535), (0.18, 0.07, 0.06), 8, 5, rot=(0, 0, 18 * k)) for k in (-1, 1)])


class Vector3(tuple):
    def __new__(cls, x, y, z):
        return tuple.__new__(cls, (x, y, z))


def chest(body):
    f = -0.55
    body.add("UpperTorso", "rock",
             B.rbox((0, 0.42, -0.42), (1.8, 1.14, 0.26), bevel=0.06, segments=1, taper=(1.06, 1.0)),
             B.rbox((0, 0.42, 0.42), (1.76, 1.1, 0.24), bevel=0.06, segments=1))
    G.add_groups(body, "UpperTorso", G.geode(B, (0, 0.48, f), (0, 0, -1), 0.44, n=9))
    body.add("UpperTorso", "glow",
             *G.crack(B, [(0.36, 0.66, f + 0.02), (0.54, 0.82, f + 0.02), (0.72, 0.94, f + 0.04)]),
             *G.crack(B, [(-0.36, 0.66, f + 0.02), (-0.52, 0.86, f + 0.02), (-0.7, 0.92, f + 0.04)]),
             *G.crack(B, [(0.3, 0.24, f + 0.02), (0.46, 0.04, f + 0.02), (0.7, -0.08, f + 0.04)]),
             *G.crack(B, [(-0.3, 0.24, f + 0.02), (-0.44, 0.0, f + 0.02), (-0.66, -0.1, f + 0.04)]))
    # belt: stone with a geode buckle
    body.add("LowerTorso", "rock", B.rbox((0, -0.63, -0.52), (0.46, 0.32, 0.08), bevel=0.02, segments=1))
    body.add("LowerTorso", "glow", G.crystal(B, (0, -0.63, -0.54), (0, -0.63, -0.68), 0.1, 6))


def pauldrons(body):
    for k, side in B.SIDES:
        x = 1.42 * k
        part = f"{side}UpperArm"
        body.add(part, "rock",
                 G.rock(B, (x, 0.94, 0), (0.6, 0.3, 0.6), rot=(0, 0, -14 * k), segments=8, rings=4),
                 G.rock(B, (x + 0.14 * k, 0.68, 0), (0.5, 0.18, 0.54), rot=(0, 0, -28 * k), segments=7, rings=3))
        cl = G.cluster(B, (x + 0.12 * k, 1.12, 0.02), (0.45 * k, 1.0, 0.1), n=6, length=0.72, r=0.11, spread=30, phase=20)
        body.add(part, "glow", cl[0], cl[3])
        body.add(part, "crystal", *cl[1:3], *cl[4:])
        body.add(part, "teal", G.crystal(B, (x - 0.12 * k, 1.1, -0.3), (x - 0.02 * k, 1.42, -0.46), 0.07, 6))
        body.add(part, "glow", *G.crack(B, [(x - 0.3 * k, 0.86, -0.56), (x, 0.8, -0.6), (x + 0.3 * k, 0.74, -0.52)], r=0.026))


def gauntlets(body):
    for k, side in B.SIDES:
        x = 1.38 * k
        body.add(f"{side}LowerArm", "rock", B.cyl((x, -0.4, 0), 0.36, 0.52, 7, bevel=0.0, top=0.8))
        body.add(f"{side}LowerArm", "glow",
                 *G.crack(B, [(x + 0.12 * k, -0.2, -0.32), (x + 0.02 * k, -0.36, -0.35), (x + 0.12 * k, -0.52, -0.33)], r=0.026))
        body.add(f"{side}Hand", "glow",
                 *[G.crystal(B, (x + dx, -0.82, -0.24), (x + dx * 1.3, -0.86, -0.42), 0.045, 5) for dx in (-0.13, 0.0, 0.13)])


def cape(body):
    panels, shards = [], []
    for i, (x, length) in enumerate(((-0.6, 2.2), (0.0, 2.45), (0.6, 2.25))):
        z = 0.62 + 0.01 * i
        panels.append(B.rbox((x, 1.0 - length / 2, z + 0.05), (0.62, length, 0.06), bevel=0.0, segments=1,
                             rot=(-3, 0, -x * 4), taper=(0.92, 1.0)))
        yb = 1.0 - length
        for dx, ln in ((-0.2, 0.32), (0.0, 0.46), (0.2, 0.3)):
            shards.append(G.crystal(B, (x + dx, yb + 0.06, z + 0.12), (x + dx * 1.15, yb - ln, z + 0.14), 0.06, 5))
    body.add("UpperTorso", "cloth", *panels)
    body.add("UpperTorso", "crystal", *shards[0::2])
    body.add("UpperTorso", "glow", *shards[1::2])
    body.add("UpperTorso", "rock", B.rbox((0, 0.98, 0.62), (1.6, 0.16, 0.14), bevel=0.0, segments=1))
    body.add("LowerTorso", "cloth",
             B.rbox((0, -1.08, -0.52), (0.66, 0.7, 0.05), bevel=0.0, segments=1, taper=(0.8, 1.0)))
    body.add("LowerTorso", "glow", G.crystal(B, (0, -1.42, -0.55), (0, -1.66, -0.55), 0.07, 5))


def legs(body):
    for k, side in B.SIDES:
        lx = 0.5 * k
        body.add(f"{side}LowerLeg", "rock",
                 B.cyl((lx, -2.14, -0.02), 0.4, 0.52, 7, bevel=0.0, top=1.1),
                 G.rock(B, (lx, -1.86, -0.3), (0.28, 0.25, 0.16), rot=(-10, 0, 0), segments=6, rings=3))
        body.add(f"{side}LowerLeg", "crystal",
                 G.crystal(B, (lx + 0.08 * k, -1.8, -0.4), (lx + 0.22 * k, -1.56, -0.56), 0.06, 5))
        body.add(f"{side}LowerLeg", "glow",
                 G.crystal(B, (lx - 0.06 * k, -1.82, -0.42), (lx - 0.06 * k, -1.62, -0.62), 0.05, 5),
                 *G.crack(B, [(lx - 0.1, -2.0, -0.41), (lx + 0.04, -2.12, -0.42), (lx - 0.06, -2.28, -0.42)], r=0.026))
        body.add(f"{side}Foot", "rock", B.rbox((lx, -2.66, -0.42), (0.74, 0.14, 0.5), bevel=0.0, segments=1, rot=(-14, 0, 0)))
        body.add(f"{side}UpperLeg", "rock", G.rock(B, (lx + 0.12 * k, -1.18, -0.06), (0.38, 0.26, 0.44), rot=(0, 0, -8 * k), segments=6, rings=3))
        body.add(f"{side}UpperLeg", "glow", *G.crack(B, [(lx + 0.0 * k, -1.2, -0.48), (lx + 0.16 * k, -1.26, -0.47), (lx + 0.3 * k, -1.2, -0.4)], r=0.024))


def build(lp):
    plp = G.protect(lp)
    body = B.Body(plp)
    B.base(body, plp, {
        "arm": 0.37, "fore": 0.33, "leg": 0.42, "shin": 0.36, "torso": (2.0, 1.55, 1.0),
        "taper": 1.08, "sleeve": "long", "hands": "gaunt", "boot": -2.36, "bootr": 0.38,
        "shorts": False, "armx": 1.38, "brow": 0.08,
    })
    helm(body)
    chest(body)
    pauldrons(body)
    gauntlets(body)
    cape(body)
    legs(body)
    return {
        "batch": "11p6",
        "budget": "hero",
        "rig": "r15",
        "pieces": body.finish(2300, 110),
        "colors": {
            "skin": (236, 188, 150),
            "eye": (32, 26, 26),
            "hair": (96, 64, 46),      # moustache and brows
            "shirt": (50, 44, 60),     # slate under-armour
            "pants": (48, 42, 58),
            "dark": (48, 42, 54),      # belt, boots
            "gaunt": (78, 74, 86),     # stone gauntlet hands
            "cloth": (74, 40, 112),    # deep violet cape + tabard
            "rock": G.ROCK,
            "rock2": G.ROCK2,
            "crystal": G.CRYSTAL,
            "teal": G.TEAL,
            "glow": G.GLOW,
        },
        "meta": {"skin": "GEM_GAMEKEEPER", "hero": "RIFLE", "display": "Gem Gamekeeper", "base": "hunter/RIFLE",
                 "theme": "GEODE", "premium": True},
    }
