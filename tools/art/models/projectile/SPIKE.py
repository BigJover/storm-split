"""Projectile SPIKE - Spike Flick (Ankylosaurus): a bone spike along a flat fast path, point
first (-Z = the flight direction); it sticks in the ground for a moment.
DinoLook: a 0.3 x 0.3 x 1.4 bone block at s = 1. A curved tapering spike on a knobbly base."""

import importlib.util
from pathlib import Path

_spec = importlib.util.spec_from_file_location("_shot", Path(__file__).with_name("_shot.py"))
S = importlib.util.module_from_spec(_spec)
_spec.loader.exec_module(S)


def build(lp):
    w = S.W.Walk(lp, ((-0.15, -0.15, -0.7), (0.15, 0.15, 0.7)), 1.0, slack=0.03)
    w.add("bone", S.W.rod((0, -0.02, 0.45), (0, 0.0, -0.1), 0.13, 8, top=0.62))
    w.add("bone", S.W.rod((0, 0.0, -0.1), (0, 0.05, -0.7), 0.08, 8, top=0.08))
    w.add("base", S.lump((0, -0.02, 0.5), (0.15, 0.14, 0.18), 7, 8, 5, 0.12))
    w.add("base", S.W.ring_along((0, -0.01, 0.3), (0, 0.0, 0.0), 0.12, 0.025, 8, 3))
    return S.model(w, {"bone": S.BONE, "base": S.W.mix(S.BONE, (150, 130, 100), 0.45)}, "spike", "Spike Flick spike")
