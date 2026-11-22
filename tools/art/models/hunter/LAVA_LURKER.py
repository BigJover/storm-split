"""LAVA_LURKER - Tracker premium skin (Lava Lord theme, PREMIUM_SKINS.md "hooded obsidian cloak,
glowing cracks", batch 11p2, #462: its own silhouette). The volcano's stalker - lean, hooded, low:

  * a deep pointed obsidian hood swept back into a long tip, a ridge of small glowing-tipped spines
    down its crown (a raptor's back), the hood's rim glowing round an open, friendly face
  * a smouldering scarf at the neck, a one-sided obsidian mantle over the left shoulder
  * a long single cloak to the knees with a jagged, glowing hem and lava veins up the back
  * a bandolier of obsidian throwing shards (glowing tips) across the chest
  * a bladed left bracer (three obsidian fins), a molten right cuff (the gun hand)
  * an obsidian holster on the right thigh, slim cracked greaves and clawed toe caps

Every crack, hem, tip and the scarf's ember line are paint group `glow` (Neon in game;
Shared/SkinFx pulses / flows them). Built on the shared R15 figure (_body.py) directly, slim Tracker
proportions, same R15 envelope (#434: hood tip and cloak extend modestly past the parts).
"""
# art-sources: _body.py variants/_lava.py

import importlib.util
import math
from pathlib import Path

_here = Path(__file__).parent
_spec = importlib.util.spec_from_file_location("_body", _here / "_body.py")
B = importlib.util.module_from_spec(_spec)
_spec.loader.exec_module(B)
_spec = importlib.util.spec_from_file_location("_lava", _here / "variants" / "_lava.py")
L = importlib.util.module_from_spec(_spec)
_spec.loader.exec_module(L)

HOOD = ((0, 1.86, 0.1), (0.7, 0.62, 0.68))  # the hood's crown (centre, radii); its front edge sits on the brows


def hood(body):
    c, r = HOOD
    tail, tip = L.horn(B, [(0, 2.1, 0.46), (0, 2.34, 0.8), (0, 2.42, 1.14), (0, 2.3, 1.46)], 0.34, 6)
    body.add("Head", "plate",
             L.plate(B, c, r, segments=10, rings=6),
             # the back of the hood, down to the nape
             L.plate(B, (0, 1.5, 0.3), (0.68, 0.56, 0.4), segments=9, rings=5),
             # thin side panels framing the face, temple to jaw, angled forward
             *[B.rbox((0.6 * k, 1.5, -0.12), (0.1, 0.86, 0.66), bevel=0.04, segments=1, rot=(-8, 0, -4 * k), taper=(1.0, 0.7))
               for k in (-1, 1)],
             # a short pointed peak over the brow
             B.rbox((0, 2.2, -0.5), (0.36, 0.1, 0.26), bevel=0.0, segments=1, rot=(-24, 0, 0), taper=(0.2, 1.0)),
             *tail)
    # the glowing rim round the face opening (thick: it is the hood's signature at game distance)
    rim = [(-0.55, 1.06, -0.4), (-0.6, 1.4, -0.46), (-0.6, 1.76, -0.48), (-0.5, 2.0, -0.5), (-0.24, 2.14, -0.6),
           (0.0, 2.18, -0.64), (0.24, 2.14, -0.6), (0.5, 2.0, -0.5), (0.6, 1.76, -0.48), (0.6, 1.4, -0.46), (0.55, 1.06, -0.4)]
    body.add("Head", "glow", tip, *L.crack(B, rim, r=0.045, segments=5),
             B.ell((0, 2.08, -0.66), (0.11, 0.09, 0.05), 6, 3))  # an ember gem on the brow peak
    body.add("Head", "plate", B.cyl((0, 2.08, -0.62), (0.15, 0.13), 0.06, 6, bevel=0.0, rot=(90, 0, 0)))  # its setting
    # a ridge of spines along the crown, front to back, glowing tips
    spines, tips = [], []
    for pitch, h in ((58, 0.22), (78, 0.3), (100, 0.3), (124, 0.24), (146, 0.18)):
        p = math.radians(pitch)
        base = (0, c[1] + r[1] * math.sin(p) * 0.96, c[2] - r[2] * math.cos(p) * 0.96)
        out = (0, math.sin(p), -math.cos(p))
        tipp = (0, base[1] + out[1] * h + 0.06, base[2] + out[2] * h + 0.1)
        mid = tuple(a + (b - a) * 0.65 for a, b in zip(base, tipp))
        spines.append(L.seg(B, base, mid, 0.09, 0.04, 4))
        tips.append(L.seg(B, mid, tipp, 0.04, 0.0, 4, cap=False))
    body.add("Head", "plate", *spines)
    body.add("Head", "glow", *tips)
    # lava cracks running back over the hood's sides
    for k in (-1, 1):
        body.add("Head", "glow",
                 *L.crack(B, [L.on_ell(c, r, k * yaw, p, 1.01) for yaw, p in ((52, 26), (72, 10), (92, 20), (116, 2))], r=0.034),
                 *L.crack(B, [(0.66 * k, 1.7, -0.3), (0.67 * k, 1.5, -0.14), (0.66 * k, 1.3, -0.22)], r=0.03))


