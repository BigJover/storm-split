"""RAPTOR - Raptor Pen (TowerLook raptor hide; a 4x tower): a palisade of sharpened logs round a
straw floor, a gate arch at the front crowned with a raptor skull and the gates swung open, a
hide-roofed lean-to and a feeding trough. The raptors themselves are walkers (RaptorLook, built
by Server/Towers), not part of this model. Authored from the base (y 0) in Roblox studs; front =
-Z (_kit conventions). The back-right corner (the owner flag's) has only short stumps.

Stage 0 (tiers 0-2): straw floor, the palisade with two lashed rails, the gate arch + skull, open
                     gates, the lean-to, a trough with a bone.
Stage 1 (tier 3):    a haunch of meat on a hook under the arch, skull trophies on two posts, a
                     water barrel, claw-scored warning planks on the gates.
Stage 2 (tier 5):    brass post caps and a brass bell on the arch, brass chain on the gates,
                     glowing eyes in the arch skull and a lantern on the lean-to.
"""

import importlib.util
from pathlib import Path

_spec = importlib.util.spec_from_file_location("_kit", Path(__file__).with_name("_kit.py"))
K = importlib.util.module_from_spec(_spec)
_spec.loader.exec_module(K)

HIDE = (150, 120, 70)  # TowerLook.COLORS.RAPTOR
STRAW = (205, 180, 110)
LOG = (118, 86, 56)
BONE = (228, 218, 192)
MEAT = (165, 62, 52)
EYE = (255, 90, 50)

E = 1.33  # palisade line, half width
GATE = 0.55  # gate opening, half width


def palisade_spots():
    """Posts along the left, right and back, and the front either side of the gate."""
    spots = []
    us = [-1.33 + i * 0.38 for i in range(8)]  # -1.33 .. 1.33
    for u in us:
        spots.append((-E, u))  # left
        if u < 0.75:
            spots.append((E, u))  # right (stops short of the flag corner)
        if -E < u < 0.75:
            spots.append((u, E))  # back
        if -E < u < E and abs(u) > GATE + 0.1:
            spots.append((u, -E))  # front, beside the gate
    return spots


