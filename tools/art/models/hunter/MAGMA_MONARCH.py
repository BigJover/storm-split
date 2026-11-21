"""MAGMA_MONARCH - Big Game Hunter premium skin (Lava Lord theme, PREMIUM_SKINS.md, batch 11p1): the
volcano's own big-game hunter. Black obsidian pith helmet with a lava crest of flame tongues on an
obsidian fin and a molten band; faceted obsidian shoulder plates in two layers with lava glowing
between them; an obsidian-black safari jacket split by cracked orange seams (chest and back), a
bandolier of glowing magma rounds, obsidian bracers and kneecaps with glowing seams, toe plates on
the boots and a molten buckle. Every seam, the crest and the rounds are paint group `glow` (Neon in
game; Shared/SkinFx pulses / flows them by the skin's fxTier). Base: hunter/RIFLE
(variants/_skins.py), same R15 envelope (#434).
"""
# art-sources: RIFLE.py variants/_skins.py variants/_lava.py

import importlib.util
import math
from pathlib import Path

_dir = Path(__file__).with_name("variants")
_spec = importlib.util.spec_from_file_location("_skins", _dir / "_skins.py")
S = importlib.util.module_from_spec(_spec)
_spec.loader.exec_module(S)
_spec = importlib.util.spec_from_file_location("_lava", _dir / "_lava.py")
L = importlib.util.module_from_spec(_spec)
_spec.loader.exec_module(L)

DOME = ((0, 2.04, 0.0), (0.64, 0.56, 0.68))  # RIFLE.py's helmet dome (centre, radii)


def helmet(body, lp, B):
    c, r = DOME
    # molten band where the yellow one was (dropped), a little slimmer
    body.add("Head", "glow", B.cyl((0, 1.99, 0), (0.652, 0.692), 0.09, 16, bevel=0.0))
    # obsidian fin along the dome's top, front to back, flame tongues standing on it
    body.add("Head", "plate",
             B.ell((0, 2.58, 0.04), (0.07, 0.11, 0.56), 8, 5),
             L.plate(B, (0, 2.5, -0.5), (0.06, 0.1, 0.12), rot=(30, 0, 0), segments=6, rings=3))
    flames = []
    for i, (z, h) in enumerate(((-0.42, 0.17), (-0.22, 0.27), (0.0, 0.33), (0.22, 0.28), (0.42, 0.18))):
        lean = -18 - 6 * i  # sweeping back like a crest in the wind
        y = c[1] + r[1] * math.sqrt(max(0.0, 1 - (z / r[2]) ** 2)) + 0.03
        flames.append(B.ell((0, y + h * 0.7, z + 0.04), (0.065, h, 0.095), 6, 4, rot=(lean, 0, 0)))
    body.add("Head", "glow", *flames)
    # cracks running down the dome from the fin to the band, both sides + one at the back
    for k in (-1, 1):
        body.add("Head", "glow", *L.crack(B, [L.on_ell(c, r, k * yaw, p, 1.01) for yaw, p in
                                              ((28, 62), (44, 50), (38, 38), (55, 26), (50, 14))]))
        body.add("Head", "glow", *L.crack(B, [L.on_ell(c, r, k * yaw, p, 1.01) for yaw, p in
                                              ((100, 64), (112, 46), (102, 30), (118, 15))]))
    body.add("Head", "glow", *L.crack(B, [L.on_ell(c, r, yaw, p, 1.01) for yaw, p in
                                          ((172, 60), (186, 42), (176, 26), (190, 14))]))


def shoulders(body, lp, B):
    for k, side in B.SIDES:
        x = 1.36 * k
        body.add(f"{side}UpperArm", "plate",
                 L.plate(B, (x, 0.86, 0), (0.5, 0.17, 0.52), rot=(0, 0, -20 * k)),
                 L.plate(B, (x + 0.1 * k, 0.64, 0), (0.44, 0.15, 0.48), rot=(0, 0, -30 * k)))
        # the lava between the two layers, and a crack across the top plate
        body.add(f"{side}UpperArm", "glow",
                 B.ell((x + 0.05 * k, 0.75, 0), (0.45, 0.07, 0.47), 10, 3, rot=(0, 0, -25 * k)),
                 *L.crack(B, [(x - 0.28 * k, 1.0, -0.3), (x - 0.06 * k, 0.99, -0.12), (x + 0.04 * k, 0.97, 0.08),
                              (x + 0.22 * k, 0.9, 0.26)], r=0.03))


