"""SET_NEBULA - the Nebula premium tower set's trim (PREMIUM_SKINS.md, batch 11p5, #462: element cosmic /
void): a deep-indigo rim round the footprint with a starlight seam along its top and star studs at the
corners, a cluster of violet meteor shards with a glowing star on the tallest at the front-left
corner, and a little ringed planet on a stem at the back-left.
`glow` = Neon in game (Shared/SkinFx twinkles it; brighter at stage 2). Over any tower's art
(variants/_sets.py checks: <= 300 tris, rim <= 0.3, raised pieces only on the left corners <= 1.1,
flag + Rescue Beacon corners clear).
"""
# art-sources: variants/_sets.py

import importlib.util
from pathlib import Path

_spec = importlib.util.spec_from_file_location("_sets", Path(__file__).with_name("variants") / "_sets.py")
S = importlib.util.module_from_spec(_spec)
_spec.loader.exec_module(S)

LOOK = ((28, 26, 58), (50, 44, 92))  # the set's colour (deep navy) + accent (dusk violet): preview paint only until the Skins row exists
COLORS = {"void": (34, 30, 80), "rock": (96, 78, 140), "nebula": (214, 88, 184), "glow": (150, 236, 240)}


def shard(K, base, h, w, lean=(0, 0, 0)):
    return K.rbox((base[0], base[1] + h / 2 + 0.04, base[2]), (w, h, w * 0.8), bevel=0.0, rot=lean, taper=(0.1, 0.12))


def design(k, K):
    S.rim(k, K, "void", h=0.2, w=0.2)
    S.rim(k, K, "glow", h=0.24, w=0.05)  # the seam: a thin starlight line out of the rim's middle
    k.add("glow", *[K.ell((x, 0.27, z), (0.06, 0.06, 0.06), 4, 2) for x, z in ((-1.4, 0.0),)])
    # front-left: violet meteor shards, a star on the tallest
    k.add("rock",
          shard(K, (-1.15, 0.0, -1.15), 0.86, 0.3, (-6, 0, 8)),
          shard(K, (-0.86, 0.0, -1.2), 0.5, 0.24, (-12, 0, -14)),
          shard(K, (-1.2, 0.0, -0.86), 0.58, 0.24, (10, 0, 12)))
    k.add("glow", K.ell((-1.2, 0.98, -1.16), (0.07, 0.07, 0.07), 4, 2),
          K.ell((-1.2, 0.98, -1.16), (0.15, 0.025, 0.025), 4, 2), K.ell((-1.2, 0.98, -1.16), (0.025, 0.11, 0.025), 4, 2))
    # back-left: a little ringed planet on a stem
    k.add("void", K.cyl((-1.12, 0.06, 1.12), 0.2, 0.12, 6, bevel=0.0), K.rod((-1.12, 0.1, 1.12), (-1.12, 0.6, 1.12), 0.03, 4))
    k.add("nebula", K.ell((-1.12, 0.78, 1.12), (0.2, 0.2, 0.2), 7, 4))
    k.add("glow", K.ring((-1.12, 0.78, 1.12), 0.3, 0.02, 10, 3, rot=(20, 0, 15)))


def build(lp):
    model = S.trim(lp, "NEBULA", "Nebula", design, colors=COLORS, look=LOOK, show="SCOUT")
    if model:  # (_setpiece_common._trim stubs S.trim to read the design: it returns {})
        model["batch"] = "11p5"
        model["meta"].update({"theme": "NEBULA", "premium": True})
    return model
