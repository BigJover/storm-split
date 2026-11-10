"""Projectile CAPSULE - Bone Spit (T-Rex): a bone-white capsule along its flight.
DinoLook: a 1.6 long, 0.64 wide capsule along Z at s = 1 (a cylinder + two ball caps; the model's
pivot faces along it). Here a cartoon bone: a shaft with two double knobs, along Z."""

import importlib.util
from pathlib import Path

_spec = importlib.util.spec_from_file_location("_shot", Path(__file__).with_name("_shot.py"))
S = importlib.util.module_from_spec(_spec)
_spec.loader.exec_module(S)


def build(lp):
    w = S.W.Walk(lp, ((-0.32, -0.32, -1.12), (0.32, 0.32, 1.12)), 1.0, slack=0.03)
    w.add("bone", S.W.rod((0, 0, -0.6), (0, 0, 0.6), 0.13, 8))
    for z in (-0.72, 0.72):
        w.add("bone", *[S.W.ell((0.14 * s, 0, z), (0.19, 0.2, 0.2), 8, 5) for s in (-1, 1)])
    w.add("marrow", *[S.W.ring_along((0, 0, z), (0, 0, z * 2), 0.135, 0.02, 8, 3) for z in (-0.35, 0.35)])
    return S.model(w, {"bone": S.BONE, "marrow": S.W.mix(S.BONE, (170, 120, 90), 0.4)}, "capsule", "Bone Spit bone")
