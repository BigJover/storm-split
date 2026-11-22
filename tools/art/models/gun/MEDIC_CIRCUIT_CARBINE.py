"""MEDIC_CIRCUIT_CARBINE - the Field Medic's Lever-Action Carbine, premium skin Circuit Carbine (Cyber
Raptor theme, PREMIUM_SKINS.md, batch 11p3, #462: its own silhouette, element electric / digital
glitch). The Nano Medic's white-chrome carbine, a circuit board you can shoot:

  * a white-chrome receiver and stock; black circuit-board panels set in both sides of the stock
    with glowing traces and pads (the pack tier's charge glow)
  * a black-chrome fore-end tube with three glowing data rings and a glowing nano vial slung under
    it in a white cradle (where the magazine tube was)
  * a raptor-jaw emitter: two gunmetal prongs above and below the barrel, ending behind the
    muzzle (the lane stays clear), glowing tips
  * a holo sight (a glowing frame) and a small antenna fin, magenta `accent` stripe on the stock
  * the lever loop is kept, so it still reads as a lever-action

Barrel, lever loop, trigger and the `muzzle` piece are the base's; grip at (0, 0, 0). `glow` = Neon in
game. Base: gun/MEDIC (variants/_skins.py), cap 1,200 (no attachments).
"""
# art-sources: _medic.py variants/_skins.py

import importlib.util
from pathlib import Path

_spec = importlib.util.spec_from_file_location("_skins", Path(__file__).with_name("variants") / "_skins.py")
S = importlib.util.module_from_spec(_spec)
_spec.loader.exec_module(S)


def extra(g, G, D):
    y = D.BORE
    w = 0.072
    g.add("white",
          G.slab([(0.18, 0.34), (-0.3, 0.34), (-0.34, 0.26), (-0.28, 0.08), (0.18, 0.06)], -0.068, 0.068, bevel=0.0),  # receiver
          G.slab([(0.12, 0.26), (0.98, 0.2), (1.0, -0.16), (0.9, -0.2), (0.32, -0.02), (0.12, 0.04)], -w, w, bevel=0.0),  # stock
          G.rbox((0, 0.075, -0.92), (0.1, 0.07, 0.42), bevel=0.0))  # vial cradle
    g.add("plate",
          G.rod((0, 0.17, -0.3), (0, 0.17, -0.96), 0.075, 8),  # fore-end tube
          *[G.slab([(0.36, 0.14), (0.8, 0.12), (0.8, -0.08), (0.42, 0.0)], (w - 0.004) * k, (w + 0.01) * k, bevel=0.0) for k in (-1, 1)])  # board panels
    g.add("chrome",
          G.rbox((0, y + 0.1, -1.12), (0.07, 0.06, 0.46), bevel=0.0, taper=(0.8, 0.5)),  # upper jaw prong
          G.rbox((0, y - 0.1, -1.12), (0.07, 0.06, 0.46), bevel=0.0, taper=(0.8, 0.5)),  # lower jaw prong
          G.rbox((0, y - 0.01, -0.92), (0.12, 0.3, 0.1), bevel=0.0),  # the jaw's hinge block
          G.rbox((0, 0.38, -0.5), (0.02, 0.08, 0.26), bevel=0.0, taper=(1.0, 0.3)))  # antenna fin
    traces = []
    for k in (-1, 1):
        x = (w + 0.012) * k
        for pts in (((0.4, 0.1), (0.52, 0.1), (0.58, 0.04), (0.74, 0.04)),
                    ((0.46, 0.0), (0.6, -0.04), (0.76, -0.04)),
                    ((0.5, 0.1), (0.5, 0.06))):
            traces += [G.rod((x, ya, za), (x, yb, zb), 0.01, 4) for (za, ya), (zb, yb) in zip(pts, pts[1:])]
        traces += [G.rbox((x, yy, zz), (0.006, 0.03, 0.03), bevel=0.0) for zz, yy in ((0.74, 0.04), (0.76, -0.04), (0.4, 0.1))]
    g.add("glow", *traces,
          *[G.rod((0, 0.17, z), (0, 0.17, z - 0.03), 0.08, 8) for z in (-0.42, -0.6, -0.78)],  # data rings
          G.rod((0, 0.035, -0.74), (0, 0.035, -1.1), 0.045, 6),  # nano vial
          *[G.rbox((0, y + dy, -1.36), (0.03, 0.03, 0.04), bevel=0.0) for dy in (0.1, -0.1)],  # prong tips
          G.ring((0, 0.39, -0.2), 0.045, 0.01, 8, 3, axis="z"))  # holo sight frame
    g.add("chrome", G.rod((0, 0.34, -0.2), (0, 0.36, -0.2), 0.03, 4))
    g.add("accent", *[G.rbox((0.073 * k, 0.17, 0.6), (0.01, 0.03, 0.66), bevel=0.0, rot=(3, 0, 0)) for k in (-1, 1)])


def build(lp):
    model = S.variant(
        lp, "MEDIC", "CIRCUIT_CARBINE", "Circuit Carbine",
        drop=[("wood", 0), ("wood", 1), ("wood", 2), ("dark", 0), ("brass", 0), ("brass", 1), ("brass", 2),
              ("steel", 1), ("steel", 2), ("steel", 3), ("steel", 4), ("steel", 5), ("cloth", 0),
              ("accent", 0), ("accent", 1)],
        extra=extra,
        colors={"steel": (70, 74, 88), "white": (226, 232, 240), "plate": (30, 32, 44), "chrome": (138, 148, 166),
                "accent": (230, 60, 220), "glow": (0, 236, 255)},
    )
    model["batch"] = "11p3"
    model["meta"].update({"theme": "CYBER_RAPTOR", "premium": True})
    return model
