"""RIFLE_ENGRAVED_GOLD - Hunting Rifle skin Engraved Gold (600K Amber, Gold Rush Bundle): a
presentation rifle. Gold engraved side plates on the receiver, a gold barrel band and bolt knob,
gold inlays on both sides of a dark burl stock; the sling is off (a rifle for the wall). `accent`
(the skin's gold, Metal) = plates, inlays, knob. Base: gun/RIFLE (variants/_skins.py).
"""
# art-sources: _rifle.py variants/_skins.py

import importlib.util
from pathlib import Path

_spec = importlib.util.spec_from_file_location("_skins", Path(__file__).with_name("variants") / "_skins.py")
S = importlib.util.module_from_spec(_spec)
_spec.loader.exec_module(S)


def extra(g, G, D):
    g.add("wood", G.rbox((0, -0.06, 0.07), (0.12, 0.28, 0.14), bevel=0.045, segments=1, rot=(-22, 0, 0)))  # grip
    g.add("accent",
          *[G.rbox((0.068 * k, 0.26, -0.08), (0.012, 0.13, 0.46), bevel=0.005, segments=1) for k in (-1, 1)],  # side plates
          G.ell((0.155, 0.265, 0.12), (0.035, 0.035, 0.035), 6, 3),  # bolt knob
          *[G.ell((0.072 * k, 0.07, 0.62), (0.008, 0.09, 0.2), 6, 3) for k in (-1, 1)])  # stock inlays
    g.add("brass", G.rod((0, 0.2, -1.3), (0, 0.2, -1.36), 0.07, 8))  # a second barrel band


def build(lp):
    return S.variant(
        lp, "RIFLE", "ENGRAVED_GOLD", "Engraved Gold",
        drop=[("wood", 2), ("steel", 3), ("steel", 6), ("steel", 7), ("leather", 0), ("leather", 1), ("leather", 2),
              ("leather", 3), ("accent", 0)],  # grip, knob, swivels, sling, badge
        extra=extra,
        colors={"wood": (92, 48, 30), "steel": (40, 42, 52), "brass": (226, 182, 70), "accent": (215, 175, 60)},
    )
