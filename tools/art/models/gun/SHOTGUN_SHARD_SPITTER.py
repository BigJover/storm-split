"""SHOTGUN_SHARD_SPITTER - Shotgun premium skin Shard Spitter (Geode theme, PREMIUM_SKINS.md, batch 11p6): its own
silhouette - a CROWN of amethyst shards fanning forward round the muzzle (the gun spits crystal), a chunky
boulder pump split open on both sides to a glowing gem bed, a hexagonal crystal barrel sleeve, a side saddle of
teal crystal "shells" in a stone holder, a crest of crystals on the receiver and a heavy faceted stone stock
with a glowing crack.

Receiver, barrel, magazine tube, trigger, guard and the `muzzle` piece are the base's; grip at (0, 0, 0).
Stock, wrist, grip (re-added in stone), pump, butt pad, groove, saddle plate, tube cap, bead, rim strip and
shells are dropped. `glow` = Neon in game. Base: gun/SHOTGUN (variants/_skins.py), cap 868 with both attachments.
"""
# art-sources: _shotgun.py variants/_skins.py variants/_geode.py

import importlib.util
import math
from pathlib import Path

_dir = Path(__file__).with_name("variants")
_spec = importlib.util.spec_from_file_location("_skins", _dir / "_skins.py")
S = importlib.util.module_from_spec(_spec)
_spec.loader.exec_module(S)
_spec = importlib.util.spec_from_file_location("_geode_gun", _dir / "_geode.py")
X = importlib.util.module_from_spec(_spec)
_spec.loader.exec_module(X)


def extra(g, G, D):
    w = 0.08
    bore = D.BORE
    # heavy stone stock + grip, a glowing crack down its side
    g.add("rock", G.slab([(0.18, 0.26), (0.96, 0.24), (1.02, -0.18), (0.92, -0.22), (0.3, 0.0), (0.18, 0.06)], -w, w, bevel=0.0),
          G.rbox((0, 0.15, 0.08), (0.14, 0.17, 0.26), bevel=0.0),
          G.rbox((0, -0.05, 0.08), (0.13, 0.28, 0.15), bevel=0.0, rot=(-22, 0, 0)))
    g.add("glow", *[G.rod(((w + 0.004) * k, y0, z0), ((w + 0.004) * k, y1, z1), 0.016, 3)
                    for k in (-1, 1) for (y0, z0), (y1, z1) in (((0.2, 0.36), (0.06, 0.58)), ((0.06, 0.58), (0.1, 0.84)))])
    g.add("rock2", G.rbox((0, 0.04, 1.02), (0.17, 0.42, 0.05), bevel=0.0))
    # boulder pump split open on both sides to a glowing gem bed
    g.add("rock", X.rock(G, (0, 0.12, -0.78), (0.12, 0.11, 0.24), segments=6, rings=4))
    for k in (-1, 1):
        X.geode_disc(g, G, (0.1 * k, 0.12, -0.78), "x", 0.075)
    # crystal barrel sleeve
    g.add("accent", X.prism(G, (0, bore, -0.32), (0, bore, -1.18), 0.082, 6))
    g.add("rock", X.prism(G, (0, bore, -1.16), (0, bore, -1.26), 0.1, 6))
    # the shard crown round the muzzle: shards fanning forward and out
    shards = []
    for i in range(6):
        a = math.radians(30 + 60 * i)
        dx, dy = math.cos(a), math.sin(a)
        shards.append(X.crystal(G, (0.07 * dx, bore + 0.07 * dy, -1.2), (0.17 * dx, bore + 0.155 * dy, -1.5), 0.035, 5))
    g.add("glow", *shards[0::2])
    g.add("crystal", *shards[1::2])
    # side saddle: teal crystal shells in a stone holder (left)
    g.add("rock", G.rbox((-0.1, 0.2, -0.04), (0.04, 0.16, 0.38), bevel=0.0))
    g.add("teal", *[X.crystal(G, (-0.125, 0.14, z), (-0.125, 0.33, z), 0.028, 5) for z in (-0.17, -0.06, 0.05)])
    # crystal crest on the receiver
    g.add("glow", X.crystal(G, (0, 0.31, -0.02), (0, 0.44, -0.12), 0.045, 5))
    g.add("crystal", *[X.crystal(G, (0.03 * k, 0.31, 0.1), (0.07 * k, 0.42, 0.06), 0.032, 5) for k in (-1, 1)])


def build(lp):
    model = S.variant(
        lp, "SHOTGUN", "SHARD_SPITTER", "Shard Spitter",
        drop=[("wood", 0), ("wood", 1), ("wood", 2), ("wood", 3), ("dark", 0), ("dark", 1), ("steel", 4),
              ("brass", 1), ("brass", 2), ("brass", 3), ("accent", 0), ("accent", 1), ("accent", 2), ("accent", 3)],
        move=[("steel", 0, "rock2")],
        extra=extra,
        colors={**X.COLORS, "steel": (70, 66, 80), "brass": (176, 150, 200)},
    )
    model["batch"] = "11p6"
    model["meta"].update({"theme": "GEODE", "premium": True})
    return model
