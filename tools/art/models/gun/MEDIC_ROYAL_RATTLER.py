"""MEDIC_ROYAL_RATTLER - Lever-Action Carbine premium skin Royal Rattler (Tyrant King theme, PREMIUM_SKINS.md,
batch 11p4): its own silhouette - a bone stock carved with a small rex skull on its side (glowing eye), a
rattle of bone beads and fangs hanging from the stock's heel on a crimson cord, a fore-end of curved ribs
round the tube (a little ribcage) bound with a crimson healer's wrap (accent) and a glowing red vial set in
it, a lever loop shaped like a jawbone with teeth, gold trim bands, and a rex mouth round the muzzle.

Receiver, barrel, magazine tube, trigger and the `muzzle` piece are the base's (the brass receiver goes
bone-gold); grip at (0, 0, 0). Stock, fore-end, bandage, barrel bands, rear sight, cross, butt plate dropped.
`glow` = Neon in game. Base: gun/MEDIC (variants/_skins.py), cap 1,200 (no attachments).
"""
# art-sources: _medic.py variants/_skins.py variants/_tyrant.py

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
    w = 0.07
    bore = D.BORE
    # bone stock + butt band
    g.add("bone", G.slab([(0.2, 0.22), (0.98, 0.2), (1.02, -0.18), (0.92, -0.2), (0.3, 0.0), (0.2, 0.06)], -w, w, bevel=0.0))
    g.add("bone", G.rbox((0, 0.13, 0.16), (0.12, 0.17, 0.24), bevel=0.0, rot=(-12, 0, 0)))  # wrist (lighter)
    g.add("gold", G.rbox((0, 0.01, 0.99), (0.15, 0.4, 0.03), bevel=0.0))
    # the rex skull carved on the stock's left side, glowing eye
    g.add("bone2", G.ell((-w - 0.01, 0.06, 0.58), (0.02, 0.09, 0.11), 6, 3),
          G.rbox((-w - 0.01, 0.03, 0.42), (0.03, 0.09, 0.2), bevel=0.0, taper=(1.0, 0.7)),
          *[T.fang(G, (-w - 0.02, -0.01, z), (-w - 0.02, -0.06, z), 0.012) for z in (0.36, 0.42, 0.48)])
    g.add("glow", G.ell((-w - 0.025, 0.08, 0.53), (0.012, 0.025, 0.025), 4, 3))
    # the rattle: a crimson cord from the heel with bone beads and two fangs
    g.add("crimson2", G.rod((0, -0.18, 0.9), (0.02, -0.4, 0.86), 0.012, 4))
    g.add("bone", *[G.ell((0.01 * i, -0.24 - 0.06 * i, 0.89 - 0.008 * i), (0.04, 0.035, 0.04), 5, 3) for i in range(3)],
          *[T.fang(G, (0.02, -0.42, 0.86 + dz), (0.03, -0.56, 0.84 + dz), 0.022) for dz in (-0.03, 0.03)])
    # ribcage fore-end: bone ribs curving round the tube, crimson wrap + a glowing vial
    for z in (-0.36, -0.58, -0.8):
        g.add("bone", G.ring((0, 0.16, z), 0.08, 0.018, 6, 3, axis="z"))
    g.add("bone", G.rbox((0, 0.07, -0.58), (0.05, 0.03, 0.56), bevel=0.0))  # sternum
    g.add("accent", G.rod((0, 0.16, -0.5), (0, 0.16, -0.66), 0.074, 6))
    g.add("glow", G.rod((0.085, 0.13, -0.42), (0.085, 0.13, -0.74), 0.022, 4))
    g.add("gold", *[G.rod((0, 0.2, z + 0.02), (0, 0.2, z - 0.02), 0.1, 6) for z in (-0.88, -1.12)])
    # jawbone lever loop with teeth inside
    g.add("bone", G.ring((0, -0.01, 0.03), 0.09, 0.024, 6, 3, axis="x"),
          *[T.fang(G, (0, -0.09, z), (0, -0.04, z), 0.014) for z in (-0.02, 0.06)])
    # the rex mouth round the muzzle
    T.jaw_muzzle(g, G, bore, D.TIP + 0.05, length=0.38, w=0.19, h=0.19, teeth=3, gape=7)


def build(lp):
    model = S.variant(
        lp, "MEDIC", "ROYAL_RATTLER", "Royal Rattler",
        drop=[("wood", 0), ("wood", 1), ("wood", 2), ("dark", 0), ("steel", 2), ("steel", 3), ("steel", 4),
              ("cloth", 0), ("accent", 0), ("accent", 1), ("brass", 2)],
        extra=extra,
        colors={**T.COLORS, "steel": (70, 56, 58), "brass": (190, 160, 100), "wood": (196, 180, 150), "dark": (52, 34, 32)},
    )
    model["batch"] = "11p4"
    model["meta"].update({"theme": "TYRANT_KING", "premium": True})
    return model
