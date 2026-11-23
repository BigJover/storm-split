"""PISTOL_MOONSHOT - Tracker revolver premium skin Moonshot (Nebula theme, PREMIUM_SKINS.md, batch 11p5,
#462: its own silhouette, element cosmic / void). A sleek void-stalker's cosmic blaster:

  * a GALAXY CORE where the cylinder was: a glowing core sphere inside a tilted orbit ring, a pale
    moon riding the ring
  * a sleek indigo barrel shroud that tapers to the tip, starlight lines down both sides, a swept
    comet fin on top ending in a star sight
  * a crescent-moon grip (a curved indigo slab, a starlight line down each side) with a pink star
    gem (`accent`) at its heel

Frame, barrel, top strap, trigger, guard and the `muzzle` piece are the base's; grip (0, 0, 0).
Base: gun/PISTOL (variants/_skins.py), cap 880 with the Scope. `glow` = Neon in game.
"""
# art-sources: _pistol.py variants/_skins.py

import importlib.util
import math
from pathlib import Path

_spec = importlib.util.spec_from_file_location("_skins", Path(__file__).with_name("variants") / "_skins.py")
S = importlib.util.module_from_spec(_spec)
_spec.loader.exec_module(S)


def extra(g, G, D):
    bore = D.BORE
    cy = bore - 0.01
    # galaxy core in the cylinder's place: core + tilted orbit ring + a moon on it
    g.add("glow", G.ell((0, cy, -0.045), (0.09, 0.09, 0.09), 8, 5),
          G.ring((0, cy, -0.045), 0.13, 0.014, 12, 3, axis="x", rot=(0, 0, 30)))
    a = math.radians(40)
    g.add("brass", G.ell((0, cy + 0.13 * math.cos(a) * math.cos(math.radians(30)), -0.045 + 0.13 * math.sin(a)), (0.035, 0.035, 0.035), 6, 3))
    g.add("dark", G.rod((0, cy, 0.08), (0, cy, 0.04), 0.1, 8), G.rod((0, cy, -0.13), (0, cy, -0.17), 0.1, 8))  # caps either side
    # tapered shroud over the barrel with starlight lines
    g.add("dark", G.rod((0, bore, -0.18), (0, bore, -0.76), 0.075, 6, top=0.7))
    g.add("glow", *[G.rbox((0.062 * k, bore, -0.46), (0.012, 0.02, 0.5), bevel=0.0, rot=(0, 2.4 * k, 0)) for k in (-1, 1)])
    # swept comet fin on top, a star sight at its head
    g.add("wood", G.slab([(0.1, 0.36), (-0.2, 0.36), (-0.62, 0.33), (-0.7, 0.36), (-0.4, 0.42), (0.0, 0.46), (0.14, 0.42)],
                         -0.02, 0.02, bevel=0.0))
    g.add("glow", G.ell((0, 0.37, -0.68), (0.04, 0.04, 0.04), 4, 2),
          G.rod((0, 0.445, 0.0), (0, 0.41, -0.4), 0.012, 3))
    # crescent-moon grip: a curved slab, fuller at the back, its horn tucked under the frame
    g.add("wood", G.slab([(0.02, 0.16), (0.16, 0.18), (0.26, 0.04), (0.28, -0.12), (0.2, -0.27), (0.08, -0.3), (0.13, -0.18),
                          (0.15, -0.04), (0.08, 0.08), (-0.02, 0.1)], -0.065, 0.065, bevel=0.0))
    for k in (-1, 1):
        x = 0.069 * k
        pts = [(0.17, 0.12), (0.22, 0.0), (0.22, -0.13), (0.15, -0.24)]
        g.add("glow", *[G.rod((x, y0, z0), (x, y1, z1), 0.012, 3) for (z0, y0), (z1, y1) in zip(pts, pts[1:])])
    g.add("accent", G.ell((0, -0.27, 0.13), (0.07, 0.03, 0.03), 4, 2), G.ell((0, -0.27, 0.13), (0.03, 0.03, 0.07), 4, 2))


def build(lp):
    model = S.variant(
        lp, "PISTOL", "MOONSHOT", "Moonshot",
        drop=[("steel", 2), ("steel", 4), ("steel", 6),  # cylinder, underlug, hammer -> galaxy core, shroud, fin
              ("wood", 0), ("brass", 0), ("brass", 2), ("accent", 0), ("accent", 1)],  # grip -> crescent; cap, blade, medallions
        extra=extra,
        colors={"wood": (40, 38, 100), "steel": (70, 66, 112), "brass": (236, 234, 250), "dark": (26, 24, 54),
                "accent": (214, 88, 184), "glow": (150, 236, 240)},
    )
    model["batch"] = "11p5"
    model["meta"].update({"theme": "NEBULA", "premium": True})
    return model
