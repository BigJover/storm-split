"""Geode set pieces (premium theme, PREMIUM_SKINS.md, batch 11p6): one themed add-on per tower kind,
`tower/SET_GEODE_<TOWER>`, worn over that tower's art at every stage on top of the Geode trim (SET_GEODE.py).
Rough grey stone cracked open to bright amethyst crystal, teal / rose accents; the lit crystal is group `glow`
(Neon in game: Shared/SkinFx glints it, brighter at stage 2). Chunky on purpose: they must read from the high
game camera, also on the tall towers.

Motifs (Roblox studs from the tower's base, front -Z, _kit.py primitives + a hexagonal `crystal`):
  cluster    a giant crystal cluster growing out of a rock lump: a tall glowing centre crystal, amethyst ones
             leaning out round it, one teal (or rose)
  boulder    a cracked boulder split in two, its glowing gem bed and crystals showing in the split
  spire      a tall crystal spire rising from rock rubble, a floating ring of shards round its upper part
  shards     a ring of floating shards (double-pointed crystals) round a point - hovering over a roof
  row        a row of crystals standing in a low stone ledge (a crystal fence)
Built and checked by _setpiece_common.setpiece (<= 800 tris, flag + Rescue Beacon columns clear, muzzle + its
lane clear at every stage, Tar Pit <= 0.8, Vent's middle clear, clip <= 35 %).
"""

import functools
import importlib.util
import math
from pathlib import Path

import bmesh
from mathutils import Matrix, Vector

TOWER = Path(__file__).resolve().parents[1]
_spec = importlib.util.spec_from_file_location("_setpiece_common", TOWER / "variants" / "_setpiece_common.py")
C = importlib.util.module_from_spec(_spec)
_spec.loader.exec_module(C)

COLORS = {"rock": (150, 146, 158), "rock2": (96, 92, 104), "crystal": (122, 58, 196), "teal": (52, 196, 186),
          "rose": (232, 112, 172), "glow": (226, 156, 255)}
LIM = 1.49


def crystal(K, a, b, r, sides=6, point=0.3, double=False):
    """A crystal a -> b (a prism + pointed termination; double = pointed at both ends, a floating shard)."""
    a, b = Vector(a), Vector(b)
    axis = b - a
    L = axis.length
    bm = bmesh.new()
    lo = L * point if double else 0.0
    rings = [[bm.verts.new((rr * math.cos(2 * math.pi * i / sides), rr * math.sin(2 * math.pi * i / sides), z)) for i in range(sides)]
             for z, rr in ((lo, r if double else r * 0.92), (L * (1 - point), r))]
    apex = bm.verts.new((0, 0, L))
    if double:
        foot = bm.verts.new((0, 0, 0))
        for i in range(sides):
            bm.faces.new((rings[0][(i + 1) % sides], rings[0][i], foot))
    else:
        bm.faces.new(list(reversed(rings[0])))
    for i in range(sides):
        j = (i + 1) % sides
        bm.faces.new((rings[0][i], rings[0][j], rings[1][j], rings[1][i]))
        bm.faces.new((rings[1][i], rings[1][j], apex))
    bmesh.ops.recalc_face_normals(bm, faces=bm.faces)
    rot = axis.to_track_quat("Z", "Y").to_matrix().to_4x4()
    bmesh.ops.transform(bm, matrix=Matrix.Translation(a) @ rot, verts=bm.verts)
    return K._obj(bm, "xtal")


def _move(objs, d):
    m = Matrix.Translation(Vector(d))
    for o in objs:
        o.data.transform(m)
        o.data.update()


class _Collect:
    def __init__(self):
        self.items = []

    def add(self, group, *objs, **kw):
        self.items.append((group, objs, kw))


def contained(fn):
    """Run a motif into a collector, then slide it (x / z) so every vertex stays inside the footprint."""

    @functools.wraps(fn)
    def run(k, K, *args, **kw):
        if isinstance(k, _Collect):
            return fn(k, K, *args, **kw)
        c = _Collect()
        fn(c, K, *args, **kw)
        vs = [v.co for _, objs, _ in c.items for o in objs for v in o.data.vertices]
        dx = dz = 0.0
        if vs:
            lo_x, hi_x = min(v.x for v in vs), max(v.x for v in vs)
            lo_z, hi_z = min(v.z for v in vs), max(v.z for v in vs)
            dx = max(0.0, -LIM - lo_x) - max(0.0, hi_x - LIM)
            dz = max(0.0, -LIM - lo_z) - max(0.0, hi_z - LIM)
        for group, objs, akw in c.items:
            if dx or dz:
                _move(objs, (dx, 0, dz))
            k.add(group, *objs, **akw)
    return run


