"""SET_CYBER_RAPTOR - the Cyber Raptor premium tower set's trim (PREMIUM_SKINS.md, batch 11p3, element
electric / digital glitch, #462): a black-chrome rim round the footprint with a light strip glowing
along its top and pixel pads at the corners, a holo pylon with a raptor-claw screen on the
front-left corner and a small server rack with status lights on the back-left.
`glow` = Neon in game (Shared/SkinFx cycles it cyan -> magenta; brighter, with pixel sparks, at
stage 2). Over any tower's art (variants/_sets.py checks: <= 300 tris, rim <= 0.3, raised pieces
only on the left corners <= 1.1, flag + Rescue Beacon corners clear).
"""
# art-sources: variants/_sets.py

import importlib.util
from pathlib import Path

_spec = importlib.util.spec_from_file_location("_sets", Path(__file__).with_name("variants") / "_sets.py")
S = importlib.util.module_from_spec(_spec)
_spec.loader.exec_module(S)

LOOK = ((36, 38, 52), (120, 128, 146))  # the set's colour (black chrome) + accent (gunmetal): preview paint only until the Skins row exists
COLORS = {"plate": (30, 32, 44), "chrome": (138, 148, 166), "glow": (0, 236, 255)}


def design(k, K):
    S.rim(k, K, "plate", h=0.2, w=0.2)
    S.rim(k, K, "glow", h=0.23, w=0.05)  # the light strip standing out of the rim's middle
    # front-left: a holo pylon - a gunmetal post, a glowing screen with three dark claw slashes
    k.add("plate", K.rbox((-1.2, 0.08, -1.2), (0.36, 0.16, 0.36), bevel=0.0))
    k.add("chrome", K.rod((-1.2, 0.16, -1.2), (-1.2, 0.55, -1.2), 0.04, 5),
          K.rbox((-1.12, 0.8, -1.12), (0.5, 0.42, 0.04), bevel=0.0, rot=(0, 45, 0)))
    k.add("glow", K.rbox((-1.12, 0.8, -1.12), (0.42, 0.34, 0.06), bevel=0.0, rot=(0, 45, 0)))
    k.add("plate", *[K.rod((-1.12 + d * 0.7 - 0.06 - 0.03, 0.92, -1.12 - d * 0.7 + 0.06 - 0.03),
                           (-1.12 + d * 0.7 + 0.06 - 0.03, 0.68, -1.12 - d * 0.7 - 0.06 - 0.03), 0.016, 4) for d in (-0.1, 0.0, 0.1)])
    # back-left: a small server rack with status lights facing the front
    k.add("plate", K.rbox((-1.18, 0.45, 1.16), (0.4, 0.9, 0.36), bevel=0.0))
    k.add("chrome", K.rbox((-1.18, 0.93, 1.16), (0.44, 0.06, 0.4), bevel=0.0))
    k.add("glow", *[K.rbox((-1.18, y, 0.97), (0.28, 0.04, 0.02), bevel=0.0) for y in (0.35, 0.55, 0.75)])


def build(lp):
    model = S.trim(lp, "CYBER_RAPTOR", "Cyber Raptor", design, colors=COLORS, look=LOOK, show="SCOUT")
    if model:  # (_setpiece_common._trim stubs S.trim to read the design: it returns {})
        model["batch"] = "11p3"
        model["meta"].update({"theme": "CYBER_RAPTOR", "premium": True})
    return model
