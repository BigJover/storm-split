"""SHOTGUN_BAMBOO_BOOMSTICK - Shotgun skin Bamboo Boomstick (200K Amber, Treehouse Bundle): the
walnut is swapped for bamboo. A stock of two bamboo poles lashed with twine, a bamboo pump with a
node, twine wraps; the barrel, receiver and muzzle stay steel. `accent` (the skin's bamboo
yellow, Wood) = the bamboo; the side saddle's shells keep the class orange. Base: gun/SHOTGUN.
"""
# art-sources: _shotgun.py variants/_skins.py

import importlib.util
from pathlib import Path

_spec = importlib.util.spec_from_file_location("_skins", Path(__file__).with_name("variants") / "_skins.py")
S = importlib.util.module_from_spec(_spec)
_spec.loader.exec_module(S)


def extra(g, G, D):
    g.add("accent",
          G.rod((0, 0.17, 0.12), (0, 0.1, 0.98), 0.085, 8),  # upper pole
          G.rod((0, -0.02, 0.3), (0, -0.1, 0.98), 0.07, 8),  # lower pole
          G.rod((0, 0.12, -0.56), (0, 0.12, -0.98), 0.082, 8))  # pump
    g.add("node",
          G.rod((0, 0.145, 0.5), (0, 0.14, 0.54), 0.094, 8),
          G.rod((0, 0.12, -0.76), (0, 0.12, -0.79), 0.09, 8))
    g.add("twine",
          G.rod((0, 0.05, 0.7), (0, 0.04, 0.78), 0.15, 6),
          G.rod((0, 0.12, -0.6), (0, 0.12, -0.64), 0.088, 6))


def build(lp):
    return S.variant(
        lp, "SHOTGUN", "BAMBOO_BOOMSTICK", "Bamboo Boomstick",
        drop=[("wood", 0), ("wood", 1), ("wood", 3), ("dark", 1)],  # walnut stock, wrist, pump, pump groove
        move=[("accent", i, "shell") for i in range(4)],  # the shells keep the class orange
        extra=extra,
        colors={"accent": (190, 175, 100), "node": (150, 138, 72), "twine": (176, 150, 100),
                "wood": (168, 140, 84), "shell": (255, 140, 50)},
    )
