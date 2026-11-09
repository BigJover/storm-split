"""RANGER - Ranger Station (TowerLook ranger khaki; a 4x tower): a log cabin with a khaki gable
roof, a porch, a stone chimney, a lookout platform on stilts at the front-right and a flagpole
at the front-left. The rangers (RangerLook: ranger / heavy / legend, the Patrol Jeep) and the
Paratroopers (TowerLook.buildRanger) are walkers built by Server/Towers, not part of this
model. Authored from the base (y 0) in Roblox studs; front = -Z (_kit conventions). The back-
right corner (the owner flag's) is kept clear: the cabin stops at x 0.8.

Stage 0 (tiers 0-2): the cabin (log walls, door, shuttered window, sign board), the gable
                     roof, the porch and step, the chimney, the lookout with its ladder and
                     roof, the flagpole and khaki pennant.
Stage 1 (tier 3):    a TWO-STOREY LODGE - a board-and-batten upper storey on the log cabin with
                     windows and a little front balcony, the gable roof raised on top, a
                     taller chimney, a radio aerial, a spotting scope on the lookout.
Stage 2 (tier 5):    the lookout rises a storey higher with a glowing searchlight and a brass
                     bell, a brass ridge cap, a great pair of antlers on the upper storey's front with a brass weather vane
                     on the ridge (the crown), a taller flagpole with a bigger pennant and a
                     brass finial, glowing windows, a brass porch lamp.
"""

import importlib.util
import math
from pathlib import Path

_spec = importlib.util.spec_from_file_location("_kit", Path(__file__).with_name("_kit.py"))
K = importlib.util.module_from_spec(_spec)
_spec.loader.exec_module(K)

KHAKI = (176, 160, 110)  # TowerLook.COLORS.RANGER
LOG = (126, 90, 56)
LOG_END = (176, 140, 96)
STONE = (120, 114, 104)
WINDOW = (44, 52, 60)
GLOW = (255, 206, 120)

CX0, CX1, CZ0, CZ1, WH = -1.22, 0.78, -0.35, 1.25, 1.35  # cabin walls, wall height
RIDGE = 2.2


