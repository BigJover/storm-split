"""SHOTGUN_GRENADE_CRYSTAL_CHERRY - the SHOTGUN grenade, premium skin Crystal Cherry (Geode theme, PREMIUM_SKINS.md, batch 11p6): a round faceted amethyst "cherry" (glowing) in a
stone cap with a twisting stone stem fuse ending in a glowing teal crystal tip, two small crystal leaves.
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
    g.add("glow", X.rock(G, (0, -0.06, 0), (0.32, 0.3, 0.32), segments=8, rings=5))
    g.add("rock", X.rock(G, (0, 0.2, 0), (0.18, 0.08, 0.18), segments=7, rings=3))
    g.add("rock2", *G.strap([(0, 0.24, 0), (0.05, 0.36, 0), (0.14, 0.44, 0.02)], 0.045, 0.045))
    g.add("teal", X.crystal(G, (0.13, 0.43, 0.02), (0.24, 0.52, 0.04), 0.045, 5))
    g.add("crystal", *[X.crystal(G, (0.02, 0.3, 0), (-0.2 * k + 0.0, 0.34, 0.16 * k), 0.035, 4) for k in (-1, 1)])
    # facet lines: a few glowing ridges are the faceted ball itself; a stone band round its waist
    g.add("rock2", G.ring((0, -0.06, 0), 0.32, 0.025, 8, 3, axis="y"))


def build(lp):
    g = G.Gun(lp, D.GRENADE, D.CAP)
    design(g)
    meta = {"hero": "SHOTGUN", "prop": "grenade", "display": "Crystal Cherry", "skin": "CRYSTAL_CHERRY",
            "base": "kit/SHOTGUN_GRENADE", "centre": [0, 0, 0], "theme": "GEODE", "premium": True}
    return g.model("11p6", "small", {**X.COLORS}, meta)
