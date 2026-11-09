"""HOSPITAL - Field Hospital (TowerLook canvas white): a white canvas A-frame tent on a
groundsheet with a green "+" on each side (green, never a red cross: DINO_REVIEW R2), an
open front door with the flaps tied back, poles and guy ropes. It doesn't shoot: no muzzle
piece. The Rescue Beacon (TowerLook.setLantern) stands at the front-right corner (x 1.25,
z -1.25), so that corner stays clear. Authored from the base (y 0) in Roblox studs; front = -Z.

The green crosses are paint group `glow` (Neon in game, like today's). TowerLook.pulseCross
finds parts named Cross*; art parts are named Art_<group>, so the runtime task must point it
at Art_glow (noted in the report).

Stage 0 (tiers 0-2): tent, groundsheet, crosses, poles, guy ropes and pegs.
Stage 1 (tier 3):    a bigger wall tent (upright side walls, a higher ridge, a taller door),
                     a canvas fly on two poles over the door, a tall flagpole at the back-left
                     flying a green-cross flag, a medical crate.
Stage 2 (tier 5):    a raised vent roof on the ridge crowned by a big glowing green cross in a
                     brass frame, brass finials, a lantern with a green glow at the door.
"""

import importlib.util
import math
from pathlib import Path

_spec = importlib.util.spec_from_file_location("_kit", Path(__file__).with_name("_kit.py"))
K = importlib.util.module_from_spec(_spec)
_spec.loader.exec_module(K)

CANVAS = (235, 232, 220)  # TowerLook.COLORS.HOSPITAL
GREEN = (60, 190, 90)
SHEET = (120, 110, 90)

RIDGE_Y, EAVE_X, EAVE_Y, HALF_L = 2.55, 1.32, 0.12, 1.22  # tent: ridge height, eave x / y, half length (z)
# stage 1+: a bigger wall tent - upright side walls, a higher ridge, shorter so both corners
# (owner flag back-right, Rescue Beacon front-right) stay clear
WALL_RIDGE, WALL_EAVE, WALL_HALF_L = 3.15, 0.8, 0.98


def panel_point(sx, t, z, out=0.0, ridge=RIDGE_Y, eave=EAVE_Y):
    """A point on the sloped side sx (-1 left / 1 right), t 0 at the ridge .. 1 at the eave,
    pushed `out` along the panel's outward normal."""
    angle = math.atan2(EAVE_X, ridge - eave)
    x = sx * (0.04 + (EAVE_X - 0.04) * t)
    y = ridge + (eave - ridge) * t
    return (x + sx * math.cos(angle) * out, y + math.sin(angle) * out, z)


