"""Cyber Raptor set pieces (premium theme, PREMIUM_SKINS.md, batch 11p3, element electric / digital
glitch, #462): one add-on per tower kind, `tower/SET_CYBER_RAPTOR_<TOWER>`, worn over that tower's
art at every stage on top of the Cyber Raptor trim (SET_CYBER_RAPTOR.py). Motifs: an antenna
**mast** with a small radar dish, a **tesla** node (coil rings, a spark ball), both topped by a
raptor **talon** gripping a glowing energy orb, a **server rack**
(rows of glowing status lights), a **holo** screen with the raptor-claw glyph, a giant raptor
**claw** sculpture, and glowing power **cables** on the ground / along the walls.

Black chrome `plate`, gunmetal `chrome`, `glow` = Neon in game (Shared/SkinFx cycles it cyan ->
magenta and, at stage 2, brightens it and pops pixel sparks). Placements follow the approved
per-tower spots of the 11e2 sets (the left corners / back, clear of the flag, the Rescue Beacon and
every muzzle lane); built and checked by _setpiece_common.setpiece (<= 800 tris, stages 0-2).
"""

import importlib.util
import math
from pathlib import Path

TOWER = Path(__file__).resolve().parents[1]
_spec = importlib.util.spec_from_file_location("_setpiece_common", TOWER / "variants" / "_setpiece_common.py")
C = importlib.util.module_from_spec(_spec)
_spec.loader.exec_module(C)

COLORS = {"plate": (30, 32, 44), "chrome": (138, 148, 166), "glow": (0, 236, 255)}


def _rot(dx, dz, yaw):
    """A local (x, z) offset turned by yaw degrees about Y (as K._place turns a piece)."""
    a = math.radians(yaw)
    return dx * math.cos(a) + dz * math.sin(a), -dx * math.sin(a) + dz * math.cos(a)


def talon(k, K, c, r=0.14, h=0.32, n=3, yaw=30.0):
    """A raptor talon gripping an energy orb: n gunmetal claws curling up and in round c (the
    orb's centre), each a tapering three-segment hook."""
    x, y, z = c
    out = []
    for i in range(n):
        a = math.radians(yaw + 360 * i / n)
        ca, sa = math.cos(a), math.sin(a)
        pts = [(x + r * 0.8 * ca, y - h * 0.55, z + r * 0.8 * sa), (x + r * 1.45 * ca, y - h * 0.1, z + r * 1.45 * sa),
               (x + r * 1.2 * ca, y + h * 0.4, z + r * 1.2 * sa), (x + r * 0.45 * ca, y + h * 0.62, z + r * 0.45 * sa)]
        for j, (p, q) in enumerate(zip(pts, pts[1:])):
            out.append(K.rod(p, q, 0.04 * (1 - j * 0.3), 5, top=(0.75 if j < 2 else 0.15)))
    k.add("chrome", *out)


def mast(k, K, foot, h, dish=True, yaw=0.0, rings=2, claws=True):
    """An antenna mast: a tapering gunmetal pole on a black-chrome foot, two cross arms, glowing
    bands, a glowing tip and (dish) a small radar dish facing local -Z near the top."""
    x, y, z = foot
    top = y + h
    k.add("plate", K.cyl((x, y + 0.06, z), 0.2, 0.12, 6, bevel=0.0))
    k.add("chrome", K.rod((x, y, z), (x, top, z), 0.085, 6, top=0.55))
    for t in (0.55, 0.8):
        ax, az = _rot(0.22 * (1.1 - t), 0, yaw)
        k.add("chrome", K.rod((x - ax, y + h * t, z - az), (x + ax, y + h * t, z + az), 0.025, 4))
    k.add("glow", *[K.ring((x, y + h * t, z), 0.1, 0.035, 8, 3) for t in (0.3, 0.65)[:rings]],
          K.ell((x, top + 0.1, z), (0.12, 0.12, 0.12), 8, 4))
    if claws:
        talon(k, K, (x, top + 0.1, z), r=0.13, h=0.3)
    if dish:
        dy = top - h * 0.18
        ox, oz = _rot(0.16, -0.16, yaw)  # off to the tower's side of the pole (keeps inside the footprint)
        k.add("chrome", K.cyl((x + ox, dy, z + oz), 0.28, 0.1, 10, top=0.35, bevel=0.0, rot=(-70, yaw, 0)))
        fx, fz = _rot(0.16, -0.32, yaw)
        k.add("glow", K.rod((x + ox, dy, z + oz), (x + fx, dy + 0.06, z + fz), 0.025, 4))