def build(lp, stage):
    k = K.Kit(lp)
    hot = stage >= 2
    lean = stage >= 1
    wh = WH if stage == 0 else 2.5  # the walls: the lodge grows a second storey
    ridge = RIDGE if stage == 0 else 3.4
    cx, cz = (CX0 + CX1) / 2, (CZ0 + CZ1) / 2
    w, d = CX1 - CX0, CZ1 - CZ0

    # log walls: a core with horizontal logs on the front and sides, log ends at the corners
    k.add("wood", K.rbox((cx, WH / 2, cz), (w - 0.1, WH, d - 0.1), bevel=0.04 if not lean else 0))
    logs, ends = [], []
    for i in range(5):
        y = 0.14 + i * 0.27
        sg = 5 if lean else 6
        logs.append(K.rod((CX0 - 0.04, y, CZ0), (CX1 + 0.04, y, CZ0), 0.13, sg))  # front
        logs.append(K.rod((CX0, y, CZ0 - 0.04), (CX0, y, CZ1 + 0.04), 0.13, sg))  # left
        logs.append(K.rod((CX1, y, CZ0 - 0.04), (CX1, y, CZ1 + 0.04), 0.13, sg))  # right
        logs.append(K.rod((CX0 - 0.04, y, CZ1), (CX1 + 0.04, y, CZ1), 0.13, sg))  # back
    k.add("log", *logs)
    if lean:  # the upper storey: board-and-batten walls, corner posts, a log band at the floor line
        k.add("plank", K.rbox((cx, (WH + wh) / 2, cz), (w + 0.06, wh - WH, d + 0.06), bevel=0))
        k.add("log", *[K.rod((x, WH, z), (x, wh + 0.02, z), 0.09, 5) for x in (CX0 - 0.03, CX1 + 0.03) for z in (CZ0 - 0.03, CZ1 + 0.03)],
              K.rbox((cx, WH + 0.04, cz), (w + 0.26, 0.14, d + 0.26), bevel=0))
        k.add("dark", *[K.rbox((x, (WH + wh) / 2, CZ0 - 0.035), (0.04, wh - WH, 0.03), bevel=0) for x in (-0.95, -0.55, 0.15, 0.5)])  # battens
        k.add("glow" if hot else "window", *[K.rbox((x, WH + 0.6, CZ0 - 0.05), (0.36, 0.38, 0.05), bevel=0) for x in (-0.75, 0.33)],
              K.rbox((CX0 - 0.05, WH + 0.6, cz), (0.05, 0.38, 0.5), bevel=0), piece="windows2")
        # a little front balcony on the porch roof line
        k.add("plank", K.rbox((-0.22, WH + 0.1, CZ0 - 0.32), (1.0, 0.07, 0.5), bevel=0))
        k.add("wood", *[K.rod((-0.22 + sx * 0.48, WH + 0.1, CZ0 - 0.55), (-0.22 + sx * 0.48, WH + 0.5, CZ0 - 0.55), 0.025, 4) for sx in (-1, 1)],
              K.rod((-0.7, WH + 0.5, CZ0 - 0.55), (0.26, WH + 0.5, CZ0 - 0.55), 0.03, 4))
    # the gable roof (ridge along x), khaki canvas over battens, gable ends in planks
    half = d / 2 + 0.1
    pitch = math.atan2(ridge - wh, half)
    slab = math.hypot(ridge - wh, half) + 0.08
    for s in (-1, 1):
        k.add("body", K.rbox((cx, (wh + ridge) / 2 + 0.06, cz + s * half / 2), (w + 0.3, 0.1, slab), bevel=0.04,
                             rot=(s * math.degrees(pitch), 0, 0)))
    k.add("brass" if hot else "log", K.rod((CX0 - 0.15, ridge + 0.06, cz), (CX1 + 0.15, ridge + 0.06, cz), 0.07 if not hot else 0.1, 6))
    gable = []
    for x in (CX0, CX1):
        gable.append(K.rbox((x, (wh + ridge) / 2 - 0.08, cz), (0.08, ridge - wh - 0.05, d * 0.5), bevel=0.02, taper=(1.0, 0.15)))
    k.add("plank", *gable)

    # door, window with shutters, sign board over the door
    fz = CZ0 - 0.13
    k.add("dark", K.rbox((-0.15, 0.55, fz), (0.5, 1.0, 0.05), bevel=0.02))
    k.add("glow" if hot else "window", K.rbox((-0.95, 0.8, fz), (0.42, 0.36, 0.05), bevel=0.02),
          K.rbox((CX0 - 0.13, 0.8, cz + 0.3), (0.05, 0.36, 0.42), bevel=0.02), piece="windows")
    k.add("plank", *[K.rbox((-0.95 + sx * 0.3, 0.8, fz - 0.02), (0.16, 0.42, 0.04), bevel=0.01) for sx in (-1, 1)])
    k.add("sign", K.rbox((-0.15, 1.2, fz - 0.03), (0.7, 0.2, 0.04), bevel=0.02))
    k.add("dark", *[K.rbox((-0.15 + dx, 1.2, fz - 0.06), (0.06, 0.1, 0.01), bevel=0.0) for dx in (-0.22, -0.11, 0.0, 0.11, 0.22)])  # lettering

    # porch: plank deck at the front, two posts, a lean of roof, a step
    pz = CZ0 - 0.42
    k.add("plank", K.rbox((-0.3, 0.1, pz), (1.6, 0.1, 0.62), bevel=0.03), K.rbox((-0.15, 0.04, pz - 0.38), (0.6, 0.08, 0.2), bevel=0.02))
    k.add("log", *[K.rod((x, 0.15, pz - 0.24), (x, 1.2, pz - 0.24), 0.06, 6) for x in (-1.0, 0.4)])
    k.add("body", K.rbox((-0.3, 1.27, pz - 0.05), (1.7, 0.07, 0.75), bevel=0.03, rot=(-14, 0, 0)))

    # stone chimney at the back-left
    ch = 2.3 if stage == 0 else 3.55
    k.add("stone", K.rbox((CX0 + 0.3, ch / 2, CZ1 - 0.1), (0.42, ch, 0.42), bevel=0.06 if not lean else 0),
          K.rbox((CX0 + 0.3, ch + 0.05, CZ1 - 0.1), (0.5, 0.12, 0.5), bevel=0.04 if not lean else 0))

    # the lookout at the front-right: four legs, a deck, a rail, a little roof, a ladder
    lx, lz, ly = 1.0, -1.0, (2.35 if stage < 2 else 3.2)
    legs = [K.rod((lx + sx * 0.32, 0, lz + sz * 0.32), (lx + sx * 0.24, ly, lz + sz * 0.24), 0.06, 6) for sx in (-1, 1) for sz in (-1, 1)]
    legs += [K.rod((lx - 0.3, y, lz + sz * 0.28), (lx + 0.3, y, lz + sz * 0.28), 0.035, 4) for sz in (-1, 1) for y in ((1.1,) if stage < 2 else (1.1, 2.2))]
    k.add("log", *legs)
    k.add("plank", K.rbox((lx, ly, lz), (0.75, 0.08, 0.75), bevel=0.02))
    rail = [K.rod((lx + sx * 0.34, ly, lz + sz * 0.34), (lx + sx * 0.34, ly + 0.95, lz + sz * 0.34), 0.03, 4) for sx in (-1, 1) for sz in (-1, 1)]
    rail += [K.rod((lx - 0.34, ly + 0.42, lz + sz * 0.34), (lx + 0.34, ly + 0.42, lz + sz * 0.34), 0.025, 4) for sz in (-1, 1)]
    rail += [K.rod((lx + sx * 0.34, ly + 0.42, lz - 0.34), (lx + sx * 0.34, ly + 0.42, lz + 0.34), 0.025, 4) for sx in (-1, 1)]
    k.add("wood", *rail)
    k.add("body", K.rbox((lx, ly + 1.12, lz), (0.9, 0.35, 0.9), bevel=0.04, taper=(0.1, 0.1)))
    ladder = [K.rod((lx - 0.15 + dx, 0, lz - 0.47), (lx - 0.15 + dx, ly, lz - 0.32), 0.025, 4) for dx in (-0.12, 0.12)]
    ladder += [K.rod((lx - 0.27, y, lz - 0.47 + 0.15 * y / ly), (lx - 0.03, y, lz - 0.47 + 0.15 * y / ly), 0.02, 4)
               for y in ((0.4, 0.8, 1.2, 1.6, 2.0) if stage < 2 else (0.4, 0.9, 1.4, 1.9, 2.4, 2.9))]
    k.add("wood", *ladder)

    # flagpole at the front-left with a khaki pennant
    fx, fzz = -1.22, -1.15
    fh, fs = (3.2, 1.0) if stage < 2 else (4.35, 1.6)  # flagpole height, pennant scale
    k.add("metal", K.rod((fx, 0, fzz), (fx, fh, fzz), 0.035 if stage < 2 else 0.05, 6))
    k.add("brass" if hot else "metal", K.ell((fx, fh + 0.02, fzz), (0.05 * fs, 0.05 * fs, 0.05 * fs), 6, 4))
    k.add("body", K.rbox((fx + 0.03 + 0.3 * fs, fh - 0.25 * fs, fzz), (0.6 * fs, 0.36 * fs, 0.03), bevel=0.01))
    k.add("log", K.rbox((fx + 0.03 + 0.3 * fs, fh - 0.25 * fs, fzz - 0.02), (0.18 * fs, 0.18 * fs, 0.01), bevel=0.0, rot=(0, 0, 45)))  # a pine-brown diamond

    brass = []
    if stage >= 1:
        # a radio aerial on the roof
        k.add("metal", K.rod((CX1 - 0.25, ridge, cz), (CX1 - 0.25, ridge + 0.9, cz), 0.02, 4),
              *[K.rod((CX1 - 0.4, ridge + y, cz), (CX1 - 0.1, ridge + y, cz), 0.015, 4) for y in (0.55, 0.8)])
        # a spotting scope on the lookout rail
        k.add("metal", K.rod((lx - 0.1, ly + 0.52, lz - 0.2), (lx - 0.1, ly + 0.62, lz - 0.42), 0.06, 8))

    if hot:
        # a glowing searchlight on the raised lookout, a brass bell under its roof
        k.add("metal", K.rod((lx + 0.15, ly, lz + 0.1), (lx + 0.15, ly + 0.35, lz + 0.1), 0.04, 4),
              K.rod((lx + 0.15, ly + 0.45, lz + 0.18), (lx + 0.15, ly + 0.55, lz - 0.15), 0.17, 8, top=1.2))
        k.add("glow", K.cyl((lx + 0.15, ly + 0.555, lz - 0.17), 0.19, 0.04, 8, rot=(-75, 0, 0), bevel=0), piece="lamp")
        brass += [K.rod((lx, ly + 0.95, lz), (lx, ly + 0.82, lz), 0.015, 4), K.cyl((lx, ly + 0.72, lz), (0.12, 0.12), 0.18, 8, top=0.5, bevel=0)]
        # the crown: great antlers on the upper storey's front, a brass weather vane on the ridge
        ax, ay, az = -0.22, wh - 0.05, CZ0 - 0.1  # over the balcony, on the upper storey's front wall
        ant = [K.ell((ax, ay, az), (0.13, 0.1, 0.08), 6, 3)]
        for sx in (-1, 1):
            base = (ax + sx * 0.1, ay + 0.04, az - 0.04)
            beam = (ax + sx * 0.66, ay + 0.62, az - 0.22)
            ant.append(K.rod(base, beam, 0.06, 5, top=0.6))
            for t, up, out in ((0.35, 0.32, 0.04), (0.65, 0.36, 0.1), (1.0, 0.3, 0.18)):
                pt = K.along(base, beam, t)
                ant.append(K.rod(pt, (pt[0] + sx * out, pt[1] + up, pt[2] - 0.05), 0.038, 4, top=0.3))
        k.add("antler", *ant)
        vx = cx + 0.4
        brass += [K.rod((vx, ridge + 0.1, cz), (vx, ridge + 0.8, cz), 0.03, 4),
                  K.rod((vx - 0.3, ridge + 0.6, cz), (vx + 0.3, ridge + 0.6, cz), 0.025, 4),
                  K.rbox((vx + 0.33, ridge + 0.6, cz), (0.16, 0.16, 0.03), bevel=0, taper=(0.2, 1.0)),
                  K.ell((vx, ridge + 0.82, cz), (0.06, 0.06, 0.06), 6, 3)]
        # a brass porch lamp, glowing
        brass += [K.rod((-1.0, 1.1, pz - 0.24), (-1.0, 1.1, pz - 0.4), 0.02, 4), K.cyl((-1.0, 1.04, pz - 0.42), 0.08, 0.04, 8, bevel=0)]
        k.add("glow", K.ell((-1.0, 0.92, pz - 0.42), (0.08, 0.1, 0.08), 6, 4), piece="porchlamp")
        k.add("brass", *brass)

    colors = {
        "body": KHAKI, "wood": K.WOOD, "log": LOG, "plank": (150, 112, 72), "firewood": LOG_END, "dark": K.DARK,
        "window": WINDOW, "sign": K.SAND, "stone": STONE, "antler": (226, 214, 186), "metal": K.METAL, "brass": K.BRASS, "glow": GLOW,
    }
    return k.model("11d", colors, "RANGER", stage)
