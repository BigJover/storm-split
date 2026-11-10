"""SPECKLED - Speckled Egg - cream shell with warm speckles (Eggs sheet). The design is in _egg.py."""

import importlib.util
from pathlib import Path

_spec = importlib.util.spec_from_file_location("_egg", Path(__file__).with_name("_egg.py"))
E = importlib.util.module_from_spec(_spec)
_spec.loader.exec_module(E)


def build(lp):
    return E.egg_model(lp, "SPECKLED")
