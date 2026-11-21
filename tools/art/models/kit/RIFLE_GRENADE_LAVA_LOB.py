"""RIFLE_GRENADE_LAVA_LOB - the Big Game Hunter's grenade, premium skin Lava Lob (Lava Lord theme,
PREMIUM_SKINS.md, batch 11p1): a lump of faceted obsidian cracked open by lava. A low-poly volcanic-glass
ball with glowing seams wrapping it, a dark-iron fuse
head, spoon lever and pull ring (the Safari Grenade's, so it still reads as a grenade) and a glowing
fuse cap. `glow` = Neon (Shared/SkinFx: the blast goes orange with a dark smoke puff). Same frame as
the base (kit/_prop.py: origin = the thrown 0.9 ball's centre, upright), <= 600 tris.
Runtime key: kit/<HERO>_GRENADE_<SKIN KEY> (PREMIUM_SKINS "Grenade art hookup").
"""

import importlib.util
import math
from pathlib import Path

_spec = importlib.util.spec_from_file_location("_prop", Path(__file__).with_name("_prop.py"))
D = importlib.util.module_from_spec(_spec)
_spec.loader.exec_module(D)
G = D.G

R = 0.31
C = (0, -0.05, 0)


def on_ball(yaw, pitch, lift=1.02):
    y, p = math.radians(yaw), math.radians(pitch)
    return (C[0] + R * lift * math.cos(p) * math.sin(y), C[1] + R * lift * math.sin(p), C[2] - R * lift * math.cos(p) * math.cos(y))


def crack(pts, r=0.017, sub=3):
    """A seam hugging the ball: each (yaw, pitch) step split in `sub` so the rods follow the curve."""
    fine = [pts[0]]
    for (y0, p0), (y1, p1) in zip(pts, pts[1:]):
        fine += [(y0 + (y1 - y0) * t / sub, p0 + (p1 - p0) * t / sub) for t in range(1, sub + 1)]
    xyz = [on_ball(*p, lift=1.0) for p in fine]
    return [G.rod(a, b, r, 3) for a, b in zip(xyz, xyz[1:])]


def faceted(obj):
    """Every edge sharp: build.py's weighted-normal smoothing keeps them, so the glass shows facets."""
    for e in obj.data.edges:
        e.use_edge_sharp = True
    return obj


def lob(g):
    g.add("body", faceted(G.ell(C, (R, R * 0.96, R), 9, 6)))  # faceted obsidian
    g.add("glow",
          *crack([(-50, 55), (-30, 30), (-40, 5), (-15, -25), (-25, -50)]),
          *crack([(-40, 5), (15, 12), (40, -12), (75, 5)], sub=2),
          *crack([(130, 45), (150, 18), (138, -12), (170, -40)], sub=2),
          *crack([(215, 30), (240, 2), (228, -30)], sub=2),
          *crack([(290, 40), (305, 10), (335, 20)], sub=2))
    g.add("steel", G.rod((0, 0.2, 0), (0, 0.36, 0), 0.08, 8))  # fuse head (dark iron)
    g.add("glow", G.ell((0, 0.37, 0), (0.06, 0.03, 0.06), 6, 3))  # glowing fuse cap
    g.add("brass",
          G.bar((0.08, 0.34, 0), (0.25, 0.06, 0), 0.07, 0.025, up=(1, 0, 0)),  # spoon lever
          G.bar((0.25, 0.06, 0), (0.27, -0.12, 0), 0.07, 0.025, up=(1, 0, 0)),
          G.ring((-0.13, 0.34, 0), 0.07, 0.016, 10, 3, axis="z"))  # pull ring


def build(lp):
    g = G.Gun(lp, D.GRENADE, D.CAP)
    lob(g)
    meta = {"hero": "RIFLE", "prop": "grenade", "display": "Lava Lob", "skin": "LAVA_LOB",
            "base": "kit/RIFLE_GRENADE", "centre": [0, 0, 0], "theme": "LAVA_LORD", "premium": True}
    return g.model("11p1", "small", {"body": (40, 34, 42), "glow": (255, 112, 20), "steel": (52, 48, 54),
                                      "brass": (120, 70, 42)}, meta)
