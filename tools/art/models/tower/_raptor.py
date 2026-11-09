"""RAPTOR - Raptor Pen (TowerLook raptor hide; a 4x tower): a palisade of sharpened logs round a
straw floor, a gate arch at the front crowned with a raptor skull and the gates swung open, a
hide-roofed lean-to and a feeding trough. The raptors themselves are walkers (RaptorLook, built
by Server/Towers), not part of this model. Authored from the base (y 0) in Roblox studs; front =
-Z (_kit conventions). The back-right corner (the owner flag's) has only short stumps.

Stage 0 (tiers 0-2): straw floor, the palisade with two lashed rails, the gate arch + skull, open
                     gates, the lean-to, a trough with a bone.
Stage 1 (tier 3):    a WATCHTOWER - a tall log tower with a railed lookout platform and a hide
                     roof stands in the back-left (the lean-to goes), the palisade grows taller,
                     a haunch of meat hangs under the arch.
Stage 2 (tier 5):    the watchtower is taller still, its roof crowned by a brass fire bowl with a
                     big glowing signal fire, hide banners on its corners; brass caps on the
                     arch posts, a brass bell, glowing eyes in the arch skull.
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
    lean = stage >= 1  # the upgrades spend their triangles on the watchtower
    seg = 5 if lean else 6
    grow = 0.0 if stage == 0 else 0.3  # the palisade stands taller

    # straw floor and tufts
    k.add("straw", K.rbox((0, 0.04, 0), (2.8, 0.08, 2.8), bevel=0 if lean else 0.04),
          *[K.ell((x, 0.08, z), (0.22, 0.07, 0.16), 8, 3, rot=(0, r, 0)) for x, z, r in ((-0.3, -0.5, 20), (0.5, 0.1, -30), (-0.1, 0.4, 60), (0.7, -0.75, 0))
            if not lean])

    # the palisade: sharpened logs of uneven height, two rails lashed along them
    logs, tips = [], []
    for i, (x, z) in enumerate(palisade_spots()):
        h = 1.0 + grow + ((i * 37) % 5) * 0.06
        logs.append(K.rod((x, 0.0, z), (x, h, z), 0.12, seg))
        tips.append(K.rod((x, h, z), (x, h + 0.24, z), 0.12, seg, top=0.08))
    # stumps in the back-right corner, kept low for the flag
    logs += [K.cyl((x, 0.2, z), 0.13, 0.4, 6, bevel=0.03) for x, z in ((E, 1.0), (1.0, E), (E, E))]
    k.add("log", *logs)
    k.add("wood", *tips)
    rails = []
    for y in ((0.32, 0.78) if stage == 0 else (0.35, 1.0)):
        rails += [K.rod((-E + 0.1, y, -E), (-E + 0.1, y, E), 0.05, seg),
                  K.rod((E - 0.1, y, -E), (E - 0.1, y, 0.75), 0.05, seg),
                  K.rod((-E, y, E - 0.1), (0.75, y, E - 0.1), 0.05, seg),
                  K.rod((-E, y, -E + 0.1), (-GATE - 0.1, y, -E + 0.1), 0.05, seg),
                  K.rod((GATE + 0.1, y, -E + 0.1), (E, y, -E + 0.1), 0.05, seg)]
    k.add("dark", *rails)

    # the gate arch: two tall posts, a cross beam, a raptor skull on top
    ah, az = 2.55, -1.18  # arch height, arch line (just inside the palisade)
    k.add("log", *[K.rod((sx * (GATE + 0.12), 0.0, az), (sx * (GATE + 0.12), ah + 0.15, az), 0.15, 8) for sx in (-1, 1)])
    k.add("wood", K.bar((-GATE - 0.4, ah, az), (GATE + 0.4, ah, az), 0.26, 0.24, bevel=0.06))
    sk = (0.0, ah + 0.36, -0.98)
    skull = [K.ell(sk, (0.26, 0.2, 0.34), 10, 6, rot=(-10, 0, 0)),
             K.ell((0.0, sk[1] - 0.06, sk[2] - 0.28), (0.15, 0.11, 0.2), 8, 5),  # snout
             K.rbox((0.0, sk[1] - 0.17, sk[2] - 0.15), (0.24, 0.05, 0.36), bevel=0 if lean else 0.02)]  # jaw
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
    if stage == 0:
        k.add("log", *[K.rod((lx + dx, 0.0, lz - 0.38), (lx + dx, 1.05, lz - 0.38), 0.06, 6) for dx in (-0.5, 0.5)])
        k.add("body", K.rbox((lx, 1.0, lz + 0.12), (1.3, 0.07, 1.15), bevel=0.03, rot=(-28, 0, 0)))
        k.add("dark", K.rod((lx - 0.6, 1.08, lz - 0.4), (lx + 0.6, 1.08, lz - 0.4), 0.05, 6))
    else:
        # the watchtower in the back-left: four log legs, braces, a railed platform, a hide roof
        tx, tz, hw = -0.72, 0.72, 0.46  # centre, half width (legs)
        py = 2.0 if stage == 1 else 2.35  # platform height
        legs = [(tx + sx * hw, tz + sz * hw) for sx in (-1, 1) for sz in (-1, 1)]
        k.add("log", *[K.rod((x, 0.0, z), (x, py + 0.75, z), 0.1, 6) for x, z in legs])
        braces = []
        for (x0, z0), (x1, z1) in zip(legs, legs[1:] + legs[:1]):
            if x0 != x1 and z0 != z1:
                continue
            braces.append(K.rod((x0, 0.25, z0), (x1, py - 0.15, z1), 0.04, 5))
        braces += [K.rod((tx - hw, 0.25, tz - hw), (tx + hw, py - 0.15, tz - hw), 0.04, 5),
                   K.rod((tx + hw, 0.25, tz + hw), (tx - hw, py - 0.15, tz + hw), 0.04, 5)]
        k.add("dark", *braces)
        k.add("wood", K.rbox((tx, py, tz), (2 * hw + 0.36, 0.12, 2 * hw + 0.36), bevel=0))  # platform
        rail = [K.rbox((tx + sx * (hw + 0.14), py + 0.42, tz), (0.07, 0.07, 2 * hw + 0.32), bevel=0) for sx in (-1, 1)]
        rail += [K.rbox((tx, py + 0.42, tz + sz * (hw + 0.14)), (2 * hw + 0.32, 0.07, 0.07), bevel=0) for sz in (-1, 1)]
        k.add("wood", *rail)
        k.add("body", *[K.rbox((tx + sx * (hw + 0.15), py + 0.22, tz), (0.04, 0.32, 2 * hw + 0.2), bevel=0) for sx in (-1, 1)],
              *[K.rbox((tx, py + 0.22, tz + sz * (hw + 0.15)), (2 * hw + 0.2, 0.32, 0.04), bevel=0) for sz in (-1, 1)])  # hide screens
        ry = py + 0.75
        k.add("body", K.rbox((tx, ry + 0.3, tz), (2 * hw + 0.55, 0.6, 2 * hw + 0.55), bevel=0, taper=(0.12, 0.12)), piece="roof")
        if stage >= 2:
            # the crown: a brass fire bowl on the roof's peak, a big signal fire, hide banners
            k.add("brass", K.cyl((tx, ry + 0.66, tz), 0.12, 0.14, 8, bevel=0),
                  K.cyl((tx, ry + 0.82, tz), 0.36, 0.22, 10, top=1.3, bevel=0),
                  K.ring((tx, ry + 0.94, tz), 0.46, 0.04, 12, 3))
            fire = [K.rod((tx, ry + 0.9, tz), (tx, ry + 1.6, tz), 0.36, 7, top=0.05)]
            fire += [K.rod((tx + dx, ry + 0.9, tz + dz), (tx + dx * 1.6, ry + 1.3, tz + dz * 1.6), 0.15, 5, top=0.05)
                     for dx, dz in ((0.2, 0.1), (-0.18, 0.14), (0.05, -0.22))]
            k.add("glow", *fire, piece="fire")
            k.add("brass", *[K.cyl((x, py + 0.78, z), 0.13, 0.08, 6, bevel=0) for x, z in legs])
            for x, z in legs[:2]:  # hide banners hanging from the two left corners
                k.add("hide", K.rbox((x - 0.08, py - 0.25, z), (0.04, 0.55, 0.3), bevel=0, taper=(1.0, 0.4)))
    # trough along the right fence, a bone in it
    k.add("log", K.rbox((1.0, 0.18, -0.25), (0.34, 0.24, 1.0), bevel=0.08))
    k.add("dark", K.rbox((1.0, 0.27, -0.25), (0.22, 0.08, 0.86), bevel=0.03))
    k.add("bone", K.rod((0.95, 0.34, -0.55), (1.05, 0.38, 0.0), 0.04, 6), *[K.ell((0.95 + dx, 0.34 + dy, -0.55 + dz), (0.07, 0.06, 0.07), 6, 4)
                                                                           for dx, dy, dz in ((0.0, 0.0, 0.0), (0.1, 0.04, 0.55))])

    brass = []
    if stage == 1:
        # meat on a hook under the arch
        k.add("rope", K.rod((0.35, ah - 0.12, az), (0.35, ah - 0.6, az), 0.02, 4))
        k.add("meat", K.ell((0.35, ah - 0.8, az), (0.14, 0.22, 0.12), 8, 5))
        k.add("bone", K.rod((0.35, ah - 0.98, az), (0.35, ah - 1.12, az), 0.03, 5))

    if stage >= 2:
        brass += [K.cyl((sx * (GATE + 0.12), ah + 0.2, az), 0.17, 0.1, 8, bevel=0) for sx in (-1, 1)]
        brass += [K.rod((-0.4, ah - 0.12, az), (-0.4, ah - 0.3, az), 0.02, 4),
                  K.cyl((-0.4, ah - 0.42, az), (0.12, 0.12), 0.2, 8, top=0.5)]  # bell
        k.add("brass", *brass)

    colors = {
        "body": HIDE, "straw": STRAW, "log": LOG, "wood": K.WOOD, "dark": K.DARK, "bone": BONE,
        "socket": (40, 34, 30), "meat": MEAT, "rope": K.ROPE, "metal": K.METAL, "sign": K.SAND,
        "brass": K.BRASS, "glow": EYE, "hide": (128, 52, 40),
    }
    return k.model("11d", colors, "RAPTOR", stage)
