"""SET_GEODE - the Geode premium tower set's trim (PREMIUM_SKINS.md, batch 11p6): a rough stone rim round the
footprint with a glowing amethyst seam along its top, a crystal cluster bursting out of a rock lump on the
front-left corner (a tall glowing crystal, two amethyst and a teal one leaning out) and a cracked-open boulder
on the back-left with a glowing gem bed and crystals in the split.
`glow` = Neon in game (Shared/SkinFx: the crystal element glints along it). Over any tower's art
(variants/_sets.py checks: <= 300 tris, rim <= 0.3, raised pieces only on the left corners <= 1.1, flag +
Rescue Beacon corners clear).
"""
# art-sources: variants/_sets.py

import importlib.util
import math
from pathlib import Path

import bmesh
from mathutils import Matrix, Vector

_spec = importlib.util.spec_from_file_location("_sets", Path(__file__).with_name("variants") / "_sets.py")
S = importlib.util.module_from_spec(_spec)
_spec.loader.exec_module(S)

LOOK = ((116, 112, 124), (70, 62, 84))  # the set's colour (stone grey) + accent (dark slate-violet): preview paint until the Skins row exists
COLORS = {"rock": (150, 146, 158), "rock2": (96, 92, 104), "crystal": (122, 58, 196), "teal": (52, 196, 186),
          "glow": (226, 156, 255)}


def crystal(K, a, b, r, sides=5, point=0.32):
    a, b = Vector(a), Vector(b)
    axis = b - a
    L = axis.length
    bm = bmesh.new()
    rings = [[bm.verts.new((rr * math.cos(2 * math.pi * i / sides), rr * math.sin(2 * math.pi * i / sides), z)) for i in range(sides)]
             for z, rr in ((0.0, r * 0.92), (L * (1 - point), r))]
    apex = bm.verts.new((0, 0, L))
    bm.faces.new(list(reversed(rings[0])))
    for i in range(sides):
        j = (i + 1) % sides
        bm.faces.new((rings[0][i], rings[0][j], rings[1][j], rings[1][i]))
        bm.faces.new((rings[1][i], rings[1][j], apex))
    bmesh.ops.recalc_face_normals(bm, faces=bm.faces)
    rot = axis.to_track_quat("Z", "Y").to_matrix().to_4x4()
    bmesh.ops.transform(bm, matrix=Matrix.Translation(a) @ rot, verts=bm.verts)
    return K._obj(bm, "xtal")


def design(k, K):
    S.rim(k, K, "rock", h=0.2, w=0.2)
    S.rim(k, K, "glow", h=0.25, w=0.05)
    # front-left: a crystal cluster out of a rock lump
    cx, cz = -1.1, -1.1
    k.add("rock", K.ell((cx, 0.18, cz), (0.36, 0.17, 0.36), 6, 3))
    k.add("glow", crystal(K, (cx, 0.1, cz), (cx - 0.04, 1.06, cz - 0.04), 0.13))
    k.add("crystal", crystal(K, (cx + 0.12, 0.1, cz), (cx + 0.3, 0.7, cz - 0.08), 0.1),
          crystal(K, (cx, 0.1, cz + 0.12), (cx - 0.08, 0.66, cz + 0.32), 0.1))
    k.add("teal", crystal(K, (cx - 0.1, 0.1, cz - 0.06), (cx - 0.34, 0.56, cz - 0.24), 0.08))
    # back-left: a cracked-open boulder, gem bed glowing in the split, crystals in it
    bx, bz = -1.08, 1.08
    k.add("rock", K.ell((bx - 0.17, 0.32, bz), (0.24, 0.3, 0.36), 6, 3, rot=(0, 0, 14)),
          K.ell((bx + 0.17, 0.28, bz), (0.22, 0.26, 0.34), 6, 3, rot=(0, 0, -16)))
    k.add("glow", K.ell((bx, 0.3, bz), (0.06, 0.22, 0.26), 5, 3),
          crystal(K, (bx, 0.4, bz), (bx, 0.92, bz - 0.06), 0.08))


def build(lp):
    model = S.trim(lp, "GEODE", "Geode", design, colors=COLORS, look=LOOK, show="SCOUT")
    if model:  # (_setpiece_common._trim stubs S.trim to read the design: it returns {})
        model["batch"] = "11p6"
        model["meta"].update({"theme": "GEODE", "premium": True})
    return model
