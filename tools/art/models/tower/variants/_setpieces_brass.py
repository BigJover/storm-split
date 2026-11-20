"""Brass Gear per-tower set pieces (#457, batch 11e2): `tower/SET_BRASS_GEAR_<TOWER>`, worn over the
tower's art at every stage on top of the Brass Gear trim (SET_BRASS_GEAR.py). A steam-works kit:
copper boilers with riveted bands, iron smokestacks with flared brass caps, big brass cogs bolted to
walls, pressure gauges, valve wheels and copper pipe runs. The set paints the tower brass + grey, so
the pieces lean on copper, polished brass, black iron and red valve wheels to read over it.

Placement comes from SPOTS (variants/_setpieces_bm_shapes.py); a few towers add their own extras.
Checked and previewed by variants/_setpiece_common.py.
"""

import importlib.util
import math
from pathlib import Path

_here = Path(__file__).resolve().parent


def _load(name):
    spec = importlib.util.spec_from_file_location(name, _here / f"{name}.py")
    mod = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(mod)
    return mod


C = _load("_setpiece_common")
S = _load("_setpieces_bm_shapes")
S.near_inside(C)

COLORS = {
    "iron": (46, 44, 50),
    "copper": (192, 104, 56),
    "brass2": (238, 194, 92),
    "cream": (242, 234, 206),
    "red": (178, 42, 34),
    "steam": (238, 238, 234),
}


# --- motifs ----------------------------------------------------------------------------------------
def stack(k, K, x, z, y0, h, r=0.17, puffs=2):
    """An iron smokestack with a flared brass cap, two brass bands and a white steam puff (as much
    of it as fits under the Body's 5-stud top)."""
    top = y0 + h
    for i in range(puffs):
        py, pr = top + 0.2 + i * 0.3, r * (1.5 + 0.35 * i)
        pr = min(pr, 1.49 - abs(x), 1.49 - abs(z))  # stays inside the Body's footprint
        if py + pr * 0.75 <= 4.97:
            k.add("steam", K.ell((x, py, z), (pr, pr * 0.75, pr), 6, 4))
    k.add("iron", K.cyl((x, y0 + (h - 0.2) / 2, z), r, h - 0.2, 8, bevel=0.0))
    k.add("brass2", K.cyl((x, top - 0.11, z), r * 1.05, 0.22, 8, top=1.6, bevel=0.0),
          *[K.cyl((x, y, z), r * 1.22, 0.07, 8, bevel=0.0) for y in (y0 + h * 0.35, y0 + h * 0.7)])
    k.add("iron", K.cyl((x, top + 0.005, z), r * 1.35, 0.03, 8, bevel=0.0))  # the dark mouth


def gauge(k, K, c, facing, r=0.16):
    """A pressure gauge mounted on the surface point c (it stands 0.095 out of it): brass bezel,
    cream face, red needle."""
    disc, _ = S.rots(facing)
    k.add("brass2", K.cyl(S.off(c, facing, 0.03), r, 0.06, 8, bevel=0.0, rot=disc))
    k.add("cream", K.cyl(S.off(c, facing, 0.065), r * 0.78, 0.03, 8, bevel=0.0, rot=disc))
    n = S.normal(facing)
    tip = S.off(c, facing, 0.085)
    if facing in ("-z", "+z"):
        a, b = (tip[0] - r * 0.1, tip[1] - r * 0.1, tip[2]), (tip[0] + r * 0.5, tip[1] + r * 0.45, tip[2])
    elif facing == "y":
        a, b = (tip[0] - r * 0.1, tip[1], tip[2]), (tip[0] + r * 0.5, tip[1], tip[2] - r * 0.45)
    else:
        a, b = (tip[0], tip[1] - r * 0.1, tip[2] - r * 0.1), (tip[0], tip[1] + r * 0.45, tip[2] + r * 0.5)
    k.add("red", K.bar(a, b, r * 0.14, 0.02, bevel=0.0, up=n))