def build(lp, stage):
    k = K.Kit(lp)
    if stage == 0:
        ry, ey, hl, zc = RIDGE_Y, EAVE_Y, HALF_L, 0.0
    else:
        ry, ey, hl, zc = WALL_RIDGE, WALL_EAVE, WALL_HALF_L, 0.0
    angle = math.degrees(math.atan2(EAVE_X, ry - ey))

    k.add("sheet", K.rbox((0, 0.03, zc), (2.9, 0.06, 2.6 if stage == 0 else 2.2), bevel=0.02))
    # the two sloped canvas sides, the back and front gable walls (the door is cut in the front)
    panels = [K.bar(panel_point(sx, 0, zc, 0.04, ry, ey), panel_point(sx, 1, zc, 0.04, ry, ey), 2 * hl + 0.1, 0.07, bevel=0.03) for sx in (-1, 1)]
    for sz in (-1, 1):
        if stage == 0:
            panels.append(K.rbox((0, (ry + 0.06) / 2, zc + sz * hl), (2 * EAVE_X + 0.06, ry + 0.06, 0.06), bevel=0.02, taper=(0.04, 1.0)))
        else:
            panels.append(K.rbox((0, ey / 2, zc + sz * hl), (2 * EAVE_X, ey, 0.06), bevel=0.02))
            panels.append(K.rbox((0, ey + (ry - ey) / 2, zc + sz * hl), (2 * EAVE_X + 0.06, ry - ey + 0.04, 0.06), bevel=0.02, taper=(0.04, 1.0)))
    if stage >= 1:  # upright side walls under the eaves
        panels += [K.rbox((sx * (EAVE_X - 0.02), ey / 2, zc), (0.06, ey, 2 * hl), bevel=0.02) for sx in (-1, 1)]
    k.add("body", *panels)
    # the door: a dark opening proud of the gable, the flaps rolled and tied back along its edges
    dh = 1.62 if stage == 0 else 2.0
    k.add("dark", K.rbox((0, dh / 2 + 0.05, zc - hl - 0.04), (1.3, dh, 0.04), bevel=0.01, taper=(0.14 if stage == 0 else 0.5, 1.0)))
    k.add("canvas2", *[K.rod((sx * 0.68, 0.1, zc - hl - 0.08), (sx * (0.12 if stage == 0 else 0.3), dh + 0.1, zc - hl - 0.08), 0.07, 8) for sx in (-1, 1)])

    # green crosses on both sides
    crosses = []
    cs = 1.0 if stage == 0 else 1.15
    for sx in (-1, 1):
        c = panel_point(sx, 0.5, zc, 0.09, ry, ey)
        rot = (0, 0, angle * sx)
        crosses += [K.rbox(c, (0.05, cs, 0.34), bevel=0.02, rot=rot), K.rbox(c, (0.05, 0.34, cs), bevel=0.02, rot=rot)]
    k.add("glow", *crosses)

    # ridge pole, upright poles at both ends, guy ropes to pegs (not at the beacon's corner)
    wood = [K.rod((0, ry + 0.05, zc - hl - 0.12), (0, ry + 0.05, zc + hl + 0.12), 0.06, 8)]
    wood += [K.rod((0, 0, zc + sz * (hl + 0.1)), (0, ry + 0.1, zc + sz * (hl + 0.1)), 0.06, 8) for sz in (-1, 1)]
    ropes, pegs = [], []
    for sx, sz in ((-1, -1), (-1, 1), (1, 1)):
        if stage == 0:
            top = (sx * 0.9, 0.9, zc + sz * (hl - 0.1))
            peg = (sx * 1.38, 0.12, zc + sz * (hl - 0.1) if sz > 0 else -1.38)
        else:
            if sx > 0 and sz > 0:
                continue  # the owner flag's corner
            top = (sx * 1.3, ey, zc + sz * (hl - 0.1))
            peg = (sx * 1.42, 0.12, sz * 1.4)
        ropes.append(K.rod(top, peg, 0.02, 4))
        pegs.append(K.rod((peg[0], 0.0, peg[2]), (peg[0], 0.2, peg[2]), 0.04, 5))
    k.add("wood", *wood, *pegs)
    k.add("rope", *ropes)

    brass = []
    if stage >= 1:
        # a canvas fly over the door on two poles
        fz = zc - hl
        k.add("body", K.bar((0, 2.35, fz + 0.05), (0, 1.95, -1.42), 2.0, 0.06, bevel=0.025))
        k.add("wood", *[K.rod((sx * 0.9, 0, -1.4), (sx * 0.9, 1.95, -1.4), 0.045, 6) for sx in (-1, 1)])
        # a tall flagpole at the back-left flying a white flag with a green cross
        fx, fzp = -1.32, 1.3
        top = 4.35 if stage == 1 else 4.15
        k.add("wood", K.rod((fx, 0, fzp), (fx, top, fzp), 0.06, 6))
        fy = top - 0.42
        k.add("canvas2", K.rbox((fx + 0.55, fy, fzp), (1.0, 0.66, 0.04), bevel=0.0))
        k.add("glow", K.rbox((fx + 0.55, fy, fzp - 0.03), (0.42, 0.13, 0.03), bevel=0.0),
              K.rbox((fx + 0.55, fy, fzp - 0.03), (0.13, 0.42, 0.03), bevel=0.0))
        # a medical crate with a green cross by the door's left
        core, frame = K.crate((-0.95, 0.27, -1.2), (0.55, 0.5, 0.45), 0)
        k.add("wood", core)
        k.add("dark", *frame)
        k.add("glow", K.rbox((-0.95, 0.3, -1.44), (0.08, 0.3, 0.03), bevel=0.0), K.rbox((-0.95, 0.3, -1.44), (0.3, 0.08, 0.03), bevel=0.0))
        if stage >= 2:
            brass.append(K.ell((fx, top + 0.08, fzp), (0.1, 0.1, 0.1), 8, 5))

    if stage >= 2:
        # a raised vent roof on the ridge and, standing on it, a big glowing green cross in a
        # brass frame - the crown
        k.add("canvas2", K.rbox((0, ry + 0.17, zc), (0.95, 0.34, 1.4), bevel=0.06, taper=(0.5, 1.0)))
        cy = ry + 0.34
        brass += [K.rbox((0, cy + 0.03, zc), (1.05, 0.06, 0.3), bevel=0.0)]
        k.add("glow", K.rbox((0, cy + 0.65, zc), (1.1, 0.36, 0.14), bevel=0.04),
              K.rbox((0, cy + 0.65, zc), (0.36, 1.2, 0.14), bevel=0.04), piece="beacon")
        brass += [K.rbox((0, cy + 0.65, zc), (1.24, 0.5, 0.1), bevel=0.04), K.rbox((0, cy + 0.65, zc), (0.5, 1.32, 0.1), bevel=0.04)]
        # brass finials on the ridge ends, brass caps on the fly poles
        brass += [K.ell((0, ry + 0.14, zc + sz * (hl + 0.1)), (0.11, 0.11, 0.11), 8, 5) for sz in (-1, 1)]
        brass += [K.ell((sx * 0.9, 2.0, -1.4), (0.08, 0.08, 0.08), 6, 4) for sx in (-1, 1)]
        # a lantern hanging from the fly at the door, glowing green
        lx, lz = 0.0, -1.25
        brass += [K.cyl((lx, 1.62, lz), 0.11, 0.06, 8), K.rod((lx, 1.65, lz), (lx, 1.98, lz), 0.015, 5)]
        k.add("glow", K.ell((lx, 1.45, lz), (0.13, 0.16, 0.13), 8, 5), piece="lantern")
    if brass:
        k.add("brass", *brass)

    colors = {
        "body": CANVAS, "sheet": SHEET, "dark": (52, 46, 40), "canvas2": (214, 206, 186), "drab": (112, 116, 78), "glow": GREEN,
        "wood": K.WOOD, "rope": K.ROPE, "metal": K.METAL, "brass": K.BRASS,
    }
    return k.model("11d", colors, "HOSPITAL", stage)
