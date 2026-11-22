"""MECHA_MARKSMAN - Big Game Hunter premium skin (Cyber Raptor theme, PREMIUM_SKINS.md, batch 11p3,
#462: its own silhouette, element electric / digital glitch). The heavy one: a walking raptor mech.

  * an open-faced black-chrome mech helmet: a crest of three swept raptor fins down the top (glowing
    leading edges), an antenna with a glowing tip on the left, jaw guards, and a scope eyepiece
    swung over the right eye (a glowing lens ring; the left eye, brows and the smile stay visible)
  * big boxy mech pauldrons, three plates deep, glowing vent slots and raptor claws hooking off the
    outer edge
  * a heavy chest plate with a hexagonal reactor core, circuit traces running out of it
  * a power pack on the back: two capacitor cylinders wrapped in glowing coil rings, cables to the
    shoulders
  * armoured forearms with glowing bands, gunmetal knuckles
  * thick thigh plates, clawed knee guards, and raptor-foot boots: three gunmetal toe claws forward
    and the sickle claw on the inside, glowing toe lights

Every trace, vent, lens, coil and fin edge is group `glow` (Neon; SkinFx cycles cyan -> magenta).
Built on the shared R15 figure (_body.py) with its own style; same R15 hit envelope (#434).
"""
# art-sources: _body.py variants/_cyber.py

import importlib.util
import math
from pathlib import Path

_here = Path(__file__).parent
_spec = importlib.util.spec_from_file_location("_body", _here / "_body.py")
B = importlib.util.module_from_spec(_spec)
_spec.loader.exec_module(B)
_spec = importlib.util.spec_from_file_location("_cyber", _here / "variants" / "_cyber.py")
C = importlib.util.module_from_spec(_spec)
_spec.loader.exec_module(C)

HELM = ((0, 2.0, 0.08), (0.66, 0.52, 0.68))


def helmet(body):
    c, r = HELM
    body.add("Head", "plate",
             B.ell(c, r, 12, 7),
             # jaw guards down the cheeks and a back guard
             *[B.rbox((0.6 * k, 1.5, 0.06), (0.14, 0.56, 0.6), bevel=0.04, segments=1, rot=(8, 0, 0), taper=(0.8, 0.7)) for k in (-1, 1)],
             B.rbox((0, 1.56, 0.55), (0.9, 0.5, 0.16), bevel=0.04, segments=1))
    # brow band (gunmetal) and the crest fins down the top
    body.add("Head", "chrome",
             B.rbox((0, 1.93, -0.56), (1.14, 0.12, 0.14), bevel=0.03, segments=1),
             *[C.fin(B, (0, 2.66 - i * 0.1, -0.16 + i * 0.36), 0.62, 0.56 - i * 0.1, 0.08, rot=(-26 - i * 6, 0, 0)) for i in range(3)])
    body.add("Head", "glow",
             B.rbox((0, 1.93, -0.635), (0.9, 0.035, 0.02), bevel=0.0, segments=1),  # brow light strip
             # each fin's glowing outline: a thin copy a size up behind it
             *[C.fin(B, (0, 2.66 - i * 0.1, -0.16 + i * 0.36), 0.72, 0.66 - i * 0.1, 0.03, rot=(-26 - i * 6, 0, 0)) for i in range(3)],
             *C.trace(B, [C.on_ell(c, r, 40, 20, 1.01), C.on_ell(c, r, 60, 20, 1.01), C.on_ell(c, r, 80, 40, 1.01)]),
             *C.trace(B, [C.on_ell(c, r, -40, 20, 1.01), C.on_ell(c, r, -60, 20, 1.01), C.on_ell(c, r, -80, 40, 1.01)]))
    # scope eyepiece on a swing arm from the right temple, over the right eye
    body.add("Head", "chrome",
             B.cyl((0.62, 1.82, -0.18), 0.12, 0.12, 8, bevel=0.0, rot=(0, 0, 90)),  # hinge
             B.rbox((0.48, 1.74, -0.42), (0.08, 0.08, 0.4), bevel=0.0, segments=1, rot=(0, -20, 0)),  # arm
             B.cyl((0.22, 1.62, -0.66), 0.15, 0.2, 10, bevel=0.02, rot=(90, 0, 0)))  # the eyepiece barrel
    body.add("Head", "glow", B.cyl((0.22, 1.62, -0.77), 0.1, 0.02, 10, bevel=0.0, rot=(90, 0, 0)))  # lens
    # antenna, left
    body.add("Head", "chrome", C.seg(B, (-0.56, 2.16, 0.2), (-0.72, 2.95, 0.36), 0.035, 0.018, 4))
    body.add("Head", "glow", B.ell((-0.72, 2.97, 0.36), (0.06, 0.06, 0.06), 6, 3))
    # moustache (the Big Game Hunter's, kept)
    body.add("Head", "hair", *[B.ell((0.15 * k, 1.37, -0.535), (0.18, 0.07, 0.06), 8, 5, rot=(0, 0, 18 * k)) for k in (-1, 1)])


