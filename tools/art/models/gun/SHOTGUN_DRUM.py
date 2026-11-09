"""SHOTGUN_DRUM - see _shotgun.py."""

import importlib.util
from pathlib import Path

_spec = importlib.util.spec_from_file_location("_shotgun", Path(__file__).with_name("_shotgun.py"))
D = importlib.util.module_from_spec(_spec)
_spec.loader.exec_module(D)


def build(lp):
    return D.build(lp, "drum")
