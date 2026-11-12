"""JUNGLE_GHOST - Tracker skin (500K Amber, Treehouse Bundle): the Tracker in a ghillie of leaves.

The slouch hat becomes a leafy ghillie hood (two rings of leaves over a moss cap), leaf tufts on
both shoulders, a vine wound round the chest and pale stripes of face paint; pale green shirt,
bone trousers (the Skins sheet's colours). Base: hunter/PISTOL (variants/_skins.py).
"""
# art-sources: PISTOL.py variants/_skins.py

import importlib.util
import math
from pathlib import Path

_spec = importlib.util.spec_from_file_location("_skins", Path(__file__).with_name("variants") / "_skins.py")
S = importlib.util.module_from_spec(_spec)
_spec.loader.exec_module(S)


def leaf(B, centre, yaw, tilt, size=(0.32, 0.07, 0.17)):
    """A flat leaf: a thin ellipsoid, long along its own x, turned to `yaw` and drooped by `tilt`."""
    return B.ell(centre, size, 6, 3, rot=(0, yaw, tilt))


def extra(body, lp, B):
    # moss cap + two rings of leaves = the ghillie hood
    body.add("Head", "leaf2", B.ell((0, 2.02, 0.06), (0.66, 0.4, 0.64), 12, 7))
    ring = []
    for i in range(9):
        a = 2 * math.pi * (i + 0.5) / 9
        c, s = math.cos(a), math.sin(a)
        ring.append(leaf(B, (0.62 * c, 1.98, 0.06 + 0.6 * s), -math.degrees(a), -28))
    for i in range(5):
        a = 2 * math.pi * i / 5
        c, s = math.cos(a), math.sin(a)
        ring.append(leaf(B, (0.28 * c, 2.3, 0.06 + 0.28 * s), -math.degrees(a), -38, (0.3, 0.065, 0.16)))
    body.add("Head", "leaf", *ring)
    # face paint: two pale stripes on each cheek
    body.add("Head", "paint", *[
        B.rbox((0.3 * k, 1.47 + dy, -0.505), (0.2, 0.04, 0.03), bevel=0.012, segments=1, rot=(0, 0, 12 * k))
        for k in (-1, 1) for dy in (0.0, -0.09)])
    # leaf tufts on the shoulders (they move with the arms)
    for k, side in B.SIDES:
        body.add(f"{side}UpperArm", "leaf", *[
            leaf(B, (1.36 * k + 0.16 * math.cos(a) * k, 0.92, 0.18 * math.sin(a)), -math.degrees(a) * k, -30 * k)
            for a in (0.4, 2.0, 3.9)])
    # a vine wound round the chest
    pts = [(-0.95, 0.75, -0.2), (-0.5, 0.55, -0.52), (0.1, 0.2, -0.55), (0.65, -0.2, -0.5), (0.98, -0.35, 0.0),
           (0.6, -0.1, 0.5), (-0.2, 0.4, 0.52), (-0.95, 0.75, 0.2)]
    body.add("UpperTorso", "vine", *[B.capsule(lp, a, b, 0.05, subdiv=1) for a, b in zip(pts, pts[1:])])
    body.add("UpperTorso", "leaf", *[leaf(B, p, 30 * i, -20, (0.17, 0.045, 0.1)) for i, p in enumerate(pts[1:6:2])])


def build(lp):
    return S.variant(
        lp, "PISTOL", "JUNGLE_GHOST", "Jungle Ghost",
        drop=[("Head", "gear", 0), ("Head", "accent", 0), ("Head", "light", 0)],  # hat, band, feather
        extra=extra,
        colors={
            "shirt": (170, 200, 170),  # the skin's colour (Skins sheet)
            "pants": (220, 215, 195),  # the skin's accent
            "leaf": (92, 138, 84),
            "leaf2": (70, 104, 62),    # moss cap
            "vine": (84, 100, 56),
            "paint": (226, 232, 214),
            "gear": (150, 140, 108),
            "dark": (88, 78, 60),
            "accent": (226, 234, 216),  # bandana
        },
    )
