"""MAGMA_MONARCH v2 - Big Game Hunter premium skin (Lava Lord theme, PREMIUM_SKINS.md, batch 11p1,
#462: its own silhouette, not the safari outfit repainted). The volcano's own warlord-hunter:

  * an open-faced horned obsidian helm: a crown of obsidian spikes on a molten circlet, two big
    curving horns with glowing tips, cheek guards; the face (eyes, brows, a fiery moustache)
    stays readable and friendly under it
  * a tall spiked obsidian collar behind the head
  * a molten core in the chest (a glowing gem in an obsidian ring) on a cracked obsidian
    breastplate, lava cracks running out from it, front and back
  * heavy three-layer lava-rock pauldrons with spikes, magma glowing between the plates and
    dripping from their edges
  * molten gauntlets: flared obsidian cuffs, glowing knuckles and seams
  * a tattered ember-red cape (five strips of different lengths, flame tongues licking up from
    the hem) and a short tattered tabard with a molten hem
  * cracked obsidian greaves, spiked knee plates, obsidian sabatons with glowing toe cracks

Every seam, crack, drip, horn tip, flame and the core are paint group `glow` (Neon in game;
Shared/SkinFx pulses / flows them by fxTier, and the pack tier's heat reads off them). Built on the
shared R15 figure (_body.py) directly, with its own style (long armoured sleeves, full legs), same
R15 envelope (#434: hit parts never change; horns, collar and cape extend modestly past them).
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

HELM = ((0, 2.05, 0.08), (0.66, 0.5, 0.67))  # the helm's dome (centre, radii); front edge above the brows


def helm(body):
    c, r = HELM
    body.add("Head", "plate",
             L.plate(B, c, r, segments=10, rings=6),
             # cheek guards and a back guard, framing the face
             *[L.plate(B, (0.58 * k, 1.62, 0.1), (0.1, 0.34, 0.4), rot=(0, 0, 8 * k), segments=6, rings=4) for k in (-1, 1)],
             L.plate(B, (0, 1.6, 0.52), (0.52, 0.32, 0.12), segments=7, rings=4),
             # nose guard down to the brow line
             B.rbox((0, 1.86, -0.6), (0.12, 0.26, 0.08), bevel=0.03, segments=1, taper=(1.6, 1.0)))
    # the molten circlet round the helm and a crown of spikes standing on it (taller at the front)
    body.add("Head", "glow", B.cyl((0, 1.98, 0.06), (0.672, 0.682), 0.08, 14, bevel=0.0))
    spikes = []
    for yaw, h in ((0, 0.46), (-28, 0.34), (28, 0.34), (-56, 0.26), (56, 0.26), (180, 0.3), (-140, 0.22), (140, 0.22)):
        base = L.on_ell(c, r, yaw, 22, 0.98)
        tip = L.on_ell(c, r, yaw, 40, 1.0 + h * 1.4)
        spikes.append(L.seg(B, base, (tip[0], base[1] + h + 0.1, tip[2]), 0.085, 0.0, 5))
    body.add("Head", "plate", *spikes)
    # horns: out of the helm's sides, sweeping out, up and a little back; glowing tips
    for k in (-1, 1):
        pts = [(0.52 * k, 2.02, 0.12), (0.84 * k, 2.06, 0.1), (1.08 * k, 2.26, 0.06), (1.18 * k, 2.58, 0.02),
               (1.1 * k, 2.88, -0.04), (0.92 * k, 3.06, -0.08)]
        horn, tip = L.horn(B, pts, 0.23, 8)
        body.add("Head", "plate", *horn)
        body.add("Head", "glow", tip, *L.crack(B, [(0.62 * k, 2.25, 0.02), (0.82 * k, 2.33, 0.04), (0.98 * k, 2.52, 0.08)], r=0.026))
    # cracks on the dome (glow), one over each brow and one at the back
    for k in (-1, 1):
        body.add("Head", "glow", *L.crack(B, [L.on_ell(c, r, k * yaw, p, 1.01) for yaw, p in ((22, 70), (34, 52), (28, 36))]))
    body.add("Head", "glow", *L.crack(B, [L.on_ell(c, r, yaw, p, 1.01) for yaw, p in ((175, 66), (186, 46), (178, 28))]))
    # fiery moustache (the Big Game Hunter's, kept) and short side hair under the cheek guards
    body.add("Head", "hair", *[B.ell((0.15 * k, 1.37, -0.535), (0.18, 0.07, 0.06), 8, 5, rot=(0, 0, 18 * k)) for k in (-1, 1)])


def collar(body):
    """A tall spiked obsidian collar behind the head (on the UpperTorso)."""
    pieces = []
    for yaw in (-105, -70, -35, 35, 70, 105):
        a = math.radians(yaw)
        x, z = 0.84 * math.sin(a), 0.5 * math.cos(a) + 0.06
        h = 0.78 if abs(yaw) == 70 else (0.66 if abs(yaw) == 105 else 0.6)
        out = 1 if x > 0 else -1
        pieces.append(L.plate(B, (x, 1.06 + h / 2, z), (0.2, h / 2 + 0.06, 0.06), rot=(-10, yaw, -16 * out), segments=6, rings=3))
        pieces.append(L.seg(B, (x + 0.04 * out, 1.0 + h, z), (x + 0.2 * out, 1.3 + h, z + 0.06), 0.08, 0.0, 4))
    body.add("UpperTorso", "plate", *pieces)


def chest(body):
    f = -0.53  # the breastplate's front face
    # breastplate (front) and backplate, faceted
    body.add("UpperTorso", "plate",
             B.rbox((0, 0.42, -0.42), (1.78, 1.12, 0.24), bevel=0.08, segments=1, taper=(1.06, 1.0)),
             B.rbox((0, 0.42, 0.42), (1.74, 1.1, 0.22), bevel=0.08, segments=1),
             # the core's obsidian ring
             B.cyl((0, 0.5, f - 0.02), 0.38, 0.08, 8, bevel=0.02, rot=(90, 0, 0)))
    # the molten core: a faceted glowing gem, and lava cracks running out from it
    body.add("UpperTorso", "glow",
             B.ell((0, 0.5, f - 0.07), (0.29, 0.29, 0.12), 8, 4),
             *L.crack(B, [(0.18, 0.62, f), (0.42, 0.78, f), (0.58, 0.94, f - 0.0)]),
             *L.crack(B, [(-0.18, 0.62, f), (-0.4, 0.74, f), (-0.62, 0.92, f)]),
             *L.crack(B, [(0.2, 0.36, f), (0.38, 0.14, f), (0.62, 0.02, f), (0.74, -0.1, f)]),
             *L.crack(B, [(-0.2, 0.36, f), (-0.34, 0.1, f), (-0.6, -0.04, f)]),
             *L.crack(B, [(0.0, 0.26, f), (0.06, 0.04, f), (-0.04, -0.12, f)]))
    b = 0.55
    body.add("UpperTorso", "glow",
             *L.crack(B, [(0.0, 0.94, b), (0.12, 0.66, b), (-0.06, 0.4, b), (0.1, 0.1, b), (0.0, -0.14, b)]),
             *L.crack(B, [(-0.06, 0.4, b), (-0.44, 0.3, b), (-0.6, 0.06, b)]),
             *L.crack(B, [(0.1, 0.1, b), (0.5, 0.0, b)]))
    # belt: obsidian with a molten gem buckle
    body.add("LowerTorso", "plate", B.rbox((0, -0.63, -0.52), (0.42, 0.28, 0.06), bevel=0.02, segments=1))
    body.add("LowerTorso", "glow", B.ell((0, -0.63, -0.56), (0.12, 0.1, 0.04), 6, 3))


def pauldrons(body):
    for k, side in B.SIDES:
        x = 1.4 * k
        part = f"{side}UpperArm"
        body.add(part, "plate",
                 L.plate(B, (x, 0.98, 0), (0.58, 0.2, 0.6), rot=(0, 0, -16 * k)),
                 L.plate(B, (x + 0.12 * k, 0.76, 0), (0.54, 0.17, 0.56), rot=(0, 0, -26 * k)),
                 L.plate(B, (x + 0.22 * k, 0.56, 0), (0.46, 0.15, 0.5), rot=(0, 0, -36 * k)),
                 # spikes along the top plate
                 *[L.seg(B, (x + dx * k, 1.1, z), (x + (dx + 0.12) * k, 1.52 - abs(z) * 0.4, z * 1.1), 0.09, 0.0, 5)
                   for dx, z in ((-0.1, -0.26), (0.06, 0.0), (-0.1, 0.26))])
        # lava between the plates, and drips hanging from their outer edges
        body.add(part, "glow",
                 B.ell((x + 0.06 * k, 0.87, 0), (0.52, 0.06, 0.55), 8, 3, rot=(0, 0, -21 * k)),
                 B.ell((x + 0.17 * k, 0.66, 0), (0.48, 0.05, 0.5), 8, 3, rot=(0, 0, -31 * k)),
                 L.drip(B, (x + 0.6 * k, 0.72, -0.2), 0.3, 0.05),
                 L.drip(B, (x + 0.6 * k, 0.42, 0.0), 0.26, 0.05),
                 *L.crack(B, [(x - 0.3 * k, 1.12, -0.32), (x - 0.08 * k, 1.1, -0.1), (x + 0.08 * k, 1.07, 0.1), (x + 0.28 * k, 1.0, 0.3)], r=0.03))


def gauntlets(body):
    for k, side in B.SIDES:
        x = 1.38 * k
        # flared cuff over the forearm with a molten seam and a crack
        body.add(f"{side}LowerArm", "plate",
                 B.cyl((x, -0.4, 0), 0.34, 0.5, 8, bevel=0.03, top=0.78),
                 L.seg(B, (x + 0.3 * k, -0.3, 0), (x + 0.56 * k, -0.12, 0.04), 0.08, 0.0, 4))  # a cuff spike
        body.add(f"{side}LowerArm", "glow",
                 B.cyl((x, -0.56, 0), 0.355, 0.05, 10, bevel=0.0),
                 *L.crack(B, [(x + 0.1 * k, -0.24, -0.3), (x + 0.02 * k, -0.36, -0.33), (x + 0.12 * k, -0.48, -0.34)], r=0.026))
        # knuckles: a molten ridge across the back of the hand, a crack on the top
        body.add(f"{side}Hand", "glow",
                 B.rbox((x, -0.86, -0.28), (0.44, 0.1, 0.06), bevel=0.02, segments=1),
                 *L.crack(B, [(x - 0.12 * k, -0.62, -0.06), (x + 0.0 * k, -0.6, 0.06), (x + 0.12 * k, -0.62, 0.16)], r=0.024))


def cape(body):
    """Five ember-red strips hanging from the shoulders (fanned a little, of uneven length) with
    flame tongues licking up from the hem; and a short tattered tabard at the front."""
    strips, flames = [], []
    for i, (x, length) in enumerate(((-0.68, 2.3), (-0.34, 2.6), (0.0, 2.45), (0.34, 2.7), (0.68, 2.25))):
        top = 1.0
        z = 0.62 + 0.015 * (i % 2)
        tilt = -x * 6  # fan out a little
        back = math.sin(math.radians(3))
        strips.append(B.rbox((x * 1.05, top - length / 2, z + length / 2 * back), (0.42, length, 0.05), bevel=0.02,
                             segments=1, rot=(-3, 0, tilt), taper=(1.0 / 1.15, 1.0)))
        # a ragged flat point at the strip's end (a wedge, narrow end down)
        yb = top - length
        zb = z + length * back
        strips.append(B.rbox((x * 1.05 - tilt * 0.02, yb - 0.12, zb), (0.4, 0.3, 0.05), bevel=0.0, segments=1,
                             rot=(-3, 0, 180 + tilt), taper=(0.08, 1.0)))
        for dx, h in ((-0.1, 0.5), (0.1, 0.7)):
            flames.append(B.ell((x * 1.05 + dx, yb + h / 2 - 0.05, zb + 0.035), (0.08, h / 2, 0.02), 5, 3))
    body.add("UpperTorso", "cape", *strips)
    body.add("UpperTorso", "glow", *flames)
    # the cape's clasp bar across the shoulders, under the collar
    body.add("UpperTorso", "plate", B.rbox((0, 0.98, 0.6), (1.5, 0.14, 0.12), bevel=0.04, segments=1))
    # tabard: a front panel from the belt, two ragged points, a molten hem line
    body.add("LowerTorso", "cape",
             B.rbox((0, -1.06, -0.52), (0.62, 0.66, 0.05), bevel=0.02, segments=1, taper=(0.8, 1.0)),
             *[B.rbox((0.15 * k, -1.5 - 0.04 * (k + 1), -0.52), (0.3, 0.3 + 0.08 * (k + 1), 0.05), bevel=0.0, segments=1,
                      rot=(0, 0, 180), taper=(0.08, 1.0)) for k in (-1, 1)])
    body.add("LowerTorso", "glow", B.rbox((0, -1.32, -0.555), (0.52, 0.04, 0.02), bevel=0.0, segments=1))


def legs(body):
    for k, side in B.SIDES:
        lx = 0.5 * k
        # greave over the shin with cracks; spiked knee plate
        body.add(f"{side}LowerLeg", "plate",
                 B.cyl((lx, -2.14, -0.02), 0.39, 0.5, 8, bevel=0.03, top=1.1),
                 L.plate(B, (lx, -1.86, -0.3), (0.26, 0.24, 0.14), rot=(-10, 0, 0)),
                 L.seg(B, (lx, -1.84, -0.4), (lx, -1.8, -0.62), 0.09, 0.0, 5))
        body.add(f"{side}LowerLeg", "glow",
                 *L.crack(B, [(lx - 0.1, -1.94, -0.4), (lx + 0.04, -2.06, -0.415), (lx - 0.06, -2.2, -0.42), (lx + 0.08, -2.34, -0.4)], r=0.026),
                 *L.crack(B, [(lx + 0.3 * k, -1.98, -0.2), (lx + 0.38 * k, -2.14, -0.1), (lx + 0.36 * k, -2.3, 0.08)], r=0.024))
        # obsidian sabaton over the boot with a toe crack
        body.add(f"{side}Foot", "plate", B.rbox((lx, -2.66, -0.42), (0.72, 0.12, 0.5), bevel=0.04, segments=1, rot=(-14, 0, 0)))
        body.add(f"{side}Foot", "glow",
                 *L.crack(B, [(lx - 0.3, -2.6, -0.44), (lx - 0.1, -2.58, -0.52), (lx + 0.06, -2.6, -0.38), (lx + 0.3, -2.62, -0.5)], r=0.028))
        # thigh guard (tasset) hanging from the belt
        body.add(f"{side}UpperLeg", "plate", L.plate(B, (lx + 0.12 * k, -1.18, -0.06), (0.36, 0.26, 0.42), rot=(0, 0, -8 * k), segments=6, rings=3))
        body.add(f"{side}UpperLeg", "glow", B.ell((lx + 0.14 * k, -1.36, -0.06), (0.3, 0.035, 0.36), 8, 3, rot=(0, 0, -8 * k)))


def build(lp):
    plp = L.protect(lp)  # glow + plate pieces skip the even decimation (thin seams stay exact)
    body = B.Body(plp)
    B.base(body, plp, {
        "arm": 0.37, "fore": 0.33, "leg": 0.42, "shin": 0.36, "torso": (2.0, 1.55, 1.0),
        "taper": 1.08, "sleeve": "long", "hands": "gaunt", "boot": -2.36, "bootr": 0.38,
        "shorts": False, "armx": 1.38, "brow": 0.08,
    })
    helm(body)
    collar(body)
    chest(body)
    pauldrons(body)
    gauntlets(body)
    cape(body)
    legs(body)
    return {
        "batch": "11p1",
        "budget": "hero",
        "rig": "r15",
        "pieces": body.finish(2500, 110),
        "colors": {
            "skin": (236, 188, 150),
            "eye": (32, 26, 26),
            "hair": (214, 92, 30),     # fiery moustache and brows
            "shirt": (52, 40, 44),     # charcoal under-armour
            "pants": (46, 36, 40),
            "dark": (40, 30, 32),      # charred leather: belt, boots
            "plate": (40, 34, 46),
            "gaunt": (40, 34, 46),     # gauntlet hands: obsidian like the plates (own group so the body decimation may thin them)     # obsidian (a cool violet-black so the facets read against the cape)
            "cape": (120, 26, 18),     # ember red
            "glow": (255, 112, 20),    # the lava (Neon in game)
        },
        "meta": {"skin": "MAGMA_MONARCH", "hero": "RIFLE", "display": "Magma Monarch", "base": "hunter/RIFLE",
                 "theme": "LAVA_LORD", "premium": True, "version": 2},
    }
