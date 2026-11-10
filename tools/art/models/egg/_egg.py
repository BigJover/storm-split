"""Shared helpers + designs for the eggs and the incubator (PLAN 11f T156, batch 11f). Runs in Blender.

Authored in ROBLOX axes (Y up, front -Z), studs. Origin = the point the model RESTS on
(y = 0 = the ground / the nest), centred in x and z. `finish` joins one piece per paint group,
decimates each to its share, converts to Blender axes and returns the real bounds as `box`
(build.py's fit-to-box is then a no-op, scale 1.00).

Eggs (<= 400 tris each, checked here; build.py's class is `small`, 800):
  MUD       Mud Egg       shell + a `mud` rim and clods round the base + a `grass` blade stuck on
  SPECKLED  Speckled Egg  cream shell + warm `spot` speckles
  GOLDEN    Golden Egg    gold shell + a darker `band` round the middle + 3 amber `glow` gems (Neon)
One egg is 1.0 wide and 1.4 tall (EGG_W / EGG_H): it fits in a hunter's hand-sized slot and in
the incubator's nest (INCUBATOR `eggSeat`).
"""

import math

import bmesh
import bpy
from mathutils import Euler, Matrix, Vector

EGG_W, EGG_H = 1.0, 1.4
EGG_CAP = 400
POINT = 0.22  # how much narrower the top is


def to_blender_matrix():
    return Matrix(((1, 0, 0, 0), (0, 0, -1, 0), (0, 1, 0, 0), (0, 0, 0, 1)))


_n = [0]


def _obj(bm, tag="e"):
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
    """Ellipsoid (Roblox axes), poles on y."""
    bm = bmesh.new()
    bmesh.ops.create_uvsphere(bm, u_segments=segments, v_segments=rings, radius=1.0)
    for v in bm.verts:
        x, y, z = v.co
        v.co = Vector((x * radii[0], z * radii[1], -y * radii[2]))
    obj = _obj(bm)
    obj.data.transform(Matrix.Translation(Vector(centre)) @ _rot(rot))
    return obj


def cyl(centre, radius, height, segments=12, top=None, rot=None):
    """Upright cylinder (or a cone frustum with `top` radius), centre = its middle."""
    bm = bmesh.new()
    bmesh.ops.create_cone(bm, cap_ends=True, segments=segments, radius1=radius,
                          radius2=radius if top is None else top, depth=height)
    bmesh.ops.transform(bm, matrix=Matrix.Rotation(math.radians(-90), 4, "X"), verts=bm.verts)  # z -> y
    obj = _obj(bm, "c")
    obj.data.transform(Matrix.Translation(Vector(centre)) @ _rot(rot))
    return obj


def ring(centre, rx, rz, thick, segments=16, minor=5, rot=None):
    bm = bmesh.new()
    grid = []
    for i in range(segments):
        a = 2 * math.pi * i / segments
        ca, sa = math.cos(a), math.sin(a)
        grid.append([bm.verts.new((rx * ca + thick * math.cos(b) * ca, thick * math.sin(b), rz * sa + thick * math.cos(b) * sa))
                     for b in (2 * math.pi * j / minor for j in range(minor))])
    for i in range(segments):
        for j in range(minor):
            bm.faces.new((grid[i][j], grid[i][(j + 1) % minor], grid[(i + 1) % segments][(j + 1) % minor],
                          grid[(i + 1) % segments][j]))
    bmesh.ops.recalc_face_normals(bm, faces=bm.faces)
    obj = _obj(bm, "r")
    obj.data.transform(Matrix.Translation(Vector(centre)) @ _rot(rot))
    return obj


def tube(points, radii, subdiv=1):
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
        obj.modifiers.new("sub", "SUBSURF").levels = subdiv
    baked = bpy.data.meshes.new_from_object(obj.evaluated_get(bpy.context.evaluated_depsgraph_get()))
    old = obj.data
    obj.modifiers.clear()
    obj.data = baked
    bpy.data.meshes.remove(old)
    return obj


