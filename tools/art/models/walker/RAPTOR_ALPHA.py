"""Walker RAPTOR_ALPHA (PLAN 11d2): see _walker.raptor(\"alpha\")."""

import importlib.util
from pathlib import Path

_spec = importlib.util.spec_from_file_location("_walker", Path(__file__).with_name("_walker.py"))
W = importlib.util.module_from_spec(_spec)
_spec.loader.exec_module(W)


def build(lp):
    return W.raptor(lp, "alpha")
