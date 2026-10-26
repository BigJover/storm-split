"""BRUTE - the Raptor (Velociraptor mongoliensis): the tougher small biped after the Compy.

Fitted to today's blocky BRUTE bounds (DinoLook: body 1.1 x 1 x 2.2, legs 1.2, head
0.7 x 0.7 x 1.2, back stripe; the blocky crest is replaced by a feather tuft): x +-0.55,
y -1.7..0.95, z -2.12..2.86 about the Root's centre. Points are Roblox studs via lp.rbx.

Reference (2026-10-26: Wikipedia / Live Science / a-dinosaur-a-day; adults ~1.8 m long,
skull 23 cm): long, low, narrow skull, upper profile concave, snout ~60% of the skull;
S-curved neck; level body, hips over the feet; stiff straight tail (ossified rods) about
half the length; feathered arms (quill knobs: ~14 secondaries on the forearm) folded
bird-like against the body, three clawed fingers; legs: shin longer than thigh, short
metatarsus; toes III + IV on the ground, toe II held up off the ground carrying the
6.5 cm sickle claw.
Proportions used (of the ~5-stud nose-to-tail length, head stylised ~1.4x):
  head 0.18 (snout 60%, slightly dished on top) | neck 0.09, S-curve up |
  body chest-to-hip 0.22, level | tail 0.50 from the hips, straight, tapering |
  thigh 0.33 forward-down, shin 0.35 back-down, metatarsus 0.18 | arm 0.2, folded |
  sickle claw raised on the inside toe, the biggest claw on the model.
Low tier = natural colours: DinoLook sandy orange-brown, darker brown stripes over the
back and tail, dark-brown feather fans on the arms + head tuft (accent), tan belly.
"""

import importlib.util
from pathlib import Path

_spec = importlib.util.spec_from_file_location("_helpers_a", Path(__file__).with_name("_helpers_a.py"))
H = importlib.util.module_from_spec(_spec)
_spec.loader.exec_module(H)

SAND = (205, 140, 70)  # DinoLook BRUTE colour
STRIPE = (120, 70, 35)  # DinoLook BRUTE stripe / crest
TAN = (232, 214, 165)
CLAW = (70, 52, 38)


