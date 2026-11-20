"""SET_MIDNIGHT_RESIN - the Midnight set's piece for the RESIN tower (#457), worn over its art at
every stage on top of the set trim. Design: variants/_setpieces_midnight.py.
"""
# art-sources: variants/_setpieces_midnight.py variants/_setpieces_bm_shapes.py variants/_setpiece_common.py variants/_sets.py SET_MIDNIGHT.py

import importlib.util
from pathlib import Path

_spec = importlib.util.spec_from_file_location("_setpieces_midnight", Path(__file__).with_name("variants") / "_setpieces_midnight.py")
P = importlib.util.module_from_spec(_spec)
_spec.loader.exec_module(P)


def build(lp):
    return P.build(lp, "RESIN")
