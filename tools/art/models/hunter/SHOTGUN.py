"""SHOTGUN - the Brush Beater (Shotgun, Brush Machete; 115 HP, close range): the tough one.

Read: broad and chunky, no hat - messy tufted hair with a green headband and brush goggles
pushed up on the forehead, an orange padded vest (the Brush Beater's orange, Server/Hero
HERO_COLORS) over a green T-shirt, big leather shoulder pads, bare forearms with leather
bracers, chunky gloves, knee pads, a machete sheath across the back, heavy boots.
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
        "arm": 0.37, "fore": 0.34, "leg": 0.42, "shin": 0.37, "torso": (2.05, 1.55, 1.02),
        "taper": 1.06, "sleeve": "short", "hands": "dark", "hand": 1.15, "boot": -2.12,
        "bootr": 0.42, "foot": 1.08, "armx": 1.42, "brow": 0.085,
    })

    # messy tufted hair, headband, goggles up on the forehead
    body.add("Head", "hair",
             B.rbox((0, 2.0, 0.04), (1.14, 0.42, 1.04), bevel=0.2),
             B.rbox((0, 1.66, 0.2), (1.14, 0.5, 0.74), bevel=0.24),
             *[B.ell(c, (0.19, 0.3, 0.17), 8, 6, rot=r) for c, r in (  # messy tufts
                 ((-0.34, 2.2, -0.22), (-25, 0, 25)),
                 ((0.02, 2.26, -0.28), (-30, 0, 0)),
                 ((0.36, 2.2, -0.18), (-25, 0, -25)),
                 ((-0.2, 2.22, 0.18), (25, 0, 20)),
                 ((0.2, 2.22, 0.22), (25, 0, -20)),
             )])
    body.add("Head", "gear2", B.cyl((0, 1.84, 0.0), (0.6, 0.56), 0.17, 16, bevel=0.04))
    body.add("Head", "light", *[B.cyl((0.22 * k, 1.86, -0.64), 0.14, 0.1, 12, bevel=0.03, rot=(90, 0, 0)) for k in (-1, 1)])
    body.add("Head", "dark",
             *[B.cyl((0.22 * k, 1.86, -0.6), 0.175, 0.08, 12, bevel=0.025, rot=(90, 0, 0)) for k in (-1, 1)],
             B.rbox((0, 1.86, -0.6), (0.12, 0.08, 0.06), bevel=0.02))

    # orange padded vest over the T-shirt: a shell over the torso, zip, pockets, quilting
    body.add("UpperTorso", "gear",
             B.rbox((0, 0.16, 0), (1.98, 1.36, 1.1), bevel=0.32, taper=(1.04, 1.0)))
    body.add("UpperTorso", "dark",
             B.rbox((0, 0.16, -0.555), (0.07, 1.25, 0.04), bevel=0.015),
             *[B.rbox((0, y, -0.545), (1.6, 0.04, 0.03), bevel=0.012) for y in (0.42, 0.0)])
    body.add("UpperTorso", "gear2", *[B.rbox((0.48 * k, -0.25, -0.56), (0.44, 0.34, 0.07), bevel=0.04) for k in (-1, 1)])
    # machete sheath across the back, handle over the right shoulder
    body.add("UpperTorso", "dark", B.rbox((0.1, 0.25, 0.6), (0.24, 1.3, 0.1), bevel=0.04, rot=(0, 0, -35)))
    body.add("UpperTorso", "pad", B.cyl((0.56, 0.93, 0.6), 0.08, 0.42, 8, bevel=0.03, rot=(0, 0, -35)))

    for k, side in B.SIDES:
        x = 1.42 * k
        # big leather shoulder pads, bracers, knee pads
        body.add(f"{side}UpperArm", "pad",
                 B.ell((x, 0.74, 0), (0.48, 0.3, 0.48), 12, 7))
        body.add(f"{side}LowerArm", "pad", B.cyl((x, -0.38, 0), (0.38, 0.38), 0.3, 12, top=1.06, bevel=0.06))
        body.add(f"{side}LowerLeg", "pad", B.ell((0.5 * k, -1.86, -0.3), (0.3, 0.3, 0.16), 10, 6))

    return {
        "batch": "11c",
        "budget": "hero",
        "rig": "r15",
        "pieces": body.finish(),
        "colors": {
            "skin": (132, 88, 60),
            "hair": (42, 32, 28),
            "eye": (30, 24, 24),
            "shirt": (76, 96, 60),     # green T-shirt
            "gear": (232, 124, 44),    # Brush Beater orange vest (HERO_COLORS SHOTGUN)
            "gear2": (86, 104, 64),    # headband, vest pockets
            "pants": (104, 92, 66),    # brush trousers
            "pad": (128, 84, 50),      # leather pads, bracers, machete grip
            "light": (120, 196, 206),  # goggle lenses
            "dark": (58, 44, 36),      # boots, gloves, belt, sheath, goggle frames
        },
    }
