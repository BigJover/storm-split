"""Walker PARATROOPER (PLAN 11d2): the Spotter Blimp's Paratroopers (TowerLook.buildRanger).

TowerLook at scale 1 about the Body's centre (the PrimaryPart; it sits 0.9 above the model's
origin): Body 1 x 1.4 x 0.6 sand, Head 0.7 at +1.05, Hat 0.9 x 0.2 leaf green at +1.45, Scarf
in the camp colour at +0.65, Legs 0.9 x 0.6 dark wood at -0.8, Rifle 1.4 long at (0.6, 0.1,
-0.5): x -0.5..0.675, y -1.1..1.55, z -1.2..0.3. Front = -Z.
A jump-suited soldier: sand jumpsuit, leaf-green round helmet with a chin strap, camp scarf,
dark harness straps, a packed chute on the back + a reserve on the belly, jump boots, a
carbine at the hip. The open canopy is a separate model (PARATROOPER_CHUTE) for the drop.
"""

import importlib.util
from pathlib import Path

_spec = importlib.util.spec_from_file_location("_walker", Path(__file__).with_name("_walker.py"))
W = importlib.util.module_from_spec(_spec)
_spec.loader.exec_module(W)

LOOK = ((-0.5, -1.1, -1.2), (0.675, 1.55, 0.3))
SAND = (190, 170, 120)  # TowerLook SAND
LEAF = (70, 110, 50)
DARK_WOOD = (70, 50, 32)
STEEL = (70, 72, 75)
SKIN = (205, 160, 120)


def build(lp):
    w = W.Walk(lp, LOOK, 1.0)
    rbox, cyl, rod, ell, ring, bar = W.rbox, W.cyl, W.rod, W.ell, W.ring, W.bar
    w.add("suit", rbox((0, -0.05, -0.02), (0.74, 1.15, 0.46), bevel=0.15))
    for s in (-1, 1):  # legs: the jumpsuit's trousers + jump boots
        w.add("pants", rbox((0.19 * s, -0.68, -0.02), (0.32, 0.5, 0.36), bevel=0.1))
        w.add("boot", rbox((0.19 * s, -0.98, -0.07), (0.33, 0.24, 0.46), bevel=0.08))
    for sh, el, ha in (((0.43, 0.38, 0), (0.5, 0.02, 0.04), (0.55, 0.08, -0.2)),
                       ((-0.43, 0.38, 0), (-0.34, 0.04, -0.3), (0.5, 0.14, -0.68))):
        w.add("suit", ell(sh, (0.15, 0.15, 0.15), 6, 4))
        w.add("suit", rod(sh, el, 0.12, 6, top=0.85))
        w.add("suit", rod(el, ha, 0.1, 6, top=0.85))
        w.add("skin", ell(ha, (0.1, 0.1, 0.1), 6, 4))
    w.add("skin", ell((0, 1.07, 0), (0.29, 0.28, 0.27), 10, 6), piece="head", role="head")
    w.add("skin", cyl((0, 0.66, 0), 0.13, 0.2, 8, bevel=0))
    w.add("skin", ell((0, 1.02, -0.27), (0.05, 0.05, 0.04), 5, 3))
    w.add("eye", *[ell((0.1 * s, 1.1, -0.245), (0.035, 0.05, 0.02), 5, 3) for s in (-1, 1)])
    # round helmet (a squashed dome) + rim + chin strap
    w.add("helmet", ell((0, 1.25, 0), (0.34, 0.26, 0.34), 10, 5))
    w.add("helmet", ring((0, 1.2, 0), 0.33, 0.04, 12, 3))
    w.add("strap", W.ring_along((0, 0.98, 0.0), (0, 0.98, 1.0), 0.29, 0.02, 10, 3))
    # camp scarf
    w.add("camp", ring((0, 0.6, 0), 0.22, 0.07, 8, 3))
    w.add("camp", rbox((0, 0.5, -0.26), (0.17, 0.17, 0.07), bevel=0, rot=(0, 0, 45)))
    # harness: shoulder straps, chest + leg straps; chute pack on the back, reserve on the belly
    for s in (-1, 1):
        w.add("strap", bar((0.2 * s, 0.52, -0.25), (0.2 * s, -0.45, -0.25), 0.08, 0.03, bevel=0))
        w.add("strap", bar((0.2 * s, 0.52, 0.25), (0.2 * s, -0.4, 0.25), 0.08, 0.03, bevel=0))
    w.add("strap", bar((-0.32, 0.2, -0.26), (0.32, 0.2, -0.26), 0.08, 0.03, bevel=0))
    w.add("strap", bar((-0.34, -0.48, -0.25), (0.34, -0.48, -0.25), 0.1, 0.03, bevel=0))
    w.add("pack", rbox((0, 0.05, 0.29), (0.6, 0.8, 0.18), bevel=0.07))
    w.add("pack", rbox((0, -0.3, -0.33), (0.46, 0.26, 0.16), bevel=0.05))
    w.add("brass", rbox((0, 0.2, -0.28), (0.1, 0.1, 0.03), bevel=0))  # quick-release buckle
    # carbine at the hip along -Z at x 0.6 (the blocky rifle's line)
    x, y = 0.6, 0.12
    w.add("wood", rbox((x, y - 0.03, 0.02), (0.08, 0.13, 0.32), bevel=0.03, rot=(-8, 0, 0)))
    w.add("gun", rbox((x, y, -0.3), (0.09, 0.12, 0.32), bevel=0.02))
    w.add("gun", rbox((x, y - 0.12, -0.36), (0.05, 0.16, 0.08), bevel=0))  # magazine
    w.add("wood", rbox((x, y - 0.02, -0.65), (0.08, 0.07, 0.4), bevel=0.02))
    w.add("gun", rod((x, y + 0.02, -0.5), (x, y + 0.02, -1.15), 0.03, 6))
    w.add("gun", W.ring_along((x, y + 0.02, -1.16), (x, y + 0.02, -2), 0.035, 0.02, 6, 3), piece="muzzle", role="muzzle")
    colors = {"suit": SAND, "pants": W.mix(SAND, DARK_WOOD, 0.35), "boot": DARK_WOOD, "skin": SKIN, "eye": W.EYE,
              "helmet": LEAF, "camp": W.CAMP, "strap": (52, 46, 38), "pack": W.mix(LEAF, (60, 60, 45), 0.4),
              "brass": W.BRASS, "wood": W.WOOD, "gun": STEEL}
    return w.model("mid", colors, {"walker": "paratrooper", "look": "TowerLook.buildRanger", "kind": "paratrooper",
                                   "display": "Paratrooper"}, 1250)