def tesla(k, K, foot, h, r=0.16, claws=True):
    """A tesla node: a black-chrome plinth, a gunmetal rod wound with three glowing coil rings, a
    gunmetal crown ring and a glowing spark ball on top."""
    x, y, z = foot
    top = y + h
    k.add("plate", K.cyl((x, y + 0.08, z), r * 1.5, 0.16, 8, bevel=0.0, top=0.8))
    k.add("chrome", K.rod((x, y + 0.16, z), (x, top - 0.12, z), 0.06, 6))
    k.add("glow", *[K.ring((x, y + 0.16 + (h - 0.4) * t, z), r * (1.0 - t * 0.3), 0.042, 8, 3) for t in (0.25, 0.5, 0.75)],
          K.ell((x, top + 0.02, z), (0.14, 0.14, 0.14), 8, 4))
    if claws:
        talon(k, K, (x, top + 0.02, z), r=0.14, h=0.32)
    else:
        k.add("chrome", K.ring((x, top - 0.12, z), r * 0.9, 0.03, 8, 3))


def rack(k, K, foot, w=0.5, h=1.2, d=0.36, yaw=0.0, rows=None):
    """A server rack: a black-chrome cabinet (front = local -Z) with gunmetal top and base and rows
    of glowing status-light slits down its front."""
    x, y, z = foot
    k.add("plate", K.rbox((x, y + h / 2, z), (w, h, d), bevel=0.0, rot=(0, yaw, 0)))
    k.add("chrome", K.rbox((x, y + h + 0.03, z), (w + 0.06, 0.06, d + 0.06), bevel=0.0, rot=(0, yaw, 0)),
          K.rbox((x, y + 0.04, z), (w + 0.06, 0.08, d + 0.06), bevel=0.0, rot=(0, yaw, 0)))
    n = rows or max(2, int(h / 0.22))
    fx, fz = _rot(0, -(d / 2 + 0.008), yaw)
    lights = []
    for i in range(n):
        yy = y + 0.18 + (h - 0.3) * i / max(1, n - 1)
        lights.append(K.rbox((x + fx, yy, z + fz), (w * 0.7, 0.06, 0.02), bevel=0.0, rot=(0, yaw, 0)))
    k.add("glow", *lights)


def holo(k, K, c, yaw=0.0, w=0.6, h=0.44, post=None):
    """A holo screen (facing local -Z, both sides lit) in a gunmetal frame, the raptor-claw glyph
    (three dark slashes) on it; post = the ground y for a support post under it."""
    x, y, z = c
    k.add("chrome", K.rbox((x, y, z), (w + 0.08, h + 0.08, 0.04), bevel=0.0, rot=(0, yaw, 0)))
    k.add("glow", K.rbox((x, y, z), (w, h, 0.06), bevel=0.0, rot=(0, yaw, 0)))
    slashes = []
    for side in (-1, 1):
        nx, nz = _rot(0, side * 0.035, yaw)
        for i in (-1, 0, 1):
            ax, az = _rot(i * w * 0.18 - w * 0.08, 0, yaw)
            bx, bz = _rot(i * w * 0.18 + w * 0.08, 0, yaw)
            slashes.append(K.rod((x + ax + nx, y + h * 0.3, z + az + nz), (x + bx + nx, y - h * 0.3, z + bz + nz), 0.018, 4))
    k.add("plate", *slashes)
    if post is not None:
        k.add("chrome", K.rod((x, post, z), (x, y - h / 2, z), 0.04, 5))
        k.add("plate", K.cyl((x, post + 0.05, z), 0.14, 0.1, 6, bevel=0.0))


def claw(k, K, foot, h=2.6, yaw=0.0, r=0.22):
    """A giant raptor claw sculpture: a gunmetal claw curving up and over (toward local -Z) out of a
    black-chrome plinth ringed with light, a glowing tip."""
    x, y, z = foot
    pts = [(0, 0.06, 0.08), (0, 0.42, 0.18), (0, 0.76, 0.1), (0, 0.96, -0.16), (0, 0.9, -0.42)]  # a hook, tip down-forward
    world = []
    for dx, t, dz in pts:
        ox, oz = _rot(dx, dz * h * 0.6, yaw)
        world.append((x + ox, y + h * t, z + oz))
    n = len(world) - 1
    segs = [K.rod(p, q, r * (1 - i / n * 0.85), 6, top=(1 - (i + 1) / n * 0.85) / (1 - i / n * 0.85)) for i, (p, q) in
            enumerate(zip(world, world[1:]))]
    k.add("chrome", *segs[:-1])
    k.add("glow", segs[-1], K.ring((x, y + 0.22, z), r * 1.6, 0.035, 10, 3))
    k.add("plate", K.cyl((x, y + 0.1, z), r * 1.7, 0.2, 8, bevel=0.0, top=0.85))


def cable(k, K, pts, r=0.042):
    """A glowing power cable along pts."""
    k.add("glow", *[K.rod(p, q, r, 4) for p, q in zip(pts, pts[1:])])


