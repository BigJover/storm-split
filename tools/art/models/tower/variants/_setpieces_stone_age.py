"""Stone Age set pieces (11e2, #457): one bold piece per tower kind, `tower/SET_STONE_AGE_<TOWER>`,
worn over the tower's art at every stage on top of the Stone Age trim (variants/_sets.py,
SET_STONE_AGE.py). The theme: carved standing stones and stacked rock pillars crowned with
horned skulls, curved mammoth tusks (and tusk arches), striped hide banners on bone poles,
ochre cave-paint marks, stone slabs weighting roofs. Built and checked by
variants/_setpiece_common.py (<= 800 tris, flag + Rescue Beacon corners clear, muzzles
untouched, Tar Pit flat, Vent middle clear).

Authored in Roblox studs from the tower's base (y 0), front = -Z, left = -X (_kit.py). The
pieces take the same free spots round each tower as the Treehouse ones (measured off all
three stages), so both sets fit the towers the same way.
"""

import math

STONE = (196, 168, 118)  # warm sandstone: reads against the set's grey paint
STONE2 = (150, 124, 92)
BONE = (236, 226, 198)
HIDE = (160, 112, 70)
STRIPE = (88, 60, 38)
OCHRE = (176, 70, 44)
MOSS = (100, 132, 60)
POLE = (112, 82, 52)
DARK = (46, 40, 36)
COLORS = {"stone": STONE, "stone2": STONE2, "bone": BONE, "hide": HIDE, "stripe": STRIPE, "ochre": OCHRE,
          "moss": MOSS, "pole": POLE, "dark": DARK}

LIM = 1.49  # the Body's half width (1.5), a hair inside


def fit(c, rx, rz):
    """Slide a centre so its x / z half sizes stay inside the 3 x 3 footprint."""
    x, y, z = c
    return (max(-LIM + rx, min(LIM - rx, x)), y, max(-LIM + rz, min(LIM - rz, z)))


# ---------------------------------------------------------------- motifs

def menhir(k, K, foot, h, w=0.42, d=0.3, yaw=0.0, mark=True):
    """A tapered standing stone with an ochre band and a mossy cap (w, d scaled 1.3x)."""
    w, d = w * 1.3, d * 1.3
    x, _, z = fit(foot, (w * w + d * d) ** 0.5 / 2 + 0.06, (w * w + d * d) ** 0.5 / 2 + 0.06)
    k.add("stone", K.rbox((x, h / 2, z), (w, h, d), bevel=0.06, segments=1, taper=(0.72, 0.8), rot=(0, yaw, 3)))
    if mark:
        k.add("ochre", K.rbox((x, h * 0.62, z), (w * 0.88, 0.07, d + 0.02), bevel=0.0, rot=(0, yaw, 3)))
    k.add("moss", K.ell((x, h - 0.02, z), (w * 0.34, 0.07, d * 0.4), 7, 3))


def pillar(k, K, foot, h, r=0.2):
    """Stacked rough stone drums with carved bands, a flat cap stone on top."""
    x, _, z = fit(foot, r * 1.85, r * 1.85)  # the cap stone (2.6 r, turned 20 degrees)
    n = max(2, int(h / 0.7))
    step = h / n
    drums, bands = [], []
    for i in range(n):
        off = 0.03 * (1 if i % 2 else -1)
        drums.append(K.cyl((x + off, step * (i + 0.5), z - off), r * (1.0 - 0.06 * i), step - 0.04, 7, bevel=0))
        if i:
            bands.append(K.cyl((x, step * i, z), r * 1.08, 0.06, 7, bevel=0))
    k.add("stone", *drums)
    k.add("stone2", *bands, K.rbox((x, h + 0.05, z), (r * 2.6, 0.1, r * 2.6), bevel=0.03, rot=(0, 20, 0)))
    return x, z


def horn(a, b, c, r, K):
    """A curved horn / tusk through a -> b -> c, tapering."""
    a, b, c = [fit((p[0], max(p[1], r), p[2]), r + 0.01, r + 0.01) for p in (a, b, c)]
    return [K.rod(a, b, r, 6, top=0.8), K.rod(b, c, r * 0.8, 6, top=0.25)]


