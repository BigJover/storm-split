"""HUSK - the Compy: small, fast, light biped; long tail, big eyes (PLAN 11a T146 proof).

Fitted to today's blocky HUSK bounds (DinoLook: body 0.9 x 0.8 x 1.4, legs 0.7, head
0.6 x 0.55 x 0.8): x +-0.45, y -1.1..0.635, z -1.38..1.82 about the Root's centre.
Points below are Roblox studs (Y up, -Z forward) via lp.rbx.
"""

GREEN = (126, 196, 110)  # DinoLook HUSK colour; the rest follow ArtSlot.paints


def _mix(a, b, t):
    return tuple(round(x + (y - x) * t) for x, y in zip(a, b))


def build(lp):
    r = lp.rbx
    # torso, neck, tail, legs and little arms on one skin skeleton
    pts = [
        r(0, 0.0, 0.3), r(0, 0.05, -0.35), r(0, 0.3, -0.75),  # 0 hip, 1 chest, 2 neck
        r(0, 0.05, 0.9), r(0, 0.1, 1.4), r(0, 0.15, 1.8),  # 3-5 tail
    ]
    rad = [0.38, 0.34, 0.19, 0.22, 0.12, 0.04]
    edges = [(0, 1), (1, 2), (0, 3), (3, 4), (4, 5)]
    for x in (-0.25, 0.25):
        i = len(pts)  # thigh, shin, ankle, toe
        pts += [r(x, -0.3, 0.2), r(x, -0.75, 0.35), r(x, -1.02, 0.2), r(x, -1.06, -0.1)]
        rad += [0.2, 0.09, 0.07, 0.06]
        edges += [(0, i), (i, i + 1), (i + 1, i + 2), (i + 2, i + 3)]
        j = len(pts)  # arm
        pts += [r(x * 0.9, -0.15, -0.5), r(x * 0.9, -0.35, -0.68)]
        rad += [0.06, 0.04]
        edges += [(1, j), (j, j + 1)]
    body = lp.decimate_to(lp.skin("body", pts, edges, rad, subdiv=1), 430)

    head = lp.skin(
        "head",
        [r(0, 0.36, -0.85), r(0, 0.42, -1.05), r(0, 0.36, -1.36)],
        [(0, 1), (1, 2)],
        [0.2, 0.29, 0.15],
    )
    head = lp.decimate_to(head, 150)

    belly = lp.decimate_to(lp.ellipsoid("belly", r(0, -0.2, -0.15), (0.27, 0.45, 0.24), 10, 6), 70)

    eyes = [lp.ellipsoid(f"eye{s}", r(s * 0.2, 0.52, -1.12), (0.065, 0.065, 0.065), 6, 4) for s in (-1, 1)]
    eye = lp.join("eye", eyes)

    spikes = [lp.cone(f"s{i}", r(0, 0.33, z), r(0, 0.48, z + 0.08), 0.06, 5) for i, z in enumerate((-0.3, 0.1, 0.5))]
    claws = [lp.cone(f"c{s}", r(s * 0.25, -1.06, -0.08), r(s * 0.25, -1.1, -0.26), 0.04, 5) for s in (-1, 1)]
    dark = lp.join("dark", spikes + claws)

    return {
        "batch": "11a",
        "budget": "small",
        "box": ((-0.45, -1.1, -1.38), (0.45, 0.635, 1.82)),
        "pieces": [body, head, belly, eye, dark],
        "groups": {"head": "body"},
        "roles": {"head": "head"},
        "colors": {
            "body": GREEN,
            "belly": _mix(GREEN, (255, 255, 255), 0.35),
            "dark": _mix(GREEN, (0, 0, 0), 0.45),
            "eye": (25, 20, 20),
        },
    }
