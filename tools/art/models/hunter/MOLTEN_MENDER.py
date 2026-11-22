"""MOLTEN_MENDER - Field Medic premium skin (Lava Lord theme, PREMIUM_SKINS.md "heat-proof coat, glowing
vial belt", batch 11p2, #462: its own silhouette). The volcano's healer - a forge-smith who mends with
fire (cauterize, not cut):

  * forge goggles pushed up on the brow, round lenses glowing; a tall stand-up heat-proof collar
  * a long burnt-leather heat-proof coat with split tails to the knees, the hems seared and glowing
  * an obsidian-scale smith's apron down the front with a big molten cross branded on the chest
  * a belt of glowing vials round the waist and a bandolier of vials across the chest
  * a forge crucible on the back: an obsidian pot with a glowing grate and a smoking chimney, a
    hose running round to a cauteriser wand (glowing tip) holstered on the right hip
  * a round heat shield on the left shoulder, thick heat-proof gauntlet gloves with glowing seams,
    tall boots with obsidian shin plates

Every crack, vial, lens, seam and the cross are paint group `glow` (Neon in game; Shared/SkinFx
pulses / flows them). Built on the shared R15 figure (_body.py) directly, Field Medic proportions,
same R15 envelope (#434: coat tails, crucible and collar extend modestly past the parts).
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


def head(body):
    # short swept hair under a leather skullcap band, the goggles pushed up on it
    body.add("Head", "hair", B.rbox((0, 1.96, 0.08), (1.12, 0.46, 1.0), bevel=0.2, segments=2),
             B.rbox((0, 1.66, 0.3), (1.1, 0.56, 0.5), bevel=0.22, segments=2))
    body.add("Head", "coat", B.cyl((0, 1.94, 0.02), (0.6, 0.56), 0.16, 14, bevel=0.04))
    body.add("Head", "plate", *[B.cyl((0.24 * k, 1.98, -0.6), 0.19, 0.12, 8, bevel=0.03, rot=(80, 0, 0)) for k in (-1, 1)],
             B.rbox((0, 1.98, -0.6), (0.14, 0.08, 0.08), bevel=0.02, segments=1))
    body.add("Head", "glow", *[B.ell((0.24 * k, 1.99, -0.68), (0.14, 0.14, 0.05), 8, 3, rot=(-10, 0, 0)) for k in (-1, 1)])


def collar(body):
    """A tall stand-up heat-proof collar, open at the front, a glowing seam round its top edge."""
    body.add("UpperTorso", "coat", B.cyl((0, 1.06, 0.1), (0.66, 0.58), 0.4, 10, top=1.12, bevel=0.04))
    body.add("UpperTorso", "glow", *L.crack(B, [(-0.62, 1.26, -0.08), (-0.5, 1.27, 0.34), (0.0, 1.27, 0.7), (0.5, 1.27, 0.34), (0.62, 1.26, -0.08)], r=0.03))


def coat(body):
    # the coat over the torso (open front shows the apron), sleeves to the elbow, split tails
    body.add("UpperTorso", "coat",
             B.rbox((0, 0.22, 0.04), (1.9, 1.5, 1.0), bevel=0.3, segments=2, taper=(1.04, 1.0)),
             *[B.rbox((0.62 * k, 0.4, -0.52), (0.34, 1.1, 0.06), bevel=0.02, segments=1, rot=(0, 0, 8 * k)) for k in (-1, 1)])  # lapels
    body.add("LowerTorso", "coat",
             B.rbox((-0.5, -1.4, 0.52), (0.86, 1.5, 0.06), bevel=0.02, segments=1, rot=(0, -8, 0), taper=(0.8, 1.0)),
             B.rbox((0.5, -1.4, 0.52), (0.86, 1.5, 0.06), bevel=0.02, segments=1, rot=(0, 8, 0), taper=(0.8, 1.0)),
             *[B.rbox((0.95 * k, -1.36, 0.0), (0.06, 1.42, 0.92), bevel=0.02, segments=1, rot=(0, 0, -6 * k)) for k in (-1, 1)])
    # seared hems glowing along the bottom of the tails and sides
    body.add("LowerTorso", "glow",
             *[B.rbox((0.5 * k, -2.12, 0.56), (0.62, 0.05, 0.03), bevel=0.0, segments=1, rot=(0, 8 * k, 0)) for k in (-1, 1)],
             *L.crack(B, [(-0.6, -1.96, 0.57), (-0.48, -1.76, 0.565), (-0.62, -1.56, 0.56)], r=0.026),
             *L.crack(B, [(0.42, -1.98, 0.57), (0.56, -1.78, 0.565), (0.44, -1.6, 0.56)], r=0.026))
    # sleeves: coat cuffs at the elbow, seared rim
    for k, side in B.SIDES:
        x = 1.36 * k
        body.add(f"{side}UpperArm", "coat", B.capsule(body.lp, (x, 0.64, 0), (x, 0.06, 0), 0.38, 0.36))
        body.add(f"{side}LowerArm", "coat", B.cyl((x, -0.02, 0), 0.37, 0.24, 9, bevel=0.04, top=1.06))
        body.add(f"{side}LowerArm", "glow", B.cyl((x, -0.14, 0), 0.38, 0.035, 9, bevel=0.0))


def apron(body):
    f = -0.56
    body.add("UpperTorso", "plate", B.rbox((0, 0.24, -0.5), (0.86, 1.36, 0.08), bevel=0.03, segments=1))
    body.add("LowerTorso", "plate", B.rbox((0, -1.2, -0.5), (0.8, 1.0, 0.08), bevel=0.03, segments=1, rot=(4, 0, 0), taper=(1.06, 1.0)))
    # scale rows on the apron (obsidian scales, glowing joins)
    body.add("LowerTorso", "glow", *[B.rbox((0, y, -0.555 - (y + 1.2) * 0.07), (0.78, 0.03, 0.02), bevel=0.0, segments=1, rot=(4, 0, 0))
                                     for y in (-0.94, -1.24, -1.54)])
    # the molten cross branded on the chest, in an obsidian ring
    body.add("UpperTorso", "obs", B.cyl((0, 0.44, f + 0.02), 0.34, 0.06, 8, bevel=0.0, rot=(90, 0, 0)))
    body.add("UpperTorso", "glow",
             B.rbox((0, 0.44, f - 0.03), (0.13, 0.46, 0.05), bevel=0.0, segments=1),
             B.rbox((0, 0.44, f - 0.03), (0.46, 0.13, 0.05), bevel=0.0, segments=1),
             *L.crack(B, [(0.0, 0.08, f + 0.02), (0.08, -0.12, f + 0.02), (-0.04, -0.3, f + 0.02)], r=0.03))


def vials(body):
    # belt of vials round the waist: glowing glass, obsidian caps
    body.add("LowerTorso", "dark", B.cyl((0, -0.64, 0), (1.0, 0.55), 0.2, 14, bevel=0.04))
    caps, glass = [], []
    for yaw in (-70, -40, 40, 70, 110, 140):
        a = math.radians(yaw)
        x, z = 1.0 * math.sin(a), -0.56 * math.cos(a)
        x, z = x * 1.04, z * 1.08
        glass.append(B.cyl((x, -0.7, z), 0.075, 0.26, 6, bevel=0.0))
        caps.append(B.cyl((x, -0.54, z), 0.06, 0.07, 6, bevel=0.0))
    body.add("LowerTorso", "glow", *glass)
    body.add("LowerTorso", "obs", *caps)
    # bandolier of vials across the chest, right shoulder to left hip
    a, b = (0.66, 0.92, -0.58), (-0.7, -0.46, -0.58)
    body.add("UpperTorso", "dark", B.rbox(((a[0] + b[0]) / 2, (a[1] + b[1]) / 2, -0.6), (0.16, 1.96, 0.06), bevel=0.02, segments=1, rot=(0, 0, 45)))
    g2, c2 = [], []
    for t in (0.14, 0.3, 0.7, 0.86):
        x, y = a[0] + (b[0] - a[0]) * t, a[1] + (b[1] - a[1]) * t
        g2.append(B.cyl((x, y, -0.66), 0.06, 0.2, 6, bevel=0.0, rot=(0, 0, 45)))
        c2.append(B.cyl((x + 0.08, y + 0.08, -0.66), 0.05, 0.05, 6, bevel=0.0, rot=(0, 0, 45)))
    body.add("UpperTorso", "glow", *g2)
    body.add("UpperTorso", "obs", *c2)


def crucible(body):
    """A forge crucible on the back: an obsidian pot open at the top, brimming with glowing molten
    metal (reads from the game's high camera), a glowing grate low on its back, a chimney beside it,
    a hose round to the cauteriser wand on the right hip."""
    cx, cy, cz = 0, 0.26, 0.8
    body.add("UpperTorso", "plate",
             B.cyl((cx, cy, cz), (0.46, 0.36), 0.86, 8, top=1.16, bevel=0.03),
             B.cyl((0.5, 0.86, 0.74), 0.09, 0.46, 6, bevel=0.0))  # chimney
    body.add("UpperTorso", "obs",
             B.cyl((cx, cy + 0.42, cz), (0.56, 0.45), 0.07, 8, bevel=0.02),  # rim band
             *[B.rbox((0.0, y, cz + 0.4), (0.4, 0.035, 0.04), bevel=0.0, segments=1) for y in (0.0, 0.12)])  # grate bars
    body.add("UpperTorso", "glow",
             B.ell((cx, cy + 0.47, cz), (0.48, 0.1, 0.38), 8, 3),  # the molten top, domed
             B.ell((cx + 0.1, cy + 0.54, cz - 0.04), (0.14, 0.08, 0.12), 6, 3),  # a bubble
             B.rbox((0, 0.06, cz + 0.37), (0.34, 0.24, 0.03), bevel=0.0, segments=1),  # the fire behind the grate
             B.cyl((0.5, 1.095, 0.74), 0.065, 0.03, 6, bevel=0.0),
             B.ell((0.5, 1.2, 0.74), (0.055, 0.09, 0.055), 5, 3),
             *L.crack(B, [(-0.42, 0.5, 0.92), (-0.47, 0.3, 0.9), (-0.44, 0.1, 0.94)], r=0.026))
    # straps over the shoulders
    body.add("UpperTorso", "dark", *[B.rbox((0.42 * k, 0.86, 0.1), (0.16, 0.08, 1.06), bevel=0.02, segments=1) for k in (-1, 1)])
    # hose from the pot's foot round the right hip to the cauteriser wand, holstered there
    hose = [(0.3, -0.12, 0.76), (0.7, -0.36, 0.64), (0.98, -0.58, 0.3), (1.04, -0.86, -0.06)]
    body.add("UpperTorso", "dark", *[L.seg(B, p, q, 0.055, 0.055, 6, cap=False) for p, q in zip(hose, hose[1:])])
    body.add("LowerTorso", "obs", B.cyl((1.04, -1.06, -0.1), 0.08, 0.42, 6, bevel=0.0, rot=(0, 0, 8)))
    body.add("LowerTorso", "glow", L.seg(B, (1.07, -1.27, -0.1), (1.09, -1.46, -0.1), 0.05, 0.0, 5))


def arms(body):
    # round heat shield on the left shoulder with a glowing rim
    body.add("LeftUpperArm", "plate", B.cyl((-1.48, 0.86, 0), (0.48, 0.48), 0.1, 9, bevel=0.03, rot=(0, 0, 28)))
    body.add("LeftUpperArm", "glow", B.cyl((-1.475, 0.85, 0), (0.5, 0.5), 0.04, 10, bevel=0.0, rot=(0, 0, 28)),
             B.ell((-1.6, 0.93, 0), (0.08, 0.04, 0.08), 5, 3, rot=(0, 0, 28)))
    for k, side in B.SIDES:
        x = 1.36 * k
        # heat-proof gauntlet gloves: a flared cuff, glowing fingertip seam
        body.add(f"{side}LowerArm", "gaunt", B.cyl((x, -0.46, 0), 0.33, 0.34, 8, bevel=0.03, top=1.22))
        body.add(f"{side}LowerArm", "glow", B.cyl((x, -0.3, 0), 0.38, 0.03, 9, bevel=0.0))
        body.add(f"{side}Hand", "glow", B.rbox((x, -0.98, -0.12), (0.4, 0.05, 0.3), bevel=0.0, segments=1))


def legs(body):
    for k, side in B.SIDES:
        lx = 0.5 * k
        body.add(f"{side}LowerLeg", "plate", L.plate(B, (lx, -2.1, -0.28), (0.3, 0.4, 0.14), rot=(-6, 0, 0), segments=6, rings=4))
        body.add(f"{side}LowerLeg", "glow", *L.crack(B, [(lx - 0.08, -1.84, -0.4), (lx + 0.06, -2.04, -0.42), (lx - 0.04, -2.3, -0.4)], r=0.026))
        body.add(f"{side}Foot", "glow", B.rbox((lx, -2.66, -0.68), (0.62, 0.04, 0.04), bevel=0.0, segments=1))


def build(lp):
    plp = L.protect(lp)
    body = B.Body(plp)
    B.base(body, plp, {
        "arm": 0.33, "fore": 0.3, "leg": 0.39, "shin": 0.34, "torso": (1.9, 1.5, 0.95),
        "taper": 1.02, "sleeve": "long", "hands": "gaunt", "boot": -1.98, "bootr": 0.37,
        "armx": 1.36,
    })
    head(body)
    collar(body)
    coat(body)
    apron(body)
    vials(body)
    crucible(body)
    arms(body)
    legs(body)
    return {
        "batch": "11p2",
        "budget": "hero",
        "rig": "r15",
        "pieces": body.finish(2500, 110),
        "colors": {
            "skin": (226, 176, 140),
            "eye": (32, 26, 26),
            "hair": (150, 60, 34),     # copper hair
            "shirt": (64, 48, 44),
            "pants": (56, 44, 42),
            "dark": (46, 34, 30),      # charred leather: belts, straps, hose, boots
            "coat": (112, 60, 38),     # burnt-leather heat-proof coat
            "plate": (40, 34, 46),     # obsidian
            "obs": (30, 26, 34),
            "gaunt": (78, 52, 40),     # heat-proof gloves
            "glow": (255, 112, 20),
        },
        "meta": {"skin": "MOLTEN_MENDER", "hero": "MEDIC", "display": "Molten Mender", "base": "hunter/MEDIC",
                 "theme": "LAVA_LORD", "premium": True},
    }
