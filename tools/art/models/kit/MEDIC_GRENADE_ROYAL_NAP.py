"""MEDIC_GRENADE_ROYAL_NAP - the MEDIC grenade, premium skin Royal Nap (Tyrant King theme, PREMIUM_SKINS.md, batch 11p4): a royal bone censer: a cage of curved
rib bones round a softly glowing red dream-core, a crimson cushion under it (gold tassel knots), a bone cap
with a small sleeping rex skull on top (no glowing eyes) and a gold ring to throw it by. No red cross
(protected emblem).
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
    g.add("glow", G.ell((0, -0.06, 0), (0.18, 0.2, 0.18), 7, 4))  # the dream-core
    ribs = []
    for i in range(5):
        a = math.radians(72 * i)
        ca, sa = math.cos(a), math.sin(a)
        pts = [(0.12 * ca, 0.16, 0.12 * sa), (0.27 * ca, -0.06, 0.27 * sa), (0.12 * ca, -0.3, 0.12 * sa)]
        ribs += [G.bar(p, q, 0.05, 0.03, bevel=0.0, up=(ca, 0, sa)) for p, q in zip(pts, pts[1:])]
    g.add("bone", *ribs, G.rod((0, 0.14, 0), (0, 0.22, 0), 0.15, 7))  # cap
    g.add("accent", G.ell((0, -0.36, 0), (0.3, 0.1, 0.3), 8, 4))  # crimson cushion
    g.add("gold", *[G.ell((0.3 * math.cos(math.radians(a)), -0.38, 0.3 * math.sin(math.radians(a))), (0.04, 0.05, 0.04), 4, 3)
                    for a in (45, 135, 225, 315)],  # tassel knots
          G.ring((0, 0.44, 0.14), 0.06, 0.015, 8, 3, axis="z"))  # the ring
    T.prop_skull(g, G, (0, 0.32, -0.02), s=0.6, gape=0, eyes=None, teeth=2, jaw=False)


def build(lp):
    g = G.Gun(lp, D.GRENADE, D.CAP)
    design(g)
    meta = {"hero": "MEDIC", "prop": "grenade", "display": "Royal Nap", "skin": "ROYAL_NAP",
            "base": "kit/MEDIC_GRENADE", "centre": [0, 0, 0], "theme": "TYRANT_KING", "premium": True}
    return g.model("11p4", "small", {**T.COLORS, "dark": (40, 26, 26)}, meta)
