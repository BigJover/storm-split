"""PISTOL_GRENADE_BRIMSTONE_STINKER - the Tracker's grenade (Stink Bomb), premium skin Brimstone Stinker
(Lava Lord theme, PREMIUM_SKINS.md, batch 11p2, #462: its own silhouette). A stink bomb brewed in a
volcano: a squat faceted obsidian flask cracked open round its belly so the boiling brimstone glows
through (a molten band and cracks running from it), its neck a little smoking volcano with a
glowing crater and a rock plug, a charred rag knotted round it with ember-tipped tails, and clusters
of sulfur crystals (`sulfur`) growing off its shoulder and foot. `glow` = Neon (Shared/SkinFx: blast
orange with a dark smoke puff; the pack tier's fire trail + splash). Same frame as the base
(kit/_prop.py: origin = the thrown 0.9 ball's centre, upright), <= 600 tris.
"""

import importlib.util
import math
from pathlib import Path

_spec = importlib.util.spec_from_file_location("_prop", Path(__file__).with_name("_prop.py"))
D = importlib.util.module_from_spec(_spec)
_spec.loader.exec_module(D)
G = D.G

C = (0, -0.1, 0)
R = (0.34, 0.29, 0.34)


def faceted(obj):
    for e in obj.data.edges:
        e.use_edge_sharp = True
    return obj


def on(yaw, pitch, lift=1.0):
    y, p = math.radians(yaw), math.radians(pitch)
    return (C[0] + R[0] * lift * math.cos(p) * math.sin(y), C[1] + R[1] * lift * math.sin(p), C[2] - R[2] * lift * math.cos(p) * math.cos(y))


def crystal(g, base, direction, length, r):
    bx, by, bz = base
    dx, dy, dz = direction
    tip = (bx + dx * length, by + dy * length, bz + dz * length)
    return G.rod(base, tip, r, 4, top=0.15)


def stinker(g):
    # the flask: two faceted obsidian halves with a molten band between them (the brimstone inside)
    g.add("body",
          faceted(G.ell((C[0], C[1] + 0.1, C[2]), (R[0], R[1] * 0.78, R[2]), 8, 4)),
          faceted(G.ell((C[0], C[1] - 0.13, C[2]), (R[0] * 0.94, R[1] * 0.7, R[2] * 0.94), 8, 4)))
    g.add("glow", G.rod((0, C[1] - 0.08, 0), (0, C[1] + 0.05, 0), R[0] * 0.97, 8))
    # cracks running up and down from the band
    cracks = []
    for yaw, ps in ((20, (4, 26, 44)), (140, (-2, -24, -46)), (250, (2, 30, 50)), (320, (-4, -30, -50))):
        pts = [on(yaw + 8 * i * (1 if i % 2 else -1), p, 0.99) for i, p in enumerate(ps)]
        cracks += [G.rod(a, b, 0.018, 3) for a, b in zip(pts, pts[1:])]
    g.add("glow", *cracks)
    # neck: a little volcano cone with a glowing crater, a rock plug sitting in it
    g.add("body", G.rod((0, 0.12, 0), (0, 0.34, 0), 0.16, 7, top=0.5))
    g.add("glow", G.rod((0, 0.335, 0), (0, 0.35, 0), 0.075, 7), G.rod((0.03, 0.18, -0.13), (0.06, 0.32, -0.06), 0.02, 3))
    g.add("rock", faceted(G.ell((0, 0.37, 0), (0.08, 0.06, 0.08), 5, 3)))
    # the charred rag knotted round the neck, two tails with ember tips
    g.add("cloth", G.ring((0, 0.2, 0), 0.135, 0.032, 8, 4, axis="y"),
          G.rbox((0.17, 0.12, 0.02), (0.07, 0.16, 0.04), bevel=0.0, rot=(0, 0, -28)),
          G.rbox((0.21, 0.13, -0.06), (0.06, 0.13, 0.04), bevel=0.0, rot=(10, 0, -48)))
    g.add("glow", G.rbox((0.215, 0.03, 0.02), (0.05, 0.04, 0.04), bevel=0.0, rot=(0, 0, -28)),
          G.rbox((0.26, 0.06, -0.06), (0.04, 0.035, 0.04), bevel=0.0, rot=(10, 0, -48)))
    # sulfur crystals: a cluster on the shoulder, one at the foot
    g.add("sulfur",
          crystal(g, on(-60, 36, 0.92), (-0.55, 0.8, -0.25), 0.3, 0.065),
          crystal(g, on(-80, 26, 0.92), (-0.85, 0.45, 0.1), 0.24, 0.055),
          crystal(g, on(-40, 22, 0.92), (-0.4, 0.5, -0.75), 0.2, 0.05),
          crystal(g, on(120, -40, 0.9), (0.6, -0.6, 0.45), 0.22, 0.055),
          crystal(g, on(150, -46, 0.9), (0.3, -0.8, 0.55), 0.16, 0.045))


def build(lp):
    g = G.Gun(lp, D.GRENADE, D.CAP)
    stinker(g)
    meta = {"hero": "PISTOL", "prop": "grenade", "display": "Brimstone Stinker", "skin": "BRIMSTONE_STINKER",
            "base": "kit/PISTOL_GRENADE", "centre": [0, 0, 0], "theme": "LAVA_LORD", "premium": True}
    return g.model("11p2", "small", {"body": (34, 30, 38), "rock": (74, 64, 68), "cloth": (70, 52, 46),
                                      "sulfur": (232, 204, 64), "glow": (255, 112, 20)}, meta)
