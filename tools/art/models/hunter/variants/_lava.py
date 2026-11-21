"""Lava Lord hunter pieces (premium theme, PREMIUM_SKINS.md, batch 11p1): black obsidian plates with
cracked orange seams. The seams are paint group `glow` (Neon in game, #439), so Shared/SkinFx can
pulse / flow them; everything here is authored in the hunter body's frame (_body.py: Roblox studs
about the HumanoidRootPart, front -Z) and added with `body.add` by a variant's `extra`.

Helpers only (no model): `rod` (a thin cylinder a -> b, the crack segment), `crack` (a jagged
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
