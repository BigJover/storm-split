"""LLAMA - the Pteranodon: a flyer, posed gliding with its wings spread (PLAN 11a, as HUSK).

Fitted to today's blocky LLAMA bounds (DinoLook: body 0.9 x 0.7 x 1.8, legLength 0 - it flies;
wings 3.4 x 0.15 x 1.3 at x +-2, head 0.5 x 0.5 x 1.4 at z -1.4, crest tilted up-back):
x +-3.7, y -0.35..1.01, z -2.1..0.9 about the Root's centre. Points are Roblox studs via lp.rbx.

Reference (2026-10-26: Britannica, Wikipedia, KU Geology "pterosaur", Triebold P. longiceps
cast): a pterosaur, not a dinosaur. Wingspan ~5.6 m (male) against a turkey-sized body; long
toothless pointed beak; a bony crest sweeping BACK from the skull, up to twice the skull's
length in males (P. longiceps: narrow, backward); the wing is a skin membrane from the
hugely elongated 4th finger back to the ankle, three small clawed fingers at the wrist;
short stubby tail; hind limbs relatively big, trailing in flight.
Proportions used (of the 7.4-stud span; the game's box decides length):
  span : nose-to-tail 2.5 : 1 | skull+beak 0.36 of the length (beak tapering to a point) |
  crest ~ skull length, swept back at ~35 deg | body (chest-hip) 0.30 | tail 0.08 |
  wing: arm to the wrist 0.40 of the half-span (leading edge pushed forward at the wrist),
  wing-finger 0.60 to a swept-back pointed tip; trailing edge scalloped in to the ankle.
High tier (#433 colour-by-tier): unnatural - deep indigo body, magenta membranes, a glowing
cyan crest (piece `glow`: wants Neon at runtime).
"""

import importlib.util
import math
from pathlib import Path

INDIGO = (70, 55, 150)
MAGENTA = (225, 50, 170)
CYAN = (90, 245, 255)
DARK = (35, 25, 55)


def _helpers():
    path = Path(__file__).with_name("_helpers_b.py")
    spec = importlib.util.spec_from_file_location("dino_helpers_b", path)
    mod = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(mod)
    return mod


def _mix(a, b, t):
    return tuple(round(x + (y - x) * t) for x, y in zip(a, b))


def _edge(t):
    """Leading / trailing edge z (Roblox) and height y of the wing at span fraction t."""
    if t < 0.4:
        le = -0.42 - 0.23 * (t / 0.4)
    else:
        le = -0.65 + 0.8 * ((t - 0.4) / 0.6) ** 1.4
    te = 0.62 + (0.17 - 0.62) * t - 0.16 * math.sin(math.pi * t)
    te = max(te, le + 0.06)
    y = 0.08 + 0.18 * t - 0.12 * t * t
    return le, te, y