def skull(k, K, c, s=1.0, facing="-z"):
    """A horned dino skull: cranium, snout, dark eye sockets, two horns curving up and out."""
    x, y, z = fit(c, 0.34 * s, 0.44 * s) if facing == "-x" else fit(c, 0.44 * s, 0.34 * s)
    fz = -1 if facing == "-z" else 1
    if facing == "-x":
        k.add("bone", K.ell((x, y, z), (0.2 * s, 0.17 * s, 0.22 * s), 8, 4),
              K.rbox((x - 0.2 * s, y - 0.06 * s, z), (0.22 * s, 0.13 * s, 0.17 * s), bevel=0.04, taper=(0.7, 0.7)))
        k.add("dark", K.ell((x - 0.17 * s, y + 0.05 * s, z - 0.09 * s), (0.04, 0.045, 0.045), 5, 3),
              K.ell((x - 0.17 * s, y + 0.05 * s, z + 0.09 * s), (0.04, 0.045, 0.045), 5, 3))
        hs = []
        for sz in (-1, 1):
            hs += horn((x, y + 0.08 * s, z + sz * 0.15 * s), (x - 0.05 * s, y + 0.25 * s, z + sz * 0.32 * s),
                       (x - 0.14 * s, y + 0.45 * s, z + sz * 0.36 * s), 0.05 * s, K)
        k.add("bone", *hs)
        return
    k.add("bone", K.ell((x, y, z), (0.22 * s, 0.17 * s, 0.2 * s), 8, 4),
          K.rbox((x, y - 0.06 * s, z + fz * 0.2 * s), (0.17 * s, 0.13 * s, 0.22 * s), bevel=0.04, taper=(0.7, 0.7)))
    k.add("dark", K.ell((x - 0.09 * s, y + 0.05 * s, z + fz * 0.17 * s), (0.045, 0.045, 0.04), 5, 3),
          K.ell((x + 0.09 * s, y + 0.05 * s, z + fz * 0.17 * s), (0.045, 0.045, 0.04), 5, 3))
    hs = []
    for sx in (-1, 1):
        hs += horn((x + sx * 0.15 * s, y + 0.08 * s, z), (x + sx * 0.32 * s, y + 0.25 * s, z + fz * 0.05 * s),
                   (x + sx * 0.36 * s, y + 0.45 * s, z + fz * 0.14 * s), 0.05 * s, K)
    k.add("bone", *hs)


def tusk(k, K, foot, mid, tip, r=0.07):
    k.add("bone", *horn(foot, mid, tip, r, K))


def banner(k, K, top, w=0.5, h=0.7, facing="-z", stripes=2):
    """A hide banner hanging from a bone crossbar at `top` (its top centre), striped, ragged
    (a tapered hem)."""
    x, y, z = top
    if facing == "-x":
        x, y, z = fit(top, 0.05, w / 2 + 0.08)
        k.add("bone", K.rod((x, y + 0.03, z - w / 2 - 0.07), (x, y + 0.03, z + w / 2 + 0.07), 0.03, 5))
        k.add("hide", K.rbox((x, y - h / 2, z), (0.04, h, w), bevel=0.0, taper=(1.0, 1.0)),
              K.rbox((x, y - h - 0.06, z), (0.04, 0.12, w * 0.8), bevel=0.0, taper=(1.0, 1.25), rot=(180, 0, 0)))
        k.add("stripe", *[K.rbox((x - 0.012, y - h * (0.28 + 0.3 * i), z), (0.03, 0.06, w * 0.96), bevel=0.0)
                          for i in range(stripes)])
        return
    x, y, z = fit(top, w / 2 + 0.08, 0.05)
    k.add("bone", K.rod((x - w / 2 - 0.07, y + 0.03, z), (x + w / 2 + 0.07, y + 0.03, z), 0.03, 5))
    k.add("hide", K.rbox((x, y - h / 2, z), (w, h, 0.04), bevel=0.0),
          K.rbox((x, y - h - 0.06, z), (w * 0.8, 0.12, 0.04), bevel=0.0, taper=(1.25, 1.0), rot=(180, 0, 0)))
    dz = -0.012 if facing == "-z" else 0.012
    k.add("stripe", *[K.rbox((x, y - h * (0.28 + 0.3 * i), z + dz), (w * 0.96, 0.06, 0.03), bevel=0.0)
                      for i in range(stripes)])


