"""HUSK - the Compy (Compsognathus): small, fast, light biped (PLAN 11a T146 proof).

Fitted to today's blocky HUSK bounds (DinoLook: body 0.9 x 0.8 x 1.4, legs 0.7, head
0.6 x 0.55 x 0.8): x +-0.45, y -1.1..0.635, z -1.38..1.82 about the Root's centre.
Points below are Roblox studs (Y up, -Z forward) via lp.rbx.

Reference (paleo descriptions, 2026-10-26: Wikipedia / Britannica / Ostrom 1978 specimens,
89 cm German + 125 cm French): long narrow skull with a tapered pointed snout on a long,
flexible S-curved neck; body held level with the hips over the feet; short slender arms,
two clawed fingers; long slender legs, shin longer than thigh, raised metatarsus (walks on
the toes), three forward clawed toes; tail longer than head + body, held straight out.
Proportions used (of the 3.2-stud nose-to-tail length, head stylised ~1.5x for readability):
  head 0.17 (snout 60% of it, tapering to a point) | neck 0.12, S-curve up |
  body chest-to-hip 0.17, level | tail 0.50 from the hips, level, thinning to a point |
  hind leg ~ hip height: thigh 0.35 forward-down, shin 0.40 back-down, metatarsus 0.25 |
  arm 0.12 of length, folded under the chest | feet under the hips (centre of mass).
Lowest tier = natural colours (DinoLook green, tan belly, brown claws/spikes).
"""

GREEN = (126, 196, 110)  # DinoLook HUSK colour; the rest follow ArtSlot.paints
TAN = (232, 214, 165)
BROWN = (84, 64, 42)


def _mix(a, b, t):
    return tuple(round(x + (y - x) * t) for x, y in zip(a, b))


def build(lp):
    r = lp.rbx
    # torso level, S-curved neck, long level tail
    pts = [
        r(0, 0.0, 0.2), r(0, -0.02, -0.34),  # 0 hip, 1 chest
        r(0, 0.08, -0.56), r(0, 0.28, -0.68),  # 2-3 neck: forward, then up (S-curve)
        r(0, 0.04, 0.7), r(0, 0.07, 1.2), r(0, 0.1, 1.8),  # 4-6 tail
        r(0, 0.01, -0.07),  # 7 mid-back, keeps the back line smooth
    ]
    rad = [0.34, 0.26, 0.13, 0.11, 0.2, 0.11, 0.035, 0.31]
    edges = [(0, 7), (7, 1), (1, 2), (2, 3), (0, 4), (4, 5), (5, 6)]
    toes = []
    for s in (-1, 1):
        x = 0.27 * s
        i = len(pts)  # thigh (forward-down), knee, ankle (back, raised), ball of the foot
        pts += [r(x, -0.18, 0.2), r(x, -0.5, -0.04), r(x, -0.82, 0.3), r(x, -1.04, 0.12)]
        rad += [0.19, 0.1, 0.06, 0.055]
        edges += [(0, i), (i, i + 1), (i + 1, i + 2), (i + 2, i + 3)]
        for dx in (-0.08, 0.0, 0.08):  # three forward toes
            t = len(pts)
            tip = (x + dx * 1.3, -1.07, -0.1 if dx == 0 else -0.04)
            pts.append(r(*tip))
            rad.append(0.03)
            edges.append((i + 3, t))
            toes.append(tip)
        j = len(pts)  # short arm folded under the chest: shoulder, elbow, hand
        pts += [r(0.15 * s, -0.1, -0.42), r(0.17 * s, -0.3, -0.36), r(0.14 * s, -0.36, -0.52)]
        rad += [0.07, 0.055, 0.045]
        edges += [(1, j), (j, j + 1), (j + 1, j + 2)]
    body = lp.decimate_to(lp.skin("body", pts, edges, rad, subdiv=1), 415)

    # long low skull: cranium -> tapered snout, with a lower jaw below it (the jaw line)
    head = lp.skin(
        "head",
        [r(0, 0.32, -0.5), r(0, 0.42, -0.86), r(0, 0.39, -1.16), r(0, 0.35, -1.38),
         r(0, 0.28, -0.92), r(0, 0.26, -1.3)],
        [(0, 1), (1, 2), (2, 3), (0, 4), (4, 5)],
        [0.17, 0.19, 0.12, 0.06, 0.1, 0.05],
    )
    head = lp.decimate_to(head, 150)

    belly = lp.decimate_to(lp.ellipsoid("belly", r(0, -0.17, -0.1), (0.24, 0.42, 0.2), 10, 6), 70)

    eyes = [lp.ellipsoid(f"eye{s}", r(s * 0.15, 0.5, -0.92), (0.055, 0.055, 0.055), 6, 4) for s in (-1, 1)]
    eye = lp.join("eye", eyes)

    spikes = [lp.cone(f"s{i}", r(0, 0.28 - 0.04 * i, z), r(0, 0.42 - 0.05 * i, z + 0.08), 0.05, 4)
              for i, z in enumerate((-0.3, 0.05, 0.4, 0.8))]
    claws = [lp.cone(f"c{k}", r(tx, ty, tz + 0.02), r(tx, ty - 0.02, tz - 0.1), 0.025, 4)
             for k, (tx, ty, tz) in enumerate(toes)]
    fingers = [lp.cone(f"f{s}{d}", r(0.14 * s + d, -0.37, -0.54), r(0.14 * s + d, -0.42, -0.6), 0.02, 4)
               for s in (-1, 1) for d in (-0.025, 0.025)]  # two fingers per hand
    dark = lp.join("dark", spikes + claws + fingers)

    return {
        "batch": "11a",
        "budget": "small",
        "box": ((-0.45, -1.1, -1.38), (0.45, 0.635, 1.82)),
        "pieces": [body, head, belly, eye, dark],
        "groups": {"head": "body"},
        "roles": {"head": "head"},
        "colors": {
            "body": GREEN,
            "belly": _mix(GREEN, TAN, 0.7),
            "dark": BROWN,
            "eye": (25, 20, 20),
        },
    }
