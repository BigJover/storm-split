"""Shared bpy helpers for the Phase 11 art scripts (PLAN 11a T146, DECISIONS #421/#433).

Runs inside Blender only (tools/art/build.sh). Conventions:
  * 1 Blender unit = 1 stud. Models are built in Blender axes (Z up, the model faces +Y)
    and the FBX export maps them to Roblox axes (+Y up, the model faces -Z).
    Blender (x, y, z) -> Roblox (x, z, -y); `rbx()` converts a Roblox point to Blender.
  * The origin is the gameplay part's centre (a dino's Root); `fit_to_box` scales the
    finished pieces onto today's blocky bounds so hitboxes line up (#426).
  * One object per paint group (body / belly / accent / dark / eye) plus role pieces such as
    `head` (ArtRole head; paint group body). Each object becomes one MeshPart.
  * Smooth stylised (#433): skin-modifier skeletons -> subdivision -> decimate to a
    triangle target -> triangulate -> smooth shading + weighted normals.
"""

import hashlib

import bmesh
import bpy
import numpy as np
from mathutils import Vector

# Triangle budgets per class (#433). A build over budget fails.
BUDGETS = {
    "small": 800,
    "mid": 1500,
    "big": 2500,
    "boss": 4000,
    "gun": 1200,
    "tower": 3000,
    "hero": 6000,
}

GROUPS = ("body", "belly", "accent", "dark", "eye")


def rbx(x, y, z):
    """A point given in Roblox studs (Y up, -Z forward) as a Blender Vector."""
    return Vector((x, -z, y))


def reset_scene():
    bpy.ops.wm.read_factory_settings(use_empty=True)
    scene = bpy.context.scene
    scene.unit_settings.system = "METRIC"
    scene.unit_settings.scale_length = 1.0
    return scene


def _link(name, mesh):
    obj = bpy.data.objects.new(name, mesh)
    bpy.context.scene.collection.objects.link(obj)
    return obj


def _bake(obj):
    """Replace obj's mesh with its evaluated mesh (modifiers applied) and drop the modifiers."""
    depsgraph = bpy.context.evaluated_depsgraph_get()
    baked = bpy.data.meshes.new_from_object(obj.evaluated_get(depsgraph))
    old = obj.data
    obj.modifiers.clear()
    obj.data = baked
    bpy.data.meshes.remove(old)
    return obj


def tris(obj):
    return sum(len(p.vertices) - 2 for p in obj.data.polygons)


def skin(name, points, edges, radii, subdiv=2):
    """A smooth limb/torso from a skeleton: points (Blender coords), edges (index pairs),
    radii (one (rx, ry) or float per point). Returns the baked object."""
    mesh = bpy.data.meshes.new(name)
    mesh.from_pydata([tuple(p) for p in points], edges, [])
    obj = _link(name, mesh)
    obj.modifiers.new("skin", "SKIN")
    layer = mesh.skin_vertices[0].data
    for i, r in enumerate(radii):
        layer[i].radius = (r, r) if isinstance(r, (int, float)) else tuple(r)
    layer[0].use_root = True
    if subdiv:
        sub = obj.modifiers.new("sub", "SUBSURF")
        sub.levels = subdiv
        sub.render_levels = subdiv
    return _bake(obj)


def ellipsoid(name, centre, radii, segments=10, rings=6):
    """A UV sphere scaled to radii (Blender axes) at centre."""
    mesh = bpy.data.meshes.new(name)
    bm = bmesh.new()
    bmesh.ops.create_uvsphere(bm, u_segments=segments, v_segments=rings, radius=1.0)
    for v in bm.verts:
        v.co = Vector((v.co.x * radii[0], v.co.y * radii[1], v.co.z * radii[2])) + Vector(centre)
    bm.to_mesh(mesh)
    bm.free()
    return _link(name, mesh)


def cone(name, base, tip, radius, segments=6):
    """A small pointed cone (claws, teeth, spikes) from base to tip."""
    mesh = bpy.data.meshes.new(name)
    bm = bmesh.new()
    axis = Vector(tip) - Vector(base)
    bmesh.ops.create_cone(bm, cap_ends=True, segments=segments, radius1=radius, radius2=0.0, depth=axis.length)
    rot = axis.to_track_quat("Z", "Y").to_matrix().to_4x4()
    bmesh.ops.transform(bm, matrix=rot, verts=bm.verts)
    bmesh.ops.translate(bm, vec=(Vector(base) + Vector(tip)) / 2, verts=bm.verts)
    bm.to_mesh(mesh)
    bm.free()
    return _link(name, mesh)


