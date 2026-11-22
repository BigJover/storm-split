"""RIFLE_RAIL_RIFLE - the Big Game Hunter's Hunting Rifle, premium skin Rail Rifle (Cyber Raptor theme,
PREMIUM_SKINS.md, batch 11p3, #462: its own silhouette, element electric / digital glitch). A long
black-chrome rail gun:

  * twin gunmetal rails above and below the barrel, held by three clamps and wrapped in three glowing coil rings near the muzzle, a glowing plasma line
    down each side of the barrel between them (the pack tier's charge glow)
  * a capacitor bank on the right of the receiver: three glowing cells in a cradle
  * an angular black-chrome receiver, a skeletal stock (two struts and a butt plate) with a light
    bar through it, a raked grip
  * a slim holo scope with a glowing lens, a raptor claw hooked under the fore-end, magenta
    `accent` trim on the stock

Barrel, trigger and the `muzzle` piece are the base's; grip at (0, 0, 0). `glow` = Neon in game.
Base: gun/RIFLE (variants/_skins.py), cap 864 with Belt Fed.
"""
# art-sources: _rifle.py variants/_skins.py

import importlib.util
from pathlib import Path

_spec = importlib.util.spec_from_file_location("_skins", Path(__file__).with_name("variants") / "_skins.py")
S = importlib.util.module_from_spec(_spec)
_spec.loader.exec_module(S)


def extra(g, G, D):
    y = D.BORE
    g.add("plate",
          G.slab([(0.22, 0.38), (-0.5, 0.38), (-0.56, 0.3), (-0.5, 0.1), (-0.16, 0.04), (0.22, 0.06)], -0.075, 0.075, bevel=0.0),  # receiver
          G.slab([(-0.5, 0.11), (-0.94, 0.11), (-0.9, -0.02), (-0.56, -0.02)], -0.06, 0.06, bevel=0.0),  # fore-grip under the rails
          G.rbox((0, -0.06, 0.07), (0.12, 0.3, 0.14), bevel=0.0, rot=(-22, 0, 0)),  # grip
          G.bar((0, 0.3, 0.2), (0, 0.24, 1.0), 0.1, 0.08, bevel=0.0),  # stock: top strut
          G.bar((0, 0.1, 0.2), (0, -0.16, 0.96), 0.1, 0.08, bevel=0.0),  # lower strut
          G.rbox((0, 0.04, 1.0), (0.14, 0.46, 0.07), bevel=0.0))  # butt plate
    g.add("chrome",
          *[G.rbox((0, yy, -1.0), (0.1, 0.045, 1.24), bevel=0.0) for yy in (y + 0.12, y - 0.12)],  # the rails
          *[G.rbox((0, y, z), (0.1, 0.29, 0.06), bevel=0.0) for z in (-0.46, -1.0, -1.56)],  # clamps
          G.rbox((0.11, 0.24, -0.2), (0.06, 0.16, 0.36), bevel=0.0),  # capacitor cradle
          G.rod((0, 0.405, 0.06), (0, 0.405, -0.34), 0.04, 6),  # scope tube
          G.rod((0, 0.33, -0.08), (0, 0.39, -0.08), 0.02, 4),
          G.rod((0, -0.0, -0.84), (0, -0.16, -0.94), 0.04, 4, top=0.2),  # claw under the fore-grip
          G.ring((0, 0.06, -0.06), 0.06, 0.015, 8, 4, axis="x"))  # trigger guard
    g.add("glow",
          *[G.rbox((0.058 * k, y, -1.0), (0.012, 0.05, 1.1), bevel=0.0) for k in (-1, 1)],  # plasma lines
          *[G.rod((0.145, yy, -0.06), (0.145, yy, -0.34), 0.03, 5) for yy in (0.19, 0.25, 0.31)],  # capacitor cells
          G.rbox((0, 0.12, 0.6), (0.02, 0.06, 0.62), bevel=0.0, rot=(-10, 0, 0)),  # stock light bar
          G.rod((0, 0.405, -0.34), (0, 0.405, -0.36), 0.036, 6),  # scope lens
          *[G.ring((0, y, z), 0.15, 0.018, 10, 3, axis="z") for z in (-1.18, -1.28, -1.38)])  # coil rings round the rails
    g.add("accent", *[G.rbox((0.056 * k, 0.29, 0.6), (0.01, 0.04, 0.5), bevel=0.0, rot=(4, 0, 0)) for k in (-1, 1)])


def build(lp):
    model = S.variant(
        lp, "RIFLE", "RAIL_RIFLE", "Rail Rifle",
        drop=[("wood", 0), ("wood", 1), ("wood", 2), ("wood", 3), ("dark", 0),
              ("steel", 0), ("steel", 2), ("steel", 3), ("steel", 4), ("steel", 6), ("steel", 7),
              ("brass", 0), ("brass", 1), ("brass", 2),
              ("leather", 0), ("leather", 1), ("leather", 2), ("leather", 3), ("accent", 0)],
        extra=extra,
        colors={"steel": (70, 74, 88), "plate": (30, 32, 44), "chrome": (138, 148, 166),
                "accent": (230, 60, 220), "glow": (0, 236, 255)},
    )
    model["batch"] = "11p3"
    model["meta"].update({"theme": "CYBER_RAPTOR", "premium": True})
    return model
