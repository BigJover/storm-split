"""Shared helpers for the Outpost props (PLAN 11f T156, kind `prop`, DECISIONS #433). Runs in Blender.

A prop replaces one of the Hunters' Outpost's blocky builds (Server/Outpost, Shared/Decor). It is
authored in ROBLOX axes and studs (Y up, the prop's front faces -Z, its left is -X) about its
ANCHOR: the point on the ground the blocky code builds from (y = 0 = the floor / Campsite ground
top), e.g. a station's `at(row.offset, 0)`, a decoration spot's CFrame, a Campsite's `facing`.
The art is NOT moved to a part centre (unlike towers): place the model so its origin is the
anchor. `Camp.model` returns the real bounds as `box`, so build.py's fit-to-box is a no-op.

Primitives are copied from models/tower/_kit.py (same shapes, same look) so a tower helper edit
doesn't re-hash every prop (#440).

Paint groups: `wood dark rope canvas stone metal leaf ...` authored; on the 7 Campsite
decorations `body` = the Skins sheet look colour and `accent` = its accent (Shared/Decor's c / a).
Group `glow` = Neon (flames). Flat `face*` pieces (group `face`) are thin boxes whose Front
(-Z) face is where the runtime puts a SurfaceGui (sign text / poster); see README.
"""

import math

import bmesh
import bpy
from mathutils import Euler, Matrix, Vector

WOOD = (122, 88, 56)
DARK = (74, 54, 36)
CANVAS = (214, 200, 160)
SAND = (196, 174, 124)
ROPE = (176, 150, 100)
METAL = (78, 82, 86)
BRASS = (214, 168, 70)
LEAF = (88, 128, 60)
STONE = (128, 124, 116)
GLOW = (255, 150, 60)
PAPER = (232, 214, 170)
RAPTOR = (150, 170, 80)


def to_blender_matrix():
    """Roblox (x, y, z) -> Blender (x, -z, y), a proper rotation (normals stay outward)."""
    return Matrix(((1, 0, 0, 0), (0, 0, -1, 0), (0, 1, 0, 0), (0, 0, 0, 1)))


_n = [0]


def _obj(bm, tag):
    _n[0] += 1
    mesh = bpy.data.meshes.new(f"_{tag}{_n[0]}")
    bm.to_mesh(mesh)
    bm.free()
    obj = bpy.data.objects.new(mesh.name, mesh)
    bpy.context.scene.collection.objects.link(obj)
    return obj


def _bake(obj):
    depsgraph = bpy.context.evaluated_depsgraph_get()
    baked = bpy.data.meshes.new_from_object(obj.evaluated_get(depsgraph))
    old = obj.data
    obj.modifiers.clear()
    obj.data = baked
    bpy.data.meshes.remove(old)
    return obj


def _bevel(obj, width, segments):
    if width > 0 and segments > 0:
        mod = obj.modifiers.new("bev", "BEVEL")
        mod.width = width
        mod.segments = segments
        mod.limit_method = "NONE"
        _bake(obj)
    return obj


def _place(obj, centre, rot=None):
    """Rotate (Euler degrees, Roblox axes, XYZ) about the local origin, then move to centre."""
    m = Matrix.Translation(Vector(centre))
    if rot:
        m = m @ Euler([math.radians(a) for a in rot], "XYZ").to_matrix().to_4x4()
    obj.data.transform(m)
    obj.data.update()
    return obj


def _orient(obj, a, b):
    """A Y-axis primitive centred at the origin -> laid along a..b."""
    a, b = Vector(a), Vector(b)
    axis = b - a
    rot = axis.to_track_quat("Y", "Z").to_matrix().to_4x4()
    obj.data.transform(Matrix.Translation((a + b) / 2) @ rot)
    obj.data.update()
    return obj


def rbox(centre, size, bevel=0.1, segments=1, rot=None, taper=None):
    """A rounded box. taper=(sx, sz) scales the top face's x / z (a wedge, a pyramid roof)."""
    bm = bmesh.new()
    bmesh.ops.create_cube(bm, size=1.0)
    for v in bm.verts:
        sx, sz = taper if (taper and v.co.y > 0) else (1, 1)
        v.co = Vector((v.co.x * size[0] * sx, v.co.y * size[1], v.co.z * size[2] * sz))
    obj = _obj(bm, "box")
    _bevel(obj, min(bevel, min(size) * 0.49), segments)
    return _place(obj, centre, rot)


