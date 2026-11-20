"""Shapes + placement spots for the Brass Gear and Midnight per-tower set pieces (#457, batch 11e2).
Owned by those two sets (variants/_setpieces_brass.py, variants/_setpieces_midnight.py); runs in
Blender with the tower kit (_kit.py, passed in as K).

Shapes: flat outlines extruded into thin prisms (gear, crescent, star, pennant), the bold silhouettes
that read from the high game camera. Authored in Roblox studs from the tower's base, front -Z.

SPOTS: where each tower kind has room at EVERY stage (from its stage 0-2 art; see the comments),
shared by both sets so each picks its own motif per spot:
  post   (x, z, y0, h)            a tall free-standing column (Brass: smokestack; Midnight: banner pole)
  base   (x, z, y0)               the foot of the post, room for a squat body (boiler / lantern plinth)
  walls  [((x, y, z), facing, r)] a disc / plate hung on a face that exists at every stage
  flats  [((x, y, z), r)]         a flat disc lying on a surface (ground, deck)
facing: "-x" "+x" "-z" "+z" (the outward normal of the wall) or "y" (lying flat).
Optional: br = the boiler radius where the post foot is tight; face = which way a banner on the post
faces (default "-z"; "+x" on the right edge keeps its width inside the footprint).
The left corners hold the set trim, the back-right the owner flag, the front-right the Rescue
Beacon: spots keep off all four corners.
"""

import math

import bmesh
from mathutils import Vector


def rots(facing):
    """(rot for a Y-axis primitive (cyl, ring) so its axis = the facing normal,
        rot for a Z-thin prism so its thin axis = the facing normal)."""
    return {
        "y": (None, (90, 0, 0)),
        "-z": ((90, 0, 0), None),
        "+z": ((90, 0, 0), (0, 180, 0)),
        "-x": ((0, 0, 90), (0, 90, 0)),
        "+x": ((0, 0, 90), (0, -90, 0)),
    }[facing]


def normal(facing):
    return {"y": (0, 1, 0), "-z": (0, 0, -1), "+z": (0, 0, 1), "-x": (-1, 0, 0), "+x": (1, 0, 0)}[facing]


def off(c, facing, d):
    """c moved d studs out along the facing normal."""
    n = normal(facing)
    return tuple(a + b * d for a, b in zip(c, n))


def prism(K, pts, depth, centre, rot=None):
    """A flat outline (x, y points, counter-clockwise) extruded depth along local z, centred."""
    bm = bmesh.new()
    front = [bm.verts.new((x, y, depth / 2)) for x, y in pts]
    back = [bm.verts.new((x, y, -depth / 2)) for x, y in pts]
    bm.faces.new(front)
    bm.faces.new(list(reversed(back)))
    n = len(pts)
    for i in range(n):
        j = (i + 1) % n
        bm.faces.new((front[i], back[i], back[j], front[j]))
    bmesh.ops.recalc_face_normals(bm, faces=bm.faces)
    return K._place(K._obj(bm, "prism"), centre, rot)


def gear_pts(r, teeth=8, depth=0.22, hole=0.0):
    """A cog outline: teeth x (root, root, tip, tip) points."""
    pts, ri = [], r * (1 - depth)
    step = 2 * math.pi / teeth
    for i in range(teeth):
        a = i * step
        for da, rr in ((0.0, ri), (0.18, r), (0.5, r), (0.68, ri)):
            pts.append((rr * math.cos(a + da * step), rr * math.sin(a + da * step)))
    return pts


def crescent_pts(R, inner=0.78, shift=0.42, n=10, m=7, tilt=0.0):
    """A crescent moon: a disc R minus a disc inner*R shifted right by shift*R; opening rotated by tilt deg."""
    r2, d = R * inner, R * shift
    x = (R * R - r2 * r2 + d * d) / (2 * d)
    y = math.sqrt(max(R * R - x * x, 1e-6))
    t0 = math.atan2(y, x)
    pts = [(R * math.cos(t0 + (2 * math.pi - 2 * t0) * i / n), R * math.sin(t0 + (2 * math.pi - 2 * t0) * i / n))
           for i in range(n + 1)]
    p0 = math.atan2(y, x - d)
    pts += [(d + r2 * math.cos(2 * math.pi - p0 - (2 * math.pi - 2 * p0) * i / m),
             r2 * math.sin(2 * math.pi - p0 - (2 * math.pi - 2 * p0) * i / m)) for i in range(1, m)]
    ct, st = math.cos(math.radians(tilt)), math.sin(math.radians(tilt))
    return [(px * ct - py * st, px * st + py * ct) for px, py in pts]


