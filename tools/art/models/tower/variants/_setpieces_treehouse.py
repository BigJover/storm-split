"""Treehouse set pieces (11e2, #457): one bold piece per tower kind, `tower/SET_TREEHOUSE_<TOWER>`,
worn over the tower's art at every stage on top of the Treehouse trim (variants/_sets.py,
SET_TREEHOUSE.py). The theme: a leafy tree growing beside / through the camp (bark trunk, branches,
canopy blobs), vines with leaves, carved plank crests with a leaf emblem, rope bridges and
plank lookouts, birdhouses. Built and checked by variants/_setpiece_common.py (<= 800 tris,
flag + Rescue Beacon corners clear, muzzles untouched, Tar Pit flat, Vent middle clear).

Authored in Roblox studs from the tower's base (y 0), front = -Z, left = -X (_kit.py). Every
piece fits round all three stages of its tower (heights measured off each stage's art).
"""

import math

BARK = (104, 74, 44)
PLANK = (150, 108, 64)
LEAF = (124, 176, 66)  # brighter than the set's accent green, so the tree reads over the tower
LEAF2 = (86, 146, 52)
VINE = (72, 102, 46)
ROPE = (176, 150, 100)
CARVE = (210, 172, 104)
DARK = (58, 42, 28)
COLORS = {"bark": BARK, "plank": PLANK, "leaf": LEAF, "leaf2": LEAF2, "vine": VINE, "rope": ROPE,
          "carve": CARVE, "dark": DARK}


# ---------------------------------------------------------------- motifs

LIM = 1.49  # the Body's half width (1.5), a hair inside


def fit(c, rx, rz):
    """Slide a blob's centre so its x / z radii stay inside the 3 x 3 footprint."""
    x, y, z = c
    return (max(-LIM + rx, min(LIM - rx, x)), y, max(-LIM + rz, min(LIM - rz, z)))


def trunk(k, K, a, b, r=0.12, seg=7):
    a, b = fit(a, r + 0.01, r + 0.01), fit(b, r, r)
    k.add("bark", K.rod(a, b, r, seg, top=0.65))
    if a[1] < 0.05:  # a root flare where it meets the ground
        k.add("bark", K.cyl(fit((a[0], 0.11, a[2]), r * 1.7, r * 1.7), r * 1.7, 0.22, seg, top=0.5, bevel=0))


def branch(k, K, a, b, r=0.05):
    k.add("bark", K.rod(a, b, r, 5, top=0.6))


def canopy(k, K, c, r=0.45, lean=(0.0, 0.0)):
    """Three overlapping leaf blobs: a big one and two smaller lobes (two greens)."""
    x, y, z = c
    lx, lz = lean
    k.add("leaf", K.ell(fit((x, y, z), r, r), (r, r * 0.66, r), 9, 4),
          K.ell(fit((x - r * 0.1, y + r * 0.45, z + r * 0.05), r * 0.6, r * 0.6), (r * 0.6, r * 0.42, r * 0.6), 7, 3))
    a, b, c2 = r * 0.62, r * 0.56, r * 0.5
    k.add("leaf2",
          K.ell(fit((x + r * 0.6 + lx, y - r * 0.2, z + r * 0.3 + lz), a, a), (a, r * 0.45, a), 7, 3),
          K.ell(fit((x - r * 0.4 - lx, y - r * 0.15, z - r * 0.55 - lz), b, b), (b, r * 0.42, b), 7, 3),
          K.ell(fit((x - r * 0.55, y - r * 0.22, z + r * 0.5), c2, c2), (c2, r * 0.38, c2), 7, 3))


def tuft(k, K, c, r=0.22, group="leaf"):
    k.add(group, K.ell(fit(c, r, r), (r, r * 0.6, r), 7, 3))


def vine(k, K, pts, r=0.03, every=2):
    """A vine through pts with a leaf at every `every`-th point."""
    pts = [fit(p, 0.1, 0.1) for p in pts]
    rods = [K.rod(a, b, r, 5) for a, b in zip(pts, pts[1:])]
    k.add("vine", *rods)
    leaves = [K.ell(p, (0.09, 0.05, 0.09), 6, 3) for i, p in enumerate(pts) if i % every == 1]
    if leaves:
        k.add("leaf", *leaves)


