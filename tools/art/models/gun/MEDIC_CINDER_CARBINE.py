"""MEDIC_CINDER_CARBINE - Lever-Action Carbine premium skin Cinder Carbine (Lava Lord theme,
PREMIUM_SKINS.md, batch 11p2, #462: its own silhouette). The Molten Mender's cauterising carbine:

  * an obsidian receiver with a glass vial of molten lava clamped on top (the healer's vial, the
    pack tier's heat ramp reads off it)
  * a hewn rock fore-end, then a glowing heat coil wound twice round the barrel's front half
  * four obsidian heat fins round the barrel behind the muzzle (the muzzle and its lane are the base's)
  * a spiked obsidian lever loop, a rock stock with a molten cross inlaid on both sides and a crack
    running back from it; an ember stone (`accent`) in the butt

Barrel, magazine tube, rear sight, lever bar, trigger, bead, butt plate and the `muzzle` piece are
the base's; grip at (0, 0, 0). `glow` = Neon in game. Base: gun/MEDIC (variants/_skins.py), cap
1,200 (no Medic attachments).
"""
# art-sources: _medic.py variants/_skins.py

import importlib.util
import math
from pathlib import Path

_spec = importlib.util.spec_from_file_location("_skins", Path(__file__).with_name("variants") / "_skins.py")
S = importlib.util.module_from_spec(_spec)
_spec.loader.exec_module(S)


def extra(g, G, D):
    bore = D.BORE
    # obsidian receiver, the lava vial clamped on top
    g.add("dark", G.rbox((0, 0.19, -0.06), (0.14, 0.23, 0.44), bevel=0.0),
          G.rod((0, 0.37, 0.07), (0, 0.37, 0.11), 0.06, 6), G.rod((0, 0.37, -0.27), (0, 0.37, -0.31), 0.06, 6),
          *[G.rbox((0, 0.33, z), (0.1, 0.08, 0.03), bevel=0.0) for z in (0.0, -0.2)])
    g.add("glow", G.rod((0, 0.37, 0.07), (0, 0.37, -0.27), 0.05, 6))
    # rock fore-end (angular)
    g.add("wood", G.slab([(-0.28, 0.22), (-0.86, 0.22), (-0.9, 0.14), (-0.8, 0.08), (-0.56, 0.1), (-0.42, 0.06),
                          (-0.28, 0.1)], -0.075, 0.075, bevel=0.0))
    g.add("glow", *[G.rod((0.077 * k, 0.2, -0.36), (0.077 * k, 0.14, -0.6), 0.014, 3) for k in (-1, 1)],
          *[G.rod((0.077 * k, 0.14, -0.6), (0.077 * k, 0.18, -0.8), 0.014, 3) for k in (-1, 1)])
    # heat coil: two turns round the barrel's front half
    pts = []
    n = 14
    for i in range(n + 1):
        a = i / n * 4 * math.pi
        pts.append((0.095 * math.cos(a), 0.205 + 0.11 * math.sin(a), -0.88 - 0.36 * i / n))
    g.add("glow", *[G.rod(p, q, 0.022, 3) for p, q in zip(pts, pts[1:])])
    # four obsidian heat fins behind the muzzle
    fins = []
    for d in (45, 135, 225, 315):
        a = math.radians(d)
        ca, sa = math.cos(a), math.sin(a)
        fins.append(G.slab([(-1.2, 0.04), (-1.38, 0.04), (-1.38, 0.16), (-1.3, 0.16)], -0.014, 0.014, bevel=0.0))
        f = fins[-1]
        from mathutils import Matrix
        f.data.transform(Matrix.Translation((0, bore, 0)) @ Matrix.Rotation(-a + math.pi / 2, 4, "Z"))
        f.data.update()
    g.add("dark", *fins)
    # spiked lever loop
    g.add("dark", G.ring((0, -0.01, 0.03), 0.085, 0.024, 8, 4, axis="x"),
          G.rod((0, -0.09, 0.06), (0, -0.2, 0.12), 0.03, 4, top=0.1),
          G.rod((0, -0.05, -0.06), (0, -0.14, -0.14), 0.026, 4, top=0.1))
    # rock stock, molten cross both sides, crack, ember stone
    w = 0.075
    g.add("wood", G.slab([(0.2, 0.24), (0.6, 0.24), (0.98, 0.2), (1.02, -0.16), (0.92, -0.2), (0.62, -0.1),
                          (0.3, 0.0), (0.2, 0.06)], -w, w, bevel=0.0))
    for k in (-1, 1):
        x = (w + 0.006) * k
        g.add("glow", G.rbox((x, 0.04, 0.66), (0.012, 0.2, 0.07), bevel=0.0), G.rbox((x, 0.04, 0.66), (0.012, 0.07, 0.2), bevel=0.0),
              *[G.rod((x, y0, z0), (x, y1, z1), 0.013, 3) for (z0, y0), (z1, y1) in zip(
                  [(0.78, 0.0), (0.86, -0.06), (0.96, -0.02)], [(0.86, -0.06), (0.96, -0.02), (1.0, -0.1)])])
    g.add("accent", G.ell((0, 0.2, 0.98), (0.05, 0.035, 0.04), 6, 3))


def build(lp):
    model = S.variant(
        lp, "MEDIC", "CINDER_CARBINE", "Cinder Carbine",
        drop=[("wood", 0), ("wood", 2),  # stock, fore-end -> rock
              ("brass", 0), ("brass", 1),  # receiver -> obsidian, saddle ring
              ("steel", 2), ("steel", 3), ("steel", 6),  # barrel bands, lever loop -> spiked
              ("cloth", 0), ("accent", 0), ("accent", 1)],  # bandage, green cross -> molten cross
        extra=extra,
        colors={"wood": (40, 34, 42), "steel": (62, 58, 66), "brass": (150, 84, 44), "dark": (28, 24, 30),
                "accent": (236, 96, 28), "glow": (255, 112, 20)},
    )
    model["batch"] = "11p2"
    model["meta"].update({"theme": "LAVA_LORD", "premium": True})
    return model
