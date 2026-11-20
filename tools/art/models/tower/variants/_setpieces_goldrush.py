"""Gold Rush set pieces (PLAN 11e, #457): one bold themed add-on per tower kind,
`tower/SET_GOLD_RUSH_<TOWER>`, worn over that tower's art at EVERY stage (0, 1, 2) on top of the
Gold Rush trim (SET_GOLD_RUSH.py), while the Gold Rush set is on. Authored like every tower
(_kit.py: Roblox studs from the base, front -Z, the art origin = the Body's centre), in its own
colours (gold, glow = Neon on the gold highlights, timber, iron).

The props (gold nuggets and ore carts on rails, pickaxes, gold-leaf crests, prospector pans,
sluice boxes, ingots, pennants) are below; each `SET_GOLD_RUSH_<TOWER>.py` places them round its
tower. Checked at build (fails the build):
  * <= CAP (800) tris, inside the 3 x 5 x 3 Body (Kit.finish);
  * the owner flag's pole (x 1.2, z 1.2) and the Rescue Beacon (x 1.25, z -1.25) columns clear
    (anything there stays <= 0.3 high, like the trim's rim);
  * clear of the tower's `muzzle` at every stage (>= MUZZLE_CLEAR away, nothing in front of it);
  * Tar Pit: <= TARPIT_MAX (it lies on the track); Vent: nothing within VENT_CLEAR of the middle
    (the basalt column / Fire Mountain cone).
Reported (the "fit" line, eyeballed in the previews): the share of the piece's vertices inside
the tower's art at stages 0, 1 and 2.

Previews: the piece on its tower painted in the Gold Rush set (Skins.paintTower: group `body` in
the set's colour, the rest its accent) with the Gold Rush trim, at stage GR_STAGE (env, default 0);
tools/art/goldrush_previews.sh (not needed by the runtime) renders stages 0 and 2.
"""

import importlib.util
import math
import os
from pathlib import Path

TOWER = Path(__file__).resolve().parents[1]
BATCH = "11e2"
CAP = 800
CLEAR = ((1.2, 1.2, 0.3), (1.25, -1.25, 0.3))  # flag pole, Rescue Beacon: x, z, radius
LOW = 0.3  # the trim's rim height: allowed in the clear columns
MUZZLE_CLEAR = 0.5
TARPIT_MAX = 0.8
VENT_CLEAR = 1.1
LOOK = ((215, 175, 60), (235, 225, 200))  # Skins GOLD_RUSH colour, accent

COLORS = {
    "gold": (230, 172, 40),
    "glow": (255, 232, 128),
    "timber": (98, 64, 36),
    "iron": (62, 64, 70),
}


def _load(path, name):
    spec = importlib.util.spec_from_file_location(name, path)
    mod = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(mod)
    return mod


K = None  # _kit, set by build()


def _put(objs, at=(0, 0, 0), yaw=0.0):
    for o in objs:
        K._place(o, at, (0, yaw, 0) if yaw else None)
    return objs


def _rot(v, yaw):
    """Rotate a local (x, z) offset by yaw degrees about Y, the way K._place does."""
    a = math.radians(yaw)
    x, y, z = v
    return (x * math.cos(a) + z * math.sin(a), y, -x * math.sin(a) + z * math.cos(a))


def _at(at, v, yaw=0.0):
    r = _rot(v, yaw)
    return (at[0] + r[0], at[1] + r[1], at[2] + r[2])


# ---------------------------------------------------------------- props (Roblox studs) ----

def nugget(k, c, s=0.12, glow=False, seed=0):
    """A lumpy gold nugget (20 tris)."""
    r = (s * (1.0 + 0.15 * ((seed * 7) % 3 - 1)), s * 0.78, s * (0.9 + 0.1 * (seed % 2)))
    k.add("glow" if glow else "gold", K.ell(c, r, 5, 3, rot=(8 * (seed % 3), 37 * seed, 0)))


def pile(k, c, r=0.3, n=6, s=None, glow_top=True, seed=0):
    """A heap of nuggets: a ring of n round a top one (glowing)."""
    s = s or r * 0.42
    x, y, z = c
    for i in range(n):
        a = 2 * math.pi * (i + 0.3 * seed) / n
        nugget(k, (x + math.cos(a) * r * 0.62, y + s * 0.7, z + math.sin(a) * r * 0.62), s, False, seed + i)
    nugget(k, (x, y + s * 1.6, z), s * 1.15, glow_top, seed + n)


