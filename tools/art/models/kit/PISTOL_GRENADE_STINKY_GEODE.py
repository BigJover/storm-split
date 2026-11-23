"""PISTOL_GRENADE_STINKY_GEODE - the PISTOL grenade, premium skin Stinky Geode (Geode theme, PREMIUM_SKINS.md, batch 11p6): a split geode left open like a
lidded pot: a rough stone bowl full of glowing amethyst crystals, its stone lid tipped back on one side, a
teal stink-crystal puff rising out of the gap and a short fuse on the lid.
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
    # the stone bowl (lower half) and the crystal bed inside it
    g.add("rock", X.rock(G, (0, -0.1, 0), (0.34, 0.26, 0.34), segments=8, rings=5))
    g.add("rock2", X.rock(G, (0, 0.06, 0), (0.33, 0.06, 0.33), segments=8, rings=3))  # the broken rim
    g.add("glow", X.rock(G, (0, 0.1, 0), (0.27, 0.05, 0.27), segments=7, rings=3),
          *[X.crystal(G, (0.13 * math.cos(a), 0.06, 0.13 * math.sin(a)), (0.2 * math.cos(a), 0.3, 0.2 * math.sin(a)), 0.05, 5)
            for a in (math.radians(d) for d in (20, 140, 260))])
    g.add("crystal", *[X.crystal(G, (0.1 * math.cos(a), 0.06, 0.1 * math.sin(a)), (0.12 * math.cos(a), 0.24, 0.12 * math.sin(a)), 0.045, 5)
                       for a in (math.radians(d) for d in (80, 200, 320))])
    # the lid tipped back (hinged at the back), a fuse on it
    g.add("rock", X.rock(G, (0, 0.26, 0.22), (0.32, 0.1, 0.3), rot=(-38, 0, 0), segments=8, rings=3))
    g.add("rock2", G.rod((0, 0.36, 0.3), (0, 0.46, 0.34), 0.04, 5))
    g.add("glow", G.ell((0, 0.48, 0.35), (0.04, 0.04, 0.04), 5, 3))
    # the stink: teal crystals puffing out of the gap at the front
    g.add("teal", *[X.crystal(G, (dx, 0.12, -0.16), (dx * 1.8, 0.42 - abs(dx), -0.3), 0.04, 4) for dx in (-0.12, 0.0, 0.12)])


def build(lp):
    g = G.Gun(lp, D.GRENADE, D.CAP)
    design(g)
    meta = {"hero": "PISTOL", "prop": "grenade", "display": "Stinky Geode", "skin": "STINKY_GEODE",
            "base": "kit/PISTOL_GRENADE", "centre": [0, 0, 0], "theme": "GEODE", "premium": True}
    return g.model("11p6", "small", {**X.COLORS, "rock": (138, 134, 120)}, meta)