def chest(body, lp, B):
    f = -0.515  # the jacket's front face (z -0.5) + a hair
    # two branching cracks on the right of the bandolier, one on the left
    body.add("UpperTorso", "glow",
             *L.crack(B, [(0.42, 0.98, f), (0.5, 0.74, f), (0.36, 0.5, f), (0.52, 0.22, f), (0.42, -0.06, f),
                          (0.58, -0.4, f)]),
             *L.crack(B, [(0.36, 0.5, f), (0.14, 0.4, f), (0.2, 0.2, f)]),
             *L.crack(B, [(0.52, 0.22, f), (0.76, 0.12, f)]),
             *L.crack(B, [(-0.6, 0.62, f), (-0.48, 0.36, f), (-0.66, 0.1, f), (-0.5, -0.2, f), (-0.62, -0.42, f)]),
             *L.crack(B, [(-0.48, 0.36, f), (-0.3, 0.22, f)]))
    b = -f
    body.add("UpperTorso", "glow",
             *L.crack(B, [(0.0, 0.98, b), (0.1, 0.7, b), (-0.06, 0.42, b), (0.12, 0.12, b), (0.0, -0.3, b)]),
             *L.crack(B, [(-0.06, 0.42, b), (-0.4, 0.3, b), (-0.52, 0.02, b)]),
             *L.crack(B, [(0.12, 0.12, b), (0.46, 0.0, b)]))
    # the bandolier's rounds, now magma (RIFLE.py's rounds, dropped from `accent`)
    a = math.radians(40)
    d = (-math.sin(a), math.cos(a))
    body.add("UpperTorso", "glow", *[
        B.cyl((-0.04 + d[0] * t, 0.28 + d[1] * t, -0.55), 0.055, 0.24, 6, bevel=0.0, rot=(0, 0, -50))
        for t in (-0.6, -0.4, -0.2, 0.0, 0.2, 0.4, 0.6)])
    # molten buckle (RIFLE.py's, dropped from `accent`) in an obsidian frame
    body.add("LowerTorso", "plate", B.rbox((0, -0.63, -0.5), (0.32, 0.22, 0.05), bevel=0.02, segments=1))
    body.add("LowerTorso", "glow", B.rbox((0, -0.63, -0.53), (0.2, 0.12, 0.04), bevel=0.02, segments=1))


def limbs(body, lp, B):
    for k, side in B.SIDES:
        x = 1.38 * k
        # obsidian bracer over the forearm, a lava seam round its middle and a crack on the back of it
        body.add(f"{side}LowerArm", "plate", B.cyl((x, -0.36, 0), 0.355, 0.42, 8, bevel=0.03, top=1.08))
        body.add(f"{side}LowerArm", "glow",
                 B.cyl((x, -0.36, 0), 0.372, 0.05, 10, bevel=0.0),
                 *L.crack(B, [(x + 0.12 * k, -0.18, -0.36), (x + 0.02 * k, -0.27, -0.375), (x + 0.1 * k, -0.33, -0.37)], r=0.026))
        lx = 0.5 * k
        # kneecaps (the RIFLE hunter's bare knees) with a cracked seam
        body.add(f"{side}LowerLeg", "plate", L.plate(B, (lx, -1.86, -0.27), (0.24, 0.24, 0.13), rot=(-10, 0, 0)))
        body.add(f"{side}LowerLeg", "glow",
                 *L.crack(B, [(lx - 0.16, -1.8, -0.37), (lx - 0.04, -1.88, -0.4), (lx + 0.06, -1.8, -0.4), (lx + 0.17, -1.9, -0.36)], r=0.026))
        # toe plates with a crack across
        body.add(f"{side}Foot", "plate", B.rbox((lx, -2.64, -0.44), (0.68, 0.08, 0.46), bevel=0.04, segments=1, rot=(-12, 0, 0)))
        body.add(f"{side}Foot", "glow",
                 *L.crack(B, [(lx - 0.3, -2.6, -0.44), (lx - 0.1, -2.58, -0.5), (lx + 0.06, -2.6, -0.38), (lx + 0.3, -2.62, -0.5)], r=0.028))


def extra(body, lp, B):
    helmet(body, lp, B)
    shoulders(body, lp, B)
    chest(body, lp, B)
    limbs(body, lp, B)


def build(lp):
    model = S.variant(
        L.protect(lp), "RIFLE", "MAGMA_MONARCH", "Magma Monarch",
        drop=[("Head", "accent", 0),         # yellow helmet band -> molten band
              ("UpperTorso", "gear2", 0),    # pockets + epaulette -> cracks + shoulder plates
              ("UpperTorso", "accent", 0),   # brass rounds -> magma rounds
              ("LowerTorso", "accent", 0)],  # brass buckle -> molten buckle
        extra=extra,
        target=4150, keep=110,  # the rest of the body; glow + plate pieces are protected (L.protect)
        colors={
            "gear": (34, 30, 36),      # obsidian helmet
            "plate": (44, 38, 48),     # obsidian plates (a touch lighter, so the facets read)
            "shirt": (54, 48, 52),     # obsidian-black jacket
            "gear2": (44, 40, 44),
            "pants": (46, 40, 44),
            "dark": (70, 40, 30),      # charred leather: boots, belt, bandolier
            "sock": (80, 70, 70),
            "hair": (200, 86, 34),     # a fiery moustache
            "accent": (210, 96, 32),
            "glow": (255, 112, 20),    # the lava (Neon in game)
        },
    )
    model["batch"] = "11p1"
    model["meta"].update({"theme": "LAVA_LORD", "premium": True})
    return model
