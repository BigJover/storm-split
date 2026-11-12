"""CROC_HIDE_CRUSHER - Brush Beater skin (500K Amber, Stone Age Bundle): the Brush Beater in croc hide.

The messy hair goes under a croc-skull cap (the upper jaw over the brow, eye knobs, a row of
teeth), the vest turns croc-green with a ridge of scutes down the back, scute spikes on the
shoulder pads and a bone-tooth necklace. The face stays clear (no dino disguise, #381).
Base: hunter/SHOTGUN (variants/_skins.py).
"""
# art-sources: SHOTGUN.py variants/_skins.py

import importlib.util
import math
from pathlib import Path

_spec = importlib.util.spec_from_file_location("_skins", Path(__file__).with_name("variants") / "_skins.py")
S = importlib.util.module_from_spec(_spec)
_spec.loader.exec_module(S)


def extra(body, lp, B):
    # croc-skull cap: crown, the upper jaw's snout over the brow, eye knobs, nostrils
    body.add("Head", "croc",
             B.rbox((0, 2.1, 0.06), (1.2, 0.5, 1.14), bevel=0.22, segments=2),
             B.ell((0, 2.05, -0.72), (0.4, 0.15, 0.42), 12, 6),
             *[B.ell((0.24 * k, 2.36, -0.32), (0.12, 0.1, 0.12), 8, 5) for k in (-1, 1)])
    body.add("Head", "dark",
             *[B.ell((0.1 * k, 2.15, -1.08), (0.04, 0.03, 0.04), 6, 3) for k in (-1, 1)],
             *[B.ell((0.24 * k, 2.42, -0.38), (0.05, 0.04, 0.03), 6, 3) for k in (-1, 1)])
    teeth = []
    for i in range(5):
        t = (i - 2) / 2
        teeth.append(B.cone(lp, (0.36 * t, 1.93, -0.72 - 0.3 * (1 - abs(t))), (0.36 * t, 1.78, -0.74 - 0.3 * (1 - abs(t))), 0.04, 5))
    for k in (-1, 1):
        teeth += [B.cone(lp, (0.38 * k, 1.93, z), (0.38 * k, 1.8, z), 0.04, 5) for z in (-0.45, -0.25)]
    body.add("Head", "bone", *teeth)
    # scute ridges: down the cap and the vest's back
    body.add("Head", "scute", *[B.ell((0, 2.36, z), (0.09, 0.07, 0.1), 6, 3) for z in (0.0, 0.25, 0.5)])
    body.add("UpperTorso", "scute", *[B.ell((0.18 * k, y, 0.6), (0.11, 0.08, 0.06), 6, 3) for k in (-1, 1) for y in (0.55, 0.2, -0.15)])
    # scute spikes on the shoulder pads
    for k, side in B.SIDES:
        body.add(f"{side}UpperArm", "scute", *[
            B.cone(lp, (1.42 * k, 0.98, z), (1.42 * k + 0.06 * k, 1.16, z), 0.07, 5) for z in (-0.2, 0.05, 0.3)])
    # bone-tooth necklace round the neck
    body.add("UpperTorso", "bone", *[
        B.cone(lp, (0.42 * math.sin(a), 0.9, -0.3 * math.cos(a) - 0.22), (0.42 * math.sin(a), 0.7, -0.32 * math.cos(a) - 0.24), 0.045, 5)
        for a in (-0.9, -0.45, 0.0, 0.45, 0.9)])
    body.add("UpperTorso", "dark", B.cyl((0, 0.93, -0.02), (0.56, 0.5), 0.05, 16, bevel=0.02))


def build(lp):
    return S.variant(
        lp, "SHOTGUN", "CROC_HIDE_CRUSHER", "Croc Hide Crusher",
        drop=[("Head", "hair", 1)],  # the messy hair + tufts (under the cap now; the brows stay)
        extra=extra,
        colors={
            "gear": (80, 110, 70),     # croc-green vest = the skin's colour (Skins sheet)
            "croc": (74, 102, 64),
            "scute": (52, 74, 46),
            "bone": (214, 204, 172),   # the skin's accent
            "pad": (100, 80, 52),
            "gear2": (62, 74, 50),
            "shirt": (66, 80, 54),
            "pants": (92, 84, 62),
        },
    )
