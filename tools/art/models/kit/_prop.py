"""Each hunter's melee and grenade prop (PLAN 11c T151, batch 11c2; names = Config HunterKit
meleeName / grenadeName). Built with the gun helpers (models/gun/_gun.py, hashed for this kind by
srchash.py); budget class `small` in build.py, capped at 600 tris here.

Melee (`<HERO>_MELEE`): authored like a gun - the grip point at the origin (the Tool Handle's
origin on RightGripAttachment), the blade / head pointing -Z, the edge down (-Y).
Grenade (`<HERO>_GRENADE`): the origin = the centre of today's thrown 0.9-stud ball (Server/Kit),
the prop about that size, upright (+Y).
"""

import importlib.util
from pathlib import Path

_spec = importlib.util.spec_from_file_location("_gun", Path(__file__).parent.parent / "gun" / "_gun.py")
G = importlib.util.module_from_spec(_spec)
_spec.loader.exec_module(G)

CAP = 600
MELEE = ((-0.25, -0.4, -1.8), (0.25, 0.4, 0.5))
GRENADE = ((-0.55, -0.55, -0.55), (0.55, 0.55, 0.55))

NAMES = {
    "PISTOL_MELEE": "Hunting Knife", "RIFLE_MELEE": "Stock Swing",
    "SHOTGUN_MELEE": "Brush Machete", "MEDIC_MELEE": "Splint Stick",
    "PISTOL_GRENADE": "Stink Bomb", "RIFLE_GRENADE": "Safari Grenade",
    "SHOTGUN_GRENADE": "Cherry Bomb", "MEDIC_GRENADE": "Dozy Cloud",
}


def knife(g):
    g.add("wood", G.rod((0, 0, 0.27), (0, 0, -0.12), 0.06, 10, top=0.85))
    g.add("brass",
          G.ell((0, 0, 0.29), (0.065, 0.07, 0.05), 8, 4),  # pommel
          G.rbox((0, -0.01, -0.14), (0.07, 0.22, 0.045), bevel=0.015))  # guard
    g.add("blade", G.slab([(-0.14, 0.065), (-0.68, 0.065), (-0.8, 0.035), (-0.92, 0.0), (-0.82, -0.055), (-0.6, -0.08), (-0.14, -0.075)], -0.02, 0.02, bevel=0.012))
    g.add("accent", G.rod((0, 0, 0.1), (0, 0, 0.02), 0.064, 10))  # red leather wrap
    g.groups["blade"] = "steel"


def stock(g):
    w = 0.075
    g.add("wood",
          G.rod((0, 0, 0.3), (0, 0, -0.22), 0.07, 10),  # wrist / handle
          G.slab([(-0.18, 0.08), (-0.95, 0.16), (-1.0, 0.13), (-1.0, -0.25), (-0.92, -0.28), (-0.3, -0.08), (-0.18, -0.06)], -w, w, bevel=0.035))
    g.add("dark", G.rbox((0, -0.06, -1.02), (0.16, 0.44, 0.05), bevel=0.02))  # butt pad
    g.add("steel",
          G.rod((0, 0, 0.3), (0, 0, 0.38), 0.075, 10),  # cap
          G.rbox((0, 0.02, -0.16), (0.16, 0.18, 0.06), bevel=0.02))  # ferrule
    g.add("brass", G.rod((0, -0.12, -0.6), (0, -0.17, -0.6), 0.03, 6))  # sling swivel
    g.add("accent", G.ell((-0.077, -0.04, -0.66), (0.012, 0.075, 0.12), 8, 3))  # class badge (left)


def machete(g):
    g.add("wood", G.slab([(0.3, 0.05), (0.32, -0.02), (0.26, -0.08), (-0.14, -0.06), (-0.14, 0.06)], -0.045, 0.045, bevel=0.02, segments=2))
    g.add("brass",
          G.rod((-0.05, 0.0, 0.05), (0.05, 0.0, 0.05), 0.022, 6),  # rivets
          G.rod((-0.05, 0.0, 0.2), (0.05, 0.0, 0.2), 0.022, 6),
          G.rbox((0, 0.0, -0.16), (0.08, 0.15, 0.04), bevel=0.012))  # bolster
    g.add("blade", G.slab([(-0.15, 0.06), (-1.2, 0.1), (-1.42, 0.08), (-1.55, -0.04), (-1.45, -0.18), (-1.1, -0.2), (-0.15, -0.07)], -0.016, 0.016, bevel=0.01))
    g.add("accent", G.ring((0, -0.06, 0.38), 0.07, 0.018, 8, 3, axis="x"))  # orange lanyard loop
    g.groups["blade"] = "steel"


def splint(g):
    g.add("wood",
          G.rbox((0, 0.06, -0.5), (0.15, 0.05, 1.42), bevel=0.02),  # two splint boards
          G.rbox((0, -0.06, -0.5), (0.15, 0.05, 1.42), bevel=0.02))
    g.add("cloth", *[G.rbox((0, 0, z), (0.19, 0.2, 0.1), bevel=0.035) for z in (-0.42, -0.82, -1.12)])
    g.add("accent", G.rbox((0, 0, 0.05), (0.19, 0.2, 0.36), bevel=0.05, segments=2))  # green grip tape


