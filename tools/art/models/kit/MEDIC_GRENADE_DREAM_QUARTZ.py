"""MEDIC_GRENADE_DREAM_QUARTZ - the MEDIC grenade, premium skin Dream Quartz (Geode theme, PREMIUM_SKINS.md, batch 11p6): a puffy cloud of rose-quartz crystals: rose crystals
spiking out in all directions round a glowing amethyst core, a small stone cap with a valve-crystal on top.
`glow` = Neon in game (Shared/SkinFx: crystal shards burst). Same frame as the base (kit/_prop.py: origin = the
thrown 0.9 ball's centre, upright), <= 600 tris. Runtime key kit/<HERO>_GRENADE_<SKIN KEY>.
"""
# art-sources: ../gun/variants/_geode.py

import importlib.util
import math
from pathlib import Path

_here = Path(__file__).parent
_spec = importlib.util.spec_from_file_location("_prop", _here / "_prop.py")
D = importlib.util.module_from_spec(_spec)
_spec.loader.exec_module(D)
G = D.G
_spec = importlib.util.spec_from_file_location("_geode_gun", _here.parent / "gun" / "variants" / "_geode.py")
X = importlib.util.module_from_spec(_spec)
_spec.loader.exec_module(X)

def design(g):
    g.add("glow", X.rock(G, (0, -0.04, 0), (0.22, 0.22, 0.22), segments=7, rings=4))
    pts = []
    for i, (yaw, pitch) in enumerate(((0, 10), (72, 10), (144, 10), (216, 10), (288, 10), (36, -40), (108, -40), (180, -40),
                                      (252, -40), (324, -40), (0, 55), (120, 55), (240, 55))):
        y, p = math.radians(yaw), math.radians(pitch)
        d = (math.cos(p) * math.cos(y), math.sin(p), math.cos(p) * math.sin(y))
        ln = 0.38 + 0.08 * (i % 3)
        pts.append(X.crystal(G, (d[0] * 0.1, -0.04 + d[1] * 0.1, d[2] * 0.1), (d[0] * ln, -0.04 + d[1] * ln, d[2] * ln), 0.07, 5, twist=17 * i))
    g.add("rose", *pts[0::2])
    g.add("crystal", *pts[1::2])
    g.add("rock2", G.rod((0, 0.24, 0), (0, 0.34, 0), 0.06, 6))
    g.add("glow", X.crystal(G, (0, 0.33, 0), (0, 0.48, 0), 0.04, 5))


def build(lp):
    g = G.Gun(lp, D.GRENADE, D.CAP)
    design(g)
    meta = {"hero": "MEDIC", "prop": "grenade", "display": "Dream Quartz", "skin": "DREAM_QUARTZ",
            "base": "kit/MEDIC_GRENADE", "centre": [0, 0, 0], "theme": "GEODE", "premium": True}
    return g.model("11p6", "small", {**X.COLORS, "crystal": (196, 160, 236)}, meta)
