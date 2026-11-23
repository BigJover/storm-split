"""Lava Lord set pieces, the other 15 towers (premium theme, PREMIUM_SKINS.md, batch 11p2, #462): same
motifs as the approved v2 pieces (Scout / Grenadier / Vent, batch 11p1) - erupting cone, lava fall,
basalt columns, magma brazier, obsidian spire, lava pool - read from variants/_setpieces_lava.py
(untouched, so the approved pieces keep their hash), plus two new ones here:

  * `arch`  a basalt gateway: two hexagonal columns under an obsidian lintel, a glowing crack in its
            keystone and molten drips hanging from it
  * `flow`  a lava river on the ground: a glowing stream between low obsidian banks (for Tar Pit,
            which must stay under 0.8)

DESIGNS = one design(k, K) per tower; `build(lp, tower)` runs it through _setpiece_common.setpiece
(<= 800 tris, flag + Rescue Beacon columns clear, muzzle + lane clear at every stage, clip <= 35 %)
as batch 11p2. `glow` = Neon in game; Shared/SkinFx pulses it and, at stage 2, brightens it and
lets embers rise.
"""

import importlib.util
import math
from pathlib import Path

TOWER = Path(__file__).resolve().parents[1]
_spec = importlib.util.spec_from_file_location("_setpieces_lava", TOWER / "variants" / "_setpieces_lava.py")
L = importlib.util.module_from_spec(_spec)
_spec.loader.exec_module(L)

spire, brazier, pool, erupting, lavafall, columns = L.spire, L.brazier, L.pool, L.erupting, L.lavafall, L.columns


def arch(k, K, at, w=0.9, h=1.4, yaw=0.0, r=0.13):
    """A basalt gateway centred on `at`, its span along local x (before `yaw`)."""
    x, y, z = at
    c, s = math.cos(math.radians(yaw)), math.sin(math.radians(yaw))

    def p(dx):
        return (x + dx * c, z - dx * s)

    for side in (-1, 1):
        px, pz = p(side * w / 2)
        k.add("basalt", K.cyl((px, y + h / 2, pz), r, h, 6, bevel=0.0))
        k.add("glow", K.cyl((px, y + 0.06, pz), r * 1.25, 0.03, 6, bevel=0.0))
    k.add("obsidian", K.rbox((x, y + h + 0.09, z), (w + 0.42, 0.2, 0.3), bevel=0.0, rot=(0, yaw, 0), taper=(1.0, 0.85)))
    kx, kz = p(0)
    k.add("obsidian", K.rbox((kx, y + h + 0.26, kz), (0.24, 0.2, 0.26), bevel=0.0, rot=(0, yaw, 0), taper=(1.4, 1.0)))
    k.add("glow",
          K.rod((kx - 0.04 * c, y + h + 0.36, kz + 0.04 * s), (kx + 0.03 * c, y + h + 0.06, kz - 0.03 * s), 0.035, 4),
          *[K.ell((x + dx * c, y + h - 0.06, z - dx * s), (0.045, 0.1, 0.045), 5, 3) for dx in (-0.18, 0.12)])


def flow(k, K, pts, w=0.22):
    """A lava river along pts (on the ground): glowing stream segments, low obsidian banks either side."""
    for (ax, ay, az), (bx, by, bz) in zip(pts, pts[1:]):
        dx, dz = bx - ax, bz - az
        n = math.hypot(dx, dz)
        yaw = math.degrees(math.atan2(dx, dz))  # local z along the segment
        mx, mz = (ax + bx) / 2, (az + bz) / 2
        k.add("glow", K.rbox((mx, ay + 0.04, mz), (w, 0.04, n + 0.08), bevel=0.0, rot=(0, yaw, 0)))
        ox, oz = math.cos(math.radians(yaw)) * (w / 2 + 0.05), -math.sin(math.radians(yaw)) * (w / 2 + 0.05)
        for sgn in (-1, 1):
            k.add("obsidian", K.rbox((mx + ox * sgn, ay + 0.06, mz + oz * sgn), (0.1, 0.12, n), bevel=0.0, rot=(0, yaw, 0)))


# Every piece puts its hero motif on the front-left corner (-x, -z: the corner the game camera and
# the previews look at), a second motif down the left side and a third at the back.


def sniper(k, K):
    erupting(k, K, (-0.95, 0.0, -0.95), h=1.8, r=0.44)
    lavafall(k, K, (-1.15, 0.0, 0.45), h=1.3, w=0.36, yaw=0)
    columns(k, K, (0.2, 0.0, 1.1), heights=(1.5, 1.05, 0.7))


def chiller(k, K):
    erupting(k, K, (-0.95, 0.0, -0.95), h=1.6, r=0.42)  # fire beside the ice
    lavafall(k, K, (-1.15, 0.0, 0.5), h=1.1, w=0.36, yaw=0)
    columns(k, K, (0.45, 0.0, 1.1), heights=(1.2, 0.8, 0.5), r=0.12)


def quartermaster(k, K):
    brazier(k, K, (-1.0, 0.0, -1.0), s=1.4, legs=0.9)
    spire(k, K, (-1.1, 0.0, 0.35), h=2.0, w=0.44, yaw=90)
    columns(k, K, (0.45, 0.0, 1.1), heights=(1.1, 0.75, 0.5), r=0.12)