def neck(body):
    # smouldering scarf: a thick wrap with an ember line, its tail hanging over the right chest
    body.add("UpperTorso", "cloak",
             B.cyl((0, 0.98, 0.02), (0.56, 0.5), 0.26, 10, top=0.84, bevel=0.06),
             B.rbox((0.34, 0.58, -0.47), (0.22, 0.6, 0.05), bevel=0.02, segments=1, rot=(0, 0, -10), taper=(1.2, 1.0)))
    body.add("UpperTorso", "glow",
             B.cyl((0, 0.93, 0.02), (0.575, 0.52), 0.04, 12, bevel=0.0),
             B.rbox((0.37, 0.28, -0.5), (0.18, 0.04, 0.02), bevel=0.0, segments=1, rot=(0, 0, -10)))
    # one-sided obsidian mantle over the left shoulder (two overlapping plates + a crack)
    body.add("LeftUpperArm", "plate",
             L.plate(B, (-1.28, 0.92, 0.02), (0.5, 0.18, 0.52), rot=(0, 0, 22)),
             L.plate(B, (-1.42, 0.7, 0.02), (0.42, 0.15, 0.46), rot=(0, 0, 34)))
    body.add("LeftUpperArm", "glow",
             B.ell((-1.36, 0.8, 0.02), (0.44, 0.05, 0.48), 8, 3, rot=(0, 0, 28)),
             *L.crack(B, [(-1.05, 1.06, -0.3), (-1.22, 1.02, -0.06), (-1.36, 0.96, 0.18), (-1.56, 0.86, 0.36)], r=0.026))


def chest(body):
    f = -0.47
    # a fitted obsidian jerkin plate (front + back) with cracks
    body.add("UpperTorso", "plate",
             B.rbox((0, 0.3, -0.38), (1.42, 1.0, 0.2), bevel=0.06, segments=1, taper=(1.12, 1.0)),
             B.rbox((0, 0.32, 0.38), (1.4, 1.0, 0.18), bevel=0.06, segments=1, taper=(1.1, 1.0)))
    body.add("UpperTorso", "glow",
             *L.crack(B, [(-0.5, 0.72, f), (-0.3, 0.52, f), (-0.42, 0.24, f), (-0.22, -0.04, f)], r=0.038),
             *L.crack(B, [(0.12, 0.0, f), (0.3, 0.18, f), (0.5, 0.1, f)], r=0.036))
    # bandolier: a strap from the right shoulder to the left hip with five obsidian throwing shards
    a, b = (0.62, 0.86, -0.5), (-0.66, -0.4, -0.5)
    body.add("UpperTorso", "dark", B.rbox(((a[0] + b[0]) / 2, (a[1] + b[1]) / 2, -0.5), (0.16, 1.86, 0.06), bevel=0.02, segments=1, rot=(0, 0, 45)))
    shards, tips = [], []
    for t in (0.18, 0.34, 0.5, 0.66, 0.82):
        x, y = a[0] + (b[0] - a[0]) * t, a[1] + (b[1] - a[1]) * t
        base = (x, y - 0.02, -0.56)
        top = (x + 0.06, y + 0.24, -0.57)
        mid = (x + 0.04, y + 0.15, -0.565)
        shards.append(L.seg(B, base, mid, 0.05, 0.035, 4))
        tips.append(L.seg(B, mid, top, 0.045, 0.0, 4, cap=False))
    body.add("UpperTorso", "plate", *shards)
    body.add("UpperTorso", "glow", *tips)
    # belt buckle: a glowing ember gem
    body.add("LowerTorso", "glow", B.ell((0, -0.63, -0.5), (0.1, 0.08, 0.04), 6, 3))


