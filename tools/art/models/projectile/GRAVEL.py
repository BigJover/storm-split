"""Projectile GRAVEL - Gravel Spray (Gallimimus): 3 pebbles in a tight cluster on a low arc.
DinoLook: Shot = a 0.75 Sand ball at the centre + Pebble1 (0.65) at (0.75, 0.2, 0.3) and
Pebble2 (0.65) at (-0.6, -0.15, 0.55), s = 1. Three knapped pebbles in one model."""

import importlib.util
from pathlib import Path

_spec = importlib.util.spec_from_file_location("_shot", Path(__file__).with_name("_shot.py"))
S = importlib.util.module_from_spec(_spec)
_spec.loader.exec_module(S)


def build(lp):
    w = S.W.Walk(lp, ((-0.925, -0.475, -0.375), (1.075, 0.525, 0.875)), 1.0, slack=0.03)
    w.add("sand", S.lump((0, 0, 0), (0.36, 0.3, 0.34), 31, 8, 5, 0.14, 0.3))
    w.add("sand", S.lump((0.75, 0.2, 0.3), (0.31, 0.27, 0.3), 32, 8, 5, 0.14, 0.3))
    w.add("pebble", S.lump((-0.6, -0.15, 0.55), (0.31, 0.25, 0.29), 33, 8, 5, 0.14, 0.3))
    return S.model(w, {"sand": S.SAND, "pebble": S.W.mix(S.SAND, (110, 90, 70), 0.35)}, "gravel", "Gravel Spray pebbles")
