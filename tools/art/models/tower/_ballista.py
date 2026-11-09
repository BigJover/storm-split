"""BALLISTA - Harpoon Ballista (TowerLook oiled oak): a heavy oak crossbow on a steel turntable,
a barbed harpoon loaded and a rope winch at the back. Authored from the base (y 0) in Roblox
studs; front = -Z (_kit conventions).

Stage 0 (tiers 0-2): plank base, the turntable, the post and yoke, the stock, recurved bow arms
                     and string, the harpoon (muzzle ring at the stock's nose), the winch.
Stage 1 (tier 3):    a DOUBLE BALLISTA - twin stocks side by side on a taller post, two harpoons,
                     a wider and heavier bow, steel bands, the lines running back to the winch.
Stage 2 (tier 5):    a big steel-plated mantlet shield across the front with a brass rim, a brass
                     sighting arch with a ring sight crowning the twin stocks, brass bands and
                     arm caps, and both harpoon heads glowing.
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


def on_stock(z, lift=0.0, py=1.9, x=0.0):
    """A point on the stock's top line at z (the stock pivots at y `py`, z 0)."""
    return (x, py + 0.24 + lift - z * math.tan(PITCH), z)


def build(lp, stage):
    k = K.Kit(lp)
    py = 1.9 if stage == 0 else 2.15  # the pivot: the upgrades stand taller
    xs = (0.0,) if stage == 0 else (-0.3, 0.3)  # one stock, or twin stocks
    lean = stage >= 1

    # base: a plank cross, the steel turntable, the post and its yoke
    k.add("wood", *[K.rbox((0, 0.06, z), (2.6, 0.12, 0.42), bevel=0 if lean else 0.04) for z in (-0.55, 0.55)])
    k.add("metal", K.cyl((0, 0.24, 0), 1.25 if stage == 0 else 1.32, 0.24, 18, bevel=0.06),
          K.cyl((0, 0.42, 0), 0.5, 0.14, 12, bevel=0 if lean else 0.04))
    k.add("dark", *[K.ell((math.cos(a) * 1.05, 0.37, math.sin(a) * 1.05), (0.06, 0.04, 0.06), 6, 3)
                    for a in [i * math.pi / 4 for i in range(8)]])  # rivets
    pw = 0.5 if stage == 0 else 0.62
    k.add("wood", K.rbox((0, 0.4 + (py - 0.6) / 2, 0.1), (pw, py - 0.6, pw), bevel=0.06))
    yx = 0.3 if stage == 0 else 0.62
    k.add("metal", *[K.rbox((sx * yx, py - 0.12, 0.0), (0.1, 0.45, 0.4), bevel=0 if lean else 0.03) for sx in (-1, 1)],
          K.rod((-yx - 0.06, py - 0.05, 0.0), (yx + 0.06, py - 0.05, 0.0), 0.06, 8))  # yoke + trunnion pin
    if lean:
        k.add("metal", K.rbox((0, py - 0.3, 0.0), (2 * yx + 0.1, 0.1, 0.4), bevel=0))  # the yoke's cross-plate

    # the stock(s): long oak beams, tilted up at the front
    sw = 0.46 if stage == 0 else 0.34
    for x in xs:
        a, b = (x, py - 1.2 * math.tan(PITCH), 1.2), (x, py + 1.35 * math.tan(PITCH), -1.35)
        k.add("body", K.bar(a, b, sw, 0.4, bevel=0.07 if stage == 0 else 0.05))
    # recurved bow arms out from the stock's front, swept back (wider and heavier on the twin)
    nose = on_stock(-0.95, -0.05, py)
    arms, tips = [], []
    span = (1.35, 1.42, 1.33)[stage]
    th = 1.0 if stage == 0 else 1.35
    for sx in (-1, 1):
        root = (sx * (0.15 if stage == 0 else 0.42), nose[1], -0.95)
        mid = (sx * 0.85 if lean else sx * 0.75, nose[1] + 0.02, -0.75 if stage == 0 else -0.85)
        tip = (sx * span, nose[1] + 0.06, -0.35 if stage == 0 else -0.3)
        arms += [K.bar(root, mid, 0.24 * th, 0.18 * th, bevel=0.06),
                 K.bar(mid, tip, 0.16 * th, 0.13 * th, bevel=0.05)]
        tips.append(tip)
    if lean:  # a crossbeam joining the twin stocks' noses
        arms.append(K.bar(on_stock(-1.0, -0.25, py, -0.55), on_stock(-1.0, -0.25, py, 0.55), 0.22, 0.26, bevel=0.04, up=(0, 1, 0)))
    k.add("body", *arms)
    strings, heads_ = [], []
    for x in xs:
        nock = on_stock(0.35, 0.02, py, x)
        strings += [K.rod(t, nock, 0.03 if stage == 0 else 0.035, 6) for t in tips] if stage == 0 else \
            [K.rod((t[0], t[1], t[2]), nock, 0.035, 6) for t in tips if (t[0] > 0) == (x > 0)]
        # the harpoon on the stock's top
        tail, head = on_stock(0.55, 0.1, py, x), on_stock(-1.2, 0.1, py, x)
        k.add("metal", K.rod(tail, head, 0.06, 8))
        point = (x, head[1] + 0.2 * math.tan(PITCH), -1.47)
        hb = [K.rod(K.along(head, point, -0.25), point, 0.17, 8, top=0.05)]
        for sx in (-1, 1):  # barbs
            hb.append(K.rod((x, head[1], head[2] + 0.02), (x + sx * (0.26 if stage == 0 else 0.2), head[1], head[2] + 0.28), 0.045, 5, top=0.3))
        heads_ += hb
        k.add("leather", *[K.rbox((x, tail[1], tail[2] - 0.04 + dz), (0.14, 0.1, 0.06), bevel=0.02 if stage == 0 else 0) for dz in (0.0, 0.1)])
        if lean:  # the line from the harpoon's tail back to the winch drum
            k.add("rope", K.rod((x, tail[1] - 0.02, tail[2] + 0.02), (x * 0.5, 1.15, 0.98), 0.03, 6))
    k.add("string", *strings)
    if stage >= 2:
        k.add("glow", *heads_, piece="harpoonhead")  # both heads glow
    else:
        k.add("metal", *heads_, piece="harpoonhead")
    # the muzzle ring(s) at the stock's nose: the piece's centre is the firing point
    k.add("dark", *[K.ring_along(on_stock(-1.3, 0.05, py, x), on_stock(-2.3, 0.05, py, x), 0.14, 0.035, 10, 4) for x in xs],
          piece="muzzle", role="muzzle")

    # the winch at the back: a drum with rope and two cranks
    wz, wy = 1.05, 1.0
    k.add("wood", *[K.rbox((sx * 0.42, wy - 0.25, wz), (0.12, 0.9, 0.36), bevel=0.04 if stage == 0 else 0) for sx in (-1, 1)])
    k.add("rope", K.cyl((0, wy, wz), 0.2, 0.62, 12, rot=(0, 0, 90)))
    k.add("dark", *[K.cyl((sx * 0.33, wy, wz), 0.26, 0.05, 12, rot=(0, 0, 90), bevel=0.03 if stage == 0 else 0) for sx in (-1, 1)])
    k.add("metal", *[K.rod((sx * 0.48, wy, wz), (sx * 0.56, wy - 0.3, wz + 0.08), 0.03, 6) for sx in (-1, 1)],
          *[K.rod((sx * 0.56, wy - 0.3, wz + 0.08), (sx * 0.7, wy - 0.3, wz + 0.08), 0.04, 6) for sx in (-1, 1)])

    brass = []
    if stage >= 1:
        trim = brass if stage >= 2 else k.sets.setdefault("metal", [])
        for x in xs:  # bands round each stock
            trim.extend(K.ring_along(on_stock(z, -0.2, py, x), on_stock(z - 1, -0.2, py, x), 0.24, 0.04, 10, 3) for z in (-0.6, 0.6))

    if stage >= 2:
        brass += [K.ell(t, (0.15, 0.12, 0.15), 8, 5) for t in tips]  # arm caps
        # the mantlet: a steel-plated plank shield across the front, brass-rimmed, a slot for the harpoons
        mz, mh, mw = -1.25, 1.0, 2.6
        k.add("wood", K.rbox((0, 0.12 + mh / 2, mz), (mw, mh, 0.14), bevel=0, rot=(10, 0, 0)))
        k.add("metal", *[K.rbox((sx * 0.72, 0.12 + mh / 2, mz - 0.09), (0.9, mh - 0.2, 0.05), bevel=0, rot=(10, 0, 0)) for sx in (-1, 1)])
        brass.append(K.rbox((0, 0.12 + mh / 2 + 0.53, mz + 0.09), (mw + 0.04, 0.1, 0.22), bevel=0, rot=(10, 0, 0)))  # top rim
        k.add("dark", *[K.ell((sx * 0.72 + dx, 0.12 + mh / 2 + dy, mz - 0.13 + dy * 0.17), (0.05, 0.05, 0.03), 4, 3)
                        for sx in (-1, 1) for dx in (-0.3, 0.3) for dy in (-0.25, 0.25)])  # plate rivets
        # the sighting arch over the twin stocks, a ring sight on top (the crown)
        az, ay = -0.2, py + 0.25
        arch = [K.rod((sx * 0.62, py - 0.1, az), (sx * 0.45, ay + 0.75, az), 0.06, 6) for sx in (-1, 1)]
        arch.append(K.rod((-0.45, ay + 0.75, az), (0.45, ay + 0.75, az), 0.06, 6))
        arch.append(K.ring_along((0, ay + 1.08, az), (0, ay + 1.08, az - 1), 0.28, 0.06, 14, 4))
        arch.append(K.rod((0, ay + 0.75, az), (0, ay + 0.8, az), 0.08, 6))
        brass += arch
        k.add("glow", K.ell((0, ay + 1.08, az), (0.12, 0.12, 0.05), 8, 4), piece="sight")  # the sight's lens
        k.add("brass", *brass)

    colors = {
        "body": OAK, "wood": K.WOOD, "dark": K.DARK, "metal": K.METAL, "string": STRING,
        "rope": K.ROPE, "leather": (180, 60, 45), "brass": K.BRASS, "glow": (255, 150, 70),
    }
    return k.model("11d", colors, "BALLISTA", stage)
