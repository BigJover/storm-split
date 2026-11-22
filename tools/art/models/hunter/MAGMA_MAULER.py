"""MAGMA_MAULER - Brush Beater premium skin (Lava Lord theme, PREMIUM_SKINS.md "heavy rock gauntlets,
lava-cracked chest plate", batch 11p2, #462: its own silhouette). The volcano's brute - wide, heavy,
made of the mountain itself (rough basalt boulders, not the Monarch's polished obsidian):

  * a craggy rock brow-cap with a molten lava crest flowing over the crown front to back
  * huge boulder shoulders, each with a little volcano on top (a glowing crater, lava running down)
  * a lava-cracked chest plate: one big boulder slab split by a glowing crack network, a magma
    fist-sized core at the sternum; a cracked boulder back plate
  * giant rock gauntlets: boulder fists with glowing knuckle seams, flared rock bracers
  * a heavy rock belt with a molten buckle, rock tassets, boulder knees, stompy rock boots

Every crack, crest, crater and seam is paint group `glow` (Neon in game; Shared/SkinFx pulses /
flows them). Built on the shared R15 figure (_body.py) directly, heavy Brush Beater proportions, same
R15 envelope (#434: shoulders and fists extend modestly past the parts).
"""
# art-sources: _body.py variants/_lava.py

import importlib.util
import math
from pathlib import Path

_here = Path(__file__).parent
_spec = importlib.util.spec_from_file_location("_body", _here / "_body.py")
B = importlib.util.module_from_spec(_spec)
_spec.loader.exec_module(B)
_spec = importlib.util.spec_from_file_location("_lava", _here / "variants" / "_lava.py")
L = importlib.util.module_from_spec(_spec)
_spec.loader.exec_module(L)

CAP = ((0, 2.0, 0.06), (0.64, 0.4, 0.62))


def head(body):
    c, r = CAP
    body.add("Head", "plate",
             L.plate(B, c, r, segments=8, rings=5),
             # a heavy brow ridge over the eyes
             B.rbox((0, 1.92, -0.5), (1.0, 0.16, 0.2), bevel=0.0, segments=1, rot=(-10, 0, 0), taper=(1.0, 0.7)))
    # a short ember-tipped beard (friendly, the face stays open)
    body.add("Head", "hair", B.ell((0, 1.12, -0.42), (0.36, 0.2, 0.16), 8, 4))
    body.add("Head", "glow", *[B.ell((x, 0.98, -0.46), (0.06, 0.06, 0.05), 5, 3) for x in (-0.18, 0.0, 0.18)])
    # the lava crest: molten blobs flowing over the crown, front (big) to back (small)
    crest = []
    for i, (pitch, s) in enumerate(((50, 1.0), (72, 1.15), (96, 1.05), (120, 0.9), (142, 0.72))):
        p = L.on_ell(c, r, 0, pitch, 1.02)
        crest.append(B.ell((p[0], p[1] + 0.06 * s, p[2]), (0.13 * s, 0.14 * s, 0.16 * s), 6, 4))
    body.add("Head", "glow", *crest,
             *L.crack(B, [(-0.5, 1.95, -0.6), (-0.2, 1.88, -0.62), (0.1, 1.95, -0.62), (0.48, 1.88, -0.6)], r=0.03),
             *[d for k in (-1, 1) for d in L.crack(B, [L.on_ell(c, r, k * y, p, 1.01) for y, p in ((50, 10), (80, 28), (110, 6))], r=0.032)])


def volcano(body, part, at, h=0.4, r=0.36):
    """A little volcano sitting on a shoulder boulder: rock cone, glowing crater + three lava runs."""
    x, y, z = at
    body.add(part, "plate", B.cyl((x, y + h / 2, z), r, h, 7, top=0.38, bevel=0.0))
    top = y + h
    body.add(part, "glow",
             B.cyl((x, top + 0.005, z), r * 0.42, 0.05, 7, bevel=0.0),
             B.ell((x, top + 0.14, z), (0.11, 0.16, 0.11), 6, 3),
             B.ell((x + 0.1, top + 0.36, z - 0.04), (0.05, 0.07, 0.05), 5, 3),
             *[L.seg(B, (x + r * 0.36 * math.cos(a), top - 0.02, z + r * 0.36 * math.sin(a)),
                     (x + r * 0.98 * math.cos(a + 0.3), y + 0.04, z + r * 0.98 * math.sin(a + 0.3)), 0.05, 0.04, 4, cap=False)
               for a in (0.6, 2.7, 4.8)])