def star_pts(r, inner=0.45, points=5, spin=90.0):
    pts = []
    for i in range(points * 2):
        a = math.radians(spin) + i * math.pi / points
        rr = r if i % 2 == 0 else r * inner
        pts.append((rr * math.cos(a), rr * math.sin(a)))
    return pts


def pennant_pts(w, h, notch=0.3):
    """A hanging banner cloth with a swallowtail: top edge y 0, hanging down to -h."""
    return [(-w / 2, 0), (-w / 2, -h), (0, -h * (1 - notch)), (w / 2, -h), (w / 2, 0)]


def flag_pts(w, h):
    """A small triangular pennant on a line, point down."""
    return [(-w / 2, 0), (0, -h), (w / 2, 0)]


# --- spots per tower kind (Roblox studs from the base; see the module docstring) -------------------
SPOTS = {
    # roof's right side is flat (thatch ~2.15) at every stage; the lookout (S1/S2) is x < 0.5;
    # left wall + front wall (below the awning, above the S1 sandbags) stand at every stage
    "SCOUT": dict(post=(0.95, 0.3, 2.12, 1.45), base=None,
                  walls=[((-1.29, 0.85, 0.15), "-x", 0.36), ((-0.12, 0.95, -1.04), "-z", 0.32)], flats=[]),
    # stilts to the roof (5.0) over the whole footprint: the ground under the deck is open;
    # the left bracing and the deck's front beam (left of the muzzle) are there at every stage
    "SNIPER": dict(post=(0.0, 0.25, 0.0, 2.5), base=(0.0, 0.25, 0.0),
                   walls=[((-1.36, 2.0, 0.0), "-x", 0.55), ((-0.62, 3.28, -1.42), "-z", 0.24)], flats=[]),
    # sandbag ring; inside it the right-back pocket is free at every stage, the mortar pit's floor too
    "GRENADIER": dict(post=(0.98, 0.42, 0.04, 1.9), base=(0.98, 0.42, 0.04),
                      walls=[], flats=[((0.0, 0.06, 0.15), 0.95)]),
    # the block spans x +-1.35 from z -0.6 back; the front-right ground is open (ice crust <= 0.75)
    "CHILLER": dict(post=(0.6, -0.98, 0.0, 2.6), base=(0.6, -0.98, 0.0),
                    walls=[((0.15, 1.2, -0.64), "-z", 0.3), ((0.15, 1.3, 1.03), "+z", 0.45)], flats=[]),
    # tall crate stack on the left (its left face 1.0..4.2 at every stage); right-middle ground open
    "QUARTERMASTER": dict(post=(1.08, 0.3, 0.0, 2.5), base=(1.08, 0.3, 0.0), face="+x",
                          walls=[((-1.42, 2.7, -0.05), "-x", 0.5)], flats=[]),
    # tent: the ground behind it (z 1.3) and the left eave's foot are open at every stage
    "HOSPITAL": dict(post=(-0.25, 1.22, 0.0, 3.6), base=(-0.25, 1.22, 0.0), br=0.24,
                     walls=[((-1.42, 0.48, 0.05), "-x", 0.36)], flats=[]),
    # back wall + shed on the back-left; the right-middle strip is open (the S2 forge is front-right)
    "ARMORY": dict(post=(1.12, 0.12, 0.0, 3.4), base=(1.12, 0.12, 0.0), face="+x",
                   walls=[((-0.25, 2.2, 1.44), "+z", 0.48)], flats=[]),
    # coil in the middle; the deck's left / right middles are free below the S1 ring (y 2.6)
    "COIL": dict(post=None, base=(-1.15, 0.0, 0.55),
                 walls=[((1.36, 1.0, 0.05), "+x", 0.38)], flats=[]),
    # hut back-left, perch front-right: the right-middle ground is open; the hut's left wall stands
    "FALCON": dict(post=(1.1, 0.25, 0.0, 3.0), base=(1.1, 0.25, 0.0), face="+x",
                   walls=[((-1.44, 0.8, 0.45), "-x", 0.42)], flats=[]),
    # round turntable (r ~1.3); bow arms above 1.5
    "BALLISTA": dict(post=None, base=None, walls=[], flats=[((0.0, 0.38, 0.0), 1.3)]),
    # flat pit, no trim (#456): the corners are free, everything <= 0.8
    "TARPIT": dict(post=None, base=(1.18, 0.0, 0.05), walls=[], flats=[((-0.95, 0.3, 0.95), 0.42)]),
    # cannon in the middle, pot back-left: the right-back pocket (z 0.55..0.85) is open
    "RESIN": dict(post=(0.92, 0.5, 0.0, 2.4), base=(0.92, 0.5, 0.0), br=0.3, walls=[], flats=[]),
    # palisade round the edge (to 2.7), hut back-left (S1/S2): the pen's right-back is open
    "RAPTOR": dict(post=(0.7, 0.45, 0.0, 4.0), base=(0.7, 0.45, 0.0),
                   walls=[((-0.85, 1.75, -1.44), "-z", 0.42), ((1.44, 1.7, -0.35), "+x", 0.42)], flats=[]),
    # the pole; the stone ring under 0.35 is the charge ring's: pieces sit on the pole at 0.5..1.0
    "TOTEM": dict(post=None, base=None,
                  walls=[((-0.42, 0.78, 0.0), "-x", 0.2), ((0.42, 0.78, 0.0), "+x", 0.2)],
                  flats=[((0.0, 0.58, 0.0), 0.72)]),
    # mast + guy ropes to the corners: the edge middles are free (gas bottles back-left, crate front-right)
    "BLIMP": dict(post=None, base=(-1.05, -0.3, 0.16),
                  walls=[((1.2, 0.75, 0.4), "+x", 0.3)], flats=[]),
    # dish over everything from 1.6 up (S1/S2): the stone base and the ground round it
    "METEOR": dict(post=(-1.2, 0.0, 0.0, 1.5), base=(-1.2, 0.0, 0.0), br=0.24,
                   walls=[((0.0, 0.42, -1.37), "-z", 0.26)], flats=[((0.0, 0.67, 0.0), 0.98)]),
    # the middle (r 1.1) is the basalt column's: the right and back edges' middles
    "VENT": dict(post=(1.3, -0.3, 0.0, 2.2), base=(1.3, -0.3, 0.0), post2=(-0.3, 1.28, 0.0, 2.6),
                 walls=[], flats=[]),
    # cabin (x <= 0.78, logs to ~0.9), tower front-right, chimney back-left: the strip x 0.9..1.5 is open
    "RANGER": dict(post=(1.18, -0.05, 0.0, 4.2), base=(1.18, -0.05, 0.0), br=0.28, face="+x",
                   walls=[((0.93, 0.85, 0.55), "+x", 0.27)], flats=[]),
}


def near_inside(C, reach=0.35):
    """Sharpen _setpiece_common's clip test for these two sets (its file stays untouched): a vertex
    counts as inside the tower's art only if that art's surface is within `reach` studs of it.
    The plain nearest-face test also fires on far, small, unrelated pieces (a vertex nearest an
    edge or corner of a falcon's beak 3 studs away picks a face that points away from it), which
    flagged wall cogs as 'sunk' into towers they don't touch."""
    from mathutils import Vector

    def _inside(p, trees):
        p = Vector(p)
        for tree in trees:
            loc, normal, _, dist = tree.find_nearest(p, reach)
            if loc is not None and dist > 1e-4 and (p - loc).dot(normal) < 0:
                return True
        return False

    C._inside = _inside
