"""SHINY_SNATCHER - Shiny Snatcher, a baby Oviraptor (Pets sheet; effect: round cash).

Chibi biped: big round head with a tall rounded casque and a stubby parrot beak, feathery
arm tufts hugging a gold coin it dug up (group gold, fixed), a fan of tail feathers. Markings
(group glow) = the casque + the tail fan. Sized to today's Shiny Snatcher look (Server/Pets
LOOKS: 1.2 x 1.3 x 1.8 body + head): about 1.0 wide, 2.1 tall, 2.2 long, feet on the
ground (origin = the ground under its middle).
"""

import importlib.util
from pathlib import Path

_spec = importlib.util.spec_from_file_location("_pet", Path(__file__).with_name("_pet.py"))
P = importlib.util.module_from_spec(_spec)
_spec.loader.exec_module(P)

BODY = (220, 140, 70)  # Server/Pets LOOKS SHINY_SNATCHER
GOLD = (245, 195, 60)


def build(lp):
    m = P.Pet(lp)
    m.add("body", P.ell((0, 0.78, 0.1), (0.44, 0.48, 0.5), 12, 8))
    m.add("body", P.ell((0, 1.42, -0.32), (0.4, 0.38, 0.4), 12, 8))  # head
    m.add("glow", P.ell((0, 1.86, -0.36), (0.09, 0.24, 0.24), 10, 6, rot=(-10, 0, 0)))  # casque
    for i, a in enumerate((-28, 0, 28)):  # tail fan
        m.add("glow", P.ell((0.22 * (i - 1), 0.82, 0.78), (0.11, 0.07, 0.3), 8, 4, rot=(-20, a, 0)))
    for s in (-1, 1):
        m.add("body", P.ell((s * 0.27, 0.42, 0.14), (0.21, 0.27, 0.28), 8, 6))  # thigh
        m.add("body", P.ell((s * 0.28, 0.09, -0.06), (0.15, 0.09, 0.24), 8, 5))  # foot
        # arm tufts wrapped round the coin
        m.add("body", P.ell((s * 0.27, 0.86, -0.4), (0.1, 0.24, 0.13), 8, 5, rot=(-50, 0, -s * 35)))
    m.add("gold", P.ell((0, 0.82, -0.58), (0.22, 0.22, 0.06), 12, 4, rot=(-12, 0, 0)))  # the coin
    m.add("belly", P.ell((0, 0.7, -0.2), (0.32, 0.36, 0.3), 10, 7))
    m.add("belly", P.ell((0, 1.28, -0.7), (0.17, 0.15, 0.17), 10, 6))  # beak
    P.eyes(m, 0.25, 1.52, -0.6, 0.13)
    P.bandana(m, 1.08, -0.22, 0.32, 0.3, thick=0.09, flap=(0.26, 0.2))
    pieces = {"body": 380, "glow": 110, "belly": 80, "gold": 50, "accent": 90, "eye": 40, "shine": 16, "leaf": 20}
    colors = {
        "body": BODY,
        "belly": P.mix(BODY, (245, 230, 190), 0.6),
        "glow": P.mix(BODY, (110, 50, 30), 0.45),
        "gold": GOLD,
        "accent": P.RARITY["COMMON"],
        "eye": P.EYE,
        "shine": P.SHINE,
        "leaf": P.LEAF,
    }
    return P.model(m, lp, "SHINY_SNATCHER", pieces, colors, "Shiny Snatcher", "baby Oviraptor")
