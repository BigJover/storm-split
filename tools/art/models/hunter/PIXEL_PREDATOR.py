"""PIXEL_PREDATOR - Tracker premium skin (Cyber Raptor theme, PREMIUM_SKINS.md, batch 11p3, #462:
its own silhouette, element electric / digital glitch). The sleek one: a stealth raptor suit.

  * a closed black-chrome raptor helmet: a snout ridge jutting over a glowing visor screen, the
    face shown ON the screen as two big friendly pixel eyes and a pixel smile (kid-friendly), a
    long swept crest of four fins with glowing outlines running back off the head, glowing nostrils
  * a skin-tight dark suit with light strips running the length of the arms and legs and a glowing
    V down the chest; slim shoulder plates with a small fin
  * wrist claws: one curved sickle claw off each forearm, pointing forward
  * a segmented cyber tail from the lower back, curving down behind the knees, a glowing node on
    each segment and a claw at the tip
  * slim raptor-foot boots: three toe claws and the sickle claw, glowing toe lights

Every strip, pad, visor and fin edge is group `glow` (Neon; SkinFx cycles cyan -> magenta).
Built on the shared R15 figure (_body.py) with its own style; same R15 hit envelope (#434).
"""
# art-sources: _body.py variants/_cyber.py

import importlib.util
import math
from pathlib import Path

_here = Path(__file__).parent
_spec = importlib.util.spec_from_file_location("_body", _here / "_body.py")
B = importlib.util.module_from_spec(_spec)
_spec.loader.exec_module(B)
_spec = importlib.util.spec_from_file_location("_cyber", _here / "variants" / "_cyber.py")
C = importlib.util.module_from_spec(_spec)
_spec.loader.exec_module(C)

HELM = ((0, 1.62, 0.02), (0.64, 0.64, 0.6))  # the dome over the helmet box (traces follow it)


def helmet(body):
    c, r = HELM
    body.add("Head", "plate",
             B.rbox((0, 1.6, 0.02), (1.24, 1.26, 1.18), bevel=0.46, segments=2),  # the shell, over the whole head
             # the snout ridge: a long wedge jutting forward over the visor
             B.rbox((0, 1.98, -0.68), (0.62, 0.3, 0.56), bevel=0.06, segments=1, rot=(14, 0, 0), taper=(0.6, 1.0)),
             # jaw / chin guard under the screen
             B.rbox((0, 1.24, -0.48), (0.7, 0.2, 0.3), bevel=0.06, segments=1, rot=(-10, 0, 0)))
    # the visor screen and its pixel face
    body.add("Head", "glow",
             B.rbox((0, 1.6, -0.6), (1.0, 0.48, 0.06), bevel=0.02, segments=1, rot=(-4, 0, 0)),
             *[C.pad(B, (0.08 * k, 2.02, -0.97), 0.06) for k in (-1, 1)])  # nostrils on the snout's tip
    body.add("Head", "eye",
             *[B.rbox((0.2 * k, 1.64, -0.645), (0.14, 0.18, 0.03), bevel=0.0, segments=1) for k in (-1, 1)],
             # a pixel smile: three little steps
             B.rbox((0, 1.46, -0.64), (0.16, 0.05, 0.03), bevel=0.0, segments=1),
             *[B.rbox((0.11 * k, 1.49, -0.64), (0.06, 0.05, 0.03), bevel=0.0, segments=1) for k in (-1, 1)])
    body.add("Head", "chrome", *[B.rbox((0.47 * k, 1.6, -0.36), (0.1, 0.5, 0.2), bevel=0.02, segments=1, rot=(0, 22 * k, 0)) for k in (-1, 1)])
    # the crest: four fins sweeping back off the head, each with a glowing outline behind it
    fins, rims = [], []
    for i, (y, z) in enumerate(((2.32, -0.2), (2.3, 0.1), (2.18, 0.38), (1.98, 0.6))):
        h, length = 0.5 - i * 0.06, 0.6 - i * 0.04
        fins.append(C.fin(B, (0, y, z), length, h, 0.07, rot=(-50 - i * 8, 0, 0)))
        rims.append(C.fin(B, (0, y, z), length + 0.1, h + 0.1, 0.03, rot=(-50 - i * 8, 0, 0)))
    body.add("Head", "plate", *fins)
    body.add("Head", "glow", *rims,
             *C.trace(B, [C.on_ell(c, r, 70, 10, 1.01), C.on_ell(c, r, 90, 30, 1.01), C.on_ell(c, r, 110, 30, 1.01)]),
             *C.trace(B, [C.on_ell(c, r, -70, 10, 1.01), C.on_ell(c, r, -90, 30, 1.01), C.on_ell(c, r, -110, 30, 1.01)]))


