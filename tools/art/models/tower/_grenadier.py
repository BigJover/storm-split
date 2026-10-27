"""GRENADIER - Mortar Pit (TowerLook olive): a ring of sandbags round an olive mortar tube on
a steel base plate, angled up at the front. Authored from the base (y 0) in Roblox studs;
front = -Z (_kit conventions).

Stage 0 (tiers 0-2): two courses of sandbags, base plate, tube on a bipod, two shells.
Stage 1 (tier 3):    a third course on the front half, a fatter tube with steel bands and a
                     sight, an ammo crate of shells, a shovel stuck in the bags.
Stage 2 (tier 5):    a plank floor, brass bands and a brass sight dial on the tube, glowing
                     shells in the crate, a pile of brass casings, a lantern on a stake.
"""

import importlib.util
import math
from pathlib import Path

_spec = importlib.util.spec_from_file_location("_kit", Path(__file__).with_name("_kit.py"))
K = importlib.util.module_from_spec(_spec)
_spec.loader.exec_module(K)

OLIVE = (120, 115, 70)  # TowerLook.COLORS.GRENADIER
BAG_H = 0.28
RING = 1.22  # sandbag ring centre line, half width


def course(level, front_only=False):
    """One course of sandbags round the pit (staggered every other course)."""
    y = BAG_H / 2 + level * (BAG_H - 0.03)
    out = []
    off = 0.31 if level % 2 else 0.0
    us = (-0.7, 0.0, 0.7) if not off else (-0.36, 0.36)
    sides = ((0, -1), (0, 1), (-1, 0), (1, 0))
    for sx, sz in sides:
        if front_only and sz != -1 and not (sx and True):
            continue
        for i, u in enumerate(us):
            if sx:
                if front_only and u > 0.1:
                    continue  # third course: the front half only
                x, z, yaw = sx * RING, u, 90 + (i % 2) * 6 - 3
            else:
                x, z, yaw = u, sz * RING, (i % 2) * 6 - 3
            out.append(K.pillow((x, y, z), 0.74, yaw=yaw))
    for cx in (-1, 1):
        for cz in (-1, 1):
            if front_only and cz > 0:
                continue
            out.append(K.pillow((cx * 1.08, y, cz * 1.08), 0.6, yaw=45 * cx * cz + (90 if level % 2 else 0)))
    return out


