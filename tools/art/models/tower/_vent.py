"""VENT - Volcano Vent (TowerLook basalt; a 4x tower): a mound of ash and rock crowned with a ring
of hexagonal basalt columns round a crater of lava, crust plates floating on it, a lava run down
the front and a plume of smoke. Authored from the base (y 0) in Roblox studs; front = -Z (_kit
conventions). The columns in the back-right (the owner flag's corner) stay short.
(Fire Mountain's cone, setVentCone, is a separate runtime part over this.)

Stage 0 (tiers 0-2): the mound, nine basalt columns, the lava pool and crust plates, a lava
                     run down the front, three smoke puffs, scattered rocks.
Stage 1 (tier 3):    a TALLER CONE - the mound rises into a steep volcano cone twice as high, the
                     basalt ring (taller columns) on its crater rim, two lava runs down its
                     slopes, obsidian shards, a hunters' pressure valve, a bigger plume.
Stage 2 (tier 5):    taller still and ERUPTING - glowing lava fountains bursting up from the
                     rim, four glowing lava rivers and the pool, glowing column tips round the
                     rim (the crown), a brass collar round the cone and a brass valve rig.
                     The crater's middle stays open (the Fire Mountain cone covers it).
"""

import importlib.util
import math
from pathlib import Path

_spec = importlib.util.spec_from_file_location("_kit", Path(__file__).with_name("_kit.py"))
K = importlib.util.module_from_spec(_spec)
_spec.loader.exec_module(K)

BASALT = (75, 60, 55)  # TowerLook.COLORS.VENT
ASH = (112, 90, 74)
CRUST = (44, 36, 34)
LAVA = (192, 76, 30)  # cooling lava (stage 2 lights it)
SMOKE = (150, 145, 140)
OBSIDIAN = (30, 28, 36)
GLOW = (255, 140, 40)  # TowerLook VENT lava

MOUND_H = 0.62


