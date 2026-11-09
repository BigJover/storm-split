"""MEDIC - see _medic.py."""

import importlib.util
from pathlib import Path

_spec = importlib.util.spec_from_file_location("_medic", Path(__file__).with_name("_medic.py"))
D = importlib.util.module_from_spec(_spec)
_spec.loader.exec_module(D)


def build(lp):
    return D.build(lp)
