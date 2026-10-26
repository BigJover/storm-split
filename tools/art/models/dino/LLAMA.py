"""LLAMA - the Pteranodon: a flyer, posed gliding with its wings spread (PLAN 11a, as HUSK).

Fitted to today's blocky LLAMA bounds (DinoLook: body 0.9 x 0.7 x 1.8, legLength 0 - it flies;
wings 3.4 x 0.15 x 1.3 at x +-2, head 0.5 x 0.5 x 1.4 at z -1.4, crest tilted up-back):
x +-3.7, y -0.35..1.01, z -2.1..0.9 about the Root's centre. Points are Roblox studs via lp.rbx.

Reference (2026-10-26: Britannica, Wikipedia, KU Geology "pterosaur", Triebold P. longiceps
cast): a pterosaur, not a dinosaur. Wingspan ~5.6 m (male) against a turkey-sized body; long
toothless pointed beak; a bony crest sweeping BACK from the skull, up to twice the skull's
length in males (P. longiceps: narrow, backward); short S-curved neck into a compact torso;
the wing is a skin membrane from the hugely elongated 4th finger back to the ankle, three
small clawed fingers at the wrist; short stubby tail; hind limbs trailing in flight.
Proportions used (of the 7.4-stud span; the game's box decides length):
  span : nose-to-tail 2.5 : 1 | skull+beak 0.38 of the length (beak tapering to a point) |
  crest ~ skull length, rooted in the back of the skull, swept back at ~40 deg |
  neck short, S-curved up into the skull | torso (chest-hip) 0.25, chunky so it reads at
  game distance | tail 0.08 | wing: arm to the wrist 0.40 of the half-span (leading edge
  pushed forward at the wrist), wing-finger 0.60 to a swept-back pointed tip, drooping
  toward the tip with an upward-cambered membrane; trailing edge scalloped in to the ankle.
Every piece overlaps its neighbour (neck into skull, crest root inside the skull, wing roots
and legs inside the torso) so the silhouette is one solid from side, top and front.
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

ROOT_X = 0.12  # wings start inside the torso
SPAN = 3.58  # root to tip, so the tip lands at x 3.7


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
        le = -0.36 - 0.26 * math.sin(0.5 * math.pi * t / 0.4)  # arm: forward to the wrist
    else:
        le = -0.62 + 0.82 * ((t - 0.4) / 0.6) ** 1.5  # wing-finger, swept back to the tip
    te = 0.78 + (0.2 - 0.78) * t - 0.2 * math.sin(math.pi * t)  # ankle -> scalloped -> tip
    te = max(te, le + 0.05)
    y = 0.14 + 0.16 * t - 0.5 * t * t  # rises to the wrist, droops toward the tip
    return le, te, y


def build(lp):
    H = _helpers()
    r = lp.rbx

    # one torso skeleton: stubby tail -> hips -> chunky chest -> short S-curved neck rising
    # into the skull (the head piece overlaps the neck's top); legs trailing to the ankles
    pts = [r(0, 0.03, 0.86), r(0, 0.04, 0.64), r(0, 0.03, 0.38), r(0, 0.06, 0.04),  # 0-3
           r(0, 0.1, -0.3), r(0, 0.17, -0.58), r(0, 0.27, -0.8), r(0, 0.34, -0.98),  # 4-7
           r(0, 0.37, -1.12)]  # 8: buried in the skull, so neck and head never part
    rad = [0.03, 0.1, 0.28, 0.36, 0.35, 0.25, 0.2, 0.18, 0.15]
    edges = [(k, k + 1) for k in range(8)]
    feet = []
    for s in (-1, 1):
        i = len(pts)  # thigh, knee, ankle: trailing back, the membrane's inner corner
        pts += [r(0.17 * s, 0.0, 0.45), r(0.25 * s, 0.0, 0.62), r(0.3 * s, 0.02, 0.78)]
        rad += [0.12, 0.08, 0.06]
        edges += [(2, i), (i, i + 1), (i + 1, i + 2)]
        feet.append((0.3 * s, 0.02, 0.8))
    body = lp.decimate_to(lp.skin("body", pts, edges, rad, subdiv=1), 330)

    # wing bones along the leading edge: shoulder (in the torso) -> elbow -> wrist knob ->
    # the long 4th finger to the tip; then the membrane, cambered up, back to the ankle
    bones, membranes, wrists = [], [], []
    for s in (-1, 1):
        chain = []
        for t in (0.0, 0.2, 0.4, 0.62, 0.82, 1.0):
            le, _, y = _edge(t)
            chain.append(r(s * (ROOT_X + SPAN * t), y + 0.02, le + 0.04))
        bones.append(lp.skin(f"bone{s}", chain, [(k, k + 1) for k in range(5)],
                             [0.13, 0.1, 0.095, 0.06, 0.04, 0.012], subdiv=1))
        le, _, y = _edge(0.4)
        wrists.append((s * (ROOT_X + SPAN * 0.4), y + 0.02, le + 0.02))
        rows = []
        for i in range(18):
            t = i / 17
            le, te, y = _edge(t)
            row = []
            for j in range(6):
                c = j / 5
                camber = 0.09 * math.sin(math.pi * c) * (1 - 0.6 * t)
                dip = -0.1 * c * c * max(0.0, 1 - t / 0.15)  # trailing root down to the ankle
                row.append(r(s * (ROOT_X + SPAN * t), y + camber + dip, le + 0.03 + (te - le - 0.03) * c))
            rows.append(row)
        membranes.append(H.sheet(lp, f"wing{s}", rows, 0.06))
    body = lp.join("body", [body] + [lp.decimate_to(b, 70) for b in bones])
    wing = lp.decimate_to(lp.join("accent", membranes), 470)

    # skull rooted over the neck's top, long toothless beak (upper) over a slimmer lower bill
    head = lp.skin(
        "head",
        [r(0, 0.36, -0.86), r(0, 0.41, -1.12), r(0, 0.35, -1.4), r(0, 0.28, -1.7), r(0, 0.22, -1.95),
         r(0, 0.19, -2.1),
         r(0, 0.29, -1.12), r(0, 0.21, -1.5), r(0, 0.17, -1.85), r(0, 0.15, -2.02)],
        [(0, 1), (1, 2), (2, 3), (3, 4), (4, 5), (1, 6), (6, 7), (7, 8), (8, 9)],
        [0.2, 0.2, 0.13, 0.08, 0.04, 0.012, 0.13, 0.08, 0.045, 0.015],
    )
    head = lp.decimate_to(head, 200)

    # the crest: rooted deep in the back of the skull, sweeping back and up - the high-tier glow
    crest = H.blade(lp, "glow", [r(0, *p) for p in (
        (0.4, -1.36), (0.54, -1.3), (0.62, -1.2), (0.74, -1.04), (0.88, -0.76), (0.99, -0.52), (1.01, -0.44),
        (0.94, -0.46), (0.76, -0.68), (0.58, -0.9), (0.42, -1.0))], 0.1, 1)
    crest = lp.decimate_to(crest, 110)

    belly = lp.decimate_to(lp.ellipsoid("belly", r(0, -0.1, 0.02), (0.26, 0.5, 0.2), 10, 6), 70)

    eyes = [lp.ellipsoid(f"eye{s}", r(s * 0.13, 0.46, -1.13), (0.05, 0.05, 0.05), 6, 4) for s in (-1, 1)]
    eye = lp.join("eye", eyes)

    claws = []
    for k, (wx, wy, wz) in enumerate(wrists):  # three little hand claws forward of each wrist
        for d in (-0.07, 0.0, 0.07):
            claws.append(lp.cone(f"h{k}{d}", r(wx + d, wy, wz), r(wx + d * 1.3, wy - 0.08, wz - 0.16), 0.025, 4))
    for k, (fx, fy, fz) in enumerate(feet):  # toes curled back
        for d in (-0.04, 0.0, 0.04):
            claws.append(lp.cone(f"t{k}{d}", r(fx + d, fy, fz - 0.02), r(fx + d * 1.4, fy - 0.05, fz + 0.1), 0.022, 4))
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