def pole(k, K, foot, top, r=0.045):
    k.add("pole", K.rod(fit(foot, r, r), fit(top, r, r), r, 6))


def slab(k, K, c, size, yaw=0.0, tilt=0.0):
    k.add("stone2", K.rbox(fit(c, size[0] / 2, size[2] / 2), size, bevel=0.04, segments=1, rot=(tilt, yaw, 0)))


def cairn(k, K, c, s=1.0):
    x, y, z = c
    k.add("stone", K.ell(fit((x, y + 0.12 * s, z), 0.26 * s, 0.24 * s), (0.26 * s, 0.13 * s, 0.24 * s), 7, 3))
    k.add("stone2", K.ell(fit((x + 0.03, y + 0.31 * s, z - 0.02), 0.18 * s, 0.17 * s), (0.18 * s, 0.1 * s, 0.17 * s), 7, 3),
          K.ell(fit((x - 0.02, y + 0.45 * s, z + 0.01), 0.11 * s, 0.1 * s), (0.11 * s, 0.07 * s, 0.1 * s), 6, 3))


def standard(k, K, foot, h, facing="-z", banner_w=0.56, banner_h=0.8, s=1.0):
    """The set's signature: a chunky carved stone pillar crowned by a big horned skull, a hide
    banner hung from a crossbar just under it (s is scaled 1.35x so it reads from the camera)."""
    s = s * 1.35
    x, z = pillar(k, K, foot, h, r=0.26)
    skull(k, K, (x, h + 0.28 * s, z), s, facing)
    off = {"-z": (0, -0.3), "+z": (0, 0.3), "-x": (-0.3, 0)}[facing]
    banner(k, K, (x + off[0], h - 0.25, z + off[1]), banner_w, banner_h, facing)


# ---------------------------------------------------------------- the 18 pieces

def scout(k, K):
    # a skull-crowned stone standard at the back-left corner, its hide banner facing the front;
    # crossed tusks on the hide's front-left roof corner, ochre-marked slabs on the left eave
    standard(k, K, (-1.28, 0.0, 1.28), 3.7, "-z", s=1.25)
    tusk(k, K, (-1.2, 2.25, -0.95), (-1.0, 2.75, -1.2), (-0.7, 3.0, -1.32))
    tusk(k, K, (-0.8, 2.25, -1.2), (-1.1, 2.75, -1.3), (-1.36, 3.0, -1.1))
    slab(k, K, (-1.22, 2.36, 0.0), (0.3, 0.12, 0.5), yaw=8)
    slab(k, K, (-1.2, 2.36, 0.6), (0.28, 0.11, 0.4), yaw=-10)


def sniper(k, K):
    # the stand's roof weighted with stone slabs along the left eave and a big horned skull on
    # its front-left corner (read from the game camera); hide banners hung off the left eave;
    # a cairn under the stand
    for z, yaw in ((-0.85, 6), (-0.15, -8), (0.6, 4)):
        k.add("stone", K.rbox(fit((-1.12, 4.68, z), 0.3, 0.32), (0.56, 0.2, 0.6), bevel=0.05, segments=1, rot=(0, yaw, 0)))
        k.add("moss", K.ell(fit((-1.1, 4.79, z + 0.05), 0.2, 0.2), (0.2, 0.05, 0.2), 6, 3))
    skull(k, K, (-0.9, 4.4, -1.05), 1.3, "-z")
    banner(k, K, (-1.44, 4.3, -0.55), 0.5, 0.75, "-x")
    banner(k, K, (-1.44, 4.3, 0.55), 0.5, 0.75, "-x")
    cairn(k, K, (-0.9, 0.0, 0.0), 1.2)


def grenadier(k, K):
    # a standing stone rooted in the left sandbags with a skull on top; tusks over the front bags
    menhir(k, K, (-1.22, 0.0, 0.0), 3.2, w=0.48, d=0.36)
    skull(k, K, (-1.18, 3.42, 0.0), 1.15, "-z")
    tusk(k, K, (-1.25, 0.5, -0.6), (-1.1, 0.95, -1.15), (-0.7, 1.05, -1.38))
    tusk(k, K, (0.6, 0.5, -1.0), (0.75, 0.95, -1.3), (0.4, 1.05, -1.42))


