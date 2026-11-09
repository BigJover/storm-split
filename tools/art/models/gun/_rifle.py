"""RIFLE - the Big Game Hunter's Hunting Rifle (Config Heroes RIFLE `weapon`): a bolt-action
walnut-stocked rifle, blued receiver and long barrel, brass barrel band, trigger guard and bead,
a leather sling hung from two swivels, the class-yellow badge on the butt.
Variant: RIFLE_BELT (Heavy T3 `Belt Fed`, HeroStats `beltFed`; Drum Mag / Spin-Up live on the same
path): a steel drum under the fore-end with a brass cartridge belt feeding the receiver's left.
Frame and conventions: _gun.py.
"""

import importlib.util
from pathlib import Path

_spec = importlib.util.spec_from_file_location("_gun", Path(__file__).with_name("_gun.py"))
G = importlib.util.module_from_spec(_spec)
_spec.loader.exec_module(G)

BORE = 0.25
TIP = -1.72
COLORS = {
    "wood": G.WOOD, "steel": G.STEEL, "brass": G.BRASS, "accent": G.ACCENT["RIFLE"],
    "leather": G.LEATHER, "dark": G.DARK,
}
ENVELOPE = ((-0.3, -0.62, -1.9), (0.3, 0.45, 1.1))


def gun(g):
    w = 0.07  # the stock's half width
    g.add("wood",
          G.slab([(0.16, 0.21), (0.98, 0.23), (1.0, -0.14), (0.92, -0.18), (0.3, -0.01), (0.16, 0.04)], -w, w, bevel=0.035, segments=1),
          G.rbox((0, 0.14, 0.06), (0.13, 0.17, 0.26), bevel=0.04),  # wrist
          G.rbox((0, -0.06, 0.07), (0.12, 0.28, 0.14), bevel=0.045, segments=2, rot=(-22, 0, 0)),  # pistol grip
          G.slab([(-0.22, 0.2), (-1.0, 0.2), (-1.06, 0.13), (-0.98, 0.06), (-0.22, 0.03)], -0.065, 0.065, bevel=0.03, segments=1))  # fore-end
    g.add("dark", G.rbox((0, 0.04, 1.0), (0.15, 0.4, 0.05), bevel=0.02, rot=(-3, 0, 0)))  # butt pad
    g.add("steel",
          G.rbox((0, 0.26, -0.08), (0.13, 0.15, 0.52), bevel=0.04, segments=1),  # receiver
          G.rod((0, BORE, -0.3), (0, BORE, TIP), 0.054, 10, top=0.85),  # barrel
          G.rod((0.02, 0.29, 0.12), (0.14, 0.27, 0.12), 0.018, 6),  # bolt handle
          G.ell((0.155, 0.265, 0.12), (0.035, 0.035, 0.035), 8, 4),  # bolt knob
          G.rbox((0, 0.31, -0.45), (0.06, 0.05, 0.08), bevel=0.015),  # rear sight
          G.rbox((0, 0.04, -0.06), (0.03, 0.09, 0.03), bevel=0.01, rot=(15, 0, 0)),  # trigger
          G.rod((0.06, -0.06, 0.74), (0.1, -0.06, 0.74), 0.03, 6),  # sling swivels (right side)
          G.rod((0.055, 0.1, -0.86), (0.1, 0.1, -0.86), 0.03, 6))
    g.add("steel", G.muzzle_ring((0, BORE, TIP - 0.01), 0.05), piece="muzzle", role="muzzle")
    g.add("brass",
          G.rod((0, 0.17, -0.82), (0, 0.17, -0.9), 0.1, 10),  # barrel band
          G.ring((0, 0.06, -0.06), 0.06, 0.015, 8, 4, axis="x"),  # trigger guard
          G.ell((0, 0.3, TIP + 0.05), (0.022, 0.03, 0.022), 6, 3))  # bead
    g.add("leather", *G.strap([(0.1, -0.06, 0.74), (0.11, -0.2, 0.42), (0.12, -0.25, 0.0), (0.12, -0.2, -0.45), (0.1, 0.1, -0.86)], 0.07, 0.022))
    g.add("accent", G.ell((-0.072, 0.06, 0.64), (0.012, 0.075, 0.12), 8, 3))  # class badge, butt left side


def belt(g):
    g.add("steel",
          G.rod((-0.1, -0.2, -0.38), (0.07, -0.2, -0.38), 0.2, 12, bevel=0.02),  # drum (left of the sling)
          G.rbox((-0.01, -0.02, -0.38), (0.09, 0.2, 0.1), bevel=0.02))  # feed neck into the fore-end
    g.add("brass",
          G.rod((-0.135, -0.2, -0.38), (-0.095, -0.2, -0.38), 0.08, 8),  # wind key boss (left face)
          G.rod((0.065, -0.2, -0.38), (0.09, -0.2, -0.38), 0.06, 8))  # hub (right face)
    path = [(-0.07, 0.25, -0.16), (-0.16, 0.16, -0.2), (-0.2, 0.02, -0.26), (-0.17, -0.1, -0.33)]
    g.add("leather", *G.strap(path, 0.08, 0.024, up=(1, 0, 0)))
    rounds = []
    for p, q in zip(path, path[1:]):
        for t in (0.5,):
            c = [a + (b - a) * t for a, b in zip(p, q)]
            rounds.append(G.rod((c[0] - 0.005, c[1], c[2]), (c[0] - 0.07, c[1], c[2]), 0.03, 6, top=0.6))
    g.add("accent2", *rounds, piece="rounds")


def build(lp, variant=None):
    if variant == "belt":
        g = G.Gun(lp, ENVELOPE, 400)
        belt(g)
        g.groups["rounds"] = "brass"
        base = G.Gun(lp, ENVELOPE, 1200)
        gun(base)
        g.base(base)
        meta = {"gun": "RIFLE", "attach": "RIFLE", "shows": "HeroStats.beltFed (Heavy T3 Belt Fed)"}
    else:
        g = G.Gun(lp, ENVELOPE, 1200)
        gun(g)
        meta = {"gun": "RIFLE", "grip": [0, 0, 0], "muzzle": [0, BORE, TIP - 0.01]}
    return g.model("11c2", "gun", COLORS, meta)
