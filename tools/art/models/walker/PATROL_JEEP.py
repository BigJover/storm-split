"""Walker PATROL_JEEP (PLAN 11d2): Ranger Station's Patrol Jeep (RangerLook.buildJeep).

RangerLook at scale 1 about the Body's centre: Body 3 x 0.9 x 5, Hood 2.8 x 0.3 x 1.6 at
(0, 0.55, -1.6), camp Stripe on top, roll bar 2.8 wide at (0, 1.6, 0.6), four wheels 0.4 x 1 x 1
at (+-1.5, -0.4, +-1.6): x +-1.7, y -0.9..1.7, z -2.5..2.5. Front = -Z.
An open safari jeep: khaki tub, flat hood with the camp stripe, slatted grille + round
headlights, fold-down windscreen, two seats + a rear bench, roll bar with a spotlight, chunky
tyres under flared fenders, a spare wheel and a jerrycan on the back.
"""

import importlib.util
from pathlib import Path

_spec = importlib.util.spec_from_file_location("_walker", Path(__file__).with_name("_walker.py"))
W = importlib.util.module_from_spec(_spec)
_spec.loader.exec_module(W)

LOOK = ((-1.7, -0.9, -2.5), (1.7, 1.7, 2.5))


def build(lp):
    w = W.Walk(lp, LOOK, 1.0, slack=0.1)
    rbox, cyl, rod, ring, bar = W.rbox, W.cyl, W.rod, W.ring, W.bar
    # tub (rear body) and the bonnet section, a lower chassis
    w.add("body", rbox((0, 0.05, 0.75), (2.7, 0.8, 3.4), bevel=0.14))
    w.add("body", rbox((0, 0.08, -1.6), (2.3, 0.75, 1.7), bevel=0.14))
    w.add("dark", rbox((0, -0.42, 0.0), (2.4, 0.24, 4.6), bevel=0.05))
    w.add("hood", rbox((0, 0.5, -1.6), (2.4, 0.14, 1.66), bevel=0.06))
    w.add("camp", rbox((0, 0.58, -1.6), (0.5, 0.04, 1.6), bevel=0.01))
    w.add("camp", rbox((0, 0.47, 0.75), (2.72, 0.06, 0.1), bevel=0.0))  # waist band round the tub
    # grille, bumper, headlights
    w.add("dark", rbox((0, 0.05, -2.46), (1.5, 0.6, 0.06), bevel=0.02))
    w.add("metal", *[rbox((x, 0.05, -2.5), (0.07, 0.5, 0.04), bevel=0) for x in (-0.5, -0.25, 0, 0.25, 0.5)])
    w.add("metal", rbox((0, -0.4, -2.42), (2.6, 0.16, 0.14), bevel=0.04))
    w.add("lamp", *[cyl((x, 0.2, -2.47), 0.15, 0.06, 10, rot=(90, 0, 0), bevel=0) for x in (-0.85, 0.85)])
    w.add("metal", *[W.ring_along((x, 0.2, -2.47), (x, 0.2, -3), 0.16, 0.03, 10, 3) for x in (-0.85, 0.85)])
    # windscreen: frame + glass, leaning back a little
    w.add("metal", bar((-1.1, 0.55, -0.72), (-1.1, 1.35, -0.6), 0.07, 0.07, bevel=0))
    w.add("metal", bar((1.1, 0.55, -0.72), (1.1, 1.35, -0.6), 0.07, 0.07, bevel=0))
    w.add("metal", bar((-1.1, 1.35, -0.6), (1.1, 1.35, -0.6), 0.07, 0.07, bevel=0))
    w.add("glass", rbox((0, 0.95, -0.66), (2.12, 0.72, 0.03), bevel=0, rot=(-9, 0, 0)))
    # seats: two buckets + a rear bench, the steering wheel (left-hand drive)
    for x in (-0.6, 0.6):
        w.add("seat", rbox((x, 0.55, -0.05), (0.75, 0.2, 0.7), bevel=0.06))
        w.add("seat", rbox((x, 0.95, 0.27), (0.7, 0.7, 0.16), bevel=0.06, rot=(-8, 0, 0)))
    w.add("seat", rbox((0, 0.55, 1.45), (2.2, 0.2, 0.7), bevel=0.06))
    w.add("seat", rbox((0, 0.92, 1.78), (2.2, 0.6, 0.15), bevel=0.06, rot=(-8, 0, 0)))
    w.add("dark", W.ring_along((-0.6, 0.95, -0.45), (-0.6, 1.25, -0.25), 0.22, 0.035, 10, 3))
    w.add("dark", rod((-0.6, 0.95, -0.45), (-0.6, 0.55, -0.7), 0.035, 5))
    # roll bar over the rear, a spotlight on it
    w.add("metal", rod((-1.25, 0.45, 0.6), (-1.25, 1.55, 0.6), 0.08, 8))
    w.add("metal", rod((1.25, 0.45, 0.6), (1.25, 1.55, 0.6), 0.08, 8))
    w.add("metal", rod((-1.25, 1.55, 0.6), (1.25, 1.55, 0.6), 0.08, 8))
    w.add("metal", rod((-1.25, 1.55, 0.6), (-1.25, 0.5, 2.3), 0.06, 6))
    w.add("metal", rod((1.25, 1.55, 0.6), (1.25, 0.5, 2.3), 0.06, 6))
    w.add("dark", cyl((0.7, 1.55, 0.4), 0.14, 0.24, 8, rot=(90, 0, 0), bevel=0))
    w.add("lamp", cyl((0.7, 1.55, 0.27), 0.11, 0.02, 8, rot=(90, 0, 0), bevel=0), piece="spotlight")
    # wheels: tyres, hubs; flared fenders over them
    for x in (-1.45, 1.45):
        for z in (-1.6, 1.6):
            w.add("tyre", cyl((x, -0.4, z), 0.5, 0.42, 12, rot=(0, 0, 90), bevel=0.08))
            w.add("metal", cyl((x + 0.2 * (1 if x > 0 else -1), -0.4, z), 0.24, 0.04, 8, rot=(0, 0, 90), bevel=0))
            w.add("body", rbox((x * 0.98, 0.2, z), (0.5, 0.1, 1.15), bevel=0.04))
    # spare wheel and jerrycan on the back
    w.add("tyre", cyl((0.55, 0.2, 2.3), 0.42, 0.26, 12, rot=(90, 0, 0), bevel=0.06))
    w.add("metal", cyl((0.55, 0.2, 2.43), 0.2, 0.04, 8, rot=(90, 0, 0), bevel=0))
    w.add("camp", rbox((-0.6, 0.15, 2.32), (0.42, 0.55, 0.2), bevel=0.04))
    colors = {"body": W.KHAKI, "hood": W.DARK_KHAKI, "camp": W.CAMP, "dark": (45, 42, 38), "metal": (88, 90, 92),
              "lamp": (250, 240, 200), "glass": (170, 200, 215), "seat": W.LEATHER, "tyre": (38, 36, 34)}
    return w.model("big", colors, {"walker": "jeep", "look": "RangerLook.buildJeep", "kind": "jeep",
                                   "display": "Patrol Jeep"}, 2300, pad=0.04)