def build(lp, stage):
    k = K.Kit(lp)

    # straw floor and tufts
    k.add("straw", K.rbox((0, 0.04, 0), (2.8, 0.08, 2.8), bevel=0.04),
          *[K.ell((x, 0.08, z), (0.22, 0.07, 0.16), 8, 3, rot=(0, r, 0)) for x, z, r in ((-0.3, -0.5, 20), (0.5, 0.1, -30), (-0.1, 0.4, 60), (0.7, -0.75, 0))])

    # the palisade: sharpened logs of uneven height, two rails lashed along them
    logs, tips = [], []
    for i, (x, z) in enumerate(palisade_spots()):
        h = 1.0 + ((i * 37) % 5) * 0.06
        logs.append(K.rod((x, 0.0, z), (x, h, z), 0.12, 6))
        tips.append(K.rod((x, h, z), (x, h + 0.24, z), 0.12, 6, top=0.08))
    # stumps in the back-right corner, kept low for the flag
    logs += [K.cyl((x, 0.2, z), 0.13, 0.4, 6, bevel=0.03) for x, z in ((E, 1.0), (1.0, E), (E, E))]
    k.add("log", *logs)
    k.add("wood", *tips)
    rails = []
    for y in (0.32, 0.78):
        rails += [K.rod((-E + 0.1, y, -E), (-E + 0.1, y, E), 0.05, 6),
                  K.rod((E - 0.1, y, -E), (E - 0.1, y, 0.75), 0.05, 6),
                  K.rod((-E, y, E - 0.1), (0.75, y, E - 0.1), 0.05, 6),
                  K.rod((-E, y, -E + 0.1), (-GATE - 0.1, y, -E + 0.1), 0.05, 6),
                  K.rod((GATE + 0.1, y, -E + 0.1), (E, y, -E + 0.1), 0.05, 6)]
    k.add("dark", *rails)

    # the gate arch: two tall posts, a cross beam, a raptor skull on top
    ah, az = 2.55, -1.18  # arch height, arch line (just inside the palisade)
    k.add("log", *[K.rod((sx * (GATE + 0.12), 0.0, az), (sx * (GATE + 0.12), ah + 0.15, az), 0.15, 8) for sx in (-1, 1)])
    k.add("wood", K.bar((-GATE - 0.4, ah, az), (GATE + 0.4, ah, az), 0.26, 0.24, bevel=0.06))
    sk = (0.0, ah + 0.36, -0.98)
    skull = [K.ell(sk, (0.26, 0.2, 0.34), 10, 6, rot=(-10, 0, 0)),
             K.ell((0.0, sk[1] - 0.06, sk[2] - 0.28), (0.15, 0.11, 0.2), 8, 5),  # snout
             K.rbox((0.0, sk[1] - 0.17, sk[2] - 0.15), (0.24, 0.05, 0.36), bevel=0.02)]  # jaw
    skull += [K.rod((sx * 0.07, sk[1] - 0.15, sk[2] - 0.38 + dz), (sx * 0.07, sk[1] - 0.24, sk[2] - 0.38 + dz), 0.02, 4, top=0.2)
              for sx in (-1, 1) for dz in (0.0, 0.1)]  # teeth
    skull += [K.rod((sx * 0.18, sk[1] + 0.1, sk[2] + 0.15), (sx * 0.3, sk[1] + 0.28, sk[2] + 0.3), 0.04, 5, top=0.2) for sx in (-1, 1)]  # crest spikes
    k.add("bone", *skull)
    k.add("socket", *[K.ell((sx * 0.05, sk[1] - 0.03, sk[2] - 0.47), (0.03, 0.025, 0.02), 4, 3) for sx in (-1, 1)])  # nostrils
    k.add("glow" if stage >= 2 else "socket", *[K.ell((sx * 0.15, sk[1] + 0.04, sk[2] - 0.14), (0.07, 0.07, 0.07), 6, 4) for sx in (-1, 1)],
          piece="eyes")

    # the gates swung open outward
    gates = []
    for sx in (-1, 1):
        hx = sx * GATE
        tipx, tipz = sx * (GATE - 0.22), -E + 0.48  # swung open, inward
        for t in (0.15, 0.5, 0.85):
            px, pz = hx + (tipx - hx) * t, -E + (tipz + E) * t
            gates.append(K.rod((px, 0.1, pz), (px, 1.25, pz), 0.07, 5))
        gates += [K.rod((hx, y, -E), (tipx, y, tipz), 0.045, 5) for y in (0.35, 1.0)]
    k.add("wood", *gates)

    # the lean-to at the back-left: two front posts, a sloping hide roof
    lx, lz = -0.7, 0.72
    k.add("log", *[K.rod((lx + dx, 0.0, lz - 0.38), (lx + dx, 1.05, lz - 0.38), 0.06, 6) for dx in (-0.5, 0.5)])
    k.add("body", K.rbox((lx, 1.0, lz + 0.12), (1.3, 0.07, 1.15), bevel=0.03, rot=(-28, 0, 0)))
    k.add("dark", K.rod((lx - 0.6, 1.08, lz - 0.4), (lx + 0.6, 1.08, lz - 0.4), 0.05, 6))
    # trough along the right fence, a bone in it
    k.add("log", K.rbox((1.0, 0.18, -0.25), (0.34, 0.24, 1.0), bevel=0.08))
    k.add("dark", K.rbox((1.0, 0.27, -0.25), (0.22, 0.08, 0.86), bevel=0.03))
    k.add("bone", K.rod((0.95, 0.34, -0.55), (1.05, 0.38, 0.0), 0.04, 6), *[K.ell((0.95 + dx, 0.34 + dy, -0.55 + dz), (0.07, 0.06, 0.07), 6, 4)
                                                                           for dx, dy, dz in ((0.0, 0.0, 0.0), (0.1, 0.04, 0.55))])

    brass = []
    if stage >= 1:
        # meat on a hook under the arch
        k.add("rope", K.rod((0.35, ah - 0.12, az), (0.35, ah - 0.6, az), 0.02, 4))
        k.add("meat", K.ell((0.35, ah - 0.8, az), (0.14, 0.22, 0.12), 8, 5))
        k.add("bone", K.rod((0.35, ah - 0.98, az), (0.35, ah - 1.12, az), 0.03, 5))
        # skull trophies on two palisade posts
        for x, z in ((-E, -0.57), (-E, 0.57)):
            k.add("bone", K.ell((x + 0.14, 0.95, z), (0.12, 0.1, 0.16), 8, 4), K.ell((x + 0.17, 0.93, z - 0.13), (0.07, 0.06, 0.09), 6, 4))
        # a water barrel by the lean-to, warning planks on the gates
        k.add("wood", K.cyl((0.2, 0.32, 0.95), 0.24, 0.64, 10, top=0.9))
        k.add("metal", *[K.ring((0.2, y, 0.95), 0.24, 0.025, 10, 3) for y in (0.12, 0.5)])
        k.add("sign", *[K.rbox((sx * (GATE - 0.13), 0.72, -E + 0.22), (0.3, 0.3, 0.04), bevel=0.02, rot=(0, sx * 64, 0)) for sx in (-1, 1)])
        k.add("dark", *[K.rbox((sx * (GATE - 0.13) + dx * 0.44, 0.72, -E + 0.22 - sx * dx * 0.9 - 0.03), (0.03, 0.24, 0.02), bevel=0.0, rot=(0, sx * 64, 18))
                        for sx in (-1, 1) for dx in (-0.06, 0.0, 0.06)])

    if stage >= 2:
        brass += [K.cyl((sx * (GATE + 0.12), ah + 0.2, az), 0.17, 0.1, 8) for sx in (-1, 1)]
        brass += [K.rod((-0.4, ah - 0.12, az), (-0.4, ah - 0.3, az), 0.02, 4),
                  K.cyl((-0.4, ah - 0.42, az), (0.12, 0.12), 0.2, 8, top=0.5)]  # bell
        brass += [K.ring((sx * (GATE + 0.12), 0.7, az), 0.17, 0.025, 8, 3) for sx in (-1, 1)]  # gate chain hasps
        k.add("metal", *[K.rod((lx + 0.5, 1.0, lz - 0.38), (lx + 0.5, 0.88, lz - 0.5), 0.02, 4)])
        brass.append(K.cyl((lx + 0.5, 0.86, lz - 0.52), 0.08, 0.05, 8))
        k.add("glow", K.ell((lx + 0.5, 0.73, lz - 0.52), (0.08, 0.1, 0.08), 8, 5), piece="lantern")
        k.add("brass", *brass)

    colors = {
        "body": HIDE, "straw": STRAW, "log": LOG, "wood": K.WOOD, "dark": K.DARK, "bone": BONE,
        "socket": (40, 34, 30), "meat": MEAT, "rope": K.ROPE, "metal": K.METAL, "sign": K.SAND,
        "brass": K.BRASS, "glow": EYE,
    }
    return k.model("11d", colors, "RAPTOR", stage)
