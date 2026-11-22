"""MEDIC_GRENADE_SLEEP_MODE - the Field Medic's grenade (Dozy Cloud), premium skin Sleep Mode (Cyber
Raptor theme, PREMIUM_SKINS.md, batch 11p3, #462: its own silhouette, element electric / digital
glitch). A white-chrome power cell put to sleep: a rounded canister with a big glowing power-button
symbol on the front, a stack of battery bars glowing down its back, black-chrome caps, a vent valve
on top under a glowing crescent-moon fin (the sleep icon), and a pixel "z" on the side.
`glow` = Neon (Shared/SkinFx: laser-cyan blast ring with square pixel sparks). Same frame as the
base (kit/_prop.py: origin = the thrown 0.9 ball's centre, upright), <= 600 tris.
"""

import importlib.util
import math
from pathlib import Path

_spec = importlib.util.spec_from_file_location("_prop", Path(__file__).with_name("_prop.py"))
D = importlib.util.module_from_spec(_spec)
_spec.loader.exec_module(D)
G = D.G

COLORS = {"body": (226, 232, 240), "plate": (30, 32, 44), "chrome": (138, 148, 166), "glow": (0, 236, 255),
          "accent": (230, 60, 220)}


def cell(g):
    r = 0.23
    g.add("body", G.rod((0, -0.3, 0), (0, 0.18, 0), r, 10))
    g.add("plate",
          G.rod((0, -0.36, 0), (0, -0.28, 0), r * 1.06, 10),  # bottom cap
          G.rod((0, 0.16, 0), (0, 0.26, 0), r * 1.06, 10, top=0.75))  # top cap
    # power symbol: a ring open at the top, the bar through the gap
    arc = []
    n = 9
    for i in range(n):
        a0 = math.radians(130 + i * 280 / n)
        a1 = math.radians(130 + (i + 1) * 280 / n)
        p = (0.1 * math.cos(a0), -0.06 + 0.1 * math.sin(a0), -r - 0.005)
        q = (0.1 * math.cos(a1), -0.06 + 0.1 * math.sin(a1), -r - 0.005)
        arc.append(G.rod(p, q, 0.017, 4))
    g.add("glow", *arc,
          G.rbox((0, 0.0, -r - 0.005), (0.035, 0.12, 0.02), bevel=0.0),
          *[G.rbox((0, y, r + 0.005), (0.14, 0.05, 0.02), bevel=0.0) for y in (-0.22, -0.14, -0.06, 0.02)],  # battery bars
          # crescent moon fin on top: two offset discs, the glowing one peeking out
          G.rod((0.0, 0.4, -0.02), (0.0, 0.4, 0.02), 0.11, 10))
    g.add("plate", G.rod((0.045, 0.43, -0.025), (0.045, 0.43, 0.025), 0.1, 10))  # the moon's shadow
    g.add("chrome",
          G.rod((0, 0.24, 0), (0, 0.33, 0), 0.06, 8),  # valve
          G.ring((0, 0.31, 0), 0.08, 0.016, 8, 3, axis="y"))  # valve wheel
    # a pixel "z" on the right side
    x = r + 0.005
    g.add("accent",
          G.rbox((x, 0.06, 0), (0.02, 0.025, 0.1), bevel=0.0),
          G.rbox((x, -0.04, 0), (0.02, 0.025, 0.1), bevel=0.0),
          G.rbox((x, 0.01, 0), (0.02, 0.1, 0.025), bevel=0.0, rot=(45, 0, 0)))


def build(lp):
    g = G.Gun(lp, D.GRENADE, D.CAP)
    cell(g)
    meta = {"hero": "MEDIC", "prop": "grenade", "display": "Sleep Mode", "skin": "SLEEP_MODE",
            "base": "kit/MEDIC_GRENADE", "centre": [0, 0, 0], "theme": "CYBER_RAPTOR", "premium": True}
    return g.model("11p3", "small", COLORS, meta)
