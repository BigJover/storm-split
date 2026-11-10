"""OPTIONAL Display Tower pedestal (today a Display Tower stands straight on the Campsite ground,
TowerLook.build at the DECO_SPOT): a low plank deck 3.6 x 3.6 x 0.3 with corner stakes and a brass
plaque, piece `face` (Front = -Z, 1.2 x 0.22 on the deck's front edge) for the tower's name.
Origin = the spot on the ground; the runtime would lift the Display Tower by 0.3 (deck top)."""

import importlib.util
import math
from pathlib import Path

_s = importlib.util.spec_from_file_location("_camp", Path(__file__).with_name("_camp.py"))
C = importlib.util.module_from_spec(_s)
_s.loader.exec_module(C)

def build(lp):
    k = C.Camp(lp)
    k.add("wood", *C.plank_floor((0, 0.3, 0), 3.6, 3.6, h=0.22, n=5))
    k.add("dark", C.rbox((0, 0.06, 0), (3.5, 0.12, 3.5), bevel=0.04))
    for x in (-1.75, 1.75):
        for z in (-1.75, 1.75):
            k.add("dark", C.rod((x, 0, z), (x, 0.5, z), 0.13, segments=7), C.ell((x, 0.5, z), (0.13, 0.07, 0.13), 7, 3))
    k.add("brass", C.rbox((0, 0.17, -1.82), (1.35, 0.3, 0.05), bevel=0.02))
    k.add("face", C.face((0, 0.17, -1.86), 1.2, 0.22, t=0.02))
    colors = {"wood": (150, 110, 70), "dark": (110, 76, 46), "brass": C.BRASS, "face": (90, 70, 40)}
    return k.model("11f", colors, 800, (1.95, 1.95, 0.6), budget="small",
                   meta={"prop": "camp", "optional": True, "replaces": "(new) Display Tower pedestal", "faces": {"face": "Front: tower name plaque"}})
