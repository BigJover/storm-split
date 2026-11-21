"""Lava Lord hunter pieces (premium theme, PREMIUM_SKINS.md, batch 11p1): black obsidian plates with
cracked orange seams. The seams are paint group `glow` (Neon in game, #439), so Shared/SkinFx can
pulse / flow them; everything here is authored in the hunter body's frame (_body.py: Roblox studs
about the HumanoidRootPart, front -Z) and added with `body.add` by a variant's `extra`.

Helpers only (no model): `seg` (a tapered segment), `horn` (a curved tapering horn, tip apart),
`drip` (a hanging magma drop), `rod` (a thin cylinder a -> b, the crack segment), `crack` (a jagged
polyline of rods, slightly overlapping so the bends don't gap), `on_ell` (a point on an
ellipsoid's surface, for cracks that follow a helmet dome) and `plate` (a faceted obsidian
plate: a low-poly flattened ellipsoid, the facets catch the light like volcanic glass) and
`protect` (an `lp` wrapper for the build: the `glow` and `plate` pieces are left out of Body.finish's
even decimation, so thin seams and facets stay exact while the base's big smooth shapes pay).
"""

import math

import bmesh
from mathutils import Matrix, Vector


def rod(B, a, b, r, segments=4):
    """A thin open tube from a to b (Roblox axes; no caps: the ends sink into the surface or the
    next segment), 2 x segments triangles."""
    a, b = Vector(a), Vector(b)
    axis = b - a
    bm = bmesh.new()
    bmesh.ops.create_cone(bm, cap_ends=False, segments=segments, radius1=r, radius2=r * 0.8, depth=axis.length)
    rot = axis.to_track_quat("Z", "Y").to_matrix().to_4x4()
    bmesh.ops.transform(bm, matrix=Matrix.Translation((a + b) / 2) @ rot, verts=bm.verts)
    return B._obj(bm, "seam")


def crack(B, pts, r=0.032, segments=4, overlap=0.012):
    """Rods along the polyline pts, each stretched by `overlap` at both ends."""
    out = []
    for p, q in zip(pts, pts[1:]):
        p, q = Vector(p), Vector(q)
        d = (q - p).normalized() * overlap
        out.append(rod(B, p - d, q + d, r, segments))
    return out


def on_ell(centre, radii, yaw, pitch, lift=1.0):
    """The point on an ellipsoid at azimuth `yaw` (degrees, 0 = front -Z, 90 = +X) and elevation
    `pitch` (degrees above the equator), pushed out by `lift` (1.0 = on the surface)."""
    y, p = math.radians(yaw), math.radians(pitch)
    cx, cy, cz = centre
    rx, ry, rz = radii
    return (cx + rx * lift * math.cos(p) * math.sin(y),
            cy + ry * lift * math.sin(p),
            cz - rz * lift * math.cos(p) * math.cos(y))


def seg(B, a, b, r1, r2, segments=6, cap=True, tag="seg"):
    """A tapered segment a -> b (radius r1 at a, r2 at b; r2 = 0 is a point), Roblox axes."""
    a, b = Vector(a), Vector(b)
    axis = b - a
    bm = bmesh.new()
    bmesh.ops.create_cone(bm, cap_ends=cap, segments=segments, radius1=r1, radius2=r2, depth=axis.length)
    rot = axis.to_track_quat("Z", "Y").to_matrix().to_4x4()
    bmesh.ops.transform(bm, matrix=Matrix.Translation((a + b) / 2) @ rot, verts=bm.verts)
    return B._obj(bm, tag)


def horn(B, pts, r0, segments=6, overlap=0.02):
    """A curved horn along pts, tapering from r0 to a point; returns (body, tip) so the tip (the
    last segment) can be its own paint group (a glowing tip)."""
    n = len(pts) - 1
    out = []
    for i, (p, q) in enumerate(zip(pts, pts[1:])):
        p, q = Vector(p), Vector(q)
        d = (q - p).normalized() * overlap
        r1, r2 = r0 * (1 - (i / n) ** 1.6), r0 * (1 - ((i + 1) / n) ** 1.6)  # thick most of the way
        out.append(seg(B, p - d, q, r1, r2, segments, cap=(i == 0)))
    return out[:-1], out[-1]


def drip(B, top, length, r, rot=None):
    """A hanging magma drop: an ellipsoid stretched down from `top`."""
    x, y, z = top
    return B.ell((x, y - length / 2, z), (r, length / 2, r), 6, 4, rot=rot)


def plate(B, centre, radii, rot=None, segments=7, rings=4):
    """A faceted obsidian plate (few segments on purpose: flat facets read as volcanic glass)."""
    return B.ell(centre, radii, segments, rings, rot=rot)


PROTECTED = ("__glow", "__plate")


class protect:
    """Wraps `lp` for S.variant: Body.finish sees the protected pieces as 0 triangles and never
    decimates them, so its `target` is the budget for everything else (build.py still counts and
    checks the real total against the hero budget)."""

    def __init__(self, lp):
        self._lp = lp

    def __getattr__(self, name):
        return getattr(self._lp, name)

    def tris(self, o):
        return 0 if o.name.endswith(PROTECTED) else self._lp.tris(o)

    def decimate_to(self, o, n):
        if not o.name.endswith(PROTECTED):
            self._lp.decimate_to(o, n)
