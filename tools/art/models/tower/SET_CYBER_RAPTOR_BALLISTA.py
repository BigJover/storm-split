"""SET_CYBER_RAPTOR_BALLISTA - the Cyber Raptor set piece for this tower (premium, batch 11p3): see
variants/_setpieces_cyber.py `ballista` - antenna mast / tesla node / server rack / holo screen /
raptor-claw sculpture and glowing cables. Worn over the tower's art at every stage, on top of the
Cyber Raptor trim.
"""
# art-sources: variants/_setpieces_cyber.py variants/_setpiece_common.py variants/_sets.py SET_CYBER_RAPTOR.py

import importlib.util
from pathlib import Path

_spec = importlib.util.spec_from_file_location("_setpieces_cyber", Path(__file__).with_name("variants") / "_setpieces_cyber.py")
L = importlib.util.module_from_spec(_spec)
_spec.loader.exec_module(L)


def build(lp):
    return L.build(lp, "BALLISTA")
