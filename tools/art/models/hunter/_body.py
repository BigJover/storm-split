"""Shared helpers for the hunter hero bodies (PLAN 11c T150, DECISIONS #434). Runs in Blender.

A hero body is a rigid R15 character: every piece belongs to one of the 15 R15 parts and is
named `<R15Part>__<group>` (e.g. `Head__skin`, `UpperTorso__accent`). Each piece becomes one
MeshPart; the runtime welds every `<Part>__*` piece to that R15 part, so default R15
animations, Tools and the hitbox stay the character's own (#434: the hit parts keep the
default R15 sizes; the art only dresses them).

Everything here is authored in ROBLOX axes (Y up, the character faces -Z, its left is -X),
in studs, about the HumanoidRootPart's centre (ground = y -3.0), and `Body.finish` turns the
joined pieces into Blender axes at the end. No fit-to-box: the R15 rest layout below is the
frame, so a piece's offset from its part's centre is exact.

R15 rest layout = the default R15 block rig at scale 1 (5.2 studs: legs 2, LowerTorso 0.4,
UpperTorso 1.6, Head 1.2), built from the rig attachment offsets. It is our best reading of
the default rig, not yet checked in Studio: the T150 runtime task compares it with a live
character and, if a joint differs, fixes it here only (every body follows).
"""

import math

import bmesh
import bpy
from mathutils import Euler, Matrix, Vector

PARTS = (
    "Head", "UpperTorso", "LowerTorso",
    "LeftUpperArm", "LeftLowerArm", "LeftHand",
    "RightUpperArm", "RightLowerArm", "RightHand",
    "LeftUpperLeg", "LeftLowerLeg", "LeftFoot",
    "RightUpperLeg", "RightLowerLeg", "RightFoot",
)

GROUND = -3.0

# part -> (centre, size), Roblox studs about the HumanoidRootPart's centre, rest pose
R15 = {
    "Head": ((0, 1.5, 0), (1.2, 1.2, 1.2)),
    "UpperTorso": ((0, 0.2, 0), (2, 1.6, 1)),
    "LowerTorso": ((0, -0.8, 0), (2, 0.4, 1)),
}
for _s, _side in ((-1, "Left"), (1, "Right")):
    R15[f"{_side}UpperArm"] = ((1.5 * _s, 0.369, 0), (1, 1.169, 1))
    R15[f"{_side}LowerArm"] = ((1.5 * _s, -0.157, 0), (1, 1.052, 1))
    R15[f"{_side}Hand"] = ((1.5 * _s, -0.783, 0), (1, 0.3, 1))
    R15[f"{_side}UpperLeg"] = ((0.5 * _s, -1.421, 0), (1, 1.217, 1))
    R15[f"{_side}LowerLeg"] = ((0.5 * _s, -2.215, 0), (1, 1.193, 1))
    R15[f"{_side}Foot"] = ((0.5 * _s, -2.85, 0), (1, 0.3, 1))

# joint pivots (Roblox studs): where the Motor6Ds bend in the rest pose
JOINTS = {"Neck": (0, 1.0, 0), "Waist": (0, -0.6, 0)}
for _s, _side in ((-1, "Left"), (1, "Right")):
    JOINTS[f"{_side}Shoulder"] = (1.0 * _s, 0.763, 0)
    JOINTS[f"{_side}Elbow"] = (1.5 * _s, 0.035, 0)
    JOINTS[f"{_side}Wrist"] = (1.5 * _s, -0.658, 0)
    JOINTS[f"{_side}Hip"] = (0.5 * _s, -1.0, 0)
    JOINTS[f"{_side}Knee"] = (0.5 * _s, -1.821, 0)
    JOINTS[f"{_side}Ankle"] = (0.5 * _s, -2.762, 0)

SIDES = ((-1, "Left"), (1, "Right"))


def to_blender_matrix():
    """Roblox (x, y, z) -> Blender (x, -z, y), a proper rotation (normals stay outward)."""
    return Matrix(((1, 0, 0, 0), (0, 0, -1, 0), (0, 1, 0, 0), (0, 0, 0, 1)))


# ---- primitives (Roblox axes) --------------------------------------------------------------

_n = [0]


def _name(tag):
    _n[0] += 1
    return f"_{tag}{_n[0]}"


def _obj(bm, tag):
    mesh = bpy.data.meshes.new(_name(tag))
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
    if width > 0:
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


def rbox(centre, size, bevel=0.15, segments=2, rot=None, taper=None):
    """A rounded box. taper=(sx, sz) scales the top face's x / z (a wedge, chest, boot)."""
    bm = bmesh.new()
    bmesh.ops.create_cube(bm, size=1.0)
    for v in bm.verts:
        sx, sz = taper if (taper and v.co.y > 0) else (1, 1)
        v.co = Vector((v.co.x * size[0] * sx, v.co.y * size[1], v.co.z * size[2] * sz))
    obj = _obj(bm, "box")
    _bevel(obj, min(bevel, min(size) * 0.49), segments)
    return _place(obj, centre, rot)


