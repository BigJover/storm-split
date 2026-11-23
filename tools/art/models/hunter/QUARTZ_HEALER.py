"""QUARTZ_HEALER - Field Medic premium skin (Geode theme, PREMIUM_SKINS.md, batch 11p6): a gem-healer, its own
silhouette (not the medic kit repainted):

  * a stone circlet with a tiara of rose-quartz crystals and a glowing amethyst at the brow; a hair bun
  * a long pale-lavender healer's robe (front and back panels to the shins) edged in rose
  * a rose-quartz CROSS on a smooth stone pectoral with a glowing gem at its heart (the medic's cross, in gems)
  * the CRYSTAL STAFF-PACK: a stone backpack with a tall staff rising from it behind the right shoulder,
    crowned high over the head by a big glowing crystal cluster held in stone prongs among rose-quartz
    shards, a rose-quartz cross on the pack
  * smooth stone shoulder caps with small rose crystals, stone bracers, a belt of glowing crystal vials

`glow` = Neon in game (Shared/SkinFx). Built on the shared R15 figure (_body.py), same R15 envelope (#434:
hit parts never change; the staff rises above the head like a backpack antenna).
"""
# art-sources: _body.py variants/_geode.py

import importlib.util
from pathlib import Path

_here = Path(__file__).parent
_spec = importlib.util.spec_from_file_location("_body", _here / "_body.py")
B = importlib.util.module_from_spec(_spec)
_spec.loader.exec_module(B)
_spec = importlib.util.spec_from_file_location("_geode", _here / "variants" / "_geode.py")
G = importlib.util.module_from_spec(_spec)
_spec.loader.exec_module(G)


def head(body):
    body.add("Head", "hair",
             B.rbox((0, 2.0, 0.08), (1.12, 0.36, 1.04), bevel=0.17),
             B.ell((0, 2.12, 0.5), (0.28, 0.26, 0.24), 8, 6))  # bun
    body.add("Head", "rock2", B.cyl((0, 1.92, 0.04), (0.6, 0.57), 0.1, 9, bevel=0.0))
    body.add("Head", "rose", *[G.crystal(B, (0.24 * k, 1.96, -0.5), (0.34 * k, 2.42, -0.6), 0.085, 6) for k in (-1, 1)],
             *[G.crystal(B, (0.44 * k, 1.96, -0.36), (0.6 * k, 2.2, -0.4), 0.055, 5) for k in (-1, 1)])
    body.add("Head", "glow", G.crystal(B, (0, 1.96, -0.54), (0, 2.66, -0.68), 0.13, 6))


def robe(body):
    body.add("UpperTorso", "cloth", B.rbox((0, 0.18, -0.06), (1.9, 1.46, 0.96), bevel=0.3))
    body.add("LowerTorso", "cloth",
             B.rbox((0, -1.28, -0.5), (0.98, 1.36, 0.06), bevel=0.0, segments=1, taper=(0.86, 1.0)),
             B.rbox((0, -1.28, 0.5), (1.08, 1.36, 0.06), bevel=0.0, segments=1, taper=(0.86, 1.0)))
    body.add("LowerTorso", "rose",
             B.rbox((0, -1.94, -0.52), (1.0, 0.07, 0.04), bevel=0.0),
             *[B.rbox((0.48 * k, -1.28, -0.52), (0.05, 1.36, 0.04), bevel=0.0, rot=(0, 0, 3 * k)) for k in (-1, 1)])
    # belt of glowing crystal vials
    body.add("LowerTorso", "rock", *[B.rbox((0.34 * x, -0.63, -0.5), (0.18, 0.2, 0.12), bevel=0.03) for x in (-2, -1, 1, 2)])
    body.add("LowerTorso", "glow", *[G.crystal(B, (0.34 * x, -0.56, -0.5), (0.34 * x, -0.32, -0.52), 0.055, 5) for x in (-2, -1, 1, 2)])


def pectoral(body):
    f = -0.56
    body.add("UpperTorso", "rock", G.rock(B, (0, 0.46, -0.46), (0.62, 0.5, 0.14), segments=8, rings=3))
    body.add("UpperTorso", "rose",
             B.rbox((0, 0.46, f - 0.04), (0.2, 0.74, 0.1), bevel=0.0),
             B.rbox((0, 0.52, f - 0.04), (0.66, 0.2, 0.1), bevel=0.0))
    body.add("UpperTorso", "glow", G.crystal(B, (0, 0.52, f - 0.06), (0, 0.52, f - 0.28), 0.11, 6))


