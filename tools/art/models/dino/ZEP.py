"""ZEP - the Triceratops: a heavy four-legged tank with a frill and three horns (PLAN 11a, as HUSK).

Fitted to today's blocky ZEP bounds (DinoLook quadruped: body 4 x 3 x 6.5, legs 1.6, head
2.4 x 2 x 2.2; frill 4.2 x 3.4 x 0.4 at y 1.2 z -3.6; brow horns 2 long at z -5.3, nose horn
1.1; tail 4.55 long): x +-2.1, y -3.1..2.9, z -6.3..7.15 about the Root's centre.
Points are Roblox studs via lp.rbx.

Reference (2026-10-26: Britannica, Wikipedia, Nix Illustration "Ceratopsian Month #31",
I Know Dino ep. 450): adults 8-9 m; skull up to ~2.5 m, a quarter to a third of the body
length, about half of it the solid, short frill; two brow horns ~1 m over the eyes curving
forward, a short nose horn; a toothless parrot-like beak; a deep barrel body, back highest
at the hips; heavy columnar legs (hind longer, front set a little wider), hoof-like nails;
a short, thick tail held off the ground.
Proportions used (of the 13.5-stud box length): skull + frill 0.30 | brow horns 0.15,
angled forward-up ~35 deg | nose horn 0.05 | body 0.45, hips higher than the shoulders |
tail 0.30 tapering | legs ~ body depth, pillar-straight, feet wider than the shin.
High tier (#433 colour-by-tier): crystalline / volcanic - an obsidian body, a smoky amber
frill plate and glowing amber crystal horns, frill-edge spikes and back shards (piece `glow`:
wants Neon at runtime).
"""

import importlib.util
import math
from pathlib import Path

OBSIDIAN = (48, 40, 62)
SMOKE = (150, 78, 30)  # frill plate (accent)
AMBER = (255, 175, 45)  # glow: horns, crystals
NAIL = (22, 18, 28)


def _helpers():
    path = Path(__file__).with_name("_helpers_b.py")
    spec = importlib.util.spec_from_file_location("dino_helpers_b", path)
    mod = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(mod)
    return mod


def _mix(a, b, t):
    return tuple(round(x + (y - x) * t) for x, y in zip(a, b))