def cyl(centre, radius, height, segments=12, top=None, bevel=0.04, rot=None):
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


def ell(centre, radii, segments=12, rings=8, rot=None):
    bm = bmesh.new()
    bmesh.ops.create_uvsphere(bm, u_segments=segments, v_segments=rings, radius=1.0)
    for v in bm.verts:
        v.co = Vector((v.co.x * radii[0], v.co.y * radii[1], v.co.z * radii[2]))
    return _place(_obj(bm, "ell"), centre, rot)


def capsule(lp, a, b, ra, rb=None, subdiv=2):
    """A smooth limb: hemispheres of radius ra at a and rb at b joined by a tapered tube. The
    rounded ends read as ball joints when the rig bends. (subdiv: 2 = smooth, 1 = lighter.)"""
    rb = ra if rb is None else rb
    a, b = Vector(a), Vector(b)
    axis = b - a
    segments, rings = (12, 7) if subdiv >= 2 else (8, 5)  # odd rings: no equator ring
    bm = bmesh.new()
    bmesh.ops.create_uvsphere(bm, u_segments=segments, v_segments=rings, radius=1.0)
    half = axis.length / 2
    for v in bm.verts:
        if v.co.z > 0:
            v.co = Vector((v.co.x * rb, v.co.y * rb, v.co.z * rb + half))
        else:
            v.co = Vector((v.co.x * ra, v.co.y * ra, v.co.z * ra - half))
    rot = axis.to_track_quat("Z", "Y").to_matrix().to_4x4()
    bmesh.ops.transform(bm, matrix=Matrix.Translation((a + b) / 2) @ rot, verts=bm.verts)
    return _obj(bm, "cap")


def cone(lp, base, tip, radius, segments=6):
    return lp.cone(_name("cone"), Vector(base), Vector(tip), radius, segments)


def mirror_x(p):
    return (-p[0], p[1], p[2])


# ---- the body ------------------------------------------------------------------------------


class Body:
    """Collects primitives per (R15 part, paint group); finish() joins each set into one piece
    `<Part>__<group>` and converts it to Blender axes."""

    def __init__(self, lp):
        self.lp = lp
        self.sets = {}

    def add(self, part, group, *objs):
        assert part in R15, part
        self.sets.setdefault((part, group), []).extend(objs)

    def finish(self, target=5300, keep=260):
        """Join + convert. If the body is over `target` triangles (under the 6,000 hero budget,
        #433), collapse-decimate every piece above `keep` triangles by the same ratio so small
        details (eyes, buckles) stay crisp and the big smooth shapes give up the polygons."""
        lp, out = self.lp, []
        to_b = to_blender_matrix()
        for (part, group), objs in sorted(self.sets.items()):
            piece = lp.join(f"{part}__{group}", objs)
            piece.data.transform(to_b)
            piece.data.update()
            lp.triangulate(piece)
            out.append(piece)
        missing = [p for p in PARTS if not any(k[0] == p for k in self.sets)]
        assert not missing, f"R15 parts without a piece: {missing}"
        total = sum(lp.tris(o) for o in out)
        if total > target:
            small = sum(lp.tris(o) for o in out if lp.tris(o) <= keep)
            big = total - small
            ratio = (target - small) / big
            for o in out:
                n = lp.tris(o)
                if n > keep:
                    lp.decimate_to(o, max(keep, int(n * ratio)))
        return out


