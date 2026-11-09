"""GRENADIER - Mortar Pit (TowerLook olive): a ring of sandbags round an olive mortar tube on
a steel base plate, angled up at the front. Authored from the base (y 0) in Roblox studs;
front = -Z (_kit conventions).

Stage 0 (tiers 0-2): two courses of sandbags, base plate, tube on a bipod, two shells.
Stage 1 (tier 3):    a third course of sandbags all round, a battery of TWO fat steel-banded
                     mortars on one long plate, an ammo crate of shells.
Stage 2 (tier 5):    one huge siege mortar on a brass-ringed turntable (brass bands, a glowing
                     bore), a tall spotter's mast at the back-left with a glowing brass
                     crow's-nest lantern and pennant, a plank floor, glowing shells.
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
CHEAP = {"segments": 6, "rings": 3}  # the upper courses' bags (~24 triangles each)


def course(level, front_only=False, cheap=False):
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
            out.append(K.pillow((x, y, z), 0.74, yaw=yaw, **CHEAP) if cheap else K.pillow((x, y, z), 0.74, yaw=yaw))
    for cx in (-1, 1):
        for cz in (-1, 1):
            if front_only and cz > 0:
                continue
            yaw = 45 * cx * cz + (90 if level % 2 else 0)
            out.append(K.pillow((cx * 1.08, y, cz * 1.08), 0.6, yaw=yaw, **CHEAP) if cheap else K.pillow((cx * 1.08, y, cz * 1.08), 0.6, yaw=yaw))
    return out


def tube(k, pivot, el_deg, length, r, group="body"):
    """A mortar tube from pivot, elevated toward the front; returns (tip, direction)."""
    el = math.radians(el_deg)
    d = (0, math.sin(el), -math.cos(el))
    tip = tuple(p + q * length for p, q in zip(pivot, d))
    k.add(group, K.rod(pivot, tip, r, 12, top=0.92))
    return tip, d


def build(lp, stage):
    k = K.Kit(lp)

    bags = course(0) + course(1, cheap=stage >= 1)
    if stage >= 1:  # a third course all round: a deeper pit
        bags += course(2, cheap=True)
    k.add("sand", *bags)
    if stage < 2:  # (stage 2 lays planks over it)
        k.add("dirt", K.cyl((0, 0.02, 0), (1.12, 1.12), 0.04, 16, bevel=0.0))  # the pit floor

    brass = []
    if stage == 0:
        # base plate and the tube, angled up at the front; the tube's mouth is the firing point
        pivot = (0, 0.42, 0.32)
        k.add("metal", K.cyl((0, 0.07, 0.32), 0.58, 0.14, 14, bevel=0.04), K.ell(pivot, (0.2, 0.2, 0.2), 8, 5))
        tip, d = tube(k, pivot, 52, 2.0, 0.22)
        r = 0.22
        k.add("dark", K.ring_along(tip, tuple(t + q for t, q in zip(tip, d)), r * 0.92 + 0.02, 0.045, 12, 4),
              piece="muzzle", role="muzzle")
        # bipod from the tube's middle to the plate's front
        mid = K.along(pivot, tip, 0.55)
        k.add("metal", *[K.rod(mid, (sx * 0.42, 0.12, -0.18), 0.04, 6) for sx in (-1, 1)],
              K.rod((-0.42, 0.12, -0.18), (0.42, 0.12, -0.18), 0.035, 6))
        # two shells lying by the plate
        k.add("body", *[K.rod((x, 0.1, z - 0.22), (x, 0.1, z + 0.18), 0.1, 8) for x, z in ((-0.62, 0.68), (-0.38, 0.8))])
        k.add("dark", *[K.rod((x, 0.1, z - 0.22), (x, 0.1, z - 0.34), 0.08, 8, top=0.3) for x, z in ((-0.62, 0.68), (-0.38, 0.8))])

    elif stage == 1:
        # a battery of two fat mortars side by side on one long plate, steel-banded
        k.add("metal", K.rbox((0, 0.08, 0.3), (1.7, 0.14, 0.9), bevel=0.05))
        tips = []
        for i, x in enumerate((0.45, -0.45)):
            pivot = (x, 0.44, 0.34)
            k.add("metal", K.ell(pivot, (0.22, 0.22, 0.22), 6, 4))
            tip, d = tube(k, pivot, 55, 2.0, 0.27)
            tips.append((tip, d, pivot))
            k.add("metal", *[K.ring_along(K.along(pivot, tip, t), tip, 0.27 * (1 - 0.08 * t), 0.05, 10, 3) for t in (0.3, 0.75)])
            mid = K.along(pivot, tip, 0.5)
            k.add("metal", *[K.rod(mid, (x + sx * 0.3, 0.14, -0.3), 0.04, 6) for sx in (-1, 1)])
            ring = K.ring_along(tip, tuple(t + q for t, q in zip(tip, d)), 0.27 * 0.92 + 0.02, 0.05, 12, 4)
            if i == 0:
                k.add("dark", ring, piece="muzzle", role="muzzle")
            else:
                k.add("dark", ring)

    else:
        # one huge siege mortar on a brass-trimmed turntable, the crowning gun
        pivot = (0, 0.55, 0.38)
        k.add("brass", K.cyl((0, 0.1, 0.32), 0.82, 0.18, 14, bevel=0.05))
        k.add("metal",
              *[K.rbox((sx * 0.42, 0.42, 0.38), (0.16, 0.6, 0.6), bevel=0.05) for sx in (-1, 1)])  # cheeks
        brass += [K.rod((-0.52, 0.55, 0.38), (0.52, 0.55, 0.38), 0.12, 8)]  # trunnion axle
        tip, d = tube(k, pivot, 55, 2.15, 0.42)
        brass += [K.ring_along(K.along(pivot, tip, t), tip, 0.42 * (1 - 0.08 * t) + 0.01, 0.06, 12, 3) for t in (0.25, 0.8)]
        k.add("dark", K.ring_along(tip, tuple(t + q for t, q in zip(tip, d)), 0.42 * 0.92 + 0.03, 0.07, 14, 4),
              piece="muzzle", role="muzzle")
        k.add("glow", K.cyl(tuple(t + q * 0.01 for t, q in zip(tip, d)), 0.33, 0.06, 12, bevel=0.0, rot=(-35, 0, 0)), piece="bore")
        # a tall spotter's mast at the back-left: crow's-nest lantern glowing, brass pennant pole top
        mx, mz = -1.2, 1.15
        k.add("wood", K.rod((mx, 0.0, mz), (mx, 3.5, mz), 0.07, 6))
        brass += [K.cyl((mx, 2.62, mz), 0.25, 0.08, 8), K.cyl((mx, 3.24, mz), 0.25, 0.08, 8, top=0.6),
                  *[K.rod((mx + dx, 2.62, mz + dz), (mx + dx, 3.24, mz + dz), 0.025, 4) for dx, dz in ((0.18, 0.18), (-0.18, -0.18), (0.18, -0.18), (-0.18, 0.18))],
                  K.ell((mx, 3.58, mz), (0.09, 0.09, 0.09), 8, 4)]
        k.add("glow", K.ell((mx, 2.93, mz), (0.21, 0.27, 0.21), 8, 5), piece="bore")
        k.add("body", K.rbox((mx + 0.42, 3.3, mz), (0.68, 0.36, 0.04), bevel=0.0, taper=(1.0, 1.0), rot=(0, 0, 0)))  # pennant
        # plank floor in the pit
        k.add("deck", *[K.rbox((x, 0.03, 0.05), (0.36, 0.05, 2.0), bevel=0.0) for x in (-0.76, -0.38, 0.0, 0.38, 0.76)])

    if stage >= 1:
        # ammo crate at the back-left with shells standing in it (glowing at stage 2)
        crate = (-0.62, 0.22, 0.8)
        k.add("wood", K.rbox(crate, (0.66, 0.44, 0.48), bevel=0.05))
        k.add("dark", *[K.rbox((crate[0], crate[1] + dy, crate[2]), (0.68, 0.05, 0.5), bevel=0.0) for dy in (-0.12, 0.12)])
        heads = [K.ell((crate[0] + dx, crate[1] + 0.3, crate[2] + dz), (0.09, 0.14, 0.09), 6, 3)
                 for dx in (-0.12, 0.12) for dz in (-0.1, 0.1)]
        k.add("glow" if stage >= 2 else "body", *heads, piece="shellheads")
    if brass:
        k.add("brass", *brass)

    colors = {
        "body": OLIVE, "sand": K.SAND, "dirt": (112, 92, 66), "metal": K.METAL, "dark": (52, 54, 50), "wood": K.WOOD,
        "deck": (150, 112, 72), "brass": K.BRASS, "glow": (255, 150, 60),
    }
    return k.model("11d", colors, "GRENADIER", stage)
