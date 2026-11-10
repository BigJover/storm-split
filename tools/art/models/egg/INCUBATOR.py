"""INCUBATOR - the egg warmer inside the Hatchery Hut (one per warming slot: 1, or 2 with the
"Second Hatchery Hut" pass). A banded wooden tub filled with a straw nest, a brass dial on
its front and a heat lamp arching over the nest on a bent pole (bulb = group glow, Neon, warm;
the runtime can light it only while an egg is warming).

Origin = the ground under the tub's centre; front = -Z (the dial). The egg sits in the nest
with its base at `eggSeat` (manifest meta) = (0, 0.88, 0): an egg model (origin = its base)
placed there sinks a little into the straw. Budget class `mid` (<= 1,500 tris, #433).
Preview: a Speckled Egg in the nest (preview-only context).
"""

import importlib.util
import math
from pathlib import Path

_spec = importlib.util.spec_from_file_location("_egg", Path(__file__).with_name("_egg.py"))
E = importlib.util.module_from_spec(_spec)
_spec.loader.exec_module(E)

SEAT = (0, 0.88, 0)


def build(lp):
    parts = {g: [] for g in ("wood", "dark", "straw", "metal", "shade", "brass", "glow")}
    # the tub, its hoops
    parts["wood"].append(E.cyl((0, 0.45, 0), 1.0, 0.9, 24, top=1.08))
    for y, r in ((0.16, 1.02), (0.74, 1.07)):
        parts["dark"].append(E.ring((0, y, 0), r, r, 0.05, 18, 4))
    # the straw nest: a fat rim + a bed + tufts poking out
    parts["straw"].append(E.ring((0, 0.98, 0), 0.82, 0.82, 0.24, 16, 6))
    parts["straw"].append(E.ell((0, 0.86, 0), (0.86, 0.14, 0.86), 14, 5))
    for k in range(12):
        a = math.radians(k * 30 + 10 + 9 * (k % 2))
        x, z = math.cos(a), math.sin(a)
        parts["straw"].append(E.tube([(0.92 * x, 1.0, 0.92 * z), (1.14 * x, 1.06 + 0.04 * (k % 3), 1.14 * z)],
                                     [0.045, 0.012], subdiv=0))
    # the heat lamp: a bent pole from the tub's back, a shade and the warm bulb over the nest
    parts["metal"].append(E.tube([(0, 0.25, 1.12), (0, 1.6, 1.16), (0, 2.85, 1.0), (0, 3.3, 0.55), (0, 3.28, 0.12)],
                                 [0.08, 0.075, 0.07, 0.065, 0.06], subdiv=1))
    parts["metal"].append(E.cyl((0, 0.55, 1.1), 0.14, 0.7, 8))  # the clamp on the tub
    parts["shade"].append(E.cyl((0, 3.06, 0), 0.48, 0.42, 16, top=0.16))  # the shade
    parts["glow"].append(E.ell((0, 2.9, 0), (0.22, 0.2, 0.22), 10, 6))  # the bulb, up inside the shade
    # the brass dial on the front
    parts["brass"].append(E.cyl((0, 0.48, -1.06), 0.22, 0.08, 14, rot=(90 - 4, 0, 0)))
    parts["dark"].append(E.cyl((0, 0.48, -1.1), 0.16, 0.02, 12, rot=(90 - 4, 0, 0)))
    parts["brass"].append(E.ell((0.06, 0.53, -1.12), (0.1, 0.022, 0.015), 6, 3, rot=(0, 0, 40)))  # needle
    targets = {"wood": 300, "dark": 170, "straw": 420, "metal": 220, "shade": 90, "brass": 90, "glow": 60}
    pieces, box = E.finish(lp, parts, targets, "INCUBATOR", 1500)
    context = E.paint_context(lp, E.design("SPECKLED", SEAT), E.COLORS["SPECKLED"]) + [E.ground(lp, 1.7), E.pad(lp, 2.2)]
    return {
        "batch": "11f",
        "budget": "mid",
        "box": box,
        "pieces": pieces,
        "colors": {
            "wood": (150, 104, 62),
            "dark": (70, 52, 36),
            "straw": (222, 192, 112),
            "metal": (84, 92, 88),
            "shade": (88, 128, 60),
            "brass": (214, 168, 70),
            "glow": (255, 170, 80),
        },
        "context": context,
        "meta": {"display": "Incubator (Hatchery Hut)", "origin": "ground", "eggSeat": list(SEAT),
                 "front": "-Z (dial)", "lamp": "glow"},
    }