def shoulders(body):
    for k, side in B.SIDES:
        x = 1.5 * k
        part = f"{side}UpperArm"
        body.add(part, "plate",
                 L.plate(B, (x, 0.86, 0), (0.74, 0.42, 0.7), rot=(0, 0, -10 * k), segments=8, rings=5),
                 L.plate(B, (x + 0.2 * k, 0.56, 0.02), (0.48, 0.26, 0.54), rot=(0, 0, -24 * k), segments=7, rings=4))
        body.add(part, "glow",
                 B.ell((x + 0.1 * k, 0.7, 0), (0.6, 0.05, 0.58), 8, 3, rot=(0, 0, -16 * k)),
                 *L.crack(B, [(x - 0.36 * k, 1.0, -0.42), (x - 0.12 * k, 0.94, -0.56), (x + 0.2 * k, 0.88, -0.5), (x + 0.4 * k, 0.76, -0.46)], r=0.032))
        volcano(body, part, (x + 0.12 * k, 1.16, 0.02))


def chest(body):
    f = -0.62
    body.add("UpperTorso", "plate",
             L.plate(B, (0, 0.34, -0.36), (1.06, 0.72, 0.3), segments=8, rings=4),
             L.plate(B, (0, 0.34, 0.36), (1.02, 0.7, 0.28), segments=8, rings=4))
    # the crack network spreading from a magma core at the sternum
    body.add("UpperTorso", "obs", B.cyl((0, 0.42, f + 0.02), 0.26, 0.08, 7, bevel=0.0, rot=(90, 0, 0)))
    body.add("UpperTorso", "glow",
             B.ell((0, 0.42, f - 0.03), (0.19, 0.19, 0.08), 7, 3),
             *L.crack(B, [(0.16, 0.54, f + 0.02), (0.4, 0.66, f + 0.04), (0.56, 0.86, f + 0.1), (0.8, 0.9, f + 0.2)], r=0.04),
             *L.crack(B, [(-0.16, 0.54, f + 0.02), (-0.38, 0.72, f + 0.05), (-0.66, 0.76, f + 0.12)], r=0.04),
             *L.crack(B, [(0.18, 0.3, f + 0.02), (0.36, 0.1, f + 0.05), (0.62, 0.02, f + 0.12), (0.84, -0.12, f + 0.22)], r=0.038),
             *L.crack(B, [(-0.18, 0.3, f + 0.02), (-0.3, 0.06, f + 0.06), (-0.58, -0.06, f + 0.12)], r=0.038),
             *L.crack(B, [(0.0, 0.22, f + 0.02), (0.08, -0.04, f + 0.06), (-0.04, -0.24, f + 0.14)], r=0.034))
    # a boulder hump across the upper back (the brute's hunch)
    body.add("UpperTorso", "plate", L.plate(B, (0, 0.74, 0.5), (0.9, 0.42, 0.36), segments=8, rings=4))
    body.add("UpperTorso", "glow", *L.crack(B, [(-0.6, 0.86, 0.78), (-0.2, 0.96, 0.84), (0.16, 0.86, 0.85), (0.56, 0.96, 0.78)], r=0.04))
    b = 0.63
    body.add("UpperTorso", "glow",
             *L.crack(B, [(0.0, 0.92, b - 0.1), (0.14, 0.62, b), (-0.08, 0.36, b + 0.01), (0.12, 0.06, b - 0.02), (0.0, -0.22, b - 0.12)], r=0.04),
             *L.crack(B, [(-0.08, 0.36, b + 0.01), (-0.5, 0.26, b - 0.04), (-0.74, 0.02, b - 0.14)], r=0.034),
             *L.crack(B, [(0.12, 0.06, b - 0.02), (0.56, -0.02, b - 0.06), (0.76, 0.2, b - 0.14)], r=0.034))
    # heavy rock belt, molten buckle, rock tassets
    body.add("LowerTorso", "obs", B.rbox((0, -0.64, 0), (2.04, 0.26, 1.08), bevel=0.06, segments=1),
             *[L.plate(B, (0.6 * k, -0.98, -0.32), (0.3, 0.28, 0.12), rot=(-8, 0, 6 * k), segments=6, rings=3) for k in (-1, 1)])
    body.add("LowerTorso", "glow", B.cyl((0, -0.64, -0.55), 0.17, 0.06, 7, bevel=0.0, rot=(90, 0, 0)),
             *[B.rbox((0.6 * k, -1.12, -0.42), (0.36, 0.035, 0.03), bevel=0.0, segments=1, rot=(0, 0, 6 * k)) for k in (-1, 1)])


