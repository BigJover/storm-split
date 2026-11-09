"""QUARTERMASTER - Supply Camp (TowerLook supply-crate orange): stacked framed crates under an
orange tarp roped down, a barrel, and an orange pennant on a pole at the front-left (the
owner flag keeps the back-right corner). It doesn't shoot: no muzzle piece. Authored from the
base (y 0) in Roblox studs; front = -Z (_kit conventions).

Stage 0 (tiers 0-2): three crates (two on the ground, one stacked), the tarp, a barrel, pennant.
Stage 1 (tier 3):    the stacks grow - a tower of three crates on a pallet under a bigger tarp,
                     a second crate on the front one, a fourth crate, grain sacks.
Stage 2 (tier 5):    a derrick crane between the stacks, its boom swinging a brass-cornered
                     strongbox of glowing amber over the front, a glowing brass lantern on the
                     mast top (the crown), a pennant finial.
"""

import importlib.util
from pathlib import Path

_spec = importlib.util.spec_from_file_location("_kit", Path(__file__).with_name("_kit.py"))
K = importlib.util.module_from_spec(_spec)
_spec.loader.exec_module(K)

ORANGE = (230, 150, 50)  # TowerLook.COLORS.QUARTERMASTER
SACK = (196, 180, 140)
AMBER = (255, 170, 40)


def light_crate(centre, size, yaw=0.0):
    """A cheap crate (a plank core and two flat rims, ~60 triangles) for the bigger stacks."""
    sx, sy, sz = size
    core = K.rbox(centre, (sx * 0.96, sy * 0.96, sz * 0.96), bevel=0.04, rot=(0, yaw, 0))
    rims = [K.rbox((centre[0], centre[1] + dy * (sy / 2 - 0.05), centre[2]), (sx, 0.08, sz), bevel=0.0, rot=(0, yaw, 0)) for dy in (-1, 1)]
    return core, rims


