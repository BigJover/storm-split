"""STORM - Gallimimus: the ostrich-like sprinter, long neck and legs, small beaked head.

Fitted to today's blocky STORM bounds (DinoLook: body 1.2 x 1.1 x 2, legs 2.2, neck to
y 1.8, head 0.5 x 0.5 x 0.9 at y 1.9 z -1.2): x +-0.6, y -2.75..2.15, z -1.65..2.6 about
the Root's centre. Points are Roblox studs via lp.rbx.

Reference (2026-10-26: Wikipedia (Gallimimus bullatus) / Enchanted Learning /
a-dinosaur-a-day; ~6 m long, 1.9 m at the hip): ostrich-like; small light head with
large side-facing eyes and a toothless keratin beak, snout long and rounded at the tip;
neck proportionally long vs the trunk, carried in an S-curve; short compact trunk; weak
short arms, three curved claws; very long hind legs (long shin + long metatarsus, built
to run), three forward toes; long tail held level.
Proportions used (body 1.0 = chest-to-hip):
  hip height 2.6 | neck 1.5, near-vertical after a forward kink at the base |
  head 0.6, beak 45% of it | tail 2.2 from the hips | thigh 0.9, shin 1.0,
  metatarsus 0.7 | arm 0.4.
High-ish tier = clearly not natural: storm-teal body, pale cyan belly, an
electric-yellow crest down the head and neck plus lightning stripes over the back and
tail (accent), indigo beak and claws (dark).
"""

import importlib.util
from pathlib import Path

_spec = importlib.util.spec_from_file_location("_helpers_a", Path(__file__).with_name("_helpers_a.py"))
H = importlib.util.module_from_spec(_spec)
_spec.loader.exec_module(H)

TEAL = (35, 130, 145)
CYAN = (190, 235, 240)
VOLT = (250, 215, 40)
INDIGO = (50, 40, 110)


def build(lp):
    r = lp.rbx
    spine = [(0.05, 0.3, 0.5), (0.0, -0.2, 0.5), (-0.05, -0.65, 0.42),
             (0.1, 1.0, 0.3), (0.12, 1.8, 0.15), (0.15, 2.58, 0.04)]
    pts = [
        r(0, 0.05, 0.3), r(0, -0.05, -0.65),  # 0 hip, 1 chest
        r(0, 0.25, -0.92), r(0, 0.8, -1.06), r(0, 1.4, -1.04), r(0, 1.86, -1.0),  # 2-5 neck, up into the skull
        r(0, 0.1, 1.0), r(0, 0.12, 1.8), r(0, 0.15, 2.58),  # 6-8 tail, level
        r(0, 0.0, -0.2),  # 9 mid-back
    ]
    rad = [0.5, 0.42, 0.27, 0.19, 0.15, 0.14, 0.3, 0.15, 0.04, 0.5]
    edges = [(0, 9), (9, 1), (1, 2), (2, 3), (3, 4), (4, 5), (0, 6), (6, 7), (7, 8)]
    claws = []
    for s in (-1, 1):
        x = 0.33 * s
        i = len(pts)  # thigh, knee, ankle (high), ball of the foot: long running legs
        pts += [r(x, -0.3, 0.3), r(x, -1.1, -0.05), r(x, -2.0, 0.45), r(x, -2.66, 0.2)]
        rad += [0.3, 0.16, 0.09, 0.08]
        edges += [(0, i), (i, i + 1), (i + 1, i + 2), (i + 2, i + 3)]
        for dx in (-0.09, 0.0, 0.09):  # three forward toes
            t = len(pts)
            tip = (x + dx * 1.2, -2.72, -0.06 if dx == 0 else 0.02)
            pts.append(r(*tip))
            rad.append(0.035)
            edges.append((i + 3, t))
            claws.append(lp.cone(f"c{t}", r(tip[0], tip[1], tip[2] + 0.03), r(tip[0], tip[1] - 0.02, tip[2] - 0.11), 0.03, 4))
        j = len(pts)  # short weak arm: shoulder, elbow, hand
        pts += [r(0.28 * s, -0.15, -0.62), r(0.34 * s, -0.42, -0.5), r(0.3 * s, -0.56, -0.76)]
        rad += [0.08, 0.06, 0.045]
        edges += [(1, j), (j, j + 1), (j + 1, j + 2)]
        for d in (-0.03, 0.0, 0.03):  # three curved claws
            claws.append(lp.cone(f"f{j}{d}", r(0.3 * s + d, -0.58, -0.78), r(0.3 * s + d, -0.7, -0.84), 0.02, 4))
    body = lp.decimate_to(lp.skin("body", pts, edges, rad, subdiv=1), 740)

    # small light skull, long shallow beak rounded at the tip
    head = lp.skin(
        "head",
        [r(0, 1.92, -0.92), r(0, 1.96, -1.15), r(0, 1.88, -1.42), r(0, 1.84, -1.62),
         r(0, 1.82, -1.1), r(0, 1.8, -1.5)],
        [(0, 1), (1, 2), (2, 3), (0, 4), (4, 5)],
        [0.17, 0.2, 0.1, 0.06, 0.12, 0.05],
    )
    head = lp.decimate_to(head, 200)
    beak = lp.ellipsoid("beak", r(0, 1.84, -1.55), (0.07, 0.11, 0.07), 8, 5)  # keratin beak tip

    belly = lp.decimate_to(lp.ellipsoid("belly", r(0, -0.22, -0.15), (0.36, 0.62, 0.28), 10, 6), 80)

    eyes = [lp.ellipsoid(f"eye{s}", r(s * 0.17, 2.0, -1.18), (0.08, 0.08, 0.08), 6, 4) for s in (-1, 1)]
    eye = lp.join("eye", eyes)

    # electric crest: a feather mane from the crown down the back of the neck
    crest = [lp.cone(f"cr{k}", r(0, y, z), r(0, y + 0.1, z + 0.24), 0.08, 4)
             for k, (y, z) in enumerate(((2.03, -1.04), (1.8, -0.99), (1.52, -1.0), (1.22, -1.02), (0.92, -1.02)))]
    stripes = H.bands(lp, "st", spine, (-0.5, -0.05, 0.4, 0.95, 1.5, 2.05))
    accent = lp.decimate_to(lp.join("accent", crest + stripes), 260)

    dark = lp.join("dark", claws + [beak])

    return {
        "batch": "11b",
        "budget": "mid",
        "box": ((-0.6, -2.75, -1.65), (0.6, 2.15, 2.6)),
        "pieces": [body, head, belly, accent, eye, dark],
        "groups": {"head": "body"},
        "roles": {"head": "head"},
        "colors": {
            "body": TEAL,
            "belly": CYAN,
            "accent": VOLT,
            "dark": INDIGO,
            "eye": (25, 20, 20),
        },
    }