def gear(k, K, c, facing, r, teeth=8, t=0.08, hub=True, group="brass2"):
    """A big cog bolted flat to a wall (or lying flat), iron hub."""
    _, flat = S.rots(facing)
    k.add(group, S.prism(K, S.gear_pts(r, teeth), t, c, flat))
    if hub:
        disc, _ = S.rots(facing)
        k.add("iron", K.cyl(S.off(c, facing, t / 2), r * 0.3, 0.07, 6, bevel=0.0, rot=disc))


def valve(k, K, c, facing, r=0.16):
    """A red valve wheel with a cross of spokes."""
    disc, _ = S.rots(facing)
    k.add("red", K.ring(c, r, 0.03, 8, 3, rot=disc))
    if facing in ("-z", "+z"):
        spokes = [((c[0] - r, c[1], c[2]), (c[0] + r, c[1], c[2])), ((c[0], c[1] - r, c[2]), (c[0], c[1] + r, c[2]))]
    elif facing == "y":
        spokes = [((c[0] - r, c[1], c[2]), (c[0] + r, c[1], c[2])), ((c[0], c[1], c[2] - r), (c[0], c[1], c[2] + r))]
    else:
        spokes = [((c[0], c[1], c[2] - r), (c[0], c[1], c[2] + r)), ((c[0], c[1] - r, c[2]), (c[0], c[1] + r, c[2]))]
    k.add("iron", *[K.rod(a, b, 0.022, 4) for a, b in spokes])


def boiler(k, K, x, z, y0, r=0.28, h=0.9, face="-z"):
    """A riveted copper boiler: drum, domed top, two brass bands, a gauge on its face."""
    k.add("copper", K.cyl((x, y0 + h / 2, z), r, h, 10, bevel=0.0),
          K.ell((x, y0 + h, z), (r, r * 0.55, r), 10, 3))
    k.add("brass2", *[K.cyl((x, y0 + f * h, z), r * 1.07, 0.07, 10, bevel=0.0) for f in (0.2, 0.75)])
    n = S.normal(face)
    gauge(k, K, (x + n[0] * (r - 0.01), y0 + h * 0.5, z + n[2] * (r - 0.01)), face, 0.14)


def pipe(k, K, pts, r=0.05):
    """A copper pipe run through pts, brass flanges at the bends."""
    k.add("copper", *[K.rod(a, b, r, 6) for a, b in zip(pts, pts[1:])])
    k.add("brass2", *[K.cyl(p, r * 1.6, r * 1.6, 6, bevel=0.0) for p in pts[1:-1]])


def ring_gear(k, K, c, r, teeth=18, skip=None, t=0.07):
    """A big flat toothed ring lying round something (a turntable, a pole): torus rim + teeth."""
    x, y, z = c
    k.add("brass2", K.ring(c, r, t, teeth, 3))
    out = []
    for i in range(teeth):
        a = 2 * math.pi * (i + 0.5) / teeth
        px, pz = x + (r + t * 1.6) * math.cos(a), z + (r + t * 1.6) * math.sin(a)
        if skip and skip(px, pz):
            continue
        out.append(K.rbox((px, y, pz), (t * 2.2, t * 1.6, t * 1.6), bevel=0.0, rot=(0, -math.degrees(a), 0)))
    k.add("brass2", *out)


def stack_with_boiler(k, K, spot, face="-z"):
    x, z, y0, h = spot["post"]
    base = spot.get("base")
    if base and abs(base[0] - x) < 1e-6 and abs(base[1] - z) < 1e-6:
        boiler(k, K, x, z, base[2], spot.get("br", 0.34), 0.95, face)
        stack(k, K, x, z, base[2] + 1.05, h - 1.05 - (base[2] - y0), 0.14)
    else:
        stack(k, K, x, z, y0, h)


