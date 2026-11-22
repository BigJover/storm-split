"""RIFLE_KINGS_CLAW - Hunting Rifle premium skin King's Claw (Tyrant King theme, PREMIUM_SKINS.md, batch
11p4): its own silhouette - a bone stock with a comb of teeth along its top and a crimson leather inlay
(accent), a fore-end built from rex vertebrae (spine discs with crimson pads between), a great curved claw
slung under the fore-end like a blade, gold trim bands, and a rex mouth round the muzzle (fangs top and
bottom, glowing red eyes and throat). A red rune runs down the stock's sides.

Receiver, barrel, bolt handle, trigger, guard and the `muzzle` piece are the base's; grip at (0, 0, 0).
Stock, grip (re-added lighter), fore-end, knob, rear sight, swivels, sling, barrel band and badge are dropped.
`glow` = Neon in game. Base: gun/RIFLE (variants/_skins.py), cap 864 with Belt Fed.
"""
# art-sources: _rifle.py variants/_skins.py variants/_tyrant.py

import importlib.util
import math
from pathlib import Path

_dir = Path(__file__).with_name("variants")
_spec = importlib.util.spec_from_file_location("_skins", _dir / "_skins.py")
S = importlib.util.module_from_spec(_spec)
_spec.loader.exec_module(S)
_spec = importlib.util.spec_from_file_location("_tyrant_gun", _dir / "_tyrant.py")
T = importlib.util.module_from_spec(_spec)
_spec.loader.exec_module(T)


def extra(g, G, D):
    w = 0.072
    bore = D.BORE
    # bone stock (a heavier, angular profile) + the lighter grip
    g.add("bone", G.slab([(0.14, 0.22), (0.5, 0.24), (1.0, 0.27), (1.03, -0.16), (0.94, -0.2), (0.3, -0.02), (0.14, 0.04)], -w, w, bevel=0.0),
          G.rbox((0, -0.06, 0.07), (0.12, 0.28, 0.14), bevel=0.0, rot=(-22, 0, 0)))
    g.add("bone", *[T.fang(G, (0, 0.24 + 0.006 * i, 0.3 + 0.15 * i), (0, 0.36 + 0.006 * i, 0.36 + 0.15 * i), 0.03) for i in range(4)])  # comb of teeth
    g.add("accent", *[G.rbox((x, 0.04, 0.62), (0.012, 0.18, 0.4), bevel=0.0) for x in (-w - 0.004, w + 0.004)])  # crimson inlays
    g.add("glow", *[G.rod((x, 0.0, 0.46), (x, 0.1, 0.84), 0.012, 3) for x in (-w - 0.01, w + 0.01)])
    g.add("dark", G.rbox((0, 0.04, 1.03), (0.15, 0.42, 0.05), bevel=0.0))  # butt pad
    g.add("gold", G.rbox((0, 0.04, 0.98), (0.155, 0.43, 0.03), bevel=0.0))
    # vertebrae fore-end: bone discs with crimson pads between, round the barrel's root
    zs = [-0.34 - 0.2 * i for i in range(4)]
    g.add("bone", *[G.rod((0, 0.16, z + 0.045), (0, 0.16, z - 0.05), 0.088, 5) for z in zs],
          *[T.fang(G, (0, 0.24, z), (0, 0.31, z + 0.04), 0.02) for z in zs[::2]])  # spines on top
    g.add("crimson2", G.rod((0, 0.16, -0.26), (0, 0.16, -1.0), 0.065, 6))
    g.add("gold", G.rod((0, 0.16, -1.02), (0, 0.16, -1.06), 0.09, 5))
    # the great claw under the fore-end
    g.add("bone", G.slab([(-0.36, 0.06), (-0.6, -0.02), (-0.86, -0.12), (-1.08, -0.2), (-1.2, -0.16), (-1.0, -0.1),
                          (-0.76, 0.0), (-0.56, 0.12), (-0.36, 0.14)], -0.035, 0.035, bevel=0.0))
    # the rex mouth round the muzzle
    T.jaw_muzzle(g, G, bore, D.TIP + 0.05, length=0.42, w=0.2, h=0.19, teeth=3, gape=7)


def build(lp):
    model = S.variant(
        lp, "RIFLE", "KINGS_CLAW", "King's Claw",
        drop=[("wood", 0), ("wood", 1), ("wood", 2), ("wood", 3), ("dark", 0),  # stock, wrist, grip, fore-end, butt pad
              ("steel", 3), ("steel", 4), ("steel", 6), ("steel", 7),  # knob, rear sight, swivels
              ("leather", 0), ("leather", 1), ("leather", 2), ("leather", 3), ("brass", 0), ("brass", 2), ("accent", 0)],
        extra=extra,
        colors={**T.COLORS, "steel": (70, 56, 58), "brass": (176, 140, 70), "dark": (52, 34, 32)},
    )
    model["batch"] = "11p4"
    model["meta"].update({"theme": "TYRANT_KING", "premium": True})
    return model
