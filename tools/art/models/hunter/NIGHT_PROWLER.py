"""NIGHT_PROWLER - Tracker skin (300K Amber, Midnight Bundle): the Tracker gone night hunting.

The slouch hat comes off for a deep navy hood with a shoulder drape, a cloth mask over the nose
and mouth (the eyes stay clear), a night-vision monocular over the right eye, a short cloak down
the back and three throwing knives on the chest strap. Midnight's ice-blue on the trims.
Base: hunter/PISTOL (variants/_skins.py).
"""
# art-sources: PISTOL.py variants/_skins.py

import importlib.util
import math
from pathlib import Path

_spec = importlib.util.spec_from_file_location("_skins", Path(__file__).with_name("variants") / "_skins.py")
S = importlib.util.module_from_spec(_spec)
_spec.loader.exec_module(S)


def extra(body, lp, B):
    # hood: crown, sides and back round the hair, a peak over the brow, a drape on the shoulders
    body.add("Head", "hood",
             B.ell((0, 1.72, 0.3), (0.7, 0.74, 0.64), 16, 10),
             B.ell((0, 1.66, 0.3), (0.62, 0.62, 0.6), 12, 7, rot=(-8, 0, 0)))  # the opening's rolled edge
    body.add("UpperTorso", "hood", B.cyl((0, 1.0, 0.06), (0.74, 0.6), 0.24, 18, top=0.8, bevel=0.08))
    # mask over the nose and mouth
    body.add("Head", "mask", B.rbox((0, 1.28, -0.47), (0.94, 0.32, 0.2), bevel=0.09, segments=2))
    # monocular over the right eye on a strap
    body.add("Head", "metal", B.cyl((0.22, 1.62, -0.66), 0.11, 0.24, 10, bevel=0.03, rot=(90, 0, 0)))
    body.add("Head", "lens", B.cyl((0.22, 1.62, -0.79), 0.075, 0.04, 10, bevel=0.0, rot=(90, 0, 0)))
    # short cloak down the back, tied at the drape
    body.add("UpperTorso", "cloak", B.rbox((0, -0.12, 0.6), (1.72, 1.95, 0.1), bevel=0.05, segments=2, taper=(0.74, 1.0), rot=(-7, 0, 0)))
    # three throwing knives on the chest strap (the strap runs at -38 degrees)
    a = math.radians(38)
    body.add("UpperTorso", "metal", *[
        B.rbox((math.sin(a) * t, 0.22 + math.cos(a) * t, -0.52), (0.07, 0.3, 0.03), bevel=0.012, segments=1, rot=(0, 0, -38))
        for t in (-0.38, 0.0, 0.38)])


def build(lp):
    return S.variant(
        lp, "PISTOL", "NIGHT_PROWLER", "Night Prowler",
        drop=[("Head", "gear", 0), ("Head", "accent", 0), ("Head", "light", 0)],  # hat, band, feather
        extra=extra,
        colors={
            "shirt": (40, 45, 70),     # the skin's colour (Skins sheet)
            "pants": (55, 55, 60),     # the skin's accent
            "hood": (32, 36, 56),
            "cloak": (30, 33, 50),
            "mask": (26, 28, 38),
            "gear": (62, 64, 74),      # pouches, sheath
            "dark": (34, 32, 36),      # boots, gloves, holster, strap
            "accent": (96, 176, 214),  # Midnight ice-blue (bandana, buckle)
            "metal": (120, 126, 136),
            "lens": (120, 220, 255),   # Midnight's accent; SmoothPlastic, never Neon (#381)
        },
    )
