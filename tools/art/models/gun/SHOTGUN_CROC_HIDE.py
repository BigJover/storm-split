"""SHOTGUN_CROC_HIDE - Shotgun skin Croc Hide (250K Amber, Stone Age Bundle): croc leather laced
over the stock and pump, a ridge of scutes along the stock's top, a croc tooth hanging off the
receiver on a cord; the side saddle comes off so the hide reads. `accent` (the skin's croc
green, Fabric) = the hide. Base: gun/SHOTGUN (variants/_skins.py).
"""
# art-sources: _shotgun.py variants/_skins.py

import importlib.util
from pathlib import Path

_spec = importlib.util.spec_from_file_location("_skins", Path(__file__).with_name("variants") / "_skins.py")
S = importlib.util.module_from_spec(_spec)
_spec.loader.exec_module(S)


def extra(g, G, D):
    g.add("accent",
          G.rbox((0, 0.12, 0.62), (0.17, 0.3, 0.5), bevel=0.05, segments=1),  # hide over the stock
          G.rod((0, 0.12, -0.6), (0, 0.12, -0.94), 0.092, 10))  # hide over the pump
    g.add("scute", *[G.ell((0, 0.28, z), (0.035, 0.03, 0.06), 6, 3) for z in (0.44, 0.62, 0.8)])
    g.add("dark", G.rod((0.06, 0.18, 0.1), (0.07, 0.0, 0.14), 0.01, 4))  # cord
    g.add("bone", G.ell((0.07, -0.06, 0.14), (0.02, 0.06, 0.02), 6, 3))  # tooth


def build(lp):
    return S.variant(
        lp, "SHOTGUN", "CROC_HIDE", "Croc Hide",
        drop=[("steel", 4), ("brass", 3)] + [("accent", i) for i in range(4)],  # side saddle, rim, shells
        extra=extra,
        colors={"accent": (80, 110, 70), "scute": (50, 70, 45), "bone": (226, 216, 186)},
    )
