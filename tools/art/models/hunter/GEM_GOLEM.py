"""GEM_GOLEM - Brush Beater premium skin (Geode theme, PREMIUM_SKINS.md, batch 11p6): a rock golem brute, its own
hulking silhouette (not the padded vest repainted):

  * a boulder helmet sitting low over the brows, a chunk of teal and amethyst crystal breaking out of its top;
    the face (eyes, brows, smile) stays open and friendly under it
  * a slab-built rock chest with glowing amethyst cracks spidering across it, a geode navel-core
  * huge boulder shoulders, rock forearm bracers with teal crystals, and BOULDER FISTS: each hand inside a big
    faceted rock with glowing crystal knuckle points
  * two rows of tall crystal spines growing down the back out of a rock spine-ridge (tallest at the shoulders)
  * boulder knees, cracked rock boots

`glow` = Neon in game (Shared/SkinFx). Built on the shared R15 figure (_body.py), same R15 envelope (#434:
hit parts never change; the fists, shoulders and spines extend past them).
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


def helmet(body):
    body.add("Head", "rock",
             G.rock(B, (0, 2.02, 0.06), (0.7, 0.46, 0.7), segments=8, rings=5),
             G.rock(B, (0.0, 1.9, -0.46), (0.62, 0.14, 0.18), segments=6, rings=3))  # heavy brow ledge
    cl = G.cluster(B, (0.1, 2.32, 0.1), (0.2, 1.0, 0.15), n=5, length=0.95, r=0.16, spread=30, phase=40)
    body.add("Head", "glow", cl[0], cl[2])
    body.add("Head", "crystal", cl[1], cl[4])
    body.add("Head", "teal", cl[3], G.crystal(B, (-0.38, 2.3, 0.0), (-0.62, 2.62, 0.02), 0.09, 6))
    body.add("Head", "glow", *G.crack(B, [(0.5, 2.24, -0.42), (0.36, 2.1, -0.56), (0.42, 1.98, -0.62)], r=0.03))


def chest(body):
    f = -0.58
    body.add("UpperTorso", "rock",
             G.rock(B, (-0.48, 0.52, -0.42), (0.6, 0.6, 0.2), rot=(0, 0, 8), segments=6, rings=3),
             G.rock(B, (0.48, 0.52, -0.42), (0.6, 0.6, 0.2), rot=(0, 0, -8), segments=6, rings=3),
             G.rock(B, (0, 0.38, 0.44), (1.0, 0.7, 0.2), segments=7, rings=3))
    body.add("UpperTorso", "glow",
             *G.crack(B, [(0.0, 0.92, f + 0.04), (0.06, 0.66, f), (-0.04, 0.42, f + 0.02), (0.04, 0.16, f + 0.02)], r=0.055),
             *G.crack(B, [(-0.06, 0.66, f), (-0.4, 0.74, f + 0.02), (-0.72, 0.62, f + 0.08)], r=0.045),
             *G.crack(B, [(0.0, 0.42, f + 0.02), (0.36, 0.3, f + 0.02), (0.7, 0.36, f + 0.08)], r=0.045),
             *G.crack(B, [(-0.04, 0.42, f + 0.02), (-0.4, 0.2, f + 0.02), (-0.66, 0.08, f + 0.08)], r=0.03))
    G.add_groups(body, "LowerTorso", G.geode(B, (0, -0.74, -0.54), (0, 0, -1), 0.24, n=5))


def spines(body):
    """Two rows of crystal spines down the back out of a rock ridge."""
    body.add("UpperTorso", "rock2", G.seg(B, (0, 1.0, 0.62), (0, -0.4, 0.58), 0.2, 0.14, 6))
    glow, xt = [], []
    for i, (y, h) in enumerate(((0.86, 1.0), (0.5, 0.8), (0.14, 0.62), (-0.2, 0.46))):
        for k in (-1, 1):
            base = (0.24 * k, y, 0.62)
            tip = (0.62 * k, y + h * 1.25, 0.66 + h * 0.8)
            (glow if (i + (k > 0)) % 2 == 0 else xt).append(G.crystal(B, base, tip, 0.17 - 0.02 * i, 6, twist=15 * i))
    body.add("UpperTorso", "glow", *glow)
    body.add("UpperTorso", "crystal", *xt)


def arms(body):
    for k, side in B.SIDES:
        x = 1.44 * k
        body.add(f"{side}UpperArm", "rock",
                 G.rock(B, (x, 0.86, 0), (0.62, 0.42, 0.62), rot=(0, 0, -12 * k), segments=8, rings=4))
        body.add(f"{side}UpperArm", "glow", *G.crack(B, [(x - 0.2 * k, 1.14, -0.4), (x + 0.06 * k, 1.0, -0.56), (x + 0.36 * k, 0.86, -0.46)], r=0.03))
        cl = G.cluster(B, (x + 0.12 * k, 1.14, 0.06), (0.5 * k, 1.0, 0.25), n=4, length=0.7, r=0.12, spread=28, phase=10 * k)
        body.add(f"{side}UpperArm", "crystal", cl[1], cl[3])
        body.add(f"{side}UpperArm", "glow", cl[0], cl[2])
        body.add(f"{side}LowerArm", "rock", B.cyl((x, -0.34, 0), 0.42, 0.5, 7, bevel=0.0, top=1.08))
        body.add(f"{side}LowerArm", "teal", *[G.crystal(B, (x + 0.34 * k, -0.3 + dy, dz), (x + 0.6 * k, -0.18 + dy, dz * 1.4), 0.06, 5)
                                               for dy, dz in ((0.06, -0.12), (-0.1, 0.12))])
        # boulder fist round the hand, crystal knuckles
        body.add(f"{side}Hand", "rock", G.rock(B, (x, -0.9, -0.04), (0.54, 0.46, 0.56), segments=7, rings=4))
        body.add(f"{side}Hand", "glow", *[G.crystal(B, (x + dx, -0.82, -0.44), (x + dx * 1.2, -0.8, -0.74), 0.075, 5) for dx in (-0.2, 0.0, 0.2)],
                 *G.crack(B, [(x - 0.36 * k, -0.7, -0.36), (x - 0.1 * k, -1.02, -0.46), (x + 0.24 * k, -1.16, -0.36)], r=0.026))


def legs(body):
    for k, side in B.SIDES:
        lx = 0.5 * k
        body.add(f"{side}LowerLeg", "rock",
                 G.rock(B, (lx, -1.86, -0.26), (0.34, 0.3, 0.2), segments=6, rings=3),
                 B.cyl((lx, -2.38, 0.0), 0.46, 0.36, 7, bevel=0.0, top=0.9))
        body.add(f"{side}LowerLeg", "glow", *G.crack(B, [(lx - 0.14, -1.78, -0.45), (lx + 0.02, -1.9, -0.46), (lx + 0.14, -1.98, -0.42)], r=0.028))
        body.add(f"{side}UpperLeg", "rock", G.rock(B, (lx + 0.14 * k, -1.16, -0.04), (0.38, 0.24, 0.44), segments=6, rings=3))


def build(lp):
    plp = G.protect(lp)
    body = B.Body(plp)
    B.base(body, plp, {
        "arm": 0.41, "fore": 0.38, "leg": 0.44, "shin": 0.39, "torso": (2.1, 1.6, 1.05),
        "taper": 1.1, "sleeve": "long", "hands": "dark", "hand": 1.1, "boot": -2.2,
        "bootr": 0.44, "foot": 1.12, "armx": 1.44, "brow": 0.09,
    })
    helmet(body)
    chest(body)
    spines(body)
    arms(body)
    legs(body)
    return {
        "batch": "11p6",
        "budget": "hero",
        "rig": "r15",
        "pieces": body.finish(2300, 110),
        "colors": {
            "skin": (132, 88, 60),
            "eye": (30, 24, 24),
            "hair": (42, 32, 28),
            "shirt": (64, 60, 74),     # stone-grey hide under the slabs
            "pants": (58, 54, 68),
            "dark": (56, 52, 62),      # boots, belt
            "rock": G.ROCK,
            "rock2": G.ROCK2,
            "crystal": G.CRYSTAL,
            "teal": G.TEAL,
            "glow": G.GLOW,
        },
        "meta": {"skin": "GEM_GOLEM", "hero": "SHOTGUN", "display": "Gem Golem", "base": "hunter/SHOTGUN",
                 "theme": "GEODE", "premium": True},
    }
