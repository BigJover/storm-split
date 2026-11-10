"""FRILL_GUARD - Frill Guard, a baby Protoceratops (Pets sheet; effect: absorb a bite).

Chibi quadruped: a chunky low body on four stumpy legs, a big head with a parrot beak and a
wide shield frill swept up behind it (group frill, the Round 21 red-tan), a short tail.
Markings (group glow) = spots along the frill's rim + the nose bump. Sized to today's Frill
Guard look (Server/Pets LOOKS: 1.6 x 1.3 x 2.2 body, frill 2.2 wide): about 1.4 wide, 1.9
tall, 2.6 long, feet on the ground (origin = the ground under its middle).
"""

import importlib.util
import math
from pathlib import Path

_spec = importlib.util.spec_from_file_location("_pet", Path(__file__).with_name("_pet.py"))
P = importlib.util.module_from_spec(_spec)
_spec.loader.exec_module(P)

BODY = (200, 170, 120)  # Server/Pets LOOKS FRILL_GUARD
FRILL = P.mix(BODY, (200, 90, 60), 0.4)  # Server/Pets: look.body:Lerp(200, 90, 60, 0.4)


def build(lp):
    m = P.Pet(lp)
    m.add("body", P.ell((0, 0.7, 0.3), (0.56, 0.46, 0.66), 12, 8))
    m.add("body", P.tube([(0, 0.72, 0.85), (0, 0.6, 1.25), (0, 0.48, 1.5)], [0.26, 0.13, 0.04]))
    for s in (-1, 1):
        for z in (-0.08, 0.66):
            m.add("body", P.ell((s * 0.36, 0.27, z), (0.19, 0.27, 0.2), 8, 6))
    m.add("body", P.ell((0, 1.04, -0.6), (0.44, 0.4, 0.44), 12, 8))  # big head
    # the frill: a wide shield swept up and back behind the head, spots round its rim
    fc, tilt = (0, 1.3, -0.36), -14
    m.add("frill", P.ell(fc, (0.66, 0.5, 0.1), 14, 6, rot=(tilt, 0, 0)))
    for k in range(5):
        a = math.radians(-60 + 30 * k)  # round the upper rim
        x, y = 0.55 * math.sin(a), 0.41 * math.cos(a)
        t = math.radians(tilt)
        m.add("glow", P.patch((x, fc[1] + y * math.cos(t), fc[2] + y * math.sin(t) - 0.09),
                              (0, math.sin(-t), -math.cos(t)), 0.09, 0.04, 8, 4))
    m.add("glow", P.ell((0, 1.26, -0.92), (0.08, 0.09, 0.1), 6, 4))  # nose bump
    m.add("belly", P.ell((0, 0.9, -0.98), (0.19, 0.2, 0.2), 10, 6))  # beak
    m.add("belly", P.ell((0, 0.52, 0.2), (0.44, 0.26, 0.5), 10, 6))
    P.eyes(m, 0.31, 1.15, -0.84, 0.135)
    P.bandana(m, 0.74, -0.42, 0.36, 0.3, thick=0.09, tilt=-20, flap=(0.26, 0.2))
    pieces = {"body": 360, "frill": 90, "glow": 80, "belly": 80, "accent": 90, "eye": 40, "shine": 16, "leaf": 20}
    colors = {
        "body": BODY,
        "frill": FRILL,
        "belly": P.mix(BODY, (245, 235, 205), 0.55),
        "glow": P.mix(FRILL, (90, 40, 30), 0.45),
        "accent": P.RARITY["COMMON"],
        "eye": P.EYE,
        "shine": P.SHINE,
        "leaf": P.LEAF,
    }
    return P.model(m, lp, "FRILL_GUARD", pieces, colors, "Frill Guard", "baby Protoceratops", ground_r=1.7)