def pickaxe(k, a, b, side, head="iron", r=0.035, length=0.3):
    """A pickaxe: handle a -> b, a curved head at b along `side` (unit, square to the handle)."""
    k.add("timber", K.rod(a, b, r, 6))
    ax = [bb - aa for aa, bb in zip(a, b)]
    n = math.sqrt(sum(v * v for v in ax))
    ax = [v / n for v in ax]
    for sg in (1, -1):
        tip = tuple(b[i] + sg * side[i] * length - ax[i] * length * 0.28 for i in range(3))
        k.add(head, K.rod(b, tip, r * 1.5, 6, top=0.25))
    k.add(head, K.rod(tuple(b[i] - ax[i] * 0.03 for i in range(3)), tuple(b[i] + ax[i] * 0.05 for i in range(3)), r * 1.9, 6))


def pan(k, c, r=0.26, tilt=(0, 0, 0), glow=3):
    """A prospector's pan (iron) with gold flakes glinting in it."""
    k.add("iron", K.cyl(c, r * 0.62, 0.07, 10, top=1.6, bevel=0.0, rot=tilt))
    for i in range(glow):
        a = 2 * math.pi * i / max(1, glow) + 0.4
        off = _tilt((math.cos(a) * r * 0.32, 0.05, math.sin(a) * r * 0.32), tilt)
        k.add("glow", K.ell((c[0] + off[0], c[1] + off[1], c[2] + off[2]), (0.05, 0.03, 0.045), 6, 3))


def _tilt(v, rot):
    """Euler XYZ (degrees) on a local vector - the same as K._place's rotation."""
    from mathutils import Euler, Vector
    w = Euler([math.radians(a) for a in rot], "XYZ").to_matrix() @ Vector(v)
    return (w.x, w.y, w.z)


def rails(k, a, b, gauge=0.34, sleepers=3):
    """A short mine track a -> b on the ground (iron rails on timber sleepers)."""
    dx, dz = b[0] - a[0], b[2] - a[2]
    n = math.hypot(dx, dz)
    px, pz = -dz / n * gauge / 2, dx / n * gauge / 2
    y = a[1]
    for sg in (1, -1):
        k.add("iron", K.bar((a[0] + sg * px, y + 0.07, a[2] + sg * pz), (b[0] + sg * px, y + 0.07, b[2] + sg * pz), 0.05, 0.05, 0.0))
    for i in range(sleepers):
        t = (i + 0.5) / sleepers
        cx, cz = a[0] + dx * t, a[2] + dz * t
        k.add("timber", K.bar((cx - px * 1.45, y + 0.025, cz - pz * 1.45), (cx + px * 1.45, y + 0.025, cz + pz * 1.45), 0.1, 0.05, 0.0))


def cart(k, at, yaw=0.0, s=1.0, heap=True):
    """An ore cart heaped with gold, long axis along local x, sitting on the ground at `at`
    (wheels on rails 0.07 up)."""
    L, W, H, y0 = 0.62 * s, 0.4 * s, 0.3 * s, 0.1 * s
    k.add("timber", *_put([K.rbox((0, y0 + H / 2, 0), (L, H, W), bevel=0.0, taper=(1.16, 1.18))], at, yaw))
    k.add("iron", *_put([K.rbox((0, y0 + H - 0.02 * s, 0), (L * 1.2, 0.05 * s, W * 1.22), bevel=0.0),
                         K.rbox((0, y0 + H * 0.35, 0), (L * 1.06, 0.045 * s, W * 1.08), bevel=0.0)], at, yaw))
    wheels = [K.cyl((x * L * 0.32, 0.1 * s + 0.02, z * W * 0.5), 0.1 * s, 0.05 * s, 6, bevel=0.0, rot=(90, 0, 0))
              for x in (-1, 1) for z in (-1, 1)]
    k.add("iron", *_put(wheels, at, yaw))
    if heap:
        k.add("gold", *_put([K.ell((0, y0 + H, 0), (L * 0.5, 0.16 * s, W * 0.52), 8, 4)], at, yaw))
        for i, (x, z) in enumerate(((-0.12, 0.05), (0.1, -0.06), (0.02, 0.08))):
            p = _at(at, (x * s, y0 + H + 0.12 * s, z * s), yaw)
            nugget(k, p, 0.075 * s, glow=i < 2, seed=i + 3)


