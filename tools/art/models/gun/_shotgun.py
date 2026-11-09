"""SHOTGUN - the Brush Beater's Shotgun (Config Heroes SHOTGUN `weapon`): a pump gun with a fat
blued barrel over a magazine tube, a ribbed walnut pump, walnut stock, brass bead, guard and tube
cap, and a side saddle of class-orange shells on the receiver's left (the side the camera sees).
Variants (additive; both can show at once at mastery 20's 6/3 split):
  SHOTGUN_DOUBLE  Point Blank T3 `Double Barrel` (HeroStats shotsPerTrigger >= 2; Quad Barrel too):
                  a second barrel side by side on the left, two brass clamps, its own muzzle ring.
  SHOTGUN_DRUM    Buckshot T5 `Thicket Sweeper` (HeroStats fireMode "auto" on the shotgun): a steel
                  drum under the receiver, in front of the trigger guard.
Frame and conventions: _gun.py.
"""

import importlib.util
from pathlib import Path

_spec = importlib.util.spec_from_file_location("_gun", Path(__file__).with_name("_gun.py"))
G = importlib.util.module_from_spec(_spec)
_spec.loader.exec_module(G)

BORE = 0.25
TIP = -1.5
COLORS = {
    "wood": G.WOOD, "steel": G.STEEL, "brass": G.BRASS, "accent": G.ACCENT["SHOTGUN"],
    "dark": G.DARK, "leather": G.LEATHER,
}
ENVELOPE = ((-0.3, -0.62, -1.7), (0.3, 0.45, 1.1))


def gun(g):
    w = 0.075
    g.add("wood",
          G.slab([(0.18, 0.25), (0.96, 0.22), (1.0, -0.15), (0.92, -0.19), (0.3, 0.0), (0.18, 0.06)], -w, w, bevel=0.035),
          G.rbox((0, 0.15, 0.08), (0.14, 0.17, 0.26), bevel=0.04),  # wrist
          G.rbox((0, -0.05, 0.08), (0.13, 0.28, 0.15), bevel=0.045, segments=2, rot=(-22, 0, 0)),  # grip
          G.rod((0, 0.12, -0.56), (0, 0.12, -0.98), 0.082, 10))  # pump
    g.add("dark",
          G.rbox((0, 0.04, 1.0), (0.16, 0.4, 0.05), bevel=0.02),  # butt pad
          G.rod((0, 0.12, -0.76), (0, 0.12, -0.79), 0.088, 10))  # pump groove
    g.add("steel",
          G.rbox((0, 0.2, -0.06), (0.15, 0.24, 0.54), bevel=0.04),  # receiver
          G.rod((0, BORE, -0.3), (0, BORE, TIP), 0.066, 10),  # barrel
          G.rod((0, 0.12, -0.3), (0, 0.12, -1.36), 0.048, 8),  # magazine tube
          G.rbox((0, 0.04, -0.06), (0.03, 0.09, 0.03), bevel=0.01, rot=(15, 0, 0)),  # trigger
          G.rbox((-0.085, 0.2, -0.04), (0.02, 0.16, 0.36), bevel=0.008))  # side saddle plate
    g.add("steel", G.muzzle_ring((0, BORE, TIP - 0.01), 0.068), piece="muzzle", role="muzzle")
    g.add("brass",
          G.ring((0, 0.05, -0.06), 0.06, 0.015, 8, 4, axis="x"),  # trigger guard
          G.rod((0, 0.12, -1.36), (0, 0.12, -1.4), 0.055, 8),  # tube cap
          G.ell((0, BORE + 0.08, TIP + 0.04), (0.025, 0.025, 0.025), 6, 3),  # bead
          G.rbox((-0.112, 0.14, -0.035), (0.07, 0.035, 0.36), bevel=0.012))  # shell heads' rim strip
    g.add("accent", *[G.rod((-0.115, 0.15, z), (-0.115, 0.29, z), 0.03, 6) for z in (-0.17, -0.08, 0.01, 0.1)])  # shells


def double(g):
    x = -0.135
    g.add("steel", G.rod((x, BORE, -0.3), (x, BORE, TIP), 0.066, 10))
    g.add("steel", G.muzzle_ring((x, BORE, TIP - 0.01), 0.068), piece="muzzle2", role="muzzle2")
    g.add("brass", *[G.rbox((x / 2, BORE, z), (0.2, 0.1, 0.07), bevel=0.025) for z in (-0.5, -1.36)])


def drum(g):
    z, y = -0.36, -0.15
    g.add("steel",
          G.rod((-0.09, y, z), (0.09, y, z), 0.19, 12),  # drum
          G.rbox((0, -0.01, z), (0.1, 0.22, 0.12), bevel=0.02))  # neck into the receiver
    g.add("brass",
          G.rod((-0.125, y, z), (-0.085, y, z), 0.075, 8),  # wind key boss (left)
          G.rod((0.085, y, z), (0.11, y, z), 0.06, 8))  # hub (right)


def build(lp, variant=None):
    if variant:
        g = G.Gun(lp, ENVELOPE, 400)
        {"double": double, "drum": drum}[variant](g)
        base = G.Gun(lp, ENVELOPE, 1200)
        gun(base)
        g.base(base)
        shows = {"double": "HeroStats.shotsPerTrigger >= 2 (Point Blank T3 Double Barrel)",
                 "drum": "HeroStats.fireMode == 'auto' (Buckshot T5 Thicket Sweeper)"}[variant]
        meta = {"gun": "SHOTGUN", "attach": "SHOTGUN", "shows": shows}
    else:
        g = G.Gun(lp, ENVELOPE, 1200)
        gun(g)
        meta = {"gun": "SHOTGUN", "grip": [0, 0, 0], "muzzle": [0, BORE, TIP - 0.01]}
    return g.model("11c2", "gun", COLORS, meta)
