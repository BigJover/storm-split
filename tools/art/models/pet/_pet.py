"""Shared helpers for the pet models (PLAN 11f T156, batch 11f). Runs in Blender.

A pet is authored in ROBLOX axes (Y up, the pet faces -Z, its left is -X), in studs, about the
GROUND point under the pet's centre (y = 0 = where its feet stand). `Pet.finish` joins one
piece per paint group, decimates each to its share of the budget (<= 800 tris, #433 `small`),
converts to Blender axes and returns the real bounds as `box`, so build.py's fit-to-box is a
no-op (scale 1.00).

Paint groups (the runtime contract, README "Pets"):
  body    the species colour (Server/Pets LOOKS body)       SmoothPlastic, authored
  belly   tummy / snout / wing membrane, a lighter tone      SmoothPlastic, authored
  eye     big dark eyes                                       authored
  shine   the white highlight in each eye                     authored
  leaf    the Round 21 leaf tag on the bandana                authored (always green)
  accent  the bandana: = the RARITY colour (Pets RARITY_COLOURS) at every rarity
  glow    the species' markings (crest, back spots, frill rim):
          Common / Uncommon = the authored colour (a darker body tone, SmoothPlastic)
          Rare / Epic       = the rarity colour, SmoothPlastic
          Legendary / Mythic = the rarity colour, Neon
Some species add a fixed group (`gold`: the Shiny Snatcher's coin).
"""

import math

import bmesh
import bpy
from mathutils import Euler, Matrix, Vector

CAP = 800  # #433 small; build.py checks the budget, finish() checks it first with names

RARITY = {  # Server/Pets RARITY_COLOURS (DINO_REVIEW Round 21) - preview-only recolours
    "COMMON": (170, 170, 170),
    "UNCOMMON": (90, 200, 100),
    "RARE": (80, 150, 255),
    "EPIC": (180, 100, 240),
    "LEGENDARY": (250, 200, 60),
    "MYTHIC": (240, 70, 70),
}
LEAF = (60, 150, 70)  # Server/Pets LEAF
EYE = (30, 24, 28)
SHINE = (250, 250, 250)

VIEWS = ["", "_rare", "_legendary", "_mythic"]  # the contact-sheet row: Common, Rare, Legendary, Mythic


def mix(a, b, t):
    return tuple(round(x + (y - x) * t) for x, y in zip(a, b))


def neon(c):
    """Preview stand-in for Neon (Workbench has no emission): lift toward white."""
    return mix(c, (255, 255, 255), 0.15)


def variants():
    """Preview-only recolours (build.py renders `<key>_<name>.png`): accent = rarity colour;
    glow plain until Rare, rarity colour at Rare, Neon (lifted) at Legendary / Mythic."""
    return {
        "rare": {"accent": RARITY["RARE"], "glow": RARITY["RARE"]},
        "legendary": {"accent": RARITY["LEGENDARY"], "glow": neon(RARITY["LEGENDARY"])},
        "mythic": {"accent": RARITY["MYTHIC"], "glow": neon(RARITY["MYTHIC"])},
    }


def to_blender_matrix():
    """Roblox (x, y, z) -> Blender (x, -z, y), a proper rotation (normals stay outward)."""
    return Matrix(((1, 0, 0, 0), (0, 0, -1, 0), (0, 1, 0, 0), (0, 0, 0, 1)))


_n = [0]


def _obj(bm, tag="p"):
    _n[0] += 1
    mesh = bpy.data.meshes.new(f"_{tag}{_n[0]}")
    bm.to_mesh(mesh)
    bm.free()
    obj = bpy.data.objects.new(mesh.name, mesh)
    bpy.context.scene.collection.objects.link(obj)
    return obj


def _rot(rot):
    return Euler(tuple(math.radians(a) for a in rot), "XYZ").to_matrix().to_4x4() if rot else Matrix()