def staff_pack(body):
    # the pack: a big split geode worn on the back, its glowing crystal bed facing out
    body.add("UpperTorso", "rock2", G.rock(B, (0, 0.3, 0.74), (0.7, 0.74, 0.3), segments=8, rings=4))
    G.add_groups(body, "UpperTorso", G.geode(B, (0, 0.32, 1.0), (0, 0, 1), 0.5, n=9), rename={"crystal": "rose"})
    body.add("UpperTorso", "dark", *[B.rbox((0.48 * k, 0.4, -0.02), (0.14, 1.3, 1.08), bevel=0.04) for k in (-1, 1)])  # straps
    # the staff: rising from the pack's right side to high over the head
    bot, top = (0.56, -0.2, 0.96), (0.74, 2.9, 0.92)
    body.add("UpperTorso", "rock2", G.seg(B, bot, top, 0.1, 0.085, 6),
             *[B.cyl((0.56 + 0.18 * t, -0.2 + 3.1 * t, 0.96 - 0.04 * t), 0.14, 0.1, 6, bevel=0.0) for t in (0.45, 0.75)])
    tx, ty, tz = top
    # stone prongs holding the crystal
    body.add("UpperTorso", "rock", *[G.seg(B, (tx, ty - 0.1, tz), (tx + 0.34 * dx, ty + 0.5, tz + 0.34 * dz), 0.08, 0.02, 4)
                                     for dx, dz in ((1, 0), (-0.5, 0.87), (-0.5, -0.87))])
    cl = G.cluster(B, (tx, ty, tz), (0.08, 1.0, 0.0), n=7, length=1.15, r=0.2, spread=26, phase=30)
    body.add("UpperTorso", "glow", cl[0], cl[2], cl[4], cl[6])
    body.add("UpperTorso", "rose", cl[1], cl[3], cl[5])


def arms(body):
    for k, side in B.SIDES:
        x = 1.38 * k
        body.add(f"{side}UpperArm", "rock", G.rock(B, (x, 0.86, 0), (0.46, 0.28, 0.48), rot=(0, 0, -14 * k), segments=8, rings=4))
        body.add(f"{side}UpperArm", "rose", *[G.crystal(B, (x + dx * k, 1.06, dz), (x + (dx + 0.14) * k, 1.36, dz * 1.3), 0.055, 5)
                                               for dx, dz in ((0.0, -0.16), (0.12, 0.12))])
        body.add(f"{side}LowerArm", "rock", B.cyl((x, -0.38, 0), 0.33, 0.34, 7, bevel=0.0, top=0.9))
        body.add(f"{side}LowerArm", "glow", B.cyl((x, -0.38, 0), 0.338, 0.05, 7, bevel=0.0))


def legs(body):
    for k, side in B.SIDES:
        lx = 0.5 * k
        body.add(f"{side}LowerLeg", "rock", G.rock(B, (lx, -2.08, -0.28), (0.24, 0.3, 0.12), segments=6, rings=3))


def build(lp):
    plp = G.protect(lp)
    body = B.Body(plp)
    B.base(body, plp, {
        "arm": 0.34, "fore": 0.3, "leg": 0.39, "shin": 0.34, "torso": (1.9, 1.5, 0.96),
        "taper": 1.0, "sleeve": "long", "hands": "glove", "boot": -2.3, "bootr": 0.37,
    })
    head(body)
    robe(body)
    pectoral(body)
    staff_pack(body)
    arms(body)
    legs(body)
    return {
        "batch": "11p6",
        "budget": "hero",
        "rig": "r15",
        "pieces": body.finish(2400, 110),
        "colors": {
            "skin": (226, 176, 140),
            "eye": (32, 26, 26),
            "hair": (70, 44, 40),
            "shirt": (104, 66, 146),  # lavender under-robe
            "pants": (78, 58, 104),
            "dark": (60, 52, 70),
            "glove": (104, 66, 146),
            "cloth": (244, 204, 222),  # the pale-lavender healer's robe
            "rock": G.ROCK,
            "rock2": G.ROCK2,
            "rose": (232, 112, 172),
            "glow": G.GLOW,
        },
        "meta": {"skin": "QUARTZ_HEALER", "hero": "MEDIC", "display": "Quartz Healer", "base": "hunter/MEDIC",
                 "theme": "GEODE", "premium": True},
    }
