"""SHOTGUN_BLAST_FURNACE - Shotgun premium skin Blast Furnace (Lava Lord theme, PREMIUM_SKINS.md, batch
11p2, #462: its own silhouette). A shotgun that is a little forge:

  * the receiver is a furnace box with a barred fire door glowing on each side and a stubby
    smokestack with a glowing mouth on top
  * the pump is a pair of forge bellows (charred leather pleats between obsidian end plates)
  * a white-hot core glows where the magazine tube was, in front of and behind the bellows
  * a thick obsidian shroud over the barrel's front with two glowing heat rings, flaring into a
    bell just behind the muzzle (the muzzle ring and its lane are the base's)
  * a hewn rock stock with glowing cracks; an ember stone (`accent`) in its side

Wrist, grip, butt pad, barrel, trigger, guard and the `muzzle` piece are the base's; grip at
(0, 0, 0). `glow` = Neon in game. Base: gun/SHOTGUN (variants/_skins.py), cap 868 with both
attachments (Double Barrel's second barrel and the drum still fit on top).
"""
# art-sources: _shotgun.py variants/_skins.py

import importlib.util
from pathlib import Path

_spec = importlib.util.spec_from_file_location("_skins", Path(__file__).with_name("variants") / "_skins.py")
S = importlib.util.module_from_spec(_spec)
_spec.loader.exec_module(S)


def extra(g, G, D):
    bore = D.BORE
    # furnace-box receiver, fire doors with bars, smokestack
    g.add("dark", G.rbox((0, 0.2, -0.06), (0.17, 0.27, 0.56), bevel=0.0),
          G.rod((0.0, 0.33, 0.06), (0.0, 0.43, 0.06), 0.05, 5),
          *[G.rbox((0.088 * k, 0.2, z), (0.012, 0.16, 0.02), bevel=0.0) for k in (-1, 1) for z in (-0.13, -0.03)])
    g.add("glow", *[G.rbox((0.084 * k, 0.2, -0.08), (0.008, 0.15, 0.22), bevel=0.0) for k in (-1, 1)],
          G.rod((0.0, 0.43, 0.06), (0.0, 0.445, 0.06), 0.036, 5))
    # bellows pump: leather pleats between obsidian end plates
    y = 0.12
    pleats = []
    zs = [-0.58 - 0.08 * i for i in range(6)]
    for i, (a, b) in enumerate(zip(zs, zs[1:])):
        pleats.append(G.rod((0, y, a), (0, y, b), 0.1 if i % 2 == 0 else 0.075, 6, top=0.75 if i % 2 == 0 else 1.33))
    g.add("leather", *pleats)
    g.add("dark", G.rod((0, y, -0.98), (0, y, -1.02), 0.11, 5), G.rod((0, y, -0.55), (0, y, -0.58), 0.11, 5))
    # white-hot core where the magazine tube was
    g.add("glow", G.rod((0, y, -0.32), (0, y, -0.55), 0.042, 5), G.rod((0, y, -1.02), (0, y, -1.3), 0.042, 5))
    # barrel shroud, heat rings, bell flare behind the muzzle
    g.add("dark", G.rod((0, bore - 0.03, -1.04), (0, bore - 0.03, -1.36), 0.105, 6),
          G.rod((0, bore, -1.36), (0, bore, -1.47), 0.09, 6, top=1.45))
    g.add("glow", G.rod((0, bore - 0.03, -1.12), (0, bore - 0.03, -1.15), 0.11, 6),
          G.rod((0, bore - 0.03, -1.26), (0, bore - 0.03, -1.29), 0.11, 6))
    # hewn rock stock, cracks, ember stone
    w = 0.08
    g.add("wood", G.slab([(0.18, 0.26), (0.56, 0.3), (0.98, 0.27), (1.02, -0.06), (0.96, -0.22), (0.7, -0.14),
                          (0.36, -0.04), (0.18, 0.06)], -w, w, bevel=0.0))
    for k in (-1, 1):
        x = (w + 0.004) * k
        pts = [(0.24, 0.18), (0.46, 0.08), (0.7, 0.14), (0.94, 0.02)]
        g.add("glow", *[G.rod((x, y0, z0), (x, y1, z1), 0.016, 3) for (z0, y0), (z1, y1) in zip(pts, pts[1:])])
    g.add("accent", G.ell((-(w + 0.004), 0.16, 0.72), (0.014, 0.06, 0.09), 6, 3))


def build(lp):
    model = S.variant(
        lp, "SHOTGUN", "BLAST_FURNACE", "Blast Furnace",
        drop=[("wood", 0), ("wood", 3), ("dark", 1),  # stock -> rock, pump + groove -> bellows
              ("steel", 0), ("steel", 2), ("steel", 4),  # receiver -> furnace, tube -> core, saddle plate
              ("brass", 1), ("brass", 2), ("brass", 3),  # tube cap, bead, shell rim
              ("accent", 0), ("accent", 1), ("accent", 2), ("accent", 3)],  # the shells
        extra=extra,
        colors={"wood": (40, 34, 42), "steel": (62, 58, 66), "brass": (150, 84, 44), "dark": (28, 24, 30),
                "leather": (84, 52, 38), "accent": (236, 96, 28), "glow": (255, 112, 20)},
    )
    model["batch"] = "11p2"
    model["meta"].update({"theme": "LAVA_LORD", "premium": True})
    return model