def spiral(c, r, y0, y1, turns, n):
    """Points winding round a vertical post at c (x, z)."""
    out = []
    for i in range(n + 1):
        t = i / n
        a = 2 * math.pi * turns * t
        out.append((c[0] + r * math.cos(a), y0 + (y1 - y0) * t, c[1] + r * math.sin(a)))
    return out


def crest(k, K, c, facing, w=0.62, h=0.5):
    """A carved plank crest: a board with a raised leaf emblem and a dark rim, `facing` = the
    board's outward normal: "-x" (left wall), "-z" (front), "+z" (back)."""
    if facing == "-x":
        c = fit(c, 0.1, w / 2 + 0.04)
    else:
        c = fit(c, w / 2 + 0.04, 0.1)
    x, y, z = c
    if facing == "-x":
        size, emb, off = (0.07, h, w), (0.04, h * 0.34, w * 0.22), (-0.05, 0, 0)
    else:
        size, emb, off = (w, h, 0.07), (w * 0.22, h * 0.34, 0.04), (0, 0, -0.05 if facing == "-z" else 0.05)
    k.add("plank", K.rbox(c, size, bevel=0.025))
    rim = tuple(s + 0.05 if s > 0.1 else s * 0.6 for s in size)
    k.add("dark", K.rbox((x - off[0] * 0.4, y, z - off[2] * 0.4), rim, bevel=0.02))
    k.add("carve", K.ell((x + off[0], y + h * 0.05, z + off[2]), emb, 7, 3),
          K.rod((x + off[0], y - h * 0.38, z + off[2]), (x + off[0], y - h * 0.05, z + off[2]), 0.025, 4))


def birdhouse(k, K, c, yaw=0.0):
    x, y, z = c
    k.add("plank", K.rbox((x, y, z), (0.26, 0.28, 0.24), bevel=0.02, rot=(0, yaw, 0)))
    k.add("bark", K.rbox((x, y + 0.2, z), (0.34, 0.14, 0.32), bevel=0.01, taper=(0.1, 1.0), rot=(0, yaw, 0)))
    a = math.radians(yaw)
    k.add("dark", K.cyl((x - 0.12 * math.sin(a), y + 0.02, z - 0.12 * math.cos(a)), 0.05, 0.03, 6, bevel=0,
                        rot=(90, yaw, 0)))


def rope_bridge(k, K, a, b, n=5, sag=0.08, w=0.32, rail=0.24):
    """Planks from a to b (sagging), two hand ropes `rail` above them."""
    ax, ay, az = a
    bx, by, bz = b
    dx, dz = bx - ax, bz - az
    length = math.hypot(dx, dz)
    sx, sz = -dz / length * w / 2, dx / length * w / 2
    planks, ropes = [], []
    pts = []
    for i in range(n):
        t = (i + 0.5) / n
        y = ay + (by - ay) * t - sag * 4 * t * (1 - t)
        p = (ax + dx * t, y, az + dz * t)
        pts.append(p)
        planks.append(K.bar((p[0] - sx, y, p[2] - sz), (p[0] + sx, y, p[2] + sz), length / n * 0.7, 0.05, 0.01))
    k.add("plank", *planks)
    for side in (-1, 1):
        rp = [(ax + side * sx, ay + rail, az + side * sz)]
        rp += [(p[0] + side * sx, p[1] + rail, p[2] + side * sz) for p in pts]
        rp += [(bx + side * sx, by + rail, bz + side * sz)]
        ropes += [K.rod(p, q, 0.018, 4) for p, q in zip(rp, rp[1:])]
    k.add("rope", *ropes)


def deck(k, K, c, w, d, posts=True, y0=0.0):
    """A small plank lookout deck at c (centre of its top), on posts down to y0."""
    x, y, z = c
    k.add("plank", *[K.rbox((x - w / 2 + (i + 0.5) * w / 4, y - 0.04, z), (w / 4 - 0.03, 0.08, d), bevel=0.015)
                     for i in range(4)])
    if posts:
        k.add("bark", *[K.rod((x + sx * (w / 2 - 0.05), y0, z + sz * (d / 2 - 0.05)),
                              (x + sx * (w / 2 - 0.05), y - 0.08, z + sz * (d / 2 - 0.05)), 0.04, 5)
                        for sx in (-1, 1) for sz in (-1, 1)])


