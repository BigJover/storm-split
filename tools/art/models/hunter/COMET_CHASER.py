"""COMET_CHASER - Tracker premium skin (Nebula theme, PREMIUM_SKINS.md, batch 11p5, #462: its own silhouette,
element cosmic / void). A sleek void stalker who runs down shooting stars - lean, fast, streaming:

  * a snug indigo void helm with a long swept-back COMET CREST (a curved fin from the brow over the
    crown, trailing past the nape, a starlight edge and a star at its head) and a starlight visor
    band pushed up on the brow; the face stays open and friendly
  * the COMET-TAIL SCARF: a thick nebula-pink wrap round the neck streaming back off the left
    shoulder into a long flowing tail that narrows to a point, starlight streaks along it and
    sparkles trailing off its end - the silhouette from behind and the side
  * a fitted indigo suit: a diagonal starlight streak across the chest from a star on the left
    breast, a single swept shoulder fin on the left, comet bracers with backswept fins
  * speed-line stripes down the legs, swept ankle fins, a star at each toe, a thigh holster

Starlight is paint group `glow` (Neon in game; Shared/SkinFx pulses / twinkles it). Built on the
shared R15 figure (_body.py) with slim Tracker proportions, same R15 envelope (#434: crest and
scarf tail extend modestly past the parts).
"""
# art-sources: _body.py variants/_nebula.py

import importlib.util
from pathlib import Path

_here = Path(__file__).parent
_spec = importlib.util.spec_from_file_location("_body", _here / "_body.py")
B = importlib.util.module_from_spec(_spec)
_spec.loader.exec_module(B)
_spec = importlib.util.spec_from_file_location("_nebula", _here / "variants" / "_nebula.py")
N = importlib.util.module_from_spec(_spec)
_spec.loader.exec_module(N)

CAP = ((0, 1.84, 0.1), (0.62, 0.52, 0.62))


def helm(body):
    c, r = CAP
    body.add("Head", "plate",
             B.ell(c, r, 12, 7),
             B.ell((0, 1.6, 0.26), (0.6, 0.5, 0.42), 10, 6),  # the back of the helm, down to the nape
             *[B.rbox((0.56 * k, 1.5, -0.02), (0.1, 0.6, 0.5), bevel=0.04, segments=1, rot=(-6, 0, -4 * k), taper=(1.0, 0.7))
               for k in (-1, 1)])  # cheek guards
    # the comet crest: a tapering fin from the brow over the crown, sweeping past the nape
    crest = [(0, 2.12, -0.4), (0, 2.34, -0.1), (0, 2.42, 0.26), (0, 2.34, 0.64), (0, 2.12, 1.0), (0, 1.84, 1.3)]
    radii = (0.2, 0.22, 0.2, 0.16, 0.1, 0.05, 0.0)
    body.add("Head", "plate", *[N.seg(B, p, q, r1, r2, 7, cap=(i == 0)) for i, (p, q, r1, r2) in
                                enumerate(zip(crest, crest[1:], radii, radii[1:]))])
    body.add("Head", "glow",
             *N.constellation(B, [(0, 2.3, -0.44), (0, 2.55, -0.1), (0, 2.62, 0.26), (0, 2.5, 0.64), (0, 2.24, 0.98), (0, 1.9, 1.3)],
                              r=0.03, s=0.04, big=(0, 2)),
             # visor band pushed up on the brow
             N.torus(B, (0, 1.98, 0.08), (0.6, 0.6), 0.05, 16, 3, rot=(-14, 0, 0), squash=1.6))
    body.add("Head", "nebula", B.ell((0, 2.0, -0.5), (0.2, 0.07, 0.06), 8, 3))  # the visor's lens
    body.add("Head", "star", *[N.star(B, N.on_ell(c, r, yaw, p, 1.01), 0.035) for yaw, p in ((60, 30), (-60, 24), (120, 50), (-130, 44))])


