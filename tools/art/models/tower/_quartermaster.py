"""QUARTERMASTER - Supply Camp (TowerLook supply-crate orange): stacked framed crates under an
orange tarp roped down, a barrel, and an orange pennant on a pole at the front-left (the
owner flag keeps the back-right corner). It doesn't shoot: no muzzle piece. Authored from the
base (y 0) in Roblox studs; front = -Z (_kit conventions).

Stage 0 (tiers 0-2): three crates (two on the ground, one stacked), the tarp, a barrel, pennant.
Stage 1 (tier 3):    a pallet under the stack, a fourth crate, grain sacks, rope coils, a
                     lean-to pole frame holding the tarp up.
Stage 2 (tier 5):    an open strongbox of glowing amber with brass corners, brass corner caps
                     on the crates, a brass lantern, a brass pennant finial.
"""

import importlib.util
from pathlib import Path

_spec = importlib.util.spec_from_file_location("_kit", Path(__file__).with_name("_kit.py"))
K = importlib.util.module_from_spec(_spec)
_spec.loader.exec_module(K)

ORANGE = (230, 150, 50)  # TowerLook.COLORS.QUARTERMASTER
SACK = (196, 180, 140)
AMBER = (255, 170, 40)


def build(lp, stage):
    k = K.Kit(lp)
    lift = 0.14 if stage >= 1 else 0.0  # stage 1+: the stack stands on a pallet

    crates = [((-0.62, lift + 0.6, 0.5), (1.2, 1.2, 1.2), 4),  # A: the big one, back-left
              ((0.62, 0.5, -0.55), (1.0, 1.0, 1.0), -8),  # B: front-right
              ((-0.55, lift + 1.2 + 0.45, 0.45), (0.95, 0.9, 0.9), 12)]  # C: on top of A
    if stage >= 1:
        crates.append(((0.7, 0.4, 0.45), (0.8, 0.8, 0.8), 20))  # D: a small one
    cores, frames = [], []
    for c, s, yaw in crates:
        core, frame = K.crate(c, s, yaw)
        cores.append(core)
        frames += frame
    k.add("wood", *cores)
    k.add("dark", *frames)

    # the orange tarp over the stack: a top sheet and a flap hanging down the front
    top_y = lift + 1.2 + 0.9 + 0.06
    k.add("body", K.rbox((-0.5, top_y, 0.42), (1.45, 0.08, 1.4), bevel=0.035, rot=(0, 12, 0)),
          K.bar((-0.5, top_y, -0.22), (-0.5, lift + 1.27, -0.42), 1.35, 0.07, bevel=0.03) if stage >= 1
          else K.bar((-0.5, top_y, -0.22), (-0.5, 1.0, -0.16), 1.35, 0.07, bevel=0.03))  # hangs on A's face
    # ropes over the tarp
    k.add("rope", *[K.bar((x, top_y + 0.05, -0.28), (x + 0.08, top_y + 0.05, 1.08), 0.05, 0.04, bevel=0.015) for x in (-0.85, -0.2)])

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
        k.add("deck", *[K.rbox((-0.62, 0.1, 0.5 + dz), (1.35, 0.07, 0.28), bevel=0.02) for dz in (-0.48, 0.0, 0.48)],
              *[K.rbox((-0.62 + dx, 0.03, 0.5), (0.18, 0.06, 1.35), bevel=0.02) for dx in (-0.55, 0.55)])
        # grain sacks leaning on crate B
        k.add("sack", *[K.ell((x, 0.3, z), (0.26, 0.32, 0.22), 10, 6, rot=(rx, 0, 0))
                        for x, z, rx in ((0.25, -1.2, -12), (0.7, -1.22, 8))])
        k.add("rope", *[K.ring((x, 0.6, z), 0.08, 0.03, 8, 4) for x, z in ((0.25, -1.2), (0.7, -1.22))])
        # a lean-to pole frame holding the tarp's front up
        k.add("dark", *[K.rod((x, 0, -0.42), (x, lift + 1.27, -0.42), 0.05, 6) for x in (-1.12, 0.12)])
        # a rope coil on crate B
        k.add("rope", K.ring((0.62, 1.04, -0.55), 0.24, 0.05, 12, 5))

    brass = []
    if stage >= 2:
        # an open strongbox of glowing amber on crate B (lid propped open)
        sb = (0.62, 1.2, -0.55)
        k.add("dark", K.rbox(sb, (0.62, 0.36, 0.44), bevel=0.04),
              K.rbox((sb[0], sb[1] + 0.33, sb[2] + 0.27), (0.62, 0.36, 0.06), bevel=0.02, rot=(-20, 0, 0)))
        k.add("glow", *[K.ell((sb[0] + dx, sb[1] + 0.18, sb[2] + dz), (0.13, 0.1, 0.11), 8, 5)
                        for dx, dz in ((-0.15, -0.06), (0.1, -0.08), (0.0, 0.1), (0.18, 0.08))])
        brass += [K.rbox((sb[0] + sx * 0.29, sb[1], sb[2] + sz * 0.2), (0.08, 0.38, 0.08), bevel=0.02)
                  for sx in (-1, 1) for sz in (-1, 1)]
        # brass corner caps on the big crate's top corners
        for c, s, yaw in crates[:1]:
            brass += [K.ell((c[0] + sx * s[0] / 2 * 0.98, c[1] + s[1] / 2, c[2] + sz * s[2] / 2 * 0.98), (0.09, 0.06, 0.09), 6, 4)
                      for sx in (-1, 1) for sz in (-1, 1)]
        # a lantern on the barrel, a finial on the pennant pole
        brass += [K.cyl((bx, 0.88, bz), 0.1, 0.06, 8), K.cyl((bx, 1.18, bz), 0.11, 0.05, 8),
                  K.ell((px, 4.36, pz), (0.09, 0.09, 0.09), 8, 5)]
        k.add("glow", K.ell((bx, 1.03, bz), (0.1, 0.13, 0.1), 8, 5), piece="lantern")
    if brass:
        k.add("brass", *brass)

    colors = {
        "body": ORANGE, "wood": (160, 118, 72), "dark": K.DARK, "rope": K.ROPE, "metal": K.METAL,
        "deck": (128, 96, 62), "sack": SACK, "brass": K.BRASS, "glow": AMBER,
    }
    return k.model("11d", colors, "QUARTERMASTER", stage)
