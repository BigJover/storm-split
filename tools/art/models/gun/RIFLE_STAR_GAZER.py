"""RIFLE_STAR_GAZER - Hunting Rifle premium skin Star Gazer (Nebula theme, PREMIUM_SKINS.md, batch 11p5,
#462: its own silhouette, element cosmic / void). A sleek star-captain's long blaster built round a
telescope:

  * a swept indigo stock (a long fin-like profile, no walnut) with a constellation down each side
  * a GALAXY CORE where the fore-end was: a glowing core in an upright silver orbit ring with a
    tilted second ring, star points round it (the pack tier's heat ramp reads off `glow`)
  * a long silver star-gazing telescope along the top (eyepiece + flared objective, starlight lens)
  * an indigo barrel shroud with starlight lines along both sides and an orbit ring behind the tip
  * a nebula-pink star gem (`accent`) on the butt where the class badge was

The receiver, barrel, trigger, guard and the `muzzle` piece are the base's; grip at (0, 0, 0).
Base: gun/RIFLE (variants/_skins.py), cap 864 with Belt Fed. `glow` = Neon in game.
"""
# art-sources: _rifle.py variants/_skins.py

import importlib.util
import math
from pathlib import Path

_spec = importlib.util.spec_from_file_location("_skins", Path(__file__).with_name("variants") / "_skins.py")
S = importlib.util.module_from_spec(_spec)
_spec.loader.exec_module(S)


def extra(g, G, D):
    w = 0.07
    # swept fin stock: long, thin at the wrist, a sharp tail at the butt
    g.add("wood",
          G.slab([(0.16, 0.22), (0.6, 0.27), (1.04, 0.34), (1.0, -0.06), (0.9, -0.2), (0.6, -0.12), (0.3, -0.01), (0.16, 0.04)],
                 -w, w, bevel=0.0),
          G.rbox((0, -0.06, 0.07), (0.12, 0.28, 0.14), bevel=0.02, rot=(-22, 0, 0)),  # grip
          G.slab([(-0.22, 0.2), (-0.36, 0.2), (-0.36, 0.08), (-0.22, 0.06)], -0.065, 0.065, bevel=0.0))  # short fore-stub
    for k in (-1, 1):
        x = (w + 0.004) * k
        pts = [(0.22, 0.2), (0.12, 0.42), (0.16, 0.66), (0.02, 0.9)]  # (y, z)
        g.add("glow", *[G.rod((x, y0, z0), (x, y1, z1), 0.012, 3) for (y0, z0), (y1, z1) in zip(pts, pts[1:])],
              *[G.ell((x, y, z), (0.008, 0.03, 0.03), 4, 2) for y, z in pts[1::2]])
    # the galaxy core under the barrel: core + an upright silver ring + a tilted glowing ring
    cz, cy = -0.6, 0.0
    g.add("glow", G.ell((0, cy, cz), (0.1, 0.1, 0.1), 6, 4),
          G.ring((0, cy, cz), 0.21, 0.014, 10, 3, axis="z", rot=(0, 50, 25)))
    g.add("brass", G.ring((0, cy, cz), 0.17, 0.024, 10, 3, axis="x"),
          G.rod((0, cy + 0.17, cz), (0, D.BORE - 0.04, cz), 0.02, 4))  # hanger to the barrel
    # barrel shroud with starlight lines and an orbit ring behind the tip
    g.add("dark", G.rod((0, D.BORE, -0.32), (0, D.BORE, -1.36), 0.075, 6, top=0.75))
    g.add("glow", *[G.rbox((0.068 * k, D.BORE, -0.84), (0.012, 0.02, 0.88), bevel=0.0, rot=(0, 2.4 * k, 0)) for k in (-1, 1)],
          G.ring((0, D.BORE, -1.5), 0.095, 0.014, 10, 3, axis="z"))
    # the telescope on top
    y = 0.395
    g.add("brass",
          G.rod((0, y, 0.16), (0, y, -0.5), 0.034, 5),
          G.rod((0, y, -0.5), (0, y, -0.66), 0.034, 5, top=1.4),
          G.rbox((0, 0.35, -0.2), (0.04, 0.1, 0.06), bevel=0.0))
    g.add("glow", G.ell((0, y, -0.665), (0.05, 0.05, 0.012), 6, 2))
    g.add("accent", G.ell((-(w + 0.004), 0.1, 0.7), (0.014, 0.07, 0.07), 4, 2),
          G.ell((-(w + 0.004), 0.1, 0.7), (0.014, 0.025, 0.12), 4, 2))  # a four-point star gem


def build(lp):
    model = S.variant(
        lp, "RIFLE", "STAR_GAZER", "Star Gazer",
        drop=[("wood", 0), ("wood", 2), ("wood", 3),  # stock, grip, fore-end -> fin stock, galaxy core
              ("steel", 2), ("steel", 3), ("steel", 4), ("steel", 6), ("steel", 7),  # bolt, knob, rear sight, swivels
              ("leather", 0), ("leather", 1), ("leather", 2), ("leather", 3), ("brass", 0), ("brass", 2), ("accent", 0)],  # sling, band, bead, badge
        extra=extra,
        colors={"wood": (40, 38, 100), "steel": (70, 66, 112), "brass": (190, 186, 224), "dark": (26, 24, 54),
                "accent": (214, 88, 184), "glow": (150, 236, 240)},
    )
    model["batch"] = "11p5"
    model["meta"].update({"theme": "NEBULA", "premium": True})
    return model
