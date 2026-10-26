"""ARMOR - Ankylosaurus: the wide, low, plated tank with side spikes and a tail club.

Fitted to today's blocky ARMOR bounds (DinoLook quadruped: body 2.4 x 1.1 x 3, legs 0.8,
head 1.1 x 0.8 x 0.9, plates 2.6 wide to y 0.825, side spikes to x 1.65, club ball to
z 3.85): x +-1.65, y -1.35..0.825, z -2.31..3.85 about the Root's centre. Roblox studs.

Reference (2026-10-26: Wikipedia (Carpenter 2004 / Arbour & Mallon 2017) / Britannica;
~6.25 m long, 1.5 m wide, 1.7 m at the hip): low-slung, very wide body; quadruped, hind
legs longer than fore legs, short stout limbs; skull low and triangular, WIDER than long
(64.5 x 74.5 cm), a short beak, four pyramidal horns at the skull's rear corners; armour
of osteoderms in regular transverse rows over neck, back and hips with small nodules
between; side spikes along the flanks; tail club of fused osteoderms (two lobes) on a
stiff rod of interlocked vertebrae.
Proportions used (of the ~6.2-stud nose-to-club length):
  head 0.12, wider than long | neck 0.05, short | body 0.5, width ~0.8 of its length,
  height ~0.4 of its width | tail 0.33 incl. club; club 0.11 long, ~0.36 wide |
  legs short pillars, ~0.45 of the hip height.
Mid tier = earthy, starting to shift: slate blue-grey body, rust-ochre osteoderm plates
and club (accent), charcoal side spikes, horns and toenails (dark), pale grey belly.
"""

import importlib.util
import math
from pathlib import Path

_spec = importlib.util.spec_from_file_location("_helpers_a", Path(__file__).with_name("_helpers_a.py"))
H = importlib.util.module_from_spec(_spec)
_spec.loader.exec_module(H)

SLATE = (95, 105, 120)  # shifts DinoLook ARMOR's grey (125, 125, 115) toward slate
RUST = (190, 110, 45)
CHARCOAL = (50, 50, 56)
PALE = (215, 210, 200)

A, B, L, CZ = 1.2, 0.6, 1.6, 0.1  # body ellipsoid half-width, half-height, half-length, centre z


def _top(x, z):
    """Height of the body ellipsoid's upper surface at (x, z)."""
    q = 1 - (x / A) ** 2 - ((z - CZ) / L) ** 2
    return B * math.sqrt(max(q, 0.0))