def cyl(centre, radius, height, segments=10, top=None, bevel=0.03, rot=None):
    """A Y-axis cylinder (or frustum: top = top radius scale); radius may be (rx, rz)."""
    rx, rz = radius if isinstance(radius, (tuple, list)) else (radius, radius)
    bm = bmesh.new()
    bmesh.ops.create_cone(bm, cap_ends=True, segments=segments, radius1=1.0, radius2=top or 1.0, depth=height)
    for v in bm.verts:  # create_cone is along Z: lay it along Y, then scale
        x, y, z = v.co.x, v.co.z, -v.co.y
        v.co = Vector((x * rx, y, z * rz))
    obj = _obj(bm, "cyl")
    _bevel(obj, min(bevel, height * 0.45), 1)
    return _place(obj, centre, rot)


def rod(a, b, radius, segments=8, top=None, bevel=0.0):
    """A cylinder (or frustum) from point a to point b."""
    length = (Vector(b) - Vector(a)).length
    return _orient(cyl((0, 0, 0), radius, length, segments, top, bevel), a, b)


def bar(a, b, w, h, bevel=0.03, up=(0, 1, 0)):
    """A rounded plank from a to b: width w (sideways), thickness h (along `up`)."""
    a, b = Vector(a), Vector(b)
    fwd = (b - a).normalized()
    side = Vector(up).cross(fwd).normalized()  # right-handed: side x upv = fwd
    upv = fwd.cross(side).normalized()
    obj = rbox((0, 0, 0), (w, h, (b - a).length), bevel)
    m = Matrix((side, upv, fwd)).transposed().to_4x4()  # columns: local x, y, z
    obj.data.transform(Matrix.Translation((a + b) / 2) @ m)
    obj.data.update()
    return obj


def ell(centre, radii, segments=10, rings=6, rot=None):
    bm = bmesh.new()
    bmesh.ops.create_uvsphere(bm, u_segments=segments, v_segments=rings, radius=1.0)
    for v in bm.verts:
        v.co = Vector((v.co.x * radii[0], v.co.y * radii[1], v.co.z * radii[2]))
    return _place(_obj(bm, "ell"), centre, rot)


def ring(centre, radius, thickness, segments=12, minor=5, rot=None):
    """A torus about the Y axis (a barrel band, a muzzle ring, a coil of rope)."""
    bm = bmesh.new()
    verts = []
    for i in range(segments):
        a = 2 * math.pi * i / segments
        row = []
        for j in range(minor):
            b = 2 * math.pi * j / minor
            r = radius + thickness * math.cos(b)
            row.append(bm.verts.new((r * math.cos(a), thickness * math.sin(b), r * math.sin(a))))
        verts.append(row)
    for i in range(segments):
        for j in range(minor):
            a, b = verts[i][j], verts[(i + 1) % segments][j]
            c, d = verts[(i + 1) % segments][(j + 1) % minor], verts[i][(j + 1) % minor]
            bm.faces.new((a, d, c, b))
    return _place(_obj(bm, "ring"), centre, rot)


def ring_along(a, b, radius, thickness, segments=12, minor=5):
    """A torus whose axis runs a -> b, centred at a (a band round a tube)."""
    obj = ring((0, 0, 0), radius, thickness, segments, minor)
    d = Vector(b) - Vector(a)
    rot = d.to_track_quat("Y", "Z").to_matrix().to_4x4()
    obj.data.transform(Matrix.Translation(Vector(a)) @ rot)
    obj.data.update()
    return obj


def sandbag(centre, length=0.62, yaw=0.0, h=0.24, w=0.34, segments=2):
    """A plump sandbag: a squashed rounded box, slightly pinched at the tied ends.
    (segments=1 for a ring of many bags: about half the triangles.)"""
    return rbox(centre, (length, h, w), bevel=0.1, segments=segments, rot=(0, yaw, 0), taper=(0.92, 0.85))


def pillow(centre, length=0.7, yaw=0.0, h=0.28, w=0.4, segments=8, rings=4):
    """A light sandbag for walls of many bags: a squashed ellipsoid (~50 triangles)."""
    bag = ell((0, 0, 0), (length / 2, h / 2, w / 2), segments, rings)
    return _place(bag, centre, (0, yaw, 0))


def crate(centre, size, yaw=0.0):
    """A framed crate: (core, frame) objects - a plank core and its edge battens (corner posts
    and top / bottom rims), for two paint groups."""
    sx, sy, sz = size
    core = rbox((0, 0, 0), (sx * 0.96, sy * 0.96, sz * 0.96), bevel=0.04)
    t = min(sx, sy, sz) * 0.09
    frame = [rbox((x * (sx - t) / 2, 0, z * (sz - t) / 2), (t, sy, t), bevel=0.015)
             for x in (-1, 1) for z in (-1, 1)]
    frame += [rbox((0, y * (sy - t) / 2, 0), (sx, t, sz), bevel=0.015) for y in (-1, 1)]
    frame += [rbox((0, 0, 0), (sx, t * 0.8, sz), bevel=0.015)]  # middle band
    out = []
    for o in [core] + frame:
        out.append(_place(o, centre, (0, yaw, 0)))
    return out[0], out[1:]