def build(lp):
    r = lp.rbx
    # spine (y, z, radius): hip, mid-back, chest, neck, tail
    spine = [(0.05, 0.35, 0.46), (0.0, -0.2, 0.44), (-0.02, -0.65, 0.36),
             (0.1, 1.1, 0.26), (0.14, 1.9, 0.14), (0.17, 2.82, 0.04)]
    pts = [
        r(0, 0.05, 0.35), r(0, -0.02, -0.65),  # 0 hip, 1 chest
        r(0, 0.2, -0.95), r(0, 0.56, -1.32),  # 2-3 neck: forward, then up (S-curve)
        r(0, 0.1, 1.1), r(0, 0.14, 1.9), r(0, 0.17, 2.82),  # 4-6 tail, straight and stiff
        r(0, 0.0, -0.2),  # 7 mid-back
    ]
    rad = [0.46, 0.36, 0.25, 0.21, 0.26, 0.14, 0.04, 0.44]
    edges = [(0, 7), (7, 1), (1, 2), (2, 3), (0, 4), (4, 5), (5, 6)]
    claws, fingers, fans = [], [], []
    for s in (-1, 1):
        x = 0.3 * s
        i = len(pts)  # thigh, knee, ankle (raised), ball of the foot
        pts += [r(x, -0.2, 0.35), r(x, -0.75, 0.0), r(x, -1.3, 0.5), r(x, -1.6, 0.3)]
        rad += [0.27, 0.14, 0.08, 0.075]
        edges += [(0, i), (i, i + 1), (i + 1, i + 2), (i + 2, i + 3)]
        for dx, tz in ((0.0, -0.06), (0.1 * s, 0.0)):  # toes III and IV on the ground
            t = len(pts)
            pts.append(r(x + dx, -1.66, tz))
            rad.append(0.035)
            edges.append((i + 3, t))
            claws.append(lp.cone(f"c{t}", r(x + dx, -1.66, tz + 0.03), r(x + dx, -1.69, tz - 0.1), 0.03, 4))
        # toe II, inside, held up: carries the sickle claw (two cones = a hook)
        t = len(pts)
        xi = x - 0.1 * s
        pts.append(r(xi, -1.5, 0.12))
        rad.append(0.045)
        edges.append((i + 3, t))
        claws.append(lp.cone(f"k{t}a", r(xi, -1.5, 0.13), r(xi, -1.4, -0.03), 0.05, 5))
        claws.append(lp.cone(f"k{t}b", r(xi, -1.42, -0.01), r(xi, -1.56, -0.15), 0.035, 5))
        j = len(pts)  # arm folded like a bird's wing: shoulder, elbow (back), wrist (forward)
        pts += [r(0.22 * s, -0.15, -0.6), r(0.32 * s, -0.38, -0.38), r(0.27 * s, -0.48, -0.78)]
        rad += [0.1, 0.07, 0.05]
        edges += [(1, j), (j, j + 1), (j + 1, j + 2)]
        for d in (-0.03, 0.0, 0.03):  # three fingers
            fingers.append(lp.cone(f"f{j}{d}", r(0.27 * s + d, -0.5, -0.8), r(0.27 * s + d, -0.6, -0.9), 0.022, 4))
        # forearm feather fan (wing-like), hanging below the folded arm
        fans.append(lp.ellipsoid(f"fan{s}", r(0.33 * s, -0.52, -0.56), (0.03, 0.27, 0.12), 8, 5))
    body = lp.decimate_to(lp.skin("body", pts, edges, rad, subdiv=1), 740)

    # long low skull, dished top, narrow snout; lower jaw below it (the jaw line)
    head = lp.skin(
        "head",
        [r(0, 0.55, -1.0), r(0, 0.62, -1.45), r(0, 0.53, -1.78), r(0, 0.51, -2.08),
         r(0, 0.42, -1.4), r(0, 0.37, -1.98)],
        [(0, 1), (1, 2), (2, 3), (0, 4), (4, 5)],
        [0.22, 0.22, 0.14, 0.07, 0.14, 0.06],
    )
    head = lp.decimate_to(head, 220)

    belly = lp.decimate_to(lp.ellipsoid("belly", r(0, -0.22, -0.15), (0.32, 0.6, 0.26), 10, 6), 80)

    eyes = [lp.ellipsoid(f"eye{s}", r(s * 0.2, 0.66, -1.47), (0.058, 0.058, 0.058), 6, 4) for s in (-1, 1)]
    eye = lp.join("eye", eyes)

    stripes = H.bands(lp, "st", spine, (-0.55, -0.15, 0.25, 0.75, 1.25, 1.75, 2.25))
    tuft = [lp.cone(f"t{i}", r(0, 0.74 - 0.03 * i, -1.3 + 0.13 * i), r(0, 0.95 - 0.05 * i, -1.18 + 0.15 * i), 0.065, 4)
            for i in range(3)]  # feather tuft behind the head
    accent = lp.decimate_to(lp.join("accent", stripes + tuft + fans), 270)

    dark = lp.join("dark", claws + fingers)

    return {
        "batch": "11b",
        "budget": "mid",
        "box": ((-0.55, -1.7, -2.12), (0.55, 0.95, 2.86)),
        "pieces": [body, head, belly, accent, eye, dark],
        "groups": {"head": "body"},
        "roles": {"head": "head"},
        "colors": {
            "body": SAND,
            "belly": H.mix(SAND, TAN, 0.7),
            "accent": STRIPE,
            "dark": CLAW,
            "eye": (25, 20, 20),
        },
    }
