"""PISTOL - the Tracker (Revolver, Hunting Knife; fast, 95 HP): the lean scout.

Read: slim figure, olive field shirt, slouch bush hat with a red band and a feather, red
bandana at the neck (the Tracker's red, Server/Hero HERO_COLORS), a ponytail, a thigh
holster and a knife sheath, fingerless gloves, short lace-up boots.
Built on the shared R15 figure (_body.py); Roblox studs about the HumanoidRootPart.
"""

import importlib.util
from pathlib import Path

_spec = importlib.util.spec_from_file_location("_body", Path(__file__).with_name("_body.py"))
B = importlib.util.module_from_spec(_spec)
_spec.loader.exec_module(B)


def build(lp):
    body = B.Body(lp)
    B.base(body, lp, {
        "arm": 0.31, "fore": 0.28, "leg": 0.37, "shin": 0.32, "torso": (1.85, 1.5, 0.92),
        "taper": 1.0, "sleeve": "rolled", "hands": "dark", "boot": -2.3, "bootr": 0.35,
    })

    # slouch bush hat: soft crown, wide brim, red band, a feather in the band
    body.add("Head", "gear",
             B.cyl((0, 2.22, 0), (0.5, 0.48), 0.44, 18, top=0.82, bevel=0.14),
             B.cyl((0, 2.0, 0), (0.98, 0.9), 0.07, 22, bevel=0.03, rot=(-4, 0, 0)))
    body.add("Head", "accent", B.cyl((0, 2.07, 0), (0.505, 0.485), 0.11, 18, top=0.98, bevel=0.03))
    body.add("Head", "light", B.ell((0.48, 2.3, 0.12), (0.06, 0.32, 0.1), 8, 6, rot=(-20, 0, -25)))
    # hair: cap under the hat + ponytail
    body.add("Head", "hair",
             B.rbox((0, 1.72, 0.08), (1.14, 0.86, 0.96), bevel=0.4, segments=3),
             B.capsule(lp, (0, 1.5, 0.56), (0, 1.0, 0.6), 0.15, 0.1, subdiv=1))
    body.add("Head", "accent", B.cyl((0, 1.38, 0.57), 0.155, 0.08, 10, bevel=0.02))  # hair tie

    # red bandana: neck roll + a point on the chest
    body.add("UpperTorso", "accent",
             B.cyl((0, 0.98, 0), (0.5, 0.44), 0.2, 16, top=0.86, bevel=0.08),
             B.rbox((0, 0.8, -0.45), (0.36, 0.36, 0.07), bevel=0.04, rot=(-8, 0, 45)))
    # chest strap (harness) across to the hip
    body.add("UpperTorso", "dark", B.rbox((0, 0.22, -0.46), (0.16, 1.5, 0.07), bevel=0.03, rot=(0, 0, -38)),
             B.rbox((0, 0.22, 0.46), (0.16, 1.5, 0.07), bevel=0.03, rot=(0, 0, -38)))
    # belt pouches
    body.add("LowerTorso", "gear", *[B.rbox((0.62 * k, -0.73, -0.46), (0.36, 0.3, 0.16), bevel=0.06) for k in (-1, 1)])
    body.add("LowerTorso", "accent", B.rbox((0, -0.63, -0.48), (0.22, 0.15, 0.05), bevel=0.03))  # buckle

    # holster on the right thigh (revolver side), knife sheath on the left
    body.add("RightUpperLeg", "dark",
             B.rbox((0.9, -1.28, -0.02), (0.18, 0.62, 0.42), bevel=0.07, rot=(0, 0, 8)),
             B.cyl((0.5, -1.45, 0), 0.43, 0.09, 16, bevel=0.03))
    body.add("LeftUpperLeg", "gear", B.rbox((-0.88, -1.25, 0.05), (0.13, 0.55, 0.22), bevel=0.05, rot=(0, 0, -6)))
    body.add("LeftUpperLeg", "dark", B.cyl((-0.5, -1.45, 0), 0.43, 0.09, 16, bevel=0.03))

    return {
        "batch": "11c",
        "budget": "hero",
        "rig": "r15",
        "pieces": body.finish(),
        "colors": {
            "skin": (205, 150, 108),
            "hair": (74, 48, 32),
            "eye": (32, 26, 26),
            "shirt": (112, 126, 78),   # olive field shirt
            "pants": (192, 168, 120),  # khaki cargo
            "gear": (128, 96, 62),     # hat, pouches, sheath
            "accent": (214, 66, 84),   # Tracker red (HERO_COLORS PISTOL, toned down)
            "light": (236, 226, 200),  # feather
            "dark": (76, 54, 38),      # leather: boots, gloves, belt, holster
        },
    }
