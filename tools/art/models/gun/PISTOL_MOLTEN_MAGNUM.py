"""PISTOL_MOLTEN_MAGNUM - Revolver premium skin Molten Magnum (Lava Lord theme, PREMIUM_SKINS.md, batch
11p2, #462: its own silhouette). A six-shooter cast round a magma heart:

  * the cylinder is a glowing molten drum held by four obsidian flutes (the lava shows between them;
    the pack tier's heat ramp reads off it)
  * a heavy faceted obsidian shroud over the barrel with three glowing vent slots a side and a
    jagged saw-tooth obsidian fin hanging under it, the lava line running along its spine
  * a spiked obsidian hammer, a hewn rock grip with a glowing crack down each side and an ember
    stone (`accent`) at its foot
  * a crown of three obsidian fangs round the muzzle (behind the tip: the muzzle lane stays clear)

The frame, top strap, barrel, trigger, guard and the `muzzle` piece are the base's; grip at (0, 0, 0).
Cylinder, underlug, hammer, walnut grip, butt cap, front blade and medallions are dropped.
`glow` = Neon in game. Base: gun/PISTOL (variants/_skins.py), cap 880 with the Scope.
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
    # molten cylinder: the glowing drum and four obsidian flutes round it
    cy = bore - 0.01
    g.add("glow", G.rod((0, cy, 0.07), (0, cy, -0.16), 0.1, 8))
    g.add("dark", *[G.rbox((0.1 * math.cos(a), cy + 0.1 * math.sin(a), -0.045), (0.04, 0.04, 0.25), bevel=0.0,
                           rot=(0, 0, math.degrees(a) + 45))
                    for a in (math.radians(d) for d in (45, 135, 225, 315))])
    # obsidian shroud over the barrel (hexagonal), vent slots both sides + a line along the top
    g.add("dark", G.rod((0, bore, -0.19), (0, bore, -0.7), 0.078, 6, top=0.9))
    g.add("glow",
          *[G.rbox((0.072 * k, bore, z), (0.012, 0.05, 0.08), bevel=0.0) for k in (-1, 1) for z in (-0.3, -0.44, -0.58)],
          G.rbox((0, bore + 0.073, -0.45), (0.03, 0.012, 0.42), bevel=0.0))
    # saw-tooth fin under the barrel
    g.add("dark", G.slab([(-0.18, 0.2), (-0.74, 0.2), (-0.72, 0.12), (-0.62, 0.15), (-0.56, 0.06), (-0.46, 0.13),
                          (-0.38, 0.02), (-0.28, 0.1), (-0.18, 0.08)], -0.028, 0.028, bevel=0.0))
    g.add("glow", G.rbox((0, 0.165, -0.46), (0.062, 0.016, 0.5), bevel=0.0))  # the lava line along the fin's spine
    # spiked hammer
    g.add("dark", G.rod((0, 0.3, 0.12), (0, 0.4, 0.22), 0.04, 4, top=0.1))
    # hewn rock grip (angular profile), a crack down each side, an ember stone at its foot
    g.add("wood", G.slab([(0.0, 0.17), (0.16, 0.19), (0.19, 0.02), (0.24, -0.19), (0.17, -0.25), (0.07, -0.22),
                          (0.03, -0.04), (-0.03, 0.08)], -0.065, 0.065, bevel=0.0))
    for k in (-1, 1):
        x = 0.069 * k
        pts = [(0.12, 0.15), (0.14, 0.04), (0.11, -0.08), (0.16, -0.19)]
        g.add("glow", *[G.rod((x, y0, z0), (x, y1, z1), 0.014, 3) for (z0, y0), (z1, y1) in zip(pts, pts[1:])])
    g.add("accent", G.ell((0, -0.235, 0.15), (0.055, 0.035, 0.06), 6, 3))
    # crown of three obsidian fangs round the barrel behind the muzzle
    fangs = []
    for d in (90, 210, 330):
        a = math.radians(d)
        ca, sa = math.cos(a), math.sin(a)
        fangs.append(G.rod((0.05 * ca, bore + 0.05 * sa, -0.7), (0.13 * ca, bore + 0.13 * sa, -0.8), 0.03, 3, top=0.05))
    g.add("dark", *fangs)
    g.add("glow", G.ring((0, bore, -0.72), 0.07, 0.014, 6, 3, axis="z"))


def build(lp):
    model = S.variant(
        lp, "PISTOL", "MOLTEN_MAGNUM", "Molten Magnum",
        drop=[("steel", 2), ("steel", 4), ("steel", 6),  # cylinder, underlug, hammer -> molten drum, fin, spike
              ("wood", 0), ("brass", 0), ("brass", 2), ("accent", 0), ("accent", 1)],  # grip -> rock; butt cap, blade, medallions
        extra=extra,
        colors={"wood": (40, 34, 42), "steel": (62, 58, 66), "brass": (150, 84, 44), "dark": (28, 24, 30),
                "accent": (236, 96, 28), "glow": (255, 112, 20)},
    )
    model["batch"] = "11p2"
    model["meta"].update({"theme": "LAVA_LORD", "premium": True})
    return model