def tree(k, K, foot, top, crown, r=0.45, trunk_r=0.16, branches=(), platform=None):
    """A chunky tree; r is scaled up 1.35x (cap 0.7) so it reads from the game camera.
    platform = (y, w): a little plank treehouse deck round the trunk at height y."""
    r = min(0.7, r * 1.35)
    trunk(k, K, foot, top, trunk_r)
    if platform:
        y, w = platform
        t = (y - foot[1]) / max(1e-3, top[1] - foot[1])
        cx, cz = foot[0] + (top[0] - foot[0]) * t, foot[2] + (top[2] - foot[2]) * t
        cx, _, cz = fit((cx, y, cz), w / 2, w / 2)
        deck(k, K, (cx, y, cz), w, w, posts=False)
        k.add("bark", *[K.rod((cx + sx * (w / 2 - 0.04), y - 0.02, cz + sz * (w / 2 - 0.04)),
                              (cx + sx * (w / 2 - 0.04), y + 0.3, cz + sz * (w / 2 - 0.04)), 0.025, 4)
                        for sx in (-1, 1) for sz in (-1, 1)])
        k.add("rope", *[K.rod((cx + sx * (w / 2 - 0.04), y + 0.26, cz - (w / 2 - 0.04)),
                              (cx + sx * (w / 2 - 0.04), y + 0.26, cz + (w / 2 - 0.04)), 0.015, 4) for sx in (-1, 1)],
              *[K.rod((cx - (w / 2 - 0.04), y + 0.26, cz + sz * (w / 2 - 0.04)),
                      (cx + (w / 2 - 0.04), y + 0.26, cz + sz * (w / 2 - 0.04)), 0.015, 4) for sz in (-1, 1)])
        k.add("bark", K.rod((cx - w * 0.3, y - 0.45, cz), (cx - w * 0.05, y - 0.06, cz), 0.03, 4),
              K.rod((cx + w * 0.3, y - 0.45, cz), (cx + w * 0.05, y - 0.06, cz), 0.03, 4))
    for b in branches:
        branch(k, K, b[0], b[1])
    canopy(k, K, crown, r)


# ---------------------------------------------------------------- the 18 pieces

def scout(k, K):
    # a lookout tree at the back-left corner, its crown over the hide; a vine along the roof's
    # left eave, a carved crest on the trunk facing the front, a leaf tuft on the front corner
    tree(k, K, (-1.34, 0.0, 1.32), (-1.2, 4.0, 1.15), (-1.0, 4.3, 0.95), r=0.5, trunk_r=0.17, platform=(2.75, 0.62),
         branches=[((-1.22, 3.2, 1.18), (-0.75, 3.75, 1.25))])
    crest(k, K, (-1.22, 3.0, 0.98), "-z", w=0.5, h=0.44)
    vine(k, K, [(-1.3, 2.25, 1.0), (-1.36, 2.2, 0.4), (-1.34, 2.25, -0.2), (-1.3, 2.26, -0.75),
                (-1.1, 2.3, -1.12)])


def sniper(k, K):
    # the stand overgrown: leafy clumps spilling over the roof's left eave and front-left
    # corner (read from the game camera), leaves hanging off the eave, vines up both left
    # stilts, a birdhouse on the back stilt and a crest under the deck
    for i, z in enumerate((-0.95, -0.1, 0.75)):
        k.add("leaf" if i % 2 == 0 else "leaf2", K.ell(fit((-1.12, 4.62, z), 0.38, 0.4), (0.38, 0.26, 0.42), 8, 4))
    k.add("leaf2", K.ell(fit((-0.55, 4.66, -1.12), 0.34, 0.34), (0.34, 0.24, 0.34), 8, 4))
    k.add("leaf", *[K.ell((-1.43, 4.2, z), (0.06, 0.34, 0.22), 6, 3) for z in (-0.6, 0.6)])
    for z in (-1.0, 1.0):
        vine(k, K, spiral((-1.34, z * 1.12), 0.13, 0.1, 3.3, 1.5, 4), every=2)
    birdhouse(k, K, (-1.2, 2.2, 1.0), yaw=90)
    crest(k, K, (-1.38, 2.75, 0.0), "-x", w=0.7, h=0.52)
    k.add("leaf2", K.ell((-0.9, 0.12, 0.0), (0.3, 0.12, 0.3), 7, 3))  # a fern clump on the ground under the stand


