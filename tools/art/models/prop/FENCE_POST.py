"""One of the Outpost fence's 48 posts (Server/Outpost FencePost 1 x 5 x 1, at RADIUS - 1). Origin = the post's
foot on the floor. A sharpened log with a rope lashing at the rail height (y 3.5)."""

import importlib.util
import math
from pathlib import Path

_s = importlib.util.spec_from_file_location("_camp", Path(__file__).with_name("_camp.py"))
C = importlib.util.module_from_spec(_s)
_s.loader.exec_module(C)

def build(lp):
    k = C.Camp(lp)
    k.add("wood", C.rod((0, 0, 0), (0, 4.6, 0), 0.38, segments=8, top=0.92),
          C.rod((0, 4.6, 0), (0, 5.3, 0), 0.35, segments=8, top=0.08))
    k.add("rope", C.ring((0, 3.5, 0), 0.38, 0.07, 10, 4), C.ring((0, 3.72, 0), 0.38, 0.07, 10, 4),
          C.ring((0, 1.8, 0), 0.39, 0.07, 10, 4))
    k.add("dark", C.ell((0, 0.08, 0), (0.55, 0.12, 0.55), 8, 3))
    colors = {"wood": (120, 84, 52), "rope": (196, 170, 120), "dark": (90, 70, 50)}
    return k.model("11f", colors, 400, (0.6, 0.6, 5.4), budget="small",
                   meta={"prop": "camp", "replaces": "Server/Outpost FencePost (x48)"})
