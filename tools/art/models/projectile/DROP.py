"""Projectile DROP - Stone Drop (Pteranodon): a stone falling straight down onto the ring.
DinoLook: a 1.2 Slate ball at s = 1. A flat-ish angular slate slab with a lighter edge."""

import importlib.util
from pathlib import Path

_spec = importlib.util.spec_from_file_location("_shot", Path(__file__).with_name("_shot.py"))
S = importlib.util.module_from_spec(_spec)
_spec.loader.exec_module(S)


def build(lp):
    w = S.W.Walk(lp, ((-0.6, -0.6, -0.6), (0.6, 0.6, 0.6)), 1.0, slack=0.03)
    w.add("rock", S.lump((0, 0, 0), (0.58, 0.4, 0.55), 41, 8, 5, 0.12, 0.5))
    w.add("layer", S.lump((0.05, 0.2, -0.04), (0.42, 0.18, 0.4), 42, 8, 4, 0.1, 0.5))
    return S.model(w, {"rock": S.W.mix(S.ROCK, (80, 85, 95), 0.3), "layer": S.W.mix(S.ROCK, (175, 170, 160), 0.3)},
                   "drop", "Stone Drop slate")