def scarf(body):
    # wrap round the neck
    body.add("UpperTorso", "nebula", N.torus(B, (0, 1.02, 0.02), (0.5, 0.42), 0.14, 14, 5))
    # the comet tail: off the knot behind the left shoulder, flowing down the back and out
    tail = [(-0.2, 1.0, 0.5), (-0.42, 0.72, 0.72), (-0.66, 0.32, 0.9), (-0.86, -0.12, 1.04), (-0.98, -0.58, 1.1), (-1.02, -1.0, 1.08)]
    body.add("UpperTorso", "nebula", N.ribbon(B, tail, (0.5, 0.72, 0.8, 0.7, 0.5, 0.08), t=0.05, side=(1, 0, -0.2)))
    tail2 = [(0.1, 0.96, 0.5), (0.0, 0.62, 0.66), (-0.12, 0.22, 0.76), (-0.2, -0.16, 0.8)]
    body.add("UpperTorso", "cape", N.ribbon(B, tail2, (0.34, 0.4, 0.3, 0.04), t=0.04, side=(1, 0, -0.3)))
    # starlight streaks along the tail and sparkles trailing off its end
    off = 0.035
    streak = [(x, y, z + off) for x, y, z in tail[1:-1]]
    body.add("UpperTorso", "glow",
             N.ribbon(B, [(x, y, z + 0.045) for x, y, z in tail[:-1]], (0.06, 0.12, 0.14, 0.12, 0.06), t=0.02, side=(1, 0, -0.2)),
             N.ribbon(B, [(x + 0.2, y, z + 0.04) for x, y, z in tail[1:-2]], (0.04, 0.06, 0.03), t=0.02, side=(1, 0, -0.2)),
             N.star(B, (-0.28, 1.12, 0.36), 0.08),  # the comet's head at the knot
             *N.sparkle(B, (-1.02, -1.14, 1.08), 0.14, rot=(0, 150, 0)),
             N.star(B, (-0.96, -1.34, 1.04), 0.04), N.star(B, (-1.08, -1.46, 1.12), 0.03))


def suit(body):
    f = -0.5
    body.add("UpperTorso", "plate", B.rbox((0, 0.4, -0.38), (1.6, 1.08, 0.2), bevel=0.08, segments=1, taper=(1.05, 1.0)))
    body.add("UpperTorso", "glow",
             N.rod(B, (-0.5, 0.82, f), (0.0, 0.42, f), 0.035, 4, 1.0), N.rod(B, (0.0, 0.42, f), (0.56, -0.04, f), 0.035, 4, 0.6),
             *N.sparkle(B, (-0.52, 0.82, f - 0.02), 0.2), N.star(B, (-0.52, 0.82, f - 0.03), 0.06))
    body.add("UpperTorso", "star", *[N.star(B, (x, y, f + 0.02), 0.03) for x, y in ((0.4, 0.8), (0.6, 0.4), (-0.6, 0.2), (-0.2, 0.05))])
    body.add("UpperTorso", "nebula", *N.cloud(B, (0.38, 0.12, f + 0.02), 0.15, tilt=35, n=4))
    # a starlight collar line under the scarf and a comet emblem on the back
    body.add("UpperTorso", "glow", B.rbox((0, -0.5, -0.47), (1.5, 0.04, 0.04), bevel=0.0, segments=1))
    # one swept shoulder fin on the left
    body.add("LeftUpperArm", "plate",
             B.ell((-1.38, 0.96, 0.02), (0.46, 0.16, 0.46), 10, 4, rot=(0, 0, 14)),
             N.ribbon(B, [(-1.3, 1.02, -0.3), (-1.5, 1.1, 0.1), (-1.62, 1.16, 0.5), (-1.66, 1.18, 0.78)], (0.2, 0.26, 0.18, 0.02), t=0.06, side=(0, 1, 0)))
    body.add("LeftUpperArm", "glow", N.rod(B, (-1.5, 1.22, 0.1), (-1.64, 1.27, 0.66), 0.022, 3, 0.6),
             B.ell((-1.38, 0.86, 0.02), (0.44, 0.03, 0.44), 10, 2, rot=(0, 0, 14)))
    for k, side in B.SIDES:
        x = 1.36 * k
        body.add(f"{side}LowerArm", "plate", B.cyl((x, -0.36, 0), 0.3, 0.46, 10, bevel=0.03, top=0.85),
                 N.ribbon(B, [(x + 0.2 * k, -0.2, -0.1), (x + 0.3 * k, -0.14, 0.2), (x + 0.36 * k, -0.08, 0.42)], (0.2, 0.14, 0.02), t=0.05, side=(0, 1, 0)))
        body.add(f"{side}LowerArm", "glow", B.cyl((x, -0.56, 0), 0.31, 0.035, 12, bevel=0.0),
                 N.rod(B, (x + 0.3 * k, -0.08, 0.1), (x + 0.36 * k, -0.02, 0.4), 0.02, 3, 0.6))
    # belt: a crescent buckle
    body.add("LowerTorso", "glow", N.torus(B, (0, -0.63, -0.5), 0.09, 0.025, 10, 3, rot=(90, 0, 0)))