def ell(centre, radii, segments=12, rings=8, rot=None):
    """Ellipsoid (Roblox axes), radii (x, y, z), rotated by Euler degrees `rot` about its centre."""
    bm = bmesh.new()
    bmesh.ops.create_uvsphere(bm, u_segments=segments, v_segments=rings, radius=1.0)
    # bmesh's sphere has its poles on z; put them on Roblox y (up) so the rings run round the body
    for v in bm.verts:
        x, y, z = v.co
        v.co = Vector((x * radii[0], z * radii[1], -y * radii[2]))  # a rotation, not a mirror
    obj = _obj(bm)
    obj.data.transform(Matrix.Translation(Vector(centre)) @ _rot(rot))
    return obj


def egg(centre, radius, height, segments=14, rings=10, point=0.22, rot=None):
    """An egg (blunt bottom, narrower top), centre = its middle, height along local y."""
    obj = ell((0, 0, 0), (radius, height / 2, radius), segments, rings)
    for v in obj.data.vertices:
        t = v.co.y / (height / 2)  # -1 bottom .. 1 top
        s = 1 - point * max(t, 0) ** 1.5 + 0.06 * (1 - t * t)
        v.co.x *= s
        v.co.z *= s
    obj.data.transform(Matrix.Translation(Vector(centre)) @ _rot(rot))
    return obj


def tube(points, radii, subdiv=1):
    """A smooth tapered limb through points (Roblox axes), one radius per point."""
    mesh = bpy.data.meshes.new("tube")
    mesh.from_pydata([tuple(p) for p in points], [(i, i + 1) for i in range(len(points) - 1)], [])
    _n[0] += 1
    obj = bpy.data.objects.new(f"_t{_n[0]}", mesh)
    bpy.context.scene.collection.objects.link(obj)
    obj.modifiers.new("skin", "SKIN")
    layer = mesh.skin_vertices[0].data
    for i, r in enumerate(radii):
        layer[i].radius = (r, r)
    layer[0].use_root = True
    if subdiv:
        sub = obj.modifiers.new("sub", "SUBSURF")
        sub.levels = subdiv
    depsgraph = bpy.context.evaluated_depsgraph_get()
    baked = bpy.data.meshes.new_from_object(obj.evaluated_get(depsgraph))
    old = obj.data
    obj.modifiers.clear()
    obj.data = baked
    bpy.data.meshes.remove(old)
    return obj


def ring(centre, rx, rz, thick, segments=14, minor=5, rot=None):
    """An elliptical torus lying flat (major radii rx / rz in x / z), tube radius thick."""
    bm = bmesh.new()
    grid = []
    for i in range(segments):
        a = 2 * math.pi * i / segments
        ca, sa = math.cos(a), math.sin(a)
        row = []
        for j in range(minor):
            b = 2 * math.pi * j / minor
            row.append(bm.verts.new((rx * ca + thick * math.cos(b) * ca, thick * math.sin(b),
                                     rz * sa + thick * math.cos(b) * sa)))
        grid.append(row)
    for i in range(segments):
        for j in range(minor):
            a, b = grid[i][j], grid[i][(j + 1) % minor]
            c, d = grid[(i + 1) % segments][(j + 1) % minor], grid[(i + 1) % segments][j]
            bm.faces.new((a, b, c, d))
    bmesh.ops.recalc_face_normals(bm, faces=bm.faces)
    obj = _obj(bm, "r")
    obj.data.transform(Matrix.Translation(Vector(centre)) @ _rot(rot))
    return obj


def cone(base, tip, radius, segments=6):
    bm = bmesh.new()
    axis = Vector(tip) - Vector(base)
    bmesh.ops.create_cone(bm, cap_ends=True, segments=segments, radius1=radius, radius2=0.0, depth=axis.length)
    bmesh.ops.transform(bm, matrix=axis.to_track_quat("Z", "Y").to_matrix().to_4x4(), verts=bm.verts)
    bmesh.ops.translate(bm, vec=(Vector(base) + Vector(tip)) / 2, verts=bm.verts)
    return _obj(bm, "c")


