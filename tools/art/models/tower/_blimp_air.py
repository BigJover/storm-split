"""BLIMP_AIR - the Spotter Blimp itself (TowerLook.buildBlimp; canvas envelope; a 4x tower),
the airborne part that the BLIMP mooring mast sends up. Sized to buildBlimp's parts: the
envelope runs along X with the nose at +X (poseBlimp turns +X to the heading), x -9.25..9.5,
z within +-3.45 (the side fins), y -4.4..3.45 about the envelope's centre (PrimaryPart
"Envelope"). The gondola, door gun and searchlight lamp sit where buildBlimp's Gondola, Gun and
Lamp parts are, so Towers' beam (from the Lamp) and the door gun still line up.

Kit's Body checks are widened for this model only (its own _kit instance): authored in studs
with the envelope's centre at y = YC, so Kit.finish's lowering puts the art origin there.

Stage 0 (tiers 0-2): the envelope with seam bands and a nose cap, four fins, the gondola
                     (windows, struts), two engine pods with propellers, the door gun (the
                     muzzle) and the searchlight (piece `lamp`, ArtRole `lamp`).
Stage 1 (tier 3):    an observation turret on the gondola roof, armour plates on the gondola,
                     a radio aerial, sandbags on the gondola rail, a third engine at the tail.
Stage 2 (tier 5):    brass nose cap, rail and propeller hubs, glowing gondola windows and
                     glowing running lights on the fin tips.
"""

import importlib.util
import math
from pathlib import Path

_spec = importlib.util.spec_from_file_location("_kit", Path(__file__).with_name("_kit.py"))
K = importlib.util.module_from_spec(_spec)
_spec.loader.exec_module(K)
# this model's own bounds (buildBlimp's parts), not the 3 x 5 x 3 tower Body
K.HALF_X, K.HALF_Z, K.HEIGHT = 9.6, 3.5, 9.0
YC = K.HEIGHT / 2  # the envelope's centre, authored height

CANVAS = (205, 195, 170)  # TowerLook.COLORS.BLIMP
SEAM = (170, 158, 128)
FIN = (70, 50, 32)  # TowerLook DARK_WOOD (the fins)
GONDOLA = (110, 80, 50)  # TowerLook WOOD
STEEL = (70, 72, 75)
LAMP = (255, 245, 200)
GLOW = (255, 214, 120)


def p(x, y, z):
    return (x, YC + y, z)


