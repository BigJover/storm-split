"""RIFLE_LAVA_LANCE v2 - Hunting Rifle premium skin Lava Lance (Lava Lord theme, PREMIUM_SKINS.md, batch
11p1, #462: its own silhouette). A rifle hewn from volcanic rock around a magma heart:

  * a jagged faceted obsidian stock (angular rock profile, a glowing crack down each side) and a
    rock fore-end with a cracked keel underneath
  * a magma reservoir slung under the fore-end: a glowing molten core in a dark-bronze cage
  * a heavy obsidian heat shroud over the barrel with four glowing vent slots on each side and a
    long vent along the top (the vents are what the pack tier's heat ramp shows: cool -> white-hot)
  * a crown of obsidian spikes round the muzzle (behind the tip, the muzzle lane stays clear)
  * an ember stone (`accent`) set in the butt where the class badge was

The receiver, barrel, trigger, guard and the `muzzle` piece are the base's; grip at (0, 0, 0).
Sling, swivels, bolt knob, rear sight, barrel band, stock, grip and fore-end are dropped (grip
re-added lighter). `glow` = Neon in game. Base: gun/RIFLE (variants/_skins.py), cap 864 with Belt Fed.
"""
# art-sources: _rifle.py variants/_skins.py

import importlib.util
import math
from pathlib import Path

_spec = importlib.util.spec_from_file_location("_skins", Path(__file__).with_name("variants") / "_skins.py")
S = importlib.util.module_from_spec(_spec)
_spec.loader.exec_module(S)


def crack(G, x, pts, r=0.016):
    """A seam on a flat side at x: pts are (y, z)."""
    return [G.rod((x, y0, z0), (x, y1, z1), r, 3) for (y0, z0), (y1, z1) in zip(pts, pts[1:])]


def extra(g, G, D):
    w = 0.08
    # jagged rock stock: an angular profile (z, y), wider than the walnut one
    g.add("wood",
          G.slab([(0.14, 0.22), (0.5, 0.26), (0.7, 0.31), (1.04, 0.29), (1.06, -0.06), (0.98, -0.22),
                  (0.74, -0.13), (0.42, -0.05), (0.16, 0.04)], -w, w, bevel=0.0),  # sharp rock facets
          G.rbox((0, -0.06, 0.07), (0.12, 0.28, 0.14), bevel=0.0, rot=(-22, 0, 0)),  # grip, lighter
          # rock fore-end with a keel underneath
          G.slab([(-0.22, 0.2), (-0.98, 0.2), (-1.04, 0.12), (-0.86, 0.02), (-0.72, -0.07), (-0.64, 0.04), (-0.28, 0.04),
                  (-0.22, 0.06)], -0.07, 0.07, bevel=0.0))
    for k in (-1, 1):
        x = (w + 0.004) * k
        g.add("glow", *crack(G, x, [(0.22, 0.2), (0.12, 0.38), (0.18, 0.58), (0.06, 0.78), (-0.06, 0.98)]),
              *crack(G, 0.074 * k, [(0.16, -0.3), (0.06, -0.5), (-0.02, -0.72)]))
    # magma reservoir: a molten core in a dark-bronze cage, slung under the fore-end like a magazine
    cz, cy = -0.46, -0.07
    g.add("glow", G.ell((0, cy - 0.02, cz), (0.095, 0.1, 0.15), 6, 4))
    g.add("brass",
          *[G.rod((0.105 * math.cos(a), cy - 0.02 + 0.105 * math.sin(a), cz + 0.16), (0.105 * math.cos(a), cy - 0.02 + 0.105 * math.sin(a), cz - 0.16), 0.014, 3)
            for a in (math.radians(d) for d in (0, 120, 240))])
    # heat shroud over the barrel, vents on both sides + a row on top
    g.add("dark", G.rbox((0, D.BORE + 0.005, -0.98), (0.15, 0.15, 0.62), bevel=0.0, taper=(0.8, 1.0)))
    g.add("glow",
          *[G.rbox((0.072 * k, D.BORE - 0.005, z), (0.012, 0.08, 0.07), bevel=0.0) for k in (-1, 1) for z in (-0.8, -0.98, -1.16)],
          G.rbox((0, D.BORE + 0.08, -0.98), (0.05, 0.012, 0.3), bevel=0.0))  # one long vent along the top
    # crown of obsidian spikes round the barrel behind the muzzle (pointing out and a little forward)
    spikes = []
    for d in (45, 135, 225, 315):
        a = math.radians(d)
        ca, sa = math.cos(a), math.sin(a)
        spikes.append(G.rod((0.05 * ca, D.BORE + 0.05 * sa, -1.48), (0.14 * ca, D.BORE + 0.14 * sa, -1.62), 0.032, 3, top=0.05))
    g.add("dark", *spikes, G.rod((0, D.BORE, -1.44), (0, D.BORE, -1.52), 0.075, 6))
    g.add("glow", G.ring((0, D.BORE, -1.53), 0.07, 0.012, 6, 3, axis="z"))
    g.add("accent", G.ell((-(w + 0.004), 0.08, 0.64), (0.014, 0.07, 0.1), 6, 3))  # ember stone


def build(lp):
    model = S.variant(
        lp, "RIFLE", "LAVA_LANCE", "Lava Lance",
        drop=[("wood", 0), ("wood", 2), ("wood", 3),  # stock, grip (re-added lighter), fore-end -> rock
              ("steel", 3), ("steel", 4), ("steel", 6), ("steel", 7),  # knob, rear sight, swivels
              ("leather", 0), ("leather", 1), ("leather", 2), ("leather", 3), ("brass", 0), ("accent", 0)],  # sling, barrel band, badge
        extra=extra,
        colors={"wood": (40, 34, 42), "steel": (62, 58, 66), "brass": (150, 84, 44), "dark": (28, 24, 30),
                "accent": (236, 96, 28), "glow": (255, 112, 20)},
    )
    model["batch"] = "11p1"
    model["meta"].update({"theme": "LAVA_LORD", "premium": True, "version": 2})
    return model
