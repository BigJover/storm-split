"""SET_NEBULA_ARMORY - the Nebula set piece for this tower (premium, batch 11p5, #462): see the design in
variants/_setpieces_nebula.py (star obelisks with orbit rings, star portals, telescopes, orreries, meteor
shards, crescent moons). Worn over the tower's art at every stage, on top of the Nebula trim.
"""
# art-sources: variants/_setpieces_nebula.py variants/_setpiece_common.py variants/_sets.py SET_NEBULA.py

import importlib.util
from pathlib import Path

_spec = importlib.util.spec_from_file_location("_setpieces_nebula", Path(__file__).with_name("variants") / "_setpieces_nebula.py")
P = importlib.util.module_from_spec(_spec)
_spec.loader.exec_module(P)


def build(lp):
    return P.build(lp, "ARMORY")
