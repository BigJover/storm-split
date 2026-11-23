"""RIFLE_GRENADE_GEODE_GRENADE - the RIFLE grenade, premium skin Geode Grenade (Geode theme, PREMIUM_SKINS.md, batch 11p6): a round stone egg split right round its middle,
a band of glowing amethyst crystals bursting out of the crack, stone halves above and below, and the Safari
Grenade's fuse head, spoon and pull ring on top.
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
    g.add("rock", X.rock(G, (0, 0.08, 0), (0.28, 0.2, 0.28), segments=8, rings=4),
          X.rock(G, (0, -0.22, 0), (0.28, 0.17, 0.28), segments=8, rings=4))
    g.add("glow", X.rock(G, (0, -0.08, 0), (0.26, 0.07, 0.26), segments=7, rings=3))
    out = []
    for i in range(8):
        a = math.radians(45 * i + 10)
        ca, sa = math.cos(a), math.sin(a)
        out.append(X.crystal(G, (0.2 * ca, -0.08, 0.2 * sa), (0.4 * ca, -0.08 + 0.08 * ((i % 3) - 1), 0.4 * sa), 0.045, 5))
    g.add("glow", *out[0::2])
    g.add("crystal", *out[1::2])
    g.add("rock2", G.rod((0, 0.24, 0), (0, 0.38, 0), 0.075, 6))  # fuse head
    g.add("teal", X.crystal(G, (0.08, 0.34, 0), (0.28, 0.14, 0), 0.04, 5))  # spoon: a teal crystal lever
    g.add("rock2", G.ring((-0.13, 0.35, 0), 0.07, 0.016, 8, 3, axis="z"))


def build(lp):
    g = G.Gun(lp, D.GRENADE, D.CAP)
    design(g)
    meta = {"hero": "RIFLE", "prop": "grenade", "display": "Geode Grenade", "skin": "GEODE_GRENADE",
            "base": "kit/RIFLE_GRENADE", "centre": [0, 0, 0], "theme": "GEODE", "premium": True}
    return g.model("11p6", "small", {**X.COLORS}, meta)
