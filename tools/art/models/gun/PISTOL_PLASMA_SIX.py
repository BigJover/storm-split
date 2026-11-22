"""PISTOL_PLASMA_SIX - the Tracker's Revolver, premium skin Plasma Six (Cyber Raptor theme,
PREMIUM_SKINS.md, batch 11p3, #462: its own silhouette, element electric / digital glitch). A sleek
black-chrome energy revolver:

  * an angular black-chrome frame and a raked grip with a light strip down its back
  * the "six": a drum of six glowing plasma cells in a gunmetal cradle where the cylinder was
  * the barrel inside a slotted shroud with three glowing coil rings (the pack tier's charge glow)
  * a swept raptor fin along the top strap with a glowing edge, a raptor claw hooked under the
    muzzle (behind the tip: the muzzle lane stays clear), a magenta `accent` trim on the grip

Barrel, trigger and the `muzzle` piece are the base's; grip at (0, 0, 0). `glow` = Neon in game.
Base: gun/PISTOL (variants/_skins.py), cap 880 with the Scope.
"""
# art-sources: _pistol.py variants/_skins.py

import importlib.util
import math
from pathlib import Path

_spec = importlib.util.spec_from_file_location("_skins", Path(__file__).with_name("variants") / "_skins.py")
S = importlib.util.module_from_spec(_spec)
_spec.loader.exec_module(S)


def extra(g, G, D):
    y = D.BORE
    g.add("plate",
          G.slab([(0.24, 0.36), (0.02, 0.38), (-0.26, 0.33), (-0.26, 0.06), (0.04, 0.05), (0.22, 0.14)], -0.055, 0.055, bevel=0.0),  # frame
          G.slab([(0.0, 0.08), (0.2, 0.12), (0.3, -0.26), (0.18, -0.3), (0.06, -0.16)], -0.075, 0.075, bevel=0.0),  # raked grip
          G.rbox((0, y, -0.52), (0.13, 0.15, 0.6), bevel=0.0, taper=(0.75, 0.8)))  # barrel shroud
    g.add("chrome",
          G.rod((0, y - 0.01, 0.09), (0, y - 0.01, -0.19), 0.05, 6),  # drum axle
          *[G.rod((0, y - 0.01, z), (0, y - 0.01, z - 0.03), 0.135, 6) for z in (0.08, -0.15)],  # drum cradle plates
          G.rbox((0, 0.36, 0.2), (0.05, 0.07, 0.08), bevel=0.0, rot=(-30, 0, 0)),  # hammer
          G.ring((0, 0.05, -0.1), 0.065, 0.015, 8, 4, axis="x"))  # trigger guard
    cells = []
    for i in range(6):
        a = math.radians(30 + 60 * i)
        cells.append(G.rod((0.085 * math.cos(a), y - 0.01 + 0.085 * math.sin(a), 0.05),
                           (0.085 * math.cos(a), y - 0.01 + 0.085 * math.sin(a), -0.12), 0.034, 5))
    g.add("glow", *cells,
          *[G.ring((0, y, z), 0.085, 0.016, 8, 3, axis="z") for z in (-0.32, -0.5, -0.68)],  # coil rings through the shroud
          G.rbox((0, -0.1, 0.25), (0.02, 0.3, 0.02), bevel=0.0, rot=(-22, 0, 0)),  # grip light strip
          *[G.rbox((0.066 * k, y, -0.5), (0.01, 0.04, 0.4), bevel=0.0) for k in (-1, 1)])  # shroud side slots
    # raptor fin along the top, glowing edge behind it
    g.add("chrome", G.rbox((0, 0.43, -0.2), (0.03, 0.1, 0.5), bevel=0.0, taper=(1.0, 0.2)))
    g.add("glow", G.rbox((0, 0.445, -0.2), (0.014, 0.12, 0.56), bevel=0.0, taper=(1.0, 0.2)))
    # a claw hooked under the muzzle end (pointing down, behind the tip)
    g.add("chrome", G.rod((0, y - 0.08, -0.74), (0, y - 0.2, -0.78), 0.03, 4, top=0.3))
    g.add("accent", *[G.rbox((0.078 * k, -0.04, 0.16), (0.01, 0.12, 0.06), bevel=0.0, rot=(-22, 0, 0)) for k in (-1, 1)])


def build(lp):
    model = S.variant(
        lp, "PISTOL", "PLASMA_SIX", "Plasma Six",
        drop=[("steel", 0), ("steel", 1), ("steel", 2), ("steel", 4), ("steel", 5), ("steel", 6),
              ("wood", 0), ("brass", 0), ("brass", 1), ("brass", 2), ("accent", 0), ("accent", 1)],
        extra=extra,
        colors={"steel": (70, 74, 88), "plate": (30, 32, 44), "chrome": (138, 148, 166),
                "accent": (230, 60, 220), "glow": (0, 236, 255)},
    )
    model["batch"] = "11p3"
    model["meta"].update({"theme": "CYBER_RAPTOR", "premium": True})
    return model
