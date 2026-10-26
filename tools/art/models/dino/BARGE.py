"""BARGE - the T-Rex, the boss: a lava tyrant (PLAN 11a, as HUSK).

Fitted to today's blocky BARGE bounds (DinoLook biped: body 4.5 x 4.5 x 7, legs 4, head
3.2 x 3 x 4.2 at y 2.0 z -5.0, jaw out to z -7.8, teeth, tiny arms, tail 6.3 long):
x +-2.25, y -6.25..3.525, z -7.8..9.1 about the Root's centre. Points are Roblox studs via lp.rbx.

Reference (2026-10-26: Britannica "tyrannosaur", Australian Geographic 2026-08 on the arms,
Enchanted Learning skeleton, Wikipedia): ~12.3 m long, ~3.7 m at the hips; skull 1.2-1.5 m
long, 0.7-0.8 m deep, broad at the back so the eyes face forward (binocular); deep jaws with
banana teeth; S-curved thick neck; body held horizontal, balanced over the hips by a heavy
stiff tail; arms shorter than the head (0.6-0.7 m), two clawed fingers; massive thighs,
long shins, walks on three forward toes.
Proportions used (of the 16.9-stud box length): skull 0.24 (deep, wide at the back, the eyes
set forward on it) | neck 0.08, curving up | body 0.33, level | tail 0.38, held level |
hip height ~ 0.37 of the length | arm ~ 0.5 of the skull | thigh : shin : foot ~ 1 : 1 : 0.5.
Boss (#433 colour-by-tier): covered in LAVA - dark basalt / charred skin, molten-crust brow
bosses and back plates (accent), bright orange-yellow lava cracks, molten spots and glowing
teeth (piece `glow`: wants Neon at runtime). Cracks are traced ON the body by ray-casting.
"""

import importlib.util
import math
from pathlib import Path

BASALT = (38, 32, 32)
ASH = (78, 68, 64)
CRUST = (165, 45, 15)  # accent: cooling lava crust
LAVA = (255, 120, 20)  # glow: cracks, spots, teeth
CHAR = (14, 11, 11)


def _helpers():
    path = Path(__file__).with_name("_helpers_b.py")
    spec = importlib.util.spec_from_file_location("dino_helpers_b", path)
    mod = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(mod)
    return mod


# body axis (Roblox z -> spine height y), for aiming the crack rays at the middle of the body
SPINE = ((-4.6, 1.8), (-3.9, 0.9), (-2.6, 0.0), (-1.0, 0.1), (1.2, 0.4), (4.5, 0.7), (7.0, 0.7), (9.6, 0.4))


def _axis_y(z):
    for (z0, y0), (z1, y1) in zip(SPINE, SPINE[1:]):
        if z0 <= z <= z1:
            return y0 + (y1 - y0) * (z - z0) / (z1 - z0)
    return SPINE[-1][1]


