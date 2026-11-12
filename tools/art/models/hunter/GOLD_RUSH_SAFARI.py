"""GOLD_RUSH_SAFARI - Big Game Hunter skin (900K Amber, Gold Rush Bundle; the top hunter skin):
a gilded expedition officer. Gold pith helmet with a crimson plume, gold fringed epaulettes on both
shoulders, two medals on the chest, a crimson waist sash knotted at the left hip and gold cuffs
on the rolled sleeves; ivory jacket and shorts. Base: hunter/RIFLE (variants/_skins.py).
"""
# art-sources: RIFLE.py variants/_skins.py

import importlib.util
import math
from pathlib import Path

_spec = importlib.util.spec_from_file_location("_skins", Path(__file__).with_name("variants") / "_skins.py")
S = importlib.util.module_from_spec(_spec)
_spec.loader.exec_module(S)


def extra(body, lp, B):
    # plume: a gold holder on the helmet's top, a crimson plume sweeping back
    body.add("Head", "gold", B.cyl((0, 2.62, 0.02), 0.09, 0.12, 10, top=0.7, bevel=0.02))
    body.add("Head", "plume",
             B.capsule(lp, (0, 2.68, 0.02), (0, 2.98, 0.28), 0.09, 0.05, subdiv=1),
             B.ell((0, 2.78, 0.1), (0.1, 0.16, 0.14), 8, 6, rot=(-35, 0, 0)))
    # fringed epaulettes
    for k in (-1, 1):
        body.add("UpperTorso", "gold",
                 B.ell((0.84 * k, 1.0, 0), (0.34, 0.08, 0.36), 12, 5),
                 *[B.cyl((0.84 * k + 0.32 * k * math.cos(a), 0.88, 0.32 * math.sin(a)), 0.03, 0.2, 5, bevel=0.0)
                   for a in (-1.2, -0.6, 0.0, 0.6, 1.2)])
    # medals on the right chest: gold discs on crimson ribbons
    body.add("UpperTorso", "plume", *[B.rbox((0.3 + 0.2 * i, 0.74, -0.53), (0.12, 0.16, 0.04), bevel=0.012, segments=1) for i in (0, 1)])
    body.add("UpperTorso", "gold", *[B.cyl((0.3 + 0.2 * i, 0.6, -0.55), 0.07, 0.04, 10, bevel=0.01, rot=(90, 0, 0)) for i in (0, 1)])
    # crimson waist sash over the shorts' top, knot + two tails on the left hip
    body.add("LowerTorso", "plume",
             B.rbox((0, -0.86, 0), (2.0 * 0.96, 0.22, 1.06), bevel=0.08),
             B.ell((-0.9, -0.86, -0.32), (0.13, 0.13, 0.1), 8, 5),
             B.rbox((-0.96, -1.08, -0.3), (0.12, 0.36, 0.06), bevel=0.02, segments=1, rot=(0, 0, -8)),
             B.rbox((-0.86, -1.06, -0.36), (0.12, 0.32, 0.06), bevel=0.02, segments=1, rot=(0, 0, 10)))
    # gold cuffs over the rolled sleeves
    for k, side in B.SIDES:
        body.add(f"{side}LowerArm", "gold", B.cyl((1.38 * k, -0.06, 0), 0.36, 0.1, 14, bevel=0.03))


def build(lp):
    return S.variant(
        lp, "RIFLE", "GOLD_RUSH_SAFARI", "Gold Rush Safari",
        extra=extra,
        target=5000, keep=165,
        colors={
            "gear": (220, 180, 60),    # gold helmet = the skin's colour (Skins sheet)
            "shirt": (240, 230, 200),  # ivory jacket = the skin's accent
            "gear2": (226, 212, 172),
            "pants": (232, 220, 186),
            "accent": (246, 206, 90),  # helmet band, bandolier rounds, buckle
            "gold": (232, 186, 70),
            "plume": (176, 38, 44),
            "dark": (96, 52, 36),
            "sock": (246, 240, 226),
        },
    )
