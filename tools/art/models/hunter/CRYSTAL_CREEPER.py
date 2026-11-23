"""CRYSTAL_CREEPER - Tracker premium skin (Geode theme, PREMIUM_SKINS.md, batch 11p6): a sleek crystal-shard
rogue, its own lean silhouette (not the field outfit repainted):

  * a FACETED hood (flat-faceted like a cut stone) open at the face, its peak swept back into a long shard
    with a glowing crystal tip, a glowing gem at the brow; the face stays open and friendly
  * ONE shard pauldron (left): a rock cap with a spray of long amethyst shards sweeping back - a rogue's
    asymmetry; a teal shard among them
  * a bandolier of glowing throwing-shards across the chest, a stone clasp
  * long glowing crystal fin-blades along the outside of both forearms, pointing back past the elbow
  * a short cloak of angular violet panels behind, each point tipped with a crystal shard
  * a crystal dagger on the right thigh, stone shin guards, pointed boots

`glow` = Neon in game (Shared/SkinFx). Built on the shared R15 figure (_body.py), same R15 envelope (#434).
"""
# art-sources: _body.py variants/_geode.py

import importlib.util
from pathlib import Path

_here = Path(__file__).parent
_spec = importlib.util.spec_from_file_location("_body", _here / "_body.py")
B = importlib.util.module_from_spec(_spec)
_spec.loader.exec_module(B)
_spec = importlib.util.spec_from_file_location("_geode", _here / "variants" / "_geode.py")
G = importlib.util.module_from_spec(_spec)
_spec.loader.exec_module(G)


def hood(body):
    body.add("Head", "cloth",
             G.rock(B, (0, 1.74, 0.12), (0.68, 0.68, 0.64), segments=8, rings=5),
             G.rock(B, (0, 1.32, 0.3), (0.62, 0.36, 0.42), segments=7, rings=3),
             # the peak swept back into a long faceted point
             G.seg(B, (0, 2.12, 0.34), (0, 2.62, 1.18), 0.3, 0.06, 4))
    body.add("Head", "glow", G.crystal(B, (0, 2.5, 0.96), (0, 2.86, 1.6), 0.12, 6))
    # the brow gem on the hood's front edge, two teal chips beside it
    body.add("Head", "glow", G.crystal(B, (0, 2.12, -0.4), (0, 2.22, -0.66), 0.1, 6))
    body.add("Head", "teal", *[G.crystal(B, (0.26 * k, 2.1, -0.4), (0.36 * k, 2.2, -0.6), 0.055, 5) for k in (-1, 1)])
    body.add("Head", "hair", *[B.ell((0.3 * k, 1.98, -0.3), (0.22, 0.12, 0.2), 6, 4, rot=(0, 0, -20 * k)) for k in (-1, 1)])  # side-swept fringe


def pauldron(body):
    x = -1.38
    body.add("LeftUpperArm", "rock",
             G.rock(B, (x, 0.94, 0), (0.5, 0.24, 0.52), rot=(0, 0, 16), segments=7, rings=3),
             G.rock(B, (x - 0.12, 0.72, 0.02), (0.42, 0.16, 0.46), rot=(0, 0, 28), segments=6, rings=3))
    shards = [G.crystal(B, (x + dx, 1.06, z), (x + dx - 0.36, 1.62 + h, z + 0.55), r, 6, twist=20 * i)
              for i, (dx, z, h, r) in enumerate(((0.12, -0.24, 0.0, 0.09), (0.02, -0.06, 0.25, 0.11), (-0.08, 0.12, 0.05, 0.09),
                                                (-0.18, 0.28, -0.15, 0.08)))]
    body.add("LeftUpperArm", "glow", shards[1], shards[3])
    body.add("LeftUpperArm", "crystal", shards[0], shards[2])
    body.add("LeftUpperArm", "teal", G.crystal(B, (x - 0.2, 0.98, -0.2), (x - 0.62, 1.2, -0.1), 0.07, 6))


def plate(body):
    """A faceted stone plate over the left chest with a glowing split, a geode-chip belt gem."""
    body.add("UpperTorso", "rock",
             G.rock(B, (-0.42, 0.5, -0.44), (0.5, 0.5, 0.14), rot=(0, 0, 12), segments=6, rings=3),
             G.rock(B, (0.5, 0.0, -0.44), (0.36, 0.32, 0.1), rot=(0, 0, -10), segments=6, rings=3))
    body.add("UpperTorso", "glow", *G.crack(B, [(-0.7, 0.8, -0.57), (-0.5, 0.56, -0.585), (-0.56, 0.32, -0.585), (-0.3, 0.12, -0.57)], r=0.03))
    body.add("LowerTorso", "glow", G.crystal(B, (0, -0.63, -0.5), (0, -0.63, -0.66), 0.09, 6))
    # a small spray of shards on the right shoulder too (smaller: the left one leads)
    body.add("RightUpperArm", "rock", G.rock(B, (1.36, 0.92, 0), (0.34, 0.16, 0.38), rot=(0, 0, -14), segments=6, rings=3))
    body.add("RightUpperArm", "crystal", *[G.crystal(B, (1.36 + dx, 1.0, z), (1.5 + dx, 1.3, z + 0.3), 0.06, 5) for dx, z in ((0.0, -0.1), (0.12, 0.1))])