def join(name, objs):
    """Merge objects into one (one MeshPart per paint group)."""
    bm = bmesh.new()
    for o in objs:
        bm.from_mesh(o.data)
    mesh = bpy.data.meshes.new(name)
    bm.to_mesh(mesh)
    bm.free()
    for o in objs:
        old = o.data
        bpy.data.objects.remove(o)
        bpy.data.meshes.remove(old)
    return _link(name, mesh)


def triangulate(obj):
    bm = bmesh.new()
    bm.from_mesh(obj.data)
    bmesh.ops.triangulate(bm, faces=bm.faces)
    bm.to_mesh(obj.data)
    bm.free()
    return obj


def decimate_to(obj, target):
    """Collapse-decimate obj to at most `target` triangles, then triangulate."""
    triangulate(obj)
    have = tris(obj)
    if have > target:
        mod = obj.modifiers.new("dec", "DECIMATE")
        mod.ratio = max(0.01, target / have)
        _bake(obj)
        triangulate(obj)
    return obj


def bounds(objs):
    """(min, max) over every vertex of objs, Blender axes."""
    pts = []
    for o in objs:
        co = np.empty(len(o.data.vertices) * 3)
        o.data.vertices.foreach_get("co", co)
        pts.append(co.reshape(-1, 3))
    allp = np.concatenate(pts)
    return allp.min(axis=0), allp.max(axis=0)


def fit_to_box(objs, lo, hi):
    """Scale and move every vertex so the pieces' joint bounds become [lo, hi] (Blender axes),
    per axis. Returns the per-axis scale used (a sanity check: far from 1 = a bad sketch)."""
    lo, hi = np.array(lo, float), np.array(hi, float)
    blo, bhi = bounds(objs)
    scale = (hi - lo) / (bhi - blo)
    for o in objs:
        co = np.empty(len(o.data.vertices) * 3)
        o.data.vertices.foreach_get("co", co)
        co = ((co.reshape(-1, 3) - blo) * scale + lo).ravel()
        o.data.vertices.foreach_set("co", co)
        o.data.update()
    return scale


def smooth(obj, weighted=True):
    """Smooth shading; weighted normals keep flat-ish faces reading cleanly (#433)."""
    obj.data.shade_smooth()
    if weighted:
        mod = obj.modifiers.new("wn", "WEIGHTED_NORMAL")
        mod.keep_sharp = True
        _bake(obj)
    return obj


def paint(obj, rgb):
    """Preview colour (Workbench object colour). Roblox recolours by paint group at runtime."""
    obj.color = (rgb[0] / 255, rgb[1] / 255, rgb[2] / 255, 1.0)


def geometry_hash(objs):
    """A hash of the exported geometry (names, rounded vertices, triangles). FBX files carry
    a timestamp, so manifest.json compares this instead of the file bytes."""
    h = hashlib.sha256()
    for o in sorted(objs, key=lambda o: o.name):
        h.update(o.name.encode())
        co = np.empty(len(o.data.vertices) * 3)
        o.data.vertices.foreach_get("co", co)
        h.update(np.round(co, 4).tobytes())
        idx = np.empty(len(o.data.loops), dtype=np.int32)
        o.data.loops.foreach_get("vertex_index", idx)
        h.update(idx.tobytes())
    return h.hexdigest()[:16]


def export_fbx(path, objs):
    """FBX for Roblox's importer: +Y up, -Z forward, transforms baked, triangulated,
    normals + smoothing groups written, no animation or leaf bones."""
    bpy.ops.object.select_all(action="DESELECT")
    for o in objs:
        o.select_set(True)
    bpy.context.view_layer.objects.active = objs[0]
    bpy.ops.export_scene.fbx(
        filepath=str(path),
        use_selection=True,
        object_types={"MESH"},
        axis_forward="-Z",
        axis_up="Y",
        apply_unit_scale=True,
        apply_scale_options="FBX_SCALE_NONE",
        bake_space_transform=True,
        use_mesh_modifiers=True,
        mesh_smooth_type="FACE",
        use_triangles=True,
        add_leaf_bones=False,
        bake_anim=False,
        use_custom_props=False,
        embed_textures=False,
    )
