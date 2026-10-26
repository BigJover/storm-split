"""MEDIC - the Field Medic (Lever-Action Carbine, Splint Stick; 100 HP, support): the helper.

Read: a big green medical backpack with a white cross (the silhouette from behind), a green
field cap with a white cross, white field shirt with a green cross patch and a green armband
(the Field Medic's green, Server/Hero HERO_COLORS), short short haircut, teal gloves, slate
trousers, a hip satchel, a stethoscope. The cross is green/white on purpose: the red cross
is a protected emblem, and green is this class's colour anyway.
Built on the shared R15 figure (_body.py); Roblox studs about the HumanoidRootPart.
"""

import importlib.util
from pathlib import Path

_spec = importlib.util.spec_from_file_location("_body", Path(__file__).with_name("_body.py"))
B = importlib.util.module_from_spec(_spec)
_spec.loader.exec_module(B)


def cross(centre, arm, thick, depth, axis="z"):
    """A plus sign facing along -z (front/back) or x (side)."""
    x, y, z = centre
    if axis == "z":
        return [B.rbox(centre, (arm, thick, depth), bevel=0.02), B.rbox(centre, (thick, arm, depth), bevel=0.02)]
    return [B.rbox(centre, (depth, thick, arm), bevel=0.02), B.rbox(centre, (depth, arm, thick), bevel=0.02)]


def build(lp):
    body = B.Body(lp)
    B.base(body, lp, {
        "arm": 0.33, "fore": 0.3, "leg": 0.39, "shin": 0.34, "torso": (1.9, 1.5, 0.95),
        "taper": 1.02, "sleeve": "short", "hands": "glove", "boot": -2.38, "bootr": 0.36,
    })

    # short haircut under a green field cap with a short visor and a white cross
    body.add("Head", "hair",
             B.rbox((0, 1.66, 0.1), (1.18, 0.9, 1.0), bevel=0.4, segments=3))
    body.add("Head", "gear",
             B.ell((0, 2.04, 0.04), (0.62, 0.34, 0.6), 14, 8),
             B.rbox((0, 1.97, -0.62), (0.8, 0.06, 0.42), bevel=0.03, rot=(-8, 0, 0)))
    body.add("Head", "light", *cross((0, 2.14, -0.57), 0.24, 0.08, 0.06))

    # chest: green cross patch, stethoscope round the neck
    body.add("UpperTorso", "gear", *cross((-0.32, 0.28, -0.5), 0.34, 0.11, 0.07))
    body.add("UpperTorso", "dark",
             B.cyl((0, 0.97, -0.02), (0.5, 0.45), 0.08, 16, bevel=0.03),
             B.capsule(lp, (0.3, 0.92, -0.42), (0.3, 0.45, -0.52), 0.035, subdiv=1),
             B.capsule(lp, (-0.25, 0.92, -0.44), (-0.12, 0.6, -0.52), 0.035, subdiv=1))
    body.add("UpperTorso", "metal", B.cyl((0.3, 0.4, -0.53), 0.1, 0.06, 10, bevel=0.02, rot=(90, 0, 0)))
    # medical backpack: body, top flap, white cross, straps over the shoulders
    body.add("UpperTorso", "gear",
             B.rbox((0, 0.2, 0.8), (1.44, 1.48, 0.62), bevel=0.24),
             B.rbox((0, 0.86, 0.78), (1.48, 0.26, 0.68), bevel=0.1))
    body.add("UpperTorso", "light", *cross((0, 0.18, 1.12), 0.6, 0.2, 0.06))
    body.add("UpperTorso", "gear",
             *[B.rbox((0.66 * k, 0.45, -0.49), (0.17, 1.05, 0.05), bevel=0.02) for k in (-1, 1)],
             *[B.rbox((0.66 * k, 1.0, 0.0), (0.17, 0.06, 1.0), bevel=0.02) for k in (-1, 1)])
    # hip satchel on the right
    body.add("LowerTorso", "gear", B.rbox((1.0, -0.84, -0.05), (0.26, 0.46, 0.56), bevel=0.08))
    body.add("LowerTorso", "light", *cross((1.135, -0.82, -0.05), 0.22, 0.07, 0.03, axis="x"))
    # green armband with a white cross on the left upper arm
    body.add("LeftUpperArm", "gear", B.cyl((-1.36, 0.28, 0), 0.355, 0.24, 14, bevel=0.04))
    body.add("LeftUpperArm", "light", *cross((-1.72, 0.28, 0), 0.17, 0.06, 0.03, axis="x"))

    return {
        "batch": "11c",
        "budget": "hero",
        "rig": "r15",
        "pieces": body.finish(),
        "colors": {
            "skin": (224, 170, 128),
            "hair": (40, 30, 30),
            "eye": (30, 24, 24),
            "shirt": (238, 238, 230),  # white field shirt
            "gear": (72, 172, 108),    # Field Medic green (HERO_COLORS MEDIC, toned down)
            "light": (246, 246, 240),  # white crosses
            "glove": (150, 206, 210),  # teal gloves
            "pants": (76, 88, 98),     # slate trousers
            "metal": (180, 186, 192),  # stethoscope chest piece
            "dark": (56, 52, 56),      # boots, belt, straps, stethoscope
        },
    }
