"""MEDIC_LIFESAVER - Carbine skin Lifesaver (400K Amber; the top carbine skin): a rescue carbine.
Orange and white striped wraps in place of the bandage, a white cross on the butt, and a little
orange-and-white life ring hanging from the saddle ring. `accent` (the skin's orange) = the
orange wraps and the ring; `white` = the skin's white. Base: gun/MEDIC (variants/_skins.py).
"""
# art-sources: _medic.py variants/_skins.py

import importlib.util
from pathlib import Path

_spec = importlib.util.spec_from_file_location("_skins", Path(__file__).with_name("variants") / "_skins.py")
S = importlib.util.module_from_spec(_spec)
_spec.loader.exec_module(S)

import math


def extra(g, G, D):
    y = 0.155
    g.add("accent",
          *[G.rod((0, y, z), (0, y, z - 0.07), 0.078, 8) for z in (-0.44, -0.72)],  # orange wraps
          G.ring((-0.09, -0.06, 0.05), 0.085, 0.03, 10, 4, axis="x"))  # life ring
    g.add("white",
          *[G.rod((0, y, z), (0, y, z - 0.21), 0.076, 8) for z in (-0.51,)],
          *[G.rbox((-0.09, -0.06 + 0.085 * math.cos(a), 0.05 + 0.085 * math.sin(a)), (0.075, 0.03, 0.03),
                   bevel=0.0, segments=0, rot=(-math.degrees(a), 0, 0)) for a in (0.785, 2.356, 3.927, 5.498)])
    g.add("dark", G.rod((-0.08, 0.17, 0.05), (-0.09, 0.03, 0.05), 0.01, 4))  # its cord


def build(lp):
    return S.variant(
        lp, "MEDIC", "LIFESAVER", "Lifesaver",
        drop=[("cloth", 0)],  # the bandage wrap
        move=[("accent", 0, "white"), ("accent", 1, "white")],  # the butt's cross turns white
        extra=extra,
        colors={"accent": (235, 120, 60), "white": (240, 240, 240)},
    )
