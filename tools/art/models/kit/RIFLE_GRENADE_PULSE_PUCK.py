"""RIFLE_GRENADE_PULSE_PUCK - the Big Game Hunter's grenade (Safari Grenade), premium skin Pulse Puck
(Cyber Raptor theme, PREMIUM_SKINS.md, batch 11p3, #462: its own silhouette, element electric /
digital glitch). A black-chrome pulse charge shaped like a thick puck: a glowing ring band round the
rim, a glowing core dome under a gunmetal crown on top, three raptor claws curling down round the
edge (it lands claws-first), circuit traces on the top face, a magenta `accent` arming light.
`glow` = Neon (Shared/SkinFx: laser-cyan blast ring with square pixel sparks). Same frame as the base
(kit/_prop.py: origin = the thrown 0.9 ball's centre, upright), <= 600 tris.
"""

import importlib.util
import math
from pathlib import Path

_spec = importlib.util.spec_from_file_location("_prop", Path(__file__).with_name("_prop.py"))
D = importlib.util.module_from_spec(_spec)
_spec.loader.exec_module(D)
G = D.G

COLORS = {"body": (30, 32, 44), "chrome": (138, 148, 166), "glow": (0, 236, 255), "accent": (230, 60, 220)}


def puck(g):
    r = 0.38
    g.add("body",
          G.rod((0, -0.12, 0), (0, 0.1, 0), r, 12),  # the puck
          G.rod((0, -0.12, 0), (0, -0.18, 0), r * 0.8, 12))  # bottom step
    g.add("glow",
          G.rod((0, -0.03, 0), (0, 0.01, 0), r + 0.012, 12),  # rim band
          G.ell((0, 0.12, 0), (0.17, 0.11, 0.17), 8, 4))  # core dome
    traces = []
    for i in range(3):
        a = math.radians(30 + 120 * i)
        ca, sa = math.cos(a), math.sin(a)
        p0 = (0.18 * ca, 0.105, 0.18 * sa)
        p1 = (0.28 * ca, 0.105, 0.28 * sa)
        b = a + 0.5
        p2 = (0.3 * math.cos(b), 0.105, 0.3 * math.sin(b))
        traces += [G.rod(p0, p1, 0.012, 4), G.rod(p1, p2, 0.012, 4), G.rbox(p2, (0.04, 0.012, 0.04), bevel=0.0)]
    g.add("glow", *traces)
    claws = []
    for i in range(3):
        a = math.radians(90 + 120 * i)
        ca, sa = math.cos(a), math.sin(a)
        pts = [(0.3 * ca, 0.06, 0.3 * sa), (0.44 * ca, 0.02, 0.44 * sa), (0.48 * ca, -0.16, 0.48 * sa), (0.42 * ca, -0.3, 0.42 * sa)]
        for j, (p, q) in enumerate(zip(pts, pts[1:])):
            claws.append(G.rod(p, q, 0.05 * (1 - j * 0.3), 5, top=(0.7 if j < 2 else 0.1)))
    g.add("chrome", *claws,
          *[G.rod((0.13 * math.cos(math.radians(a)), 0.1, 0.13 * math.sin(math.radians(a))),
                  (0.08 * math.cos(math.radians(a)), 0.3, 0.08 * math.sin(math.radians(a))), 0.025, 4) for a in (0, 90, 180, 270)],  # crown
          G.rod((0, 0.27, 0), (0, 0.34, 0), 0.07, 8),  # fuse button
          G.ring((0.15, 0.34, 0), 0.06, 0.014, 8, 3, axis="z"))  # pull ring
    g.add("accent", G.rbox((0, 0.0, -r - 0.01), (0.06, 0.06, 0.02), bevel=0.0))


def build(lp):
    g = G.Gun(lp, D.GRENADE, D.CAP)
    puck(g)
    meta = {"hero": "RIFLE", "prop": "grenade", "display": "Pulse Puck", "skin": "PULSE_PUCK",
            "base": "kit/RIFLE_GRENADE", "centre": [0, 0, 0], "theme": "CYBER_RAPTOR", "premium": True}
    return g.model("11p3", "small", COLORS, meta)