def chiller(k, K):
    # a tall stone standard behind the tank with a mammoth-tusk arch over it; a hide over the
    # tank's left end
    standard(k, K, (-0.45, 0.0, 1.3), 3.55, "-z", s=1.2)
    tusk(k, K, (-1.25, 0.0, 1.3), (-1.3, 1.6, 1.25), (-0.95, 2.4, 1.25), r=0.09)
    tusk(k, K, (0.35, 0.0, 1.3), (0.4, 1.6, 1.25), (0.05, 2.4, 1.25), r=0.09)
    banner(k, K, (-1.44, 1.55, 0.0), 0.6, 0.6, "-x")


def quartermaster(k, K):
    # a hide-banner standard at the back with a cairn of supply stones and a tusk pair
    standard(k, K, (-0.35, 0.0, 1.3), 3.55, "-z", banner_w=0.6, banner_h=0.9, s=1.2)
    cairn(k, K, (-0.85, 0.0, 1.25), 1.0)
    tusk(k, K, (0.15, 0.0, 1.32), (0.2, 0.8, 1.3), (-0.05, 1.3, 1.22))


def hospital(k, K):
    # a skull pillar at the left edge with a hide banner over the tent's left slope; a
    # healer's stone (ochre-marked menhir) at the front-left
    standard(k, K, (-1.3, 0.0, 0.25), 3.3, "-x", banner_w=0.56, banner_h=0.7, s=1.15)
    menhir(k, K, (-1.25, 0.0, -0.8), 1.25, w=0.34, d=0.24)


def armory(k, K):
    # a war standard at the front-left with a skull, tusks crossed on the left wall
    standard(k, K, (-1.1, 0.0, -1.25), 3.3, "-z", s=1.2)
    tusk(k, K, (-1.4, 0.4, -0.5), (-1.44, 1.4, -0.1), (-1.38, 2.1, 0.35))
    tusk(k, K, (-1.4, 0.4, 0.55), (-1.44, 1.4, 0.15), (-1.38, 2.1, -0.3))


def coil(k, K):
    # a skull standard at the front-left (clear of the spark ball), a stone ring piece behind
    standard(k, K, (-1.28, 0.0, -0.65), 2.9, "-z", s=1.1)
    cairn(k, K, (-1.2, 0.0, 0.7), 1.0)
    menhir(k, K, (-0.5, 0.0, 1.3), 0.9, w=0.3, d=0.22, mark=False)


def falcon(k, K):
    # a perch-stone with a bird skull and a hide banner at the front-left, tusks at the front
    standard(k, K, (-1.05, 0.0, -1.3), 2.9, "-z", s=1.1)
    tusk(k, K, (-0.55, 0.0, -1.38), (-0.4, 0.7, -1.4), (-0.05, 0.95, -1.36))


def ballista(k, K):
    # a skull standard at the back-left behind the turntable, tusks round the left rim
    standard(k, K, (-1.25, 0.0, 0.85), 3.5, "-z", s=1.2)
    tusk(k, K, (-1.35, 0.0, -0.55), (-1.4, 0.7, -0.9), (-1.2, 1.0, -1.25))
    cairn(k, K, (-0.9, 0.0, 1.25), 0.9)


def tarpit(k, K):
    # flat (<= 0.8): a sunken mammoth's tusks arching low over the back of the pit, its skull at
    # the left edge, stepping stones across the tar
    tusk(k, K, (-1.25, 0.0, 1.05), (-0.75, 0.62, 1.15), (-0.15, 0.58, 1.0), r=0.14)
    tusk(k, K, (0.8, 0.0, 1.05), (0.35, 0.62, 1.15), (-0.05, 0.58, 1.0), r=0.14)
    k.add("bone", K.ell((-1.1, 0.3, 0.1), (0.34, 0.28, 0.4), 8, 4),
          K.rbox((-1.1, 0.2, -0.42), (0.28, 0.2, 0.36), bevel=0.05, taper=(0.7, 0.7)))
    k.add("dark", K.ell((-1.22, 0.42, -0.24), (0.06, 0.06, 0.05), 5, 3), K.ell((-0.98, 0.42, -0.24), (0.06, 0.06, 0.05), 5, 3))
    k.add("stone2", *[K.cyl((x, 0.2, z), 0.17, 0.12, 7, bevel=0.03) for x, z in ((-0.7, -0.8), (-0.2, -0.45), (0.3, -0.15))])


