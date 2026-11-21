"""SET_LAVA_LORD - the Lava Lord premium tower set's trim (PREMIUM_SKINS.md, batch 11p1): an obsidian
rim round the footprint with a lava seam glowing along its top, a cluster of jagged obsidian shards
with glowing cracks on the front-left corner and (v2, #462) lava pouring off a small obsidian ledge
into a pool at the back-left.
`glow` = Neon in game (Shared/SkinFx pulses it; brighter, with embers, at stage 2). Over any tower's
art (variants/_sets.py checks: <= 300 tris, rim <= 0.3, raised pieces only on the left corners
<= 1.1, flag + Rescue Beacon corners clear).
"""
# art-sources: variants/_sets.py

import importlib.util
from pathlib import Path

_spec = importlib.util.spec_from_file_location("_sets", Path(__file__).with_name("variants") / "_sets.py")
S = importlib.util.module_from_spec(_spec)
_spec.loader.exec_module(S)

LOOK = ((50, 44, 54), (78, 68, 74))  # the set's colour (obsidian) + accent (basalt grey): preview paint only until the Skins row exists
COLORS = {"obsidian": (34, 30, 38), "glow": (255, 112, 20)}


def shard(K, base, h, w, lean=(0, 0, 0)):
    return K.rbox((base[0], base[1] + h / 2 + 0.04, base[2]), (w, h, w * 0.8), bevel=0.0, rot=lean, taper=(0.08, 0.1))


def design(k, K):
    S.rim(k, K, "obsidian", h=0.2, w=0.2)
    S.rim(k, K, "glow", h=0.24, w=0.05)  # the seam: a thin hot line standing out of the rim's middle
    # front-left: jagged shards, a crack glowing up the tallest
    k.add("obsidian",
          shard(K, (-1.15, 0.0, -1.15), 1.05, 0.34, (-6, 0, 8)),
          shard(K, (-0.85, 0.0, -1.22), 0.62, 0.26, (-12, 0, -14)),
          shard(K, (-1.22, 0.0, -0.84), 0.72, 0.26, (10, 0, 12)),
          shard(K, (-0.92, 0.0, -0.92), 0.4, 0.22, (0, 0, -20)))
    k.add("glow",
          K.rod((-1.06, 0.12, -1.3), (-1.1, 0.42, -1.29), 0.025, 3),
          K.rod((-1.1, 0.42, -1.29), (-1.05, 0.68, -1.25), 0.022, 3),
          K.rod((-0.95, 0.06, -0.8), (-0.98, 0.3, -0.78), 0.022, 3))
    # back-left (v2, #462): lava pouring off a small obsidian ledge into a pool in an obsidian lip
    k.add("obsidian", K.rbox((-1.2, 0.48, 1.2), (0.4, 0.96, 0.36), bevel=0.0, rot=(0, 45, 0), taper=(0.7, 0.7)),
          K.cyl((-0.92, 0.08, 0.92), 0.32, 0.16, 7, bevel=0.0))
    k.add("glow",
          K.rbox((-1.06, 0.5, 1.06), (0.18, 0.9, 0.04), bevel=0.0, rot=(0, 45, 0), taper=(0.6, 1.0)),  # the fall
          K.cyl((-0.92, 0.165, 0.92), 0.25, 0.02, 7, bevel=0.0))


def build(lp):
    model = S.trim(lp, "LAVA_LORD", "Lava Lord", design, colors=COLORS, look=LOOK, show="SCOUT")
    if model:  # (_setpiece_common._trim stubs S.trim to read the design: it returns {})
        model["batch"] = "11p1"
        model["meta"].update({"theme": "LAVA_LORD", "premium": True})
    return model
