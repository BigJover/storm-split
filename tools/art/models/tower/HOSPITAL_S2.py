"""HOSPITAL stage 2 (TowerLook model-swap stage 2) - the design is in _hospital.py."""

import importlib.util
from pathlib import Path

_spec = importlib.util.spec_from_file_location("_hospital", Path(__file__).with_name("_hospital.py"))
D = importlib.util.module_from_spec(_spec)
_spec.loader.exec_module(D)


def build(lp):
    return D.build(lp, 2)
