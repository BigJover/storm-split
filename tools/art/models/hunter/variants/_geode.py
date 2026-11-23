"""Geode hunter pieces (premium theme, PREMIUM_SKINS.md, batch 11p6): rough grey rock armour cracked open to
bright amethyst crystal, with some teal / rose crystal accents. The lit crystal (cracks, gem cores, the tips of
the clusters) is paint group `glow` (Neon in game, #439: Shared/SkinFx pulses it, the crystal element glints);
`crystal` is the deeper solid amethyst of the bigger shards, `teal` / `rose` the accent crystals and `rock` /
`rock2` the stone. Authored in the hunter body's frame (_body.py: Roblox studs about the HumanoidRootPart,
front -Z).

Helpers only (no model):
  seg / rod / crack / on_ell     tapered segments, thin glowing crack lines, points on an ellipsoid
  rock(B, c, radii, rot)         a faceted boulder / plate (few segments: flat facets read as rough stone)
  crystal(B, base, tip, r)       a hexagonal crystal: a 6-sided prism with a pointed termination (~22 tris)
  cluster(B, at, up, ...)        a fan of crystals of uneven length round a direction (a druse)
  geode(B, c, normal, r)         a cracked-open rock rim round a glowing faceted gem bed: the theme's core
  protect                        an `lp` wrapper: glow / crystal / teal / rose / rock pieces skip
                                 Body.finish's even decimation (facets and points stay crisp)
"""

import math

import bmesh
from mathutils import Matrix, Vector

ROCK = (150, 146, 158)
ROCK2 = (96, 92, 104)
CRYSTAL = (122, 58, 196)
GLOW = (226, 156, 255)
TEAL = (52, 196, 186)
ROSE = (240, 140, 186)


def rod(B, a, b, r, segments=4):
    a, b = Vector(a), Vector(b)
    axis = b - a
    bm = bmesh.new()
    bmesh.ops.create_cone(bm, cap_ends=False, segments=segments, radius1=r, radius2=r * 0.8, depth=axis.length)
    rot = axis.to_track_quat("Z", "Y").to_matrix().to_4x4()
    bmesh.ops.transform(bm, matrix=Matrix.Translation((a + b) / 2) @ rot, verts=bm.verts)
    return B._obj(bm, "seam")


def crack(B, pts, r=0.03, segments=4, overlap=0.012):
    out = []
    for p, q in zip(pts, pts[1:]):
        p, q = Vector(p), Vector(q)
        d = (q - p).normalized() * overlap
        out.append(rod(B, p - d, q + d, r, segments))
    return out


def on_ell(centre, radii, yaw, pitch, lift=1.0):
    y, p = math.radians(yaw), math.radians(pitch)
    cx, cy, cz = centre
    rx, ry, rz = radii
    return (cx + rx * lift * math.cos(p) * math.sin(y), cy + ry * lift * math.sin(p), cz - rz * lift * math.cos(p) * math.cos(y))


def seg(B, a, b, r1, r2, segments=6, cap=True, tag="seg"):
    a, b = Vector(a), Vector(b)
    axis = b - a
    bm = bmesh.new()
    bmesh.ops.create_cone(bm, cap_ends=cap, segments=segments, radius1=r1, radius2=r2, depth=axis.length)
    rot = axis.to_track_quat("Z", "Y").to_matrix().to_4x4()
    bmesh.ops.transform(bm, matrix=Matrix.Translation((a + b) / 2) @ rot, verts=bm.verts)
    return B._obj(bm, tag)


def rock(B, centre, radii, rot=None, segments=7, rings=4):
    """A faceted stone (a flattened low-poly ellipsoid: flat facets read as rough rock)."""
    return B.ell(centre, radii, segments, rings, rot=rot)


def crystal(B, base, tip, r, sides=6, point=0.3, twist=0.0):
    """A crystal from base to tip: a `sides`-sided prism of radius r, then a pyramid over the last `point`
    share of its length (a natural termination). The base end is capped flat (it sinks into rock)."""
    a, b = Vector(base), Vector(tip)
    axis = b - a
    L = axis.length
    bm = bmesh.new()
    rings = []
    for z, rr in ((0.0, r * 0.92), (L * (1 - point), r)):
        ring = []
        for i in range(sides):
            t = 2 * math.pi * i / sides + math.radians(twist)
            ring.append(bm.verts.new((rr * math.cos(t), rr * math.sin(t), z)))
        rings.append(ring)
    apex = bm.verts.new((0, 0, L))
    bm.faces.new(list(reversed(rings[0])))
    for i in range(sides):
        j = (i + 1) % sides
        bm.faces.new((rings[0][i], rings[0][j], rings[1][j], rings[1][i]))
        bm.faces.new((rings[1][i], rings[1][j], apex))
    bmesh.ops.recalc_face_normals(bm, faces=bm.faces)
    rot = axis.to_track_quat("Z", "Y").to_matrix().to_4x4()
    bmesh.ops.transform(bm, matrix=Matrix.Translation(a) @ rot, verts=bm.verts)
    obj = B._obj(bm, "xtal")
    for e in obj.data.edges:
        e.use_edge_sharp = True
    return obj