def walls(k, K, spot, kinds=None):
    for i, (c, facing, r) in enumerate(spot["walls"]):
        kind = (kinds or ["gear"] * 9)[i]
        if kind == "gear":  # a cog + a gauge on its hub; slim (hub only) right at the Body's edge
            slim = max(abs(a * b) for a, b in zip(c, S.normal(facing))) > 1.33
            if slim:  # pull it in so the hub stays inside the Body (+-1.5)
                c = tuple(min(1.41, a) if n > 0 else max(-1.41, a) if n < 0 else a for a, n in zip(c, S.normal(facing)))
            gear(k, K, c, facing, r, 8 if r < 0.4 else 10, t=0.1)
            if not slim:
                gauge(k, K, S.off(c, facing, 0.05), facing, r * 0.32)
        elif kind == "plate":  # riveted plate + gauge + valve
            disc, flat = S.rots(facing)
            w = r * 2
            k.add("iron", K.rbox(c, (w, w * 0.75, 0.05), bevel=0.0, rot=flat))
            gauge(k, K, S.off(c, facing, 0.025), facing, r * 0.45)


# --- the eighteen pieces ---------------------------------------------------------------------------
def _scout(k, K, s):
    x, z, y0, h = s["post"]
    k.add("iron", K.rbox((x, y0 + 0.04, z), (0.42, 0.08, 0.42), bevel=0.0))  # a riveted roof plate
    stack(k, K, x, z, y0 + 0.08, h - 0.08)
    gauge(k, K, (x - 0.13, y0 + 0.45, z), "-x", 0.11)
    walls(k, K, s, ["plate", "gear"])
    pipe(k, K, [(-1.33, 0.02, 0.42), (-1.33, 1.25, 0.42), (-1.24, 1.32, 0.42)], 0.04)  # a down-pipe to the ground


def _sniper(k, K, s):
    boiler(k, K, 0.0, 0.25, 0.0, 0.36, 1.0)
    stack(k, K, 0.0, 0.25, 1.1, 1.6, 0.12)
    walls(k, K, s, ["gear", "gear"])
    pipe(k, K, [(-0.36, 0.6, 0.25), (-1.3, 0.6, 0.25)], 0.05)


def _grenadier(k, K, s):
    stack_with_boiler(k, K, s)
    ring_gear(k, K, (0.0, 0.07, 0.2), 0.8, 12, t=0.06)
    valve(k, K, (0.98, 0.98, 0.15), "-z", 0.12)


def _chiller(k, K, s):
    stack_with_boiler(k, K, s, "-x")
    walls(k, K, s, ["plate", "gear"])
    pipe(k, K, [(0.72, 0.55, -0.82), (0.72, 0.55, -0.66)], 0.06)


def _quartermaster(k, K, s):
    stack_with_boiler(k, K, s)
    walls(k, K, s)
    valve(k, K, (1.08, 0.5, 0.0), "-z", 0.12)


def _hospital(k, K, s):
    stack_with_boiler(k, K, s, "-x")
    walls(k, K, s, ["gear"])


def _armory(k, K, s):
    stack_with_boiler(k, K, s, "-z")
    walls(k, K, s)
    gear(k, K, (1.12, 0.55, -0.2), "-z", 0.3, 8)


def _coil(k, K, s):
    x, z, y0 = s["base"]
    boiler(k, K, x, z, y0, 0.22, 0.65, "-z")
    stack(k, K, x, z, y0 + 0.72, 0.9, 0.09)
    walls(k, K, s)
    pipe(k, K, [(1.36, 0.6, 0.05), (1.36, 0.6, 0.6), (1.36, 0.02, 0.6)], 0.05)  # conduit down the deck edge


def _falcon(k, K, s):
    stack_with_boiler(k, K, s, "-z")
    walls(k, K, s)


def _ballista(k, K, s):
    ring_gear(k, K, (0.0, 0.42, 0.0), 1.22, 22, skip=lambda px, pz: pz < -1.0 or (px > 0.75 and pz > 0.75), t=0.07)
    gauge(k, K, (0.0, 0.62, 1.32), "+z", 0.14)
    k.add("iron", K.rod((0.0, 0.0, 1.28), (0.0, 0.62, 1.28), 0.04, 6))  # the gauge's post


