"""OPTIONAL Hunt Board notice board (today the Hunt Board is only a screen, G): a big roofed board with
pinned bounty notes and a carved header; piece `face` (Front = -Z, 4.6 x 2.8 at y 2.9) for a
SurfaceGui (today's Bounties / Daily Haul summary, or a "press G" prompt). Proposed spot: by the
spawn ring north of the fire (CENTRE + (0, 0, -2)), facing the spawn (+Z)."""

import importlib.util
import math
from pathlib import Path

_s = importlib.util.spec_from_file_location("_camp", Path(__file__).with_name("_camp.py"))
C = importlib.util.module_from_spec(_s)
_s.loader.exec_module(C)

def build(lp):
    k = C.Camp(lp)
    for x in (-2.7, 2.7):
        k.add("wood", C.rod((x, 0, 0), (x, 5.1, 0), 0.2, segments=8))
        k.add("dark", C.ell((x, 0.1, 0), (0.38, 0.12, 0.3), 7, 3))
    k.add("dark", C.rbox((0, 2.9, 0.05), (5.2, 3.3, 0.16), bevel=0.05))
    k.add("wood", C.rbox((0, 1.15, -0.05), (5.6, 0.22, 0.3), bevel=0.05), C.rbox((0, 4.62, -0.05), (5.6, 0.22, 0.3), bevel=0.05))
    k.add("face", C.face((0, 2.9, -0.06), 4.6, 2.8))
    # carved header board + roof
    k.add("wood", C.rbox((0, 5.05, -0.05), (3.4, 0.6, 0.16), bevel=0.06))
    k.add("accent", C.ell((0, 5.05, -0.15), (0.35, 0.22, 0.06), 8, 4))
    k.add("roof", C.rbox((0, 5.6, -0.33), (6.3, 0.1, 0.9), bevel=0.02, rot=(-25, 0, 0)),
          C.rbox((0, 5.6, 0.33), (6.3, 0.1, 0.9), bevel=0.02, rot=(25, 0, 0)))
    # pinned notes (stand slightly proud of the face, around its edges, so the middle stays clear)
    for x, y, rot, g in ((-2.0, 4.1, 6, "note"), (2.05, 4.05, -5, "note2"), (-2.05, 1.7, -4, "note2"), (2.0, 1.75, 7, "note")):
        k.add(g, C.rbox((x, y, -0.1), (0.7, 0.75, 0.02), bevel=0.0, rot=(0, 0, rot)))
        k.add("accent", C.ell((x, y + 0.3, -0.13), (0.06, 0.06, 0.04), 6, 3))
    colors = {"wood": C.WOOD, "dark": C.DARK, "face": C.PAPER, "roof": (110, 76, 46), "accent": (200, 60, 50),
              "note": (240, 230, 200), "note2": (220, 200, 150)}
    return k.model("11f", colors, 1500, (3.2, 0.8, 6.0), budget="mid",
                   meta={"prop": "camp", "optional": True, "replaces": "(new) Hunt Board in camp", "faces": {"face": "Front: board SurfaceGui"}})
