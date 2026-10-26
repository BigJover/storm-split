"""SHIELD - Pachycephalosaurus: the bulky dome-headed biped (the head is its shield).

Fitted to today's blocky SHIELD bounds (DinoLook: body 1.4 x 1.3 x 2.2, legs 1.3, head
0.9 x 0.8 x 1, dome ball 1.1 at y 1.05 z -1.5): x +-0.7, y -1.95..1.36 (art dome top; the blocky ball reached 1.6), z -2.05..2.86 about
the Root's centre. Points are Roblox studs via lp.rbx.

Reference (2026-10-26: Wikipedia / Britannica / thedinosaurs.org; ~4.5 m long): massive
domed skull roof up to 25 cm thick; the dome's rear edge (squamosal shelf) ringed with
bony knobs and short blunt spikes, more small blunt spikes pointing up off the snout;
short, thick neck; bulky barrel body; short forelimbs with small hands; long hind legs,
three forward toes with blunt claws; long heavy tail held stiff by ossified tendons.
Proportions used (of the ~4.9-stud nose-to-tail length, dome stylised big for readability):
  head 0.22 incl. dome (dome ~0.45 of head height, snout short below/in front of it) |
  neck 0.06, short + thick | body chest-to-hip 0.25, barrel (width ~ height) |
  tail 0.49 from the hips, heavy at the root | thigh 0.3, shin 0.3, metatarsus 0.15 |
  arm 0.1, tiny.
Low tier = natural colours: DinoLook brown body, tan belly, a bolder brick-red dome
(accent) so the signature reads from across the map; knobs, snout spikes and claws dark.
"""

import importlib.util
import math
from pathlib import Path

_spec = importlib.util.spec_from_file_location("_helpers_a", Path(__file__).with_name("_helpers_a.py"))
H = importlib.util.module_from_spec(_spec)
_spec.loader.exec_module(H)

BROWN = (150, 110, 80)  # DinoLook SHIELD colour
DOME = (190, 75, 45)  # bolder than the old pale dome (215, 190, 150)
TAN = (232, 214, 165)
HORN = (70, 55, 45)


def build(lp):
    r = lp.rbx
    pts = [
        r(0, 0.05, 0.45), r(0, -0.05, -0.75),  # 0 hip, 1 chest
        r(0, 0.22, -1.05), r(0, 0.6, -1.38),  # 2-3 short thick neck, ending inside the skull
        r(0, 0.1, 1.3), r(0, 0.12, 2.1), r(0, 0.14, 2.84),  # 4-6 heavy stiff tail
        r(0, 0.02, -0.2),  # 7 mid-back
    ]
    rad = [0.62, 0.5, 0.36, 0.3, 0.32, 0.17, 0.05, 0.64]
    edges = [(0, 7), (7, 1), (1, 2), (2, 3), (0, 4), (4, 5), (5, 6)]
    claws = []
    for s in (-1, 1):
        x = 0.38 * s
        i = len(pts)  # thigh, knee, ankle (raised), ball of the foot
        pts += [r(x, -0.3, 0.4), r(x, -0.95, 0.1), r(x, -1.55, 0.5), r(x, -1.86, 0.3)]
        rad += [0.36, 0.2, 0.12, 0.1]
        edges += [(0, i), (i, i + 1), (i + 1, i + 2), (i + 2, i + 3)]
        for dx in (-0.1, 0.0, 0.1):  # three forward toes, blunt claws
            t = len(pts)
            tip = (x + dx * 1.2, -1.9, 0.02 if dx == 0 else 0.08)
            pts.append(r(*tip))
            rad.append(0.05)
            edges.append((i + 3, t))
            claws.append(lp.cone(f"c{t}", r(tip[0], tip[1], tip[2] + 0.03), r(tip[0], tip[1] - 0.02, tip[2] - 0.1), 0.045, 4))
        j = len(pts)  # short arm: shoulder, elbow, hand
        pts += [r(0.32 * s, -0.2, -0.7), r(0.38 * s, -0.45, -0.6), r(0.33 * s, -0.56, -0.85)]
        rad += [0.11, 0.08, 0.06]
        edges += [(1, j), (j, j + 1), (j + 1, j + 2)]
        for d in (-0.03, 0.03):
            claws.append(lp.cone(f"f{j}{d}", r(0.33 * s + d, -0.58, -0.88), r(0.33 * s + d, -0.66, -0.96), 0.025, 4))
    body = lp.decimate_to(lp.skin("body", pts, edges, rad, subdiv=1), 700)

    # face under the dome: cranium -> short snout, lower jaw below (the jaw line)
    head = lp.skin(
        "head",
        [r(0, 0.72, -1.2), r(0, 0.8, -1.55), r(0, 0.68, -1.88), r(0, 0.6, -2.05),
         r(0, 0.55, -1.45), r(0, 0.5, -1.95)],
        [(0, 1), (1, 2), (2, 3), (0, 4), (4, 5)],
        [0.3, 0.32, 0.19, 0.11, 0.2, 0.09],
    )
    head = lp.decimate_to(head, 220)

    # the dome (accent): a big smooth cap on the skull roof
    dome = lp.decimate_to(lp.ellipsoid("accent", r(0, 0.98, -1.5), (0.38, 0.44, 0.38), 14, 9), 190)

    belly = lp.decimate_to(lp.ellipsoid("belly", r(0, -0.3, -0.15), (0.45, 0.75, 0.35), 10, 6), 80)

    eyes = [lp.ellipsoid(f"eye{s}", r(s * 0.24, 0.84, -1.75), (0.06, 0.06, 0.06), 6, 4) for s in (-1, 1)]
    eye = lp.join("eye", eyes)

    knobs = []
    for k in range(9):  # bony knobs ringing the back and sides of the dome
        a = math.radians(60 + 30 * k)
        bx, bz = 0.36 * math.sin(a), -1.5 - 0.42 * math.cos(a)
        tx, tz = 0.5 * math.sin(a), -1.5 - 0.58 * math.cos(a)
        knobs.append(lp.cone(f"n{k}", r(bx, 0.86, bz), r(tx, 0.92, tz), 0.06, 4))
    for k, (dx, z) in enumerate(((0.0, -1.98), (-0.08, -1.88), (0.08, -1.88))):  # snout spikes
        knobs.append(lp.cone(f"sn{k}", r(dx, 0.66, z), r(dx * 1.4, 0.82, z - 0.03), 0.045, 4))
    dark = lp.join("dark", knobs + claws)

    return {
        "batch": "11b",
        "budget": "mid",
        "box": ((-0.7, -1.95, -2.05), (0.7, 1.36, 2.86)),
        "pieces": [body, head, dome, belly, eye, dark],
        "groups": {"head": "body"},
        "roles": {"head": "head"},
        "colors": {
            "body": BROWN,
            "belly": H.mix(BROWN, TAN, 0.7),
            "accent": DOME,
            "dark": HORN,
            "eye": (25, 20, 20),
        },
    }