def build(lp):
    H = _helpers()
    r = lp.rbx

    # level body: S-curved neck up into the skull, heavy tail out the back
    pts = [r(0, y, z) for z, y in SPINE]
    rad = [1.3, 1.35, 1.9, 2.15, 2.0, 1.1, 0.5, 0.08]
    edges = [(k, k + 1) for k in range(len(SPINE) - 1)]
    toes, hands = [], []
    for s in (-1, 1):
        i = len(pts)  # thigh, knee, ankle (raised), ball of the foot
        pts += [r(1.35 * s, -0.4, 1.0), r(1.5 * s, -2.8, -0.3), r(1.5 * s, -5.0, 1.1), r(1.5 * s, -6.0, 0.3)]
        rad += [1.05, 0.7, 0.42, 0.42]
        edges += [(4, i), (i, i + 1), (i + 1, i + 2), (i + 2, i + 3)]
        for dx in (-0.4, 0.0, 0.4):  # three forward toes
            t = len(pts)
            tip = (1.5 * s + dx * 1.2, -6.1, -1.0 if dx == 0 else -0.75)
            pts.append(r(*tip))
            rad.append(0.17)
            edges.append((i + 3, t))
            toes.append(tip)
        j = len(pts)  # tiny arm: shoulder, elbow, hand
        pts += [r(1.25 * s, -0.9, -2.7), r(1.45 * s, -1.6, -2.45), r(1.4 * s, -1.95, -3.05)]
        rad += [0.32, 0.22, 0.16]
        edges += [(2, j), (j, j + 1), (j + 1, j + 2)]
        hands.append((1.4 * s, -1.95, -3.05))
    body = lp.decimate_to(lp.skin("body", pts, edges, rad, subdiv=1), 1400)

    # deep skull, wide at the back; separate lower jaw (ArtRole jaw), mouth a little open
    head = lp.skin(
        "head",
        [r(0, 2.15, -4.2), r(0, 2.2, -5.4), r(0, 1.95, -6.7), r(0, 1.7, -7.7)],
        [(0, 1), (1, 2), (2, 3)],
        [(1.5, 1.55), (1.35, 1.4), (1.0, 1.05), 0.62],
    )
    head = lp.decimate_to(head, 560)
    jaw = lp.decimate_to(lp.skin(
        "jaw", [r(0, 1.0, -4.5), r(0, 0.8, -6.1), r(0, 0.72, -7.6)], [(0, 1), (1, 2)], [0.95, 0.7, 0.42]), 260)

    # lava: zig-zag cracks traced on the body / head surface, plus molten spots
    def ray_round(z, deg, y_off=0.0):
        a = math.radians(deg)
        c = (0.0, _axis_y(z) + y_off, z)
        return r(c[0] + 9 * math.sin(a), c[1] + 9 * math.cos(a), z), r(*c)

    cracks = []
    for s in (-1, 1):
        cracks.append([ray_round(-2.6 + 0.75 * k, s * (62 + 14 * (-1) ** k)) for k in range(8)])  # flank
        cracks.append([ray_round(-1.4 + 0.55 * k, s * (78 + 9 * k)) for k in range(6)])  # down the side
        cracks.append([ray_round(2.4 + 0.9 * k, s * (40 + 13 * (-1) ** k)) for k in range(6)])  # tail
        cracks.append([(r(9 * s, y, 0.9 + 0.35 * (-1) ** k), r(1.4 * s, y, 0.9))  # down the thigh
                       for k, y in enumerate((-0.6, -1.2, -1.8, -2.4))])
        cracks.append([(r(9 * s, -2.8 - 0.55 * k, -0.3 + 0.35 * k + 0.12 * (-1) ** k), r(1.5 * s, -2.8 - 0.55 * k, -0.3 + 0.35 * k))  # down the shin
                       for k in range(5)])
        cracks.append([(r(0.25 * s + 0.2 * (-1) ** k, 9, z), r(0.25 * s, 1.5, z))  # over the skull
                       for k, z in enumerate((-4.0, -4.7, -5.4, -6.1, -6.8))])
        cracks.append([(r(9 * s, 1.8 + 0.25 * (-1) ** k, z), r(0, 1.8, z))  # along the cheek
                       for k, z in enumerate((-4.3, -5.0, -5.7, -6.4))])
    cracks.append([ray_round(-3.4 + 0.85 * k, 9 * (-1) ** k) for k in range(12)])  # spine
    tubes = []
    for n, rays in enumerate(cracks):
        p = H.on_surface([body, head], rays, lift=0.02)
        if len(p) >= 2:
            rr = [0.14 if 0 < k < len(p) - 1 else 0.06 for k in range(len(p))]
            tubes.append(lp.skin(f"crack{n}", p, [(k, k + 1) for k in range(len(p) - 1)], rr, subdiv=1))
    spot_rays = [ray_round(z, d) for z, d in ((-1.8, 45), (-0.4, -50), (0.6, 30), (1.6, -35), (3.4, 60),
                                              (-0.9, 105), (0.9, -110), (5.6, -20), (-2.0, -80))]
    spot_rays += [(r(0.55 * s, 9, -5.1), r(0.55 * s, 1.5, -5.1)) for s in (-1, 1)]
    spots = [lp.ellipsoid(f"spot{k}", p, (0.32, 0.32, 0.32), 8, 5)
             for k, p in enumerate(H.on_surface([body, head], spot_rays, lift=-0.12))]
    teeth = []
    for k, z in enumerate((-5.0, -5.6, -6.2, -6.8, -7.35)):
        w = 1.1 - 0.12 * k
        for s in (-1, 1):
            teeth.append(lp.cone(f"tu{k}{s}", r(w * s * 0.85, 1.35, z), r(w * s * 0.8, 0.85, z - 0.08), 0.15, 5))
            teeth.append(lp.cone(f"tl{k}{s}", r(w * s * 0.72, 1.05, z - 0.2), r(w * s * 0.7, 1.45, z - 0.25), 0.12, 5))
    glow = lp.join("glow", lp_list(lp, tubes, 760) + [lp.decimate_to(lp.join("spots", spots), 300),
                                                      lp.decimate_to(lp.join("teeth", teeth), 140)])

    # molten crust: brow bosses over the forward eyes and a row of back plates
    crust = [lp.cone(f"brow{s}", r(0.9 * s, 2.9, -4.9), r(1.0 * s, 3.65, -4.6), 0.38, 6) for s in (-1, 1)]
    for k, z in enumerate((-2.4, -1.2, 0.0, 1.2, 2.4, 3.6, 4.8)):
        h = 0.75 - 0.06 * abs(k - 2)
        y = _axis_y(z) + (2.05 if z < 3 else 1.5 - 0.2 * (z - 3))
        crust.append(lp.cone(f"plate{k}", r(0, y - 0.3, z), r(0, y + h, z + 0.3), 0.32, 5))
    accent = lp.decimate_to(lp.join("accent", crust), 150)

    belly = lp.decimate_to(lp.ellipsoid("belly", r(0, -1.15, -1.0), (1.55, 2.8, 1.2), 12, 6), 110)

    eyes = [lp.ellipsoid(f"eye{s}", r(s * 0.95, 2.72, -5.35), (0.2, 0.2, 0.2), 6, 4) for s in (-1, 1)]
    eye = lp.join("eye", eyes)

    claws = [lp.cone(f"c{k}", r(tx, ty + 0.05, tz + 0.1), r(tx, ty - 0.12, tz - 0.4), 0.13, 5)
             for k, (tx, ty, tz) in enumerate(toes)]
    for k, (hx, hy, hz) in enumerate(hands):  # two fingers per hand
        for d in (-0.07, 0.07):
            claws.append(lp.cone(f"f{k}{d}", r(hx + d, hy, hz), r(hx + d, hy - 0.2, hz - 0.22), 0.06, 4))
    dark = lp.decimate_to(lp.join("dark", claws), 150)

    return {
        "batch": "11a",
        "budget": "boss",
        "box": ((-2.25, -6.25, -7.8), (2.25, 3.525, 9.1)),
        "pieces": [body, head, jaw, glow, accent, belly, eye, dark],
        "groups": {"head": "body", "jaw": "body"},
        "roles": {"head": "head", "jaw": "jaw"},
        "colors": {
            "body": BASALT,
            "accent": CRUST,
            "glow": LAVA,
            "belly": ASH,
            "dark": CHAR,
            "eye": (255, 220, 60),
        },
    }


def lp_list(lp, tubes, target):
    """The cracks as one decimated object (in a list, for the glow join)."""
    return [lp.decimate_to(lp.join("cracks", tubes), target)] if tubes else []
