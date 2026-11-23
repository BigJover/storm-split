"""SHOTGUN_SUPERNOVA - Brush Beater shotgun premium skin Supernova (Nebula theme, PREMIUM_SKINS.md, batch
11p5, #462: its own silhouette, element cosmic / void). A meteor brute's star-cannon:

  * a STAR CORE slung under the receiver where the magazine tube was: a big glowing core in a
    meteor-rock cradle, two orbit rings round it
  * a SUPERNOVA burst behind the muzzle: eight starlight rays fanned round the barrel in a dark
    collar (the muzzle and its lane stay clear in front)
  * a fore-grip of three stacked orbit rings where the pump was
  * a heavy cratered meteor-rock stock (angular profile), a starlight crack down each side, a pink
    nebula gem (`accent`) where the shells were

Receiver, barrel, grip, trigger, guard, butt pad and the `muzzle` piece are the base's; grip at
(0, 0, 0). Base: gun/SHOTGUN (variants/_skins.py), cap 868 with both attachments. `glow` = Neon.
"""
# art-sources: _shotgun.py variants/_skins.py

import importlib.util
import math
from pathlib import Path

_spec = importlib.util.spec_from_file_location("_skins", Path(__file__).with_name("variants") / "_skins.py")
S = importlib.util.module_from_spec(_spec)
_spec.loader.exec_module(S)


def extra(g, G, D):
    w = 0.08
    # meteor-rock stock (sharp facets)
    g.add("wood", G.slab([(0.18, 0.25), (0.46, 0.3), (0.78, 0.28), (1.02, 0.3), (1.04, -0.1), (0.96, -0.24), (0.7, -0.16),
                          (0.42, -0.06), (0.18, 0.06)], -w, w, bevel=0.0))
    for k in (-1, 1):
        x = (w + 0.004) * k
        pts = [(0.24, 0.22), (0.1, 0.4), (0.16, 0.62), (0.02, 0.8), (-0.12, 0.98)]
        g.add("glow", *[G.rod((x, y0, z0), (x, y1, z1), 0.014, 3) for (y0, z0), (y1, z1) in zip(pts, pts[1:])])
    # the star core under the receiver, in a rock cradle, two orbit rings
    cz, cy = -0.62, 0.06
    g.add("glow", G.ell((0, cy, cz), (0.11, 0.11, 0.13), 6, 4),
          G.ring((0, cy, cz), 0.19, 0.014, 10, 3, axis="x", rot=(0, 0, 25)))
    g.add("crater", G.rbox((0, cy - 0.06, cz), (0.18, 0.08, 0.34), bevel=0.0, taper=(0.7, 1.0)),
          G.rod((0, cy + 0.08, cz - 0.1), (0, D.BORE - 0.05, cz - 0.1), 0.025, 4),
          G.rod((0, cy + 0.08, cz + 0.12), (0, D.BORE - 0.05, cz + 0.12), 0.025, 4))
    # fore-grip: three stacked orbit rings
    g.add("brass", *[G.ring((0, 0.13, z), 0.08, 0.024, 8, 3, axis="z") for z in (-0.96, -1.08)])
    # supernova burst behind the muzzle
    zc = -1.3
    rays = []
    for i in range(8):
        a = math.radians(22.5 + 45 * i)
        ln = 0.135 if i % 2 else 0.1
        ca, sa = math.cos(a), math.sin(a)
        rays.append(G.rod((0.06 * ca, D.BORE + 0.06 * sa, zc), (ln * 1.4 * ca, D.BORE + ln * 1.4 * sa, zc + 0.05), 0.028, 3, top=0.05))
    g.add("glow", *rays)
    g.add("accent", G.ell((-0.085, 0.2, -0.02), (0.02, 0.08, 0.08), 4, 2), G.ell((-0.085, 0.2, -0.02), (0.02, 0.03, 0.14), 4, 2))


def build(lp):
    model = S.variant(
        lp, "SHOTGUN", "SUPERNOVA", "Supernova",
        drop=[("wood", 0), ("wood", 3), ("dark", 1),  # stock -> meteor rock, pump + groove -> orbit rings
              ("steel", 2), ("steel", 4),  # tube -> star core, saddle plate
              ("brass", 1), ("brass", 2), ("brass", 3),  # tube cap, bead, shell rim
              ("accent", 0), ("accent", 1), ("accent", 2), ("accent", 3)],  # the shells -> star gem
        extra=extra,
        colors={"wood": (86, 76, 122), "steel": (64, 60, 104), "brass": (190, 186, 224), "dark": (26, 24, 54),
                "crater": (50, 42, 84), "accent": (214, 88, 184), "glow": (150, 236, 240)},
    )
    model["batch"] = "11p5"
    model["meta"].update({"theme": "NEBULA", "premium": True})
    return model