def cloak(body):
    """One long cloak from the shoulders to the knees in two halves meeting in a soft ridge down the
    back (its edges wrap forward round the sides), a jagged hem whose points glow like cooling
    lava, a molten band above them and lava veins branching up the back."""
    top, length, z, half, yaw = 0.98, 2.6, 0.5, 0.5, 16
    bot = top - length
    t = math.tan(math.radians(yaw))

    def zc(x, lift=0.0):  # the cloak's back face at x
        return z + (half - abs(x)) * t + 0.035 + lift

    body.add("UpperTorso", "cloak",
             *[B.rbox((half * k, top - length / 2, z), (2 * half + 0.04, length, 0.06), bevel=0.02, segments=1,
                      rot=(0, yaw * k, 0), taper=(0.78, 1.0)) for k in (-1, 1)])
    teeth, tips = [], []
    for i, x in enumerate((-0.84, -0.5, -0.17, 0.17, 0.5, 0.84)):
        h = 0.42 if i % 2 else 0.28
        k = 1 if x > 0 else -1
        zz = zc(x) - 0.035
        teeth.append(B.rbox((x, bot - h * 0.3 + 0.01, zz), (0.33, h * 0.6, 0.06), bevel=0.0, segments=1, rot=(0, yaw * k, 0), taper=(1.0, 1.0 / 0.55)))
        tips.append(B.rbox((x, bot - h * 0.8 + 0.01, zz), (0.19, h * 0.4, 0.07), bevel=0.0, segments=1, rot=(0, yaw * k + 180, 180), taper=(0.08, 1.0)))
    body.add("UpperTorso", "cloak", *teeth)

    def vein(pts, r):
        return L.crack(B, [(x, y, zc(x, 0.01)) for x, y in pts], r=r)

    body.add("UpperTorso", "glow", *tips,
             *[B.rbox((0.5 * k, bot + 0.1, zc(0.5) + 0.005), (1.04, 0.07, 0.03), bevel=0.0, segments=1, rot=(0, yaw * k, 0)) for k in (-1, 1)],
             *vein([(0.0, bot + 0.12), (0.12, -0.9), (-0.06, -0.3), (0.06, 0.3), (0.0, 0.8)], 0.04),
             *vein([(0.12, -0.9), (0.46, -1.16), (0.68, -1.46)], 0.032),
             *vein([(-0.06, -0.3), (-0.4, -0.6), (-0.62, -1.0)], 0.032),
             *vein([(0.06, 0.3), (0.4, 0.42), (0.6, 0.7)], 0.03))
    # clasp bar under the hood
    body.add("UpperTorso", "plate", B.rbox((0, 0.94, 0.56), (1.3, 0.12, 0.1), bevel=0.03, segments=1))


def arms(body):
    # left bracer with three obsidian fins along the outside
    x = -1.31
    body.add("LeftLowerArm", "plate", B.cyl((x, -0.32, 0), 0.31, 0.6, 7, bevel=0.02, top=1.08))
    fins = []
    for y, h in ((-0.1, 0.34), (-0.3, 0.3), (-0.5, 0.24)):
        fins.append(L.seg(B, (x - 0.24, y, 0.0), (x - 0.24 - h, y + 0.16, 0.05), 0.07, 0.0, 4))
    body.add("LeftLowerArm", "plate", *fins)
    body.add("LeftLowerArm", "glow",
             *L.crack(B, [(x - 0.2, -0.04, -0.22), (x - 0.15, -0.28, -0.26), (x - 0.22, -0.56, -0.22)], r=0.024),
             B.cyl((x, -0.62, 0), 0.32, 0.04, 9, bevel=0.0))
    # right (gun hand) molten cuff
    x = 1.31
    body.add("RightLowerArm", "plate", B.cyl((x, -0.44, 0), 0.31, 0.34, 7, bevel=0.02, top=1.1))
    body.add("RightLowerArm", "glow", B.cyl((x, -0.58, 0), 0.325, 0.04, 9, bevel=0.0), B.cyl((x, -0.3, 0), 0.31, 0.03, 9, bevel=0.0))
    for k, side in B.SIDES:
        body.add(f"{side}Hand", "glow", *L.crack(B, [(1.31 * k - 0.1, -0.62, -0.08), (1.31 * k + 0.02, -0.6, 0.06), (1.31 * k + 0.1, -0.62, 0.16)], r=0.022))


