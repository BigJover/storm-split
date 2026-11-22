"""Cyber Raptor hunter pieces (premium theme, PREMIUM_SKINS.md, batch 11p3, element electric /
digital glitch, #462): black-chrome raptor armour with circuit-line seams. Every trace, pad, visor,
emitter and fin edge is paint group `glow` (Neon in game, #439; Shared/SkinFx cycles it cyan ->
magenta), black chrome is `plate`, bright gunmetal trim is `chrome`. Authored in the hunter body's
frame (_body.py: Roblox studs about the HumanoidRootPart, front -Z).

Helpers only (no model): `rod` (a thin square tube a -> b: a circuit trace), `trace` (a polyline
of rods, overlapping so the bends close), `pad` (a small square solder pad / pixel), `seg` (a
tapered segment, a spike or antenna), `claw` (a curved tapering raptor claw), `fin` (a flat
swept crest fin), `on_ell` (a point on an ellipsoid, for traces that follow a helmet), `protect`
(the `lp` wrapper: glow / plate / chrome pieces skip Body.finish's even decimation).
"""

import math

import bmesh
from mathutils import Matrix, Vector


def rod(B, a, b, r, segments=4, tag="seam"):
    a, b = Vector(a), Vector(b)
    axis = b - a
    bm = bmesh.new()
    bmesh.ops.create_cone(bm, cap_ends=False, segments=segments, radius1=r, radius2=r, depth=axis.length)
    rot = axis.to_track_quat("Z", "Y").to_matrix().to_4x4()
    bmesh.ops.transform(bm, matrix=Matrix.Translation((a + b) / 2) @ rot, verts=bm.verts)
    return B._obj(bm, tag)


def trace(B, pts, r=0.026, overlap=0.01):
    """A circuit trace along pts (thin square tubes, 8 tris a segment)."""
    out = []
    for p, q in zip(pts, pts[1:]):
        p, q = Vector(p), Vector(q)
        d = (q - p).normalized() * overlap
        out.append(rod(B, p - d, q + d, r))
    return out


def pad(B, p, s=0.075, rot=None):
    """A square solder pad / pixel (a flat box, 12 tris) at p."""
    return B.rbox(p, (s, s, s * 0.6), bevel=0.0, segments=1, rot=rot)


def seg(B, a, b, r1, r2, segments=5, cap=True, tag="seg"):
    a, b = Vector(a), Vector(b)
    axis = b - a
    bm = bmesh.new()
    bmesh.ops.create_cone(bm, cap_ends=cap, segments=segments, radius1=r1, radius2=r2, depth=axis.length)
    rot = axis.to_track_quat("Z", "Y").to_matrix().to_4x4()
    bmesh.ops.transform(bm, matrix=Matrix.Translation((a + b) / 2) @ rot, verts=bm.verts)
    return B._obj(bm, tag)


def claw(B, pts, r0, segments=4, overlap=0.015):
    """A curved claw along pts tapering from r0 to a point: (body, tip) - the tip can glow."""
    n = len(pts) - 1
    out = []
    for i, (p, q) in enumerate(zip(pts, pts[1:])):
        p, q = Vector(p), Vector(q)
        d = (q - p).normalized() * overlap
        r1, r2 = r0 * (1 - (i / n) ** 1.3), r0 * (1 - ((i + 1) / n) ** 1.3)
        out.append(seg(B, p - d, q, r1, max(r2, 0.0), segments, cap=(i == 0)))
    return out[:-1], out[-1]


def fin(B, centre, length, height, thick, rot=None, sweep=0.35):
    """A flat swept crest fin: a wedge whose top edge is shorter (swept back), 12 tris.
    Its long axis is local Z (front -Z), height local Y."""
    return B.rbox(centre, (thick, height, length), bevel=0.0, segments=1, rot=rot, taper=(0.6, sweep))


def on_ell(centre, radii, yaw, pitch, lift=1.0):
    y, p = math.radians(yaw), math.radians(pitch)
    cx, cy, cz = centre
    rx, ry, rz = radii
    return (cx + rx * lift * math.cos(p) * math.sin(y),
            cy + ry * lift * math.sin(p),
            cz - rz * lift * math.cos(p) * math.cos(y))


PROTECTED = ("__glow", "__plate", "__chrome", "__eye")


class protect:
    """Body.finish sees the protected pieces as 0 triangles and never decimates them (build.py
    still counts the real total against the hero budget)."""

    def __init__(self, lp):
        self._lp = lp

    def __getattr__(self, name):
        return getattr(self._lp, name)

    def tris(self, o):
        return 0 if o.name.endswith(PROTECTED) else self._lp.tris(o)

    def decimate_to(self, o, n):
        if not o.name.endswith(PROTECTED):
            self._lp.decimate_to(o, n)


COLORS = {
    "plate": (30, 32, 44),     # black chrome (a cool blue-black so the facets read)
    "chrome": (138, 148, 166), # bright gunmetal trim, joints, claws
    "glow": (0, 236, 255),     # circuit cyan (Neon; SkinFx cycles it toward magenta)
}
