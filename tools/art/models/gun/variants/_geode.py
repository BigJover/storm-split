"""Geode gun / grenade pieces (premium theme, PREMIUM_SKINS.md, batch 11p6): rough grey rock housings cracked open
to amethyst crystal, teal / rose accents. Lit crystal (prism cores, crystal barrels' cores, geode beds) is group
`glow` (Neon in game; Shared/SkinFx's pack tier ramps it as the weapon fires). Authored in the gun frame (_gun.py:
grip at (0, 0, 0), barrel -Z, +Y up) with the `_gun.py` primitives (passed in as G).

  crystal(G, a, b, r, sides, point)   a crystal from a to b: a prism with a pointed termination
  prism(G, a, b, r, sides)            a plain faceted prism (a crystal barrel / a prism core), flat ends
  rock(G, c, radii, rot)              a faceted stone lump (a low-poly ellipsoid, sharp facets)
  geode_disc(g, G, c, axis, r)        a split geode's face: a stone rim ring round a glowing gem disc
"""

import math

import bmesh
from mathutils import Matrix, Vector

COLORS = {
    "rock": (150, 146, 158), "rock2": (96, 92, 104), "crystal": (122, 58, 196), "accent": (150, 84, 220),
    "teal": (52, 196, 186), "rose": (232, 112, 172), "glow": (226, 156, 255),
}


def _sharp(obj):
    for e in obj.data.edges:
        e.use_edge_sharp = True
    return obj


def crystal(G, a, b, r, sides=6, point=0.3, twist=0.0):
    a, b = Vector(a), Vector(b)
    axis = b - a
    L = axis.length
    bm = bmesh.new()
    rings = []
    for z, rr in ((0.0, r * 0.92), (L * (1 - point), r)):
        rings.append([bm.verts.new((rr * math.cos(2 * math.pi * i / sides + math.radians(twist)),
                                    rr * math.sin(2 * math.pi * i / sides + math.radians(twist)), z)) for i in range(sides)])
    apex = bm.verts.new((0, 0, L))
    bm.faces.new(list(reversed(rings[0])))
    for i in range(sides):
        j = (i + 1) % sides
        bm.faces.new((rings[0][i], rings[0][j], rings[1][j], rings[1][i]))
        bm.faces.new((rings[1][i], rings[1][j], apex))
    bmesh.ops.recalc_face_normals(bm, faces=bm.faces)
    rot = axis.to_track_quat("Z", "Y").to_matrix().to_4x4()
    bmesh.ops.transform(bm, matrix=Matrix.Translation(a) @ rot, verts=bm.verts)
    return _sharp(G._obj(bm, "xtal"))


def prism(G, a, b, r, sides=6, twist=0.0, top=1.0):
    obj = G.rod(a, b, r, sides, top=top)
    if twist:
        pass
    return _sharp(obj)


def rock(G, c, radii, rot=None, segments=6, rings=4):
    return _sharp(G.ell(c, radii, segments, rings, rot=rot))


def geode_disc(g, G, c, axis, r, rim="rock", bed="glow"):
    """A split geode's face on a flat side: axis 'x' (a side face) or 'z' / 'y'."""
    g.add(rim, _sharp(G.ring(c, r, r * 0.28, 7, 3, axis=axis)))
    radii = {"x": (r * 0.25, r * 0.9, r * 0.9), "y": (r * 0.9, r * 0.25, r * 0.9), "z": (r * 0.9, r * 0.9, r * 0.25)}[axis]
    g.add(bed, _sharp(G.ell(c, radii, 6, 3)))
