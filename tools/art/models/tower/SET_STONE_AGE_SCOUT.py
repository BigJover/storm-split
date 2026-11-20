"""SET_STONE_AGE_SCOUT - the Stone Age set's piece for SCOUT (11e2, #457): worn over the tower's art at every
stage on top of the Stone Age trim. The design is _setpieces_stone_age.scout; built + checked by _setpiece_common.
"""
# art-sources: variants/_setpiece_common.py variants/_setpieces_stone_age.py

import importlib.util
from pathlib import Path


def _load(name):
    spec = importlib.util.spec_from_file_location(name, Path(__file__).with_name("variants") / f"{name}.py")
    mod = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(mod)
    return mod


C, D = _load("_setpiece_common"), _load("_setpieces_stone_age")


def build(lp):
    return C.setpiece(lp, "STONE_AGE", "SCOUT", D.DESIGNS["SCOUT"], D.COLORS)
