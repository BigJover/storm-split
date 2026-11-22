"""Tyrant King hunter pieces (premium theme, PREMIUM_SKINS.md, batch 11p4): crimson and bone-white T. rex
royalty, gold only as trim, glowing red eyes / runes in group `glow` (Neon in game, #439; Shared/SkinFx
pulses them and the pack tier reads them). Authored in the hunter body's frame (_body.py: Roblox studs
about the HumanoidRootPart, front -Z).

Helpers only (no model):
  seg / horn / rod / crack / on_ell   tapered segments, curved horns, glowing rune lines (as in Lava Lord)
  tooth                                a fang: a 4-sided cone from base to tip
  skull(B, ...)                        a dino skull (cranium, snout, brow ridges, glowing eyes in dark
                                       sockets, nostrils, a row of teeth and an optional open lower jaw)
                                       in its own frame (facing -Z, origin = cranium centre), returned
                                       per paint group; `place` scales / turns / moves it onto the body
  place(objs, at, yaw, s, pitch)       transform finished objects (local frame -> body frame)
  protect                              an `lp` wrapper: glow / bone / gold pieces skip Body.finish's even
                                       decimation (teeth and runes stay crisp)
"""

import math

import bmesh
from mathutils import Euler, Matrix, Vector

BONE = (234, 224, 198)
BONE2 = (196, 180, 150)
CRIMSON = (156, 22, 36)
CRIMSON2 = (96, 16, 26)
FUR = (50, 38, 36)
GOLD = (214, 170, 64)
GLOW = (255, 34, 44)
LEATHER = (52, 34, 32)


def rod(B, a, b, r, segments=4):
    a, b = Vector(a), Vector(b)
    axis = b - a
    bm = bmesh.new()
    bmesh.ops.create_cone(bm, cap_ends=False, segments=segments, radius1=r, radius2=r * 0.85, depth=axis.length)
    rot = axis.to_track_quat("Z", "Y").to_matrix().to_4x4()
    bmesh.ops.transform(bm, matrix=Matrix.Translation((a + b) / 2) @ rot, verts=bm.verts)
    return B._obj(bm, "rune")


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


def tooth(B, base, tip, r=0.05, segments=4):
    return seg(B, base, tip, r, 0.0, segments)


def horn(B, pts, r0, segments=6, overlap=0.02):
    n = len(pts) - 1
    out = []
    for i, (p, q) in enumerate(zip(pts, pts[1:])):
        p, q = Vector(p), Vector(q)
        d = (q - p).normalized() * overlap
        r1, r2 = r0 * (1 - (i / n) ** 1.6), r0 * (1 - ((i + 1) / n) ** 1.6)
        out.append(seg(B, p - d, q, r1, r2, segments, cap=(i == 0)))
    return out[:-1], out[-1]


def place(objs, at=(0, 0, 0), yaw=0.0, s=1.0, pitch=0.0, roll=0.0):
    """Scale by s, pitch about X, roll about Z, turn by yaw about Y (degrees, Roblox axes), move to at."""
    m = (Matrix.Translation(Vector(at)) @ Euler((0, math.radians(yaw), 0), "XYZ").to_matrix().to_4x4()
         @ Euler((math.radians(pitch), 0, math.radians(roll)), "XYZ").to_matrix().to_4x4() @ Matrix.Scale(s, 4))
    for o in objs:
        o.data.transform(m)
        o.data.update()
    return objs


