"""SET_TREEHOUSE - the Treehouse tower set's trim (400K Amber, Treehouse Bundle): a plank deck
edge round the footprint, a leafy bush on the front-left corner and a vine-wrapped post with a
rope coil on the back-left. Over any tower's art (variants/_sets.py); the set's colours still
repaint the tower itself.
"""
# art-sources: variants/_sets.py

import importlib.util
import math
from pathlib import Path

_spec = importlib.util.spec_from_file_location("_sets", Path(__file__).with_name("variants") / "_sets.py")
S = importlib.util.module_from_spec(_spec)
_spec.loader.exec_module(S)


def design(k, K):
    S.rim(k, K, "plank", h=0.22, w=0.2)
    k.add("leaf",
          K.ell((-1.1, 0.42, -1.12), (0.36, 0.34, 0.34), 8, 4),
          K.ell((-1.28, 0.3, -0.8), (0.22, 0.24, 0.22), 8, 4))
    k.add("leaf2", K.ell((-0.85, 0.3, -1.25), (0.24, 0.24, 0.2), 8, 4), K.ell((-1.2, 0.95, 1.2), (0.2, 0.14, 0.2), 6, 3))
    k.add("post", K.rod((-1.2, 0.0, 1.2), (-1.2, 0.95, 1.2), 0.09, 6))
    k.add("rope", K.ring((-1.2, 0.5, 1.2), 0.13, 0.04, 8, 3))


def build(lp):
    return S.trim(
        lp, "TREEHOUSE", "Treehouse", design,
        colors={"plank": (150, 108, 64), "leaf": (84, 136, 62), "leaf2": (64, 110, 50),
                "post": (110, 78, 46), "rope": (176, 150, 100)},
        look=((140, 100, 60), (80, 130, 60)), show="SCOUT")