def grenadier(k, K):
    # a leafy tree rooted in the left sandbags with a crest on its trunk; a vine draped over
    # the front sandbags
    tree(k, K, (-1.25, 0.0, 0.05), (-1.15, 3.3, -0.05), (-1.0, 3.6, -0.15), r=0.5,
         branches=[((-1.18, 2.6, -0.02), (-0.7, 3.2, 0.25))])
    crest(k, K, (-1.18, 1.55, -0.2), "-z", w=0.42, h=0.38)
    vine(k, K, [(-1.3, 0.55, -0.7), (-0.95, 0.62, -1.15), (-0.5, 0.6, -1.32), (-0.1, 0.58, -1.38),
                (0.3, 0.6, -1.32)])


def chiller(k, K):
    # a tree behind the tank with a rope swing, its crown above the back; a vine over the
    # tank's left end
    tree(k, K, (-0.45, 0.0, 1.32), (-0.45, 4.0, 1.18), (-0.5, 4.35, 1.0), r=0.48,
         branches=[((-0.45, 3.3, 1.2), (-1.05, 3.85, 1.15))])
    k.add("rope", K.rod((-0.95, 3.75, 1.15), (-0.95, 2.4, 1.25), 0.018, 4),
          K.rod((-0.75, 3.7, 1.15), (-0.75, 2.4, 1.25), 0.018, 4))
    k.add("plank", K.rbox((-0.85, 2.38, 1.25), (0.32, 0.05, 0.14), bevel=0.01))
    vine(k, K, [(-1.4, 0.4, -0.5), (-1.42, 1.0, -0.3), (-1.4, 1.45, 0.0), (-1.42, 1.0, 0.3), (-1.4, 0.4, 0.5)])


def quartermaster(k, K):
    # a supply tree at the back with a plank lookout deck and a birdhouse; vine on the crates
    tree(k, K, (-0.35, 0.0, 1.32), (-0.35, 3.9, 1.2), (-0.45, 4.25, 1.0), r=0.48,
         branches=[((-0.35, 3.1, 1.25), (-0.85, 3.6, 1.2))])
    deck(k, K, (-0.35, 2.4, 1.2), 0.62, 0.42, posts=False)
    branch(k, K, (-0.62, 2.0, 1.25), (-0.35, 2.36, 1.25))
    birdhouse(k, K, (-0.12, 3.25, 1.05), yaw=0)
    vine(k, K, [(-1.4, 0.3, 0.2), (-1.42, 1.0, 0.0), (-1.4, 1.6, -0.2), (-1.36, 2.1, -0.4)])


def hospital(k, K):
    # a tree at the left edge leaning its crown over the tent's left slope; a leaf garland
    # along the tent's front edge; a carved crest on a post at the front-left
    tree(k, K, (-1.38, 0.0, 0.25), (-1.3, 3.5, 0.15), (-1.05, 3.6, 0.05), r=0.42,
         branches=[((-1.32, 2.8, 0.2), (-1.0, 3.2, 0.55))])
    k.add("bark", K.rod((-1.32, 0.0, -0.75), (-1.32, 1.25, -0.75), 0.05, 5))
    crest(k, K, (-1.32, 1.22, -0.82), "-z", w=0.42, h=0.36)
    vine(k, K, [(-1.36, 0.9, -1.3), (-0.95, 1.1, -1.4), (-0.6, 1.4, -1.44), (-0.3, 1.8, -1.45)], every=1)


def armory(k, K):
    # a tree at the front-left with a crest board, vines up the left wall and over the rack
    tree(k, K, (-1.05, 0.0, -1.28), (-1.12, 3.5, -1.1), (-1.0, 3.75, -0.95), r=0.48,
         branches=[((-1.1, 2.7, -1.15), (-0.6, 3.25, -1.25))])
    crest(k, K, (-1.05, 1.5, -1.38), "-z", w=0.42, h=0.38)
    vine(k, K, [(-1.44, 0.2, -0.6), (-1.46, 0.9, -0.3), (-1.44, 1.6, 0.1), (-1.46, 2.3, 0.5), (-1.42, 2.9, 0.9)])