def pad(k, K, c, r=0.3):
    """A flat hex floor pad: black chrome with a glowing ring inset."""
    x, y, z = c
    k.add("plate", K.cyl((x, y + 0.04, z), r, 0.08, 6, bevel=0.0))
    k.add("glow", K.cyl((x, y + 0.085, z), r * 0.75, 0.015, 6, bevel=0.0))


# ---- per tower (spots after the approved 11e2 sets, _setpieces_treehouse.py) --------------------

def scout(k, K):
    mast(k, K, (-1.3, 0.0, 1.3), 3.9, yaw=0)
    holo(k, K, (-1.42, 1.45, -0.2), yaw=90, w=0.7, h=0.42)
    cable(k, K, [(-1.3, 0.03, 1.1), (-1.38, 0.03, 0.3), (-1.38, 0.03, -1.1)])


def sniper(k, K):
    rack(k, K, (-0.9, 0.0, 0.0), w=0.5, h=1.1, d=0.36, yaw=90)
    for z in (-1.0, 1.0):
        k.add("glow", *[K.ring((-1.32, y, z * 1.12), 0.13, 0.025, 8, 3) for y in (0.7, 1.5, 2.3)])
    holo(k, K, (-1.4, 2.75, 0.0), yaw=90, w=0.8, h=0.46)


def grenadier(k, K):
    tesla(k, K, (-1.22, 0.0, 0.05), 3.0)
    cable(k, K, [(-1.22, 0.55, -0.4), (-1.3, 0.58, -0.75), (-0.95, 0.62, -1.15), (-0.5, 0.6, -1.32), (-0.1, 0.58, -1.38),
                 (0.3, 0.6, -1.32)])


def chiller(k, K):
    rack(k, K, (-0.5, 0.0, 1.26), w=0.7, h=2.4, d=0.36, yaw=0)
    mast(k, K, (-0.5, 2.46, 1.26), 1.4, dish=True, yaw=0, rings=1)
    cable(k, K, [(-1.4, 0.4, -0.5), (-1.42, 1.0, -0.3), (-1.4, 1.45, 0.0), (-1.42, 1.0, 0.3), (-1.4, 0.4, 0.5)])


def quartermaster(k, K):
    mast(k, K, (-0.35, 0.0, 1.3), 3.8, yaw=0)
    holo(k, K, (-0.35, 2.3, 1.12), yaw=0, w=0.62, h=0.42)
    cable(k, K, [(-1.4, 0.3, 0.2), (-1.42, 1.0, 0.0), (-1.4, 1.6, -0.2), (-1.36, 2.1, -0.4)])


def hospital(k, K):
    mast(k, K, (-1.25, 0.0, 0.25), 3.4, yaw=0)
    holo(k, K, (-1.2, 1.25, -0.8), yaw=0, w=0.4, h=0.34, post=0.0)
    cable(k, K, [(-1.36, 0.9, -1.3), (-0.95, 1.1, -1.4), (-0.6, 1.4, -1.42), (-0.3, 1.8, -1.42)])


def armory(k, K):
    rack(k, K, (-1.05, 0.0, -1.2), w=0.56, h=1.8, d=0.36, yaw=0)
    tesla(k, K, (-1.05, 1.86, -1.2), 1.2, r=0.12)
    cable(k, K, [(-1.42, 0.2, -0.6), (-1.42, 0.9, -0.3), (-1.42, 1.6, 0.1), (-1.42, 2.3, 0.5), (-1.42, 2.9, 0.9)])


def coil(k, K):
    tesla(k, K, (-1.24, 0.0, -0.6), 3.4)
    cable(k, K, [(-1.3, 0.2, 0.3), (-1.4, 0.25, 0.7), (-1.2, 0.22, 1.0), (-0.8, 0.25, 1.38), (-0.3, 0.22, 1.4)])


def falcon(k, K):
    mast(k, K, (-1.05, 0.0, -1.1), 3.1, yaw=0)
    holo(k, K, (-1.4, 1.9, -0.8), yaw=90, w=0.56, h=0.4)
    cable(k, K, [(-0.75, 0.25, -1.42), (-0.3, 0.3, -1.4), (0.1, 0.25, -1.42), (0.45, 0.3, -1.4)])


def ballista(k, K):
    mast(k, K, (-1.28, 0.0, 0.8), 3.6, yaw=0)
    rack(k, K, (-0.8, 0.0, 1.22), w=0.5, h=1.3, d=0.3, yaw=0)
    cable(k, K, [(-1.3, 0.35, -0.6), (-1.15, 0.4, -0.95), (-0.8, 0.38, -1.2), (-0.4, 0.4, -1.35)])