def crest(k, at, yaw=0.0, s=1.0, picks=True):
    """A gold-leaf crest: a shield plate on a timber backing, crossed pickaxes, laurel sprigs and
    a glowing nugget boss. Local: faces -Z, `at` = the plate's centre (back face at z 0)."""
    objs_t, objs_g, objs_i, objs_glow = [], [], [], []
    objs_t.append(K.rbox((0, 0.0, 0.035 * s), (0.56 * s, 0.62 * s, 0.05 * s), bevel=0.0, taper=(1.45, 1.0)))
    objs_t.append(K.rbox((0, -0.36 * s, 0.035 * s), (0.3 * s, 0.3 * s, 0.05 * s), bevel=0.0, rot=(0, 0, 45)))
    objs_g.append(K.rbox((0, 0.01 * s, -0.01 * s), (0.4 * s, 0.46 * s, 0.05 * s), bevel=0.0, taper=(1.5, 1.0)))
    objs_g.append(K.rbox((0, -0.33 * s, -0.01 * s), (0.21 * s, 0.21 * s, 0.05 * s), bevel=0.0, rot=(0, 0, 45)))
    for deg in (-30, 10, 170, 210):  # laurel sprigs round the plate
        a = math.radians(deg)
        objs_g.append(K.ell((math.cos(a) * 0.33 * s, math.sin(a) * 0.33 * s - 0.02 * s, -0.02 * s),
                            (0.12 * s, 0.05 * s, 0.025 * s), 5, 3, rot=(0, 0, deg + 90)))
    if picks:
        for sg in (-1, 1):
            a, b = (-sg * 0.22 * s, -0.2 * s, -0.06 * s), (sg * 0.18 * s, 0.22 * s, -0.06 * s)
            objs_t.append(K.rod(a, b, 0.025 * s, 4))
            for hs in (1, -1):
                tip = (b[0] + hs * 0.13 * s, b[1] + sg * hs * 0.11 * s - 0.03 * s, -0.06 * s)
                objs_i.append(K.rod(b, tip, 0.035 * s, 4, top=0.25))
    objs_glow.append(K.ell((0, 0.03 * s, -0.07 * s), (0.11 * s, 0.1 * s, 0.06 * s), 6, 3))
    k.add("timber", *_put(objs_t, at, yaw))
    k.add("gold", *_put(objs_g, at, yaw))
    if objs_i:
        k.add("iron", *_put(objs_i, at, yaw))
    k.add("glow", *_put(objs_glow, at, yaw))


def sluice(k, a, b, w=0.3, legs=True, riffles=3):
    """A sluice box: a timber trough from a (high end) to b (low end) on legs, gold riffles and
    glowing nuggets caught at the low end. a, b = the trough floor's centre line."""
    dx, dy, dz = b[0] - a[0], b[1] - a[1], b[2] - a[2]
    n = math.hypot(dx, dz)
    px, pz = -dz / n * w / 2, dx / n * w / 2
    k.add("timber", K.bar(a, b, w, 0.04, 0.0))
    for sg in (1, -1):
        k.add("timber", K.bar((a[0] + sg * px, a[1] + 0.07, a[2] + sg * pz), (b[0] + sg * px, b[1] + 0.07, b[2] + sg * pz), 0.04, 0.14, 0.0,
                              up=(px, 0, pz)))
    for i in range(riffles):
        t = (i + 0.6) / (riffles + 0.4)
        cx, cy, cz = a[0] + dx * t, a[1] + dy * t + 0.035, a[2] + dz * t
        k.add("gold", K.bar((cx - px * 0.85, cy, cz - pz * 0.85), (cx + px * 0.85, cy, cz + pz * 0.85), 0.035, 0.035, 0.0))
    t = 0.92
    nugget(k, (a[0] + dx * t, a[1] + dy * t + 0.06, a[2] + dz * t), 0.06, glow=True, seed=1)
    if legs:
        for t in (0.12, 0.88):
            cx, cy, cz = a[0] + dx * t, a[1] + dy * t, a[2] + dz * t
            for sg in (1, -1):
                k.add("timber", K.rod((cx + sg * px * 0.8, 0.0, cz + sg * pz * 0.8), (cx + sg * px * 0.8, cy, cz + sg * pz * 0.8), 0.025, 5))


def ingots(k, at, yaw=0.0, rows=((0, 0, 0), (0, 0, 0.22), (0, 0.13, 0.11)), glow_top=True):
    """Stacked gold ingots (tapered bars), local long axis along x."""
    for i, (x, y, z) in enumerate(rows):
        g = "glow" if (glow_top and i == len(rows) - 1) else "gold"
        k.add(g, *_put([K.rbox((x, y + 0.065, z), (0.34, 0.13, 0.18), bevel=0.0, taper=(0.78, 0.7))], at, yaw))