def build(lp, stage):
    k = K.Kit(lp)
    hot = stage >= 2

    # the envelope: one long ellipsoid, nose +X; seam bands round it; a nose cap
    k.add("body", K.ell(p(0.25, 0, 0), (9.2, 2.5, 2.5), 24, 12, rot=(0, 0, 0)))
    seams = []
    for x in (-5.0, -1.5, 2.0, 5.5):
        r = 2.5 * math.sqrt(max(0.0, 1 - ((x - 0.25) / 9.2) ** 2)) + 0.01
        seams.append(K.ring_along(p(x, 0, 0), p(x + 1, 0, 0), r, 0.05, 18, 3))
    k.add("seam", *seams)
    k.add("brass" if hot else "steel", K.ell(p(9.3, 0, 0), (0.25, 0.75, 0.75), 10, 6), piece="nosecap")
    k.add("steel", *[K.rod(p(9.0, 0, 0), p(7.6, 1.55 * math.cos(a), 1.55 * math.sin(a)), 0.05, 4)
                     for a in (i * math.pi / 3 for i in range(6))])  # nose battens

    # four fins at the tail (top, bottom, left, right)
    fins = []
    for ang in (0, 90, 180, 270):
        a = math.radians(ang)
        dy, dz = math.cos(a), math.sin(a)
        base = 0.95
        span = 2.45 if ang != 180 else 1.8  # the bottom fin is shorter
        # the fin panel: a wedge from the root chord out to the tip chord
        cx = -7.95
        mid = p(cx, dy * (base + span * 0.5), dz * (base + span * 0.5))
        rot = (ang, 0, 0)
        fins.append(K.rbox(mid, (2.3, span, 0.14), bevel=0.05, rot=rot, taper=(0.6, 1.0)))
    k.add("fin", *fins)

    # the gondola under the envelope (buildBlimp: 4 x 1.4 x 1.8 at (0.5, -3.2, 0))
    gx, gy = 0.5, -3.2
    k.add("gondola", K.rbox(p(gx, gy, 0), (4.0, 1.3, 1.7), bevel=0.25, segments=2, taper=(0.92, 0.92)))
    k.add("gondola", K.ell(p(gx + 2.0, gy, 0), (0.45, 0.62, 0.82), 10, 6))  # rounded bow
    win = [K.rbox(p(gx + x, gy + 0.2, sz * 0.84), (0.42, 0.34, 0.06), bevel=0.04) for x in (-1.2, -0.4, 0.4, 1.2) for sz in (-1, 1)]
    win.append(K.rbox(p(gx + 2.38, gy + 0.2, 0), (0.06, 0.34, 0.9), bevel=0.04))
    k.add("glow" if hot else "window", *win, piece="windows")
    k.add("steel", *[K.rod(p(gx + x, gy + 0.6, sz * 0.6), p(gx + x * 0.9, -2.15, sz * 0.9), 0.05, 4) for x in (-1.4, 1.4) for sz in (-1, 1)])
    k.add("brass" if hot else "steel", K.rbox(p(gx, gy + 0.68, 0), (4.1, 0.08, 1.8), bevel=0.03), piece="rail")

    # two engine pods on outriggers, propellers facing back
    props, hubs = [], []
    pods = [(-1.0, -2.9, sz * 1.95) for sz in (-1, 1)]
    if stage >= 1:
        pods.append((-8.0, -1.55, 0.0))  # a tail engine under the bottom fin
    for x, y, z in pods:
        if z:
            k.add("steel", K.rod(p(x, y, z * 0.45), p(x, y, z), 0.06, 4))
        k.add("pod", K.ell(p(x, y, z), (0.6, 0.26, 0.26), 10, 5))
        hubs.append(K.ell(p(x - 0.62, y, z), (0.1, 0.1, 0.1), 6, 4))
        props += [K.rbox(p(x - 0.66, y + math.cos(a) * 0.32, z + math.sin(a) * 0.32), (0.04, 0.6, 0.12), bevel=0.02, rot=(math.degrees(-a), 0, 0))
                  for a in (0.4, 0.4 + math.pi)]
    k.add("brass" if hot else "steel", *hubs, piece="hubs")
    k.add("fin", *props)

    # the door gun (buildBlimp Gun: 1.6 long along X at (1.5, -3.9, 1)); muzzle at its front
    k.add("steel", K.rod(p(0.75, -3.9, 1.0), p(2.25, -3.9, 1.0), 0.07, 8), K.rbox(p(0.95, -3.85, 1.0), (0.4, 0.2, 0.2), bevel=0.05),
          K.rod(p(0.95, -3.85, 0.85), p(0.95, -3.6, 0.7), 0.04, 4))
    k.add("dark", K.ring_along(p(2.25, -3.9, 1.0), p(3.25, -3.9, 1.0), 0.09, 0.03, 8, 3), piece="muzzle", role="muzzle")
    # the searchlight (buildBlimp Lamp: a ball at (-1, -4, 0)) in a steel housing
    k.add("steel", K.cyl(p(-1.0, -3.8, 0), 0.42, 0.3, 12, bevel=0.06), K.rod(p(-1.0, -3.6, 0), p(-1.0, -3.5, 0), 0.12, 6))
    k.add("lamp", K.ell(p(-1.0, -4.0, 0), (0.36, 0.28, 0.36), 10, 5), piece="lamp", role="lamp")

    brass = []
    if stage >= 1:
        # an observation turret on the gondola roof's front, a radio aerial, armour plates, sandbags
        k.add("gondola", K.cyl(p(gx + 1.2, gy + 0.85, 0), 0.38, 0.32, 10, bevel=0.05))
        k.add("steel", K.rod(p(gx + 1.2, gy + 0.95, 0), p(gx + 1.85, gy + 1.0, 0), 0.05, 6))
        k.add("steel", K.rod(p(gx - 1.4, gy + 0.7, 0.3), p(gx - 1.4, -1.4, 0.95), 0.02, 4))
        k.add("plate", *[K.rbox(p(gx + x, gy - 0.32, sz * 0.86), (0.85, 0.42, 0.06), bevel=0.02) for x in (-1.0, 0.0, 1.0) for sz in (-1, 1)])
        k.add("dark", *[K.ell(p(gx + x + dx, gy - 0.32, sz * 0.9), (0.03, 0.03, 0.02), 4, 3) for x in (-1.0, 0.0, 1.0) for dx in (-0.3, 0.3) for sz in (-1, 1)])
        k.add("sand", *[K.pillow(p(gx + x, gy + 0.85, sz * 0.6), 0.5, 0.0, h=0.2, w=0.3) for x in (-1.3, -0.6) for sz in (-1, 1)])

    if hot:
        lights = []
        for ang in (0, 90, 270):
            a = math.radians(ang)
            lights.append(K.ell(p(-7.95, math.cos(a) * 3.34, math.sin(a) * 3.34), (0.13, 0.13, 0.13), 6, 4))
        k.add("glow", *lights, piece="lights")
        brass.append(K.ring_along(p(-1.0, -3.95, 0), p(-1.0, -4.95, 0), 0.4, 0.04, 12, 3))
        k.add("brass", *brass)

    colors = {
        "body": CANVAS, "seam": SEAM, "fin": FIN, "gondola": GONDOLA, "window": (40, 46, 52), "steel": STEEL,
        "pod": (96, 100, 106), "dark": K.DARK, "plate": (112, 118, 124), "sand": K.SAND, "lamp": LAMP,
        "brass": K.BRASS, "glow": GLOW,
    }
    return k.model("11d", colors, "BLIMP_AIR", stage)
