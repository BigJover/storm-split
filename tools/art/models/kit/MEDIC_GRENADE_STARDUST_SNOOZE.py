"""MEDIC_GRENADE_STARDUST_SNOOZE - the Field Medic's grenade, premium skin Stardust Snooze (Nebula theme,
PREMIUM_SKINS.md, batch 11p5, #462: its own silhouette, element cosmic / void). A sleepy moon canister:
a deep-violet canister wearing a floppy NIGHTCAP (a drooping cone with a star pompom) over the valve, a
starlight crescent moon on its front with a sleepy closed eye, a silver band of star specks, stardust
puffing from the nozzle. `glow` = Neon in game. Same frame as the base (kit/_prop.py: origin = the
thrown canister's centre, upright), <= 600 tris.
"""

import importlib.util
import math
from pathlib import Path

_spec = importlib.util.spec_from_file_location("_prop", Path(__file__).with_name("_prop.py"))
D = importlib.util.module_from_spec(_spec)
_spec.loader.exec_module(D)
G = D.G


def snooze(g):
    g.add("body", G.rod((0, -0.36, 0), (0, 0.16, 0), 0.22, 10, bevel=0.04))
    g.add("steel", G.rod((0, 0.14, 0), (0, 0.25, 0), 0.15, 10, top=0.7),
          G.rbox((0, 0.3, -0.1), (0.05, 0.05, 0.14), bevel=0.012))  # nozzle
    g.add("band", G.rod((0, -0.3, 0), (0, -0.22, 0), 0.228, 10))
    g.add("glow", *[G.ell((0.228 * math.sin(math.radians(a)), -0.26, -0.228 * math.cos(math.radians(a))), (0.025, 0.025, 0.025), 4, 2)
                    for a in range(0, 360, 60)])
    # the nightcap: a drooping cone in two segments, a star pompom at its tip
    g.add("cap", G.rod((0, 0.22, 0.02), (0.02, 0.4, 0.06), 0.16, 8, top=0.55),
          G.rod((0.02, 0.4, 0.06), (0.16, 0.44, 0.16), 0.088, 6, top=0.25))
    g.add("cuff", G.ring((0, 0.24, 0.02), 0.16, 0.035, 10, 3, axis="y"))
    g.add("glow", G.ell((0.2, 0.43, 0.2), (0.06, 0.06, 0.06), 6, 3),
          G.ell((0.2, 0.43, 0.2), (0.12, 0.024, 0.024), 4, 2), G.ell((0.2, 0.43, 0.2), (0.024, 0.11, 0.024), 4, 2))
    # sleepy crescent moon on the front (a glowing disc, bitten by a body-coloured disc), a closed eye
    arc = []
    angs = [100, 140, 180, 220, 260]
    pts = [(0.1 * math.cos(math.radians(a)), -0.06 + 0.12 * math.sin(math.radians(a)), -0.228) for a in angs]
    for i, (p, q) in enumerate(zip(pts, pts[1:])):
        r = 0.022 if i in (0, 3) else 0.034
        arc.append(G.rod(p, q, r, 5, top=0.75 if i == 3 else (1.3 if i == 0 else 1.0)))
    g.add("glow", *arc)
    g.add("dark", G.bar((-0.06, -0.04, -0.235), (-0.02, -0.055, -0.235), 0.01, 0.012))
    # stardust puffing from the nozzle
    g.add("glow", *[G.ell((x, y, z), (s, s, s), 4, 2) for x, y, z, s in
                    ((0.0, 0.33, -0.22, 0.03), (0.05, 0.37, -0.3, 0.025), (-0.04, 0.4, -0.36, 0.022), (0.03, 0.46, -0.42, 0.018))])


def build(lp):
    g = G.Gun(lp, D.GRENADE, D.CAP)
    snooze(g)
    meta = {"hero": "MEDIC", "prop": "grenade", "display": "Stardust Snooze", "skin": "STARDUST_SNOOZE",
            "base": "kit/MEDIC_GRENADE", "centre": [0, 0, 0], "theme": "NEBULA", "premium": True}
    return g.model("11p5", "small", {"body": (70, 46, 140), "steel": (186, 182, 222), "band": (186, 182, 222),
                                      "cap": (214, 88, 184), "cuff": (240, 240, 255), "glow": (150, 236, 240),
                                      "dark": (30, 24, 60)}, meta)
