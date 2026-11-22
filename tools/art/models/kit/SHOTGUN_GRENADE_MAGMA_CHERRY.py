"""SHOTGUN_GRENADE_MAGMA_CHERRY - the Brush Beater's grenade (Cherry Bomb), premium skin Magma Cherry (Lava
Lord theme, PREMIUM_SKINS.md, batch 11p2, #462: its own silhouette). A pair of lava cherries on one
stem: two molten balls crusted with obsidian plates (the lava glows between them), hanging from a
forked obsidian stem with a basalt leaf; the stem's top is the fuse, curling up to a glowing lit
end. `glow` = Neon (Shared/SkinFx: blast orange with a dark smoke puff; the pack tier's fire trail
+ splash). Same frame as the base (kit/_prop.py: origin = the thrown 0.9 ball's centre, upright),
<= 600 tris.
"""

import importlib.util
import math
from pathlib import Path

_spec = importlib.util.spec_from_file_location("_prop", Path(__file__).with_name("_prop.py"))
D = importlib.util.module_from_spec(_spec)
_spec.loader.exec_module(D)
G = D.G

BALLS = (((-0.19, -0.2, 0.02), 0.22), ((0.2, -0.24, -0.03), 0.21))


def faceted(obj):
    for e in obj.data.edges:
        e.use_edge_sharp = True
    return obj


def cherry(g):
    crust, cores = [], []
    for (cx, cy, cz), r in BALLS:
        cores.append(faceted(G.ell((cx, cy, cz), (r * 0.92, r * 0.9, r * 0.92), 7, 4)))
        for yaw, pitch in ((0, 30), (100, 10), (200, 34), (290, -10), (50, -40), (170, -38), (250, 60)):
            y, p = math.radians(yaw), math.radians(pitch)
            pos = (cx + r * 0.66 * math.cos(p) * math.sin(y), cy + r * 0.66 * math.sin(p), cz - r * 0.66 * math.cos(p) * math.cos(y))
            crust.append(faceted(G.ell(pos, (0.105, 0.1, 0.105), 6, 3)))
    g.add("glow", *cores)
    g.add("body", *crust)
    # forked stem from each ball's top up to a knot, the fuse curling on from it
    knot = (0.02, 0.2, 0.0)
    stems = [G.rod((cx, cy + r * 0.85, cz), knot, 0.03, 4) for (cx, cy, cz), r in BALLS]
    g.add("stem", *stems, G.ell(knot, (0.05, 0.05, 0.05), 5, 3))
    fuse = [knot, (0.04, 0.3, -0.02), (0.1, 0.38, -0.02), (0.18, 0.4, 0.0)]
    g.add("dark", *[G.rod(a, b, 0.022, 4) for a, b in zip(fuse, fuse[1:])])
    g.add("glow", G.ell((0.2, 0.41, 0.0), (0.05, 0.05, 0.05), 5, 3))
    # a basalt leaf off the knot (a flat pointed slab with a glowing vein)
    g.add("leaf", G.ell((-0.16, 0.3, 0.02), (0.17, 0.04, 0.09), 6, 3, rot=(0, 0, -24)))
    g.add("glow", G.rod((-0.02, 0.24, 0.02), (-0.26, 0.355, 0.02), 0.012, 3))


def build(lp):
    g = G.Gun(lp, D.GRENADE, D.CAP)
    cherry(g)
    meta = {"hero": "SHOTGUN", "prop": "grenade", "display": "Magma Cherry", "skin": "MAGMA_CHERRY",
            "base": "kit/SHOTGUN_GRENADE", "centre": [0, 0, 0], "theme": "LAVA_LORD", "premium": True}
    return g.model("11p2", "small", {"body": (34, 30, 38), "stem": (40, 34, 42), "dark": (28, 24, 30),
                                      "leaf": (74, 64, 68), "glow": (255, 112, 20)}, meta)
