"""BALLISTA - Harpoon Ballista (TowerLook oiled oak): a heavy oak crossbow on a steel turntable,
a barbed harpoon loaded and a rope winch at the back. Authored from the base (y 0) in Roblox
studs; front = -Z (_kit conventions).

Stage 0 (tiers 0-2): plank base, the turntable, the post and yoke, the stock, recurved bow arms
                     and string, the harpoon (muzzle ring at the stock's nose), the winch.
Stage 1 (tier 3):    steel bands on the stock and arms, the harpoon's line running back to the
                     winch, a rack of spare harpoons, plank shields on the arms.
Stage 2 (tier 5):    brass arm caps, bands and a brass sight, a brass-bound harpoon head, a
                     glowing lantern on a post at the front-left.
"""

import importlib.util
import math
from pathlib import Path

_spec = importlib.util.spec_from_file_location("_kit", Path(__file__).with_name("_kit.py"))
K = importlib.util.module_from_spec(_spec)
_spec.loader.exec_module(K)

OAK = (125, 90, 55)  # TowerLook.COLORS.BALLISTA
STRING = (205, 190, 150)

PITCH = math.radians(8)  # the stock tilts up toward the front


def on_stock(z, lift=0.0):
    """A point on the stock's top line at z (the stock pivots at y 1.9, z 0)."""
    return (0.0, 1.9 + 0.24 + lift - z * math.tan(PITCH), z)