def coil(k, K):
    # a tree at the front-left (clear of the spark ball) with a vine wound up the left leg
    tree(k, K, (-1.3, 0.0, -0.55), (-1.25, 3.5, -0.7), (-1.12, 3.75, -0.85), r=0.36, platform=(2.1, 0.55),
         branches=[((-1.27, 2.6, -0.62), (-1.38, 3.1, -0.2))])
    birdhouse(k, K, (-1.22, 2.0, -0.9), yaw=0)
    tuft(k, K, (-1.36, 3.2, -0.2), 0.2, "leaf2")
    vine(k, K, [(-1.3, 0.2, 0.3), (-1.4, 0.25, 0.7), (-1.2, 0.22, 1.0), (-0.8, 0.25, 1.38), (-0.3, 0.22, 1.4)])


def falcon(k, K):
    # a nesting tree at the front-left with a birdhouse and a nest, a vine across the front
    tree(k, K, (-1.0, 0.0, -1.32), (-1.05, 3.1, -1.2), (-1.05, 3.4, -1.1), r=0.4,
         branches=[((-1.03, 2.4, -1.25), (-0.55, 2.9, -1.35))])
    k.add("rope", K.ring((-0.55, 2.95, -1.33), 0.12, 0.04, 8, 4))  # a twig nest on the branch
    birdhouse(k, K, (-1.25, 1.9, -1.28), yaw=0)
    vine(k, K, [(-0.75, 0.25, -1.42), (-0.3, 0.3, -1.4), (0.1, 0.25, -1.42), (0.45, 0.3, -1.4)])


def ballista(k, K):
    # a tree at the back-left with a lookout deck, a vine round the turntable's left rim
    tree(k, K, (-1.28, 0.0, 0.8), (-1.22, 3.7, 0.85), (-1.0, 3.95, 0.85), r=0.45,
         branches=[((-1.24, 2.8, 0.82), (-0.75, 3.3, 1.2))])
    deck(k, K, (-1.05, 2.0, 1.12), 0.58, 0.48, posts=True, y0=0.0)
    vine(k, K, [(-1.3, 0.35, -0.6), (-1.15, 0.4, -0.95), (-0.8, 0.38, -1.2), (-0.4, 0.4, -1.35)])


def tarpit(k, K):
    # flat: a plank rope bridge over the back of the pit, a mossy log along the left edge, fern
    # tufts; nothing over 0.8
    rope_bridge(k, K, (-1.2, 0.42, 1.0), (0.78, 0.42, 1.0), n=6, sag=0.06, rail=0.22)
    k.add("bark", K.rod((-1.2, 0.0, 1.0), (-1.2, 0.72, 1.0), 0.05, 5), K.rod((-1.2, 0.0, 0.7), (-1.2, 0.72, 0.7), 0.05, 5),
          K.rod((0.78, 0.0, 1.0), (0.78, 0.72, 1.0), 0.05, 5), K.rod((0.78, 0.0, 0.7), (0.78, 0.72, 0.7), 0.05, 5))
    k.add("bark", K.rod((-1.28, 0.16, -0.55), (-1.05, 0.16, 0.45), 0.15, 7, top=0.85))
    k.add("leaf2", K.ell((-1.2, 0.33, -0.15), (0.18, 0.06, 0.4), 7, 3))
    tuft(k, K, (-0.95, 0.15, -0.75), 0.22)
    tuft(k, K, (-1.25, 0.14, 0.75), 0.2, "leaf2")


def resin(k, K):
    # a tree at the back-left, a crest on its trunk, a vine over the left wheel
    tree(k, K, (-1.3, 0.0, 0.95), (-1.2, 3.5, 0.9), (-1.0, 3.8, 0.8), r=0.45,
         branches=[((-1.22, 2.7, 0.92), (-0.75, 3.2, 1.25))])
    crest(k, K, (-1.2, 1.9, 0.72), "-z", w=0.42, h=0.38)
    vine(k, K, [(-1.45, 0.3, -0.7), (-1.47, 0.9, -0.4), (-1.46, 1.3, 0.0), (-1.47, 0.9, 0.4)])