def skull(B, w=1.0, length=1.0, h=1.0, teeth=5, jaw=None, eyes=True, cranium=True, seg_n=10):
    """A dino skull facing -Z, cranium centre at the origin (s = 1: about 1.25 wide, 1.9 long).
    w / length / h stretch it (a raptor = narrow, long, low). jaw = None (no lower jaw) or the
    gape in degrees. Returns {group: [objs]} with groups bone, bone2 (sockets' rims / jaw), dark
    (sockets, nostrils), glow (eyes)."""
    g = {"bone": [], "bone2": [], "dark": [], "glow": []}
    sl = 0.62 * w
    if cranium:
        g["bone"].append(B.ell((0, 0, 0.1), (0.62 * w, 0.46 * h, 0.62), seg_n, 6))
    # the snout: a tapered box forward of the cranium, a rounded tip
    sn_z = -0.62 * length
    g["bone"].append(B.rbox((0, -0.04 * h, sn_z), (0.78 * w, 0.4 * h, 0.78 * length), bevel=0.1, segments=1, taper=(0.82, 1.0)))
    g["bone"].append(B.ell((0, -0.06 * h, sn_z - 0.38 * length), (0.32 * w, 0.2 * h, 0.2), 8, 4))
    # brow ridges (the rex's heavy brows) and the cheek horns
    g["bone2"] += [B.ell((0.34 * w * k, 0.24 * h, -0.3), (0.2 * w, 0.09 * h, 0.24), 6, 3, rot=(0, 0, -10 * k)) for k in (-1, 1)]
    # eye sockets (dark) with glowing eyes
    if eyes:
        g["dark"] += [B.ell((0.42 * w * k, 0.1 * h, -0.32), (0.1, 0.12 * h, 0.13), 6, 4) for k in (-1, 1)]
        g["glow"] += [B.ell((0.45 * w * k, 0.1 * h, -0.34), (0.095, 0.1 * h, 0.11), 6, 3) for k in (-1, 1)]
    g["dark"] += [B.ell((0.13 * w * k, 0.1 * h, sn_z - 0.42 * length), (0.06, 0.05, 0.04), 5, 3) for k in (-1, 1)]
    # the rex's skull windows (a dark opening on each side of the snout) and a nasal ridge of bumps
    g["dark"] += [B.ell((0.37 * w * k, 0.0, sn_z + 0.06 * length), (0.05, 0.1 * h, 0.2 * length), 6, 3) for k in (-1, 1)]
    g["bone2"] += [B.ell((0, 0.17 * h, sn_z + dz * length), (0.1 * w, 0.06 * h, 0.12), 5, 3) for dz in (-0.25, 0.0, 0.25)]
    # upper teeth along the snout's lower edge (sides) and at the front
    y0 = -0.22 * h
    tl = 0.2 * h
    for i in range(teeth):
        t = i / max(1, teeth - 1)
        z = -0.25 - t * (0.75 * length)
        xs = 0.36 * w * (1 - 0.3 * t)
        for k in (-1, 1):
            g["bone"].append(tooth(B, (xs * k, y0, z), (xs * k * 1.02, y0 - tl * (1.0 - 0.3 * t), z - 0.02), 0.045))
    for x in (-0.12, 0.12):
        g["bone"].append(tooth(B, (x * w, y0 - 0.02, sn_z - 0.42 * length), (x * w, y0 - tl * 0.8, sn_z - 0.44 * length), 0.04))
    if jaw is not None:
        a = math.radians(jaw)
        hinge = Vector((0, -0.18 * h, 0.15))
        objs = [B.rbox((0, -0.08, -0.55 * length), (0.66 * w, 0.14, 1.0 * length), bevel=0.05, segments=1, taper=(0.8, 1.0))]
        for i in range(teeth - 1):
            t = i / max(1, teeth - 2)
            z = -0.2 - t * 0.8 * length
            xs = 0.28 * w * (1 - 0.3 * t)
            for k in (-1, 1):
                objs.append(tooth(B, (xs * k, 0.0, z), (xs * k, 0.16 * (1 - 0.3 * t), z - 0.02), 0.04))
        place(objs, at=tuple(hinge + Vector((0, -0.06, 0))), pitch=-jaw)  # pitch down = open
        g["bone2"] += objs
    return g


def add_groups(body, part, groups, rename=None):
    rename = rename or {}
    for group, objs in groups.items():
        if objs:
            body.add(part, rename.get(group, group), *objs)


def place_groups(groups, **kw):
    for objs in groups.values():
        place(objs, **kw)
    return groups


PROTECTED = ("__glow", "__bone", "__gold")


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
