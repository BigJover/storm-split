"""Extra bpy helpers for the winged / big / boss dinos (LLAMA, ZEP, BARGE), kept out of the shared
lowpoly.py. Load from a species script with:

    H = _helpers_b()   # see LLAMA.py

  * sheet   - a thin smooth membrane from a grid of points (wings), solidified
  * blade   - a flat outline (crest, frill) given thickness and rounded by subdivision
  * on_surface - points projected onto a mesh by rays toward an axis (lava cracks, spots)
"""

import bmesh
import bpy
from mathutils import Vector
from mathutils.bvhtree import BVHTree


def _solid(lp, obj, thickness, subdiv):
    sol = obj.modifiers.new("sol", "SOLIDIFY")
    sol.thickness = thickness
    sol.offset = 0.0
    if subdiv:
        sub = obj.modifiers.new("sub", "SUBSURF")
        sub.levels = subdiv
        sub.render_levels = subdiv
    return lp._bake(obj)


def sheet(lp, name, rows, thickness, subdiv=0):
    """rows: list (span) of lists (chord) of Blender points, all rows the same length."""
    nu, nv = len(rows), len(rows[0])
    verts = [tuple(p) for row in rows for p in row]
    faces = [(i * nv + j, i * nv + j + 1, (i + 1) * nv + j + 1, (i + 1) * nv + j)
             for i in range(nu - 1) for j in range(nv - 1)]
    mesh = bpy.data.meshes.new(name)
    mesh.from_pydata(verts, [], faces)
    obj = lp._link(name, mesh)
    return _solid(lp, obj, thickness, subdiv)


def blade(lp, name, outline, thickness, subdiv=1):
    """A closed outline (Blender points, roughly planar) -> a rounded slab."""
    mesh = bpy.data.meshes.new(name)
    mesh.from_pydata([tuple(p) for p in outline], [], [tuple(range(len(outline)))])
    obj = lp._link(name, mesh)
    bm = bmesh.new()
    bm.from_mesh(obj.data)
    bmesh.ops.triangulate(bm, faces=bm.faces, quad_method="BEAUTY", ngon_method="BEAUTY")
    bm.to_mesh(obj.data)
    bm.free()
    return _solid(lp, obj, thickness, subdiv)


def on_surface(objs, rays, lift=0.0):
    """rays: [(origin, target)] Blender points; each ray is cast from origin toward target and
    the nearest hit on any of objs is returned (lifted along its normal). Misses are skipped."""
    trees = []
    for o in objs:
        bm = bmesh.new()
        bm.from_mesh(o.data)
        trees.append(BVHTree.FromBMesh(bm))
        bm.free()
    out = []
    for origin, target in rays:
        origin, target = Vector(origin), Vector(target)
        d = (target - origin).normalized()
        best = None
        for t in trees:
            loc, nrm, _, dist = t.ray_cast(origin, d)
            if loc is not None and (best is None or dist < best[2]):
                best = (loc, nrm, dist)
        if best:
            out.append(best[0] + best[1] * lift)
    return out
