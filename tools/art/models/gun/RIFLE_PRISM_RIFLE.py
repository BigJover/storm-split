"""RIFLE_PRISM_RIFLE - Hunting Rifle premium skin Prism Rifle (Geode theme, PREMIUM_SKINS.md, batch 11p6): its own
silhouette - a long hexagonal amethyst crystal barrel sleeve held in three rough stone collars, a big glowing
triangular PRISM CORE set in an open stone housing over the fore-end, a prism sight (a long glowing crystal laid
along the top of the receiver), crystal shards breaking out of both sides of the fore-end (amethyst + teal), and
an angular faceted stone stock with a split geode on each side and a crystal comb.

Receiver, barrel, bolt handle, trigger, guard and the `muzzle` piece are the base's; grip at (0, 0, 0).
Stock, grip (re-added in stone), fore-end, knob, rear sight, swivels, sling, barrel band, bead and badge are dropped.
`glow` = Neon in game. Base: gun/RIFLE (variants/_skins.py), cap 864 with Belt Fed.
"""
# art-sources: _rifle.py variants/_skins.py variants/_geode.py

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
    bore = D.BORE
    # angular stone stock + grip
    g.add("rock", G.slab([(0.14, 0.22), (0.56, 0.26), (1.0, 0.3), (1.03, -0.18), (0.9, -0.22), (0.3, -0.02), (0.14, 0.04)], -w, w, bevel=0.0),
          G.rbox((0, -0.06, 0.07), (0.12, 0.28, 0.14), bevel=0.0, rot=(-22, 0, 0)))
    for k in (-1, 1):
        X.geode_disc(g, G, ((w + 0.005) * k, 0.06, 0.64), "x", 0.11)
    g.add("crystal", *[X.crystal(G, (0, 0.24 + 0.01 * i, 0.4 + 0.18 * i), (0, 0.38 + 0.01 * i, 0.46 + 0.18 * i), 0.03, 5) for i in range(3)])
    g.add("rock2", G.rbox((0, 0.04, 1.03), (0.16, 0.46, 0.05), bevel=0.0))
    # fore-end: a stone block under the barrel's root with the prism core housed above it
    g.add("rock", G.rbox((0, 0.12, -0.6), (0.15, 0.14, 0.62), bevel=0.0, taper=(0.8, 0.8)))
    g.add("glow", X.prism(G, (0, 0.335, -0.36), (0, 0.335, -0.82), 0.11, 3))  # the prism core (triangular)
    g.add("rock", *[X.prism(G, (0, 0.33, z + 0.03), (0, 0.33, z - 0.03), 0.105, 6) for z in (-0.33, -0.85)],
          )
    # shards breaking out of the fore-end's sides
    g.add("crystal", *[X.crystal(G, (0.06 * k, 0.1, z), (0.26 * k, -0.04, z + 0.16), 0.045, 5) for k in (-1, 1) for z in (-0.48, -0.74)])
    g.add("teal", *[X.crystal(G, (0.06 * k, 0.14, -0.62), (0.28 * k, 0.26, -0.46), 0.04, 5) for k in (-1, 1)])
    # the crystal barrel sleeve and its stone collars
    g.add("accent", X.prism(G, (0, bore, -0.92), (0, bore, -1.6), 0.07, 6))
    g.add("rock", *[X.prism(G, (0, bore, z + 0.03), (0, bore, z - 0.03), 0.085, 6) for z in (-0.95, -1.62)])
    g.add("glow", *[G.rod(((w + 0.006) * k, 0.22, 0.2), ((w + 0.006) * k, 0.26, 0.5), 0.014, 3) for k in (-1, 1)])
    # prism sight
    g.add("glow", X.crystal(G, (0, 0.36, 0.08), (0, 0.38, -0.28), 0.035, 4, point=0.25))


def build(lp):
    model = S.variant(
        lp, "RIFLE", "PRISM_RIFLE", "Prism Rifle",
        drop=[("wood", 0), ("wood", 1), ("wood", 2), ("wood", 3), ("dark", 0),
              ("steel", 3), ("steel", 4), ("steel", 6), ("steel", 7),
              ("leather", 0), ("leather", 1), ("leather", 2), ("leather", 3), ("brass", 0), ("brass", 2), ("accent", 0)],
        move=[("steel", 0, "rock2")],  # receiver in dark stone
        extra=extra,
        colors={**X.COLORS, "steel": (70, 66, 80), "brass": (176, 150, 200)},
    )
    model["batch"] = "11p6"
    model["meta"].update({"theme": "GEODE", "premium": True})
    return model
