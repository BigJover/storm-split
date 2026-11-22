"""RIFLE_GRENADE_CROWN_JEWEL - the RIFLE grenade, premium skin Crown Jewel (Tyrant King theme, PREMIUM_SKINS.md, batch 11p4): a big faceted ruby (glowing
red) held in a bone crown: a gold band round its middle, bone fang prongs clasping it from below, a ring
of crown points round its top, and the Safari Grenade's fuse head, spoon and pull ring on top.
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


def faceted(obj):
    for e in obj.data.edges:
        e.use_edge_sharp = True
    return obj


def design(g):
    g.add("glow", faceted(G.ell((0, -0.04, 0), (0.25, 0.3, 0.25), 8, 5)))
    g.add("gold", G.ring((0, -0.04, 0), 0.26, 0.03, 8, 3, axis="y"))  # band (trim)
    prongs, points = [], []
    for i in range(6):
        a = math.radians(60 * i)
        ca, sa = math.cos(a), math.sin(a)
        prongs.append(G.bar((0.06 * ca, -0.36, 0.06 * sa), (0.26 * ca, -0.1, 0.26 * sa), 0.06, 0.03, bevel=0.0, up=(ca, 0, sa)))
        points.append(T.fang(G, (0.2 * ca, 0.16, 0.2 * sa), (0.26 * ca, 0.34, 0.26 * sa), 0.045))
    g.add("bone", *prongs, *points, G.rod((0, -0.34, 0), (0, -0.42, 0), 0.08, 6),
          G.ring((0, 0.16, 0), 0.2, 0.03, 8, 3, axis="y"))  # crown ring
    g.add("steel", G.rod((0, 0.22, 0), (0, 0.36, 0), 0.075, 6))  # fuse head
    g.add("gold", G.bar((0.08, 0.34, 0), (0.3, 0.12, 0), 0.07, 0.025, up=(1, 0, 0)),  # spoon (gold trim)
          G.ring((-0.13, 0.35, 0), 0.07, 0.016, 8, 3, axis="z"))  # pull ring


def build(lp):
    g = G.Gun(lp, D.GRENADE, D.CAP)
    design(g)
    meta = {"hero": "RIFLE", "prop": "grenade", "display": "Crown Jewel", "skin": "CROWN_JEWEL",
            "base": "kit/RIFLE_GRENADE", "centre": [0, 0, 0], "theme": "TYRANT_KING", "premium": True}
    return g.model("11p4", "small", {**T.COLORS, "steel": (70, 56, 58)}, meta)
