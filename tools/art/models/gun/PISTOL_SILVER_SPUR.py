"""PISTOL_SILVER_SPUR - Revolver skin Silver Spur (250K Amber, Midnight Bundle): a nickel-silver
revolver with pearl grips, two engraved bands on the barrel and a spur rowel (a five-point star)
on each grip panel. `accent` (the skin's silver, Metal) = the bands + the rowel; the frame is bright
nickel. Base: gun/PISTOL (variants/_skins.py); grip and muzzle unchanged.
"""
# art-sources: _pistol.py variants/_skins.py

import importlib.util
from pathlib import Path

_spec = importlib.util.spec_from_file_location("_skins", Path(__file__).with_name("variants") / "_skins.py")
S = importlib.util.module_from_spec(_spec)
_spec.loader.exec_module(S)

import math


def extra(g, G, D):
    y = D.BORE
    g.add("steel", G.rod((0, y - 0.01, 0.075), (0, y - 0.01, -0.165), 0.112, 10))  # plain cylinder
    g.add("pearl", G.rbox((0, -0.03, 0.08), (0.15, 0.4, 0.17), bevel=0.05, segments=1, rot=(-18, 0, 0)))
    g.add("accent",
          G.rod((0, y, -0.3), (0, y, -0.34), 0.056, 8),  # engraved bands
          G.rod((0, y, -0.66), (0, y, -0.7), 0.054, 8),
          G.rod((-0.081, -0.03, 0.08), (0.081, -0.03, 0.08), 0.03, 8),  # rowel hub through the grip
          *[G.rbox((0.079 * k, -0.03 + 0.05 * math.cos(a), 0.08 + 0.05 * math.sin(a)), (0.01, 0.075, 0.024),
                   bevel=0.0, segments=0, rot=(math.degrees(a), 0, 0))
            for k in (-1, 1) for a in [math.radians(90 + i * 72) for i in range(5)]])


def build(lp):
    return S.variant(
        lp, "PISTOL", "SILVER_SPUR", "Silver Spur",
        drop=[("wood", 0), ("accent", 0), ("accent", 1), ("steel", 2)],  # walnut grip, medallions, cylinder
        extra=extra,
        colors={"steel": (150, 156, 168), "brass": (214, 216, 224), "pearl": (242, 230, 204),
                "accent": (200, 200, 210)},
    )
