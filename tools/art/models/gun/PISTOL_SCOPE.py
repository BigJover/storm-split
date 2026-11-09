"""PISTOL_SCOPE - the Revolver's Scope attachment (Marksman T3); the design is in _pistol.py."""

import importlib.util
from pathlib import Path

_spec = importlib.util.spec_from_file_location("_pistol", Path(__file__).with_name("_pistol.py"))
D = importlib.util.module_from_spec(_spec)
_spec.loader.exec_module(D)


def build(lp):
    return D.build(lp, "scope")
