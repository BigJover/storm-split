"""MEDIC_MOONBEAM - Field Medic carbine premium skin Moonbeam (Nebula theme, PREMIUM_SKINS.md, batch 11p5,
#462: its own silhouette, element cosmic / void). A celestial healer's lever carbine:

  * a CRESCENT-MOON stock: the butt sweeps into a moon-silver crescent (its horns point back), a
    starlight line along its inner curve
  * a STAR VIAL fore-grip where the wooden fore-end was: a glowing starlight capsule in a silver
    cage, a star on its front cap
  * a moonbeam along the barrel: a starlight rod under it threaded through three orbit rings
  * a full moon on the receiver's side (a silver disc with craters), a nebula-pink four-point star
    cross (`accent`) on the butt where the green cross was

Receiver, barrel, magazine tube, lever, trigger, sight and the `muzzle` piece are the base's; grip at
(0, 0, 0). Base: gun/MEDIC (variants/_skins.py), cap 1,200 (no attachments). `glow` = Neon in game.
"""
# art-sources: _medic.py variants/_skins.py

import importlib.util
from pathlib import Path

_spec = importlib.util.spec_from_file_location("_skins", Path(__file__).with_name("variants") / "_skins.py")
S = importlib.util.module_from_spec(_spec)
_spec.loader.exec_module(S)


def extra(g, G, D):
    w = 0.07
    # crescent stock: wrist to a crescent whose two horns point back
    g.add("wood", G.slab([(0.2, 0.22), (0.5, 0.24), (0.8, 0.34), (1.06, 0.42), (0.84, 0.22), (0.76, 0.04), (0.84, -0.14),
                          (1.06, -0.3), (0.8, -0.22), (0.5, -0.1), (0.3, 0.0), (0.2, 0.06)], -w, w, bevel=0.0))
    for k in (-1, 1):
        x = (w + 0.004) * k
        pts = [(0.36, 0.98), (0.22, 0.85), (0.04, 0.77), (-0.12, 0.85), (-0.24, 0.98)]  # (y, z): the inner curve
        g.add("glow", *[G.rod((x, y0, z0), (x, y1, z1), 0.014, 3) for (y0, z0), (y1, z1) in zip(pts, pts[1:])])
    # star vial fore-grip round the tube
    g.add("glow", G.rod((0, 0.155, -0.36), (0, 0.155, -0.82), 0.068, 8))
    g.add("brass", G.rod((0, 0.155, -0.32), (0, 0.155, -0.38), 0.082, 8), G.rod((0, 0.155, -0.8), (0, 0.155, -0.86), 0.082, 8),
          *[G.rod((0.075 * c, 0.155 + 0.075 * s, -0.36), (0.075 * c, 0.155 + 0.075 * s, -0.82), 0.012, 3) for c, s in ((1, 0), (-1, 0), (0, -1))])
    g.add("glow", G.ell((0, 0.155, -0.88), (0.04, 0.04, 0.02), 4, 2))
    # moonbeam under the barrel through orbit rings
    g.add("glow", G.rod((0, 0.17, -0.9), (0, 0.17, -1.3), 0.018, 4))
    g.add("brass", *[G.ring((0, 0.2, z), 0.075, 0.014, 10, 3, axis="z") for z in (-0.98, -1.1, -1.22)])
    # full moon on the receiver's left side, craters
    g.add("moon", G.rod((-0.07, 0.19, -0.06), (-0.09, 0.19, -0.06), 0.085, 10))
    g.add("crater", *[G.rod((-0.088, 0.19 + dy, -0.06 + dz), (-0.096, 0.19 + dy, -0.06 + dz), r, 6)
                      for dy, dz, r in ((0.03, -0.02, 0.022), (-0.03, 0.03, 0.016), (-0.01, -0.045, 0.012))])
    # pink star cross on the butt's left
    g.add("accent", G.ell((-(w + 0.004), 0.04, 0.62), (0.014, 0.1, 0.03), 4, 2), G.ell((-(w + 0.004), 0.04, 0.62), (0.014, 0.03, 0.1), 4, 2))


def build(lp):
    model = S.variant(
        lp, "MEDIC", "MOONBEAM", "Moonbeam",
        drop=[("wood", 0), ("wood", 2),  # stock -> crescent, fore-end -> star vial
              ("steel", 2), ("steel", 3),  # barrel bands -> orbit rings
              ("cloth", 0), ("accent", 0), ("accent", 1), ("dark", 0)],  # bandage, green cross -> star cross, butt plate
        extra=extra,
        colors={"wood": (206, 200, 236), "steel": (64, 60, 110), "brass": (186, 182, 222), "dark": (30, 28, 64),
                "moon": (226, 224, 244), "crater": (150, 142, 186), "accent": (214, 88, 184), "glow": (150, 236, 240)},
    )
    model["batch"] = "11p5"
    model["meta"].update({"theme": "NEBULA", "premium": True})
    return model
