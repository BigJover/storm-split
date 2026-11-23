"""RIFLE_GRENADE_MOON_ROCK - the Big Game Hunter's grenade, premium skin Moon Rock (Nebula theme,
PREMIUM_SKINS.md, batch 11p5, #462: its own silhouette, element cosmic / void). A tiny ringed planet: a
faceted pale-lilac moon pocked with dark craters, a wide tilted starlight ring round its middle with a
moonlet riding it and star points on the rock; the Safari Grenade's fuse head, spoon lever and pull
ring stay on top so it still reads as a grenade, with a starlight fuse cap. `glow` = Neon in game
(Shared/SkinFx: the blast recolours to the theme; the pack tier adds a trail in flight). Same frame as
the base (kit/_prop.py: origin = the thrown 0.9 ball's centre, upright), <= 600 tris.
"""

import importlib.util
import math
from pathlib import Path

_spec = importlib.util.spec_from_file_location("_prop", Path(__file__).with_name("_prop.py"))
D = importlib.util.module_from_spec(_spec)
_spec.loader.exec_module(D)
G = D.G

R = 0.29
C = (0, -0.04, 0)


def on_ball(yaw, pitch, lift=1.0):
    y, p = math.radians(yaw), math.radians(pitch)
    return (C[0] + R * lift * math.cos(p) * math.sin(y), C[1] + R * lift * math.sin(p), C[2] - R * lift * math.cos(p) * math.cos(y))


def faceted(obj):
    for e in obj.data.edges:
        e.use_edge_sharp = True
    return obj


def moon(g):
    g.add("body", faceted(G.ell(C, (R, R * 0.96, R), 10, 6)))
    craters = []
    for yaw, p, s in ((20, 30, 0.09), (-40, -15, 0.07), (110, 35, 0.08), (190, -20, 0.09), (280, 25, 0.07)):
        a, b = on_ball(yaw, p, 0.93), on_ball(yaw, p, 1.03)
        craters.append(G.rod(a, b, s, 6, top=1.15))
    g.add("crater", *craters)
    # the ring: wide, tilted, a moonlet riding it
    tilt = (22, 0, -14)
    g.add("glow", G.ring(C, 0.46, 0.022, 14, 3, axis="y", rot=tilt),
          *[G.ell(on_ball(yaw, p, 1.02), (0.025, 0.025, 0.025), 4, 2) for yaw, p in ((70, 10), (-90, 50), (230, -40))])
    g.add("ring", G.ring(C, 0.38, 0.03, 12, 3, axis="y", rot=tilt))
    a = math.radians(200)
    x, z = 0.46 * math.cos(a), 0.46 * math.sin(a)
    # rotate (x, 0, z) by the tilt (X then Z, as Euler XYZ)
    rx, rz = math.radians(tilt[0]), math.radians(tilt[2])
    y1, z1 = -z * math.sin(rx), z * math.cos(rx)
    x2, y2 = x * math.cos(rz) - y1 * math.sin(rz), x * math.sin(rz) + y1 * math.cos(rz)
    g.add("crater", G.ell((C[0] + x2, C[1] + y2, C[2] + z1), (0.06, 0.06, 0.06), 6, 3))
    g.add("steel", G.rod((0, 0.22, 0), (0, 0.36, 0), 0.075, 7))  # fuse head
    g.add("glow", G.ell((0, 0.37, 0), (0.05, 0.03, 0.05), 6, 3))
    g.add("brass",
          G.bar((0.08, 0.34, 0), (0.24, 0.1, 0), 0.07, 0.025, up=(1, 0, 0)),
          G.bar((0.24, 0.1, 0), (0.29, -0.08, 0), 0.07, 0.025, up=(1, 0, 0)),
          G.ring((-0.13, 0.34, 0), 0.07, 0.016, 8, 3, axis="z"))


def build(lp):
    g = G.Gun(lp, D.GRENADE, D.CAP)
    moon(g)
    meta = {"hero": "RIFLE", "prop": "grenade", "display": "Moon Rock", "skin": "MOON_ROCK",
            "base": "kit/RIFLE_GRENADE", "centre": [0, 0, 0], "theme": "NEBULA", "premium": True}
    return g.model("11p5", "small", {"body": (176, 168, 204), "crater": (124, 74, 156), "ring": (70, 52, 130),
                                      "glow": (150, 236, 240), "steel": (60, 58, 92), "brass": (190, 186, 224)}, meta)
