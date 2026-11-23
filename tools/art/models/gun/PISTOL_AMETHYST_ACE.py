"""PISTOL_AMETHYST_ACE - Revolver premium skin Amethyst Ace (Geode theme, PREMIUM_SKINS.md, batch 11p6): its own
silhouette - a hexagonal amethyst crystal barrel (faceted, sharp) running out of a rough stone frame, a glowing
prism core turning where the cylinder was (caged by two stone collars), a crest of three crystals standing on
the top strap like a sight, a chunky faceted stone grip with a split geode on each side (a glowing gem bed in a
stone rim), a teal crystal hammer spur.

Frame, top strap, barrel, trigger, guard and the `muzzle` piece are the base's; grip at (0, 0, 0).
Cylinder, underlug, hammer, walnut grip, butt cap, front blade and medallions are dropped.
`glow` = Neon in game. Base: gun/PISTOL (variants/_skins.py), cap 880 with the Scope.
"""
# art-sources: _pistol.py variants/_skins.py variants/_geode.py

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
    bore = D.BORE
    cy = bore - 0.01
    # the prism core where the cylinder was, caged by two stone collars
    g.add("glow", X.prism(G, (0, cy, 0.05), (0, cy, -0.14), 0.135, 6))
    g.add("rock", *[X.prism(G, (0, cy, z + 0.02), (0, cy, z - 0.02), 0.11, 6) for z in (0.075, -0.165)])
    # the crystal barrel: a hexagonal amethyst sleeve over the steel barrel, a pointed collar at its front
    g.add("accent", X.prism(G, (0, bore, -0.18), (0, bore, -0.74), 0.075, 6))
    g.add("glow", *[G.rod((0.0, bore + 0.077, z), (0.0, bore + 0.077, z - 0.18), 0.02, 3) for z in (-0.24, -0.48)])
    g.add("rock", X.prism(G, (0, bore, -0.72), (0, bore, -0.8), 0.088, 6))
    # crest of crystals on the top strap (a sight)
    g.add("glow", X.crystal(G, (0, 0.34, -0.04), (0, 0.56, -0.12), 0.04, 5))
    g.add("crystal", *[X.crystal(G, (0.0, 0.34, z), (0.04 * s, 0.48, z - 0.06), 0.03, 5) for z, s in ((0.06, 1), (-0.14, -1))])
    # teal crystal hammer spur
    g.add("teal", X.crystal(G, (0, 0.3, 0.12), (0, 0.42, 0.26), 0.035, 5))
    # faceted stone grip with a split geode on each side
    g.add("rock", X.rock(G, (0, -0.06, 0.1), (0.085, 0.24, 0.11), rot=(-18, 0, 0), segments=6, rings=4))
    for k in (-1, 1):
        X.geode_disc(g, G, (0.08 * k, -0.06, 0.1), "x", 0.07)


def build(lp):
    model = S.variant(
        lp, "PISTOL", "AMETHYST_ACE", "Amethyst Ace",
        drop=[("steel", 2), ("steel", 4), ("steel", 6),  # cylinder, underlug, hammer
              ("wood", 0), ("brass", 0), ("brass", 2), ("accent", 0), ("accent", 1)],
        move=[("steel", 0, "rock"), ("steel", 1, "rock"), ("steel", 5, "rock2")],  # frame + top strap in stone
        extra=extra,
        colors={**X.COLORS, "steel": (70, 66, 80), "brass": (176, 150, 200)},
    )
    model["batch"] = "11p6"
    model["meta"].update({"theme": "GEODE", "premium": True})
    return model