def build(lp):
    r = lp.rbx
    shell = lp.ellipsoid("shell", r(0, 0, CZ), (A, L, B), 16, 10)
    # skeleton for neck, tail and legs (one island: everything hangs off the centre)
    pts = [r(0, 0, CZ), r(0, 0, -1.3), r(0, -0.02, -1.72),  # 0 centre, 1-2 short neck
           r(0, 0.05, 1.4), r(0, 0.05, 2.5), r(0, 0.02, 3.35)]  # 3-5 stiff tail into the club
    rad = [0.5, 0.42, 0.36, 0.42, 0.22, 0.13]
    edges = [(0, 1), (1, 2), (0, 3), (3, 4), (4, 5)]
    dark = []
    for sx in (-1, 1):
        for sz, hind in ((-1, False), (1, True)):
            x, z = 0.84 * sx, 0.9 * sz
            i = len(pts)  # hip/shoulder inside the shell, knee, foot
            pts += [r(x, -0.2, z), r(x * 1.04, -0.78, z + 0.05), r(x * 1.04, -1.3, z - 0.04), r(x * 1.04, -1.3, z - 0.2)]
            w = 0.3 if hind else 0.26
            rad += [w, w * 0.78, w * 0.85, w * 0.6]
            edges += [(0, i), (i, i + 1), (i + 1, i + 2), (i + 2, i + 3)]
            for dx in (-0.12, 0.0, 0.12):  # three blunt toenails
                dark.append(lp.cone(f"n{i}{dx}", r(x * 1.04 + dx, -1.28, z - 0.17), r(x * 1.04 + dx * 1.2, -1.34, z - 0.29), 0.06, 4))
    limbs = lp.skin("limbs", pts, edges, rad, subdiv=1)
    belly = lp.decimate_to(lp.ellipsoid("belly", r(0, -0.3, CZ), (1.02, 1.38, 0.32), 12, 6), 110)
    body = lp.decimate_to(lp.join("body", [shell, limbs]), 980)

    # low triangular skull, wider than long, with a short beak
    head = lp.join("head", [
        lp.ellipsoid("skull", r(0, -0.02, -1.95), (0.56, 0.38, 0.28), 12, 7),
        lp.ellipsoid("beak", r(0, -0.13, -2.2), (0.27, 0.13, 0.15), 8, 5),
    ])
    head = lp.decimate_to(head, 160)
    for sx in (-1, 1):  # four pyramidal horns at the skull's rear corners
        dark.append(lp.cone(f"hu{sx}", r(0.4 * sx, 0.12, -1.76), r(0.66 * sx, 0.24, -1.6), 0.09, 4))
        dark.append(lp.cone(f"hl{sx}", r(0.42 * sx, -0.14, -1.8), r(0.64 * sx, -0.3, -1.66), 0.08, 4))

    eyes = [lp.ellipsoid(f"eye{s}", r(s * 0.48, 0.07, -2.04), (0.065, 0.065, 0.065), 6, 4) for s in (-1, 1)]
    eye = lp.join("eye", eyes)

    plates = []
    for zi, z in enumerate((-1.05, -0.5, 0.05, 0.6, 1.15)):  # transverse rows of osteoderms
        for x in (-0.78, -0.4, 0.0, 0.4, 0.78):
            y = _top(x, z)
            plates.append(lp.cone(f"p{zi}{x}", r(x, y - 0.05, z), r(x * 1.08, y + 0.11, z + 0.03), 0.21, 6))
    for x in (-0.18, 0.18):  # a half-ring on the neck
        plates.append(lp.cone(f"pn{x}", r(x, 0.26, -1.5), r(x * 1.4, 0.44, -1.48), 0.13, 5))
    # the club: two fused lobes
    plates += [lp.ellipsoid(f"club{s}", r(0.24 * s, 0.0, 3.5), (0.33, 0.34, 0.3), 10, 6) for s in (-1, 1)]
    accent = lp.decimate_to(lp.join("accent", plates), 520)

    for k, z in enumerate((-1.0, -0.45, 0.1, 0.65, 1.2)):  # side spikes along the flanks
        xs = A * math.sqrt(1 - ((z - CZ) / L) ** 2)
        size = 0.55 if k == 0 else 0.4
        for sx in (-1, 1):
            dark.append(lp.cone(f"ss{k}{sx}", r(sx * xs * 0.9, 0.0, z), r(sx * (xs + size), -0.02, z + 0.18), 0.13, 5))
    for k, z in enumerate((1.9, 2.5, 3.0)):  # small spikes down the tail
        for sx in (-1, 1):
            w = 0.36 - 0.07 * k
            dark.append(lp.cone(f"ts{k}{sx}", r(sx * w * 0.7, 0.05, z), r(sx * (w + 0.22), 0.05, z + 0.12), 0.07, 4))
    dark = lp.join("dark", dark)

    return {
        "batch": "11b",
        "budget": "big",
        "box": ((-1.65, -1.35, -2.31), (1.65, 0.825, 3.85)),
        "pieces": [body, head, belly, accent, eye, dark],
        "groups": {"head": "body"},
        "roles": {"head": "head"},
        "colors": {
            "body": SLATE,
            "belly": H.mix(SLATE, PALE, 0.6),
            "accent": RUST,
            "dark": CHARCOAL,
            "eye": (25, 20, 20),
        },
    }
