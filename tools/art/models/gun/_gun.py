"""Shared helpers for the hand-held models (PLAN 11c T151, batch 11c2, DECISIONS #433). Runs in Blender.

Kinds `gun` (the 4 heroes' guns + their variant attachments) and `kit` (each hunter's melee and
grenade prop; models/kit/_prop.py loads this file, and srchash.py hashes it for both kinds).

Frame (the runtime's contract, see tools/art/README.md "Guns and kit"):
  * Authored in ROBLOX studs and axes about the **Tool Handle's origin = the grip point**: today's
    Handle (Server/Hero syncTool, 0.4 x 0.5 x 2) is held with the default Tool.Grip (identity), so
    the Handle's centre sits on the RightHand's RightGripAttachment. The art keeps that: the hand
    closes round (0, 0, 0), the barrel points **-Z** (the Handle's LookVector = forward when aimed),
    **+Y** is up, +X the gun's right side.
  * The firing point is piece `muzzle` (ArtRole `muzzle`): a small ring at the barrel's tip; its
    centre = where tracers leave (the runtime puts the `Muzzle` attachment there).
  * Grenades: origin = the thrown ball's centre (Server/Kit's 0.9-stud ball); no grip.
  * Variant attachments (`<GUN>_<VARIANT>` keys) are authored in the SAME frame as their gun and
    are purely additive: the runtime welds them to the Handle at identity, on top of the base gun.

`Gun.finish` joins one object per piece, converts to Blender axes and returns the real bounds as
the model's `box`, so build.py's fit-to-box is a no-op (scale 1.00). It fails if anything leaves
the model's envelope or the triangle cap (guns 1,200 with any one attachment, #433; kit 600).
"""

import math

import bmesh
import bpy
from mathutils import Euler, Matrix, Vector

GUN_CAP = 1200  # a gun with any one attachment (#433)

# Shared palette (authored colours, #439): expedition / hunting gear, matching the hunters.
WOOD = (132, 86, 50)  # walnut stock
WOOD_LIGHT = (168, 118, 72)  # birch / ash handles
STEEL = (64, 72, 86)  # blued steel
STEEL_LIGHT = (150, 156, 164)  # bright steel (blade edges)
BRASS = (214, 168, 70)
LEATHER = (92, 62, 40)
DARK = (44, 40, 38)  # rubber butt pads, cord
CLOTH = (226, 218, 196)  # bandage / canvas
GLASS = (150, 200, 210)
CORK = (176, 136, 90)

# Class colours = Server/Hero HERO_COLORS (group `accent`: the runtime may recolour it with a
# weapon skin / mastery gold, the rest keeps its authored colour).
ACCENT = {
    "PISTOL": (255, 90, 110),
    "RIFLE": (255, 220, 90),
    "SHOTGUN": (255, 140, 50),
    "MEDIC": (110, 230, 140),
}


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


def rbox(centre, size, bevel=0.03, segments=1, rot=None, taper=None):
    """A rounded box. taper=(sx, sy) scales the FRONT (-Z) face's x / y (a tapering stock)."""
    bm = bmesh.new()
    bmesh.ops.create_cube(bm, size=1.0)
    for v in bm.verts:
        sx, sy = taper if (taper and v.co.z < 0) else (1, 1)
        v.co = Vector((v.co.x * size[0] * sx, v.co.y * size[1] * sy, v.co.z * size[2]))
    obj = _obj(bm, "box")
    _bevel(obj, min(bevel, min(size) * 0.45), segments)
    return _place(obj, centre, rot)


def rod(a, b, radius, segments=8, top=None, bevel=0.0):
    """A cylinder (or frustum: top = the b end's radius scale) from point a to point b."""
    a, b = Vector(a), Vector(b)
    bm = bmesh.new()
    bmesh.ops.create_cone(bm, cap_ends=True, segments=segments, radius1=radius,
                          radius2=radius * (top if top is not None else 1.0), depth=(b - a).length)
    obj = _obj(bm, "rod")  # along +Z, centred
    _bevel(obj, min(bevel, radius * 0.4), 1)
    rot = (b - a).to_track_quat("Z", "Y").to_matrix().to_4x4()
    obj.data.transform(Matrix.Translation((a + b) / 2) @ rot)
    obj.data.update()
    return obj


def ell(centre, radii, segments=10, rings=6, rot=None):
    bm = bmesh.new()
    bmesh.ops.create_uvsphere(bm, u_segments=segments, v_segments=rings, radius=1.0)
    for v in bm.verts:
        v.co = Vector((v.co.x * radii[0], v.co.y * radii[1], v.co.z * radii[2]))
    return _place(_obj(bm, "ell"), centre, rot)


def ring(centre, radius, thickness, segments=10, minor=4, axis="z", rot=None):
    """A torus round an axis ('x', 'y' or 'z'): a barrel band, a trigger guard, a muzzle ring."""
    bm = bmesh.new()
    verts = []
    for i in range(segments):
        a = 2 * math.pi * i / segments
        row = []
        for j in range(minor):
            b = 2 * math.pi * j / minor
            r = radius + thickness * math.cos(b)
            p = (r * math.cos(a), r * math.sin(a), thickness * math.sin(b))  # about Z
            p = {"z": p, "x": (p[2], p[1], p[0]), "y": (p[0], p[2], p[1])}[axis]
            row.append(bm.verts.new(p))
        verts.append(row)
    for i in range(segments):
        for j in range(minor):
            a, b = verts[i][j], verts[(i + 1) % segments][j]
            c, d = verts[(i + 1) % segments][(j + 1) % minor], verts[i][(j + 1) % minor]
            bm.faces.new((a, b, c, d))
    bmesh.ops.recalc_face_normals(bm, faces=bm.faces)
    return _place(_obj(bm, "ring"), centre, rot)