def patch(centre, normal, radius, thick, segments=8, rings=4, squash=1.0, spin=0.0):
    obj = ell((0, 0, 0), (radius, thick, radius * squash), segments, rings, rot=(0, spin, 0))
    q = Vector((0, 1, 0)).rotation_difference(Vector(normal).normalized())
    obj.data.transform(Matrix.Translation(Vector(centre)) @ q.to_matrix().to_4x4())
    return obj


# ------------------------------------------------------------------ the egg shape

def _scale(t):
    return 1 - POINT * max(t, 0) ** 1.5 + 0.06 * (1 - t * t)


def shell(base=(0, 0, 0), w=EGG_W, h=EGG_H, segments=14, rings=10):
    """The egg, resting on `base` (its lowest point)."""
    obj = ell((0, 0, 0), (w / 2, h / 2, w / 2), segments, rings)
    for v in obj.data.vertices:
        s = _scale(v.co.y / (h / 2))
        v.co.x *= s
        v.co.z *= s
    obj.data.transform(Matrix.Translation(Vector(base) + Vector((0, h / 2, 0))))
    return obj


def surface(theta, phi, base=(0, 0, 0), w=EGG_W, h=EGG_H, out=0.0):
    """A point on the egg (theta 0 = bottom .. 180 = top, phi round from +X) and its normal."""
    th, ph = math.radians(theta), math.radians(phi)
    t = -math.cos(th)
    s = _scale(t)
    x, y, z = math.sin(th) * math.cos(ph) * w / 2 * s, t * h / 2, math.sin(th) * math.sin(ph) * w / 2 * s
    n = Vector((x / (w / 2) ** 2, y / (h / 2) ** 2, z / (w / 2) ** 2)).normalized()
    p = Vector((x, y + h / 2, z)) + Vector(base) + n * out
    return p, n


# deterministic "random" spot layout (no RNG: the source hash is the change hash, #440)
def _scatter(count, lo=40, hi=150):
    """An R2 low-discrepancy layout: even cover, no clumps, no RNG."""
    out = []
    for i in range(1, count + 1):
        u, v = (0.5 + i * 0.7548776662) % 1.0, (0.5 + i * 0.5698402910) % 1.0
        c = math.cos(math.radians(lo)) + (math.cos(math.radians(hi)) - math.cos(math.radians(lo))) * u
        out.append((math.degrees(math.acos(c)), v * 360))  # even by area between lo and hi
    return out


def radius_at(y, w=EGG_W, h=EGG_H):
    t = y / (h / 2) - 1
    return w / 2 * math.sqrt(max(0.0, 1 - t * t)) * _scale(t)


SHELL = {"MUD": (176, 150, 112), "SPECKLED": (255, 242, 208), "GOLDEN": (255, 190, 30)}
COLORS = {
    "MUD": {"shell": SHELL["MUD"], "mud": (96, 70, 46), "grass": (92, 140, 60)},
    "SPECKLED": {"shell": SHELL["SPECKLED"], "spot": (196, 96, 52)},
    "GOLDEN": {"shell": SHELL["GOLDEN"], "band": (178, 104, 24), "glow": (255, 140, 40)},
}
TARGETS = {
    "MUD": {"shell": 220, "mud": 140, "grass": 30},
    "SPECKLED": {"shell": 200, "spot": 190},
    "GOLDEN": {"shell": 220, "band": 80, "glow": 96},
}
DISPLAY = {"MUD": "Mud Egg", "SPECKLED": "Speckled Egg", "GOLDEN": "Golden Egg"}


