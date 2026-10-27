"""VENT - Volcano Vent (TowerLook basalt; a 4x tower): a mound of ash and rock crowned with a ring
of hexagonal basalt columns round a crater of lava, crust plates floating on it, a lava run down
the front and a plume of smoke. Authored from the base (y 0) in Roblox studs; front = -Z (_kit
conventions). The columns in the back-right (the owner flag's corner) stay short.
(Fire Mountain's cone, setVentCone, is a separate runtime part over this.)

Stage 0 (tiers 0-2): the mound, nine basalt columns, the lava pool and crust plates, a lava
                     run down the front, three smoke puffs, scattered rocks.
Stage 1 (tier 3):    taller columns, a second lava run, obsidian shards, a hunters' pressure
                     valve (pipe, wheel, gauge) bolted to a column, a bigger plume.
Stage 2 (tier 5):    brass valve wheel, gauge and pipe bands, the lava glowing, embers in the
                     smoke.
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
    lava_group = "glow" if hot else "lava"

    # the mound
    k.add("ash", K.cyl((0, MOUND_H / 2, 0), 1.42, MOUND_H, 14, top=0.66, bevel=0.1))
    k.add("ash", *[K.ell((math.cos(a) * 1.25, 0.12, math.sin(a) * 1.25), (0.22, 0.14, 0.18), 7, 3, rot=(0, -math.degrees(a), 0))
                   for a in (math.radians(d) for d in (150, 200, 250, 290, 330))])  # rocks round the foot

    # the ring of hexagonal basalt columns (short in the back-right)
    cols, tops = [], []
    n = 9
    for i in range(n):
        a = 2 * math.pi * i / n + 0.15
        x, z = math.cos(a) * 0.78, math.sin(a) * 0.78
        if z < -0.55:
            continue  # a gap at the front where the lava spills out
        flag = x > 0.2 and z > 0.2  # toward the owner flag's corner
        h = (0.35 if flag else 0.5 + ((i * 7) % 4) * 0.14) + (0.25 if stage >= 1 and not flag else 0.0)
        y0 = MOUND_H - 0.12
        cols.append(K.cyl((x, y0 + h / 2, z), 0.21, h, 6, bevel=0.03, rot=(0, (i * 23) % 60, 0)))
        tops.append(K.cyl((x, y0 + h + 0.015, z), 0.17, 0.03, 6, bevel=0.0, rot=(0, (i * 23) % 60, 0)))
    k.add("body", *cols)
    k.add("crust", *tops)

    # the lava pool in the crater with crust plates on it
    k.add(lava_group, K.cyl((0, MOUND_H + 0.03, 0), 0.62, 0.1, 14, bevel=0.03), piece="pool")
    k.add("crust", *[K.cyl((x, MOUND_H + 0.08, z), r, 0.04, 6, bevel=0.0, rot=(0, rr, 0)) for x, z, r, rr in
                     ((-0.22, 0.12, 0.2, 10), (0.24, -0.08, 0.17, 40), (0.06, 0.34, 0.14, 25), (-0.3, -0.25, 0.13, 5), (0.32, 0.3, 0.12, 50))])
    k.add(lava_group, *[K.ell((x, MOUND_H + 0.08, z), (r, r * 0.7, r), 8, 4) for x, z, r in ((0.02, -0.2, 0.1), (-0.05, 0.1, 0.07))],
          piece="blobs")

    # lava runs down the front of the mound
    runs = [(-0.15, -0.12)] + ([(0.35, 0.25)] if stage >= 1 else [])
    run_parts = []
    for x0, dx in runs:
        a, b = (x0, MOUND_H + 0.04, -0.5), (x0 + dx * 0.3, MOUND_H + 0.03, -0.92)
        c, d = (x0 + dx * 0.65, 0.36, -1.18), (x0 + dx, 0.08, -1.4)
        run_parts += [K.bar(a, b, 0.26, 0.07, bevel=0.03), K.bar(b, c, 0.24, 0.07, bevel=0.03), K.bar(c, d, 0.22, 0.07, bevel=0.03),
                      K.ell(d, (0.2, 0.05, 0.08), 8, 3)]
    k.add(lava_group, *run_parts, piece="runs")

    # the smoke plume
    puffs = [(0.0, 1.35, 0.0, 0.42), (0.22, 1.75, 0.1, 0.36), (-0.12, 2.1, 0.22, 0.34), (0.1, 2.45, 0.34, 0.27)]
    if stage >= 1:
        puffs += [(-0.05, 2.8, 0.45, 0.24), (-0.3, 1.6, -0.12, 0.28)]
    k.add("smoke", *[K.ell((x, y, z), (r, r * 0.85, r), 10, 6) for x, y, z, r in puffs])

    brass = []
    if stage >= 1:
        # obsidian shards on the mound
        k.add("obsidian", *[K.rod((x, 0.12, z), (x * 1.08, 0.48, z * 1.08), 0.08, 4, top=0.1) for x, z in ((-1.15, -0.55), (-0.65, -1.1), (0.95, -0.85))])
        # a pressure valve on the left column: a pipe out of the mound, a wheel and a gauge
        vx, vz = -1.05, 0.15
        pipe = [K.rod((-0.55, 0.45, vz), (vx, 0.45, vz), 0.08, 8), K.rod((vx, 0.45, vz), (vx, 1.15, vz), 0.08, 8)]
        k.add("metal", *pipe, K.cyl((vx, 1.2, vz), 0.12, 0.1, 8))
        k.add("brass" if hot else "metal", K.ring((vx - 0.15, 0.95, vz), 0.16, 0.035, 10, 3, rot=(0, 0, 90)),
              K.rod((vx - 0.15, 0.95, vz - 0.16), (vx - 0.15, 0.95, vz + 0.16), 0.02, 4),
              K.rod((vx - 0.15, 0.79, vz), (vx - 0.15, 1.11, vz), 0.02, 4), piece="wheel")
        k.add("metal", K.rod((vx, 0.95, vz), (vx - 0.15, 0.95, vz), 0.03, 4))
        k.add("brass" if hot else "metal", K.cyl((vx, 0.7, vz - 0.12), 0.11, 0.05, 10, rot=(90, 0, 0)), piece="gauge")
        k.add("dial", K.cyl((vx, 0.7, vz - 0.15), 0.08, 0.02, 10, rot=(90, 0, 0)))

    if hot:
        brass += [K.ring_along((vx, y, vz), (vx, y + 1, vz), 0.09, 0.025, 8, 3) for y in (0.6, 1.05)]
        k.add("glow", *[K.ell((x, y, z), (0.05, 0.05, 0.05), 6, 4) for x, y, z in ((0.3, 1.6, -0.2), (-0.3, 2.0, 0.25), (0.25, 2.7, -0.15), (-0.2, 3.1, 0.3))],
              piece="embers")
        k.add("brass", *brass)

    colors = {
        "body": BASALT, "ash": ASH, "crust": CRUST, "lava": LAVA, "smoke": SMOKE, "obsidian": OBSIDIAN,
        "metal": K.METAL, "dial": (232, 226, 200), "brass": K.BRASS, "glow": GLOW,
    }
    return k.model("11d", colors, "VENT", stage)
