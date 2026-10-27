"""HOSPITAL - Field Hospital (TowerLook canvas white): a white canvas A-frame tent on a
groundsheet with a green "+" on each side (green, never a red cross: DINO_REVIEW R2), an
open front door with the flaps tied back, poles and guy ropes. It doesn't shoot: no muzzle
piece. The Rescue Beacon (TowerLook.setLantern) stands at the front-right corner (x 1.25,
z -1.25), so that corner stays clear. Authored from the base (y 0) in Roblox studs; front = -Z.

The green crosses are paint group `glow` (Neon in game, like today's). TowerLook.pulseCross
finds parts named Cross*; art parts are named Art_<group>, so the runtime task must point it
at Art_glow (noted in the report).

Stage 0 (tiers 0-2): tent, groundsheet, crosses, poles, guy ropes and pegs.
Stage 1 (tier 3):    a canvas fly awning on two poles over the door, a stretcher leaning on
                     the left side, a medical crate with a green cross, a water barrel.
Stage 2 (tier 5):    brass ridge finials, a brass-cornered medical chest, rolled bandages,
                     a lantern with a green glow hanging at the door.
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
ANGLE = math.degrees(math.atan2(EAVE_X, RIDGE_Y - EAVE_Y))


def panel_point(sx, t, z, out=0.0):
    """A point on the sloped side sx (-1 left / 1 right), t 0 at the ridge .. 1 at the eave,
    pushed `out` along the panel's outward normal."""
    x = sx * (0.04 + (EAVE_X - 0.04) * t)
    y = RIDGE_Y + (EAVE_Y - RIDGE_Y) * t
    nx, ny = math.cos(math.radians(ANGLE)), math.sin(math.radians(ANGLE))
    return (x + sx * nx * out, y + ny * out, z)


