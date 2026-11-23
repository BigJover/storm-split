"""SET_TYRANT_KING - the Tyrant King premium tower set's trim (PREMIUM_SKINS.md, batch 11p4): a bone rim round
the footprint with a crimson band along its top and a red glowing seam, a pair of giant rex fangs with a
small bone crown between them on the front-left corner (its gem glows), and a crimson pennant on a short
bone pole with a gold claw finial and a glowing rex-eye sigil at the back-left.
`glow` = Neon in game (Shared/SkinFx pulses it; at stage 2 the eyes light up and gold dust sparkles).
Over any tower's art (variants/_sets.py checks: <= 300 tris, rim <= 0.3, raised pieces only on the left
corners <= 1.1, flag + Rescue Beacon corners clear).
"""
# art-sources: variants/_sets.py

import importlib.util
import math
from pathlib import Path

_spec = importlib.util.spec_from_file_location("_sets", Path(__file__).with_name("variants") / "_sets.py")
S = importlib.util.module_from_spec(_spec)
_spec.loader.exec_module(S)

LOOK = ((150, 26, 38), (62, 46, 48))  # the set's colour (crimson) + accent (dark iron, so the bone pieces read): preview paint until the Skins row exists
COLORS = {"bone": (234, 224, 198), "crimson": (156, 22, 36), "gold": (214, 170, 64), "glow": (255, 34, 44)}


def design(k, K):
    S.rim(k, K, "bone", h=0.18, w=0.2)
    S.rim(k, K, "crimson", h=0.24, w=0.12)
    S.rim(k, K, "glow", h=0.28, w=0.03)
    # front-left: two giant fangs curving in, a small bone crown between them
    k.add("bone", K.rod((-1.32, 0.0, -0.92), (-1.24, 1.05, -1.08), 0.13, 5, top=0.05),
          K.rod((-0.92, 0.0, -1.32), (-1.08, 0.95, -1.24), 0.12, 5, top=0.05))
    cx, cz = -1.05, -1.05
    k.add("gold", K.cyl((cx, 0.3, cz), 0.16, 0.1, 6, bevel=0.0))
    k.add("bone", *[K.rod((cx + 0.14 * math.cos(a), 0.34, cz + 0.14 * math.sin(a)),
                          (cx + 0.16 * math.cos(a), 0.58, cz + 0.16 * math.sin(a)), 0.04, 3, top=0.05)
                    for a in (math.radians(d) for d in (0, 120, 240))])
    k.add("glow", K.ell((cx + 0.06, 0.32, cz - 0.12), (0.04, 0.04, 0.03), 4, 3))
    # back-left: a crimson pennant on a short bone pole, gold claw finial, glowing sigil
    k.add("bone", K.rod((-1.3, 0.0, 1.3), (-1.3, 1.0, 1.3), 0.045, 5))
    k.add("gold", K.rod((-1.3, 1.0, 1.3), (-1.3, 1.1, 1.3), 0.03, 4, top=0.1))
    k.add("crimson", K.rbox((-1.3, 0.78, 1.04), (0.04, 0.32, 0.48), bevel=0.0, taper=(1.0, 1.0)))
    k.add("glow", K.ell((-1.33, 0.78, 1.04), (0.02, 0.07, 0.07), 4, 3))


def build(lp):
    model = S.trim(lp, "TYRANT_KING", "Tyrant King", design, colors=COLORS, look=LOOK, show="SCOUT")
    if model:  # (_setpiece_common._trim stubs S.trim to read the design: it returns {})
        model["batch"] = "11p4"
        model["meta"].update({"theme": "TYRANT_KING", "premium": True})
    return model
