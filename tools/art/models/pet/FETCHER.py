"""FETCHER - Fetcher, a tiny Dimorphodon (pterosaur; Pets sheet; effect: fetch). It flies.

Chibi flyer: round body, big deep-skulled head with a stubby puffin beak, wide membrane wings
(group `wing`) on bony leading edges, little legs dangling, a long thin tail ending in a
diamond vane. Markings (group glow) = the tail vane + a spot on each wing. Sized to today's
Fetcher look (Server/Pets LOOKS: 1 x 0.8 x 1.4 body, wings out to about +-2): span about 3.4,
1.6 tall, 2.6 long. Origin = the ground under its middle (its dangling toes at y 0); the
runtime keeps today's hover lift (Server/Pets: `flies`).
"""

import importlib.util
from pathlib import Path

_spec = importlib.util.spec_from_file_location("_pet", Path(__file__).with_name("_pet.py"))
P = importlib.util.module_from_spec(_spec)
_spec.loader.exec_module(P)

BODY = (150, 110, 80)  # Server/Pets LOOKS FETCHER


def build(lp):
    m = P.Pet(lp)
    m.add("body", P.ell((0, 0.75, 0.12), (0.36, 0.34, 0.44), 12, 8))
    m.add("body", P.ell((0, 1.18, -0.4), (0.37, 0.35, 0.37), 12, 8))  # big head
    m.add("body", P.tube([(0, 0.74, 0.5), (0, 0.72, 0.95), (0, 0.7, 1.32)], [0.1, 0.05, 0.03], subdiv=1))
    m.add("glow", P.ell((0, 0.7, 1.42), (0.035, 0.15, 0.15), 6, 4, rot=(45, 0, 0)))  # tail vane
    for s in (-1, 1):
        # wing: bony leading edge (body) + membrane (wing)
        m.add("body", P.tube([(s * 0.25, 0.92, -0.08), (s * 0.85, 1.12, -0.12), (s * 1.7, 1.02, 0.04)],
                             [0.09, 0.07, 0.03], subdiv=1))
        m.add("wing", P.ell((s * 0.95, 0.98, 0.18), (0.78, 0.04, 0.3), 12, 5, rot=(0, s * 8, s * 6)))
        m.add("glow", P.patch((s * 1.05, 1.025, 0.18), (s * 0.1, 1, 0), 0.13, 0.03, 8, 4))
        # legs dangling, little feet
        m.add("body", P.tube([(s * 0.16, 0.52, 0.28), (s * 0.18, 0.24, 0.36), (s * 0.18, 0.08, 0.3)],
                             [0.07, 0.05, 0.04], subdiv=1))
        m.add("belly", P.ell((s * 0.18, 0.05, 0.25), (0.07, 0.05, 0.1), 6, 4))
    m.add("belly", P.ell((0, 0.68, -0.14), (0.26, 0.26, 0.3), 10, 6))  # tummy
    m.add("belly", P.ell((0, 1.06, -0.8), (0.17, 0.16, 0.26), 10, 6))  # beak
    P.eyes(m, 0.24, 1.28, -0.62, 0.12)
    P.bandana(m, 0.93, -0.22, 0.25, 0.25, thick=0.08, flap=(0.22, 0.18))
    pieces = {"body": 320, "wing": 120, "glow": 70, "belly": 110, "accent": 90, "eye": 40, "shine": 16, "leaf": 20}
    colors = {
        "body": BODY,
        "belly": P.mix(BODY, (238, 220, 180), 0.6),
        "wing": P.mix(BODY, (230, 170, 120), 0.45),
        "glow": P.mix(BODY, (60, 40, 30), 0.45),
        "accent": P.RARITY["COMMON"],
        "eye": P.EYE,
        "shine": P.SHINE,
        "leaf": P.LEAF,
    }
    return P.model(m, lp, "FETCHER", pieces, colors, "Fetcher", "tiny Dimorphodon", ground_r=1.8,
                   extra_meta={"flies": True})
