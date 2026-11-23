"""MEDIC_CRYSTAL_CARBINE - Lever-Action Carbine premium skin Crystal Carbine (Geode theme, PREMIUM_SKINS.md, batch
11p6): its own silhouette - a stone carbine for the gem-healer: a faceted stone stock with a split geode on each
side and a rose-quartz cross inlaid on its left, a stone receiver, a fore-end of hexagonal rose-quartz crystal
round the magazine tube, a glowing healing crystal held upright in a stone cradle over the receiver (with two
small rose shards beside it), a little rose-quartz druse hanging under the fore-end and stone barrel bands.

Barrel, magazine tube, lever, trigger and the `muzzle` piece are the base's; grip at (0, 0, 0). Stock, wrist,
fore-end, butt plate, bandage, rear sight, saddle ring, bead and cross are dropped; the receiver and bands turn
to stone. `glow` = Neon in game. Base: gun/MEDIC (variants/_skins.py), cap 1,200 (no attachments).
"""
# art-sources: _medic.py variants/_skins.py variants/_geode.py

import importlib.util
from pathlib import Path

_dir = Path(__file__).with_name("variants")
_spec = importlib.util.spec_from_file_location("_skins", _dir / "_skins.py")
S = importlib.util.module_from_spec(_spec)
_spec.loader.exec_module(S)
_spec = importlib.util.spec_from_file_location("_geode_gun", _dir / "_geode.py")
X = importlib.util.module_from_spec(_spec)
_spec.loader.exec_module(X)


def extra(g, G, D):
    w = 0.075
    # faceted stone stock + wrist, split geodes, the rose cross
    g.add("rock", G.slab([(0.2, 0.22), (0.98, 0.2), (1.02, -0.17), (0.92, -0.2), (0.3, 0.0), (0.2, 0.06)], -w, w, bevel=0.0),
          G.rbox((0, 0.13, 0.16), (0.12, 0.17, 0.24), bevel=0.0, rot=(-12, 0, 0)))
    for k in (-1, 1):
        X.geode_disc(g, G, ((w + 0.004) * k, 0.03, 0.78), "x", 0.09)
    g.add("rose", G.rbox((-w - 0.01, 0.03, 0.5), (0.02, 0.2, 0.07), bevel=0.0), G.rbox((-w - 0.01, 0.03, 0.5), (0.02, 0.07, 0.2), bevel=0.0))
    g.add("rock2", G.rbox((0, 0.02, 1.02), (0.16, 0.38, 0.05), bevel=0.0))
    # rose-quartz fore-end round the tube: a chunky hexagonal crystal
    g.add("accent", X.prism(G, (0, 0.15, -0.3), (0, 0.15, -0.96), 0.1, 6))
    # the healing crystal laid along the top in its stone cradle
    g.add("rock", G.rbox((0, 0.33, -0.1), (0.12, 0.05, 0.34), bevel=0.0),
          *[G.rbox((0.06 * k, 0.37, -0.1), (0.025, 0.07, 0.2), bevel=0.0) for k in (-1, 1)])
    g.add("glow", X.crystal(G, (0, 0.39, 0.1), (0, 0.39, -0.36), 0.05, 6, point=0.3))
    g.add("rose", *[X.crystal(G, (0.05 * k, 0.36, 0.02), (0.1 * k, 0.44, 0.08), 0.028, 5) for k in (-1, 1)])
    # the rose druse hanging under the fore-end, a glowing heart in it
    g.add("rose", *[X.crystal(G, (0.0, 0.06, z), (0.14 * dx, -0.24 + 0.06 * abs(dx), z + dz), 0.05, 5)
                    for z, dx, dz in ((-0.5, -1, 0.08), (-0.62, 1, -0.04), (-0.74, -0.5, -0.1), (-0.44, 0.6, 0.12))])
    g.add("glow", X.crystal(G, (0, 0.06, -0.58), (0, -0.32, -0.6), 0.06, 6))


def build(lp):
    model = S.variant(
        lp, "MEDIC", "CRYSTAL_CARBINE", "Crystal Carbine",
        drop=[("wood", 0), ("wood", 1), ("wood", 2), ("dark", 0), ("cloth", 0), ("steel", 4),
              ("brass", 1), ("brass", 2), ("accent", 0), ("accent", 1)],
        move=[("brass", 0, "rock2"), ("steel", 2, "rock"), ("steel", 3, "rock")],
        extra=extra,
        colors={**X.COLORS, "accent": (236, 150, 190), "steel": (70, 66, 80)},
    )
    model["batch"] = "11p6"
    model["meta"].update({"theme": "GEODE", "premium": True})
    return model
