"""PISTOL_GRENADE_REX_REEKER - the PISTOL grenade, premium skin Rex Reeker (Tyrant King theme, PREMIUM_SKINS.md, batch 11p4): a roaring rex skull charm,
jaws wide open on a glowing red stink-gas core inside its mouth, a crimson rag tied round the back of the
skull with a trailing tail, and a cork plug with a glowing tip in the top of the cranium (the Stink Bomb's
jar, reborn as a skull).
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
    T.prop_skull(g, G, (0, 0.02, 0.04), s=1.25, gape=28, teeth=3)
    g.add("glow", G.ell((0, -0.16, -0.24), (0.14, 0.1, 0.16), 7, 4))  # the gas core in the mouth
    g.add("accent", G.ring((0, 0.08, 0.2), 0.2, 0.04, 8, 3, axis="z"),  # crimson rag round the back
          G.rbox((0.12, -0.08, 0.34), (0.1, 0.24, 0.04), bevel=0.0, rot=(20, 0, -20)))  # its tail
    g.add("cork", G.rod((0, 0.32, 0.1), (0, 0.44, 0.1), 0.08, 6, top=1.15))
    g.add("glow", G.ell((0, 0.47, 0.1), (0.04, 0.04, 0.04), 5, 3))


def build(lp):
    g = G.Gun(lp, D.GRENADE, D.CAP)
    design(g)
    meta = {"hero": "PISTOL", "prop": "grenade", "display": "Rex Reeker", "skin": "REX_REEKER",
            "base": "kit/PISTOL_GRENADE", "centre": [0, 0, 0], "theme": "TYRANT_KING", "premium": True}
    return g.model("11p4", "small", {**T.COLORS, "cork": (176, 136, 90), "dark": (40, 26, 26)}, meta)
