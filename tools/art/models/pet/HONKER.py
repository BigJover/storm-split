"""HONKER - Honker, a baby Parasaurolophus (Pets sheet; effect: honk).

Chibi hatchling: big round head with a soft duck-bill, the backward tube crest (group glow,
so it lights up at Legendary / Mythic), a chubby upright body on two stubby legs, a short
tail. Sized to today's Honker look (Server/Pets LOOKS: 1.4 x 1.4 x 2 body + head): about
1.0 wide, 2.1 tall, 2.5 long, feet on the ground (origin = the ground under its middle).
"""

import importlib.util
from pathlib import Path

_spec = importlib.util.spec_from_file_location("_pet", Path(__file__).with_name("_pet.py"))
P = importlib.util.module_from_spec(_spec)
_spec.loader.exec_module(P)

BODY = (120, 150, 90)  # Server/Pets LOOKS HONKER


def build(lp):
    m = P.Pet(lp)
    # body + legs + arms + tail
    m.add("body", P.ell((0, 0.8, 0.12), (0.5, 0.52, 0.58), 12, 8))
    m.add("body", P.tube([(0, 0.72, 0.55), (0, 0.6, 0.98), (0, 0.5, 1.32)], [0.3, 0.17, 0.05]))
    for s in (-1, 1):
        m.add("body", P.ell((s * 0.3, 0.46, 0.16), (0.24, 0.3, 0.32), 8, 6))  # thigh
        m.add("body", P.ell((s * 0.31, 0.1, -0.02), (0.17, 0.1, 0.26), 8, 5))  # foot, on the ground
        m.add("body", P.ell((s * 0.36, 0.86, -0.34), (0.09, 0.19, 0.09), 6, 4, rot=(-35, 0, s * 15)))  # arm
    # head (big, chibi) + crest
    m.add("body", P.ell((0, 1.5, -0.4), (0.44, 0.42, 0.44), 12, 8))
    m.add("glow", P.tube([(0, 1.78, -0.36), (0, 2.02, -0.02), (0, 2.02, 0.38), (0, 1.88, 0.62)],
                         [0.13, 0.13, 0.11, 0.07]))
    for y, z, n in ((1.28, 0.22, (0, 1, 0.3)), (1.14, 0.52, (0, 1, 1.0)), (0.88, 0.76, (0, 0.6, 1.0))):
        m.add("glow", P.patch((0, y, z), n, 0.15, 0.05, 10, 5))  # three soft back spots
    # bill + tummy
    m.add("belly", P.ell((0, 1.35, -0.83), (0.27, 0.17, 0.27), 12, 6))
    m.add("belly", P.ell((0, 0.72, -0.22), (0.36, 0.4, 0.34), 12, 7))
    P.eyes(m, 0.27, 1.6, -0.7, 0.135)
    P.bandana(m, 1.12, -0.28, 0.36, 0.34, thick=0.1, flap=(0.3, 0.24))
    pieces = {"body": 400, "glow": 140, "belly": 80, "accent": 90, "eye": 40, "shine": 16, "leaf": 20}
    colors = {
        "body": BODY,
        "belly": P.mix(BODY, (238, 226, 180), 0.65),
        "glow": P.mix(BODY, (60, 70, 40), 0.45),
        "accent": P.RARITY["COMMON"],
        "eye": P.EYE,
        "shine": P.SHINE,
        "leaf": P.LEAF,
    }
    return P.model(m, lp, "HONKER", pieces, colors, "Honker", "baby Parasaurolophus")
