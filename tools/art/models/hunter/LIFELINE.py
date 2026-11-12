"""LIFELINE - Field Medic skin (500K Amber; the top medic skin): a modern paramedic.

The field cap becomes a radio headset (earcups, band, mic boom) with tinted glasses pushed up on
the forehead, a graphite shoulder guard on the left arm, a red heartbeat line across the chest and
a radio antenna on the pack; teal top, white trousers and pack (the Skins sheet's colours).
Base: hunter/MEDIC (variants/_skins.py).
"""
# art-sources: MEDIC.py variants/_skins.py

import importlib.util
import math
from pathlib import Path

_spec = importlib.util.spec_from_file_location("_skins", Path(__file__).with_name("variants") / "_skins.py")
S = importlib.util.module_from_spec(_spec)
_spec.loader.exec_module(S)


def extra(body, lp, B):
    # headset: earcups, band over the top, mic boom to the mouth
    body.add("Head", "tech",
             *[B.cyl((0.6 * k, 1.56, 0.02), 0.2, 0.14, 12, bevel=0.04, rot=(0, 0, 90)) for k in (-1, 1)],
             B.capsule(lp, (-0.62, 1.7, 0.02), (-0.36, 2.14, 0.02), 0.05, subdiv=1),
             B.capsule(lp, (-0.36, 2.14, 0.02), (0.36, 2.14, 0.02), 0.05, subdiv=1),
             B.capsule(lp, (0.36, 2.14, 0.02), (0.62, 1.7, 0.02), 0.05, subdiv=1),
             B.capsule(lp, (0.66, 1.5, -0.1), (0.3, 1.3, -0.6), 0.03, subdiv=1))
    body.add("Head", "pulse", B.ell((0.27, 1.29, -0.62), (0.06, 0.05, 0.06), 8, 4))  # mic tip
    # short hair on top (the cap is gone)
    body.add("Head", "hair", B.ell((0, 2.0, 0.08), (0.6, 0.3, 0.56), 12, 6))
    # tinted glasses pushed up on the forehead
    body.add("Head", "visor", B.rbox((0, 1.95, -0.52), (0.92, 0.16, 0.08), bevel=0.04, segments=1, rot=(-12, 0, 0)))
    # shoulder guard on the left arm
    body.add("LeftUpperArm", "tech", B.ell((-1.36, 0.66, 0), (0.42, 0.26, 0.42), 12, 6))
    # heartbeat line across the right chest
    line = [(0.0, 0.0), (0.18, 0.0), (0.26, 0.22), (0.34, -0.18), (0.42, 0.08), (0.48, 0.0), (0.74, 0.0)]
    body.add("UpperTorso", "pulse", *[
        B.capsule(lp, (x1, y1 - 0.05, -0.54), (x2, y2 - 0.05, -0.54), 0.03, subdiv=1) for (x1, y1), (x2, y2) in zip(line, line[1:])])
    # radio antenna on the pack
    body.add("UpperTorso", "tech", B.capsule(lp, (0.5, 0.9, 0.95), (0.56, 1.95, 1.0), 0.03, subdiv=1))
    body.add("UpperTorso", "pulse", B.ell((0.56, 1.97, 1.0), (0.06, 0.06, 0.06), 8, 4))


def build(lp):
    return S.variant(
        lp, "MEDIC", "LIFELINE", "Lifeline",
        drop=[("Head", "gear", 0), ("Head", "light", 0)],  # field cap + its cross
        extra=extra,
        colors={
            "shirt": (60, 170, 170),   # the skin's colour (Skins sheet)
            "pants": (232, 236, 236),  # the skin's accent
            "gear": (240, 242, 242),   # pack, straps, armband, satchel: white
            "light": (212, 52, 62),    # the crosses turn red on white
            "glove": (40, 52, 60),
            "tech": (50, 60, 70),
            "pulse": (220, 60, 70),
            "visor": (110, 210, 222),
        },
    )