def suit(body):
    f = -0.49
    body.add("UpperTorso", "plate",
             B.rbox((0, 0.5, -0.36), (1.5, 0.9, 0.2), bevel=0.06, segments=1, taper=(1.12, 1.0)),
             B.rbox((0, 0.6, 0.38), (1.4, 0.7, 0.18), bevel=0.06, segments=1))
    body.add("UpperTorso", "glow",
             # three raptor-claw slashes across the chest
             *[o for d in (0.0, 0.26, 0.52) for o in C.trace(B, [(-0.5 + d, 0.92, f), (-0.2 + d, 0.46, f), (0.06 + d, 0.06, f)], r=0.034)],
             *C.trace(B, [(-0.7, 0.4, f + 0.06), (-0.5, 0.2, f + 0.06), (-0.5, -0.38, f + 0.06)]),
             *C.trace(B, [(0.7, 0.4, f + 0.06), (0.5, 0.2, f + 0.06), (0.5, -0.38, f + 0.06)]),
             
             *C.trace(B, [(0, 0.94, 0.48), (0, 0.3, 0.48), (-0.3, 0.1, 0.48)]),
             *C.trace(B, [(0, 0.3, 0.48), (0.3, 0.1, 0.48)]))
    body.add("LowerTorso", "plate", B.rbox((0, -0.63, 0), (1.76, 0.22, 0.9), bevel=0.05, segments=1))
    body.add("LowerTorso", "glow", B.rbox((0, -0.63, -0.46), (0.3, 0.07, 0.02), bevel=0.0, segments=1))
    for k, side in B.SIDES:
        x = 1.3 * k
        # slim shoulder plate with a small fin
        body.add(f"{side}UpperArm", "plate",
                 B.ell((x, 0.84, 0), (0.42, 0.2, 0.42), 8, 4, rot=(0, 0, -18 * k)),
                 C.fin(B, (x + 0.1 * k, 1.06, 0.06), 0.4, 0.26, 0.05, rot=(-30, 0, -18 * k)))
        # light strips down the outside of the arm and leg
        ox = x + 0.31 * k
        body.add(f"{side}UpperArm", "glow", *C.trace(B, [(ox, 0.7, 0), (ox, 0.1, 0)]))
        body.add(f"{side}LowerArm", "glow", *C.trace(B, [(ox - 0.03 * k, 0.0, 0), (ox - 0.04 * k, -0.56, 0)]))
        body.add(f"{side}LowerArm", "plate", B.cyl((x, -0.36, 0), 0.31, 0.44, 8, bevel=0.03, top=0.9))
        # the wrist claw
        cb, ct = C.claw(B, [(x + 0.18 * k, -0.4, -0.2), (x + 0.24 * k, -0.42, -0.5), (x + 0.22 * k, -0.6, -0.72)], 0.08)
        body.add(f"{side}LowerArm", "chrome", *cb, ct)
        lx = 0.5 * k
        body.add(f"{side}UpperLeg", "glow", *C.trace(B, [(lx + 0.36 * k, -1.0, 0), (lx + 0.36 * k, -1.76, 0)]))
        body.add(f"{side}UpperLeg", "plate", B.rbox((lx, -1.3, -0.3), (0.5, 0.5, 0.16), bevel=0.04, segments=1))
        body.add(f"{side}LowerLeg", "plate", B.rbox((lx, -2.06, -0.33), (0.48, 0.5, 0.14), bevel=0.04, segments=1, rot=(-6, 0, 0)))
        body.add(f"{side}LowerLeg", "glow", *C.trace(B, [(lx + 0.33 * k, -1.86, 0), (lx + 0.33 * k, -2.34, 0)]),
                 B.rbox((lx, -2.0, -0.41), (0.24, 0.04, 0.02), bevel=0.0, segments=1))
        foot(body, side, lx, k)