def raptor(k, K):
    # a jungle tree inside the pen (right of the watchtower), vines along the left palisade
    tree(k, K, (0.55, 0.0, 0.4), (0.55, 3.6, 0.25), (0.55, 3.9, 0.12), r=0.45,
         branches=[((0.55, 2.8, 0.3), (0.95, 3.3, -0.2))])
    vine(k, K, [(-1.45, 1.2, -1.0), (-1.47, 1.45, -0.5), (-1.45, 1.2, 0.0), (-1.47, 1.45, 0.5), (-1.45, 1.2, 0.9)],
         every=1)


def totem(k, K):
    # a tree at the back-left with a leafy garland strung to the totem pole
    tree(k, K, (-1.05, 0.0, 1.05), (-1.0, 3.9, 1.0), (-0.95, 4.2, 0.98), r=0.5, platform=(2.3, 0.7),
         branches=[((-1.0, 3.0, 1.02), (-1.3, 3.5, 0.6))])
    pts = [(-0.95, 3.55, 0.85), (-0.75, 3.35, 0.65), (-0.55, 3.3, 0.48), (-0.35, 3.4, 0.32)]
    vine(k, K, pts, r=0.022, every=1)
    birdhouse(k, K, (-1.2, 2.3, 1.2), yaw=45)


def blimp(k, K):
    # a tree at the left with a rope bridge up to the mast's deck height... kept low: a vine up
    # a guy line, a tree with a crest
    tree(k, K, (-1.3, 0.0, 0.0), (-1.25, 3.2, -0.05), (-1.1, 3.5, -0.1), r=0.4, platform=(2.1, 0.55),
         branches=[((-1.27, 2.5, -0.02), (-1.35, 3.0, 0.45))])
    crest(k, K, (-1.28, 1.6, -0.2), "-z", w=0.4, h=0.36)
    vine(k, K, [(-1.4, 0.15, -1.3), (-1.0, 0.18, -1.42), (-0.5, 0.15, -1.4)])


def meteor(k, K):
    # a tree rising out of the trim's front-left bush, a vine and a birdhouse
    tree(k, K, (-1.25, 0.0, -1.28), (-1.2, 3.4, -1.18), (-1.05, 3.65, -1.05), r=0.42,
         branches=[((-1.22, 2.6, -1.2), (-0.7, 3.1, -1.35))])
    birdhouse(k, K, (-1.25, 2.1, -0.95), yaw=0)


def vent(k, K):
    # two trees on the volcano's flanks (left corners, clear of its middle) joined by a vine
    tree(k, K, (-1.3, 0.0, 1.0), (-1.22, 3.3, 1.12), (-1.15, 3.55, 1.15), r=0.25, platform=(1.9, 0.55),
         branches=[((-1.25, 2.6, 1.08), (-0.75, 3.0, 1.38))])
    tree(k, K, (-1.32, 0.0, -1.0), (-1.25, 2.6, -1.15), (-1.18, 2.85, -1.18), r=0.24, trunk_r=0.12)
    vine(k, K, [(-1.4, 1.6, -0.95), (-1.46, 1.3, -0.4), (-1.46, 1.25, 0.2), (-1.42, 1.5, 0.8)], every=1)


def ranger(k, K):
    # a tree at the back-left corner of the cabin, its crown over the cabin roof, with a deck;
    # a vine along the left wall
    tree(k, K, (-1.32, 0.0, 1.32), (-1.22, 3.95, 1.2), (-1.0, 4.35, 1.0), r=0.42, platform=(2.6, 0.5))
    vine(k, K, [(-1.45, 0.3, -0.6), (-1.47, 1.0, -0.3), (-1.45, 1.6, 0.1), (-1.47, 2.1, 0.5)])


DESIGNS = {"SCOUT": scout, "SNIPER": sniper, "GRENADIER": grenadier, "CHILLER": chiller,
           "QUARTERMASTER": quartermaster, "HOSPITAL": hospital, "ARMORY": armory, "COIL": coil,
           "FALCON": falcon, "BALLISTA": ballista, "TARPIT": tarpit, "RESIN": resin, "RAPTOR": raptor,
           "TOTEM": totem, "BLIMP": blimp, "METEOR": meteor, "VENT": vent, "RANGER": ranger}