def slab(profile, x0, x1, bevel=0.012, segments=1):
    """A flat plate: `profile` = (z, y) points (a convex-ish outline, any winding) extruded
    across x0..x1 - a blade, a stock's side profile, a lever."""
    bm = bmesh.new()
    lo = [bm.verts.new((x0, y, z)) for z, y in profile]
    hi = [bm.verts.new((x1, y, z)) for z, y in profile]
    n = len(profile)
    bm.faces.new(lo)
    bm.faces.new(list(reversed(hi)))
    for i in range(n):
        j = (i + 1) % n
        bm.faces.new((lo[i], lo[j], hi[j], hi[i]))
    bmesh.ops.recalc_face_normals(bm, faces=bm.faces)
    obj = _obj(bm, "slab")
    return _bevel(obj, min(bevel, abs(x1 - x0) * 0.45), segments)


class Gun:
    """Collects primitives per piece; finish() joins each set into one MeshPart object."""

    def __init__(self, lp, envelope, cap):
        self.lp = lp
        self.envelope = envelope  # ((x0, y0, z0), (x1, y1, z1)) Roblox studs about the grip
        self.cap = cap
        self.sets = {}
        self.groups = {}
        self.roles = {}
        self.context = []

    def add(self, group, *objs, piece=None, role=None):
        name = piece or group
        self.sets.setdefault(name, []).extend(objs)
        self.groups[name] = group
        if role:
            self.roles[name] = role

    def base(self, other):
        """Show `other` (the base gun, built into its own Gun) in this model's previews only:
        an attachment is drawn mounted on its gun, but only the attachment is exported."""
        base_tris = 0
        for name, objs in sorted(other.sets.items()):
            obj = self.lp.triangulate(self.lp.join(f"ctx_{name}", objs))
            base_tris += self.lp.tris(obj)
            self.context.append((obj, other.groups[name]))
        other.sets = {}
        self.cap = min(self.cap, GUN_CAP - base_tris)  # gun + this attachment <= 1,200 (#433)
        print(f"ART base gun {base_tris} tris: this attachment may use {self.cap}")

    def finish(self):
        lp, out = self.lp, []
        m = to_blender_matrix()
        for name, objs in sorted(self.sets.items()):
            piece = lp.join(name, objs)
            piece.data.transform(m)
            piece.data.update()
            lp.triangulate(piece)
            out.append(piece)
        total = sum(lp.tris(o) for o in out)
        assert total <= self.cap, f"{total} tris > this model's cap {self.cap}"
        blo, bhi = lp.bounds(out)
        lo = (float(blo[0]), float(blo[2]), float(-bhi[1]))
        hi = (float(bhi[0]), float(bhi[2]), float(-blo[1]))
        (ex0, ey0, ez0), (ex1, ey1, ez1) = self.envelope
        eps = 1e-3
        for axis, l, h, a, b in (("x", lo[0], hi[0], ex0, ex1), ("y", lo[1], hi[1], ey0, ey1), ("z", lo[2], hi[2], ez0, ez1)):
            assert l >= a - eps and h <= b + eps, f"{axis} outside the envelope: {l:.3f}..{h:.3f} not in {a}..{b}"
        return out, (lo, hi)

    def model(self, batch, budget, colors, meta=None):
        pieces, box = self.finish()
        m = to_blender_matrix()
        ctx = []
        for o, group in self.context:  # preview-only context (the base gun under an attachment)
            o.data.transform(m)
            o.data.update()
            self.lp.paint(o, colors.get(group, (200, 200, 200)))
            ctx.append(o)
        return {
            "batch": batch,
            "budget": budget,
            "box": box,
            "pieces": pieces,
            "groups": dict(self.groups),
            "roles": dict(self.roles),
            "colors": colors,
            "context": ctx,
            "meta": meta or {},
        }


def muzzle_ring(centre, radius, thickness=0.02):
    """The firing point: a ring round the bore at the barrel's tip (its centre = the point)."""
    return ring(centre, radius, thickness, segments=8, minor=4, axis="z")


def bar(a, b, w, h, bevel=0.01, up=(0, 1, 0)):
    """A rounded strap / plank from a to b: width w (sideways), thickness h (along `up`)."""
    a, b = Vector(a), Vector(b)
    fwd = (b - a).normalized()
    side = Vector(up).cross(fwd).normalized()
    upv = fwd.cross(side).normalized()
    obj = rbox((0, 0, 0), (w, h, (b - a).length), bevel)
    m = Matrix((side, upv, fwd)).transposed().to_4x4()
    obj.data.transform(Matrix.Translation((a + b) / 2) @ m)
    obj.data.update()
    return obj


def strap(points, w, h, up=(1, 0, 0)):
    """A strap (a sling, a belt) along a polyline: one bar per segment, joints overlapping."""
    out = []
    for p, q in zip(points, points[1:]):
        d = Vector(q) - Vector(p)
        ext = d.normalized() * (h * 0.6)  # overlap so the joints close
        out.append(bar(Vector(p) - ext, Vector(q) + ext, w, h, bevel=0, up=up))
    return out
