"""PISTOL_GRENADE_GLITCH_BOMB - the Tracker's grenade (Stink Bomb), premium skin Glitch Bomb (Cyber Raptor
theme, PREMIUM_SKINS.md, batch 11p3, #462: its own silhouette, element electric / digital glitch). A
black-chrome cube caught mid-glitch: five horizontal slices knocked sideways out of line, glowing
seams between them, three loose pixel cubes breaking off one corner, a gunmetal cap with a little
antenna and a glowing tip on top, a magenta `accent` pixel. `glow` = Neon (Shared/SkinFx: laser-cyan
blast ring with square pixel sparks). Same frame as the base (kit/_prop.py: origin = the thrown
0.9 ball's centre, upright), <= 600 tris. Runtime key kit/<HERO>_GRENADE_<SKIN KEY>.
"""

import importlib.util
from pathlib import Path

_spec = importlib.util.spec_from_file_location("_prop", Path(__file__).with_name("_prop.py"))
D = importlib.util.module_from_spec(_spec)
_spec.loader.exec_module(D)
G = D.G

COLORS = {"body": (30, 32, 44), "chrome": (138, 148, 166), "glow": (0, 236, 255), "accent": (230, 60, 220)}


def bomb(g):
    s, h = 0.52, 0.1  # the cube's side, a slice's height
    shifts = ((0.0, 0.0), (0.07, -0.02), (-0.05, 0.04), (0.1, 0.03), (-0.03, -0.06))
    slices, seams = [], []
    for i, (dx, dz) in enumerate(shifts):
        y = -0.24 + i * (h + 0.012)
        slices.append(G.rbox((dx, y, dz), (s, h, s), bevel=0.0))
        if i:
            seams.append(G.rbox((dx * 0.5, y - h / 2 - 0.006, dz * 0.5), (s - 0.06, 0.016, s - 0.06), bevel=0.0))
    g.add("body", *slices)
    g.add("glow", *seams,
          # loose pixels breaking off the top-right corner
          G.rbox((0.3, 0.24, -0.27), (0.08, 0.08, 0.08), bevel=0.0),
          G.rbox((0.36, 0.31, -0.33), (0.065, 0.065, 0.065), bevel=0.0),
          # pixel "eyes" on the front: a glitchy face for the bomb
          *[G.rbox((0.09 * k + 0.05, 0.02, -0.29), (0.07, 0.07, 0.02), bevel=0.0) for k in (-1, 1)],
          G.ell((-0.06, 0.48, 0.0), (0.035, 0.035, 0.035), 6, 3))  # antenna tip
    g.add("accent", G.rbox((0.41, 0.37, -0.38), (0.05, 0.05, 0.05), bevel=0.0), G.rbox((-0.31, -0.2, 0.27), (0.06, 0.06, 0.06), bevel=0.0))
    g.add("chrome",
          G.rbox((-0.03, 0.27, -0.06), (0.3, 0.07, 0.3), bevel=0.0),  # cap
          G.rod((-0.06, 0.3, 0.0), (-0.06, 0.46, 0.0), 0.016, 4),  # antenna
          G.ring((0.16, 0.32, -0.06), 0.06, 0.014, 8, 3, axis="z"))  # pull ring


def build(lp):
    g = G.Gun(lp, D.GRENADE, D.CAP)
    bomb(g)
    meta = {"hero": "PISTOL", "prop": "grenade", "display": "Glitch Bomb", "skin": "GLITCH_BOMB",
            "base": "kit/PISTOL_GRENADE", "centre": [0, 0, 0], "theme": "CYBER_RAPTOR", "premium": True}
    return g.model("11p3", "small", COLORS, meta)
