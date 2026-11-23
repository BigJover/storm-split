"""SET_GEODE_RANGER - the Geode set piece for this tower (premium, batch 11p6): the design is
_setpieces_geode.ranger (crystal clusters, cracked geode boulders, crystal spires with floating shard rings,
crystal ledges). Worn over the tower's art at every stage, on top of the Geode trim.
"""
# art-sources: variants/_setpieces_geode.py variants/_setpiece_common.py variants/_sets.py SET_GEODE.py

import importlib.util
from pathlib import Path

_spec = importlib.util.spec_from_file_location("_setpieces_geode", Path(__file__).with_name("variants") / "_setpieces_geode.py")
L = importlib.util.module_from_spec(_spec)
_spec.loader.exec_module(L)


def build(lp):
    return L.build(lp, "RANGER")
