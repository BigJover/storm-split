"""MEDIC - the Field Medic's Lever-Action Carbine (Config Heroes MEDIC `weapon`): a short carbine
with a brass receiver, blued barrel over a magazine tube, a steel lever loop round the grip point,
a straight walnut stock, a white bandage wrap on the fore-end, a brass saddle ring on the left and
the class-green cross on the butt's left side. No variant attachments: none of the Field Medic's
paths changes the gun's look today (Runaway Lever / Rapid Cycle fire faster, the Muzzle path
changes the rounds). Frame and conventions: _gun.py.
"""

import importlib.util
from pathlib import Path

_spec = importlib.util.spec_from_file_location("_gun", Path(__file__).with_name("_gun.py"))
G = importlib.util.module_from_spec(_spec)
_spec.loader.exec_module(G)

BORE = 0.25
TIP = -1.42
COLORS = {
    "wood": G.WOOD, "steel": G.STEEL, "brass": G.BRASS, "accent": G.ACCENT["MEDIC"],
    "cloth": G.CLOTH, "dark": G.DARK,
}
ENVELOPE = ((-0.3, -0.62, -1.7), (0.3, 0.45, 1.1))


def gun(g):
    w = 0.07
    g.add("wood",
          G.slab([(0.2, 0.22), (0.98, 0.17), (1.0, -0.15), (0.92, -0.18), (0.3, 0.0), (0.2, 0.06)], -w, w, bevel=0.035),
          G.rbox((0, 0.13, 0.16), (0.12, 0.17, 0.24), bevel=0.045, segments=2, rot=(-12, 0, 0)),  # wrist
          G.rod((0, 0.155, -0.3), (0, 0.155, -0.84), 0.07, 10))  # fore-end round the tube
    g.add("dark", G.rbox((0, 0.02, 1.0), (0.15, 0.36, 0.05), bevel=0.02))  # butt plate
    g.add("brass",
          G.rbox((0, 0.19, -0.06), (0.13, 0.22, 0.44), bevel=0.04, segments=2),  # receiver
          G.ring((-0.075, 0.18, 0.05), 0.04, 0.012, 8, 3, axis="x"),  # saddle ring
          G.ell((0, BORE + 0.065, TIP + 0.05), (0.022, 0.03, 0.022), 6, 3))  # bead
    g.add("steel",
          G.rod((0, BORE, -0.28), (0, BORE, TIP), 0.048, 10),  # barrel
          G.rod((0, 0.155, -0.84), (0, 0.155, -1.32), 0.04, 8),  # magazine tube
          G.rod((0, 0.2, -0.86), (0, 0.2, -0.92), 0.105, 10),  # barrel bands
          G.rod((0, 0.2, -1.26), (0, 0.2, -1.32), 0.1, 10),
          G.rbox((0, 0.31, -0.42), (0.06, 0.05, 0.07), bevel=0.015),  # rear sight
          G.rbox((0, 0.06, -0.12), (0.04, 0.06, 0.24), bevel=0.015),  # lever bar under the receiver
          G.ring((0, -0.01, 0.03), 0.085, 0.022, 10, 4, axis="x"),  # lever loop round the grip
          G.rbox((0, 0.04, -0.03), (0.03, 0.08, 0.03), bevel=0.01, rot=(15, 0, 0)))  # trigger
    g.add("steel", G.muzzle_ring((0, BORE, TIP - 0.01), 0.05), piece="muzzle", role="muzzle")
    g.add("cloth", G.rod((0, 0.155, -0.5), (0, 0.155, -0.64), 0.078, 10))  # bandage wrap
    g.add("accent",
          G.rbox((-0.073, 0.03, 0.66), (0.02, 0.2, 0.07), bevel=0.008),  # green cross, butt left
          G.rbox((-0.073, 0.03, 0.66), (0.02, 0.07, 0.2), bevel=0.008))


def build(lp, variant=None):
    g = G.Gun(lp, ENVELOPE, 1200)
    gun(g)
    meta = {"gun": "MEDIC", "grip": [0, 0, 0], "muzzle": [0, BORE, TIP - 0.01]}
    return g.model("11c2", "gun", COLORS, meta)
