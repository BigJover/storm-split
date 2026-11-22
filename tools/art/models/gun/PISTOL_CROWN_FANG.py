"""PISTOL_CROWN_FANG - Revolver premium skin Crown Fang (Tyrant King theme, PREMIUM_SKINS.md, batch 11p4):
its own silhouette - the barrel runs out of a small rex mouth (bone upper jaw over it, lower jaw under it,
fangs top and bottom, glowing red eyes and throat), a crimson cylinder bound with two gold bands, a grip
carved from one great curved fang with a gold cap and a red gem at its foot, a row of small teeth along
the top strap like a crown.

Frame, top strap, barrel, trigger, guard and the `muzzle` piece are the base's; grip at (0, 0, 0).
Cylinder, underlug, hammer, walnut grip, butt cap, front blade and medallions are dropped.
`glow` = Neon in game. Base: gun/PISTOL (variants/_skins.py), cap 880 with the Scope.
"""
# art-sources: _pistol.py variants/_skins.py variants/_tyrant.py

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
    bore = D.BORE
    cy = bore - 0.01
    # crimson cylinder (accent = the skin colour) with two gold bands
    g.add("accent", G.rod((0, cy, 0.075), (0, cy, -0.165), 0.108, 8))
    g.add("gold", *[G.rod((0, cy, z + 0.012), (0, cy, z - 0.012), 0.114, 8) for z in (0.05, -0.14)])
    # the rex mouth round the front of the barrel
    T.jaw_muzzle(g, G, bore, D.TIP + 0.05, length=0.4, w=0.17, h=0.2, teeth=3)
    # crown of small teeth along the top strap
    g.add("bone", *[T.fang(G, (0, 0.355, z), (0, 0.45, z - 0.03), 0.022) for z in (0.08, -0.02, -0.12)])
    # spiked hammer (a fang)
    g.add("bone", T.fang(G, (0, 0.3, 0.12), (0, 0.42, 0.24), 0.04))
    # the fang grip: a curved ivory fang, gold cap, red gem at its foot
    g.add("bone", G.slab([(0.0, 0.17), (0.16, 0.19), (0.2, 0.02), (0.24, -0.16), (0.2, -0.27), (0.12, -0.22),
                          (0.05, -0.06), (-0.03, 0.08)], -0.065, 0.065, bevel=0.0))
    g.add("gold", G.rod((0, 0.02, 0.135), (0, -0.04, 0.155), 0.075, 6))
    g.add("glow", G.ell((0, -0.25, 0.17), (0.035, 0.035, 0.035), 5, 3),
          *[G.rod((0.067 * k, 0.12, 0.11), (0.067 * k, -0.12, 0.17), 0.012, 3) for k in (-1, 1)])  # a rune down each side


def build(lp):
    model = S.variant(
        lp, "PISTOL", "CROWN_FANG", "Crown Fang",
        drop=[("steel", 2), ("steel", 4), ("steel", 6),  # cylinder, underlug, hammer
              ("wood", 0), ("brass", 0), ("brass", 2), ("accent", 0), ("accent", 1)],  # grip, butt cap, blade, medallions
        extra=extra,
        colors={**T.COLORS, "steel": (70, 56, 58), "brass": (176, 140, 70)},
    )
    model["batch"] = "11p4"
    model["meta"].update({"theme": "TYRANT_KING", "premium": True})
    return model
