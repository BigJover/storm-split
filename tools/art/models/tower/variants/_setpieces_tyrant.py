"""Tyrant King set pieces (premium theme, PREMIUM_SKINS.md, batch 11p4): one themed add-on per tower kind,
`tower/SET_TYRANT_KING_<TOWER>`, worn over that tower's art at every stage on top of the Tyrant King trim
(SET_TYRANT_KING.py). Crimson and bone-white T. rex royalty, gold only as trim; the rex eyes and sigils are
group `glow` (Neon in game: Shared/SkinFx pulses them and, at stage 2, lights them up with gold dust).

Motifs (Roblox studs from the tower's base, front -Z, _kit.py primitives):
  rex        a giant T. rex skull (cranium, long snout, heavy brows, glowing red eyes in dark sockets,
             fangs, an open lower jaw: it roars), facing `yaw`
  plinth     a crimson-draped plinth (gold hem) for a rex skull to sit on: the monument
  pole       a bone banner pole: crimson swallowtail banner, gold claw finial, a glowing rex-eye sigil
  palisade   a row of giant fangs standing in a low bone rail (a tooth palisade)
  arch       a rex-jaw arch: two curved jawbones meeting overhead, fangs hanging inside
  throne     a bone throne: crimson seat, a fan of rib bones for its back, a small rex skull crowning it
  crown      a small bone crown with a gold band and a glowing gem
Built and checked by _setpiece_common.setpiece (<= 800 tris, flag + Rescue Beacon columns clear, muzzle +
its lane clear at every stage, Tar Pit <= 0.8, Vent's middle clear, clip <= 35 %).
"""

import importlib.util
import math
from pathlib import Path

from mathutils import Euler, Matrix, Vector

TOWER = Path(__file__).resolve().parents[1]
_spec = importlib.util.spec_from_file_location("_setpiece_common", TOWER / "variants" / "_setpiece_common.py")
C = importlib.util.module_from_spec(_spec)
_spec.loader.exec_module(C)

COLORS = {"bone": (234, 224, 198), "bone2": (196, 180, 150), "crimson": (156, 22, 36), "crimson2": (96, 16, 26),
          "gold": (214, 170, 64), "dark": (46, 30, 30), "glow": (255, 34, 44)}
LIM = 1.49


def fit(c, rx, rz):
    x, y, z = c
    return (max(-LIM + rx, min(LIM - rx, x)), y, max(-LIM + rz, min(LIM - rz, z)))


def place(objs, at, yaw=0.0, s=1.0, pitch=0.0):
    m = (Matrix.Translation(Vector(at)) @ Euler((0, math.radians(yaw), 0), "XYZ").to_matrix().to_4x4()
         @ Euler((math.radians(pitch), 0, 0), "XYZ").to_matrix().to_4x4() @ Matrix.Scale(s, 4))
    for o in objs:
        o.data.transform(m)
        o.data.update()
    return objs


class _Collect:
    def __init__(self):
        self.items = []

    def add(self, group, *objs, **kw):
        self.items.append((group, objs, kw))


def contained(fn):
    """Run a motif into a collector, then slide it (x / z) so every vertex stays inside the 3 x 3
    footprint (a hair inside the Body), and add it to the real kit."""
    import functools

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
                place(objs, (dx, 0, dz))
            k.add(group, *objs, **akw)
    return run


def fang(K, a, b, r):
    return K.rod(a, b, r, 4, top=0.04)