def _tarpit(k, K, s):
    x, z, y0 = s["base"]
    k.add("iron", K.rbox((x, y0 + 0.2, z), (0.36, 0.4, 0.5), bevel=0.0))
    valve(k, K, (x, y0 + 0.44, z), "y", 0.16)
    gauge(k, K, (x, y0 + 0.22, z - 0.26), "-z", 0.12)
    pipe(k, K, [(x - 0.18, 0.2, z + 0.1), (0.7, 0.2, 0.75), (0.2, 0.2, 1.05)], 0.06)
    for c, r in s["flats"]:
        gear(k, K, c, "y", r, 10)


def _resin(k, K, s):
    stack_with_boiler(k, K, s, "-z")
    pipe(k, K, [(0.62, 0.55, 0.5), (0.45, 0.55, 0.5), (0.45, 1.25, 0.45)], 0.05)
    gear(k, K, (1.22, 0.5, 0.42), "+x", 0.22, 8)


def _raptor(k, K, s):
    stack_with_boiler(k, K, s)
    walls(k, K, s)


def _totem(k, K, s):
    for c, r in s["flats"]:
        ring_gear(k, K, c, 0.5, 14, t=0.06)
    gauge(k, K, (-0.43, 0.8, 0.05), "-x", 0.14)
    valve(k, K, (0.42, 0.8, 0.05), "+x", 0.13)
    pipe(k, K, [(0.4, 0.02, -0.2), (0.4, 0.8, -0.2)], 0.045)  # the valve's feed, up out of the ground
    gear(k, K, (0.0, 3.7, 0.52), "+z", 0.7, 12, t=0.1)  # a big clockwork cog behind the pole
    k.add("copper", K.rod((0.0, 3.7, 0.3), (0.0, 3.7, 0.5), 0.09, 6))


def _blimp(k, K, s):
    x, z, y0 = s["base"]
    k.add("iron", K.rbox((x, y0 + 0.25, z), (0.3, 0.5, 0.7), bevel=0.0))
    k.add("copper", K.cyl((x, y0 + 0.66, z), 0.28, 0.56, 10, bevel=0.0, rot=(90, 0, 0)))
    gear(k, K, (x + 0.02, y0 + 0.66, z - 0.34), "-z", 0.36, 8)
    stack(k, K, x - 0.1, z + 0.55, y0, 2.2, 0.13)
    walls(k, K, s, ["plate"])


def _meteor(k, K, s):
    stack_with_boiler(k, K, s, "-z")
    for c, r in s["flats"]:
        ring_gear(k, K, c, 0.9, 14, t=0.05)
    walls(k, K, s, ["plate"])


def _vent(k, K, s):
    x, z, y0, h = s["post"]
    stack(k, K, x, z, y0, h, 0.11)  # thin: its flared cap stays out of the basalt column's ring
    gauge(k, K, (x, 0.9, z - 0.12), "-z", 0.11)
    x2, z2, y2, h2 = s["post2"]
    stack(k, K, x2, z2, y2, h2, 0.1)
    gear(k, K, (x2, 1.1, z2 + 0.08), "+z", 0.3, 8)
    valve(k, K, (x + 0.13, 0.7, z), "+x", 0.11)


def _ranger(k, K, s):
    stack_with_boiler(k, K, s, "-z")
    walls(k, K, s)
    pipe(k, K, [(0.9, 0.45, -0.05), (0.84, 0.45, -0.05)], 0.05)


DESIGNS = {
    "SCOUT": _scout, "SNIPER": _sniper, "GRENADIER": _grenadier, "CHILLER": _chiller,
    "QUARTERMASTER": _quartermaster, "HOSPITAL": _hospital, "ARMORY": _armory, "COIL": _coil,
    "FALCON": _falcon, "BALLISTA": _ballista, "TARPIT": _tarpit, "RESIN": _resin, "RAPTOR": _raptor,
    "TOTEM": _totem, "BLIMP": _blimp, "METEOR": _meteor, "VENT": _vent, "RANGER": _ranger,
}


def build(lp, tower):
    spot = S.SPOTS[tower]
    return C.setpiece(lp, "BRASS_GEAR", tower, lambda k, K: DESIGNS[tower](k, K, spot), COLORS)
