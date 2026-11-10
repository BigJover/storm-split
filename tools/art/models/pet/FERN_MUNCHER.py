"""FERN_MUNCHER - Fern Muncher, a baby longneck (sauropod; Pets sheet; effect: regen).

Chibi sauropod: a round barrel body on four stumpy legs, a long curved neck up to a small
round head munching a fern sprig (group leaf, the same green as the leaf tag), a tapering
tail. Markings (group glow) = a row of round spots down the back and neck. Sized to today's
Fern Muncher look (Server/Pets LOOKS: 1.6 x 1.4 x 2.2 body + a 1.4 neck): about 1.2 wide,
2.3 tall, 3.0 long, feet on the ground (origin = the ground under its middle).
"""

import importlib.util
from pathlib import Path

_spec = importlib.util.spec_from_file_location("_pet", Path(__file__).with_name("_pet.py"))
P = importlib.util.module_from_spec(_spec)
_spec.loader.exec_module(P)

BODY = (90, 160, 110)  # Server/Pets LOOKS FERN_MUNCHER


def build(lp):
    m = P.Pet(lp)
    m.add("body", P.ell((0, 0.78, 0.22), (0.55, 0.46, 0.68), 12, 8))
    m.add("body", P.tube([(0, 0.95, -0.3), (0, 1.38, -0.52), (0, 1.75, -0.6)], [0.28, 0.21, 0.19]))
    m.add("body", P.ell((0, 1.95, -0.72), (0.38, 0.34, 0.4), 12, 8))  # big chibi head
    m.add("body", P.tube([(0, 0.86, 0.8), (0, 0.66, 1.32), (0, 0.48, 1.7)], [0.28, 0.14, 0.04]))
    for s in (-1, 1):
        for z in (-0.18, 0.62):  # four stumpy legs, flat-bottomed on the ground
            m.add("body", P.ell((s * 0.31, 0.29, z), (0.22, 0.29, 0.23), 8, 6))
    for i, (y, z, n) in enumerate(((1.23, 0.0, (0, 1, 0.1)), (1.2, 0.38, (0, 1, 0.5)),
                                   (1.03, 0.72, (0, 1, 1.0)), (1.5, -0.4, (0, 0.5, 1.0)))):
        m.add("glow", P.patch((0, y, z), n, 0.15 if i < 3 else 0.11, 0.045, 10, 5))
    m.add("belly", P.ell((0, 0.6, 0.1), (0.42, 0.28, 0.5), 10, 6))
    m.add("belly", P.ell((0, 1.82, -1.02), (0.22, 0.15, 0.16), 8, 5))  # muzzle
    # the fern sprig in its mouth
    m.add("leaf", P.tube([(-0.04, 1.8, -1.12), (0.22, 1.74, -1.18), (0.46, 1.6, -1.16)], [0.025, 0.02, 0.015], subdiv=0))
    for t, (x, y, z) in enumerate(((0.2, 1.78, -1.21), (0.32, 1.71, -1.13), (0.42, 1.64, -1.22))):
        m.add("leaf", P.ell((x, y, z), (0.09, 0.03, 0.05), 6, 3, rot=(0, 30 * t, -30)))
    P.eyes(m, 0.28, 2.04, -0.94, 0.13)
    P.bandana(m, 1.12, -0.33, 0.26, 0.26, thick=0.08, tilt=-30, flap=(0.24, 0.2))
    pieces = {"body": 400, "glow": 110, "belly": 80, "accent": 90, "eye": 40, "shine": 16, "leaf": 50}
    colors = {
        "body": BODY,
        "belly": P.mix(BODY, (232, 226, 186), 0.6),
        "glow": P.mix(BODY, (30, 70, 50), 0.45),
        "accent": P.RARITY["COMMON"],
        "eye": P.EYE,
        "shine": P.SHINE,
        "leaf": P.LEAF,
    }
    return P.model(m, lp, "FERN_MUNCHER", pieces, colors, "Fern Muncher", "baby longneck", ground_r=1.8)
