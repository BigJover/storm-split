"""SET_STONE_AGE - the Stone Age tower set's trim (400K Amber, Stone Age Bundle): a ring of
rough stone slabs round the footprint, a mossy boulder pile on the front-left corner and a pair
of crossed bone tusks on the back-left. Over any tower's art (variants/_sets.py).
"""
# art-sources: variants/_sets.py

import importlib.util
import math
from pathlib import Path

_spec = importlib.util.spec_from_file_location("_sets", Path(__file__).with_name("variants") / "_sets.py")
S = importlib.util.module_from_spec(_spec)
_spec.loader.exec_module(S)


def design(k, K):
    slabs = []
    for i, (a, b, h) in enumerate(((-1.5, -0.1, 0.24), (0.0, 1.5, 0.2))):
        slabs += [K.rbox(((a + b) / 2, h / 2, -1.39), (b - a - 0.06, h, 0.22), bevel=0.0),
                  K.rbox(((a + b) / 2, h / 2, 1.39), (b - a - 0.06, h * 0.9, 0.22), bevel=0.0),
                  K.rbox((-1.39, h / 2, (a + b) / 2 * 0.8), (0.22, h * 0.95, (b - a) * 0.8 - 0.06), bevel=0.0),
                  K.rbox((1.39, h / 2, (a + b) / 2 * 0.8), (0.22, h, (b - a) * 0.8 - 0.06), bevel=0.0)]
    k.add("stone", *slabs)
    k.add("stone2", K.ell((-1.08, 0.36, -1.1), (0.38, 0.36, 0.34), 8, 4), K.ell((-1.25, 0.24, -0.72), (0.24, 0.24, 0.22), 8, 4))
    k.add("moss", K.ell((-1.06, 0.66, -1.08), (0.24, 0.08, 0.22), 8, 3))
    k.add("bone",
          K.rod((-1.36, 0.05, 1.0), (-1.05, 0.98, 1.3), 0.08, 6, top=0.25),
          K.rod((-1.0, 0.05, 1.3), (-1.32, 0.98, 1.02), 0.08, 6, top=0.25))


def build(lp):
    return S.trim(
        lp, "STONE_AGE", "Stone Age", design,
        colors={"stone": (130, 125, 120), "stone2": (108, 104, 100), "moss": (84, 114, 62), "bone": (228, 218, 192)},
        look=((130, 125, 120), (80, 110, 60)), show="TOTEM")
