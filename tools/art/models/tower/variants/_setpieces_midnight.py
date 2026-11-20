"""Midnight per-tower set pieces (#457, batch 11e2): `tower/SET_MIDNIGHT_<TOWER>`, worn over the
tower's art at every stage on top of the Midnight trim (SET_MIDNIGHT.py). A night-watch kit: black
iron poles with crescent-moon finials flying deep indigo swallowtail banners (a pale-gold crescent
and a silver star on each), lanterns with a warm `glow` core (Neon in game), moon crests (a navy
roundel, silver rim, gold crescent) on walls, and silver stars laid round turntables and pits.
The set paints the tower near-black + ice blue, so the pieces lean on indigo, silver and gold.

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
    "night": (30, 28, 46),
    "cloth": (108, 70, 204),
    "silver": (216, 224, 242),
    "moon": (246, 222, 140),
    "glow": (255, 224, 140),
}


# --- motifs ----------------------------------------------------------------------------------------
def finial(k, K, x, y, z, r=0.22, facing="-z"):
    """A crescent moon standing on a pole top, horns up (y = the pole top)."""
    _, flat = S.rots(facing)
    k.add("night", K.ell((x, y + 0.04, z), (0.07, 0.07, 0.07), 6, 3))
    k.add("moon", S.prism(K, S.crescent_pts(r, tilt=90), 0.06, (x, y + 0.08 + r, z), flat))


def emblem(k, K, c, facing, r):
    """A gold crescent with a silver star in its arms, on a cloth / roundel face at c."""
    _, flat = S.rots(facing)
    k.add("moon", S.prism(K, S.crescent_pts(r, tilt=20), 0.03, S.off(c, facing, 0.015), flat))
    n = S.normal(facing)
    side = (1, 0, 0) if facing in ("-z", "+z") else (0, 0, 1)
    sc = tuple(a + b * r * 0.55 * (-1 if facing in ("+z", "-x") else 1) for a, b in zip(c, side))
    sc = (sc[0], sc[1] + r * 0.25, sc[2])
    k.add("silver", S.prism(K, S.star_pts(r * 0.38), 0.03, S.off(sc, facing, 0.015), flat))


def lantern(k, K, x, y, z, s=1.0):
    """A lantern standing on (x, y, z): base, glowing core, four iron posts, pyramid cap, ring."""
    k.add("night", K.rbox((x, y + 0.04 * s, z), (0.3 * s, 0.08 * s, 0.3 * s), bevel=0.0),
          K.rbox((x, y + 0.5 * s, z), (0.34 * s, 0.16 * s, 0.34 * s), bevel=0.0, taper=(0.3, 0.3)),
          *[K.rod((x + dx * 0.12 * s, y + 0.08 * s, z + dz * 0.12 * s), (x + dx * 0.12 * s, y + 0.42 * s, z + dz * 0.12 * s), 0.02 * s, 4)
            for dx in (-1, 1) for dz in (-1, 1)])
    k.add("glow", K.cyl((x, y + 0.25 * s, z), 0.1 * s, 0.32 * s, 6, bevel=0.0))
    k.add("silver", K.ring((x, y + 0.62 * s, z), 0.05 * s, 0.015 * s, 6, 3))


def banner(k, K, x, z, y0, h, face="-z", w=0.8, drop=1.3, hang=True):
    """A black iron pole with a crescent finial, a crossbar and an indigo swallowtail banner (gold
    crescent + silver star), plus a lantern hung off a bracket at mid-height."""
    top = y0 + h
    drop = min(drop, h - 0.35)
    k.add("night", K.rod((x, y0, z), (x, top, z), 0.06, 6),
          K.cyl((x, y0 + 0.06, z), 0.13, 0.12, 6, bevel=0.0))
    finial(k, K, x, top, z, 0.27, face if face in ("-z", "+z") else "-x")
    side = (1, 0, 0) if face in ("-z", "+z") else (0, 0, 1)
    sx, sz = side[0] * w / 2, side[2] * w / 2
    bar_y = top - 0.12
    k.add("silver", K.rod((x - sx - side[0] * 0.04, bar_y, z - sz - side[2] * 0.04),
                         (x + sx + side[0] * 0.04, bar_y, z + sz + side[2] * 0.04), 0.03, 4))
    n = S.normal(face)
    cc = (x + n[0] * 0.07, bar_y - 0.03, z + n[2] * 0.07)
    _, flat = S.rots(face)
    k.add("cloth", S.prism(K, S.pennant_pts(w, drop, 0.28), 0.04, cc, flat))
    emblem(k, K, (cc[0], cc[1] - drop * 0.36, cc[2]), face, w * 0.32)
    if hang:  # a lantern on a bracket, toward the tower's middle (keeps it inside the Body)
        d = math.hypot(x, z) or 1.0
        lx, lz = x - x / d * 0.3, z - z / d * 0.3
        hy = y0 + h * 0.45
        k.add("night", K.rod((x, hy, z), (lx, hy, lz), 0.025, 4), K.rod((lx, hy, lz), (lx, hy - 0.1, lz), 0.015, 4))
        lantern(k, K, lx, hy - 0.8, lz, 1.15)


def crest(k, K, c, facing, r):
    """A moon crest on a wall: navy roundel, silver rim, gold crescent + silver star."""
    disc, _ = S.rots(facing)
    k.add("cloth", K.cyl(S.off(c, facing, 0.03), r, 0.06, 10, bevel=0.0, rot=disc))
    k.add("silver", K.ring(S.off(c, facing, 0.06), r, 0.035, 10, 3, rot=disc))
    emblem(k, K, S.off(c, facing, 0.06), facing, r * 0.72)


def star_ring(k, K, c, r, n=8, size=0.13, ring=True):
    """Silver stars laid flat round a circle (a turntable's, a pole's), on a thin silver hoop."""
    x, y, z = c
    if ring:
        k.add("silver", K.ring(c, r, 0.03, max(12, n * 2), 3))
    _, flat = S.rots("y")
    k.add("moon", *[S.prism(K, S.star_pts(size), 0.04, (x + r * math.cos(a), y + 0.02, z + r * math.sin(a)), flat)
                    for a in [2 * math.pi * (i + 0.5) / n for i in range(n)]])


def post_banner(k, K, spot, **kw):
    x, z, y0, h = spot["post"]
    banner(k, K, x, z, y0, h - 0.4, spot.get("face", "-z"), **kw)


def walls(k, K, spot):
    for c, facing, r in spot["walls"]:
        c = tuple(min(1.38, a) if n > 0 else max(-1.38, a) if n < 0 else a for a, n in zip(c, S.normal(facing)))
        crest(k, K, c, facing, r * 1.25)


def lantern_post(k, K, x, z, y0, h=1.0, s=1.3):
    k.add("night", K.rod((x, y0, z), (x, y0 + h, z), 0.05, 6), K.cyl((x, y0 + 0.05, z), 0.12, 0.1, 6, bevel=0.0))
    lantern(k, K, x, y0 + h, z, s)


# --- the eighteen pieces ---------------------------------------------------------------------------
def _scout(k, K, s):
    post_banner(k, K, s, hang=False)
    walls(k, K, s)
    k.add("night", K.rod((-1.4, 0.0, 0.15), (-1.4, 0.5, 0.15), 0.05, 6))  # the left crest's post


def _sniper(k, K, s):
    # banners hung from the deck: the front beam (left of the muzzle) and the left side
    for c, face in (((-0.72, 3.15, -1.44), "-z"), ((-1.44, 3.15, 0.0), "-x")):
        _, flat = S.rots(face)
        k.add("night", K.rod(S.off(c, face, -0.02), S.off(c, face, 0.06), 0.03, 4))
        k.add("cloth", S.prism(K, S.pennant_pts(0.62, 1.3, 0.25), 0.04, S.off(c, face, 0.0), flat))
        emblem(k, K, (c[0], c[1] - 0.5, c[2]), face, 0.2)
    lantern_post(k, K, 0.0, 0.25, 0.0, 1.5, 1.4)  # under the deck


def _grenadier(k, K, s):
    post_banner(k, K, s, hang=False)
    lantern(k, K, 0.98, 0.45, -0.3, 1.1)
    star_ring(k, K, (0.0, 0.06, 0.2), 0.75, 6, 0.12)


def _chiller(k, K, s):
    post_banner(k, K, s)
    walls(k, K, s)


def _quartermaster(k, K, s):
    post_banner(k, K, s)
    walls(k, K, s)


def _hospital(k, K, s):
    post_banner(k, K, s)
    walls(k, K, s)


def _armory(k, K, s):
    post_banner(k, K, s)
    walls(k, K, s)


def _coil(k, K, s):
    x, z, y0 = s["base"]
    lantern_post(k, K, x, z, 0.0, 1.65)  # its post stands on the ground beside the deck
    walls(k, K, s)


def _falcon(k, K, s):
    post_banner(k, K, s)
    walls(k, K, s)


def _ballista(k, K, s):
    star_ring(k, K, (0.0, 0.42, 0.0), 1.22, 8, 0.16)
    lantern_post(k, K, 0.0, 1.32, 0.0, 0.42, 0.9)


def _tarpit(k, K, s):
    x, z, y0 = s["base"]
    lantern(k, K, x, y0, z, 1.1)
    for c, r in s["flats"]:
        _, flat = S.rots("y")
        k.add("cloth", K.cyl(c, r, 0.04, 10, bevel=0.0))
        k.add("moon", S.prism(K, S.crescent_pts(r * 0.75, tilt=30), 0.04, (c[0], c[1] + 0.03, c[2]), flat))
        k.add("silver", S.prism(K, S.star_pts(r * 0.3), 0.04, (c[0] + r * 0.32, c[1] + 0.03, c[2] - r * 0.1), flat))
    star_ring(k, K, (0.0, 0.3, 0.0), 1.15, 5, 0.12, ring=False)


def _resin(k, K, s):
    post_banner(k, K, s, hang=False)
    lantern(k, K, 1.15, 0.0, -0.45, 1.25)


def _raptor(k, K, s):
    post_banner(k, K, s)
    walls(k, K, s)


def _totem(k, K, s):
    for c, r in s["flats"]:
        star_ring(k, K, c, 0.55, 6, 0.12)
    walls(k, K, s)
    _, flat = S.rots("+z")  # a big crescent moon behind the pole
    k.add("moon", S.prism(K, S.crescent_pts(0.78, tilt=90), 0.1, (0.0, 3.65, 0.55), flat))
    k.add("night", K.rod((0.0, 3.0, 0.3), (0.0, 3.0, 0.52), 0.06, 6),
          K.rod((0.0, 0.0, 0.42), (0.0, 0.62, 0.42), 0.05, 6))  # an iron stake under the star hoop


def _blimp(k, K, s):
    x, z, y0 = s["base"]
    banner(k, K, x, z, y0, 2.0, "-x", hang=False)
    lantern_post(k, K, x, z + 0.55, y0, 0.9)
    walls(k, K, s)


def _meteor(k, K, s):
    x, z, y0, h = s["post"]
    lantern_post(k, K, x, z, y0, 0.85)
    for c, r in s["flats"]:
        star_ring(k, K, c, 0.95, 8, 0.12)
    walls(k, K, s)


def _vent(k, K, s):
    x, z, y0, h = s["post"]
    banner(k, K, x, z, y0, h, "+x", w=0.5, hang=False)
    x2, z2, y2, h2 = s["post2"]
    banner(k, K, x2, z2, y2, h2, "+z", w=0.5, hang=False)
    lantern(k, K, 1.25, 0.0, 0.55, 1.1)


def _ranger(k, K, s):
    post_banner(k, K, s)
    walls(k, K, s)


DESIGNS = {
    "SCOUT": _scout, "SNIPER": _sniper, "GRENADIER": _grenadier, "CHILLER": _chiller,
    "QUARTERMASTER": _quartermaster, "HOSPITAL": _hospital, "ARMORY": _armory, "COIL": _coil,
    "FALCON": _falcon, "BALLISTA": _ballista, "TARPIT": _tarpit, "RESIN": _resin, "RAPTOR": _raptor,
    "TOTEM": _totem, "BLIMP": _blimp, "METEOR": _meteor, "VENT": _vent, "RANGER": _ranger,
}


def build(lp, tower):
    spot = S.SPOTS[tower]
    return C.setpiece(lp, "MIDNIGHT", tower, lambda k, K: DESIGNS[tower](k, K, spot), COLORS)