def stink(g):
    g.add("glass",
          G.ell((0, -0.1, 0), (0.33, 0.3, 0.33), 12, 7),  # jar
          G.rod((0, 0.14, 0), (0, 0.32, 0), 0.13, 10))  # neck
    g.add("cork", G.rod((0, 0.3, 0), (0, 0.44, 0), 0.12, 10, top=1.15))
    g.add("cloth", G.ring((0, 0.24, 0), 0.14, 0.03, 10, 4, axis="y"),  # rag tied round the neck
          G.rbox((0.17, 0.17, 0), (0.08, 0.16, 0.05), bevel=0.02, rot=(0, 0, -25)))  # its tail
    g.add("accent", G.rbox((0, -0.08, -0.31), (0.24, 0.16, 0.04), bevel=0.015, rot=(8, 0, 0)))  # red label


def safari(g):
    g.add("body", G.ell((0, -0.06, 0), (0.28, 0.34, 0.28), 12, 8))
    g.add("dark", *[G.ring((0, y, 0), r, 0.025, 12, 3, axis="y") for y, r in ((-0.2, 0.235), (0.08, 0.255))])
    g.add("accent", G.ring((0, -0.06, 0), 0.28, 0.035, 12, 3, axis="y"))  # yellow band
    g.add("steel", G.rod((0, 0.24, 0), (0, 0.38, 0), 0.08, 8))  # fuse head
    g.add("brass",
          G.bar((0.08, 0.36, 0), (0.25, 0.08, 0), 0.07, 0.025, up=(1, 0, 0)),  # spoon lever down the side
          G.bar((0.25, 0.08, 0), (0.26, -0.1, 0), 0.07, 0.025, up=(1, 0, 0)),
          G.ring((-0.13, 0.36, 0), 0.07, 0.016, 10, 3, axis="z"))  # pull ring


def cherry(g):
    g.add("body", G.ell((0, -0.04, 0), (0.33, 0.33, 0.33), 12, 8))
    g.add("brass", G.rod((0, 0.25, 0), (0, 0.33, 0), 0.06, 8))  # ferrule
    g.add("dark", *G.strap([(0, 0.31, 0), (0.06, 0.43, 0), (0.15, 0.49, 0)], 0.035, 0.035))  # fuse
    g.add("glow", G.ell((0.17, 0.5, 0), (0.05, 0.05, 0.05), 6, 4))  # the lit end
    g.add("accent", G.ring((0, -0.04, 0), 0.33, 0.03, 12, 3, axis="y"))  # orange band


def dozy(g):
    g.add("body", G.rod((0, -0.36, 0), (0, 0.18, 0), 0.22, 12, bevel=0.04))  # canister
    g.add("steel",
          G.rod((0, 0.16, 0), (0, 0.27, 0), 0.15, 10, top=0.7),  # shoulder cap
          G.rod((0, 0.26, 0), (0, 0.38, 0), 0.05, 8),  # valve stem
          G.rbox((0, 0.36, -0.1), (0.05, 0.05, 0.16), bevel=0.012))  # nozzle
    g.add("brass", G.ring((0, 0.4, 0), 0.08, 0.018, 10, 3, axis="y"))  # valve wheel
    g.add("cloth", G.rod((0, -0.22, 0), (0, 0.02, 0), 0.232, 12, bevel=0.012))  # label band
    g.add("accent",
          G.rbox((0, -0.1, -0.237), (0.05, 0.16, 0.02), bevel=0.006),  # green cross on the label
          G.rbox((0, -0.1, -0.237), (0.16, 0.05, 0.02), bevel=0.006))


DESIGNS = {
    "PISTOL_MELEE": (knife, MELEE, {"wood": G.WOOD, "brass": G.BRASS, "steel": G.STEEL_LIGHT, "accent": G.ACCENT["PISTOL"]}),
    "RIFLE_MELEE": (stock, MELEE, {"wood": G.WOOD, "dark": G.DARK, "steel": G.STEEL, "brass": G.BRASS, "accent": G.ACCENT["RIFLE"]}),
    "SHOTGUN_MELEE": (machete, MELEE, {"wood": G.WOOD_LIGHT, "brass": G.BRASS, "steel": G.STEEL_LIGHT, "accent": G.ACCENT["SHOTGUN"]}),
    "MEDIC_MELEE": (splint, MELEE, {"wood": G.WOOD_LIGHT, "cloth": G.CLOTH, "accent": G.ACCENT["MEDIC"]}),
    "PISTOL_GRENADE": (stink, GRENADE, {"glass": (150, 176, 84), "cork": G.CORK, "cloth": G.CLOTH, "accent": G.ACCENT["PISTOL"]}),
    "RIFLE_GRENADE": (safari, GRENADE, {"body": (118, 116, 70), "dark": G.DARK, "steel": G.STEEL, "brass": G.BRASS, "accent": G.ACCENT["RIFLE"]}),
    "SHOTGUN_GRENADE": (cherry, GRENADE, {"body": (196, 36, 44), "brass": G.BRASS, "dark": G.DARK, "glow": (255, 196, 90), "accent": G.ACCENT["SHOTGUN"]}),
    "MEDIC_GRENADE": (dozy, GRENADE, {"body": (176, 160, 214), "steel": G.STEEL, "brass": G.BRASS, "cloth": G.CLOTH, "accent": G.ACCENT["MEDIC"]}),
}


def build(lp, key):
    design, envelope, colors = DESIGNS[key]
    g = G.Gun(lp, envelope, CAP)
    design(g)
    hero, _, what = key.partition("_")
    meta = {"hero": hero, "prop": what.lower(), "display": NAMES[key]}
    meta["grip" if what == "MELEE" else "centre"] = [0, 0, 0]
    return g.model("11c2", "small", colors, meta)
