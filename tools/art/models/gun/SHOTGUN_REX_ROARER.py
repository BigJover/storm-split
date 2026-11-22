"""SHOTGUN_REX_ROARER - Shotgun premium skin Rex Roarer (Tyrant King theme, PREMIUM_SKINS.md, batch 11p4):
its own silhouette - the whole front is a roaring rex head: barrel and magazine tube run out of a wide,
gaping bone mouth (big fangs top and bottom, a glowing red throat, glowing eyes under heavy brows); the
pump is a stack of rex vertebrae with crimson wraps (accent) between; a row of dorsal spines along the
receiver; a bone stock wrapped in crimson leather with a fringe of teeth under it and a gold butt band.

Receiver, barrel, magazine tube, trigger, guard, tube cap and the `muzzle` piece are the base's; grip at
(0, 0, 0). Stock, pump + groove, side saddle (plate, rim, shells) and bead are dropped.
`glow` = Neon in game. Base: gun/SHOTGUN (variants/_skins.py), cap 868 with both attachments.
"""
# art-sources: _shotgun.py variants/_skins.py variants/_tyrant.py

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
    w = 0.08
    # the roaring head: a wide gaping mouth round barrel + tube, eyes under heavy brows
    mid = 0.19
    T.jaw_muzzle(g, G, mid, D.TIP + 0.06, length=0.56, w=0.3, h=0.26, teeth=3, eyes=False, hump=False, gape=11)
    ez = D.TIP + 0.5
    g.add("bone2", G.rbox((0, 0.37, ez), (0.3, 0.07, 0.22), bevel=0.01))  # brow shelf
    g.add("glow", *[G.ell((x * 0.15, 0.33, ez), (0.02, 0.04, 0.05), 4, 3) for x in (-1, 1)])
    # vertebrae pump: bone discs, crimson wraps between
    g.add("bone", *[G.rod((0, 0.12, z + 0.04), (0, 0.12, z - 0.04), 0.098, 5) for z in (-0.58, -0.76, -0.94)],
          )
    g.add("accent", G.rod((0, 0.12, -0.54), (0, 0.12, -0.98), 0.084, 5))
    # dorsal spines along the receiver
    g.add("bone", *[T.fang(G, (0, 0.31, z), (0, 0.41, z + 0.06), 0.03) for z in (0.1, -0.14)])
    # bone stock wrapped in crimson, teeth fringe under it, gold butt band
    g.add("bone", G.slab([(0.18, 0.25), (0.96, 0.22), (1.0, -0.17), (0.92, -0.21), (0.3, 0.0), (0.18, 0.06)], -w, w, bevel=0.0))
    g.add("accent", *[G.rbox((0, 0.1 - 0.02 * i, 0.42 + 0.17 * i), (0.17, 0.3, 0.06), bevel=0.0, rot=(-14, 0, 0)) for i in range(2)])
    g.add("bone2", *[T.fang(G, (0, -0.07 - 0.065 * i, 0.46 + 0.14 * i), (0, -0.16 - 0.065 * i, 0.43 + 0.14 * i), 0.026) for i in range(3)])
    g.add("bone", G.rbox((0, -0.05, 0.08), (0.13, 0.28, 0.15), bevel=0.0, rot=(-22, 0, 0)))  # grip (lighter)
    g.add("gold", G.rbox((0, 0.03, 0.97), (0.17, 0.4, 0.03), bevel=0.0))
    g.add("glow", *[G.rod((x, 0.17, 0.76), (x, -0.08, 0.9), 0.012, 3) for x in (-w - 0.006, w + 0.006)])


def build(lp):
    model = S.variant(
        lp, "SHOTGUN", "REX_ROARER", "Rex Roarer",
        drop=[("wood", 0), ("wood", 2), ("wood", 3), ("dark", 1), ("steel", 4), ("brass", 2), ("brass", 3),
              ("accent", 0), ("accent", 1), ("accent", 2), ("accent", 3)],
        extra=extra,
        colors={**T.COLORS, "steel": (70, 56, 58), "brass": (176, 140, 70), "wood": (196, 180, 150), "dark": (52, 34, 32)},
    )
    model["batch"] = "11p4"
    model["meta"].update({"theme": "TYRANT_KING", "premium": True})
    return model