def build(lp, stage):
    k = K.Kit(lp)

    bags = course(0) + course(1)
    if stage >= 1:
        bags += course(2, front_only=True)
    k.add("sand", *bags)
    k.add("dirt", K.cyl((0, 0.02, 0), (1.12, 1.12), 0.04, 16, bevel=0.0))  # the pit floor

    # base plate and the tube, angled up at the front; the tube's mouth is the firing point
    pivot = (0, 0.42, 0.32)
    el = math.radians(52)
    length = 2.0 if stage == 0 else 2.15
    d = (0, math.sin(el), -math.cos(el))
    tip = tuple(p + q * length for p, q in zip(pivot, d))
    r = 0.22 if stage == 0 else 0.26
    k.add("metal", K.cyl((0, 0.07, 0.32), 0.58, 0.14, 14, bevel=0.04),
          K.ell(pivot, (0.2, 0.2, 0.2), 8, 5))
    k.add("body", K.rod(pivot, tip, r, 12, top=0.92))
    k.add("dark", K.ring_along(tip, tuple(t + q for t, q in zip(tip, d)), r * 0.92 + 0.02, 0.045, 12, 4),
          piece="muzzle", role="muzzle")
    # bipod from the tube's middle to the plate's front
    mid = K.along(pivot, tip, 0.55)
    k.add("metal", *[K.rod(mid, (sx * 0.42, 0.12, -0.18), 0.04, 6) for sx in (-1, 1)],
          K.rod((-0.42, 0.12, -0.18), (0.42, 0.12, -0.18), 0.035, 6))

    shells = []
    if stage == 0:  # two shells lying by the plate
        for x, z in ((-0.62, 0.68), (-0.38, 0.8)):
            shells.append(K.rod((x, 0.1, z - 0.22), (x, 0.1, z + 0.18), 0.1, 8))
        k.add("body", *shells)
        k.add("dark", *[K.rod((x, 0.1, z - 0.22), (x, 0.1, z - 0.34), 0.08, 8, top=0.3) for x, z in ((-0.62, 0.68), (-0.38, 0.8))])

    brass = []
    if stage >= 1:
        # steel (stage 1) or brass (stage 2) bands on the tube, a sight block
        bands = [K.ring_along(K.along(pivot, tip, t), tip, r * (1 - 0.08 * t), 0.05, 12, 5) for t in (0.25, 0.75)]
        (brass if stage >= 2 else shells).extend(bands)
        sight_at = tuple(p + q for p, q in zip(K.along(pivot, tip, 0.3), (0.3, 0.0, 0.0)))
        sight = K.rbox(sight_at, (0.16, 0.22, 0.2), bevel=0.04)
        (brass if stage >= 2 else shells).append(sight)
        if stage >= 2:
            brass.append(K.cyl((0.4, sight_at[1] + 0.05, sight_at[2]), 0.1, 0.05, 10, rot=(0, 0, 90)))  # dial
        if shells:
            k.add("metal", *shells)
        # ammo crate at the back-left with shells standing in it
        crate = (-0.6, 0.22, 0.72)
        k.add("wood", K.rbox(crate, (0.66, 0.44, 0.5), bevel=0.05))
        k.add("dark", *[K.rbox((crate[0], crate[1] + dy, crate[2]), (0.68, 0.05, 0.52), bevel=0.02) for dy in (-0.12, 0.12)])
        heads = [K.ell((crate[0] + dx, crate[1] + 0.3, crate[2] + dz), (0.09, 0.14, 0.09), 6, 4)
                 for dx in (-0.16, 0.0, 0.16) for dz in (-0.1, 0.1)]
        k.add("glow" if stage >= 2 else "body", *heads, piece="shellheads")
        # a shovel stuck in the bags at the right
        k.add("wood", K.rod((1.18, 0.4, -0.35), (1.0, 1.25, -0.42), 0.035, 6))
        k.add("metal", K.rbox((1.22, 0.33, -0.34), (0.06, 0.32, 0.24), bevel=0.03, rot=(0, 0, 12)))

    if stage >= 2:
        # plank floor in the pit
        k.add("deck", *[K.rbox((x, 0.03, 0.05), (0.36, 0.05, 2.0), bevel=0.015) for x in (-0.76, -0.38, 0.0, 0.38, 0.76)])
        # brass casings piled at the front-right
        brass += [K.rod((x, 0.17 + dy, z - 0.15), (x + 0.04, 0.17 + dy, z + 0.15), 0.07, 8)
                  for x, z, dy in ((0.55, -0.55, 0.0), (0.7, -0.4, 0.0), (0.62, -0.47, 0.13))]
        # a lantern on a stake at the front-left corner
        k.add("wood", K.rod((-1.1, 0.0, -0.75), (-1.1, 1.3, -0.75), 0.04, 6))
        brass += [K.cyl((-1.1, 1.36, -0.75), 0.09, 0.06, 8)]
        k.add("glow", K.ell((-1.1, 1.18, -0.75), (0.1, 0.13, 0.1), 8, 5))
    if brass:
        k.add("brass", *brass)

    colors = {
        "body": OLIVE, "sand": K.SAND, "dirt": (112, 92, 66), "metal": K.METAL, "dark": (52, 54, 50), "wood": K.WOOD,
        "deck": (150, 112, 72), "brass": K.BRASS, "glow": (255, 150, 60),
    }
    return k.model("11d", colors, "GRENADIER", stage)