def _lean(a, lean_deg):
    return (math.sin(math.radians(lean_deg)) * math.cos(a), math.cos(math.radians(lean_deg)), math.sin(math.radians(lean_deg)) * math.sin(a))


@contained
def cluster(k, K, foot, h=1.6, s=1.0, accent="teal", n=5, base=True, phase=20.0):
    """A giant crystal cluster: centre crystal h tall (glow), n-1 leaning out round it."""
    x, y, z = foot
    if base:
        k.add("rock", K.ell((x, y + 0.22 * s, z), (0.5 * s, 0.21 * s, 0.5 * s), 7, 3))
        y0 = y + 0.22 * s
    else:
        y0 = y
    k.add("glow", crystal(K, (x, y0 - 0.05, z), (x, y0 + h, z), 0.27 * s))
    side = []
    for i in range(n - 1):
        a = math.radians(phase + 360 * i / (n - 1))
        d = Vector(_lean(a, 28 + 8 * (i % 2)))
        foot_i = Vector((x + 0.16 * s * math.cos(a), y0 - 0.04, z + 0.16 * s * math.sin(a)))
        ln = h * (0.55 + 0.12 * ((i * 5) % 3))
        side.append(crystal(K, tuple(foot_i), tuple(foot_i + d * ln), 0.18 * s, 6))
    k.add(accent, side[0])
    k.add("crystal", *side[1:])


@contained
def boulder(k, K, foot, s=1.0, accent="teal"):
    """A boulder cracked in two along x, its gem bed and crystals glowing in the split."""
    x, y, z = foot
    k.add("rock", K.ell((x - 0.26 * s, y + 0.44 * s, z), (0.34 * s, 0.42 * s, 0.5 * s), 7, 4, rot=(0, 0, 16)),
          K.ell((x + 0.26 * s, y + 0.4 * s, z), (0.32 * s, 0.38 * s, 0.48 * s), 7, 4, rot=(0, 0, -18)))
    k.add("glow", K.ell((x, y + 0.4 * s, z), (0.1 * s, 0.34 * s, 0.4 * s), 6, 3),
          crystal(K, (x, y + 0.5 * s, z), (x - 0.04 * s, y + 1.3 * s, z - 0.06 * s), 0.13 * s))
    k.add("crystal", crystal(K, (x, y + 0.5 * s, z + 0.16 * s), (x + 0.12 * s, y + 1.0 * s, z + 0.4 * s), 0.1 * s),
          crystal(K, (x, y + 0.5 * s, z - 0.2 * s), (x - 0.1 * s, y + 0.96 * s, z - 0.46 * s), 0.1 * s))
    k.add(accent, crystal(K, (x, y + 0.6 * s, z), (x + 0.3 * s, y + 1.02 * s, z), 0.08 * s))


def shards(k, K, c, r=0.5, n=6, ln=0.42, w=0.08, groups=("glow", "crystal")):
    """A ring of floating double-pointed shards round c (each stands upright, tilted outward)."""
    x, y, z = c
    out = {g: [] for g in groups}
    for i in range(n):
        a = math.radians(360 * i / n + 15)
        px, pz = x + r * math.cos(a), z + r * math.sin(a)
        tx, tz = 0.12 * math.cos(a), 0.12 * math.sin(a)
        dy = 0.08 * ((i % 2) * 2 - 1)
        out[groups[i % len(groups)]].append(crystal(K, (px - tx, y - ln / 2 + dy, pz - tz), (px + tx, y + ln / 2 + dy, pz + tz), w, 4, 0.4, double=True))
    for g, objs in out.items():
        if objs:
            k.add(g, *objs)


@contained
def spire(k, K, foot, h=3.0, s=1.0, ring=True, accent="teal", base=True, ring_r=0.5):
    """A tall crystal spire out of rock rubble, a floating ring of shards round its upper third."""
    x, y, z = foot
    if base:
        k.add("rock", K.ell((x, y + 0.2 * s, z), (0.42 * s, 0.19 * s, 0.42 * s), 7, 3),
              K.ell((x + 0.26 * s, y + 0.14 * s, z - 0.2 * s), (0.2 * s, 0.13 * s, 0.2 * s), 6, 3))
    k.add("glow", crystal(K, (x, y + 0.1, z), (x, y + h, z), 0.32 * s, 6, 0.2))
    k.add("crystal", crystal(K, (x - 0.08 * s, y + 0.2, z + 0.12 * s), (x - 0.28 * s, y + h * 0.42, z + 0.3 * s), 0.11 * s))
    k.add(accent, crystal(K, (x + 0.1 * s, y + 0.2, z - 0.06 * s), (x + 0.34 * s, y + h * 0.32, z - 0.16 * s), 0.09 * s))
    if ring:
        shards(k, K, (x, y + h * 0.7, z), r=ring_r * s, n=5, ln=0.56 * s, w=0.12 * s, groups=("crystal", "crystal", accent))