def bandolier(body):
    body.add("UpperTorso", "dark", B.rbox((0, 0.24, -0.5), (0.18, 1.6, 0.06), bevel=0.02, rot=(0, 0, -38)),
             B.rbox((0, 0.24, 0.5), (0.18, 1.6, 0.06), bevel=0.02, rot=(0, 0, 38)))
    import math
    a = math.radians(-38)
    pts = []
    for t in (-0.44, -0.16, 0.12, 0.4):
        cx, cy = -t * math.sin(a), 0.24 + t * math.cos(a)
        pts.append(G.crystal(B, (cx, cy - 0.12, -0.55), (cx, cy + 0.26, -0.6), 0.06, 5))
    body.add("UpperTorso", "glow", *pts)
    body.add("UpperTorso", "rock", G.rock(B, (0.46, 0.84, -0.54), (0.14, 0.14, 0.06), segments=6, rings=3))


def cloak(body):
    panels, tips = [], []
    for x, length, tilt in ((-0.56, 1.7, 8), (0.0, 2.05, 0), (0.56, 1.8, -8)):
        panels.append(B.rbox((x, 1.0 - length / 2, 0.62), (0.6, length, 0.05), bevel=0.0, segments=1,
                             rot=(-4, 0, tilt), taper=(0.85, 1.0)))
        yb = 1.0 - length
        panels.append(B.rbox((x, yb - 0.16, 0.66), (0.5, 0.36, 0.05), bevel=0.0, segments=1, rot=(-4, 0, 180 + tilt), taper=(0.06, 1.0)))
        tips.append(G.crystal(B, (x, yb - 0.24, 0.7), (x, yb - 0.6, 0.72), 0.06, 5))
    body.add("UpperTorso", "cloth", *panels,
             B.cyl((0, 0.86, 0.04), (1.06, 0.64), 0.34, 7, top=0.66, bevel=0.0))  # the shoulder mantle
    body.add("UpperTorso", "glow", tips[1])
    body.add("UpperTorso", "crystal", tips[0], tips[2])


def arms(body):
    for k, side in B.SIDES:
        x = 1.36 * k
        body.add(f"{side}LowerArm", "rock", B.cyl((x, -0.36, 0), 0.31, 0.42, 6, bevel=0.0, top=0.86))
        # a long crystal fin along the outside of the forearm, pointing back up past the elbow
        body.add(f"{side}LowerArm", "glow", G.crystal(B, (x + 0.26 * k, -0.56, 0.0), (x + 0.5 * k, 0.32, 0.12), 0.07, 4, point=0.45))
        body.add(f"{side}LowerArm", "crystal", G.crystal(B, (x + 0.24 * k, -0.5, 0.16), (x + 0.4 * k, 0.0, 0.32), 0.05, 4, point=0.45))


def legs(body):
    for k, side in B.SIDES:
        lx = 0.5 * k
        body.add(f"{side}LowerLeg", "rock", G.rock(B, (lx, -2.0, -0.3), (0.26, 0.34, 0.12), segments=6, rings=3))
        body.add(f"{side}LowerLeg", "glow", *G.crack(B, [(lx - 0.08, -1.82, -0.42), (lx + 0.04, -1.98, -0.43), (lx - 0.04, -2.16, -0.42)], r=0.024))
        body.add(f"{side}Foot", "rock2", G.seg(B, (lx, -2.84, -0.56), (lx, -2.84, -0.86), 0.14, 0.02, 4))
    # crystal dagger on the right thigh
    body.add("RightUpperLeg", "dark", B.rbox((0.92, -1.32, 0.0), (0.12, 0.5, 0.22), bevel=0.04, rot=(0, 0, 6)))
    body.add("RightUpperLeg", "glow", G.crystal(B, (0.92, -1.08, 0.0), (0.95, -0.66, -0.1), 0.07, 4))


def build(lp):
    plp = G.protect(lp)
    body = B.Body(plp)
    B.base(body, plp, {
        "arm": 0.31, "fore": 0.28, "leg": 0.37, "shin": 0.32, "torso": (1.85, 1.5, 0.92),
        "taper": 1.0, "sleeve": "long", "hands": "dark", "boot": -2.32, "bootr": 0.35,
    })
    hood(body)
    pauldron(body)
    plate(body)
    bandolier(body)
    cloak(body)
    arms(body)
    legs(body)
    return {
        "batch": "11p6",
        "budget": "hero",
        "rig": "r15",
        "pieces": body.finish(2400, 110),
        "colors": {
            "skin": (205, 150, 108),
            "eye": (32, 26, 26),
            "hair": (40, 32, 44),
            "shirt": (70, 62, 86),     # slate jerkin + sleeves
            "pants": (62, 54, 78),
            "dark": (40, 34, 46),      # gloves, boots, straps, sheath
            "cloth": (88, 52, 128),    # faceted violet hood + cloak
            "rock": G.ROCK,
            "rock2": G.ROCK2,
            "crystal": G.CRYSTAL,
            "teal": G.TEAL,
            "glow": G.GLOW,
        },
        "meta": {"skin": "CRYSTAL_CREEPER", "hero": "PISTOL", "display": "Crystal Creeper", "base": "hunter/PISTOL",
                 "theme": "GEODE", "premium": True},
    }
