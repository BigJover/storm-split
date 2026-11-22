"""SHOTGUN_SCATTER_BYTE - the Brush Beater's Shotgun, premium skin Scatter Byte (Cyber Raptor theme,
PREMIUM_SKINS.md, batch 11p3, #462: its own silhouette, element electric / digital glitch). A chunky
"pixel" blaster built from stepped blocks, like a sprite come to life:

  * a heavy square barrel shroud with a stepped pixel top and a grid of glowing pixel vents on
    each side; a flared square emitter collar behind the muzzle
  * a blocky gunmetal pump with glowing grip lines
  * a stepped pixel stock (three blocks stepping down) with glowing pixels
  * four glowing "byte" cubes in a side saddle on the left (where the shells were, `accent` frame)
  * a big raptor sickle claw hanging under the shroud like a bayonet (behind the muzzle), glowing edge

Barrel, trigger and the `muzzle` piece are the base's; grip at (0, 0, 0). `glow` = Neon in game.
Base: gun/SHOTGUN (variants/_skins.py), cap 868 with Double Barrel + the drum.
"""
# art-sources: _shotgun.py variants/_skins.py

import importlib.util
from pathlib import Path

_spec = importlib.util.spec_from_file_location("_skins", Path(__file__).with_name("variants") / "_skins.py")
S = importlib.util.module_from_spec(_spec)
_spec.loader.exec_module(S)


def extra(g, G, D):
    y = D.BORE
    g.add("plate",
          G.rbox((0, 0.2, -0.06), (0.17, 0.28, 0.56), bevel=0.0),  # receiver
          G.rbox((0, y + 0.01, -0.82), (0.2, 0.2, 0.96), bevel=0.0),  # barrel shroud
          *[G.rbox((0, y + 0.13, z), (0.12, 0.06, 0.16), bevel=0.0) for z in (-0.5, -0.82, -1.14)],  # stepped pixel top
          G.rbox((0, -0.06, 0.08), (0.13, 0.28, 0.15), bevel=0.0, rot=(-22, 0, 0)),  # grip
          # stepped pixel stock
          G.rbox((0, 0.18, 0.37), (0.14, 0.24, 0.34), bevel=0.0),
          G.rbox((0, 0.1, 0.64), (0.15, 0.34, 0.32), bevel=0.0),
          G.rbox((0, 0.03, 0.91), (0.16, 0.44, 0.3), bevel=0.0))
    g.add("chrome",
          G.rbox((0, y, -1.38), (0.28, 0.28, 0.1), bevel=0.0),  # emitter collar
          G.rbox((0, 0.08, -0.74), (0.2, 0.14, 0.4), bevel=0.0),  # pump
          G.ring((0, 0.05, -0.06), 0.06, 0.015, 8, 4, axis="x"),  # trigger guard
          G.slab([(-1.0, 0.16), (-1.22, 0.16), (-1.34, 0.0), (-1.38, -0.22), (-1.28, -0.08), (-1.1, 0.06)], -0.025, 0.025, bevel=0.0))  # sickle claw under the shroud
    vents = [G.rbox((0.102 * k, y + yy, z), (0.012, 0.045, 0.045), bevel=0.0)
             for k in (-1, 1) for yy in (-0.04, 0.04) for z in (-0.5, -0.62, -0.74, -0.86, -0.98, -1.1)]
    g.add("glow", *vents,
          G.rbox((0, y, -1.435), (0.22, 0.22, 0.012), bevel=0.0),  # emitter face round the bore
          *[G.rbox((0.101 * k, 0.08, -0.74), (0.01, 0.03, 0.34), bevel=0.0) for k in (-1, 1)],  # pump grip lines
          *[G.rbox((0.081 * k, 0.1, 0.64), (0.01, 0.06, 0.06), bevel=0.0) for k in (-1, 1)],  # stock pixels
          *[G.rbox((0.081 * k, 0.0, 0.92), (0.01, 0.06, 0.06), bevel=0.0) for k in (-1, 1)],
          *[G.rbox((-0.13, 0.22, z), (0.06, 0.06, 0.06), bevel=0.0) for z in (-0.18, -0.08, 0.02, 0.12)],  # byte cubes
          G.rod((0, 0.16, -1.23), (0, 0.0, -1.355), 0.02, 4), G.rod((0, 0.0, -1.355), (0, -0.21, -1.385), 0.018, 4))  # the claw's glowing edge
    g.add("accent", G.rbox((-0.1, 0.22, -0.03), (0.02, 0.1, 0.4), bevel=0.0))  # the saddle's frame


def build(lp):
    model = S.variant(
        lp, "SHOTGUN", "SCATTER_BYTE", "Scatter Byte",
        drop=[("wood", 0), ("wood", 1), ("wood", 2), ("wood", 3), ("dark", 0), ("dark", 1),
              ("steel", 0), ("steel", 2), ("steel", 4),
              ("brass", 0), ("brass", 1), ("brass", 2), ("brass", 3),
              ("accent", 0), ("accent", 1), ("accent", 2), ("accent", 3)],
        extra=extra,
        colors={"steel": (70, 74, 88), "plate": (30, 32, 44), "chrome": (138, 148, 166),
                "accent": (230, 60, 220), "glow": (0, 236, 255)},
    )
    model["batch"] = "11p3"
    model["meta"].update({"theme": "CYBER_RAPTOR", "premium": True})
    return model