def design(key, base=(0, 0, 0)):
    """{group: [objs]} for one egg resting on `base` (Roblox axes)."""
    parts = {"shell": [shell(base)]}
    if key == "MUD":
        # thick splats round the base, a couple of drips up the side, a grass blade stuck on
        y = 0.2
        parts["mud"] = [ring(Vector(base) + Vector((0, y, 0)), radius_at(y), radius_at(y), 0.075, 16, 4)]
        parts["mud"] += [ell(tuple(surface(th, ph, base, out=-0.03)[0]), (r, r * 0.8, r), 8, 5)
                         for th, ph, r in ((38, 20, 0.13), (42, 95, 0.11), (36, 170, 0.14), (40, 240, 0.12), (37, 310, 0.13))]
        p, n = surface(40, 285, base, out=0.0)
        tip = p + Vector((0.12, 0.42, -0.08))
        parts["grass"] = [tube([p, (p + tip) / 2 + n * 0.05, tip], [0.035, 0.025, 0.008], subdiv=0)]
    elif key == "SPECKLED":
        parts["spot"] = [patch(*surface(th, ph, base, out=0.002), 0.06 + 0.03 * ((i * 7) % 3), 0.015, 8, 3,
                               squash=1.0 + 0.3 * (i % 2), spin=ph)
                         for i, (th, ph) in enumerate(_scatter(14, 30, 165))]
    elif key == "GOLDEN":
        parts["band"] = [ring(Vector(base) + Vector((0, EGG_H * 0.47, 0)), EGG_W / 2 * _scale(-0.06) + 0.01,
                              EGG_W / 2 * _scale(-0.06) + 0.01, 0.065, 18, 5)]
        parts["glow"] = [ell(tuple(surface(87, ph, base, out=0.06)[0]), (0.1, 0.13, 0.1), 8, 6)
                         for ph in (-90, 30, 150)]
    return parts


def finish(lp, parts, targets, key, cap):
    pieces = []
    for group, objs in parts.items():
        obj = lp.join(group, objs)
        lp.decimate_to(obj, targets.get(group, 10_000))
        obj.data.transform(to_blender_matrix())
        pieces.append(obj)
    total = sum(lp.tris(o) for o in pieces)
    print(f"ART {key} egg tris {total} " + " ".join(f"{o.name}={lp.tris(o)}" for o in pieces))
    if total > cap:
        raise SystemExit(f"ART FAIL {key}: {total} tris > {cap}")
    blo, bhi = lp.bounds(pieces)
    lo = (float(blo[0]), float(blo[2]), float(-bhi[1]))
    hi = (float(bhi[0]), float(bhi[2]), float(-blo[1]))
    print(f"ART {key} box {tuple(round(v, 2) for v in lo)} .. {tuple(round(v, 2) for v in hi)}")
    return pieces, (lo, hi)


def ground(lp, radius):
    obj = lp.ellipsoid("ground", (0, 0, -0.02), (radius, radius, 0.02), 32, 4)
    obj.color = (0.45, 0.42, 0.36, 1.0)
    return obj


def pad(lp, half):
    """Preview only: two loose vertices (no faces, renders nothing) that widen the ortho framing."""
    mesh = bpy.data.meshes.new("frame")
    mesh.from_pydata([(-half, -half, -0.5), (half, half, 2 * half - 0.3)], [], [])
    obj = bpy.data.objects.new("frame", mesh)
    bpy.context.scene.collection.objects.link(obj)
    return obj


def paint_context(lp, parts, colors):
    """Preview-only copies (e.g. an egg in the incubator): joined, in Blender axes, coloured."""
    out = []
    for group, objs in parts.items():
        obj = lp.join(f"ctx_{group}", objs)
        obj.data.transform(to_blender_matrix())
        c = colors[group]
        obj.color = (c[0] / 255, c[1] / 255, c[2] / 255, 1.0)
        out.append(obj)
    return out


def egg_model(lp, key):
    pieces, box = finish(lp, design(key), TARGETS[key], key, EGG_CAP)
    return {
        "batch": "11f",
        "budget": "small",
        "box": box,
        "pieces": pieces,
        "colors": COLORS[key],
        "context": [ground(lp, 0.9)],
        "meta": {"egg": key, "display": DISPLAY[key], "origin": "base", "cap": EGG_CAP},
    }
