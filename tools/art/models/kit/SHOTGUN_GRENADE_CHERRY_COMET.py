"""SHOTGUN_GRENADE_CHERRY_COMET - the Brush Beater's grenade, premium skin Cherry Comet (Nebula theme,
PREMIUM_SKINS.md, batch 11p5, #462: its own silhouette, element cosmic / void). A cherry bomb that is a
comet: a cherry-pink faceted ball wrapped in a nebula band, a sweeping starlight comet tail curling off
its back (three tapering streaks), craters and star specks on the ball; the Cherry Bomb's ferrule and
curled fuse kept on top with a star burning at its end. `glow` = Neon in game. Same frame as the base
(kit/_prop.py: origin = the thrown ball's centre, upright), <= 600 tris.
"""

import importlib.util
import math
from pathlib import Path

_spec = importlib.util.spec_from_file_location("_prop", Path(__file__).with_name("_prop.py"))
D = importlib.util.module_from_spec(_spec)
_spec.loader.exec_module(D)
G = D.G

C = (0, -0.06, 0)
R = 0.3


def on_ball(yaw, pitch, lift=1.0):
    y, p = math.radians(yaw), math.radians(pitch)
    return (C[0] + R * lift * math.cos(p) * math.sin(y), C[1] + R * lift * math.sin(p), C[2] - R * lift * math.cos(p) * math.cos(y))


def comet(g):
    g.add("body", G.ell(C, (R, R, R), 10, 7))
    g.add("band", G.ring(C, R, 0.035, 12, 3, axis="y", rot=(0, 0, 12)))
    g.add("crater", *[G.rod(on_ball(y, p, 0.94), on_ball(y, p, 1.03), 0.06, 6, top=1.15) for y, p in ((-30, 30), (40, -30), (150, 20))])
    # the comet tail: three tapering streaks curling off the back (+Z), sweeping down
    tip = (0.0, C[1] + 0.2, 0.54)
    for dx, dy, r0 in ((0.0, 0.0, 0.16), (0.17, 0.06, 0.07), (-0.17, -0.02, 0.07), (0.0, 0.17, 0.07)):
        a0 = (dx, C[1] + dy, 0.16)
        mid = (dx * 0.6, C[1] + dy * 0.6 + 0.08, 0.38)
        g.add("glow", G.rod(a0, mid, r0, 6, top=0.62), G.rod(mid, tip, r0 * 0.62, 6, top=0.05))
    g.add("glow", *[G.ell(on_ball(y, p, 1.02), (0.022, 0.022, 0.022), 4, 2) for y, p in ((0, 50), (-80, -10), (90, 10))])
    g.add("brass", G.rod((0, 0.22, 0), (0, 0.31, 0), 0.06, 7))
    g.add("dark", *G.strap([(0, 0.29, 0), (0.06, 0.41, 0), (0.15, 0.47, 0)], 0.035, 0.035))
    g.add("glow", G.ell((0.17, 0.48, 0), (0.05, 0.05, 0.05), 4, 2),
          G.ell((0.17, 0.48, 0), (0.12, 0.022, 0.022), 4, 2), G.ell((0.17, 0.48, 0), (0.022, 0.06, 0.022), 4, 2))


def build(lp):
    g = G.Gun(lp, D.GRENADE, D.CAP)
    comet(g)
    meta = {"hero": "SHOTGUN", "prop": "grenade", "display": "Cherry Comet", "skin": "CHERRY_COMET",
            "base": "kit/SHOTGUN_GRENADE", "centre": [0, 0, 0], "theme": "NEBULA", "premium": True}
    return g.model("11p5", "small", {"body": (222, 64, 132), "band": (62, 30, 104), "crater": (150, 40, 100),
                                      "glow": (150, 236, 240), "brass": (190, 186, 224), "dark": (40, 30, 60)}, meta)
