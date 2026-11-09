"""TARPIT - Tar Pit (TowerLook tar black): a pool of glossy tar with bubbles, sunk in a rim of
dug earth and stones, a dino bone sticking out. It lies ON the track, so everything stays low
(under ~0.8 studs) and never blocks the view of the dinos walking through it. Authored from the
base (y 0) in Roblox studs; front = -Z (_kit conventions). The pit can't be damaged.

Stage 0 (tiers 0-2): the earth rim, the tar pool, three bubbles, a thigh bone half sunk, a
                     short warning stake.
Stage 1 (tier 3):    a WIDER TAR LAKE - the pool spreads to a wider rim with two lobes out to the
                     front-right and back-left corners, and a whole dino skeleton lies sunk in
                     it: a long spine and tail, a big ribcage, a skull at the front-right.
                     More bubbles, rim stones, a tar ladle.
Stage 2 (tier 5):    the lake's heart glows - a glowing ring of hot tar with glowing cracks and
                     hot bubbles - the skull wears a bony frill crowned with brass spikes and
                     glowing eyes, a brass-banded keg is half sunk at the back-left.
"""

import importlib.util
import math
from pathlib import Path

import bmesh

_spec = importlib.util.spec_from_file_location("_kit", Path(__file__).with_name("_kit.py"))
K = importlib.util.module_from_spec(_spec)
_spec.loader.exec_module(K)

TAR = (35, 28, 24)  # TowerLook.COLORS.TARPIT
SHEEN = (62, 54, 48)
EARTH = (96, 74, 52)
STONE = (112, 106, 98)
BONE = (225, 215, 190)
GLOW = (255, 120, 40)

TY = 0.12  # the tar's surface


def lake_r(t):
    """The stage-1/2 lake's outline radius at angle t (Roblox x = cos, z = sin): a wide round
    pool with lobes reaching into the front-right and back-left corners (the back-right stays round)."""
    lobe = max(0.0, math.cos(2 * (t + math.pi / 4)))  # 1 at -45 (front-right) and 135 deg (back-left)
    return 1.2 + 0.5 * lobe ** 3


def slab(outline, y0, y1):
    """A flat prism over a closed outline [(x, z), ...] from y0 to y1 (the lake's tar)."""
    bm = bmesh.new()
    lo = [bm.verts.new((x, y0, z)) for x, z in outline]
    hi = [bm.verts.new((x, y1, z)) for x, z in outline]
    n = len(outline)
    bm.faces.new(list(reversed(hi)))
    bm.faces.new(lo)
    for i in range(n):
        j = (i + 1) % n
        bm.faces.new((lo[i], lo[j], hi[j], hi[i]))
    bmesh.ops.recalc_face_normals(bm, faces=bm.faces)
    return K._obj(bm, "slab")


def band(inner, outer, y0, y1):
    """A low earth rim between two closed outlines: a flat top, sloped inner and outer walls."""
    bm = bmesh.new()
    n = len(inner)
    ib = [bm.verts.new((x, y0 + 0.06, z)) for x, z in inner]
    it = [bm.verts.new((x * 1.02, y1, z * 1.02)) for x, z in inner]
    ot = [bm.verts.new((x * 0.98, y1 - 0.02, z * 0.98)) for x, z in outer]
    ob = [bm.verts.new((x, y0, z)) for x, z in outer]
    for i in range(n):
        j = (i + 1) % n
        bm.faces.new((ib[i], ib[j], it[j], it[i]))
        bm.faces.new((it[i], it[j], ot[j], ot[i]))
        bm.faces.new((ot[i], ot[j], ob[j], ob[i]))
    bmesh.ops.recalc_face_normals(bm, faces=bm.faces)
    return K._obj(bm, "band")


