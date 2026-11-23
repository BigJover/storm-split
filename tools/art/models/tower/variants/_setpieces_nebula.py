"""Nebula set pieces (premium theme, PREMIUM_SKINS.md, batch 11p5, #462: element cosmic / void): one themed
add-on per tower kind, `tower/SET_NEBULA_<TOWER>`, worn over that tower's art at every stage on top of the
Nebula trim (SET_NEBULA.py). Built BOLD and tall on purpose (the Lava Lord pieces read small next to the
tall towers): every tower gets one hero motif at its front-left corner sized to the tower.

Motifs:
  * `obelisk`   a tall tapered indigo star obelisk on a plinth, a constellation running up its front,
                a big starlight star on its tip and an orbit ring with a planet riding it
  * `portal`    a star portal: an upright void ring on a rock foot, a starlight ring inside it and a
                nebula-pink swirl filling it, star points round the rim
  * `telescope` a silver star-gazing telescope on a tripod, tilted at the sky, a starlight lens
  * `orrery`    an orbiting planet: a nebula planet on a tall stem in a starlight ring, a small moon
                swinging round it on an arm
  * `meteor`    meteor shards: cratered violet rocks with starlight cracks round a small crater
  * `crescent`  a standing crescent moon on a plinth, a starlight edge along its inner curve
  * `starmap`   a flat star map on the ground (constellations + meteor pebbles; Tar Pit, <= 0.8)

DESIGNS = one design(k, K) per tower; `build(lp, tower)` runs it through _setpiece_common.setpiece
(<= 800 tris, flag + Rescue Beacon columns clear, muzzle + lane clear at every stage, clip <= 35 %).
`glow` = Neon in game; Shared/SkinFx twinkles it and brightens it at stage 2.
"""

import importlib.util
import math
from pathlib import Path

TOWER = Path(__file__).resolve().parents[1]
_spec = importlib.util.spec_from_file_location("_setpiece_common", TOWER / "variants" / "_setpiece_common.py")
C = importlib.util.module_from_spec(_spec)
_spec.loader.exec_module(C)

COLORS = {"void": (34, 30, 80), "stone": (206, 198, 242), "rock": (96, 78, 140), "metal": (186, 182, 222), "nebula": (214, 88, 184),
          "glow": (150, 236, 240)}


def _yawed(at, yaw):
    x, y, z = at
    c, s = math.cos(math.radians(yaw)), math.sin(math.radians(yaw))
    return lambda dx, dy, dz: (x + dx * c + dz * s, y + dy, z - dx * s + dz * c)


def star(k, K, c, s):
    """A starlight star: a core and a four-point sparkle (vertical + horizontal spikes)."""
    k.add("glow", K.ell(c, (s * 0.5, s * 0.5, s * 0.5), 4, 2),
          K.ell(c, (s * 1.3, s * 0.2, s * 0.2), 4, 2), K.ell(c, (s * 0.2, s * 1.5, s * 0.2), 4, 2))


def obelisk(k, K, at, h=2.4, w=0.42, yaw=0.0, ring=True):
    x, y, z = at
    p = _yawed(at, yaw)
    k.add("rock", K.cyl((x, y + 0.08, z), min(w * 0.8, 1.45 - abs(x), 1.45 - abs(z)), 0.16, 6, bevel=0.0))
    k.add("stone", K.rbox((x, y + 0.16 + h / 2, z), (w, h, w), bevel=0.0, rot=(0, yaw, 0), taper=(0.5, 0.5)),
          K.rbox((x, y + 0.16 + h + 0.13, z), (w * 0.5, 0.26, w * 0.5), bevel=0.0, rot=(0, yaw, 0), taper=(0.05, 0.05)))
    star(k, K, (x, y + h + 0.62, z), 0.2)
    # constellation up the front face (-Z before yaw)
    pts = []
    for t, dx in ((0.12, 0.05), (0.34, -0.06), (0.56, 0.04), (0.8, -0.02)):
        half = w / 2 * (1 - t * 0.5) + 0.012
        pts.append(p(dx * (1 - t * 0.5), 0.16 + h * t, -half))
    k.add("glow", *[K.rod(a, b, 0.028, 3) for a, b in zip(pts, pts[1:])],
          *[K.ell(q, (0.06, 0.06, 0.06), 4, 2) for q in pts])
    if ring:
        rc = (x, y + 0.16 + h * 0.5, z)
        rr = max(w * 0.7, min(w * 1.5, 1.42 - abs(x), 1.42 - abs(z)))  # stays inside the 3 x 3 footprint
        k.add("glow", K.ring(rc, rr, 0.03, 14, 3, rot=(16, yaw, 10)))
        k.add("nebula", K.ell((x + rr * 0.96, rc[1] + 0.14, z + 0.1), (0.15, 0.15, 0.15), 7, 4))