@contained
def rex(k, K, at, s=1.0, yaw=0.0, gape=22, pitch=0.0, teeth=3):
    """A T. rex skull facing -Z (before yaw), cranium centre at `at`; s = 1: ~0.75 wide, 1.15 long."""
    s = s * 1.7  # read from the game camera
    g = {"bone": [], "bone2": [], "dark": [], "glow": []}
    g["bone"] += [K.ell((0, 0.04, 0.12), (0.36, 0.3, 0.36), 8, 5),
                  K.rbox((0, -0.02, -0.34), (0.48, 0.26, 0.5), bevel=0.04, taper=(0.75, 0.8)),
                  K.ell((0, -0.04, -0.6), (0.2, 0.13, 0.12), 6, 3)]
    g["bone2"] += [K.ell((0.2 * x, 0.17, -0.14), (0.13, 0.07, 0.16), 5, 3) for x in (-1, 1)]
    g["dark"] += [K.ell((0.25 * x, 0.06, -0.16), (0.07, 0.08, 0.08), 5, 3) for x in (-1, 1)]
    g["dark"] += [K.ell((0.22 * x, -0.02, -0.42), (0.03, 0.06, 0.11), 4, 3) for x in (-1, 1)]  # skull windows
    g["glow"] += [K.ell((0.28 * x, 0.06, -0.18), (0.05, 0.06, 0.06), 5, 3) for x in (-1, 1)]
    g["bone"] += [fang(K, (0.2 * x, -0.14, -0.16 - 0.15 * i), (0.2 * x, -0.27, -0.17 - 0.15 * i), 0.035)
                  for x in (-1, 1) for i in range(teeth)]
    a = math.radians(gape)

    def q(y, z):  # a point on the lower jaw opened about its hinge (0, -0.14, 0.12)
        return (-0.14 + y * math.cos(a) + z * math.sin(a), 0.12 - y * math.sin(a) + z * math.cos(a))

    y0, z0 = q(-0.05, -0.36)
    g["bone2"] += [K.rbox((0, y0, z0), (0.4, 0.1, 0.62), bevel=0.03, taper=(0.75, 0.8), rot=(-gape, 0, 0))]
    g["bone"] += [fang(K, (0.15 * x, *q(0.0, -0.2 - 0.16 * i)), (0.15 * x, *q(0.12, -0.21 - 0.16 * i)), 0.03)
                  for x in (-1, 1) for i in range(teeth - 1)]
    for group, objs in g.items():
        place(objs, at, yaw, s, pitch)
        k.add(group, *objs)


def plinth(k, K, foot, h=0.7, w=0.6):
    x, y, z = fit(foot, w / 2 + 0.06, w / 2 + 0.06)
    k.add("bone2", K.rbox((x, y + h / 2, z), (w, h, w), bevel=0.04, taper=(0.86, 0.86)))
    k.add("crimson", K.rbox((x, y + h * 0.62, z), (w + 0.06, h * 0.5, w + 0.06), bevel=0.02, taper=(0.9, 0.9)))
    k.add("gold", K.rbox((x, y + h * 0.37, z), (w + 0.08, 0.05, w + 0.08), bevel=0.0))
    return (x, y + h, z)


@contained
def monument(k, K, foot, h=0.7, s=1.0, yaw=0.0, gape=24):
    """The set's signature: a giant rex skull roaring on a crimson-draped plinth."""
    x, top, z = plinth(k, K, foot, h, w=0.56 * s + 0.1)
    rex(k, K, (x, top + 0.24 * s, z), s, yaw, gape, pitch=10)


