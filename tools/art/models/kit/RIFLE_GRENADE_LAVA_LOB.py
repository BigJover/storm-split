"""RIFLE_GRENADE_LAVA_LOB v2 - the Big Game Hunter's grenade, premium skin Lava Lob (Lava Lord theme,
PREMIUM_SKINS.md, batch 11p1, #462: its own silhouette). A cracked magma core caged in obsidian:
a glowing faceted core with plates of dark crust floating on it (the lava shows between them), held
in five curved obsidian ribs that meet in a spiked cap underneath and a collar on top; the Safari
Grenade's dark-iron fuse head, spoon lever and pull ring stay on top so it still reads as a grenade,
with a glowing fuse cap. `glow` = Neon (Shared/SkinFx: the blast goes orange with a dark smoke puff;
the pack tier adds a fire trail in flight and a lava splash on impact). Same frame as the base
(kit/_prop.py: origin = the thrown 0.9 ball's centre, upright), <= 600 tris.
Runtime key: kit/<HERO>_GRENADE_<SKIN KEY> (PREMIUM_SKINS "Grenade art hookup").
"""

import importlib.util
import math
from pathlib import Path

_spec = importlib.util.spec_from_file_location("_prop", Path(__file__).with_name("_prop.py"))
D = importlib.util.module_from_spec(_spec)
_spec.loader.exec_module(D)
G = D.G

R = 0.3
C = (0, -0.04, 0)


def on_ball(yaw, pitch, lift=1.0, r=R):
    y, p = math.radians(yaw), math.radians(pitch)
    return (C[0] + r * lift * math.cos(p) * math.sin(y), C[1] + r * lift * math.sin(p), C[2] - r * lift * math.cos(p) * math.cos(y))


def faceted(obj):
    """Every edge sharp: build.py's weighted-normal smoothing keeps them, so facets show."""
    for e in obj.data.edges:
        e.use_edge_sharp = True
    return obj


def lob(g):
    # the molten core, faceted
    g.add("glow", faceted(G.ell(C, (R * 0.86, R * 0.84, R * 0.86), 8, 5)))
    # dark crust plates floating on the core (the lava glows in the gaps)
    g.add("crust", *[faceted(G.ell(on_ball(yaw, p, 0.8), (0.1, 0.08, 0.035), 5, 3, rot=(-p, yaw, 0)))
                     for yaw, p in ((36, 20), (130, -24), (220, 10), (310, -14), (80, 46))])
    # five obsidian ribs: curved bands along the meridians, top collar to bottom cap
    ribs = []
    for yaw in (0, 72, 144, 216, 288):
        pts = [on_ball(yaw + 6 * math.sin(math.radians(p)), p, 1.04) for p in (62, 22, -22, -64)]
        for a, b in zip(pts, pts[1:]):
            mid = [(u + v) / 2 - c for u, v, c in zip(a, b, C)]
            ribs.append(G.bar(a, b, 0.07, 0.04, bevel=0.0, up=mid))
    g.add("body", *ribs,
          G.rod((0, C[1] + 0.22, 0), (0, C[1] + 0.3, 0), 0.15, 7),  # top collar the ribs meet in
          G.rod((0, C[1] - 0.24, 0), (0, C[1] - 0.3, 0), 0.13, 7),  # bottom cap
          G.rod((0, C[1] - 0.29, 0), (0, C[1] - 0.47, 0), 0.08, 5, top=0.05))  # its spike
    g.add("steel", G.rod((0, 0.25, 0), (0, 0.38, 0), 0.075, 7))  # fuse head (dark iron)
    g.add("glow", G.ell((0, 0.39, 0), (0.055, 0.03, 0.055), 6, 3))  # glowing fuse cap
    g.add("brass",
          G.bar((0.08, 0.36, 0), (0.25, 0.1, 0), 0.07, 0.025, up=(1, 0, 0)),  # spoon lever
          G.bar((0.25, 0.1, 0), (0.3, -0.1, 0), 0.07, 0.025, up=(1, 0, 0)),
          G.ring((-0.13, 0.36, 0), 0.07, 0.016, 8, 3, axis="z"))  # pull ring


def build(lp):
    g = G.Gun(lp, D.GRENADE, D.CAP)
    lob(g)
    meta = {"hero": "RIFLE", "prop": "grenade", "display": "Lava Lob", "skin": "LAVA_LOB",
            "base": "kit/RIFLE_GRENADE", "centre": [0, 0, 0], "theme": "LAVA_LORD", "premium": True, "version": 2}
    return g.model("11p1", "small", {"body": (34, 30, 38), "crust": (58, 44, 44), "glow": (255, 112, 20),
                                      "steel": (52, 48, 54), "brass": (120, 70, 42)}, meta)
