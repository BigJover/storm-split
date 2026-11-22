"""NANO_MEDIC - Field Medic premium skin (Cyber Raptor theme, PREMIUM_SKINS.md, batch 11p3, #462: its
own silhouette, element electric / digital glitch). The light one: a white-chrome nano-medic with a
drone.

  * an open-faced white-chrome helmet with headset discs and a small glowing raptor crest fin; a
    glowing scanner halo ring floats round the head on two struts (the face stays open, friendly)
  * a white-chrome chest plate with a cluster of glowing nanobot hex cells (no cross: protected
    emblem) and circuit traces
  * a rounded backpack with a glowing core window; an articulated arm from it holds a little
    medic drone over the right shoulder (four rotor rings, a glowing eye)
  * white bracers, a glowing holo-emitter on the left wrist (the heal beam's lens)
  * a belt of three glowing nano vials, white shin guards with light strips, slim raptor-claw boots

Every cell, halo, vial and strip is group `glow` (Neon; SkinFx cycles cyan -> magenta).
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

HELM = ((0, 1.98, 0.08), (0.64, 0.5, 0.66))


def hexcell(p, r=0.1):
    return B.cyl(p, r, 0.03, 6, bevel=0.0, rot=(90, 0, 0))


def helmet(body):
    c, r = HELM
    body.add("Head", "white",
             B.ell(c, r, 12, 7),
             *[B.cyl((0.6 * k, 1.6, 0.02), 0.24, 0.14, 10, bevel=0.03, rot=(0, 0, 90)) for k in (-1, 1)])  # headset
    body.add("Head", "plate",
             C.fin(B, (0, 2.5, 0.16), 0.7, 0.34, 0.07, rot=(-24, 0, 0)),
             *[B.rbox((0.62 * k, 2.02, 0.08), (0.08, 0.3, 0.08), bevel=0.0, segments=1) for k in (-1, 1)],  # halo struts
             B.rbox((0, 1.93, -0.6), (1.0, 0.08, 0.1), bevel=0.02, segments=1))  # brow rim
    body.add("Head", "glow",
             C.fin(B, (0, 2.5, 0.16), 0.8, 0.42, 0.03, rot=(-24, 0, 0)),
             _halo(),
             *[B.cyl((0.68 * k, 1.6, 0.02), 0.13, 0.03, 8, bevel=0.0, rot=(0, 0, 90)) for k in (-1, 1)],
             *C.trace(B, [C.on_ell(c, r, -30, 30, 1.01), C.on_ell(c, r, 0, 44, 1.01), C.on_ell(c, r, 30, 30, 1.01)]))


def _halo():
    """The scanner halo: a flat glowing ring round the head (a polygon of thin bars)."""
    import bmesh
    from mathutils import Vector
    bm = bmesh.new()
    n, r0, r1, y0, y1 = 18, 0.72, 0.8, 2.18, 2.22
    rows = []
    for i in range(n):
        a = 2 * math.pi * i / n
        ca, sa = math.cos(a), math.sin(a)
        rows.append([bm.verts.new(Vector((r * ca, y, 0.06 + r * sa))) for r, y in ((r0, y0), (r1, y0), (r1, y1), (r0, y1))])
    for i in range(n):
        a, b = rows[i], rows[(i + 1) % n]
        for j in range(4):
            bm.faces.new((a[j], b[j], b[(j + 1) % 4], a[(j + 1) % 4]))
    bmesh.ops.recalc_face_normals(bm, faces=bm.faces)
    return B._obj(bm, "halo")


def chest(body):
    f = -0.53
    body.add("UpperTorso", "white",
             B.rbox((0, 0.44, -0.38), (1.7, 1.06, 0.24), bevel=0.1, segments=1, taper=(1.08, 1.0)),
             B.rbox((0, 0.24, 0.52), (1.3, 1.24, 0.44), bevel=0.18, segments=1))  # backpack
    body.add("UpperTorso", "plate",
             B.rbox((0, 0.24, 0.76), (0.7, 0.7, 0.06), bevel=0.02, segments=1),  # core window frame
             B.rbox((0, 0.98, -0.3), (1.2, 0.12, 0.3), bevel=0.03, segments=1))  # collar
    cells = [(0.0, 0.52), (0.18, 0.62), (-0.18, 0.62), (0.18, 0.42), (-0.18, 0.42), (0.0, 0.72), (0.0, 0.32)]
    body.add("UpperTorso", "glow",
             *[hexcell((x, y, f - 0.02), 0.085) for x, y in cells],
             *C.trace(B, [(0.3, 0.52, f), (0.56, 0.52, f), (0.7, 0.3, f), (0.7, 0.06, f)]),
             *C.trace(B, [(-0.3, 0.52, f), (-0.56, 0.52, f), (-0.7, 0.3, f), (-0.7, 0.06, f)]),
             B.rbox((0, 0.24, 0.8), (0.54, 0.54, 0.03), bevel=0.0, segments=1))  # core window
    drone(body)
    # belt with three nano vials
    body.add("LowerTorso", "white", *[B.cyl((x, -0.66, -0.52), 0.08, 0.26, 6, bevel=0.0) for x in (-0.3, 0.0, 0.3)])
    body.add("LowerTorso", "glow", *[B.cyl((x, -0.66, -0.56), 0.06, 0.18, 6, bevel=0.0) for x in (-0.3, 0.0, 0.3)])


def drone(body):
    """An articulated arm from the pack's top to a little drone hovering over the right shoulder."""
    body.add("UpperTorso", "plate",
             *C.trace(B, [(0.4, 0.8, 0.7), (0.62, 1.34, 0.78), (1.0, 1.66, 0.56)], r=0.06),
             B.ell((0.62, 1.34, 0.78), (0.1, 0.1, 0.1), 6, 3))
    d = (1.12, 1.92, 0.42)
    body.add("UpperTorso", "white",
             B.ell(d, (0.36, 0.17, 0.36), 10, 5),
             *[B.rbox((d[0] + 0.36 * math.cos(a), d[1] + 0.06, d[2] + 0.36 * math.sin(a)), (0.3, 0.06, 0.08), bevel=0.0, segments=1,
                      rot=(0, -math.degrees(a), 0)) for a in (0.785, 2.356, 3.927, 5.498)])
    body.add("UpperTorso", "glow",
             *[B.cyl((d[0] + 0.52 * math.cos(a), d[1] + 0.1, d[2] + 0.52 * math.sin(a)), 0.17, 0.03, 8, bevel=0.0)
               for a in (0.785, 2.356, 3.927, 5.498)],
             B.ell((d[0], d[1] - 0.04, d[2] - 0.32), (0.11, 0.1, 0.07), 6, 3),  # its eye
             B.cyl((d[0], d[1] - 0.02, d[2]), 0.37, 0.03, 10, bevel=0.0))  # its light ring