def chest(body):
    f = -0.55
    body.add("UpperTorso", "plate",
             B.rbox((0, 0.42, -0.4), (1.86, 1.16, 0.3), bevel=0.06, segments=1, taper=(1.05, 1.0)),
             B.rbox((0, 0.42, 0.4), (1.8, 1.12, 0.28), bevel=0.06, segments=1))
    body.add("UpperTorso", "chrome",
             B.cyl((0, 0.48, f - 0.02), 0.32, 0.08, 6, bevel=0.0, rot=(90, 0, 0)),  # hex frame round the core
             B.rbox((0, 0.98, -0.42), (1.3, 0.12, 0.3), bevel=0.03, segments=1))  # collar rim
    body.add("UpperTorso", "glow",
             B.cyl((0, 0.48, f - 0.06), 0.22, 0.04, 6, bevel=0.0, rot=(90, 0, 0)),  # reactor core
             *C.trace(B, [(0.24, 0.56, f), (0.5, 0.56, f), (0.64, 0.7, f), (0.78, 0.7, f)]),
             *C.trace(B, [(-0.24, 0.56, f), (-0.5, 0.56, f), (-0.64, 0.7, f), (-0.78, 0.7, f)]),
             *C.trace(B, [(0.2, 0.32, f), (0.42, 0.1, f), (0.7, 0.1, f)]),
             *C.trace(B, [(-0.2, 0.32, f), (-0.42, 0.1, f), (-0.7, 0.1, f)]),
             *C.trace(B, [(0, 0.24, f), (0, -0.04, f)]),
             *[C.pad(B, p) for p in ((0.8, 0.7, f), (-0.8, 0.7, f), (0.72, 0.1, f), (-0.72, 0.1, f), (0, -0.06, f))])
    # belt: gunmetal with a glowing buckle
    body.add("LowerTorso", "chrome", B.rbox((0, -0.63, -0.52), (0.44, 0.26, 0.07), bevel=0.02, segments=1))
    body.add("LowerTorso", "glow", B.rbox((0, -0.63, -0.565), (0.26, 0.08, 0.02), bevel=0.0, segments=1))


def power_pack(body):
    z = 0.78
    body.add("UpperTorso", "plate", B.rbox((0, 0.36, z - 0.1), (1.1, 1.08, 0.3), bevel=0.05, segments=1))
    for k in (-1, 1):
        x = 0.34 * k
        body.add("UpperTorso", "chrome",
                 B.cyl((x, 0.36, z + 0.12), 0.17, 1.04, 8, bevel=0.03),
                 B.cyl((x, 0.96, z + 0.12), 0.1, 0.16, 6, bevel=0.0))  # capacitor caps
        body.add("UpperTorso", "glow", *[B.cyl((x, y, z + 0.12), 0.19, 0.07, 8, bevel=0.0) for y in (0.14, 0.4, 0.66)])
        # cable from the pack up over the shoulder
        body.add("UpperTorso", "chrome", *C.trace(B, [(x * 1.6, 0.86, z - 0.1), (x * 2.2, 1.02, 0.42), (x * 2.4, 1.02, 0.0)], r=0.045))


def pauldrons(body):
    for k, side in B.SIDES:
        x = 1.42 * k
        part = f"{side}UpperArm"
        body.add(part, "plate",
                 B.rbox((x, 0.98, 0), (0.86, 0.3, 0.96), bevel=0.05, segments=1, rot=(0, 0, -12 * k)),
                 B.rbox((x + 0.14 * k, 0.72, 0), (0.7, 0.26, 0.9), bevel=0.05, segments=1, rot=(0, 0, -20 * k)),
                 B.rbox((x + 0.24 * k, 0.5, 0), (0.56, 0.22, 0.82), bevel=0.04, segments=1, rot=(0, 0, -28 * k)))
        body.add(part, "glow",
                 # vent slots along the top plate's outer side and the plate seams
                 *[B.rbox((x + 0.2 * k, 1.07, z), (0.3, 0.03, 0.06), bevel=0.0, segments=1, rot=(0, 0, -12 * k)) for z in (-0.24, 0.0, 0.24)],
                 B.rbox((x + 0.1 * k, 0.84, -0.46), (0.74, 0.03, 0.02), bevel=0.0, segments=1, rot=(0, 0, -16 * k)),
                 B.rbox((x + 0.2 * k, 0.6, -0.42), (0.62, 0.03, 0.02), bevel=0.0, segments=1, rot=(0, 0, -24 * k)))
        claws, tips = [], []
        for z in (-0.28, 0.02, 0.32):
            pts = [(x + 0.36 * k, 1.04, z), (x + 0.62 * k, 1.2, z), (x + 0.8 * k, 1.04, z), (x + 0.8 * k, 0.78, z)]
            cb, ct = C.claw(B, pts, 0.1)
            claws += cb
            tips.append(ct)
        body.add(part, "chrome", *claws, *tips)
        # forearm armour with glowing bands, gunmetal knuckles
        body.add(f"{side}LowerArm", "plate", B.cyl((1.38 * k, -0.34, 0), 0.37, 0.62, 8, bevel=0.03, top=0.84))
        body.add(f"{side}LowerArm", "glow", *[B.cyl((1.38 * k, y, 0), 0.365 - (0.16 - y) * 0.0, 0.04, 8, bevel=0.0) for y in (-0.16, -0.44)])
        body.add(f"{side}Hand", "chrome", B.rbox((1.38 * k, -0.86, -0.27), (0.46, 0.12, 0.08), bevel=0.02, segments=1))