def foot(body, side, lx, k):
    part = f"{side}Foot"
    body.add(part, "plate", B.rbox((lx, -2.66, -0.28), (0.66, 0.16, 0.66), bevel=0.04, segments=1, rot=(-6, 0, 0)))
    claws = []
    for dx in (-0.2, 0.0, 0.2):
        cb, ct = C.claw(B, [(lx + dx, -2.7, -0.56), (lx + dx * 1.1, -2.72, -0.78), (lx + dx * 1.15, -2.86, -0.9)], 0.06)
        claws += cb + [ct]
    sb, st = C.claw(B, [(lx - 0.3 * k, -2.6, -0.14), (lx - 0.4 * k, -2.42, -0.34), (lx - 0.38 * k, -2.56, -0.56)], 0.06)
    body.add(part, "chrome", *claws, *sb, st)
    body.add(part, "glow", *[C.pad(B, (lx + dx, -2.62, -0.6), 0.05) for dx in (-0.2, 0.0, 0.2)])


def tail(body):
    """Six tapering segments from the lower back, curving down and back behind the knees."""
    pts = [(0, -0.72, 0.42), (0, -0.92, 0.72), (0, -1.2, 0.96), (0, -1.52, 1.12), (0, -1.86, 1.2), (0, -2.18, 1.22), (0, -2.44, 1.16)]
    segs, nodes = [], []
    n = len(pts) - 1
    for i, (p, q) in enumerate(zip(pts, pts[1:])):
        r1, r2 = 0.2 * (1 - i / n * 0.7), 0.2 * (1 - (i + 1) / n * 0.7)
        segs.append(C.seg(B, p, q, r1, r2 * 1.05, 6))
        nodes.append(B.ell(q, (r2 * 0.9, r2 * 0.9, r2 * 0.9), 6, 3))
    tb, tt = C.claw(B, [pts[-1], (0, -2.6, 1.0), (0, -2.66, 0.84)], 0.08)
    body.add("LowerTorso", "plate", *segs)
    body.add("LowerTorso", "chrome", *nodes, *tb, tt)
    body.add("LowerTorso", "glow", *[C.pad(B, ((p[0] + q[0]) / 2, (p[1] + q[1]) / 2 + 0.02, (p[2] + q[2]) / 2 + 0.17 * (1 - i / n * 0.6)), 0.07)
                                     for i, (p, q) in enumerate(zip(pts[:-1], pts[1:-1]))])


def build(lp):
    plp = C.protect(lp)
    body = B.Body(plp)
    B.base(body, plp, {
        "arm": 0.3, "fore": 0.27, "leg": 0.36, "shin": 0.31, "torso": (1.8, 1.5, 0.9),
        "taper": 1.08, "sleeve": "long", "hands": "gaunt", "boot": -2.36, "bootr": 0.34,
        "shorts": False, "armx": 1.32, "brow": 0.06,
    })
    helmet(body)
    suit(body)
    tail(body)
    return {
        "batch": "11p3",
        "budget": "hero",
        "rig": "r15",
        "pieces": body.finish(2400, 110),
        "colors": {
            "skin": (236, 188, 150),
            "eye": (16, 18, 30),       # the pixel eyes + smile on the visor screen
            "hair": (40, 40, 52),
            "shirt": (22, 24, 34),     # the stealth suit
            "pants": (22, 24, 34),
            "dark": (18, 20, 28),
            "gaunt": (30, 32, 44),
            **C.COLORS,
        },
        "meta": {"skin": "PIXEL_PREDATOR", "hero": "PISTOL", "display": "Pixel Predator", "base": "hunter/PISTOL",
                 "theme": "CYBER_RAPTOR", "premium": True},
    }