def _basis(up):
    up = Vector(up).normalized()
    side = up.cross(Vector((0, 0, 1)) if abs(up.z) < 0.9 else Vector((1, 0, 0))).normalized()
    fwd = side.cross(up).normalized()
    return up, side, fwd


def cluster(B, at, up, n=5, length=0.6, r=0.09, spread=28, phase=0.0, sides=6, lens=None):
    """A druse: one tall centre crystal along `up` and n-1 shorter ones leaning out round it (deterministic
    lengths and angles). Returns the list of crystals (centre first)."""
    at = Vector(at)
    u, s, f = _basis(up)
    out = [crystal(B, at - u * 0.06, at + u * length, r, sides)]
    lens = lens or [0.72, 0.55, 0.85, 0.6, 0.68, 0.5, 0.78]
    for i in range(n - 1):
        a = math.radians(phase + 360 * i / (n - 1))
        lean = math.radians(spread * (0.8 + 0.4 * ((i * 7) % 3) / 2))
        d = (u * math.cos(lean) + (s * math.cos(a) + f * math.sin(a)) * math.sin(lean)).normalized()
        foot = at + (s * math.cos(a) + f * math.sin(a)) * r * 0.9
        ln = length * lens[i % len(lens)]
        out.append(crystal(B, foot - d * 0.05, foot + d * ln, r * (0.65 + 0.2 * (i % 2)), sides, twist=15 * i))
    return out


def geode(B, c, normal, r, depth=0.08, n=7, rim_group_sides=7):
    """A split geode facing `normal`: a faceted rock rim (a torus of rough stone), a glowing faceted gem bed
    inside it and short crystal points standing out of the bed. Returns {"rock": [...], "glow": [...],
    "crystal": [...]}."""
    c = Vector(c)
    u, s, f = _basis(normal)
    bm = bmesh.new()
    seg_n, minor = rim_group_sides + 2, 4
    rows = []
    for i in range(seg_n):
        a = 2 * math.pi * i / seg_n
        wob = 1.0 + 0.12 * math.sin(3 * a + 1.0)
        row = []
        for j in range(minor):
            b = 2 * math.pi * j / minor + math.pi / 4
            rr = r * wob + r * 0.22 * math.cos(b)
            p = c + (s * math.cos(a) + f * math.sin(a)) * rr + u * (r * 0.22 * math.sin(b))
            row.append(bm.verts.new(p))
        rows.append(row)
    for i in range(seg_n):
        for j in range(minor):
            a_, b_ = rows[i][j], rows[(i + 1) % seg_n][j]
            c_, d_ = rows[(i + 1) % seg_n][(j + 1) % minor], rows[i][(j + 1) % minor]
            bm.faces.new((a_, b_, c_, d_))
    bmesh.ops.recalc_face_normals(bm, faces=bm.faces)
    rim = B._obj(bm, "rim")
    bed = B.ell(tuple(c - u * depth * 0.5), (r * 0.95, r * 0.95, r * 0.95), 7, 4)
    # flatten the bed along the normal: squash it so it reads as a glowing faceted disc
    m = Matrix.Translation(c) @ _squash(u, 0.35) @ Matrix.Translation(-c)
    bed.data.transform(m)
    bed.data.update()
    pts = []
    for i in range(n):
        a = 2 * math.pi * i / n + 0.4
        rr = r * (0.25 + 0.4 * ((i * 5) % 3) / 2)
        foot = c + (s * math.cos(a) + f * math.sin(a)) * rr
        d = (u + (s * math.cos(a) + f * math.sin(a)) * 0.35).normalized()
        pts.append(crystal(B, foot - u * 0.04, foot + d * r * (0.45 + 0.25 * (i % 3)), r * 0.16, 5, twist=20 * i))
    pts.append(crystal(B, c - u * 0.04, c + u * r * 0.85, r * 0.22, 6))
    return {"rock": [rim], "glow": [bed] + pts[-1:] + pts[0:-1:2], "crystal": pts[1:-1:2]}


def _squash(u, k):
    """A scale by k along unit vector u (1 elsewhere)."""
    u = Vector(u)
    I = Matrix.Identity(3)
    M = I + (k - 1) * Matrix([[u.x * u.x, u.x * u.y, u.x * u.z], [u.y * u.x, u.y * u.y, u.y * u.z], [u.z * u.x, u.z * u.y, u.z * u.z]])
    return M.to_4x4()


def add_groups(body, part, groups, rename=None):
    rename = rename or {}
    for group, objs in groups.items():
        if objs:
            body.add(part, rename.get(group, group), *objs)


PROTECTED = ("__glow", "__crystal", "__teal", "__rose", "__rock", "__rock2")


class protect:
    def __init__(self, lp):
        self._lp = lp

    def __getattr__(self, name):
        return getattr(self._lp, name)

    def tris(self, o):
        return 0 if o.name.endswith(PROTECTED) else self._lp.tris(o)

    def decimate_to(self, o, n):
        if not o.name.endswith(PROTECTED):
            self._lp.decimate_to(o, n)