def build(lp):
    H = _helpers()
    r = lp.rbx

    # barrel body (hips high), short neck, thick tapering tail
    pts = [r(0, 0.35, 1.9), r(0, 0.25, -0.1), r(0, -0.05, -2.2), r(0, 0.0, -4.4),  # 0-3
           r(0, 0.1, 3.8), r(0, -0.45, 5.6), r(0, -0.9, 7.1)]  # 4-6 tail
    rad = [(1.75, 1.6), (1.95, 1.75), (1.7, 1.55), 1.25, 0.95, 0.5, 0.1]
    edges = [(0, 1), (1, 2), (2, 3), (0, 4), (4, 5), (5, 6)]
    feet = []
    for s in (-1, 1):
        for (spine, z, w, top, rr) in ((2, -2.1, 1.35, -0.5, 0.78), (0, 2.0, 1.25, -0.2, 0.88)):
            i = len(pts)  # pillar legs: shoulder/hip, knee, ankle, foot pad
            pts += [r(w * s, top, z), r(w * s, -1.6, z - 0.1), r(w * s, -2.6, z), r(w * s, -3.0, z - 0.08)]
            rad += [rr, rr * 0.8, rr * 0.7, rr * 0.85]
            edges += [(spine, i), (i, i + 1), (i + 1, i + 2), (i + 2, i + 3)]
            feet.append((w * s, -3.0, z - 0.08, rr * 0.85))
    body = lp.decimate_to(lp.skin("body", pts, edges, rad, subdiv=1), 1000)

    # skull: cheeks and snout down to the beak
    skull = lp.skin(
        "skull",
        [r(0, 0.1, -3.6), r(0, -0.25, -4.6), r(0, -0.7, -5.3), r(0, -1.1, -5.8), r(0, -1.35, -6.05)],
        [(0, 1), (1, 2), (2, 3), (3, 4)],
        [1.3, 1.1, 0.72, 0.42, 0.15],
    )
    cheeks = lp.ellipsoid("cheeks", r(0, -0.75, -4.4), (1.05, 0.95, 0.75), 12, 8)
    head = lp.join("head", [skull, cheeks])
    head = lp.decimate_to(head, 520)

    # frill: a shield leaning back from the back of the skull, edged with crystals
    rim, outline = [], []
    for k in range(13):
        a = math.pi * k / 12
        x, y = 1.65 * math.cos(a), 0.55 + 1.9 * math.sin(a)
        rim.append((x, y, -3.75 + 0.42 * (y + 0.4) / 3.3))
    outline = [r(*p) for p in rim] + [r(-1.1, -0.3, -3.8), r(0, -0.5, -3.8), r(1.1, -0.3, -3.8)]
    frill = lp.decimate_to(H.blade(lp, "accent", outline[::-1], 0.35, 1), 300)

    crystals = []
    for k, (x, y, z) in enumerate(rim[1:-1]):  # epoccipitals as glowing crystal points
        d = math.hypot(x, y - 0.55) or 1
        ox, oy = x / d, (y - 0.55) / d
        crystals.append(lp.cone(f"e{k}", r(x - ox * 0.1, y - oy * 0.1, z), r(x + ox * 0.5, y + oy * 0.5, z + 0.15), 0.2, 5))
    horns = [lp.cone(f"hb{s}", r(0.6 * s, 0.25, -4.25), r(0.85 * s, 1.05, -6.3), 0.3, 8) for s in (-1, 1)]
    horns.append(lp.cone("hn", r(0, -0.7, -5.35), r(0, 0.0, -5.85), 0.22, 7))
    for k, (z, y, h) in enumerate(((-1.0, 1.95, 0.6), (0.4, 2.1, 0.75), (1.8, 2.0, 0.6), (3.2, 1.2, 0.45))):
        for s in (-1, 1) if k % 2 else (0,):  # crystal shards along the spine
            crystals.append(lp.cone(f"b{k}{s}", r(0.4 * s, y - 0.35, z), r(0.6 * s, y + h, z + 0.25), 0.22, 5))
    glow = lp.decimate_to(lp.join("glow", horns + crystals), 450)

    belly = lp.decimate_to(lp.ellipsoid("belly", r(0, -1.1, 0.0), (1.45, 2.7, 0.9), 12, 6), 110)

    eyes = [lp.ellipsoid(f"eye{s}", r(s * 0.8, 0.1, -4.35), (0.17, 0.17, 0.17), 6, 4) for s in (-1, 1)]
    eye = lp.join("eye", eyes)

    nails = [lp.cone("beak", r(0, -1.2, -5.85), r(0, -1.55, -6.15), 0.2, 6)]
    for k, (fx, fy, fz, fr) in enumerate(feet):  # three hoof-like nails on the front of each foot
        for d in (-0.3, 0.0, 0.3):
            a = d / fr
            nails.append(lp.cone(f"n{k}{d}", r(fx + math.sin(a) * fr * 0.9, fy - 0.05, fz - math.cos(a) * fr * 0.85),
                                 r(fx + math.sin(a) * fr * 1.2, fy - 0.1, fz - math.cos(a) * fr * 1.2), 0.13, 4))
    dark = lp.join("dark", nails)

    return {
        "batch": "11a",
        "budget": "big",
        "box": ((-2.1, -3.1, -6.3), (2.1, 2.9, 7.15)),
        "pieces": [body, head, frill, glow, belly, eye, dark],
        "groups": {"head": "body"},
        "roles": {"head": "head"},
        "colors": {
            "body": OBSIDIAN,
            "accent": SMOKE,
            "glow": AMBER,
            "belly": _mix(OBSIDIAN, (255, 255, 255), 0.25),
            "dark": NAIL,
            "eye": (255, 120, 30),
        },
    }