@contained
def pole(k, K, foot, h, w=0.62, bh=1.0, facing="-z"):
    """A bone banner pole, a crimson swallowtail banner hung from a crossbar near the top, a gold claw
    finial and a glowing rex-eye sigil on the banner."""
    x, y, z = fit(foot, 0.07, 0.07)
    k.add("bone", K.rod((x, y, z), (x, y + h, z), 0.07, 6),
          *[K.cyl((x, y + h * t, z), 0.07, 0.06, 6, bevel=0.0) for t in (0.3, 0.55)])
    k.add("gold", *[fang(K, (x, y + h, z), (x + dx, y + h + 0.24, z + dz), 0.035) for dx, dz in ((0.08, 0), (-0.08, 0), (0, 0.06))])
    top = y + h - 0.12
    if facing == "-x":
        x, _, z = fit((x, top, z), 0.07, w / 2 + 0.08)
        fx, sz = x - 0.04, 1
        k.add("bone", K.rod((fx, top, z - w / 2 - 0.06), (fx, top, z + w / 2 + 0.06), 0.03, 4))
        k.add("crimson", K.rbox((fx, top - bh / 2, z), (0.04, bh, w), bevel=0.0),
              *[K.rbox((fx, top - bh - 0.1, z + d * w / 4), (0.04, 0.2, w / 2), bevel=0.0, taper=(1.0, 0.06)) for d in (-1, 1)])
        k.add("gold", K.rbox((fx - 0.005, top - bh + 0.02, z), (0.045, 0.05, w), bevel=0.0))
        k.add("glow", K.ell((fx - 0.03, top - bh * 0.45, z), (0.02, 0.13, 0.1), 5, 3))
        return
    fz = z + (-0.07 if facing == "-z" else 0.07)
    x, _, _ = fit((x, top, z), w / 2 + 0.08, 0.07)
    k.add("bone", K.rod((x - w / 2 - 0.06, top, fz), (x + w / 2 + 0.06, top, fz), 0.03, 4))
    k.add("crimson", K.rbox((x, top - bh / 2, fz), (w, bh, 0.04), bevel=0.0),
          *[K.rbox((x + d * w / 4, top - bh - 0.1, fz), (w / 2, 0.2, 0.04), bevel=0.0, taper=(1.0, 1.0)) for d in (-1, 1)])
    k.add("gold", K.rbox((x, top - bh + 0.02, fz), (w, 0.05, 0.045), bevel=0.0))
    dz = -0.03 if facing == "-z" else 0.03
    k.add("glow", K.ell((x, top - bh * 0.45, fz + dz), (0.1, 0.13, 0.02), 5, 3))


@contained
def palisade(k, K, a, b, n=4, h=0.6, r=0.09):
    """A row of giant fangs standing in a low bone rail from a to b (ground points)."""
    a, b = Vector(a), Vector(b)
    k.add("bone2", K.bar(a + Vector((0, 0.06, 0)), b + Vector((0, 0.06, 0)), 0.14, 0.12, 0.0))
    teeth = []
    for i in range(n):
        p = a + (b - a) * ((i + 0.5) / n)
        hh = h * (1.0 if i % 2 == 0 else 0.75)
        teeth.append(K.rod((p.x, p.y + 0.1, p.z), (p.x, p.y + 0.1 + hh, p.z - 0.04), r, 5, top=0.05))
    k.add("bone", *teeth)


@contained
def arch(k, K, a, b, h=2.0, r=0.1, n=3):
    """A rex-jaw arch from ground point a to ground point b: two curved jawbones meeting overhead, fangs
    hanging from them, a gold band at the crown and a glowing gem."""
    a, b = Vector(a), Vector(b)
    mid = (a + b) / 2
    span = b - a
    pts = []
    for i in range(7):
        t = i / 6
        p = a + span * t
        pts.append(Vector((p.x, a.y + h * math.sin(math.pi * t) ** 0.8, p.z)))
    k.add("bone", *[K.rod(p, q, r * (1.0 - 0.25 * abs(i - 2.5) / 2.5), 6) for i, (p, q) in enumerate(zip(pts, pts[1:]))])
    k.add("bone", *[fang(K, pts[i] - Vector((0, r * 0.8, 0)), pts[i] - Vector((0, r * 0.8 + 0.22, 0)), 0.04) for i in (1, 2, 4, 5)])
    top = Vector((mid.x, a.y + h, mid.z))
    k.add("gold", K.cyl(tuple(top), r * 1.3, 0.12, 6, bevel=0.0, rot=(90, math.degrees(math.atan2(span.x, span.z)), 0)))
    k.add("glow", K.ell(tuple(top + Vector((0, 0.04, 0))), (0.07, 0.07, 0.07), 5, 3))