def build(lp, stage):
    if stage == 0:
        return build0(lp)
    k = K.Kit(lp)

    # the lake: one wide pool with lobes into two corners, a low earth rim round it
    n = 40
    ts = [2 * math.pi * i / n for i in range(n)]
    pool = [(math.cos(t) * lake_r(t), math.sin(t) * lake_r(t)) for t in ts]
    rim_o = [(math.cos(t) * (lake_r(t) + 0.2), math.sin(t) * (lake_r(t) + 0.2)) for t in ts]
    rim_o = [(max(-1.48, min(1.48, x)), max(-1.48, min(1.48, z))) for x, z in rim_o]
    k.add("body", slab(pool, 0.0, TY))
    k.add("earth", band(pool, rim_o, 0.0, 0.22))

    # bubbles (domes rising from the tar); stage 2's are hot
    spots = [(-0.55, 0.35, 0.2), (0.45, -0.5, 0.15), (0.1, 0.05, 0.1), (-0.2, -0.85, 0.16), (0.85, 0.35, 0.13),
             (1.12, -1.1, 0.13), (-1.1, 1.05, 0.11)]
    bubbles = [K.ell((x, TY + r * 0.3, z), (r, r * 0.85, r), 8, 4) for x, z, r in spots]
    k.add("glow" if stage >= 2 else "bubble", *bubbles, piece="bubbles")
    k.add("sheen", *[K.ring((x, TY + 0.005, z), r * 1.3, 0.025, 8, 3) for x, z, r in spots])  # ripples

    # the sunken skeleton: a spine curving from the back-left lobe's tail to a skull at the front-right
    spine = [(-1.1, TY + 0.02, 1.05), (-0.7, TY + 0.05, 0.6), (-0.25, TY + 0.1, 0.18), (0.2, TY + 0.1, -0.2), (0.55, TY + 0.06, -0.55)]
    bones = [K.rod(spine[i], spine[i + 1], 0.07 - 0.008 * (3 - i if i < 3 else 0), 6) for i in range(len(spine) - 1)]
    bones += [K.ell(p, (0.09, 0.08, 0.09), 6, 3) for p in spine[1:4]]  # vertebra knobs
    # a big ribcage arching out of the tar along the middle of the spine
    d = (0.71, 0.0, -0.71)  # the spine's direction (back-left -> front-right)
    side = (0.71, 0.0, 0.71)
    for u, h in ((-0.45, 0.42), (-0.2, 0.55), (0.05, 0.6), (0.3, 0.5), (0.52, 0.36)):
        c = (-0.05 + d[0] * u, TY + 0.08, 0.0 + d[2] * u)
        for sg in (-1, 1):
            elbow = (c[0] + side[0] * sg * 0.42, TY + h * 0.75, c[2] + side[2] * sg * 0.42)
            tip = (c[0] + side[0] * sg * 0.24, TY + h, c[2] + side[2] * sg * 0.24)
            bones += [K.rod(c, elbow, 0.045, 5), K.rod(elbow, tip, 0.04, 5, top=0.4)]
    # the skull at the front-right lobe, snout to the front-right, the jaw sunk
    sk = (0.82, TY + 0.13, -0.82)
    bones += [K.ell(sk, (0.24, 0.17, 0.4), 8, 5, rot=(0, -45, 0)),
              K.ell((sk[0] + 0.16, TY + 0.08, sk[2] - 0.16), (0.16, 0.1, 0.26), 8, 4, rot=(0, -45, 0))]
    bones += [K.rod((sk[0] + 0.24 + dx, TY + 0.05, sk[2] - 0.24 + dx), (sk[0] + 0.26 + dx, TY - 0.05, sk[2] - 0.26 + dx), 0.03, 4, top=0.2)
              for dx in (-0.08, 0.0, 0.08)]  # teeth
    k.add("bone", *bones)
    eyes = [K.ell((sk[0] + 0.1 + ex, TY + 0.25, sk[2] - 0.1 + ez), (0.06, 0.04, 0.06), 6, 3) for ex, ez in ((-0.13, -0.05), (0.05, 0.13))]
    k.add("glow" if stage >= 2 else "tar", *eyes, piece="eyes")

    # stones on the rim (none near the back-right owner-flag corner)
    stones = [K.ell((math.cos(a) * 1.4, 0.18, math.sin(a) * 1.4), (0.17, 0.12, 0.14), 6, 4, rot=(0, math.degrees(a), 0))
              for a in (math.radians(d) for d in (195, 240, 160, 110, 345))]
    k.add("stone", *stones)

    # the warning stake at the front-left, sign tilted
    sx, sz = -1.25, -1.2
    k.add("wood", K.rod((sx, 0.0, sz), (sx + 0.04, 0.85, sz), 0.05, 6))
    k.add("sign", K.rbox((sx + 0.04, 0.62, sz - 0.06), (0.5, 0.3, 0.05), bevel=0, rot=(0, 20, 8)))
    k.add("tar", K.ell((sx + 0.04, 0.62, sz - 0.1), (0.12, 0.08, 0.02), 6, 3, rot=(0, 20, 0)))
    # a tar ladle stuck in the edge at the left
    k.add("wood", K.rod((-1.05, TY, -0.2), (-1.35, 0.72, -0.1), 0.035, 6))
    k.add("metal", K.ell((-1.0, TY + 0.02, -0.22), (0.13, 0.06, 0.13), 8, 4))

    if stage >= 2:
        brass = []
        # the hot heart of the lake: a glowing ring with cracks running out from it
        heart = [K.ring((0.1, TY + 0.01, 0.0), 0.62, 0.06, 18, 3)]
        for ang in (20, 95, 160, 230, 300):
            a0, a1 = math.radians(ang), math.radians(ang + 14)
            heart.append(K.bar((math.cos(a0) * 0.68 + 0.1, TY + 0.01, math.sin(a0) * 0.68),
                               (math.cos(a1) * 1.18 + 0.1, TY + 0.01, math.sin(a1) * 1.18), 0.07, 0.03, bevel=0))
        k.add("glow", *heart, piece="heart")
        # a bony frill behind the skull, crowned with brass spikes
        fc = (sk[0] - 0.22, TY + 0.36, sk[2] + 0.22)
        k.add("bone", K.ell(fc, (0.55, 0.34, 0.08), 10, 4, rot=(-30, -45, 0)))
        for ang in (-60, -30, 0, 30, 60):
            ra = math.radians(ang)
            ox, oy = math.sin(ra) * 0.48, math.cos(ra) * 0.28
            base = (fc[0] + ox * 0.71, fc[1] + oy * 0.86, fc[2] + ox * 0.71 + oy * 0.5)
            tip = (base[0] + ox * 0.35, min(0.82, base[1] + oy * 0.6), base[2] + ox * 0.35 + 0.08)
            brass.append(K.rod(base, tip, 0.08, 6, top=0.1))
        # a brass-banded keg half sunk at the back-left
        kx, kz = -0.95, 0.15
        k.add("wood", K.cyl((kx, TY + 0.15, kz), 0.22, 0.5, 10, rot=(0, 25, 90), bevel=0))
        ax = (math.cos(math.radians(25)), 0.0, -math.sin(math.radians(25)))
        brass += [K.ring_along((kx + ax[0] * t, TY + 0.15, kz + ax[2] * t), (kx + ax[0] * (t + 1), TY + 0.15, kz + ax[2] * (t + 1)), 0.22, 0.035, 10, 3)
                  for t in (-0.15, 0.15)]
        brass.append(K.cyl((sx + 0.04, 0.86, sz), 0.08, 0.06, 8, bevel=0))  # a brass cap on the stake
        k.add("brass", *brass)

    colors = {
        "body": TAR, "sheen": SHEEN, "bubble": (70, 60, 52), "earth": EARTH, "stone": STONE, "bone": BONE,
        "wood": K.WOOD, "sign": K.SAND, "tar": (24, 20, 18), "metal": K.METAL, "brass": K.BRASS, "glow": GLOW,
    }
    return k.model("11d", colors, "TARPIT", stage)


