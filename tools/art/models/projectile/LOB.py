"""Projectile LOB - Skull Toss (Pachycephalosaurus): a stone on a high spinning arc.
DinoLook: a 0.8 Rock ball at s = 1 (max(base, 0.8 s)). A rough round stone with a few chips."""

import importlib.util
from pathlib import Path

_spec = importlib.util.spec_from_file_location("_shot", Path(__file__).with_name("_shot.py"))
S = importlib.util.module_from_spec(_spec)
_spec.loader.exec_module(S)


def build(lp):
    w = S.W.Walk(lp, ((-0.4, -0.4, -0.4), (0.4, 0.4, 0.4)), 1.0, slack=0.03)
    w.add("rock", S.lump((0, 0, 0), (0.38, 0.35, 0.37), 11, 10, 7, 0.1, 0.25))
    w.add("chip", S.lump((0.08, 0.1, -0.08), (0.3, 0.27, 0.3), 21, 8, 5, 0.12, 0.4))  # a lighter knapped face
    return S.model(w, {"rock": S.ROCK, "chip": S.W.mix(S.ROCK, (190, 180, 165), 0.35)}, "lob", "Skull Toss stone")
