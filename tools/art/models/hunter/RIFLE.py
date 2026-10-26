"""RIFLE - the Big Game Hunter (Hunting Rifle, Stock Swing; 110 HP): the classic safari hunter.

Read: sturdy build, cream pith helmet with a yellow band (the Big Game Hunter's yellow,
Server/Hero HERO_COLORS), a big friendly moustache, khaki four-pocket safari jacket with
epaulettes and rolled sleeves, a brass-cartridge bandolier across the chest, khaki shorts,
cream knee socks and tall brown boots.
Built on the shared R15 figure (_body.py); Roblox studs about the HumanoidRootPart.
"""

import importlib.util
import math
from pathlib import Path

_spec = importlib.util.spec_from_file_location("_body", Path(__file__).with_name("_body.py"))
B = importlib.util.module_from_spec(_spec)
_spec.loader.exec_module(B)


def build(lp):
    body = B.Body(lp)
    B.base(body, lp, {
        "arm": 0.35, "fore": 0.31, "leg": 0.4, "shin": 0.34, "torso": (2.0, 1.55, 1.0),
        "taper": 1.04, "sleeve": "rolled", "hands": "skin", "boot": -2.32, "bootr": 0.37,
        "shorts": True, "armx": 1.38, "brow": 0.07,
    })

    # pith helmet: dome, oval brim (longer front and back), yellow band, top button
    body.add("Head", "gear",
             B.ell((0, 2.04, 0.0), (0.64, 0.56, 0.68), 14, 9),
             B.cyl((0, 1.9, 0.02), (0.84, 0.98), 0.06, 20, bevel=0.025),
             B.ell((0, 2.6, 0), (0.07, 0.05, 0.07), 6, 4))
    body.add("Head", "accent", B.cyl((0, 2.0, 0), (0.645, 0.685), 0.12, 18, bevel=0.03))
    # moustache, hair at the back under the helmet
    body.add("Head", "hair",
             *[B.ell((0.15 * k, 1.37, -0.535), (0.17, 0.065, 0.06), 8, 5, rot=(0, 0, 14 * k)) for k in (-1, 1)],
             B.rbox((0, 1.6, 0.07), (1.18, 0.66, 1.04), bevel=0.38))

    # safari jacket details: four pockets, collar, epaulettes
    body.add("UpperTorso", "gear2",
             *[B.rbox((0.42 * k, 0.5, -0.5), (0.4, 0.3, 0.06), bevel=0.03) for k in (-1, 1)],
             *[B.rbox((0.45 * k, -0.25, -0.5), (0.46, 0.38, 0.06), bevel=0.03) for k in (-1, 1)],
             B.rbox((0.8, 0.98, 0), (0.42, 0.08, 0.5), bevel=0.03))  # epaulette (the left one is under the bandolier)
    body.add("UpperTorso", "shirt", *[B.rbox((0.2 * k, 0.94, -0.36), (0.34, 0.2, 0.08), bevel=0.03, rot=(-25, 0, 28 * k)) for k in (-1, 1)])
    # bandolier: left shoulder to right hip, front and back, brass rounds on the front
    a = math.radians(40)
    d = (-math.sin(a), math.cos(a))
    body.add("UpperTorso", "dark",
             B.rbox((-0.04, 0.28, -0.5), (0.3, 1.75, 0.07), bevel=0.03, rot=(0, 0, 40)),
             B.rbox((-0.04, 0.28, 0.5), (0.3, 1.75, 0.07), bevel=0.03, rot=(0, 0, 40)),
             B.rbox((-0.62, 1.03, 0), (0.3, 0.07, 1.04), bevel=0.03))  # over the left shoulder
    body.add("UpperTorso", "accent", *[
        B.cyl((-0.04 + d[0] * t, 0.28 + d[1] * t, -0.55), 0.055, 0.24, 6, bevel=0.015, rot=(0, 0, -50))
        for t in (-0.6, -0.4, -0.2, 0.0, 0.2, 0.4, 0.6)])
    body.add("LowerTorso", "accent", B.rbox((0, -0.63, -0.49), (0.24, 0.16, 0.05), bevel=0.03))  # buckle
    # sock cuffs (turned down at the top)
    for k, side in B.SIDES:
        body.add(f"{side}LowerLeg", "sock", B.cyl((0.5 * k, -1.74, 0), 0.36, 0.13, 12, bevel=0.05))

    return {
        "batch": "11c",
        "budget": "hero",
        "rig": "r15",
        "pieces": body.finish(),
        "colors": {
            "skin": (236, 188, 150),
            "hair": (150, 86, 44),     # ginger moustache
            "eye": (32, 26, 26),
            "shirt": (206, 186, 136),  # khaki safari jacket
            "gear2": (176, 156, 106),  # pockets, epaulettes
            "pants": (190, 168, 118),  # khaki shorts
            "gear": (232, 222, 190),   # pith helmet
            "accent": (232, 190, 64),  # Big Game Hunter yellow / brass (HERO_COLORS RIFLE)
            "sock": (236, 228, 204),
            "dark": (112, 72, 40),     # tan-brown leather: boots, belt, bandolier
        },
    }