@contained
def throne(k, K, at, yaw=0.0, s=1.0):
    """A bone throne facing -Z before yaw: crimson seat, rib-bone back, skull crest with glowing eyes."""
    g = {"bone2": [K.rbox((0, 0.22, 0), (0.62, 0.44, 0.52), bevel=0.0)],
         "crimson": [K.rbox((0, 0.47, -0.02), (0.56, 0.08, 0.46), bevel=0.0),
                     K.rbox((0, 0.8, 0.22), (0.46, 0.6, 0.05), bevel=0.0)],
         "bone": [K.rod((0.12 * i, 0.44, 0.26), (0.18 * i, 1.24 - 0.06 * abs(i), 0.3), 0.04, 4) for i in (-2, -1, 0, 1, 2)]
         + [K.rbox((0.3 * x, 0.62, -0.02), (0.08, 0.06, 0.48), bevel=0.0) for x in (-1, 1)],
         "gold": [K.rbox((0, 0.45, -0.27), (0.62, 0.05, 0.03), bevel=0.0)]}
    for group, objs in g.items():
        place(objs, at, yaw, s)
        k.add(group, *objs)
    x, y, z = at
    c, sn = math.cos(math.radians(yaw)), math.sin(math.radians(yaw))
    rex(k, K, (x + 0.32 * s * sn, y + 1.32 * s, z + 0.32 * s * c), 0.42 * s, yaw, 18, teeth=2)


@contained
def crown(k, K, at, s=1.0):
    x, y, z = at
    k.add("gold", K.cyl((x, y + 0.06 * s, z), 0.2 * s, 0.12 * s, 8, bevel=0.0))
    k.add("bone", *[fang(K, (x + 0.18 * s * math.cos(a), y + 0.1 * s, z + 0.18 * s * math.sin(a)),
                         (x + 0.2 * s * math.cos(a), y + 0.34 * s, z + 0.2 * s * math.sin(a)), 0.045 * s)
                    for a in (math.radians(d) for d in range(0, 360, 72))])
    k.add("glow", K.ell((x, y + 0.08 * s, z - 0.2 * s), (0.05 * s, 0.05 * s, 0.03 * s), 5, 3))


# ---------------------------------------------------------------- the 18 pieces

def scout(k, K):
    pole(k, K, (-1.3, 0.0, 1.3), 3.7, facing="-z")
    rex(k, K, (-0.95, 2.6, -1.0), 0.62, 0, 26, pitch=8)
    palisade(k, K, (-1.36, 0.0, -0.5), (-1.36, 0.0, 0.7), n=4, h=0.55)


def sniper(k, K):
    rex(k, K, (-0.95, 3.4, -1.15), 0.62, 0, 26, pitch=6)
    pole(k, K, (-1.42, 0.0, 0.55), 4.6, facing="-x")
    palisade(k, K, (-1.3, 0.0, -1.3), (-0.2, 0.0, -1.36), n=4, h=0.5)


def grenadier(k, K):
    monument(k, K, (-1.15, 0.0, 0.1), h=0.9, s=0.85)
    palisade(k, K, (-1.25, 0.0, -1.32), (0.7, 0.0, -1.36), n=5, h=0.5)


def chiller(k, K):
    arch(k, K, (-1.3, 0.0, 1.32), (0.4, 0.0, 1.32), h=2.6, r=0.1)
    pole(k, K, (-1.42, 0.0, -0.1), 2.6, w=0.5, bh=0.7, facing="-x")


def quartermaster(k, K):
    monument(k, K, (-1.15, 0.0, 1.15), h=0.9, s=0.8)
    pole(k, K, (0.35, 0.0, 1.35), 3.4, facing="-z")
    palisade(k, K, (-1.4, 0.0, -1.2), (-1.4, 0.0, 0.3), n=4, h=0.55)


def hospital(k, K):
    pole(k, K, (-1.3, 0.0, 0.3), 3.3, w=0.5, bh=0.8, facing="-x")
    monument(k, K, (-1.15, 0.0, -0.95), h=0.6, s=0.65)


def armory(k, K):
    monument(k, K, (-1.1, 0.0, -1.15), h=0.8, s=0.75)
    palisade(k, K, (-1.42, 0.0, -0.4), (-1.42, 0.0, 0.9), n=4, h=0.6)


def coil(k, K):
    monument(k, K, (-1.15, 0.0, -0.75), h=0.7, s=0.7)
    pole(k, K, (-1.3, 0.0, 0.85), 2.9, w=0.44, bh=0.7, facing="-z")