def legs(body):
    for k, side in B.SIDES:
        lx = 0.5 * k
        body.add(f"{side}UpperLeg", "plate",
                 B.rbox((lx + 0.04 * k, -1.32, -0.08), (0.62, 0.62, 0.7), bevel=0.05, segments=1, taper=(1.0, 1.0)))
        body.add(f"{side}UpperLeg", "glow", *C.trace(B, [(lx + 0.36 * k, -1.08, -0.2), (lx + 0.36 * k, -1.36, -0.2), (lx + 0.36 * k, -1.48, 0.0)]))
        # knee guard with a claw spike forward
        body.add(f"{side}LowerLeg", "plate",
                 B.cyl((lx, -2.14, -0.02), 0.41, 0.56, 8, bevel=0.03, top=1.08),
                 B.rbox((lx, -1.86, -0.32), (0.4, 0.34, 0.18), bevel=0.03, segments=1, rot=(-10, 0, 0)))
        kb, kt = C.claw(B, [(lx, -1.84, -0.4), (lx, -1.76, -0.6), (lx, -1.86, -0.74)], 0.08)
        body.add(f"{side}LowerLeg", "chrome", *kb, kt)
        body.add(f"{side}LowerLeg", "glow", B.rbox((lx, -2.2, -0.43), (0.06, 0.42, 0.02), bevel=0.0, segments=1))
        raptor_foot(body, side, lx, k)


def raptor_foot(body, side, lx, k):
    """A mech raptor foot over the boot: a sabaton, three toe claws forward, the sickle claw inside."""
    part = f"{side}Foot"
    body.add(part, "plate", B.rbox((lx, -2.68, -0.3), (0.76, 0.2, 0.78), bevel=0.04, segments=1, rot=(-6, 0, 0)))
    claws, tips = [], []
    for dx in (-0.24, 0.0, 0.24):
        cb, ct = C.claw(B, [(lx + dx, -2.7, -0.62), (lx + dx * 1.1, -2.72, -0.86), (lx + dx * 1.15, -2.86, -0.98)], 0.07)
        claws += cb
        tips.append(ct)
    sb, st = C.claw(B, [(lx - 0.36 * k, -2.62, -0.2), (lx - 0.46 * k, -2.48, -0.42), (lx - 0.44 * k, -2.6, -0.62)], 0.06)
    body.add(part, "chrome", *claws, *tips, *sb, st)
    body.add(part, "glow", *[C.pad(B, (lx + dx, -2.6, -0.69), 0.06) for dx in (-0.24, 0.0, 0.24)])


def build(lp):
    plp = C.protect(lp)
    body = B.Body(plp)
    B.base(body, plp, {
        "arm": 0.38, "fore": 0.34, "leg": 0.43, "shin": 0.37, "torso": (2.05, 1.55, 1.0),
        "taper": 1.1, "sleeve": "long", "hands": "gaunt", "boot": -2.36, "bootr": 0.38,
        "shorts": False, "armx": 1.38, "brow": 0.08,
    })
    helmet(body)
    chest(body)
    power_pack(body)
    pauldrons(body)
    legs(body)
    return {
        "batch": "11p3",
        "budget": "hero",
        "rig": "r15",
        "pieces": body.finish(2200, 110),
        "colors": {
            "skin": (236, 188, 150),
            "eye": (26, 24, 34),
            "hair": (60, 52, 58),      # dark moustache and brows
            "shirt": (40, 44, 58),     # the under-suit
            "pants": (36, 40, 52),
            "dark": (24, 26, 34),
            "gaunt": (30, 32, 44),
            **C.COLORS,
        },
        "meta": {"skin": "MECHA_MARKSMAN", "hero": "RIFLE", "display": "Mecha Marksman", "base": "hunter/RIFLE",
                 "theme": "CYBER_RAPTOR", "premium": True},
    }
