"""RANGER stage 1 (TowerLook model-swap stage 1) - the design is in _ranger.py."""

import importlib.util
from pathlib import Path

_spec = importlib.util.spec_from_file_location("_ranger", Path(__file__).with_name("_ranger.py"))
D = importlib.util.module_from_spec(_spec)
_spec.loader.exec_module(D)


def build(lp):
    return D.build(lp, 1)