def falcon(k, K):
    pole(k, K, (-1.1, 0.0, -1.32), 2.9, w=0.5, bh=0.7, facing="-z")
    palisade(k, K, (-0.6, 0.0, -1.38), (0.6, 0.0, -1.38), n=4, h=0.5)
    rex(k, K, (-1.05, 3.15, -1.15), 0.55, 0, 26, pitch=10)


def ballista(k, K):
    monument(k, K, (-1.15, 0.0, 0.95), h=0.9, s=0.8)
    palisade(k, K, (-1.4, 0.0, -1.2), (-1.4, 0.0, 0.2), n=4, h=0.55)


def tarpit(k, K):
    # flat (<= 0.8): a sunken rex skull at the left edge, jaws open on the tar, fangs of a jaw poking out
    rex(k, K, (-1.0, 0.4, 0.05), 0.62, 90, 10, pitch=0)
    k.add("bone", *[K.rod((x, 0.0, 1.2), (x + 0.04, 0.58, 1.16), 0.09, 5, top=0.05) for x in (-0.6, -0.2, 0.2, 0.6)])
    k.add("bone2", K.bar((-0.8, 0.06, 1.22), (0.8, 0.06, 1.22), 0.16, 0.12, 0.0))


def resin(k, K):
    monument(k, K, (-1.15, 0.0, 1.0), h=1.0, s=0.8)
    pole(k, K, (-1.42, 0.0, -0.6), 2.6, w=0.46, bh=0.7, facing="-x")


def raptor(k, K):
    arch(k, K, (0.15, 0.0, 0.45), (1.0, 0.0, -0.15), h=3.0, r=0.12)
    pole(k, K, (-1.42, 0.0, -0.9), 2.6, w=0.46, bh=0.7, facing="-x")


def totem(k, K):
    monument(k, K, (-1.05, 0.0, 1.05), h=1.4, s=0.85, yaw=-20)
    palisade(k, K, (-1.38, 0.0, -1.2), (-1.38, 0.0, 0.2), n=4, h=0.5)


def blimp(k, K):
    throne(k, K, (-0.95, 0.0, 0.2), yaw=-90, s=1.05)
    palisade(k, K, (-1.0, 0.0, -1.38), (0.4, 0.0, -1.38), n=4, h=0.5)


def meteor(k, K):
    monument(k, K, (-1.15, 0.0, -1.1), h=1.3, s=0.8, yaw=0)
    pole(k, K, (-1.42, 0.0, 0.5), 3.0, w=0.46, bh=0.8, facing="-x")


def vent(k, K):
    rex(k, K, (-1.15, 0.45, 1.15), 0.36, 135, 28, pitch=14)
    k.add("bone2", K.cyl((-1.18, 0.12, 1.18), 0.26, 0.24, 7, bevel=0.0))
    pole(k, K, (-1.3, 0.0, -1.25), 2.8, w=0.4, bh=0.7, facing="-z")


def ranger(k, K):
    pole(k, K, (-1.3, 0.0, 1.3), 3.7, facing="-z")
    rex(k, K, (-1.05, 2.45, -0.95), 0.6, 0, 24, pitch=8)
    palisade(k, K, (-1.42, 0.0, -0.6), (-1.42, 0.0, 0.7), n=4, h=0.55)


DESIGNS = {"SCOUT": scout, "SNIPER": sniper, "GRENADIER": grenadier, "CHILLER": chiller,
           "QUARTERMASTER": quartermaster, "HOSPITAL": hospital, "ARMORY": armory, "COIL": coil,
           "FALCON": falcon, "BALLISTA": ballista, "TARPIT": tarpit, "RESIN": resin, "RAPTOR": raptor,
           "TOTEM": totem, "BLIMP": blimp, "METEOR": meteor, "VENT": vent, "RANGER": ranger}


def build(lp, tower):
    model = C.setpiece(lp, "TYRANT_KING", tower, DESIGNS[tower], COLORS)
    model["batch"] = "11p4"
    model["meta"].update({"theme": "TYRANT_KING", "premium": True})
    return model
