"""Walker PARATROOPER_CHUTE (PLAN 11d2): the Paratrooper's open canopy, for the drop.

Not in today's game: Paratroopers appear on the ground (Towers: Walkers.sync at the landing
point). Additive, authored in PARATROOPER's frame (origin = the Body's centre), so a runtime
drop can weld it at identity on top of the trooper while it falls and remove it on landing.
A round canopy (sand gores + camp-colour bands, a vent cap) on 8 lines that gather to two risers
at the harness's shoulders (+-0.2, 0.52).
"""

import importlib.util
import math
from pathlib import Path

_spec = importlib.util.spec_from_file_location("_walker", Path(__file__).with_name("_walker.py"))
W = importlib.util.module_from_spec(_spec)
_spec.loader.exec_module(W)

LOOK = ((-2.7, 0.4, -2.7), (2.7, 6.5, 2.7))  # its own envelope (no blocky look to match)


def dome(centre, radius, height, under, segments=12, rings=5):
    """A canopy: the upper half of a squashed sphere, its underside a shallow bowl (`under` x)."""
    obj = W.ell(centre, (radius, radius, height), segments, rings, rot=(-90, 0, 0))  # poles on Y
    cy = centre[1]
    for v in obj.data.vertices:  # Roblox axes (the Walk converts at finish): y is up
        if v.co.y < cy:
            v.co.y = cy + (v.co.y - cy) * under
    obj.data.update()
    return obj


def gores(centre, radius, height, under, keep, segments=16, rings=7, per=2):
    """The dome's faces in alternate sectors (`per` segments wide): keep = 0 or 1, so two calls
    make the classic two-colour gores."""
    import bmesh

    obj = dome(centre, radius, height, under, segments, rings)
    bm = bmesh.new()
    bm.from_mesh(obj.data)
    drop = []
    for f in bm.faces:
        c = f.calc_center_median()
        a = math.atan2(c.z - centre[2], c.x - centre[0]) % (2 * math.pi)
        if int(a / (2 * math.pi) * segments / per) % 2 != keep:
            drop.append(f)
    bmesh.ops.delete(bm, geom=drop, context="FACES")
    bm.to_mesh(obj.data)
    bm.free()
    return obj


def build(lp):
    w = W.Walk(lp, LOOK, 1.0, slack=0.05)
    top = 4.9
    w.add("canvas", gores((0, top, 0), 2.5, 1.45, 0.3, 0))
    w.add("camp", gores((0, top, 0), 2.5, 1.45, 0.3, 1))
    w.add("canvas", W.cyl((0, top + 1.42, 0), 0.34, 0.08, 10, bevel=0.02))  # vent cap
    w.add("canvas", W.ring((0, top - 0.02, 0), 2.48, 0.05, 16, 3))  # hem
    lines = []
    for i in range(8):
        a = 2 * math.pi * (i + 0.5) / 8
        rim = (2.42 * math.cos(a), top - 0.02, 2.42 * math.sin(a))
        riser = (0.2 if rim[0] > 0 else -0.2, 1.5, 0.0)
        lines.append(W.rod(rim, riser, 0.018, 3))
    for s in (-1, 1):  # risers down to the shoulders
        lines.append(W.rod((0.2 * s, 1.5, 0.0), (0.2 * s, 0.55, 0.1), 0.03, 4))
    w.add("rope", *lines)
    colors = {"canvas": (226, 214, 180), "camp": W.CAMP, "rope": (150, 140, 110)}
    return w.model("small", colors, {"walker": "paratrooper", "attach": "PARATROOPER", "kind": "chute",
                                     "display": "Paratrooper's canopy"}, 760)