def portal(k, K, at, r=0.55, yaw=0.0):
    x, y, z = at
    cy = y + 0.22 + r
    k.add("rock", K.rbox((x, y + 0.11, z), (r * 1.5, 0.22, 0.36), bevel=0.0, rot=(0, yaw, 0), taper=(0.8, 0.8)))
    k.add("metal", K.ring((x, cy, z), r, 0.09, 14, 3, rot=(90, yaw, 0)))
    k.add("glow", K.ring((x, cy, z), r * 0.8, 0.03, 14, 3, rot=(90, yaw, 0)))
    k.add("nebula", K.ell((x, cy, z), (r * 0.74, 0.04, r * 0.74), 10, 3, rot=(90, yaw, 0)))
    p = _yawed((x, cy, z), yaw)
    k.add("glow", *[K.ell(p(r * 1.1 * math.cos(math.radians(a)), r * 1.1 * math.sin(math.radians(a)), 0), (0.05, 0.05, 0.05), 4, 2)
                    for a in (30, 100, 160, 230, 300)])


def telescope(k, K, at, h=1.3, yaw=0.0, tilt=35):
    x, y, z = at
    c, s_ = math.cos(math.radians(yaw)), math.sin(math.radians(yaw))
    t = math.radians(tilt)
    d = (-math.cos(t) * s_, math.sin(t), -math.cos(t) * c)  # local (0, sin t, -cos t) turned by yaw

    def along(u):
        return (x + d[0] * u, y + h + d[1] * u, z + d[2] * u)

    top = (x, y + h, z)
    k.add("void", *[K.rod((x + 0.32 * math.cos(a), y, z + 0.32 * math.sin(a)), top, 0.03, 4) for a in (0.3, 2.4, 4.5)])
    k.add("metal", K.rod(along(-0.35), along(0.75), 0.1, 8, top=1.35), K.cyl(top, 0.07, 0.1, 6, bevel=0.0))
    k.add("void", K.rod(along(-0.47), along(-0.35), 0.05, 6), K.rod(along(0.08), along(0.16), 0.125, 8))
    k.add("glow", K.ell(along(0.76), (0.13, 0.13, 0.13), 6, 3))


def orrery(k, K, at, h=2.0, r=0.34):
    x, y, z = at
    k.add("rock", K.cyl((x, y + 0.08, z), 0.3, 0.16, 6, bevel=0.0))
    k.add("metal", K.rod((x, y + 0.16, z), (x, y + h - r, z), 0.04, 5),
          K.rod((x, y + h * 0.55, z), (x + 0.5, y + h * 0.55 + 0.25, z + 0.2), 0.025, 4))
    k.add("nebula", K.ell((x, y + h, z), (r, r, r), 8, 5))
    k.add("void", K.ell((x, y + h, z), (r * 1.01, r * 0.2, r * 1.01), 8, 2, rot=(0, 0, 18)))
    k.add("glow", K.ring((x, y + h, z), max(r * 1.05, min(r * 1.7, 1.38 - abs(x), 1.38 - abs(z))), 0.035, 14, 3, rot=(18, 0, 22)))
    k.add("rock", K.ell((x + 0.5, y + h * 0.55 + 0.32, z + 0.2), (0.12, 0.12, 0.12), 6, 4))
    star(k, K, (x - 0.1, y + h + r + 0.3, z), 0.12)


def meteor(k, K, at, s=1.0):
    x, y, z = at
    k.add("rock",
          K.ell((x, y + 0.31 * s, z), (0.34 * s, 0.28 * s, 0.3 * s), 7, 4, rot=(10, 20, 14)),
          K.ell((x + 0.32 * s, y + 0.19 * s, z + 0.2 * s), (0.18 * s, 0.14 * s, 0.16 * s), 6, 4, rot=(0, 40, -20)),
          K.ell((x - 0.22 * s, y + 0.12 * s, z + 0.28 * s), (0.14 * s, 0.11 * s, 0.13 * s), 6, 3))
    k.add("void", K.ring((x - 0.05 * s, y + 0.05 * s, z - 0.38 * s), 0.16 * s, 0.04 * s, 8, 3))
    k.add("glow", K.cyl((x - 0.05 * s, y + 0.04, z - 0.38 * s), 0.12 * s, 0.03, 8, bevel=0.0),
          K.rod((x - 0.12 * s, y + 0.42 * s, z - 0.24 * s), (x + 0.1 * s, y + 0.2 * s, z - 0.28 * s), 0.025, 3),
          K.rod((x + 0.1 * s, y + 0.2 * s, z - 0.28 * s), (x + 0.04 * s, y + 0.06 * s, z - 0.26 * s), 0.022, 3),
          K.rod((x + 0.2 * s, y + 0.44 * s, z), (x + 0.3 * s, y + 0.2 * s, z - 0.08 * s), 0.022, 3))


