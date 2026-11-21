"""RIFLE_LAVA_LANCE - Hunting Rifle premium skin Lava Lance (Lava Lord theme, PREMIUM_SKINS.md, batch
11p1): an obsidian-stocked rifle split by cracked lava seams. Black volcanic-glass stock and fore-end
with glowing cracks on both sides, a molten channel down each side of the fore-end, three heat rings
glowing on the barrel, a dark-bronze band, and an obsidian lance blade under the muzzle (below the
bore, the muzzle lane stays clear). The sling and swivels are off. `glow` = Neon in game (Shared/
SkinFx pulses it; the tracer goes orange); `accent` (the skin's colour) = an ember stone set in the
butt where the class badge was. Base: gun/RIFLE (variants/_skins.py).
"""
# art-sources: _rifle.py variants/_skins.py

import importlib.util
from pathlib import Path

_spec = importlib.util.spec_from_file_location("_skins", Path(__file__).with_name("variants") / "_skins.py")
S = importlib.util.module_from_spec(_spec)
_spec.loader.exec_module(S)


def crack(G, x, pts, r=0.016):
    """A seam on a flat side at x: pts are (y, z)."""
    return [G.rod((x, y0, z0), (x, y1, z1), r, 3) for (y0, z0), (y1, z1) in zip(pts, pts[1:])]


def extra(g, G, D):
    g.add("wood", G.rbox((0, -0.06, 0.07), (0.12, 0.28, 0.14), bevel=0.045, segments=1, rot=(-22, 0, 0)))  # grip, lighter
    for k in (-1, 1):
        x = 0.072 * k
        g.add("glow",
              *crack(G, x, [(0.2, 0.22), (0.12, 0.36), (0.16, 0.5), (0.05, 0.66), (0.1, 0.8), (-0.04, 0.95)]),
              G.rbox((0.067 * k, 0.12, -0.6), (0.012, 0.035, 0.6), bevel=0.0))  # molten channel, fore-end
    g.add("glow", *[G.ring((0, D.BORE, z), 0.058, 0.012, 6, 3, axis="z") for z in (-1.15, -1.35)])
    g.add("dark",
          G.rbox((0, 0.175, -1.5), (0.06, 0.08, 0.14), bevel=0.0),  # blade lug under the barrel
          G.slab([(-1.44, 0.17), (-1.89, 0.14), (-1.72, 0.06), (-1.44, 0.09)], -0.024, 0.024, bevel=0.008))  # lance blade
    g.add("glow", G.slab([(-1.5, 0.125), (-1.78, 0.118), (-1.5, 0.112)], -0.021, 0.021, bevel=0.0))  # its hot edge line


def build(lp):
    model = S.variant(
        lp, "RIFLE", "LAVA_LANCE", "Lava Lance",
        drop=[("wood", 2), ("steel", 3), ("steel", 4), ("steel", 6), ("steel", 7), ("leather", 0), ("leather", 1), ("leather", 2), ("leather", 3)],  # grip (re-added lighter), knob, rear sight, swivels, sling
        extra=extra,
        colors={"wood": (40, 34, 42), "steel": (62, 58, 66), "brass": (150, 84, 44), "dark": (28, 24, 30),
                "accent": (236, 96, 28), "glow": (255, 112, 20)},
    )
    model["batch"] = "11p1"
    model["meta"].update({"theme": "LAVA_LORD", "premium": True})
    return model
