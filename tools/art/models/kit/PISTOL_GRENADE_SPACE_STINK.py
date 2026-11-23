"""PISTOL_GRENADE_SPACE_STINK - the Tracker's grenade, premium skin Space Stink (Nebula theme,
PREMIUM_SKINS.md, batch 11p5, #462: its own silhouette, element cosmic / void). A little black hole in a
jar: a void-dark orb wrapped in a tilted accretion disc (a starlight inner ring and a pink outer
band), star specks on the orb, the Stink Bomb's neck and cork kept on top (so it still reads as the
stink jar) with a cloud of nebula gas puffing out under the cork. `glow` = Neon in game. Same frame as
the base (kit/_prop.py: origin = the thrown ball's centre, upright), <= 600 tris.
"""

import importlib.util
import math
from pathlib import Path

_spec = importlib.util.spec_from_file_location("_prop", Path(__file__).with_name("_prop.py"))
D = importlib.util.module_from_spec(_spec)
_spec.loader.exec_module(D)
G = D.G

C = (0, -0.1, 0)
R = 0.3


def jar(g):
    g.add("body", G.ell(C, (R, R * 0.94, R), 12, 6), G.rod((0, 0.14, 0), (0, 0.3, 0), 0.12, 8))
    tilt = (18, 0, -20)
    g.add("glow", G.ring(C, 0.5, 0.024, 16, 3, axis="y", rot=tilt))
    g.add("disc", G.ring(C, 0.39, 0.05, 16, 3, axis="y", rot=tilt))
    g.add("glow", *[G.ell((C[0] + R * 1.0 * math.cos(math.radians(p)) * math.sin(math.radians(y)),
                           C[1] + R * math.sin(math.radians(p)),
                           C[2] - R * math.cos(math.radians(p)) * math.cos(math.radians(y))), (0.022, 0.022, 0.022), 4, 2)
                    for y, p in ((30, 40), (-50, 20), (120, -30), (200, 30), (-120, -45))])
    g.add("cork", G.rod((0, 0.29, 0), (0, 0.42, 0), 0.11, 8, top=1.15))
    g.add("cloth", G.ring((0, 0.22, 0), 0.13, 0.028, 8, 3, axis="y"))
    # nebula gas puffing out under the cork
    g.add("gas", *[G.ell((x, y, z), (s, s * 0.8, s), 6, 4) for x, y, z, s in
                   ((0.14, 0.33, -0.06, 0.07), (0.22, 0.42, -0.02, 0.06), (0.17, 0.51, 0.05, 0.05), (-0.13, 0.35, 0.08, 0.06))])


def build(lp):
    g = G.Gun(lp, D.GRENADE, D.CAP)
    jar(g)
    meta = {"hero": "PISTOL", "prop": "grenade", "display": "Space Stink", "skin": "SPACE_STINK",
            "base": "kit/PISTOL_GRENADE", "centre": [0, 0, 0], "theme": "NEBULA", "premium": True}
    return g.model("11p5", "small", {"body": (30, 24, 60), "disc": (214, 88, 184), "glow": (150, 236, 240),
                                      "cork": (120, 96, 150), "cloth": (96, 44, 150), "gas": (132, 214, 150)}, meta)
