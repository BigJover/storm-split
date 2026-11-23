"""Nebula hunter pieces (premium theme, PREMIUM_SKINS.md "Nebula - cosmic", batch 11p5, #462: element
cosmic / void). Star-speckled indigo plates, deep-violet cloth with pink / teal nebula swirls, and
starlight in paint group `glow` (Neon in game: constellation lines, star points, orbit rings, halos;
Shared/SkinFx pulses / twinkles them). Authored in the hunter body's frame (_body.py: Roblox studs
about the HumanoidRootPart, front -Z).

Helpers only (no model): `rod` / `seg` (tubes and tapered spikes a -> b), `on_ell` (a point on an
ellipsoid's surface), `torus` (an orbit ring / halo), `star` (a small faceted star point),
`sparkle` (a flat four-point star facing a direction), `constellation` (star points joined by thin
lines), `swirl` (a flat nebula streak), `protect` (an `lp` wrapper: the protected pieces skip
Body.finish's even decimation, so thin lines and points stay exact).
"""

import math

import bmesh
from mathutils import Euler, Matrix, Vector


def rod(B, a, b, r, segments=4, taper=0.85):
    """A thin open tube a -> b (no caps)."""
    a, b = Vector(a), Vector(b)
    axis = b - a
    bm = bmesh.new()
    bmesh.ops.create_cone(bm, cap_ends=False, segments=segments, radius1=r, radius2=r * taper, depth=axis.length)
    rot = axis.to_track_quat("Z", "Y").to_matrix().to_4x4()
    bmesh.ops.transform(bm, matrix=Matrix.Translation((a + b) / 2) @ rot, verts=bm.verts)
    return B._obj(bm, "line")


def seg(B, a, b, r1, r2, segments=6, cap=True):
    """A tapered segment a -> b (r2 = 0: a point)."""
    a, b = Vector(a), Vector(b)
    axis = b - a
    bm = bmesh.new()
    bmesh.ops.create_cone(bm, cap_ends=cap, segments=segments, radius1=r1, radius2=r2, depth=axis.length)
    rot = axis.to_track_quat("Z", "Y").to_matrix().to_4x4()
    bmesh.ops.transform(bm, matrix=Matrix.Translation((a + b) / 2) @ rot, verts=bm.verts)
    return B._obj(bm, "seg")


def on_ell(centre, radii, yaw, pitch, lift=1.0):
    """Point on an ellipsoid: yaw 0 = front (-Z), 90 = +X; pitch above the equator; lift 1 = surface."""
    y, p = math.radians(yaw), math.radians(pitch)
    cx, cy, cz = centre
    rx, ry, rz = radii
    return (cx + rx * lift * math.cos(p) * math.sin(y), cy + ry * lift * math.sin(p), cz - rz * lift * math.cos(p) * math.cos(y))


def torus(B, centre, R, r, segments=16, minor=4, rot=None, squash=1.0):
    """A ring in the XZ plane (axis Y) of major radius R (or (Rx, Rz)) and tube radius r; then
    rotated (Euler degrees, XYZ) and moved to centre. squash flattens the tube vertically."""
    Rx, Rz = R if isinstance(R, (tuple, list)) else (R, R)
    bm = bmesh.new()
    rings = []
    for i in range(segments):
        a = 2 * math.pi * i / segments
        ca, sa = math.cos(a), math.sin(a)
        ring = []
        for j in range(minor):
            b = 2 * math.pi * j / minor + math.pi / minor
            rr = r * math.cos(b)
            ring.append(bm.verts.new(((Rx + rr) * ca, r * squash * math.sin(b), (Rz + rr) * sa)))
        rings.append(ring)
    for i in range(segments):
        a, b = rings[i], rings[(i + 1) % segments]
        for j in range(minor):
            bm.faces.new((a[j], a[(j + 1) % minor], b[(j + 1) % minor], b[j]))
    obj = B._obj(bm, "torus")
    m = Matrix.Translation(Vector(centre))
    if rot:
        m = m @ Euler([math.radians(v) for v in rot], "XYZ").to_matrix().to_4x4()
    obj.data.transform(m)
    obj.data.update()
    return obj


def star(B, c, s):
    """A small faceted star point (an octahedron, 8 tris)."""
    return B.ell(c, (s, s, s), 4, 2)


def sparkle(B, c, s, rot=(0, 0, 0), t=0.025):
    """A flat four-point star (two long thin diamonds crossed), facing -Z before rot."""
    return [B.ell(c, (s, s * 0.2, t), 4, 2, rot=rot),
            B.ell(c, (s * 0.2, s, t), 4, 2, rot=rot)]