def legs(body):
    for k, side in B.SIDES:
        lx = 0.5 * k
        # slim cracked greave, a pointed knee cop
        body.add(f"{side}LowerLeg", "plate",
                 B.cyl((lx, -2.16, -0.02), 0.34, 0.46, 7, bevel=0.02, top=1.12),
                 L.seg(B, (lx, -1.88, -0.26), (lx, -1.74, -0.5), 0.12, 0.0, 5))
        body.add(f"{side}LowerLeg", "glow",
                 *L.crack(B, [(lx + 0.06, -1.96, -0.35), (lx - 0.06, -2.12, -0.37), (lx + 0.04, -2.32, -0.36)], r=0.024))
        # clawed toe caps: three obsidian claws over the boot's toe, glowing between
        claws = [L.seg(B, (lx + dx, -2.74, -0.5), (lx + dx * 1.3, -2.9, -0.84), 0.07, 0.0, 4) for dx in (-0.2, 0.0, 0.2)]
        body.add(f"{side}Foot", "plate", B.rbox((lx, -2.68, -0.44), (0.66, 0.1, 0.42), bevel=0.03, segments=1, rot=(-12, 0, 0)), *claws)
        body.add(f"{side}Foot", "glow", B.rbox((lx, -2.73, -0.62), (0.56, 0.035, 0.04), bevel=0.0, segments=1))
    # obsidian holster on the right thigh with a glowing seam
    body.add("RightUpperLeg", "plate", B.rbox((0.86, -1.3, -0.02), (0.18, 0.62, 0.4), bevel=0.04, segments=1, rot=(0, 0, 8)))
    body.add("RightUpperLeg", "dark", B.cyl((0.5, -1.45, 0), 0.4, 0.08, 10, bevel=0.02))
    body.add("RightUpperLeg", "glow", *L.crack(B, [(0.965, -1.04, -0.12), (0.98, -1.3, -0.02), (0.96, -1.56, 0.08)], r=0.022))
    # a thigh wrap with an ember line on the left
    body.add("LeftUpperLeg", "dark", B.cyl((-0.5, -1.4, 0), 0.4, 0.12, 10, bevel=0.02))
    body.add("LeftUpperLeg", "glow", B.cyl((-0.5, -1.4, 0), 0.405, 0.03, 10, bevel=0.0))


def build(lp):
    plp = L.protect(lp)
    body = B.Body(plp)
    B.base(body, plp, {
        "arm": 0.3, "fore": 0.27, "leg": 0.36, "shin": 0.31, "torso": (1.8, 1.5, 0.9),
        "taper": 1.04, "sleeve": "long", "hands": "gaunt", "boot": -2.36, "bootr": 0.34,
        "armx": 1.31, "brow": 0.07,
    })
    hood(body)
    neck(body)
    chest(body)
    cloak(body)
    arms(body)
    legs(body)
    return {
        "batch": "11p2",
        "budget": "hero",
        "rig": "r15",
        "pieces": body.finish(2500, 110),
        "colors": {
            "skin": (205, 150, 108),
            "eye": (32, 26, 26),
            "hair": (60, 38, 30),
            "shirt": (58, 44, 42),     # soot-brown under-suit
            "pants": (50, 40, 40),
            "dark": (40, 30, 30),      # charred leather: straps, boots
            "plate": (36, 32, 42),     # obsidian
            "gaunt": (36, 32, 42),
            "cloak": (62, 48, 50),     # smoky ash-black cloak (warmer than the obsidian so it reads)
            "glow": (255, 112, 20),
        },
        "meta": {"skin": "LAVA_LURKER", "hero": "PISTOL", "display": "Lava Lurker", "base": "hunter/PISTOL",
                 "theme": "LAVA_LORD", "premium": True},
    }