def base(body, lp, s):
    """The shared figure every class dresses. s: style dict -
      arm (upper radius), fore (lower radius), leg, shin, torso (w, h, d), taper,
      sleeve: 'long' | 'short' | 'rolled' | 'none'   (what covers the arms)
      hands: paint group of the hands ('skin' or a glove group)
      boot: y where the boot starts on the shin (lower = shorter boots)
      shorts: True = bare knees (skin below the shorts, socks group 'sock' on the shin)
      armx: the arm art's x (default 1.36, inside the R15 arm centre 1.5 so it meets the torso)
    """
    lp_ = lp
    # head: a rounded cartoon block, neck, ears, nose, face
    body.add("Head", "skin",
             rbox((0, 1.56, 0), (1.08, 1.12, 1.02), bevel=0.4, segments=3),
             capsule(lp_, (0, 0.92, 0.03), (0, 1.12, 0.03), 0.24, subdiv=1),
             ell((0, 1.47, -0.53), (0.085, 0.085, 0.07), 8, 6),
             *[ell((0.55 * k, 1.52, 0.03), (0.07, 0.13, 0.1), 8, 6) for k in (-1, 1)])
    body.add("Head", "eye",
             *[ell((0.21 * k, 1.61, -0.49), (0.085, 0.12, 0.045), 10, 6) for k in (-1, 1)],
             ell((0, 1.29, -0.505), (0.13, 0.035, 0.03), 8, 4))  # small smile line
    brow = s.get("brow", 0.06)
    body.add("Head", "hair", *[
        rbox((0.21 * k, 1.8, -0.5), (0.26, brow, 0.06), bevel=0.025, segments=2, rot=(0, 0, -9 * k))
        for k in (-1, 1)])

    # torso: chest block (wider at the shoulders), hips
    w, h, d = s.get("torso", (1.9, 1.5, 0.95))
    body.add("UpperTorso", "shirt", rbox((0, 0.24, 0), (w * 0.9, h, d), bevel=0.32, taper=(1 / 0.9 * s.get("taper", 1.0), 1.0)))
    body.add("LowerTorso", "pants", rbox((0, -0.79, 0), (w * 0.92, 0.48, d * 0.94), bevel=0.2))
    body.add("LowerTorso", "dark", rbox((0, -0.63, 0), (w * 0.95, 0.19, d * 0.99), bevel=0.08))  # belt

    sleeve = s.get("sleeve", "long")
    for k, side in SIDES:
        # the arm art sits a little inside the R15 arm's centre (x 1.5) so it meets the
        # shoulder; it still turns about the R15 shoulder joint
        x = s.get("armx", 1.36) * k
        ua, la = s.get("arm", 0.4), s.get("fore", 0.35)
        # upper arm: shoulder ball to elbow
        if sleeve in ("none", "short"):
            body.add(f"{side}UpperArm", "skin", capsule(lp_, (x, 0.64, 0), (x, 0.06, 0), ua, ua * 0.92))
        else:
            body.add(f"{side}UpperArm", "shirt", capsule(lp_, (x, 0.64, 0), (x, 0.06, 0), ua, ua * 0.92))
        # forearm
        fore_group = "shirt" if sleeve == "long" else "skin"
        body.add(f"{side}LowerArm", fore_group, capsule(lp_, (x, 0.02, 0), (x, -0.6, 0), la, la * 0.88))
        if sleeve == "rolled":  # a rolled cuff just below the elbow
            body.add(f"{side}LowerArm", "shirt", cyl((x, -0.06, 0), la * 1.12, 0.17, 14, bevel=0.06))
        if sleeve == "short":  # a sleeve over the top half of the upper arm
            body.add(f"{side}UpperArm", "shirt", capsule(lp_, (x, 0.64, 0), (x, 0.36, 0), ua * 1.07, ua * 1.05))
        # hand: a mitten with a thumb, slightly forward
        hand = s.get("hands", "skin")
        hs = s.get("hand", 1.0)
        body.add(f"{side}Hand", hand,
                 rbox((x, -0.8, -0.02), (0.46 * hs, 0.44 * hs, 0.5 * hs), bevel=0.2),
                 ell((x - 0.2 * k * hs, -0.74, -0.2), (0.09, 0.15, 0.09), 8, 6, rot=(0, 0, 20 * k)))

        # legs
        lx = 0.5 * k
        ul, ll = s.get("leg", 0.42), s.get("shin", 0.37)
        if s.get("shorts"):
            body.add(f"{side}UpperLeg", "pants", capsule(lp_, (lx, -0.95, 0), (lx, -1.36, 0), ul * 1.06))
            body.add(f"{side}UpperLeg", "skin", capsule(lp_, (lx, -1.3, 0), (lx, -1.86, 0), ul * 0.86, ll * 0.92))
            body.add(f"{side}LowerLeg", "sock", capsule(lp_, (lx, -2.04, 0), (lx, -2.45, 0), ll * 1.02, ll * 0.92))
        else:
            body.add(f"{side}UpperLeg", "pants", capsule(lp_, (lx, -0.95, 0), (lx, -1.8, 0), ul, ul * 0.94))
            body.add(f"{side}LowerLeg", "pants", capsule(lp_, (lx, -1.82, 0), (lx, -2.5, 0), ll, ll * 0.92))
        boot = s.get("boot", -2.1)
        br = s.get("bootr", 0.41)
        body.add(f"{side}LowerLeg", "dark", capsule(lp_, (lx, boot, 0), (lx, -2.97 + br * 0.98, 0.02), br, br * 0.98, subdiv=2),
                 cyl((lx, boot + 0.02, 0), br * 1.07, 0.12, 14, bevel=0.04))  # boot cuff
        fs = s.get("foot", 1.0)
        body.add(f"{side}Foot", "dark", rbox((lx, -2.82, -0.14), (0.8 * fs, 0.36, 1.12 * fs), bevel=0.16, taper=(0.92, 0.85)))