def resin(k, K):
    # a skull standard at the back-left, tusks over the left wheel
    standard(k, K, (-1.28, 0.0, 0.95), 3.4, "-z", s=1.2)
    tusk(k, K, (-1.4, 0.0, -0.85), (-1.45, 0.9, -0.45), (-1.38, 1.5, 0.0))


def raptor(k, K):
    # a great tusk arch inside the pen (right of the watchtower) with a skull at its keystone
    tusk(k, K, (0.2, 0.0, 0.45), (0.15, 2.0, 0.35), (0.55, 3.1, 0.2), r=0.15)
    tusk(k, K, (1.0, 0.0, -0.1), (1.05, 2.0, 0.0), (0.65, 3.1, 0.15), r=0.15)
    skull(k, K, (0.6, 3.2, 0.18), 1.2, "-z")
    k.add("stone2", *[K.cyl((x, 0.09, z), 0.22, 0.18, 7, bevel=0) for x, z in ((0.2, 0.45), (1.0, -0.1))])  # footing stones
    k.add("hide", K.rbox((-1.44, 1.05, 0.0), (0.04, 0.5, 1.4), bevel=0.0))
    k.add("stripe", K.rbox((-1.46, 1.1, 0.0), (0.03, 0.07, 1.36), bevel=0.0))


def totem(k, K):
    # a standing stone at the back-left with a hide garland strung to the totem pole
    menhir(k, K, (-1.05, 0.0, 1.05), 3.6, w=0.5, d=0.38, yaw=40)
    skull(k, K, (-1.05, 3.85, 1.05), 1.2, "-z")
    pts = [(-0.95, 3.2, 0.85), (-0.7, 3.0, 0.62), (-0.5, 2.98, 0.45), (-0.3, 3.1, 0.3)]
    k.add("pole", *[K.rod(a, b, 0.02, 4) for a, b in zip(pts, pts[1:])])
    k.add("hide", *[K.rbox((p[0], p[1] - 0.14, p[2]), (0.16, 0.22, 0.03), bevel=0.0, taper=(0.4, 1.0), rot=(180, -45, 0))
                    for p in pts[1:]])


def blimp(k, K):
    # a skull standard at the left of the mast, stones along the front
    standard(k, K, (-1.28, 0.0, 0.0), 3.2, "-z", s=1.15)
    cairn(k, K, (-0.6, 0.0, -1.25), 0.8)


def meteor(k, K):
    # a star-watcher's stone at the front-left with ochre marks and a skull
    menhir(k, K, (-1.25, 0.0, -1.2), 3.0, w=0.46, d=0.34, yaw=-30)
    skull(k, K, (-1.22, 3.22, -1.18), 1.1, "-z")
    k.add("ochre", K.ell((-1.0, 2.0, -1.31), (0.08, 0.08, 0.02), 6, 3), K.ell((-1.1, 1.6, -1.34), (0.06, 0.06, 0.02), 6, 3))


def vent(k, K):
    # two standing stones on the volcano's left flanks (clear of its middle), a skull on the tall one
    menhir(k, K, (-1.22, 0.0, 1.2), 3.1, w=0.42, d=0.32, yaw=45)
    skull(k, K, (-1.22, 3.32, 1.2), 1.0, "-z")
    menhir(k, K, (-1.22, 0.0, -1.2), 2.0, w=0.36, d=0.28, yaw=-45)
    tusk(k, K, (-1.4, 0.0, -0.4), (-1.45, 0.8, -0.1), (-1.38, 1.2, 0.3))


def ranger(k, K):
    # a skull standard at the cabin's back-left corner, hides on the left wall
    standard(k, K, (-1.3, 0.0, 1.3), 3.7, "-z", s=1.2)
    banner(k, K, (-1.44, 2.0, -0.2), 0.6, 0.7, "-x")


DESIGNS = {"SCOUT": scout, "SNIPER": sniper, "GRENADIER": grenadier, "CHILLER": chiller,
           "QUARTERMASTER": quartermaster, "HOSPITAL": hospital, "ARMORY": armory, "COIL": coil,
           "FALCON": falcon, "BALLISTA": ballista, "TARPIT": tarpit, "RESIN": resin, "RAPTOR": raptor,
           "TOTEM": totem, "BLIMP": blimp, "METEOR": meteor, "VENT": vent, "RANGER": ranger}