@contained
def row(k, K, a, b, n=4, h=0.7, r=0.12, accent=None, w=0.26):
    """A row of crystals standing in a low stone ledge from ground point a to b."""
    a, b = Vector(a), Vector(b)
    k.add("rock", K.bar(a + Vector((0, 0.09, 0)), b + Vector((0, 0.09, 0)), w, 0.18, 0.0))
    g = {"glow": [], "crystal": []}
    if accent:
        g[accent] = []
    for i in range(n):
        p = a + (b - a) * ((i + 0.5) / n)
        hh = h * (1.0 if i % 2 == 0 else 0.7)
        grp = "glow" if i % 2 == 0 else (accent if (accent and i == 1) else "crystal")
        g[grp].append(crystal(K, (p.x, p.y + 0.12, p.z), (p.x + 0.05 * ((i % 3) - 1), p.y + 0.12 + hh, p.z), r, 6))
    for grp, objs in g.items():
        if objs:
            k.add(grp, *objs)


# ---------------------------------------------------------------- the 18 pieces

def scout(k, K):
    spire(k, K, (-1.4, 0.0, 1.38), 3.4, 0.55, base=False, ring_r=0.7)
    cluster(k, K, (-0.9, 2.45, -0.95), 1.3, 1.0, base=False)
    row(k, K, (-1.43, 0.0, -0.6), (-1.43, 0.0, 0.7), n=3, h=0.6, r=0.07, w=0.12)


def sniper(k, K):
    cluster(k, K, (-0.9, 3.3, -1.05), 1.3, 1.0, base=False)
    spire(k, K, (-1.2, 0.0, 0.55), 4.4, 1.0)
    row(k, K, (-1.3, 0.0, -1.3), (-0.2, 0.0, -1.36), n=3, h=0.55)
    shards(k, K, (0.0, 4.15, 0.0), r=1.18, n=6, ln=0.6, w=0.12, groups=("glow", "crystal", "teal"))


def grenadier(k, K):
    boulder(k, K, (-1.0, 0.0, 0.3), 1.15)
    row(k, K, (-1.25, 0.0, -1.32), (0.7, 0.0, -1.36), n=4, h=0.55)


def chiller(k, K):
    spire(k, K, (-1.15, 0.0, 1.15), 3.0, 1.0)
    cluster(k, K, (-1.1, 0.0, -0.4), 1.3, 0.85)


def quartermaster(k, K):
    boulder(k, K, (-0.3, 0.0, -1.0), 0.95)
    spire(k, K, (0.25, 0.0, 1.2), 3.2, 0.9)
    row(k, K, (-1.42, 0.0, -1.2), (-1.42, 0.0, 0.0), n=3, h=0.6, r=0.09, w=0.16)


def hospital(k, K):
    # the healer's corner: rose-quartz cluster + a spire with a rose accent
    spire(k, K, (-1.15, 0.0, 0.4), 3.2, 0.95, accent="rose")
    cluster(k, K, (-1.05, 0.0, -0.95), 1.2, 0.8, accent="rose")


def armory(k, K):
    boulder(k, K, (-1.0, 0.0, -1.0), 1.0)
    row(k, K, (-1.4, 0.0, -0.2), (-1.4, 0.0, 1.0), n=3, h=0.65)


def coil(k, K):
    cluster(k, K, (-1.1, 0.0, 0.15), 1.5, 0.85)
    spire(k, K, (-1.3, 0.0, -1.3), 3.0, 0.8, ring_r=0.45)


def falcon(k, K):
    spire(k, K, (-1.15, 0.0, -1.15), 2.9, 0.9)
    row(k, K, (-0.5, 0.0, -1.38), (0.6, 0.0, -1.38), n=3, h=0.55)
    cluster(k, K, (-0.6, 1.95, 0.4), 1.2, 0.9, base=False)


def ballista(k, K):
    boulder(k, K, (-1.0, 0.0, 0.95), 1.1)
    row(k, K, (-1.4, 0.0, -1.2), (-1.4, 0.0, 0.1), n=3, h=0.6)