def crescent(k, K, at, h=1.8, yaw=0.0):
    """A standing crescent moon on a plinth at `at`: its back (the arc's leftmost point) on a short
    stem, its horns pointing to local +x; facing -Z before yaw."""
    x, y, z = at
    p = _yawed(at, yaw)
    R = h * 0.36
    cy = 0.3 + R  # arc centre height above `at`
    k.add("rock", K.cyl((x, y + 0.1, z), 0.26, 0.2, 6, bevel=0.0))
    pts = [p(R + R * math.cos(math.radians(a)), cy + R * math.sin(math.radians(a)), 0) for a in (60, 100, 140, 180, 220, 260, 300)]
    n = len(pts) - 1
    for i, (a, b) in enumerate(zip(pts, pts[1:])):
        t = 1 - abs(i + 0.5 - n / 2) / (n / 2)
        k.add("metal", K.rod(a, b, 0.05 + 0.12 * t, 6))
    k.add("void", K.rod((x, y + 0.2, z), pts[3], 0.05, 4))
    inner = [p(R + R * 0.72 * math.cos(math.radians(a)), cy + R * 0.72 * math.sin(math.radians(a)), -0.03) for a in (120, 160, 200, 240)]
    k.add("glow", *[K.rod(a, b, 0.03, 3) for a, b in zip(inner, inner[1:])])
    star(k, K, pts[0], 0.1)


def starmap(k, K, pts_list, y=0.14):
    for pts in pts_list:
        q = [(a, y + 0.02, b) for a, b in pts]
        k.add("glow", *[K.rod(a, b, 0.025, 3) for a, b in zip(q, q[1:])], *[K.ell(c, (0.06, 0.04, 0.06), 4, 2) for c in q])


# Hero motif at the front-left corner (-x, -z: the corner the game camera and the previews look at),
# second motifs down the left side and at the back; sized to each tower.


def scout(k, K):
    obelisk(k, K, (-1.18, 0.0, -1.18), h=3.0, w=0.34)
    telescope(k, K, (0.55, 2.42, -0.35), h=0.45, yaw=40)  # star-gazing from the hide's roof
    meteor(k, K, (-1.15, 0.0, 0.9), s=0.6)


def sniper(k, K):
    portal(k, K, (-0.45, 0.0, -1.28), r=0.78, yaw=0)  # a big star portal across the front, under the deck
    obelisk(k, K, (-1.15, 0.0, -1.15), h=3.0, w=0.4)
    orrery(k, K, (-1.05, 0.0, 0.45), h=2.6)


def grenadier(k, K):
    orrery(k, K, (-1.0, 0.0, -1.0), h=2.2, r=0.38)
    crescent(k, K, (-1.0, 0.0, 0.95), h=1.6, yaw=90)
    meteor(k, K, (0.6, 0.0, 0.95), s=0.8)


def chiller(k, K):
    obelisk(k, K, (-1.15, 0.0, -1.15), h=2.2, w=0.38)  # beside the dart launcher, clear of its lane
    portal(k, K, (-1.3, 0.0, 0.35), r=0.5, yaw=90)
    meteor(k, K, (0.45, 0.0, 1.1), s=0.7)


def quartermaster(k, K):
    telescope(k, K, (-0.8, 0.0, -0.8), h=1.5, yaw=45)
    orrery(k, K, (-1.0, 0.0, 0.45), h=2.4)
    meteor(k, K, (0.45, 0.0, 1.1), s=0.7)


def hospital(k, K):
    crescent(k, K, (-1.05, 0.0, -1.1), h=2.6, yaw=0)  # the healer's moon at the tent's door
    obelisk(k, K, (-1.15, 0.0, 0.45), h=3.0, w=0.42)
    meteor(k, K, (-0.2, 0.0, 1.1), s=0.7)


