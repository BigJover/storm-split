"""MEDIC_GRENADE_SULFUR_SNOOZE - the Field Medic's grenade (Dozy Cloud), premium skin Sulfur Snooze (Lava
Lord theme, PREMIUM_SKINS.md, batch 11p2, #462: its own silhouette). A sleeping-gas canister made from a
volcano's fumarole: a hexagonal basalt column with lava glowing in its cracks and a molten band, a
sulfur crust round its shoulder, a little fumarole cone on top with a glowing vent, an obsidian
valve wheel, and a puff of sulfur cloud already curling out of it. `glow` = Neon (Shared/SkinFx:
blast orange with a dark smoke puff; the pack tier's fire trail + splash). Same frame as the base
(kit/_prop.py: origin = the thrown 0.9 ball's centre, upright), <= 600 tris.
"""

import importlib.util
import math
from pathlib import Path

_spec = importlib.util.spec_from_file_location("_prop", Path(__file__).with_name("_prop.py"))
D = importlib.util.module_from_spec(_spec)
_spec.loader.exec_module(D)
G = D.G


def faceted(obj):
    for e in obj.data.edges:
        e.use_edge_sharp = True
    return obj


def snooze(g):
    r = 0.23
    # the basalt column (hexagonal), cracks + a molten band
    g.add("body", faceted(G.rod((0, -0.38, 0), (0, 0.14, 0), r, 6)))
    g.add("glow", G.rod((0, -0.2, 0), (0, -0.12, 0), r * 1.03, 6))
    cracks = []
    for i in range(6):
        a = math.radians(i * 60)
        rr = r * 0.9  # on the hexagon's flats
        x, z = math.cos(a) * rr, math.sin(a) * rr
        if True:
            cracks += [G.rod((x, -0.36, z), (x * 0.97, -0.28, z * 1.03), 0.02, 3), G.rod((x * 0.97, -0.28, z * 1.03), (x, -0.2, z), 0.02, 3),
                       G.rod((x, -0.12, z), (x * 1.03, -0.02, z * 0.97), 0.02, 3), G.rod((x * 1.03, -0.02, z * 0.97), (x, 0.1, z), 0.02, 3)]
    g.add("glow", *cracks)
    # sulfur crust round the shoulder (lumps)
    g.add("sulfur", *[faceted(G.ell((0.2 * math.cos(math.radians(d)), 0.15, 0.2 * math.sin(math.radians(d))), (0.08, 0.06, 0.08), 5, 3))
                      for d in (0, 60, 120, 180, 240, 300)])
    # fumarole cone with the glowing vent, valve wheel on its side
    g.add("body", G.rod((0, 0.14, 0), (0, 0.34, 0), 0.17, 6, top=0.4))
    g.add("glow", G.rod((0, 0.335, 0), (0, 0.35, 0), 0.06, 6))
    g.add("dark", G.ring((0.14, 0.26, 0), 0.07, 0.016, 8, 3, axis="x"), G.rod((0.07, 0.26, 0), (0.15, 0.26, 0), 0.02, 4))
    # a sulfur cloud puff curling out of the vent (three soft lumps)
    g.add("cloud", G.ell((0.02, 0.42, -0.02), (0.11, 0.08, 0.1), 7, 4), G.ell((-0.1, 0.45, 0.03), (0.09, 0.07, 0.08), 7, 4),
          G.ell((0.08, 0.47, 0.05), (0.08, 0.07, 0.08), 7, 4))


def build(lp):
    g = G.Gun(lp, D.GRENADE, D.CAP)
    snooze(g)
    meta = {"hero": "MEDIC", "prop": "grenade", "display": "Sulfur Snooze", "skin": "SULFUR_SNOOZE",
            "base": "kit/MEDIC_GRENADE", "centre": [0, 0, 0], "theme": "LAVA_LORD", "premium": True}
    return g.model("11p2", "small", {"body": (62, 54, 56), "sulfur": (232, 204, 64), "cloud": (240, 226, 140),
                                      "dark": (30, 26, 34), "glow": (255, 112, 20)}, meta)