def limbs(body):
    for k, side in B.SIDES:
        x = 1.34 * k
        body.add(f"{side}UpperArm", "white", B.ell((x, 0.82, 0), (0.44, 0.24, 0.44), 10, 5, rot=(0, 0, -16 * k)))
        body.add(f"{side}UpperArm", "glow", B.cyl((x, 0.74, 0), (0.42, 0.42), 0.03, 10, bevel=0.0, rot=(0, 0, -16 * k)))
        body.add(f"{side}LowerArm", "white", B.cyl((x, -0.34, 0), 0.33, 0.5, 8, bevel=0.04, top=0.9))
        body.add(f"{side}LowerArm", "glow", *C.trace(B, [(x + 0.33 * k, -0.14, -0.06), (x + 0.32 * k, -0.52, -0.06)]))
        lx = 0.5 * k
        body.add(f"{side}LowerLeg", "white", B.rbox((lx, -2.06, -0.32), (0.5, 0.56, 0.16), bevel=0.05, segments=1, rot=(-6, 0, 0)))
        body.add(f"{side}LowerLeg", "glow", B.rbox((lx, -2.0, -0.415), (0.06, 0.4, 0.02), bevel=0.0, segments=1, rot=(-6, 0, 0)))
        body.add(f"{side}UpperLeg", "white", B.rbox((lx + 0.1 * k, -1.24, -0.1), (0.5, 0.42, 0.6), bevel=0.08, segments=1))
        body.add(f"{side}UpperLeg", "glow", hexcell((lx + 0.1 * k, -1.24, -0.415), 0.08))
        part = f"{side}Foot"
        body.add(part, "white", B.rbox((lx, -2.68, -0.26), (0.66, 0.16, 0.62), bevel=0.04, segments=1))
        claws = []
        for dx in (-0.18, 0.0, 0.18):
            cb, ct = C.claw(B, [(lx + dx, -2.72, -0.52), (lx + dx * 1.1, -2.74, -0.72), (lx + dx * 1.15, -2.86, -0.82)], 0.055)
            claws += cb + [ct]
        body.add(part, "chrome", *claws)
    # the holo-emitter on the left wrist
    body.add("LeftLowerArm", "chrome", B.cyl((-1.34, -0.4, -0.34), 0.12, 0.16, 8, bevel=0.0, rot=(90, 0, 0)))
    body.add("LeftLowerArm", "glow", B.cyl((-1.34, -0.4, -0.43), 0.08, 0.03, 8, bevel=0.0, rot=(90, 0, 0)))


def build(lp):
    plp = C.protect(lp)
    body = B.Body(plp)
    B.base(body, plp, {
        "arm": 0.32, "fore": 0.29, "leg": 0.38, "shin": 0.33, "torso": (1.85, 1.5, 0.92),
        "taper": 1.04, "sleeve": "long", "hands": "gaunt", "boot": -2.36, "bootr": 0.35,
        "shorts": False, "armx": 1.34, "brow": 0.06,
    })
    helmet(body)
    chest(body)
    limbs(body)
    return {
        "batch": "11p3",
        "budget": "hero",
        "rig": "r15",
        "pieces": body.finish(2400, 110),
        "colors": {
            "skin": (240, 196, 160),
            "eye": (26, 24, 34),
            "hair": (70, 46, 34),
            "shirt": (40, 46, 62),     # dark under-suit so the white chrome reads
            "pants": (40, 46, 62),
            "dark": (34, 38, 52),
            "gaunt": (222, 228, 236),
            "white": (226, 232, 240),  # white chrome
            **C.COLORS,
        },
        "meta": {"skin": "NANO_MEDIC", "hero": "MEDIC", "display": "Nano Medic", "base": "hunter/MEDIC",
                 "theme": "CYBER_RAPTOR", "premium": True},
    }