def build0(lp):
    """Stage 0 (tiers 0-2): the round pit."""
    stage = 0
    k = K.Kit(lp)

    # dug-earth rim (a fat low torus) and the tar pool inside it, a sheen across the surface
    k.add("earth", K.ring((0, 0.17, 0), 1.24, 0.17, 20, 5), K.cyl((0, 0.02, 0), 1.25, 0.04, 20, bevel=0.0))
    k.add("body", K.cyl((0, TY / 2, 0), 1.18, TY, 20, bevel=0.03))

    # bubbles (domes rising from the tar); stage 2's are hot
    spots = [(-0.55, 0.35, 0.2), (0.45, -0.5, 0.15), (0.1, 0.05, 0.1)]
    if stage >= 1:
        spots += [(-0.2, -0.7, 0.12), (0.7, 0.2, 0.09)]
    bubbles = [K.ell((x, TY + r * 0.3, z), (r, r * 0.85, r), 10, 5) for x, z, r in spots]
    k.add("glow" if stage >= 2 else "bubble", *bubbles, piece="bubbles")
    k.add("sheen", *[K.ring((x, TY + 0.005, z), r * 1.25, 0.02, 10, 3) for x, z, r in spots])  # ripples

    # a thigh bone half sunk, sticking up out of the tar
    k.add("bone", K.rod((0.3, 0.08, 0.5), (0.82, 0.42, 0.7), 0.07, 8),
          K.ell((0.85, 0.44, 0.71), (0.13, 0.1, 0.1), 8, 5), K.ell((0.8, 0.5, 0.62), (0.09, 0.08, 0.09), 8, 4))

    # a short warning stake at the front-left, sign tilted
    sx, sz = -1.25, -1.2
    k.add("wood", K.rod((sx, 0.0, sz), (sx + 0.04, 0.85, sz), 0.05, 6))
    k.add("sign", K.rbox((sx + 0.04, 0.62, sz - 0.06), (0.5, 0.3, 0.05), bevel=0.02, rot=(0, 20, 8)))
    k.add("tar", K.ell((sx + 0.04, 0.62, sz - 0.1), (0.12, 0.08, 0.02), 6, 3, rot=(0, 20, 0)))  # a tar splash on it

    colors = {
        "body": TAR, "sheen": SHEEN, "bubble": (70, 60, 52), "earth": EARTH, "stone": STONE, "bone": BONE,
        "wood": K.WOOD, "sign": K.SAND, "tar": (24, 20, 18), "metal": K.METAL, "brass": K.BRASS, "glow": GLOW,
    }
    return k.model("11d", colors, "TARPIT", stage)