def build(lp, stage):
    k = K.Kit(lp)
    lift = 0.14 if stage >= 1 else 0.0  # stage 1+: the stack stands on a pallet

    crates = [((-0.62, lift + 0.6, 0.5), (1.2, 1.2, 1.2), 4),  # A: the big one, back-left
              ((0.62, 0.5, -0.55), (1.0, 1.0, 1.0), -8),  # B: front-right
              ((-0.55, lift + 1.2 + 0.45, 0.45), (0.95, 0.9, 0.9), 12)]  # C: on top of A
    if stage == 1:
        crates.append(((0.7, 0.4, 0.45), (0.8, 0.8, 0.8), 20))  # D: a small one
    cores, frames = [], []
    for c, s, yaw in crates:
        core, frame = K.crate(c, s, yaw)
        cores.append(core)
        frames += frame
    stack_top = lift + 2.1
    if stage >= 1:
        # the stacks grow: a third crate on C (a tower of three), a second one on B
        for c, s, yaw in (((-0.58, stack_top + 0.4, 0.42), (0.8, 0.8, 0.8), -6), ((0.6, 1.0 + 0.36, -0.58), (0.78, 0.72, 0.72), 10)):
            core, rims = light_crate(c, s, yaw)
            cores.append(core)
            frames += rims
        stack_top += 0.8
    k.add("wood", *cores)
    k.add("dark", *frames)

    # the orange tarp over the stack: a top sheet and a flap hanging down the front
    top_y = stack_top + 0.06
    if stage == 0:
        k.add("body", K.rbox((-0.5, top_y, 0.42), (1.45, 0.08, 1.4), bevel=0.035, rot=(0, 12, 0)),
              K.bar((-0.5, top_y, -0.22), (-0.5, 1.0, -0.16), 1.35, 0.07, bevel=0.03))  # hangs on A's face
        k.add("rope", *[K.bar((x, top_y + 0.05, -0.28), (x + 0.08, top_y + 0.05, 1.08), 0.05, 0.04, bevel=0.015) for x in (-0.85, -0.2)])
    else:
        # a bigger tarp thrown over the tall stack, hanging down its front and left
        k.add("body", K.rbox((-0.58, top_y, 0.42), (1.2, 0.08, 1.15), bevel=0.035, rot=(0, -6, 0)),
              K.bar((-0.58, top_y, -0.16), (-0.58, lift + 1.35, -0.26), 1.2, 0.07, bevel=0.03),
              K.bar((-1.18, top_y, 0.42), (-1.32, lift + 1.4, 0.42), 1.15, 0.07, bevel=0.03, up=(1, 0, 0)))
        k.add("rope", *[K.bar((x, top_y + 0.05, -0.2), (x, top_y + 0.05, 1.02), 0.05, 0.04, bevel=0.0) for x in (-0.85, -0.3)])

    # a barrel at the front-left
    bx, bz = -0.75, -0.85
    k.add("wood", K.cyl((bx, 0.42, bz), 0.34, 0.84, 12, top=0.92, bevel=0.05))
    k.add("metal", *[K.ring((bx, y, bz), 0.33, 0.03, 12, 4) for y in (0.18, 0.66)])

    # pennant pole at the front-left corner
    px, pz = -1.3, -1.3
    k.add("dark", K.rod((px, 0, pz), (px, 4.3, pz), 0.05, 6))
    k.add("body", K.rbox((px + 0.45, 3.98, pz), (0.5, 0.86, 0.05), bevel=0.02, taper=(0.12, 1.0), rot=(0, 0, -90)))

    if stage >= 1:
        # pallet under A and C
        k.add("deck", *[K.rbox((-0.62, 0.1, 0.5 + dz), (1.35, 0.07, 0.28), bevel=0.0) for dz in (-0.48, 0.0, 0.48)],
              *[K.rbox((-0.62 + dx, 0.03, 0.5), (0.18, 0.06, 1.35), bevel=0.0) for dx in (-0.55, 0.55)])
        # grain sacks leaning on crate B
        k.add("sack", *[K.ell((x, 0.3, z), (0.26, 0.32, 0.22), 8, 5, rot=(rx, 0, 0))
                        for x, z, rx in ((0.25, -1.2, -12), (0.7, -1.22, 8))])

    brass = []
    if stage >= 2:
        # a derrick crane: a mast between the stacks, a boom out over the front-right, a
        # strongbox of glowing amber hanging from it - the crown is the mast's brass lantern
        mx, mz = 0.2, 0.55
        mt = 4.3
        tipp = (0.85, 3.7, -0.7)
        k.add("wood", K.rod((mx, 0, mz), (mx, mt, mz), 0.1, 8),
              K.rod((mx, 2.3, mz), tipp, 0.07, 6))
        k.add("rope", K.rod((mx, mt - 0.1, mz), tipp, 0.025, 4),
              K.rod(tipp, (tipp[0], 2.65, tipp[2]), 0.03, 4),
              *[K.rod((tipp[0], 2.65, tipp[2]), (tipp[0] + dx, 2.37, tipp[2] + dz), 0.02, 4) for dx, dz in ((-0.22, -0.16), (0.22, 0.16), (-0.22, 0.16), (0.22, -0.16))])
        sb = (tipp[0], 2.17, tipp[2])
        k.add("dark", K.rbox(sb, (0.6, 0.4, 0.45), bevel=0.04))
        k.add("glow", *[K.ell((sb[0] + dx, sb[1] + 0.22, sb[2] + dz), (0.15, 0.11, 0.13), 6, 3)
                        for dx, dz in ((-0.14, -0.06), (0.12, -0.08), (0.0, 0.1))], piece="amber")
        brass += [K.rbox((sb[0] + sx * 0.28, sb[1], sb[2] + sz * 0.2), (0.08, 0.42, 0.08), bevel=0.0)
                  for sx in (-1, 1) for sz in (-1, 1)]
        brass += [K.cyl(tipp, 0.12, 0.08, 10, rot=(0, 0, 90))]
        # the crown: a brass lantern on the mast top, glowing amber
        brass += [K.cyl((mx, mt + 0.05, mz), 0.2, 0.08, 8), K.cyl((mx, mt + 0.58, mz), 0.2, 0.08, 8, top=0.5),
                  *[K.rod((mx + dx, mt + 0.05, mz + dz), (mx + dx, mt + 0.55, mz + dz), 0.025, 4) for dx, dz in ((0.14, 0.14), (-0.14, -0.14), (0.14, -0.14), (-0.14, 0.14))]]
        k.add("glow", K.ell((mx, mt + 0.32, mz), (0.17, 0.22, 0.17), 8, 5), piece="lantern")
        # a finial on the pennant pole
        brass.append(K.ell((px, 4.36, pz), (0.09, 0.09, 0.09), 6, 4))
    if brass:
        k.add("brass", *brass)

    colors = {
        "body": ORANGE, "wood": (160, 118, 72), "dark": K.DARK, "rope": K.ROPE, "metal": K.METAL,
        "deck": (128, 96, 62), "sack": SACK, "brass": K.BRASS, "glow": AMBER,
    }
    return k.model("11d", colors, "QUARTERMASTER", stage)
