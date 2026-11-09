"""RIFLE_BELT - see _rifle.py."""

import importlib.util
from pathlib import Path

_spec = importlib.util.spec_from_file_location("_rifle", Path(__file__).with_name("_rifle.py"))
D = importlib.util.module_from_spec(_spec)
_spec.loader.exec_module(D)


def build(lp):
    return D.build(lp, "belt")
