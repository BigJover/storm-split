"""SHOTGUN_GRENADE_RUBY_BOMB - the SHOTGUN grenade, premium skin Ruby Bomb (Tyrant King theme, PREMIUM_SKINS.md, batch 11p4): a round crimson bomb gripped by
a rex skull clamped over its top (ruby-red glowing eyes), a ring of bone teeth round its middle above a thin
gold band, and the Cherry Bomb's curling fuse out of the skull's crown with a glowing lit tip.
`glow` = Neon in game (Shared/SkinFx: crimson blast with gold dust). Same frame as the base (kit/_prop.py:
origin = the thrown 0.9 ball's centre, upright), <= 600 tris. Runtime key kit/<HERO>_GRENADE_<SKIN KEY>.
"""
# art-sources: ../gun/variants/_tyrant.py

import importlib.util
import math
from pathlib import Path

_here = Path(__file__).parent
_spec = importlib.util.spec_from_file_location("_prop", _here / "_prop.py")
D = importlib.util.module_from_spec(_spec)
_spec.loader.exec_module(D)
G = D.G
_spec = importlib.util.spec_from_file_location("_tyrant_gun", _here.parent / "gun" / "variants" / "_tyrant.py")
T = importlib.util.module_from_spec(_spec)
_spec.loader.exec_module(T)


def design(g):
    g.add("accent", G.ell((0, -0.12, 0), (0.3, 0.3, 0.3), 10, 6))  # the crimson bomb
    g.add("gold", G.ring((0, -0.14, 0), 0.3, 0.02, 10, 3, axis="y"))
    g.add("bone", *[T.fang(G, (0.29 * math.cos(math.radians(a)), -0.16, 0.29 * math.sin(math.radians(a))),
                           (0.38 * math.cos(math.radians(a)), -0.16, 0.38 * math.sin(math.radians(a))), 0.035)
                    for a in range(0, 360, 45)])
    T.prop_skull(g, G, (0, 0.14, -0.02), s=0.8, gape=0, teeth=3, jaw=False)
    g.add("dark", *G.strap([(0, 0.33, 0.06), (0.06, 0.43, 0.06), (0.15, 0.46, 0.06)], 0.035, 0.035))  # fuse
    g.add("glow", G.ell((0.17, 0.47, 0.06), (0.05, 0.05, 0.05), 6, 3))  # lit end


def build(lp):
    g = G.Gun(lp, D.GRENADE, D.CAP)
    design(g)
    meta = {"hero": "SHOTGUN", "prop": "grenade", "display": "Ruby Bomb", "skin": "RUBY_BOMB",
            "base": "kit/SHOTGUN_GRENADE", "centre": [0, 0, 0], "theme": "TYRANT_KING", "premium": True}
    return g.model("11p4", "small", {**T.COLORS, "dark": (40, 26, 26)}, meta)
