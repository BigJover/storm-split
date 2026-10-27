"""RESIN stage 2 (TowerLook model-swap stage 2) - the design is in _resin.py."""

import importlib.util
from pathlib import Path

_spec = importlib.util.spec_from_file_location("_resin", Path(__file__).with_name("_resin.py"))
D = importlib.util.module_from_spec(_spec)
_spec.loader.exec_module(D)


def build(lp):
    return D.build(lp, 2)