def along(p, q, t):
    return tuple(a + (b - a) * t for a, b in zip(p, q))


def plank_floor(centre, w, d, h=0.18, n=5, gap=0.04, along_x=True):
    """A floor of n planks (centre = the floor's top centre)."""
    cx, cy, cz = centre
    out = []
    span = d if along_x else w
    pw = (span - gap * (n - 1)) / n
    for i in range(n):
        o = -span / 2 + pw / 2 + i * (pw + gap)
        if along_x:
            out.append(rbox((cx, cy - h / 2, cz + o), (w, h, pw), bevel=0.03))
        else:
            out.append(rbox((cx + o, cy - h / 2, cz), (pw, h, d), bevel=0.03))
    return out


def flame(centre, r=0.5, h=1.3, yaw=0.0):
    """Three leaning teardrop tongues of fire (group glow)."""
    cx, cy, cz = centre
    out = []
    for i, (s, lean) in enumerate(((1.0, 0), (0.7, 1), (0.6, -1))):
        a = math.radians(yaw + i * 120)
        ox, oz = (0, 0) if i == 0 else (math.cos(a) * r * 0.5, math.sin(a) * r * 0.5)
        out.append(cyl((cx + ox, cy + h * s / 2, cz + oz), r * s, h * s, segments=8, top=0.05, bevel=0.0,
                       rot=(lean * 10, 0, lean * 8)))
    return out


def face(centre, w, h, yaw=0.0, t=0.03):
    """A flat sign face (SurfaceGui target): a thin box, Front = -Z before yaw."""
    return rbox(centre, (w, h, t), bevel=0.0, rot=(0, yaw, 0))


class Camp:
    """Collects primitives per piece; model() joins each set into one object (one MeshPart)."""

    def __init__(self, lp):
        self.lp = lp
        self.sets = {}
        self.groups = {}
        self.roles = {}

    def add(self, group, *objs, piece=None, role=None):
        name = piece or group
        self.sets.setdefault(name, []).extend(objs)
        self.groups[name] = group
        if role:
            self.roles[name] = role

    def model(self, batch, colors, cap, footprint, meta=None, budget="big"):
        """footprint = (x half, z half, height): the build fails if the art leaves it or is over cap tris."""
        lp, out = self.lp, []
        m = to_blender_matrix()
        for name, objs in sorted(self.sets.items()):
            piece = lp.join(name, objs)
            piece.data.transform(m)
            piece.data.update()
            lp.triangulate(piece)
            out.append(piece)
        total = sum(lp.tris(o) for o in out)
        assert total <= cap, f"{total} tris > prop cap {cap}"
        blo, bhi = lp.bounds(out)
        lo = (float(blo[0]), float(blo[2]), float(-bhi[1]))
        hi = (float(bhi[0]), float(bhi[2]), float(-blo[1]))
        hx, hz, hy = footprint
        e = 1e-3
        assert lo[0] >= -hx - e and hi[0] <= hx + e, f"x outside footprint: {lo[0]:.2f}..{hi[0]:.2f}"
        assert lo[2] >= -hz - e and hi[2] <= hz + e, f"z outside footprint: {lo[2]:.2f}..{hi[2]:.2f}"
        assert lo[1] >= -0.05 and hi[1] <= hy + e, f"y outside 0..{hy}: {lo[1]:.2f}..{hi[1]:.2f}"
        # preview-only ground (build.py renders `context`, never exports it)
        cx, cz = (lo[0] + hi[0]) / 2, (lo[2] + hi[2]) / 2
        rx, rz = (hi[0] - lo[0]) / 2 + 0.6, (hi[2] - lo[2]) / 2 + 0.6
        disc = cyl((cx, -0.04, cz), (rx, rz), 0.06, segments=40, bevel=0.0)
        disc.data.transform(m)
        disc.data.update()
        disc.color = (0.45, 0.42, 0.36, 1.0)
        # preview-only framing: two loose vertices (render nothing) a little outside the art
        d = max(hi[0] - lo[0], hi[1] - lo[1], hi[2] - lo[2]) * 0.1
        mesh = bpy.data.meshes.new("frame")
        mesh.from_pydata([(lo[0] - d, -hi[2] - d, lo[1] - d), (hi[0] + d, -lo[2] + d, hi[1] + d)], [], [])
        frame = bpy.data.objects.new("frame", mesh)
        bpy.context.scene.collection.objects.link(frame)
        return {
            "batch": batch,
            "budget": budget,
            "box": (lo, hi),
            "pieces": out,
            "groups": dict(self.groups),
            "roles": dict(self.roles),
            "colors": colors,
            "context": [disc, frame],
            "meta": dict(meta or {}, cap=cap, origin="anchor on the ground (y 0), front -Z"),
        }
