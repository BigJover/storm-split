"""MEDIC_BRASS_SADDLE - Carbine skin Brass Saddle (250K Amber, Brass Gear Bundle): a saddle-ring
carbine dressed in brass. Brass butt plate and barrel bands, a big saddle ring with a second
ring hanging from it, a laced leather cheek piece on the stock with brass tacks. `accent` (the
skin's brass, Metal) = plate, bands, rings, tacks. Base: gun/MEDIC (variants/_skins.py).
"""
# art-sources: _medic.py variants/_skins.py

import importlib.util
from pathlib import Path

_spec = importlib.util.spec_from_file_location("_skins", Path(__file__).with_name("variants") / "_skins.py")
S = importlib.util.module_from_spec(_spec)
_spec.loader.exec_module(S)


def extra(g, G, D):
    g.add("accent",
          G.ring((-0.085, 0.18, 0.05), 0.055, 0.014, 10, 4, axis="x"),  # saddle ring
          G.ring((-0.095, 0.06, 0.05), 0.045, 0.012, 10, 4, axis="x"),  # the hanging ring
          *[G.ell((-0.074, y, z), (0.012, 0.022, 0.022), 6, 3) for y, z in
            ((0.13, 0.42), (0.11, 0.6), (0.09, 0.78), (-0.05, 0.5), (-0.07, 0.7))])  # tacks
    g.add("leather", G.rbox((-0.06, 0.04, 0.6), (0.03, 0.22, 0.42), bevel=0.012, segments=1))  # cheek piece
    g.add("dark", *[G.rbox((-0.077, 0.04, z), (0.006, 0.2, 0.012), bevel=0.0, segments=0) for z in (0.48, 0.6, 0.72)])  # lacing


def build(lp):
    return S.variant(
        lp, "MEDIC", "BRASS_SADDLE", "Brass Saddle",
        drop=[("brass", 1), ("accent", 0), ("accent", 1)],  # small saddle ring, the green cross
        move=[("dark", 0, "accent"), ("steel", 2, "accent"), ("steel", 3, "accent")],  # butt plate, bands
        extra=extra,
        colors={"accent": (180, 140, 60), "leather": (110, 70, 40), "wood": (120, 74, 42)},
    )