def build(lp):
    H = _helpers()
    r = lp.rbx

    # body: hips -> chest -> short neck; stubby tail; legs trailing back under the membrane
    pts = [r(0, 0.0, 0.42), r(0, 0.02, -0.05), r(0, 0.08, -0.48), r(0, 0.24, -0.98),  # 0-3
           r(0, 0.03, 0.72), r(0, 0.04, 0.86)]  # 4-5 tail
    rad = [0.24, 0.3, 0.26, 0.14, 0.07, 0.02]
    edges = [(0, 1), (1, 2), (2, 3), (0, 4), (4, 5)]
    feet = []
    for s in (-1, 1):
        i = len(pts)  # thigh, knee, ankle, trailing back and a little down
        pts += [r(0.16 * s, -0.08, 0.38), r(0.22 * s, -0.2, 0.62), r(0.24 * s, -0.26, 0.84)]
        rad += [0.1, 0.06, 0.045]
        edges += [(0, i), (i, i + 1), (i + 1, i + 2)]
        feet.append((0.24 * s, -0.26, 0.84))
    body = lp.decimate_to(lp.skin("body", pts, edges, rad, subdiv=1), 290)

    # wing bones along the leading edge (arm to the wrist, then the long 4th finger)
    bones, membranes, wrists = [], [], []
    for s in (-1, 1):
        chain = []
        for t in (0.0, 0.2, 0.4, 0.7, 1.0):
            le, _, y = _edge(t)
            chain.append(r(s * (0.3 + 3.4 * t), y + 0.01, le + 0.03))
        bones.append(lp.skin(f"bone{s}", chain, [(k, k + 1) for k in range(4)],
                             [0.09, 0.08, 0.07, 0.04, 0.012], subdiv=1))
        le, _, y = _edge(0.4)
        wrists.append((s * 1.66, y, le))
        rows = []
        for i in range(15):
            t = i / 14
            le, te, y = _edge(t)
            rows.append([r(s * (0.3 + 3.4 * t), y + 0.035 * math.sin(math.pi * j / 4) * (1 - t),
                           le + (te - le) * j / 4) for j in range(5)])
        membranes.append(H.sheet(lp, f"wing{s}", rows, 0.05))
    body = lp.join("body", [body] + [lp.decimate_to(b, 90) for b in bones])
    wing = lp.decimate_to(lp.join("accent", membranes), 480)

    # skull + long toothless beak (upper) over a slimmer lower bill
    head = lp.skin(
        "head",
        [r(0, 0.32, -0.92), r(0, 0.33, -1.2), r(0, 0.28, -1.6), r(0, 0.22, -1.88), r(0, 0.18, -2.1),
         r(0, 0.2, -1.1), r(0, 0.13, -1.55), r(0, 0.12, -1.95)],
        [(0, 1), (1, 2), (2, 3), (3, 4), (0, 5), (5, 6), (6, 7)],
        [0.17, 0.13, 0.085, 0.05, 0.015, 0.1, 0.06, 0.02],
    )
    head = lp.decimate_to(head, 190)

    # the crest sweeping back and up from the top of the skull - the high-tier glow
    crest = H.blade(lp, "glow", [r(0, *p) for p in (
        (0.4, -1.18), (0.56, -1.0), (0.78, -0.72), (0.97, -0.42), (1.0, -0.33),
        (0.9, -0.3), (0.62, -0.5), (0.42, -0.68), (0.3, -0.86))], 0.08, 1)
    crest = lp.decimate_to(crest, 110)

    belly = lp.decimate_to(lp.ellipsoid("belly", r(0, -0.13, 0.05), (0.2, 0.42, 0.14), 10, 6), 70)

    eyes = [lp.ellipsoid(f"eye{s}", r(s * 0.135, 0.38, -1.02), (0.05, 0.05, 0.05), 6, 4) for s in (-1, 1)]
    eye = lp.join("eye", eyes)

    claws = []
    for k, (wx, wy, wz) in enumerate(wrists):  # three little hand claws at each wrist
        for d in (-0.06, 0.0, 0.06):
            claws.append(lp.cone(f"h{k}{d}", r(wx + d, wy - 0.02, wz + 0.02), r(wx + d * 1.3, wy - 0.1, wz - 0.1), 0.022, 4))
    for k, (fx, fy, fz) in enumerate(feet):  # toes curled back
        for d in (-0.04, 0.0, 0.04):
            claws.append(lp.cone(f"t{k}{d}", r(fx + d, fy, fz), r(fx + d * 1.4, fy - 0.06, fz + 0.1), 0.02, 4))
    dark = lp.join("dark", claws)

    return {
        "batch": "11a",
        "budget": "mid",
        "box": ((-3.7, -0.35, -2.1), (3.7, 1.01, 0.9)),
        "pieces": [body, wing, head, crest, belly, eye, dark],
        "groups": {"head": "body"},
        "roles": {"head": "head"},
        "colors": {
            "body": INDIGO,
            "accent": MAGENTA,
            "glow": CYAN,
            "belly": _mix(INDIGO, (255, 255, 255), 0.35),
            "dark": DARK,
            "eye": (25, 20, 20),
        },
    }