def fists(body):
    for k, side in B.SIDES:
        x = 1.42 * k
        # flared rock bracer
        body.add(f"{side}LowerArm", "plate", B.cyl((x, -0.36, 0), 0.38, 0.56, 7, bevel=0.0, top=1.3))
        body.add(f"{side}LowerArm", "glow",
                 B.cyl((x, -0.12, 0), 0.43, 0.04, 9, bevel=0.0),
                 *L.crack(B, [(x + 0.05 * k, -0.2, -0.43), (x - 0.06 * k, -0.36, -0.45), (x + 0.04 * k, -0.56, -0.48)], r=0.03))
        # the boulder fist round the hand, glowing knuckle seam and cracks
        body.add(f"{side}Hand", "plate", L.plate(B, (x, -0.86, -0.04), (0.54, 0.44, 0.54), segments=7, rings=4))
        body.add(f"{side}Hand", "glow",
                 B.rbox((x, -0.8, -0.56), (0.66, 0.09, 0.07), bevel=0.0, segments=1),
                 *L.crack(B, [(x - 0.47 * k, -0.72, -0.22), (x - 0.54 * k, -0.86, 0.0), (x - 0.47 * k, -1.02, 0.2)], r=0.028),
                 *L.crack(B, [(x + 0.48 * k, -0.7, -0.26), (x + 0.54 * k, -0.88, -0.04)], r=0.028))


def legs(body):
    for k, side in B.SIDES:
        lx = 0.5 * k
        body.add(f"{side}LowerLeg", "plate",
                 L.plate(B, (lx, -1.86, -0.3), (0.34, 0.3, 0.2), segments=6, rings=4),  # boulder knee
                 B.cyl((lx, -2.22, -0.02), 0.46, 0.44, 7, bevel=0.0, top=0.9))  # rock boot shaft
        body.add(f"{side}LowerLeg", "glow",
                 *L.crack(B, [(lx - 0.12, -1.76, -0.48), (lx + 0.02, -1.86, -0.5), (lx + 0.14, -1.98, -0.46)], r=0.03),
                 B.cyl((lx, -2.0, -0.02), 0.425, 0.035, 9, bevel=0.0))
        body.add(f"{side}Foot", "plate", B.rbox((lx, -2.74, -0.24), (0.9, 0.26, 1.08), bevel=0.04, segments=1, taper=(0.9, 0.85)))
        body.add(f"{side}Foot", "glow", *L.crack(B, [(lx - 0.36, -2.64, -0.79), (lx - 0.1, -2.6, -0.8), (lx + 0.1, -2.66, -0.79), (lx + 0.36, -2.62, -0.78)], r=0.03))
        body.add(f"{side}UpperLeg", "glow", *L.crack(B, [(lx + 0.38 * k, -1.2, -0.12), (lx + 0.43 * k, -1.4, 0.02), (lx + 0.4 * k, -1.6, -0.06)], r=0.026))


def build(lp):
    plp = L.protect(lp)
    body = B.Body(plp)
    B.base(body, plp, {
        "arm": 0.38, "fore": 0.35, "leg": 0.43, "shin": 0.38, "torso": (2.1, 1.55, 1.04),
        "taper": 1.1, "sleeve": "none", "hands": "gaunt", "hand": 1.1, "boot": -2.2,
        "bootr": 0.43, "foot": 1.0, "armx": 1.42, "brow": 0.1,
    })
    head(body)
    shoulders(body)
    chest(body)
    fists(body)
    legs(body)
    return {
        "batch": "11p2",
        "budget": "hero",
        "rig": "r15",
        "pieces": body.finish(2500, 110),
        "colors": {
            "skin": (132, 88, 60),
            "eye": (30, 24, 24),
            "hair": (50, 34, 28),
            "shirt": (64, 48, 44),     # charred under-shirt
            "pants": (60, 48, 44),
            "dark": (44, 34, 32),
            "plate": (70, 60, 60),     # rough basalt boulders (warmer + lighter than the obsidian sets)
            "obs": (38, 32, 40),       # obsidian trim: belt, core ring
            "gaunt": (54, 44, 44),
            "glow": (255, 112, 20),
        },
        "meta": {"skin": "MAGMA_MAULER", "hero": "SHOTGUN", "display": "Magma Mauler", "base": "hunter/SHOTGUN",
                 "theme": "LAVA_LORD", "premium": True},
    }