def constellation(B, pts, r=0.022, s=0.055, big=()):
    """Star points at pts joined by thin lines; points listed in `big` (indices) are larger."""
    lines = [rod(B, p, q, r, 3, 1.0) for p, q in zip(pts, pts[1:])]
    stars = [star(B, p, s * (1.7 if i in big else 1.0)) for i, p in enumerate(pts)]
    return lines + stars


def swirl(B, pts, w, t=0.03, facing=(0, 0, 0)):
    """A flat streak along pts lying on a surface that faces -Z before `facing` (Euler degrees):
    flattened ellipsoids end to end, narrowing toward the last point."""
    out = []
    n = len(pts) - 1
    for i, (p, q) in enumerate(zip(pts, pts[1:])):
        dx, dy = q[0] - p[0], q[1] - p[1]
        length = math.hypot(dx, dy)
        ang = math.degrees(math.atan2(dy, dx))
        c = tuple((a + b) / 2 for a, b in zip(p, q))
        ww = w * (1 - 0.45 * i / max(1, n))
        out.append(B.ell(c, (length / 2 + ww * 0.4, ww / 2, t), 8, 3, rot=(facing[0], facing[1], ang)))
    return out


def cloud(B, c, r, t=0.02, tilt=0.0, n=4):
    """A flat nebula cloud on a surface facing +/-Z: overlapping ovals of falling size along a
    slight diagonal (tilt degrees). Lies in the XY plane at c's z."""
    out = []
    a = math.radians(tilt)
    for i, (dx, dy, s) in enumerate(((0, 0, 1.0), (0.7, 0.25, 0.72), (-0.65, -0.2, 0.66), (1.25, 0.5, 0.42), (-1.15, -0.45, 0.4))[:n]):
        x = c[0] + r * (dx * math.cos(a) - dy * math.sin(a))
        y = c[1] + r * (dx * math.sin(a) + dy * math.cos(a))
        out.append(B.cyl((x, y, c[2]), (r * s, r * s * 0.62), t, 10, bevel=0.0, rot=(90, 0, tilt)))
    return out


def ribbon(B, pts, widths, t=0.04, side=(1, 0, 0)):
    """A flat flowing strip (scarf / tail) through pts, widths[i] wide at pts[i] across `side`
    (kept perpendicular to the strip's direction), t thick. A closed slab mesh."""
    side0 = Vector(side)
    top, bot = [], []
    bm = bmesh.new()
    n = len(pts)
    for i, p in enumerate(pts):
        p = Vector(p)
        d = (Vector(pts[min(i + 1, n - 1)]) - Vector(pts[max(i - 1, 0)])).normalized()
        sd = (side0 - d * side0.dot(d)).normalized()
        nm = d.cross(sd).normalized()
        w = widths[i] / 2
        top.append((bm.verts.new(p - sd * w + nm * t / 2), bm.verts.new(p + sd * w + nm * t / 2)))
        bot.append((bm.verts.new(p - sd * w - nm * t / 2), bm.verts.new(p + sd * w - nm * t / 2)))
    for i in range(n - 1):
        a, b = top[i], top[i + 1]
        c, d = bot[i], bot[i + 1]
        bm.faces.new((a[0], a[1], b[1], b[0]))
        bm.faces.new((c[0], d[0], d[1], c[1]))
        bm.faces.new((a[0], b[0], d[0], c[0]))
        bm.faces.new((a[1], c[1], d[1], b[1]))
    bm.faces.new((top[0][0], bot[0][0], bot[0][1], top[0][1]))
    bm.faces.new((top[-1][0], top[-1][1], bot[-1][1], bot[-1][0]))
    bmesh.ops.recalc_face_normals(bm, faces=bm.faces)
    return B._obj(bm, "ribbon")


def ring_point(centre, R, deg, rot):
    """The point at angle deg on a torus(centre, R, rot=rot) ring's centre line."""
    Rx, Rz = R if isinstance(R, (tuple, list)) else (R, R)
    a = math.radians(deg)
    v = Vector((Rx * math.cos(a), 0, Rz * math.sin(a)))
    v = Euler([math.radians(x) for x in rot], "XYZ").to_matrix() @ v
    return tuple(Vector(centre) + v)


PROTECTED = ("__glow", "__plate", "__star")


class protect:
    """Wraps `lp`: Body.finish sees the protected pieces as 0 triangles and never decimates them."""

    def __init__(self, lp):
        self._lp = lp

    def __getattr__(self, name):
        return getattr(self._lp, name)

    def tris(self, o):
        return 0 if o.name.endswith(PROTECTED) else self._lp.tris(o)

    def decimate_to(self, o, n):
        if not o.name.endswith(PROTECTED):
            self._lp.decimate_to(o, n)