def hospital(k, K):
    brazier(k, K, (-1.0, 0.0, -1.0), s=1.4, legs=0.9)  # the healer's fire at the tent's door
    columns(k, K, (-1.1, 0.0, 0.4), heights=(1.4, 1.0, 0.6))
    pool(k, K, (-0.2, 0.0, 1.1), r=0.3)


def armory(k, K):
    # everything stands on the plank floor (y 0.13)
    spire(k, K, (-0.95, 0.13, -0.95), h=2.0, w=0.44, yaw=45)
    erupting(k, K, (-0.95, 0.13, 0.35), h=1.1, r=0.34)
    columns(k, K, (0.3, 0.13, 1.15), heights=(1.0, 0.7, 0.45), r=0.12)


def coil(k, K):
    erupting(k, K, (-0.95, 0.0, -0.95), h=1.5, r=0.42)
    spire(k, K, (-1.15, 0.0, 0.5), h=1.9, w=0.4, yaw=90)
    brazier(k, K, (-0.3, 0.0, 1.15), s=1.1, legs=0.7)


def falcon(k, K):
    # the mews fills the left half: a fire perch out in front, a small cone at its door
    brazier(k, K, (0.05, 0.0, -1.15), s=1.3, legs=1.2)
    erupting(k, K, (-0.95, 0.0, -1.1), h=1.0, r=0.32)
    columns(k, K, (0.85, 0.0, 0.5), heights=(1.2, 0.85, 0.55), r=0.12)


def ballista(k, K):
    erupting(k, K, (-0.95, 0.0, -0.95), h=1.6, r=0.42)
    columns(k, K, (-1.1, 0.0, 0.55), heights=(1.2, 0.8, 0.5), r=0.13)
    lavafall(k, K, (0.15, 0.0, 0.85), h=0.9, w=0.36, yaw=180)


def tarpit(k, K):
    # flat (<= 0.8): a lava river running across the tar (on its surface, y 0.14) into a pool in the
    # front-left corner, a low basalt cluster in the back-left corner
    flow(k, K, [(-0.95, 0.14, -0.75), (-0.55, 0.14, -0.2), (-0.1, 0.14, 0.2), (0.45, 0.14, 0.45)], w=0.2)
    pool(k, K, (-1.15, 0.0, -1.15), r=0.3)
    columns(k, K, (-1.15, 0.0, 1.1), heights=(0.7, 0.5, 0.35), r=0.12)


def resin(k, K):
    erupting(k, K, (-0.95, 0.0, -0.95), h=1.7, r=0.42)
    lavafall(k, K, (-1.15, 0.0, 0.5), h=1.1, w=0.36, yaw=0)
    brazier(k, K, (0.25, 0.0, 1.15), s=1.0, legs=0.6)


def raptor(k, K):
    arch(k, K, (0.6, 0.0, 0.15), w=0.8, h=1.7, yaw=90)  # a basalt gateway inside the pen
    erupting(k, K, (-1.0, 0.0, -1.0), h=1.3, r=0.38)
    brazier(k, K, (-1.15, 0.0, 0.9), s=1.1, legs=0.7)


def totem(k, K):
    brazier(k, K, (-1.0, 0.0, -1.0), s=1.4, legs=1.0)
    spire(k, K, (-1.0, 0.0, 1.0), h=2.4, w=0.46, yaw=40)
    pool(k, K, (0.4, 0.0, 1.1), r=0.3)


def blimp(k, K):
    erupting(k, K, (-0.95, 0.0, -0.95), h=1.4, r=0.42)
    spire(k, K, (-1.15, 0.0, 0.45), h=2.0, w=0.42, yaw=90)
    columns(k, K, (0.2, 0.0, 1.1), heights=(1.0, 0.7, 0.45), r=0.12)


def meteor(k, K):
    erupting(k, K, (-0.95, 0.0, -0.95), h=1.8, r=0.44)  # a cone erupting under the falling star
    columns(k, K, (-1.1, 0.0, 0.7), heights=(1.4, 0.95, 0.6))
    pool(k, K, (0.2, 0.0, 1.1), r=0.3)


def ranger(k, K):
    brazier(k, K, (-1.0, 0.0, -1.0), s=1.3, legs=1.0)
    erupting(k, K, (0.2, 0.0, -1.05), h=1.0, r=0.3)
    columns(k, K, (-1.15, 0.0, 1.1), heights=(1.1, 0.75, 0.5), r=0.12)


DESIGNS = {"SNIPER": sniper, "CHILLER": chiller, "QUARTERMASTER": quartermaster, "HOSPITAL": hospital,
           "ARMORY": armory, "COIL": coil, "FALCON": falcon, "BALLISTA": ballista, "TARPIT": tarpit,
           "RESIN": resin, "RAPTOR": raptor, "TOTEM": totem, "BLIMP": blimp, "METEOR": meteor, "RANGER": ranger}


def build(lp, tower):
    model = L.build(lp, tower, DESIGNS[tower])
    model["batch"] = "11p2"
    return model