def tarpit(k, K):
    # flat: two short tesla posts with a glowing cable sagging between them over the back of the
    # pit, a low rack along the left edge, a hex pad; nothing over 0.8
    tesla(k, K, (-1.2, 0.0, 1.0), 0.62, r=0.12, claws=False)
    tesla(k, K, (0.78, 0.0, 1.0), 0.62, r=0.12, claws=False)
    cable(k, K, [(-1.2, 0.56, 1.0), (-0.7, 0.44, 1.0), (-0.2, 0.4, 1.0), (0.3, 0.44, 1.0), (0.78, 0.56, 1.0)], r=0.035)
    rack(k, K, (-1.26, 0.0, -0.1), w=0.36, h=0.5, d=0.9, yaw=0, rows=2)
    pad(k, K, (-0.95, 0.0, -0.95), 0.26)


def resin(k, K):
    rack(k, K, (-1.18, 0.0, 1.0), w=0.5, h=2.0, d=0.4, yaw=0)
    tesla(k, K, (-1.18, 2.06, 1.0), 1.1, r=0.12)
    holo(k, K, (-1.18, 2.36, 0.8), yaw=0, w=0.5, h=0.36)
    cable(k, K, [(-1.43, 0.3, -0.7), (-1.42, 0.9, -0.4), (-1.43, 1.3, 0.0), (-1.42, 0.9, 0.4)])


def raptor(k, K):
    # a raptor's three claws bursting up inside the pen (right of the watchtower), the middle one tallest
    claw(k, K, (0.55, 0.0, 0.4), h=3.0, yaw=0, r=0.26)
    claw(k, K, (0.95, 0.0, 0.75), h=2.1, yaw=-35, r=0.18)
    claw(k, K, (0.2, 0.0, 0.85), h=1.7, yaw=30, r=0.16)
    cable(k, K, [(-1.42, 1.2, -1.0), (-1.43, 1.45, -0.5), (-1.42, 1.2, 0.0), (-1.43, 1.45, 0.5), (-1.42, 1.2, 0.9)])


def totem(k, K):
    mast(k, K, (-1.05, 0.0, 1.05), 3.9, yaw=0)
    cable(k, K, [(-0.95, 3.55, 0.92), (-0.75, 3.35, 0.65), (-0.55, 3.3, 0.48), (-0.35, 3.4, 0.32)], r=0.025)
    pad(k, K, (-1.05, 0.0, 1.05), 0.3)


def blimp(k, K):
    tesla(k, K, (-1.24, 0.0, 0.0), 3.0)
    holo(k, K, (-1.18, 1.6, -0.55), yaw=0, w=0.4, h=0.34)
    cable(k, K, [(-1.4, 0.15, -1.3), (-1.0, 0.18, -1.42), (-0.5, 0.15, -1.4)])


def meteor(k, K):
    mast(k, K, (-1.12, 0.0, -1.0), 3.3, yaw=0)
    k.add("chrome", K.cyl((-1.04, 2.0, -1.12), 0.3, 0.12, 10, top=0.3, bevel=0.0, rot=(-60, 0, 0)))  # a second, bigger dish
    k.add("glow", K.ell((-1.04, 2.1, -1.2), (0.06, 0.06, 0.06), 6, 3))
    cable(k, K, [(-1.4, 0.05, -0.9), (-1.42, 0.05, 0.0), (-1.4, 0.05, 0.9)])


def vent(k, K):
    tesla(k, K, (-1.25, 0.0, 1.05), 2.6, r=0.13)
    tesla(k, K, (-1.25, 0.0, -1.05), 2.1, r=0.13, claws=False)
    cable(k, K, [(-1.36, 1.6, -1.0), (-1.42, 1.3, -0.4), (-1.42, 1.25, 0.2), (-1.4, 1.6, 0.9)])


def ranger(k, K):
    mast(k, K, (-1.3, 0.0, 1.3), 3.9, yaw=0)
    holo(k, K, (-1.44, 1.6, 0.0), yaw=90, w=0.6, h=0.4)
    cable(k, K, [(-1.42, 0.3, -0.6), (-1.42, 1.0, -0.3), (-1.42, 1.4, 0.1)])


DESIGNS = {"SCOUT": scout, "SNIPER": sniper, "GRENADIER": grenadier, "CHILLER": chiller,
           "QUARTERMASTER": quartermaster, "HOSPITAL": hospital, "ARMORY": armory, "COIL": coil,
           "FALCON": falcon, "BALLISTA": ballista, "TARPIT": tarpit, "RESIN": resin, "RAPTOR": raptor,
           "TOTEM": totem, "BLIMP": blimp, "METEOR": meteor, "VENT": vent, "RANGER": ranger}


def build(lp, tower):
    model = C.setpiece(lp, "CYBER_RAPTOR", tower, DESIGNS[tower], COLORS)
    model["batch"] = "11p3"
    model["meta"].update({"theme": "CYBER_RAPTOR", "premium": True})
    return model