def build(lp, stage):
    k = K.Kit(lp)
    zc = 0.0 if stage == 0 else 0.12  # stage 1+: the tent sits back to make room for the fly

    k.add("sheet", K.rbox((0, 0.03, zc), (2.9, 0.06, 2.6), bevel=0.02))
    # the two sloped canvas sides and the back wall
    panels = [K.bar(panel_point(sx, 0, zc, 0.04), panel_point(sx, 1, zc, 0.04), 2 * HALF_L + 0.1, 0.07, bevel=0.03) for sx in (-1, 1)]
    panels.append(K.rbox((0, (RIDGE_Y + 0.06) / 2, zc + HALF_L), (2 * EAVE_X + 0.06, RIDGE_Y + 0.06, 0.06), bevel=0.02, taper=(0.04, 1.0)))
    # the front gable wall (the door is cut in it below)
    panels.append(K.rbox((0, (RIDGE_Y + 0.06) / 2, zc - HALF_L), (2 * EAVE_X + 0.06, RIDGE_Y + 0.06, 0.06), bevel=0.02, taper=(0.04, 1.0)))
    k.add("body", *panels)
    # the door: a dark opening proud of the gable, the flaps rolled and tied back along its edges
    k.add("dark", K.rbox((0, 0.86, zc - HALF_L - 0.04), (1.3, 1.62, 0.04), bevel=0.01, taper=(0.14, 1.0)))
    k.add("canvas2", *[K.rod((sx * 0.68, 0.1, zc - HALF_L - 0.08), (sx * 0.12, 1.72, zc - HALF_L - 0.08), 0.07, 8) for sx in (-1, 1)])

    # green crosses on both sides
    crosses = []
    for sx in (-1, 1):
        c = panel_point(sx, 0.5, zc, 0.09)
        rot = (0, 0, ANGLE * sx)
        crosses += [K.rbox(c, (0.05, 1.0, 0.32), bevel=0.02, rot=rot), K.rbox(c, (0.05, 0.32, 1.0), bevel=0.02, rot=rot)]
    k.add("glow", *crosses)

    # ridge pole, upright poles at both ends, guy ropes to pegs (not at the beacon's corner)
    wood = [K.rod((0, RIDGE_Y + 0.05, zc - HALF_L - 0.12), (0, RIDGE_Y + 0.05, zc + HALF_L + 0.12), 0.06, 8)]
    wood += [K.rod((0, 0, zc + sz * (HALF_L + 0.1)), (0, RIDGE_Y + 0.1, zc + sz * (HALF_L + 0.1)), 0.06, 8) for sz in (-1, 1)]
    ropes, pegs = [], []
    for sx, sz in ((-1, -1), (-1, 1), (1, 1)):
        top = (sx * 0.9, 0.9, zc + sz * (HALF_L - 0.1))
        peg = (sx * 1.38, 0.12, zc + sz * (HALF_L - 0.1) if sz > 0 else -1.38)
        ropes.append(K.rod(top, peg, 0.02, 4))
        pegs.append(K.rod((peg[0], 0.0, peg[2]), (peg[0], 0.2, peg[2]), 0.04, 5))
    k.add("wood", *wood, *pegs)
    k.add("rope", *ropes)

    brass = []
    if stage >= 1:
        # a canvas fly over the door on two poles
        fz = zc - HALF_L
        k.add("body", K.bar((0, RIDGE_Y - 0.25, fz + 0.05), (0, 1.75, -1.42), 1.9, 0.06, bevel=0.025))
        k.add("wood", *[K.rod((sx * 0.85, 0, -1.4), (sx * 0.85, 1.75, -1.4), 0.04, 6) for sx in (-1, 1)])
        # a stretcher leaning on the left side
        a, b = (-1.42, 0.05, -0.4 + zc), (-0.97, 0.98, -0.4 + zc)  # its top rests on the tent side
        k.add("wood", *[K.rod((a[0], a[1], a[2] + dz), (b[0], b[1], b[2] + dz), 0.035, 6) for dz in (-0.25, 0.25)])
        k.add("drab", K.bar(K.along(a, b, 0.15), K.along(a, b, 0.85), 0.48, 0.03, bevel=0.01, up=(-0.9, 0.45, 0)))
        # a medical crate at the back-left with a green cross, a water barrel beside it
        core, frame = K.crate((-0.95, 0.27, 1.12), (0.6, 0.54, 0.5), 0)
        k.add("wood", core)
        k.add("dark", *frame)
        k.add("glow", K.rbox((-0.95, 0.3, 0.86), (0.08, 0.3, 0.03), bevel=0.01), K.rbox((-0.95, 0.3, 0.86), (0.3, 0.08, 0.03), bevel=0.01))
        k.add("wood", K.cyl((1.05, 0.35, -0.2), 0.27, 0.7, 12, top=0.9, bevel=0.04))
        k.add("metal", *[K.ring((1.05, y, -0.2), 0.27, 0.025, 12, 4) for y in (0.15, 0.55)])

    if stage >= 2:
        # brass finials on the ridge ends
        brass += [K.ell((0, RIDGE_Y + 0.14, zc + sz * (HALF_L + 0.02)), (0.1, 0.1, 0.1), 8, 5) for sz in (-1, 1)]
        # a brass-cornered medical chest in front of the left door wall, bandage rolls on it
        ch = (-0.6, 0.2, -1.3)
        k.add("body", K.rbox(ch, (0.6, 0.4, 0.34), bevel=0.05))
        brass += [K.rbox((ch[0] + sx * 0.27, ch[1], ch[2] + sz * 0.14), (0.07, 0.42, 0.07), bevel=0.02) for sx in (-1, 1) for sz in (-1, 1)]
        k.add("canvas2", *[K.rod((ch[0] + dx, 0.48, ch[2] - 0.08), (ch[0] + dx, 0.48, ch[2] + 0.08), 0.08, 8) for dx in (-0.14, 0.12)])
        # a lantern hanging from the fly at the door, glowing green
        lx, lz = 0.0, -1.2
        brass += [K.cyl((lx, 1.72, lz), 0.1, 0.06, 8), K.rod((lx, 1.75, lz), (lx, 2.1, lz), 0.015, 5)]
        k.add("glow", K.ell((lx, 1.56, lz), (0.11, 0.14, 0.11), 8, 5), piece="lantern")
    if brass:
        k.add("brass", *brass)

    colors = {
        "body": CANVAS, "sheet": SHEET, "dark": (52, 46, 40), "canvas2": (214, 206, 186), "drab": (112, 116, 78), "glow": GREEN,
        "wood": K.WOOD, "rope": K.ROPE, "metal": K.METAL, "brass": K.BRASS,
    }
    return k.model("11d", colors, "HOSPITAL", stage)