def armory(k, K):
    obelisk(k, K, (-0.95, 0.13, -0.95), h=2.6, w=0.44)
    orrery(k, K, (-0.95, 0.13, 0.4), h=1.8)
    meteor(k, K, (0.3, 0.13, 1.15), s=0.6)


def coil(k, K):
    portal(k, K, (-0.95, 0.0, -0.95), r=0.55, yaw=45)
    obelisk(k, K, (-1.15, 0.0, 0.5), h=2.8, w=0.4)
    meteor(k, K, (-0.3, 0.0, 1.15), s=0.7)


def falcon(k, K):
    telescope(k, K, (0.1, 0.0, -0.6), h=1.4, yaw=0)
    crescent(k, K, (-1.05, 0.0, -1.1), h=1.4, yaw=0)
    obelisk(k, K, (0.85, 0.0, 0.5), h=2.0, w=0.36, ring=False)


def ballista(k, K):
    orrery(k, K, (-0.95, 0.0, -0.95), h=2.2)
    meteor(k, K, (-1.1, 0.0, 0.55), s=0.85)
    obelisk(k, K, (0.15, 0.0, 0.95), h=1.8, w=0.36, ring=False)


def tarpit(k, K):
    starmap(k, K, [[(-0.95, -0.75), (-0.55, -0.25), (-0.1, -0.35), (0.3, 0.1), (0.55, 0.45)],
                   [(-0.6, 0.5), (-0.2, 0.75), (0.2, 0.6)]])
    meteor(k, K, (-1.1, 0.0, -1.1), s=0.6)
    meteor(k, K, (-1.1, 0.0, 1.05), s=0.5)


def resin(k, K):
    obelisk(k, K, (-0.95, 0.0, -0.95), h=2.6, w=0.44)
    crescent(k, K, (-1.15, 0.0, 0.5), h=1.6, yaw=90)
    meteor(k, K, (0.25, 0.0, 1.15), s=0.7)


def raptor(k, K):
    portal(k, K, (0.6, 0.0, 0.15), r=0.6, yaw=90)  # a star portal inside the pen
    obelisk(k, K, (-1.0, 0.0, -1.0), h=2.0, w=0.4, ring=False)
    meteor(k, K, (-1.1, 0.0, 0.9), s=0.7)


def totem(k, K):
    obelisk(k, K, (-1.0, 0.0, -1.0), h=3.8, w=0.5)
    orrery(k, K, (-1.0, 0.0, 0.98), h=2.8)
    crescent(k, K, (-0.2, 0.0, 1.15), h=1.4, yaw=0)


def blimp(k, K):
    obelisk(k, K, (-0.95, 0.0, -0.95), h=2.4, w=0.44)
    orrery(k, K, (-1.0, 0.0, 0.45), h=2.2)
    meteor(k, K, (0.2, 0.0, 1.1), s=0.7)


def meteor_(k, K):
    meteor(k, K, (-0.95, 0.0, -0.8), s=1.1)  # fallen stars under the beacon
    telescope(k, K, (-1.1, 0.0, 0.6), h=1.4, yaw=0)
    obelisk(k, K, (0.2, 0.0, 1.1), h=2.0, w=0.36, ring=False)


def vent(k, K):
    obelisk(k, K, (-1.1, 0.0, -1.08), h=2.4, w=0.38)
    crescent(k, K, (-1.27, 0.0, 1.05), h=1.1, yaw=90)
    meteor(k, K, (1.2, 0.0, -0.4), s=0.6)


def ranger(k, K):
    telescope(k, K, (-1.0, 0.0, -1.0), h=1.5, yaw=45, tilt=60)
    obelisk(k, K, (0.2, 0.0, -1.1), h=1.8, w=0.34, ring=False)
    orrery(k, K, (-1.12, 0.0, 1.12), h=1.9, r=0.28)


DESIGNS = {"SCOUT": scout, "SNIPER": sniper, "GRENADIER": grenadier, "CHILLER": chiller, "QUARTERMASTER": quartermaster,
           "HOSPITAL": hospital, "ARMORY": armory, "COIL": coil, "FALCON": falcon, "BALLISTA": ballista, "TARPIT": tarpit,
           "RESIN": resin, "RAPTOR": raptor, "TOTEM": totem, "BLIMP": blimp, "METEOR": meteor_, "VENT": vent, "RANGER": ranger}


def build(lp, tower):
    model = C.setpiece(lp, "NEBULA", tower, DESIGNS[tower], COLORS)
    model["batch"] = "11p5"
    model["meta"].update({"theme": "NEBULA", "premium": True})
    return model