def build(lp, stage):
    k = K.Kit(lp)
    hot = stage >= 2
    lean = stage >= 1
    lava_group = "glow" if hot else "lava"
    MH = (MOUND_H, 1.25, 1.65)[stage]  # the cone's height: the upgrades raise it
    TOP = (0.66, 0.56, 0.5)[stage]  # its top radius / base radius
    RIM = 0.78 if stage == 0 else 1.42 * TOP - 0.06  # the column ring

    def slope(r):  # the cone surface's height at radius r
        return max(0.05, MH * (1 - r / 1.42) / (1 - TOP))

    # the mound
    k.add("ash", K.cyl((0, MH / 2, 0), 1.42, MH, 14, top=TOP, bevel=0.1))
    k.add("ash", *[K.ell((math.cos(a) * 1.25, 0.12, math.sin(a) * 1.25), (0.22, 0.14, 0.18), 7, 3, rot=(0, -math.degrees(a), 0))
                   for a in (math.radians(d) for d in (150, 200, 250, 290, 330))])  # rocks round the foot

    # the ring of hexagonal basalt columns (short in the back-right)
    cols, tops, tipy = [], [], []
    n = 9
    for i in range(n):
        a = 2 * math.pi * i / n + 0.15
        x, z = math.cos(a) * RIM, math.sin(a) * RIM
        if z < -0.55 * RIM / 0.78:
            continue  # a gap at the front where the lava spills out
        flag = x > 0.2 and z > 0.2  # toward the owner flag's corner
        h = (0.35 if flag else 0.5 + ((i * 7) % 4) * 0.14) + (0.25 if stage >= 1 and not flag else 0.0)
        y0 = MH - 0.12
        cols.append(K.cyl((x, y0 + h / 2, z), 0.21, h, 6, bevel=0 if lean else 0.03, rot=(0, (i * 23) % 60, 0)))
        tipy.append((x, y0 + h, z, flag))
        tops.append(K.cyl((x, y0 + h + 0.015, z), 0.17, 0.03, 6, bevel=0.0, rot=(0, (i * 23) % 60, 0)))
    k.add("body", *cols)
    k.add("crust", *tops)

    # the lava pool in the crater with crust plates on it
    k.add(lava_group, K.cyl((0, MH + 0.03, 0), RIM - 0.16, 0.1, 14, bevel=0 if lean else 0.03), piece="pool")
    k.add("crust", *[K.cyl((x, MH + 0.08, z), r, 0.04, 6, bevel=0.0, rot=(0, rr, 0)) for x, z, r, rr in
                     ((-0.22, 0.12, 0.2, 10), (0.24, -0.08, 0.17, 40), (0.06, 0.34, 0.14, 25), (-0.3, -0.25, 0.13, 5), (0.32, 0.3, 0.12, 50))])
    k.add(lava_group, *[K.ell((x, MH + 0.08, z), (r, r * 0.7, r), 8, 4) for x, z, r in ((0.02, -0.2, 0.1), (-0.05, 0.1, 0.07))],
          piece="blobs")

    # lava runs down the front of the mound
    run_parts = []
    if stage == 0:
        for x0, dx in [(-0.15, -0.12)]:
            a, b = (x0, MOUND_H + 0.04, -0.5), (x0 + dx * 0.3, MOUND_H + 0.03, -0.92)
            c, d = (x0 + dx * 0.65, 0.36, -1.18), (x0 + dx, 0.08, -1.4)
            run_parts += [K.bar(a, b, 0.26, 0.07, bevel=0.03), K.bar(b, c, 0.24, 0.07, bevel=0.03), K.bar(c, d, 0.22, 0.07, bevel=0.03),
                          K.ell(d, (0.2, 0.05, 0.08), 8, 3)]
    else:  # lava runs spilling over the rim and down the cone's slopes (front, front-left, and the right at stage 2)
        for ang, w in ((-95, 0.3), (-140, 0.24)) + (((-30, 0.24), (175, 0.22)) if hot else ()):
            ca, sa = math.cos(math.radians(ang)), math.sin(math.radians(ang))
            pts = []
            for i, r in enumerate((RIM - 0.2, RIM + 0.12, 0.95, 1.13, 1.28)):
                wig = 0.05 * (1 if i % 2 else -1)
                pts.append((ca * r - sa * wig, slope(r) + 0.05 if i else MH + 0.06, sa * r + ca * wig))
            nrm = (ca * MH, 1.42 * (1 - TOP), sa * MH)  # the slope's normal: the stream lies flat on it
            run_parts += [K.bar(K.along(pts[i], pts[i + 1], -0.12), K.along(pts[i], pts[i + 1], 1.12), w - 0.02 * i, 0.08, bevel=0,
                                up=nrm if i else (0, 1, 0)) for i in range(len(pts) - 1)]  # overlapping, so the run reads as one stream
            run_parts.append(K.ell((pts[-1][0], 0.07, pts[-1][2]), (0.14, 0.05, 0.18), 6, 3, rot=(0, -ang, 0)))
    k.add(lava_group, *run_parts, piece="runs")

    # the smoke plume
    puffs = [(0.0, 1.35, 0.0, 0.42), (0.22, 1.75, 0.1, 0.36), (-0.12, 2.1, 0.22, 0.34), (0.1, 2.45, 0.34, 0.27)]
    if stage >= 1:
        puffs += [(-0.05, 2.8, 0.45, 0.24), (-0.3, 1.6, -0.12, 0.28), (0.25, 3.1, 0.55, 0.22)]
    rise = MH - MOUND_H  # the plume rides on the taller cone
    k.add("smoke", *[K.ell((x, y + rise, z), (r, r * 0.85, r), 8 if lean else 10, 5 if lean else 6) for x, y, z, r in puffs
                       if y + rise + r * 0.85 < 4.95])

    brass = []
    if stage >= 1:
        # obsidian shards on the slopes
        k.add("obsidian", *[K.rod((x, slope(math.hypot(x, z)) - 0.05, z), (x * 1.08, slope(math.hypot(x, z)) + 0.4, z * 1.08), 0.09, 4, top=0.1)
                            for x, z in ((-1.1, -0.5), (-0.55, -1.05), (0.9, -0.8), (-1.15, 0.45))])
        # a hunters' pressure valve on the left slope: a pipe out of the cone, a wheel and a gauge
        vx, vz = -1.12, 0.05
        vy = slope(1.0)
        k.add("metal", K.rod((-0.9, vy, vz), (vx, vy, vz), 0.08, 6), K.rod((vx, slope(1.15) - 0.1, vz), (vx, vy + 0.75, vz), 0.08, 6),
              K.cyl((vx, vy + 0.8, vz), 0.12, 0.1, 8, bevel=0))
        k.add("brass" if hot else "metal", K.ring((vx - 0.15, vy + 0.5, vz), 0.18, 0.04, 10, 3, rot=(0, 0, 90)),
              K.rod((vx - 0.15, vy + 0.5, vz - 0.18), (vx - 0.15, vy + 0.5, vz + 0.18), 0.025, 4),
              K.rod((vx - 0.15, vy + 0.32, vz), (vx - 0.15, vy + 0.68, vz), 0.025, 4), piece="wheel")
        k.add("brass" if hot else "metal", K.cyl((vx, vy + 0.25, vz - 0.12), 0.11, 0.05, 10, rot=(90, 0, 0), bevel=0), piece="gauge")
        k.add("dial", K.cyl((vx, vy + 0.25, vz - 0.15), 0.08, 0.02, 10, rot=(90, 0, 0), bevel=0))

    if hot:
        # the crown: glowing tips on the rim's columns
        k.add("glow", *[K.cyl((x, y + 0.08, z), 0.19, 0.16, 6, bevel=0, top=0.6) for x, y, z, flag in tipy if not flag], piece="tips")
        # the eruption: fountains of lava bursting up out of the rim's gaps, blobs flung off their tops
        spurts = []
        for ang in (-90, 150, 30, -150):
            ca, sa = math.cos(math.radians(ang)), math.sin(math.radians(ang))
            base = (ca * (RIM - 0.05), MH, sa * (RIM - 0.05))
            tip = (ca * (RIM + 0.3), MH + 0.95, sa * (RIM + 0.3))
            spurts += [K.rod(base, tip, 0.2, 6, top=0.3), K.ell(K.along(base, tip, 1.15), (0.13, 0.15, 0.13), 6, 3),
                       K.ell((ca * (RIM + 0.5), MH + 0.95, sa * (RIM + 0.5)), (0.08, 0.08, 0.08), 5, 3)]
        k.add("glow", *spurts, piece="bombs")
        # a brass collar round the cone, brass bands on the valve pipe
        k.add("brass", K.ring((0, slope(1.3) - 0.02, 0), 1.3, 0.05, 14, 3),
              *[K.ring_along((vx, y, vz), (vx, y + 1, vz), 0.1, 0.03, 8, 3) for y in (vy + 0.1, vy + 0.62)])

    colors = {
        "body": BASALT, "ash": ASH, "crust": CRUST, "lava": LAVA, "smoke": SMOKE, "obsidian": OBSIDIAN,
        "metal": K.METAL, "dial": (232, 226, 200), "brass": K.BRASS, "glow": GLOW,
    }
    return k.model("11d", colors, "VENT", stage)
