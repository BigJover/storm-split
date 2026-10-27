"""Shared helpers for the tower models (PLAN 11d T152-T154, DECISIONS #426/#433). Runs in Blender.

A tower model dresses today's invisible tower Body (TowerLook: 3 x 5 x 3 studs). Everything is
authored in ROBLOX axes (Y up, the tower's front faces -Z, its left is -X), in studs, measured
from the tower's BASE (the ground under the Body's centre, y = 0), like TowerLook's silhouette
blocks. `Kit.finish` joins one piece per paint group (plus role pieces), moves y down by the
Body's half height (the art origin = the Body's centre, ArtSlot's rule) and converts to Blender
axes. It returns the art's real bounds as the model's `box`, so build.py's fit-to-box is a
no-op (scale 1.00): the art is placed exactly where it was authored, and `finish` fails if any
vertex leaves the Body's footprint (x, z within +-1.5) or height (0..5).

One look per TowerLook model-swap stage (setStage): stage 0 = tiers 0-2 (key `SCOUT`),
stage 1 = a path at tier 3 (key `SCOUT_S1`, the crown sits on top), stage 2 = tier 5
(`SCOUT_S2`, the glow). Higher stages add gear; stage 2 adds brass trim.

Anchors (roles, recorded in manifest.json `pieces[*].role`; FBX can't carry attributes):
  muzzle  the firing point (a small ring/cap where shots leave; its centre = the point)
The crown needs no anchor: TowerLook puts it on `LookTop` = the art's highest point
(ArtSlot.top). The owner flag stands at the Body's back-right corner (x 1.2, z 1.2), so every
model keeps that corner low and clear.
"""

import math

import bmesh
import bpy
from mathutils import Euler, Matrix, Vector

HALF_X, HALF_Z, HEIGHT = 1.5, 1.5, 5.0
FLAG = (1.2, 1.2)  # TowerLook.addFlag's pole, Roblox x / z from the Body's centre

# Shared camp-gear palette (authored colours, #439). The tower's own colour is group `body`.
WOOD = (122, 88, 56)
DARK = (74, 54, 36)
CANVAS = (214, 200, 160)
SAND = (196, 174, 124)
ROPE = (176, 150, 100)
METAL = (78, 82, 86)
BRASS = (214, 168, 70)
LEAF = (88, 128, 60)
GLOW = (255, 196, 90)


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


def sandbag(centre, length=0.62, yaw=0.0, h=0.24, w=0.34):
    """A plump sandbag: a squashed rounded box, slightly pinched at the tied ends."""
    return rbox(centre, (length, h, w), bevel=0.1, segments=2, rot=(0, yaw, 0), taper=(0.92, 0.85))


def along(p, q, t):
    return tuple(a + (b - a) * t for a, b in zip(p, q))


class Kit:
    """Collects primitives per piece; finish() joins each set into one object."""

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

    def finish(self, target=2700, keep=200):
        lp, out = self.lp, []
        m = to_blender_matrix() @ Matrix.Translation((0, -HEIGHT / 2, 0))
        for name, objs in sorted(self.sets.items()):
            piece = lp.join(name, objs)
            piece.data.transform(m)
            piece.data.update()
            lp.triangulate(piece)
            out.append(piece)
        total = sum(lp.tris(o) for o in out)
        if total > target:  # (a last resort: keep models under target by design) decimate the big pieces evenly; small details stay crisp
            small = sum(lp.tris(o) for o in out if lp.tris(o) <= keep)
            ratio = (target - small) / (total - small)
            for o in out:
                n = lp.tris(o)
                if n > keep:
                    lp.decimate_to(o, max(keep, int(n * ratio)))
        blo, bhi = lp.bounds(out)
        # Blender (x, y, z) -> Roblox (x, z, -y)
        lo = (float(blo[0]), float(blo[2]), float(-bhi[1]))
        hi = (float(bhi[0]), float(bhi[2]), float(-blo[1]))
        eps = 1e-3
        assert lo[0] >= -HALF_X - eps and hi[0] <= HALF_X + eps, f"x outside the Body: {lo[0]:.3f}..{hi[0]:.3f}"
        assert lo[2] >= -HALF_Z - eps and hi[2] <= HALF_Z + eps, f"z outside the Body: {lo[2]:.3f}..{hi[2]:.3f}"
        assert lo[1] >= -HEIGHT / 2 - 0.02 and hi[1] <= HEIGHT / 2 + eps, f"y outside the Body: {lo[1]:.3f}..{hi[1]:.3f}"
        return out, (lo, hi)

    def model(self, batch, colors, tower, stage):
        pieces, box = self.finish()
        return {
            "batch": batch,
            "budget": "tower",
            "tower": tower,
            "stage": stage,
            "box": box,
            "pieces": pieces,
            "groups": dict(self.groups),
            "roles": dict(self.roles),
            "colors": colors,
        }
