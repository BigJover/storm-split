"""PISTOL - the Tracker's Revolver (Config Heroes PISTOL `weapon`): a blued six-shooter with a
walnut grip, brass trigger guard, butt cap and front blade, the class-red medallion on the grip.
Variant: PISTOL_SCOPE (Marksman T3 `Scope`, HeroStats `scope`): a short brass-ringed scope on two
mounts over the top strap. Dual Pistols (Gunslinger T3, HeroStats `guns` 2) is a second copy of
PISTOL in the left hand (no extra model). Frame and conventions: _gun.py.
"""

import importlib.util
from pathlib import Path

_spec = importlib.util.spec_from_file_location("_gun", Path(__file__).with_name("_gun.py"))
G = importlib.util.module_from_spec(_spec)
_spec.loader.exec_module(G)

BORE = 0.25  # the bore's height above the grip point
TIP = -0.84  # the barrel's front
COLORS = {
    "wood": G.WOOD, "steel": G.STEEL, "brass": G.BRASS, "accent": G.ACCENT["PISTOL"], "glass": G.GLASS,
}
ENVELOPE = ((-0.2, -0.35, -1.0), (0.2, 0.62, 0.4))


def gun(g):
    steel = [
        G.rbox((0, 0.21, 0.13), (0.1, 0.26, 0.1), bevel=0.03),  # frame behind the cylinder
        G.rbox((0, 0.1, -0.05), (0.1, 0.1, 0.38), bevel=0.03),  # frame under the cylinder
        G.rod((0, BORE - 0.01, 0.075), (0, BORE - 0.01, -0.165), 0.112, 12, bevel=0.035),  # cylinder
        G.rod((0, BORE, -0.17), (0, BORE, TIP), 0.046, 10),  # barrel
        G.rbox((0, BORE - 0.06, -0.42), (0.06, 0.08, 0.46), bevel=0.025),  # underlug
        G.rbox((0, 0.33, -0.04), (0.09, 0.05, 0.36), bevel=0.02),  # top strap
        G.rbox((0, 0.35, 0.15), (0.05, 0.08, 0.08), bevel=0.02, rot=(-35, 0, 0)),  # hammer spur
        G.rbox((0, 0.04, -0.1), (0.03, 0.09, 0.03), bevel=0.01, rot=(15, 0, 0)),  # trigger
    ]
    g.add("steel", *steel)
    g.add("steel", G.muzzle_ring((0, BORE, TIP - 0.01), 0.05), piece="muzzle", role="muzzle")
    g.add("wood", G.rbox((0, -0.03, 0.08), (0.15, 0.4, 0.17), bevel=0.06, segments=2, rot=(-18, 0, 0)))
    g.add("brass",
          G.ell((0, -0.22, 0.14), (0.08, 0.035, 0.095), 10, 4, rot=(-18, 0, 0)),  # butt cap
          G.ring((0, 0.05, -0.1), 0.065, 0.015, 8, 4, axis="x"),  # trigger guard
          G.rbox((0, 0.31, TIP + 0.05), (0.025, 0.07, 0.06), bevel=0.01))  # front blade
    g.add("accent", *[G.ell((sx * 0.077, -0.0, 0.08), (0.012, 0.05, 0.04), 8, 3) for sx in (-1, 1)])


def scope(g):
    y = 0.47
    g.add("steel",
          G.rod((0, y, 0.08), (0, y, -0.5), 0.04, 8),  # tube
          G.rod((0, y, -0.48), (0, y, -0.64), 0.04, 8, top=1.45),  # objective bell
          G.rod((0, y, 0.2), (0, y, 0.06), 0.05, 8, top=0.8),  # eyepiece
          G.rbox((0, 0.395, -0.06), (0.05, 0.12, 0.07), bevel=0.015),  # rear mount (top strap)
          G.rbox((0, 0.365, -0.44), (0.05, 0.18, 0.07), bevel=0.015))  # front mount (barrel)
    g.add("brass",
          G.rod((0, y, -0.03), (0, y, -0.09), 0.052, 8),  # mount rings
          G.rod((0, y, -0.41), (0, y, -0.47), 0.052, 8),
          G.rod((0, y, -0.62), (0, y, -0.66), 0.064, 8))  # bell rim
    g.add("glass", G.ell((0, y, -0.665), (0.05, 0.05, 0.012), 8, 3),
          G.ell((0, y, 0.205), (0.04, 0.04, 0.01), 8, 3))


def build(lp, variant=None):
    g = G.Gun(lp, ENVELOPE, 1200 if variant is None else 400)
    if variant == "scope":
        scope(g)
        base = G.Gun(lp, ENVELOPE, 1200)
        gun(base)
        g.base(base)
        meta = {"gun": "PISTOL", "attach": "PISTOL", "shows": "HeroStats.scope (Marksman T3 Scope)"}
    else:
        gun(g)
        meta = {"gun": "PISTOL", "grip": [0, 0, 0], "muzzle": [0, BORE, TIP - 0.01],
                "dual": "guns >= 2: a second PISTOL in the left hand"}
    return g.model("11c2", "gun", COLORS, meta)
