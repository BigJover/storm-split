"""Lava Lord set pieces (premium theme, PREMIUM_SKINS.md, batch 11p1): one themed add-on per tower kind,
`tower/SET_LAVA_LORD_<TOWER>`, worn over that tower's art at every stage on top of the Lava Lord trim
(SET_LAVA_LORD.py). The plan's three motifs: an obsidian **spire** (jagged volcanic-glass shards with a
crack glowing up them), a **magma brazier** (an obsidian bowl of lava with flame tongues) and a **lava
pool** (a glowing pool in an obsidian lip with crust rocks). `glow` = Neon in game; Shared/SkinFx
pulses it and, at stage 2, brightens it and lets embers rise from the piece.

Built and checked by _setpiece_common.setpiece (<= 800 tris, flag + Rescue Beacon columns clear,
muzzle + its lane clear at every stage, Vent's middle clear, clip <= 35 %); previews on stage 0 and 2.
"""

import importlib.util
import math
from pathlib import Path

TOWER = Path(__file__).resolve().parents[1]
_spec = importlib.util.spec_from_file_location("_setpiece_common", TOWER / "variants" / "_setpiece_common.py")
C = importlib.util.module_from_spec(_spec)
_spec.loader.exec_module(C)

COLORS = {"obsidian": (34, 30, 38), "basalt": (74, 64, 68), "glow": (255, 112, 20)}


def shard(K, base, h, w, lean=(0, 0, 0)):
    """A jagged pyramid shard standing on `base` (lifted a hair so a lean doesn't dip below it)."""
    return K.rbox((base[0], base[1] + h / 2 + 0.03, base[2]), (w, h, w * 0.8), bevel=0.0, rot=lean, taper=(0.08, 0.12))


def spire(k, K, at, h=1.6, w=0.42, yaw=0.0):
    """A main shard with two smaller ones leaning off it; a crack glows up the main one's face."""
    x, y, z = at
    c, s = math.cos(math.radians(yaw)), math.sin(math.radians(yaw))

    def p(dx, dz):
        return (x + dx * c + dz * s, y, z - dx * s + dz * c)

    k.add("obsidian",
          shard(K, p(0, 0), h, w, (-4, yaw, 5)),
          shard(K, p(0.2, 0.08), h * 0.55, w * 0.7, (-8, yaw, -18)),
          shard(K, p(-0.16, 0.12), h * 0.42, w * 0.6, (10, yaw, 16)))
    k.add("basalt", K.cyl((x, y + 0.05, z), w * 0.75, 0.1, 7, bevel=0.0))  # its rubble foot
    face = [(0.0, 0.12), (0.06, 0.36), (-0.03, 0.58), (0.03, 0.8)]
    pts = []
    for dx, t in face:  # up the shard's -Z face (in its own yaw), where it narrows
        half = w * 0.4 * (1 - t * 0.92) + 0.01
        px, py, pz = p(dx * (1 - t), -half)
        pts.append((px, y + 0.03 + h * t, pz))
    k.add("glow", *[K.rod(a, b, 0.036, 4) for a, b in zip(pts, pts[1:])],
          K.ell((x, y + 0.1, z), (w * 0.55, 0.04, w * 0.55), 7, 2))  # lava welling round its foot


def brazier(k, K, at, s=1.0, legs=0.35):
    """An obsidian bowl of lava on three short legs, flame tongues licking up."""
    x, y, z = at
    top = y + legs * s
    k.add("obsidian",
          *[K.rod((x + 0.2 * s * math.cos(a), y, z + 0.2 * s * math.sin(a)),
                  (x + 0.14 * s * math.cos(a), top, z + 0.14 * s * math.sin(a)), 0.035 * s, 4)
            for a in (0.5, 2.6, 4.7)],
          K.cyl((x, top + 0.1 * s, z), 0.18 * s, 0.22 * s, 8, top=1.45, bevel=0.0))
    k.add("basalt", K.cyl((x, top + 0.22 * s, z), 0.27 * s, 0.04 * s, 8, bevel=0.0))  # rim band
    k.add("glow",
          K.cyl((x, top + 0.2 * s, z), 0.23 * s, 0.03 * s, 8, bevel=0.0),
          *[K.ell((x + dx * s, top + (0.2 + hh) * s, z + dz * s), (0.075 * s, hh * s, 0.075 * s), 6, 3,
                  rot=(lx, 0, lz))
            for dx, dz, hh, lx, lz in ((0.0, 0.0, 0.3, 0, 0), (0.1, 0.05, 0.2, 8, -14), (-0.09, -0.04, 0.18, -10, 12), (0.02, -0.1, 0.15, -14, -6))])


def pool(k, K, at, r=0.38, rocks=2):
    """A flat lava pool in an obsidian lip (stays under ~0.2), a crust rock or two on it."""
    x, y, z = at
    k.add("obsidian", K.cyl((x, y + 0.06, z), r, 0.12, 9, bevel=0.0))
    k.add("glow", K.cyl((x, y + 0.125, z), r * 0.8, 0.02, 9, bevel=0.0))
    k.add("basalt", *[K.ell((x + r * 0.35 * math.cos(a), y + 0.15, z + r * 0.35 * math.sin(a)), (0.08, 0.05, 0.07), 5, 3)
                      for a in (0.8, 3.6)[:rocks]])


def build(lp, tower, design):
    """design(k, K) with this module's props; the batch 11p1 entry."""
    model = C.setpiece(lp, "LAVA_LORD", tower, design, COLORS)
    model["batch"] = "11p1"
    model["meta"].update({"theme": "LAVA_LORD", "premium": True})
    return model