def patch(centre, normal, radius, thick, segments=8, rings=4, squash=1.0):
    """A flat spot lying on a surface: an ellipsoid flattened along `normal`."""
    obj = ell((0, 0, 0), (radius, thick, radius * squash), segments, rings)
    q = Vector((0, 1, 0)).rotation_difference(Vector(normal).normalized())
    obj.data.transform(Matrix.Translation(Vector(centre)) @ q.to_matrix().to_4x4())
    return obj


def eyes(m, x, y, z, r, toe_in=18):
    """Big glossy baby eyes on both sides of the head + a white highlight in each."""
    for s in (-1, 1):
        m.add("eye", ell((s * x, y, z), (r * 0.7, r, r), 10, 6, rot=(0, -s * toe_in, 0)))
        m.add("shine", ell((s * (x + r * 0.42), y + r * 0.42, z - r * 0.5), (r * 0.3, r * 0.34, r * 0.3), 6, 4))


def bandana(m, y, z, rx, rz, thick=0.07, tilt=-12, flap=(0.22, 0.18), leaf_z=None):
    """The rarity bandana: a ring round the neck + a flap in front, with the green leaf tag."""
    m.add("accent", ring((0, y, z), rx, rz, thick, 14, 4, rot=(tilt, 0, 0)))
    fz = z - rz - thick * 0.6
    fy = y - flap[1] * 0.55 + math.sin(math.radians(-tilt)) * rz
    m.add("accent", ell((0, fy, fz), (flap[0], flap[1], 0.06), 10, 5, rot=(tilt * 0.6, 0, 0)))
    m.add("leaf", ell((0, fy - flap[1] * 0.25, fz - 0.06 if leaf_z is None else leaf_z),
                      (0.075, 0.1, 0.035), 6, 4, rot=(0, 0, 25)))


class Pet:
    def __init__(self, lp):
        self.lp = lp
        self.parts = {}

    def add(self, group, obj):
        self.parts.setdefault(group, []).append(obj)
        return obj

    def finish(self, targets, key):
        """Join per group (targets = {group: max tris}), convert to Blender, check <= CAP.
        Returns (pieces, box) - box in Roblox axes, the art's real bounds."""
        pieces = []
        for group, objs in self.parts.items():
            obj = self.lp.join(group, objs)
            self.lp.decimate_to(obj, targets.get(group, 10_000))
            obj.data.transform(to_blender_matrix())
            pieces.append(obj)
        total = sum(self.lp.tris(o) for o in pieces)
        print(f"ART {key} pet tris {total} " + " ".join(f"{o.name}={self.lp.tris(o)}" for o in pieces))
        if total > CAP:
            raise SystemExit(f"ART FAIL {key}: {total} tris > {CAP}")
        blo, bhi = self.lp.bounds(pieces)
        lo = (float(blo[0]), float(blo[2]), float(-bhi[1]))
        hi = (float(bhi[0]), float(bhi[2]), float(-blo[1]))
        print(f"ART {key} box {tuple(round(v, 2) for v in lo)} .. {tuple(round(v, 2) for v in hi)}")
        return pieces, (lo, hi)


def ground(lp, radius=1.5):
    """Preview only: a dirt disc at y 0, so floating feet show."""
    obj = lp.ellipsoid("ground", (0, 0, -0.02), (radius, radius, 0.02), 32, 4)
    obj.color = (0.45, 0.42, 0.36, 1.0)
    return obj


def model(m, lp, key, targets, colors, display, species, ground_r=1.5, extra_meta=None):
    pieces, box = m.finish(targets, key)
    meta = {"pet": key, "display": display, "species": species, "origin": "ground",
            "views": VIEWS, "rarityGroups": {"accent": "rarity colour", "glow": "markings: plain < Rare, rarity colour, Neon >= Legendary"}}
    meta.update(extra_meta or {})
    return {
        "batch": "11f",
        "budget": "small",
        "box": box,
        "pieces": pieces,
        "colors": colors,
        "context": [ground(lp, ground_r)],
        "variants": variants(),
        "meta": meta,
    }