def tarpit(k, K):
    # flat (<= 0.8): a half-sunk split geode at the left edge, a crystal ledge at the back
    x, z = -1.05, 0.0
    k.add("rock", K.ell((x - 0.2, 0.2, z), (0.3, 0.2, 0.5), 7, 3, rot=(0, 0, 12)), K.ell((x + 0.22, 0.18, z), (0.28, 0.18, 0.46), 7, 3, rot=(0, 0, -12)))
    k.add("glow", K.ell((x, 0.2, z), (0.1, 0.16, 0.38), 6, 3),
          crystal(K, (x, 0.2, z), (x, 0.78, z - 0.06), 0.12))
    k.add("crystal", crystal(K, (x, 0.2, z + 0.2), (x + 0.1, 0.62, z + 0.42), 0.1), crystal(K, (x, 0.2, z - 0.22), (x - 0.1, 0.6, z - 0.44), 0.1))
    k.add("rock", K.bar((-0.8, 0.08, 1.24), (0.8, 0.08, 1.24), 0.24, 0.16, 0.0))
    k.add("glow", *[crystal(K, (xx, 0.12, 1.24), (xx, 0.74, 1.2), 0.11) for xx in (-0.55, 0.15)])
    k.add("teal", *[crystal(K, (xx, 0.12, 1.24), (xx + 0.04, 0.56, 1.22), 0.09) for xx in (-0.2, 0.5)])


def resin(k, K):
    boulder(k, K, (-1.0, 0.0, 1.0), 1.1)
    spire(k, K, (-1.2, 0.0, -0.6), 2.8, 0.85)


def raptor(k, K):
    spire(k, K, (0.6, 0.0, 0.2), 3.2, 0.9)
    cluster(k, K, (-1.1, 0.0, -0.9), 1.3, 0.8)


def totem(k, K):
    # a tall twin: a big spire at the back-left (reads next to the tall totem) + a cluster at the front-left
    spire(k, K, (-1.1, 0.0, 1.0), 4.2, 1.1)
    cluster(k, K, (-1.1, 0.0, -0.9), 1.4, 0.85)
    shards(k, K, (0.0, 4.3, 0.0), r=0.85, n=6, ln=0.55, w=0.11, groups=("glow", "crystal", "teal"))


def blimp(k, K):
    cluster(k, K, (-0.95, 0.0, 0.3), 1.8, 1.0)
    row(k, K, (-1.0, 0.0, -1.38), (0.4, 0.0, -1.38), n=3, h=0.55)
    spire(k, K, (-1.2, 0.0, 1.15), 3.4, 0.9)


def meteor(k, K):
    boulder(k, K, (-1.0, 0.0, -1.0), 1.15)
    spire(k, K, (-1.2, 0.0, 0.6), 3.0, 0.9)


def vent(k, K):
    # the Vent's middle stays clear (its cone): two spires on the left corners and a crystal ledge between
    spire(k, K, (-1.3, 0.0, 1.3), 2.4, 0.6, ring=False, base=False)
    spire(k, K, (-1.3, 0.0, -1.3), 3.0, 0.65, ring_r=0.4, base=False)
    row(k, K, (-1.42, 0.0, -0.7), (-1.42, 0.0, 0.7), n=3, h=0.7, r=0.08, w=0.14)


def ranger(k, K):
    spire(k, K, (-1.15, 0.0, -1.1), 3.6, 0.95)
    cluster(k, K, (0.15, 0.0, -1.05), 1.3, 0.8, phase=60)
    row(k, K, (1.38, 0.0, -0.75), (1.38, 0.0, 0.75), n=3, h=0.6, r=0.08, w=0.16)


DESIGNS = {"SCOUT": scout, "SNIPER": sniper, "GRENADIER": grenadier, "CHILLER": chiller,
           "QUARTERMASTER": quartermaster, "HOSPITAL": hospital, "ARMORY": armory, "COIL": coil,
           "FALCON": falcon, "BALLISTA": ballista, "TARPIT": tarpit, "RESIN": resin, "RAPTOR": raptor,
           "TOTEM": totem, "BLIMP": blimp, "METEOR": meteor, "VENT": vent, "RANGER": ranger}


def build(lp, tower):
    model = C.setpiece(lp, "GEODE", tower, DESIGNS[tower], COLORS)
    model["batch"] = "11p6"
    model["meta"].update({"theme": "GEODE", "premium": True})
    return model
