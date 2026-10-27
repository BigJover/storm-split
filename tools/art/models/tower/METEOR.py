"""METEOR stage 0 (TowerLook model-swap stage 0) - the design is in _meteor.py."""

import importlib.util
from pathlib import Path

_spec = importlib.util.spec_from_file_location("_meteor", Path(__file__).with_name("_meteor.py"))
D = importlib.util.module_from_spec(_spec)
_spec.loader.exec_module(D)


def build(lp):
    return D.build(lp, 0)
