"""OPTIONAL Campsite marker post (today the Campsite's name is a BillboardGui on its Ground): a signpost
with a plank sign, piece `face` (Front = -Z, 2.4 x 0.9 at y 2.6) for "Campsite 3" / the owner's name,
and a lantern. Proposed spot: the Campsite frame's front edge (0, 0, -10), facing the camp."""

import importlib.util
import math
from pathlib import Path

_s = importlib.util.spec_from_file_location("_camp", Path(__file__).with_name("_camp.py"))
C = importlib.util.module_from_spec(_s)
_s.loader.exec_module(C)

def build(lp):
    k = C.Camp(lp)
    k.add("wood", C.rod((0, 0, 0.1), (0, 3.6, 0.1), 0.15, segments=8, top=0.85))
    k.add("dark", C.rbox((0, 2.6, -0.06), (2.7, 1.1, 0.14), bevel=0.06), C.ell((0, 0.1, 0.1), (0.35, 0.12, 0.3), 7, 3))
    k.add("face", C.face((0, 2.6, -0.15), 2.4, 0.9))
    k.add("wood", C.rod((0, 3.4, 0.1), (0.7, 3.4, 0.1), 0.05, segments=5))
    k.add("metal", C.cyl((0.7, 3.0, 0.1), 0.15, 0.06, segments=8), C.cyl((0.7, 3.35, 0.1), 0.13, 0.08, segments=8))
    k.add("glow", C.cyl((0.7, 3.17, 0.1), 0.11, 0.28, segments=8, bevel=0.0))
    k.add("rope", C.ring((0, 2.0, 0.1), 0.16, 0.04, 8, 3))
    colors = {"wood": C.WOOD, "dark": C.DARK, "face": C.PAPER, "metal": C.METAL, "glow": (255, 200, 110), "rope": C.ROPE}
    return k.model("11f", colors, 800, (1.4, 0.4, 3.7), budget="small",
                   meta={"prop": "camp", "optional": True, "replaces": "(new) Campsite N label", "faces": {"face": "Front: Campsite name"}})