def build(lp, stage):
    k = K.Kit(lp)

    # base: a plank cross, the steel turntable, the post and its yoke
    k.add("wood", *[K.rbox((0, 0.06, z), (2.6, 0.12, 0.42), bevel=0.04) for z in (-0.55, 0.55)])
    k.add("metal", K.cyl((0, 0.24, 0), 1.25, 0.24, 18, bevel=0.06),
          K.cyl((0, 0.42, 0), 0.5, 0.14, 12, bevel=0.04))
    k.add("dark", *[K.ell((math.cos(a) * 1.05, 0.37, math.sin(a) * 1.05), (0.06, 0.04, 0.06), 6, 3)
                    for a in [i * math.pi / 4 for i in range(8)]])  # rivets
    k.add("wood", K.rbox((0, 1.05, 0.1), (0.5, 1.3, 0.5), bevel=0.06))
    k.add("metal", *[K.rbox((sx * 0.3, 1.78, 0.0), (0.1, 0.45, 0.4), bevel=0.03) for sx in (-1, 1)],
          K.rod((-0.36, 1.85, 0.0), (0.36, 1.85, 0.0), 0.06, 8))  # yoke + trunnion pin

    # the stock: a long oak beam, tilted up at the front
    a, b = (0.0, 1.9 - 1.2 * math.tan(PITCH), 1.2), (0.0, 1.9 + 1.35 * math.tan(PITCH), -1.35)
    k.add("body", K.bar(a, b, 0.46, 0.4, bevel=0.07))
    # recurved bow arms out from the stock's front, swept back
    nose = on_stock(-0.95, -0.05)
    arms, tips = [], []
    for sx in (-1, 1):
        mid = (sx * 0.75, nose[1] + 0.02, -0.75)
        tip = (sx * 1.35, nose[1] + 0.06, -0.35)
        arms += [K.bar((sx * 0.15, nose[1], -0.95), mid, 0.24, 0.18, bevel=0.06),
                 K.bar(mid, tip, 0.16, 0.13, bevel=0.05)]
        tips.append(tip)
    k.add("body", *arms)
    nock = on_stock(0.35, 0.02)
    k.add("string", *[K.rod(t, nock, 0.03, 6) for t in tips])
    # the harpoon on the stock's top; the muzzle ring at the stock's nose
    tail, head = on_stock(0.55, 0.1), on_stock(-1.2, 0.1)
    k.add("metal", K.rod(tail, head, 0.06, 8))
    point = (0.0, head[1] + 0.2 * math.tan(PITCH), -1.47)
    hb = []
    hb.append(K.rod(K.along(head, point, -0.25), point, 0.17, 8, top=0.05))
    for sx in (-1, 1):  # barbs
        hb.append(K.rod((0, head[1], head[2] + 0.02), (sx * 0.26, head[1], head[2] + 0.28), 0.045, 5, top=0.3))
    k.add("brass" if stage >= 2 else "metal", *hb, piece="harpoonhead")
    k.add("leather", *[K.rbox((0, tail[1], tail[2] - 0.04 + dz), (0.14, 0.1, 0.06), bevel=0.02) for dz in (0.0, 0.1)])  # fletch vanes
    k.add("dark", K.ring_along(on_stock(-1.3, 0.05), on_stock(-2.3, 0.05), 0.14, 0.035, 10, 4), piece="muzzle", role="muzzle")

    # the winch at the back: a drum with rope and two cranks
    wz, wy = 1.05, 1.0
    k.add("wood", *[K.rbox((sx * 0.42, wy - 0.25, wz), (0.12, 0.9, 0.36), bevel=0.04) for sx in (-1, 1)])
    k.add("rope", K.cyl((0, wy, wz), 0.2, 0.62, 12, rot=(0, 0, 90)))
    k.add("dark", *[K.cyl((sx * 0.33, wy, wz), 0.26, 0.05, 12, rot=(0, 0, 90)) for sx in (-1, 1)])
    k.add("metal", *[K.rod((sx * 0.48, wy, wz), (sx * 0.56, wy - 0.3, wz + 0.08), 0.03, 6) for sx in (-1, 1)],
          *[K.rod((sx * 0.56, wy - 0.3, wz + 0.08), (sx * 0.7, wy - 0.3, wz + 0.08), 0.04, 6) for sx in (-1, 1)])

    brass = []
    if stage >= 1:
        bands = [K.ring_along(on_stock(z, -0.2), on_stock(z - 1, -0.2), 0.3, 0.04, 10, 4) for z in (-0.6, 0.6)]
        (brass if stage >= 2 else k.sets.setdefault("metal", [])).extend(bands)
        # the line from the harpoon's tail back to the winch drum
        k.add("rope", K.rod((0, tail[1] - 0.02, tail[2] + 0.02), (0, wy + 0.15, wz - 0.05), 0.03, 6))
        # a rack of spare harpoons at the left
        rx = -1.2
        k.add("wood", K.rbox((rx, 0.35, 0.25), (0.14, 0.7, 0.14), bevel=0.03),
              K.rbox((rx, 0.35, 0.85), (0.14, 0.7, 0.14), bevel=0.03),
              K.rbox((rx, 0.62, 0.55), (0.14, 0.08, 0.8), bevel=0.02))
        spares = [K.rod((rx + dx, 0.12, 0.55 + dz), (rx + dx * 0.2, 1.4, 0.55 + dz * 0.4), 0.035, 6) for dx, dz in ((-0.08, -0.2), (0.06, 0.0), (-0.04, 0.2))]
        k.add("metal", *spares, *[K.rod((rx + dx * 0.2, 1.4, 0.55 + dz * 0.4), (rx + dx * 0.15, 1.6, 0.55 + dz * 0.35), 0.07, 6, top=0.05)
                                    for dx, dz in ((-0.08, -0.2), (0.06, 0.0), (-0.04, 0.2))])
        # plank shields on the arms
        k.add("wood", *[K.rbox((sx * 0.6, nose[1] - 0.25, -0.88), (0.6, 0.38, 0.06), bevel=0.03, rot=(0, -sx * 18, 0)) for sx in (-1, 1)])
        k.add("dark", *[K.ell((sx * 0.6 + dx, nose[1] - 0.25, -0.92 + sx * dx * 0.3), (0.03, 0.03, 0.03), 4, 3)
                        for sx in (-1, 1) for dx in (-0.2, 0.2)])

    if stage >= 2:
        brass += [K.ell(t, (0.12, 0.1, 0.12), 8, 5) for t in tips]  # arm caps
        brass.append(K.rbox(on_stock(-0.15, 0.22), (0.1, 0.2, 0.08), bevel=0.02))  # sight post
        brass.append(K.ring_along(on_stock(-0.15, 0.36), on_stock(-1.15, 0.36), 0.07, 0.02, 8, 4))
        # a lantern on a post at the front-left
        lx, lz = -1.1, -1.15
        k.add("wood", K.rod((lx, 0.12, lz), (lx, 1.5, lz), 0.045, 6), K.rod((lx, 1.5, lz), (lx + 0.22, 1.5, lz), 0.03, 6))
        brass += [K.cyl((lx + 0.22, 1.44, lz), 0.09, 0.05, 8)]
        k.add("glow", K.ell((lx + 0.22, 1.29, lz), (0.09, 0.12, 0.09), 8, 5))
        k.add("brass", *brass)

    colors = {
        "body": OAK, "wood": K.WOOD, "dark": K.DARK, "metal": K.METAL, "string": STRING,
        "rope": K.ROPE, "leather": (180, 60, 45), "brass": K.BRASS, "glow": K.GLOW,
    }
    return k.model("11d", colors, "BALLISTA", stage)
