"""MOUNTAIN_RESCUE - Field Medic skin (300K Amber, Brass Gear Bundle): an alpine rescuer.

The field cap becomes a red climbing helmet with a headlamp, a blue rope coil goes over the right
shoulder, a bedroll rides on the pack, silver reflective bands circle the sleeves and shins;
orange jacket, grey trousers (the Skins sheet's colours). Base: hunter/MEDIC (variants/_skins.py).
"""
# art-sources: MEDIC.py variants/_skins.py

import importlib.util
import math
from pathlib import Path

_spec = importlib.util.spec_from_file_location("_skins", Path(__file__).with_name("variants") / "_skins.py")
S = importlib.util.module_from_spec(_spec)
_spec.loader.exec_module(S)


def extra(body, lp, B):
    # climbing helmet: dome, rim, vents, chin strap; headlamp on the front
    body.add("Head", "helmet",
             B.ell((0, 2.0, 0.04), (0.64, 0.5, 0.64), 14, 8),
             B.cyl((0, 1.86, 0.04), (0.66, 0.66), 0.1, 18, bevel=0.04))
    body.add("Head", "dark",
             *[B.rbox((0.2 * k, 2.38, 0.06), (0.08, 0.06, 0.5), bevel=0.02, segments=1) for k in (-1, 1)],
             *[B.rbox((0.56 * k, 1.4, 0.02), (0.05, 0.62, 0.08), bevel=0.02, segments=1) for k in (-1, 1)])
    body.add("Head", "metal", B.rbox((0, 2.06, -0.64), (0.3, 0.2, 0.14), bevel=0.05))
    body.add("Head", "lamp", B.cyl((0, 2.06, -0.72), 0.08, 0.04, 10, bevel=0.0, rot=(90, 0, 0)))
    # rope coil over the right shoulder to the left hip (an ellipse of capsules, front and back)
    pts = []
    for i in range(10):
        a = 2 * math.pi * i / 10
        x, y = 0.95 * math.cos(a), 0.7 * math.sin(a)
        c, s = math.cos(math.radians(-40)), math.sin(math.radians(-40))
        px, py = x * c - y * s, x * s + y * c
        pts.append((px * 0.75, 0.3 + py, -0.56 if math.sin(a) < 0.15 and math.cos(a) > -0.9 else 0.56))
    coil = []
    for a, b in zip(pts, pts[1:] + pts[:1]):
        if a[2] == b[2]:
            coil.append(B.capsule(lp, a, b, 0.07, subdiv=1))
    coil.append(B.capsule(lp, (0.72, 0.92, -0.5), (0.72, 0.98, 0.5), 0.08, subdiv=1))  # over the shoulder
    body.add("UpperTorso", "rope", *coil)
    # bedroll on the pack
    body.add("UpperTorso", "roll", B.cyl((0, 1.18, 0.8), 0.2, 1.3, 12, bevel=0.06, rot=(0, 0, 90)))
    # reflective bands: sleeves and shins
    for k, side in B.SIDES:
        body.add(f"{side}UpperArm", "stripe", B.cyl((1.36 * k, 0.5, 0), 0.36, 0.08, 10, bevel=0.02))
        body.add(f"{side}LowerLeg", "stripe", B.cyl((0.5 * k, -2.0, 0), 0.355, 0.1, 10, bevel=0.02))


def build(lp):
    return S.variant(
        lp, "MEDIC", "MOUNTAIN_RESCUE", "Mountain Rescue",
        drop=[("Head", "gear", 0), ("Head", "light", 0)],  # field cap + its cross
        extra=extra,
        target=4800, keep=150,
        colors={
            "shirt": (230, 120, 40),   # the skin's colour (Skins sheet)
            "pants": (90, 90, 95),     # the skin's accent
            "gear": (196, 56, 48),     # pack, straps, armband, satchel: rescue red
            "helmet": (212, 50, 44),
            "light": (246, 246, 240),
            "glove": (60, 62, 70),
            "rope": (70, 130, 200),
            "roll": (78, 96, 72),
            "stripe": (214, 218, 224),
            "lamp": (255, 236, 170),
            "metal": (70, 72, 78),
        },
    )
