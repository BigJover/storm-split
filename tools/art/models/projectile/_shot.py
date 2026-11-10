"""Shared helpers for the dino projectiles (kind `projectile`, PLAN 11d2): one model per
DinoLook.PROJECTILE_STYLE (lob, spike, gravel, drop, roll, capsule), keyed by style in capitals.

Authored like the walkers (models/walker/_walker.py `Walk`): Roblox studs about the `Shot`
part's centre (DinoLook.buildProjectile's PrimaryPart; the model's pivot), at the shot's
scale-1 size (`s` = 1, `base` <= the minimum: buildProjectile's max(base, k * s) - the runtime
scales the art to the live Shot size). The spike and the bone lie along Z (the pivot faces
along the flight). Each <= 300 tris (CAP, checked here; budget class small).
"""

import importlib.util
import math
import random
from pathlib import Path

_spec = importlib.util.spec_from_file_location("_walker", Path(__file__).parents[1] / "walker" / "_walker.py")
W = importlib.util.module_from_spec(_spec)
_spec.loader.exec_module(W)

CAP = 300
ROCK = (120, 105, 90)  # DinoLook ROCK
BONE = (230, 225, 210)
SAND = (170, 140, 100)
BOULDER = (95, 85, 75)


def lump(centre, radii, seed, segments=10, rings=6, rough=0.12, flat=0.0):
    """A lumpy stone: an ellipsoid with every vertex pushed in / out by up to `rough` (a share
    of its radius), deterministic per seed; `flat` squares off a few faces (a knapped look)."""
    rng = random.Random(seed)
    obj = W.ell((0, 0, 0), radii, segments, rings)
    for v in obj.data.vertices:
        k = 1 + rng.uniform(-rough, rough)
        if flat and rng.random() < flat:
            k = min(k, 0.9)
        v.co = v.co * k
        v.co.x += centre[0]
        v.co.y += centre[1]
        v.co.z += centre[2]
    obj.data.update()
    return obj


def model(w, colors, style, display, budget="small"):
    m = w.model(budget, colors, {"projectile": style, "look": "DinoLook.buildProjectile", "display": display},
                CAP, pad=0.12)
    total = sum(w.lp.tris(o) for o in m["pieces"])
    assert total <= CAP, f"{style}: {total} tris > {CAP}"
    return m
