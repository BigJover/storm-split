"""TARPIT - Tar Pit (TowerLook tar black): a pool of glossy tar with bubbles, sunk in a rim of
dug earth and stones, a dino bone sticking out. It lies ON the track, so everything stays low
(under ~0.8 studs) and never blocks the view of the dinos walking through it. Authored from the
base (y 0) in Roblox studs; front = -Z (_kit conventions). The pit can't be damaged.

Stage 0 (tiers 0-2): the earth rim, the tar pool, three bubbles, a thigh bone half sunk, a
                     short warning stake.
Stage 1 (tier 3):    a sunken ribcage and a dino skull, more bubbles, stones on the rim, a tar
                     ladle stuck in the edge.
Stage 2 (tier 5):    a half-sunk brass-banded keg, brass rivets on the stake, glowing hot
                     bubbles and embers in the tar.
"""

import importlib.util
import math
from pathlib import Path

_spec = importlib.util.spec_from_file_location("_kit", Path(__file__).with_name("_kit.py"))
K = importlib.util.module_from_spec(_spec)
_spec.loader.exec_module(K)

TAR = (35, 28, 24)  # TowerLook.COLORS.TARPIT
SHEEN = (62, 54, 48)
EARTH = (96, 74, 52)
STONE = (112, 106, 98)
BONE = (225, 215, 190)
GLOW = (255, 120, 40)

TY = 0.12  # the tar's surface


def build(lp, stage):
    k = K.Kit(lp)

    # dug-earth rim (a fat low torus) and the tar pool inside it, a sheen across the surface
    k.add("earth", K.ring((0, 0.17, 0), 1.24, 0.17, 20, 5), K.cyl((0, 0.02, 0), 1.25, 0.04, 20, bevel=0.0))
    k.add("body", K.cyl((0, TY / 2, 0), 1.18, TY, 20, bevel=0.03))

    # bubbles (domes rising from the tar); stage 2's are hot
    spots = [(-0.55, 0.35, 0.2), (0.45, -0.5, 0.15), (0.1, 0.05, 0.1)]
    if stage >= 1:
        spots += [(-0.2, -0.7, 0.12), (0.7, 0.2, 0.09)]
    bubbles = [K.ell((x, TY + r * 0.3, z), (r, r * 0.85, r), 10, 5) for x, z, r in spots]
    k.add("glow" if stage >= 2 else "bubble", *bubbles, piece="bubbles")
    k.add("sheen", *[K.ring((x, TY + 0.005, z), r * 1.25, 0.02, 10, 3) for x, z, r in spots])  # ripples

    # a thigh bone half sunk, sticking up out of the tar
    k.add("bone", K.rod((0.3, 0.08, 0.5), (0.82, 0.42, 0.7), 0.07, 8),
          K.ell((0.85, 0.44, 0.71), (0.13, 0.1, 0.1), 8, 5), K.ell((0.8, 0.5, 0.62), (0.09, 0.08, 0.09), 8, 4))

    # a short warning stake at the front-left, sign tilted
    sx, sz = -1.25, -1.2
    k.add("wood", K.rod((sx, 0.0, sz), (sx + 0.04, 0.85, sz), 0.05, 6))
    k.add("sign", K.rbox((sx + 0.04, 0.62, sz - 0.06), (0.5, 0.3, 0.05), bevel=0.02, rot=(0, 20, 8)))
    k.add("tar", K.ell((sx + 0.04, 0.62, sz - 0.1), (0.12, 0.08, 0.02), 6, 3, rot=(0, 20, 0)))  # a tar splash on it

    brass = []
    if stage >= 1:
        # a sunken ribcage: ribs arcing out of the tar, a spine along it
        ribs = []
        for i, u in enumerate((-0.35, -0.12, 0.11, 0.34)):
            h = 0.42 - abs(u) * 0.4
            for s in (-1, 1):
                elbow = (-0.45 + s * 0.34, TY + h * 0.75, u - 0.1)
                ribs += [K.rod((-0.45 + s * 0.05, TY, u - 0.1), elbow, 0.045, 5),
                         K.rod(elbow, (-0.45 + s * 0.22, TY + h, u - 0.1), 0.04, 5, top=0.5)]
        ribs.append(K.rod((-0.45, TY + 0.02, -0.6), (-0.45, TY + 0.02, 0.35), 0.06, 6))
        # a skull at the front-right, jaw sunk
        ribs += [K.ell((0.6, TY + 0.1, -0.15), (0.2, 0.15, 0.27), 10, 5),
                 K.rod((0.48, TY + 0.2, -0.05), (0.42, TY + 0.38, 0.05), 0.04, 5, top=0.3)]
        k.add("bone", *ribs)
        k.add("tar", *[K.ell((0.6 + dx, TY + 0.14, -0.33), (0.04, 0.04, 0.02), 6, 3) for dx in (-0.08, 0.08)])  # sockets
        # stones on the rim
        stones = [K.ell((math.cos(a) * 1.28, 0.2, math.sin(a) * 1.28), (0.17, 0.12, 0.14), 8, 4, rot=(0, math.degrees(a), 0))
                  for a in (math.radians(d) for d in (200, 250, 300, 340, 160))]
        k.add("stone", *stones)
        # a tar ladle stuck in the edge at the left
        k.add("wood", K.rod((-1.05, TY, 0.6), (-1.3, 0.75, 0.75), 0.035, 6))
        k.add("metal", K.ell((-1.0, TY + 0.02, 0.58), (0.13, 0.06, 0.13), 8, 4))

    if stage >= 2:
        # a brass-banded keg half sunk at the back-left
        kx, kz = -0.15, 0.6
        k.add("wood", K.cyl((kx, TY + 0.1, kz), 0.2, 0.45, 10, rot=(0, 25, 90)))
        ax = (math.cos(math.radians(25)), 0.0, -math.sin(math.radians(25)))
        brass += [K.ring_along((kx + ax[0] * t, TY + 0.1, kz + ax[2] * t), (kx + ax[0] * (t + 1), TY + 0.1, kz + ax[2] * (t + 1)), 0.2, 0.03, 10, 3)
                  for t in (-0.13, 0.13)]
        brass += [K.ell((sx + 0.04 + dx, 0.62 + dy, sz - 0.09), (0.03, 0.03, 0.02), 4, 3) for dx in (-0.18, 0.18) for dy in (-0.08, 0.08)]
        # embers floating just above the hot tar
        k.add("glow", *[K.ell((x, TY + 0.03, z), (0.05, 0.03, 0.05), 6, 3) for x, z in ((-0.1, -0.35), (0.3, 0.55), (-0.75, -0.25), (0.85, -0.2))],
              piece="embers")
        k.add("brass", *brass)

    colors = {
        "body": TAR, "sheen": SHEEN, "bubble": (70, 60, 52), "earth": EARTH, "stone": STONE, "bone": BONE,
        "wood": K.WOOD, "sign": K.SAND, "tar": (24, 20, 18), "metal": K.METAL, "brass": K.BRASS, "glow": GLOW,
    }
    return k.model("11d", colors, "TARPIT", stage)