def pennant(k, base, h, yaw=0.0, length=0.6, finial=True):
    """A timber pole with a swallow-tailed gold pennant (local: flies along +x) and a glowing
    nugget finial."""
    top = (base[0], base[1] + h, base[2])
    k.add("timber", K.rod(base, top, 0.035, 6))
    fl = [K.rbox((length / 2, -0.18, 0), (length, 0.26, 0.03), bevel=0.0, rot=(0, 0, 0), taper=(1.0, 1.0)),
          K.rbox((length * 0.9, -0.09, 0), (0.18, 0.12, 0.03), bevel=0.0, rot=(0, 0, 25)),
          K.rbox((length * 0.9, -0.27, 0), (0.18, 0.12, 0.03), bevel=0.0, rot=(0, 0, -25))]
    k.add("gold", *_put(fl, top, yaw))
    if finial:
        k.add("glow", K.ell((top[0], top[1] + 0.06, top[2]), (0.07, 0.08, 0.07), 6, 3))


def lantern(k, c, s=1.0):
    """A miner's lantern: an iron cap and base round a glowing glass."""
    x, y, z = c
    k.add("iron", K.cyl((x, y - 0.1 * s, z), 0.08 * s, 0.04 * s, 6, bevel=0.0),
          K.cyl((x, y + 0.11 * s, z), 0.08 * s, 0.05 * s, 6, top=0.5, bevel=0.0),
          K.ring((x, y + 0.17 * s, z), 0.04 * s, 0.012 * s, 6, 3, rot=(90, 0, 0)))
    k.add("glow", K.cyl((x, y, z), 0.06 * s, 0.17 * s, 6, bevel=0.0))


def barrel(k, c, r=0.17, h=0.36, heap=True):
    """A timber barrel with iron hoops, brimming with gold."""
    x, y, z = c
    k.add("timber", K.cyl((x, y + h / 2, z), r, h, 8, bevel=0.0))
    k.add("iron", K.cyl((x, y + h * 0.22, z), r * 1.04, 0.04, 8, bevel=0.0), K.cyl((x, y + h * 0.8, z), r * 1.04, 0.04, 8, bevel=0.0))
    if heap:
        k.add("gold", K.ell((x, y + h, z), (r * 0.9, 0.07, r * 0.9), 8, 3))
        nugget(k, (x + 0.03, y + h + 0.06, z - 0.02), 0.06, glow=True, seed=2)


def plaque(k, at, yaw=0.0, w=0.7, h=0.24):
    """A gold-framed timber name board (faces local -Z, back at z 0) with a glowing nugget at
    each end."""
    k.add("timber", *_put([K.rbox((0, 0, 0.025), (w, h, 0.05), bevel=0.0)], at, yaw))
    k.add("gold", *_put([K.rbox((0, h / 2, 0.0), (w + 0.04, 0.04, 0.06), bevel=0.0),
                         K.rbox((0, -h / 2, 0.0), (w + 0.04, 0.04, 0.06), bevel=0.0),
                         K.rbox((0, 0, -0.01), (w * 0.55, 0.05, 0.03), bevel=0.0)], at, yaw))
    k.add("glow", *_put([K.ell((sg * (w / 2 - 0.02), 0, -0.04), (0.06, 0.07, 0.04), 6, 3) for sg in (-1, 1)], at, yaw))


# ---------------------------------------------------------------- build + checks ----------

def _tower_art(lp, tower, stage):
    return _load(TOWER / f"_{tower.lower()}.py", f"_gr_{tower}_{stage}").build(lp, stage)


def _muzzle(model):
    for o in model["pieces"]:
        if model.get("roles", {}).get(o.name) == "muzzle":
            vs = [v.co for v in o.data.vertices]
            c = [sum(v[i] for v in vs) / len(vs) for i in range(3)]
            return (c[0], c[2] + 2.5, -c[1])  # Blender -> Roblox
    return None


def _rbx(v):
    return v.x, v.z + 2.5, -v.y


