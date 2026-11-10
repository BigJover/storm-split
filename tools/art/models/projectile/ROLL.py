"""Projectile ROLL - Horn Toss (Triceratops): a big boulder rolling and bouncing along the ground.
DinoLook: a 2.5 Boulder ball at s = 1 (Height attribute = its size, for rolling). A round
lumpy boulder with lighter chips and a moss patch (so the roll reads)."""

import importlib.util
from pathlib import Path

_spec = importlib.util.spec_from_file_location("_shot", Path(__file__).with_name("_shot.py"))
S = importlib.util.module_from_spec(_spec)
_spec.loader.exec_module(S)


def build(lp):
    w = S.W.Walk(lp, ((-1.25, -1.25, -1.25), (1.25, 1.25, 1.25)), 1.0, slack=0.04)
    w.add("rock", S.lump((0, 0, 0), (1.2, 1.18, 1.2), 51, 12, 8, 0.07, 0.2))
    w.add("chip", *[S.lump(c, (0.86, 0.86, 0.86), 60 + i, 7, 4, 0.08, 0.5) for i, c in
                    enumerate(((0.3, 0.28, -0.3), (-0.32, -0.25, 0.3)))])  # lighter split faces
    w.add("moss", S.lump((0.2, 0.32, 0.25), (0.92, 0.88, 0.92), 70, 7, 4, 0.05))  # a moss cap on one side
    return S.model(w, {"rock": S.BOULDER, "chip": S.W.mix(S.BOULDER, (170, 160, 145), 0.4), "moss": (88, 112, 62)},
                   "roll", "Horn Toss boulder")
