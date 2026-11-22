"""SHOTGUN_GRENADE_NEON_CHERRY - the Brush Beater's grenade (Cherry Bomb), premium skin Neon Cherry
(Cyber Raptor theme, PREMIUM_SKINS.md, batch 11p3, #462: its own silhouette, element electric /
digital glitch). A pair of black-chrome cherries: a big orb and a small one, each wrapped in glowing
circuit rings, their gunmetal cable stems meeting in a socket at the top with a glowing spark (the
lit fuse), and a flat pixel-stepped leaf fin. `glow` = Neon (Shared/SkinFx: laser-cyan blast ring
with square pixel sparks). Same frame as the base (kit/_prop.py: origin = the thrown 0.9 ball's
centre, upright), <= 600 tris.
"""

import importlib.util
from pathlib import Path

_spec = importlib.util.spec_from_file_location("_prop", Path(__file__).with_name("_prop.py"))
D = importlib.util.module_from_spec(_spec)
_spec.loader.exec_module(D)
G = D.G

COLORS = {"body": (30, 32, 44), "chrome": (138, 148, 166), "glow": (0, 236, 255), "accent": (230, 60, 220)}


def cherries(g):
    big, small = ((-0.1, -0.1, 0.0), 0.27), ((0.24, -0.2, 0.06), 0.19)
    g.add("body", *[G.ell(c, (r, r, r), 10, 6) for c, r in (big, small)])
    g.add("glow",
          *[G.ring(c, r * 1.005, 0.018, 10, 3, axis=ax) for c, r in (big, small) for ax in ("y", "x")],
          G.ell((0.06, 0.42, 0.0), (0.05, 0.05, 0.05), 6, 3))  # the spark
    top = (0.06, 0.34, 0.0)
    g.add("chrome",
          *G.strap([(big[0][0], big[0][1] + big[1] - 0.02, 0), (-0.06, 0.26, 0), top], 0.035, 0.035),
          *G.strap([(small[0][0], small[0][1] + small[1] - 0.02, small[0][2]), (0.2, 0.18, 0.03), top], 0.03, 0.03),
          G.rod((0.06, 0.32, 0), (0.06, 0.39, 0), 0.045, 6))  # the socket
    # a flat pixel-stepped leaf
    g.add("accent",
          G.rbox((0.13, 0.37, 0), (0.12, 0.05, 0.02), bevel=0.0),
          G.rbox((0.21, 0.41, 0), (0.12, 0.05, 0.02), bevel=0.0),
          G.rbox((0.27, 0.45, 0), (0.08, 0.05, 0.02), bevel=0.0))


def build(lp):
    g = G.Gun(lp, D.GRENADE, D.CAP)
    cherries(g)
    meta = {"hero": "SHOTGUN", "prop": "grenade", "display": "Neon Cherry", "skin": "NEON_CHERRY",
            "base": "kit/SHOTGUN_GRENADE", "centre": [0, 0, 0], "theme": "CYBER_RAPTOR", "premium": True}
    return g.model("11p3", "small", COLORS, meta)
