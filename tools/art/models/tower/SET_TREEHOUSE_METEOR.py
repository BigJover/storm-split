"""SET_TREEHOUSE_METEOR - the Treehouse set's piece for METEOR (11e2, #457): worn over the tower's art at every
stage on top of the Treehouse trim. The design is _setpieces_treehouse.meteor; built + checked by _setpiece_common.
"""
# art-sources: variants/_setpiece_common.py variants/_setpieces_treehouse.py

import importlib.util
from pathlib import Path


def _load(name):
    spec = importlib.util.spec_from_file_location(name, Path(__file__).with_name("variants") / f"{name}.py")
    mod = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(mod)
    return mod


C, D = _load("_setpiece_common"), _load("_setpieces_treehouse")


def build(lp):
    return C.setpiece(lp, "TREEHOUSE", "METEOR", D.DESIGNS["METEOR"], D.COLORS)