def legs(body):
    for k, side in B.SIDES:
        lx = 0.5 * k
        body.add(f"{side}UpperLeg", "glow", B.rbox((lx + 0.33 * k, -1.38, -0.06), (0.03, 0.72, 0.05), bevel=0.0, segments=1),
                 B.rbox((lx + 0.33 * k, -1.32, 0.06), (0.03, 0.5, 0.05), bevel=0.0, segments=1))
        body.add(f"{side}LowerLeg", "plate", B.cyl((lx, -2.14, -0.02), 0.35, 0.48, 10, bevel=0.03, top=1.08))
        body.add(f"{side}LowerLeg", "glow", B.rbox((lx, -2.12, -0.37), (0.04, 0.4, 0.03), bevel=0.0, segments=1),
                 *N.sparkle(B, (lx, -1.84, -0.42), 0.15))
        body.add(f"{side}LowerLeg", "plate", B.ell((lx, -1.84, -0.3), (0.22, 0.22, 0.12), 8, 4))
        # swept ankle fins
        body.add(f"{side}Foot", "plate", N.ribbon(B, [(lx + 0.34 * k, -2.62, -0.1), (lx + 0.44 * k, -2.5, 0.2), (lx + 0.48 * k, -2.4, 0.42)],
                                                  (0.2, 0.14, 0.02), t=0.05, side=(0, 1, 0)))
        body.add(f"{side}Foot", "glow", N.star(B, (lx, -2.7, -0.7), 0.05),
                 N.rod(B, (lx + 0.43 * k, -2.44, 0.12), (lx + 0.49 * k, -2.36, 0.4), 0.018, 3, 0.6))
    # thigh holster (right)
    body.add("RightUpperLeg", "dark", B.rbox((0.86, -1.4, 0.0), (0.12, 0.5, 0.36), bevel=0.04, segments=1))
    body.add("RightUpperLeg", "glow", N.star(B, (0.93, -1.3, 0.0), 0.05))


def build(lp):
    plp = N.protect(lp)
    body = B.Body(plp)
    B.base(body, plp, {
        "arm": 0.31, "fore": 0.28, "leg": 0.37, "shin": 0.32, "torso": (1.8, 1.5, 0.9),
        "sleeve": "long", "hands": "glove", "boot": -2.36, "bootr": 0.36, "shorts": False, "armx": 1.36,
    })
    helm(body)
    scarf(body)
    suit(body)
    legs(body)
    return {
        "batch": "11p5",
        "budget": "hero",
        "rig": "r15",
        "pieces": body.finish(2600, 110),
        "colors": {
            "skin": (226, 176, 140),
            "eye": (32, 26, 40),
            "hair": (60, 40, 90),
            "shirt": (74, 56, 146),    # violet under-suit (the plates read darker on it)
            "pants": (58, 46, 124),
            "dark": (24, 22, 46),
            "glove": (28, 26, 58),
            "plate": (38, 36, 100),
            "cape": (96, 44, 150),     # violet under-strand
            "nebula": (214, 88, 184),  # the scarf: nebula pink
            "star": (244, 244, 255),
            "glow": (150, 236, 240),
        },
        "meta": {"skin": "COMET_CHASER", "hero": "PISTOL", "display": "Comet Chaser", "base": "hunter/PISTOL",
                 "theme": "NEBULA", "premium": True},
    }