def _check(lp, key, tower, pieces, arts):
    import bpy
    from mathutils.bvhtree import BVHTree

    total = sum(lp.tris(o) for o in pieces)
    assert total <= CAP, f"{key}: {total} tris > the set-piece cap {CAP}"
    verts = [_rbx(v.co) for o in pieces for v in o.data.vertices]
    top = max(v[1] for v in verts)
    for x, y, z in verts:
        for cx, cz, r in CLEAR:
            assert (x - cx) ** 2 + (z - cz) ** 2 > r * r or y <= LOW + 1e-3, \
                f"{key}: a vertex ({x:.2f}, {y:.2f}, {z:.2f}) in the clear column {cx, cz}"
        if tower == "VENT":
            assert x * x + z * z > VENT_CLEAR ** 2, f"{key}: ({x:.2f}, {z:.2f}) in the Vent's middle"
    if tower == "TARPIT":
        assert top <= TARPIT_MAX + 1e-3, f"{key}: {top:.2f} high > {TARPIT_MAX} (Tar Pit lies on the track)"
    fit = []
    deps = bpy.context.evaluated_depsgraph_get()
    for stage, art in arts:
        m = _muzzle(art)
        if m:
            for x, y, z in verts:
                d = math.dist((x, y, z), m)
                assert d >= MUZZLE_CLEAR, f"{key}: {d:.2f} from the stage-{stage} muzzle {tuple(round(c, 2) for c in m)}"
                if m[2] < -0.9:  # a front-firing muzzle: nothing in its lane
                    assert not (abs(x - m[0]) < 0.3 and abs(y - m[1]) < 0.3 and z < m[2]), f"{key}: in front of the muzzle"
        trees = [BVHTree.FromObject(o, deps) for o in art["pieces"]]
        inside = 0
        for o in pieces:
            for v in o.data.vertices:
                for tr in trees:
                    loc, nrm, _, dist = tr.find_nearest(v.co)
                    if loc is not None and dist > 0.03 and (v.co - loc).dot(nrm) < 0:
                        inside += 1
                        break
        fit.append(f"s{stage} {100 * inside / max(1, len(verts)):.0f}%")
    print(f"ART set piece {key}: {total} tris, top {top:.2f}, inside the tower art: {', '.join(fit)}")
    return total


def build(lp, tower, design, display):
    """design(k) places the props (this module's functions) round `tower`'s art."""
    global K
    import bpy

    K = _load(TOWER / "_kit.py", "_gr_kit")
    key = f"GOLD_RUSH_{tower}"
    k = K.Kit(lp)
    design(k)
    pieces, box = k.finish(target=10 ** 6)  # never decimated: _check holds the cap
    shown = int(os.environ.get("GR_STAGE", "0"))
    arts = []
    context = []
    base = _tower_art(lp, tower, shown)  # first, so its piece names stay unsuffixed
    for o in base["pieces"]:  # preview-only: the tower in the set's paint (Skins.paintTower)
        lp.paint(o, LOOK[0] if base["groups"].get(o.name, o.name) == "body" else LOOK[1])
        context.append(o)
    arts.append((shown, base))
    extra = []
    for stage in (0, 1, 2):
        if stage != shown:
            art = _tower_art(lp, tower, stage)
            arts.append((stage, art))
            extra += art["pieces"]
    arts.sort(key=lambda a: a[0])
    tris = _check(lp, key, tower, pieces, arts)
    for o in extra:
        mesh = o.data
        bpy.data.objects.remove(o)
        bpy.data.meshes.remove(mesh)
    if tower != "TARPIT":  # the trim is never worn on Tar Pit (#456)
        sets = _load(TOWER / "variants" / "_sets.py", "_gr_sets")
        trim = _load(TOWER / "SET_GOLD_RUSH.py", "_gr_trim")
        tk = K.Kit(lp)
        trim.design(tk, K)
        tpieces, _ = tk.finish(target=10 ** 6)
        tcol = {"gold": (232, 186, 70), "timber": (110, 76, 46), "metal": (92, 94, 98)}
        for o in tpieces:
            lp.paint(o, tcol.get(tk.groups.get(o.name.split(".")[0], ""), (200, 200, 200)))
            context.append(o)
        del sets
    print(f"ART set piece {key} over {tower} stage {shown} (preview)")
    return {
        "batch": BATCH,
        "budget": "tower",
        "tower": f"SET_{key}",
        "stage": 0,
        "box": box,
        "pieces": pieces,
        "groups": dict(k.groups),
        "roles": {},
        "colors": dict(COLORS),
        "context": context,
        "meta": {"set": "GOLD_RUSH", "display": display, "setPiece": tower, "preview": tower, "cap": CAP},
    }

