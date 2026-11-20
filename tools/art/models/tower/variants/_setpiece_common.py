"""Per-tower set pieces (#457, batch 11e2): each tower set (Treehouse, Stone Age, Brass Gear,
Midnight, Gold Rush) gets one bold themed add-on per tower kind, `tower/SET_<SET>_<TOWER>`, that
the runtime adds over that tower's art at EVERY stage while the set is worn, on top of the set's
trim (`tower/SET_<SET>`, variants/_sets.py) and the set's paint (TowerLook.applySkin).

Shared by every set's piece scripts (read-only once other sets import it). A piece script:

    # art-sources: variants/_setpiece_common.py variants/_setpieces_<set>.py
    def build(lp):
        return C.setpiece(lp, "TREEHOUSE", "SCOUT", design, colors)

design(k, K) authors the piece with the tower kit (_kit.py: Roblox studs from the base, front -Z,
the Body's 3 x 5 x 3 box). setpiece() then checks it against all three stages of that tower:
  * <= CAP (800) tris;
  * the owner flag's corner (x 1.2, z 1.2) and the Rescue Beacon's (x 1.25, z -1.25) stay clear
    above RIM (0.3): no vertex within CLEAR_R of either column;
  * the `muzzle` of every stage untouched: no vertex within MUZZLE_R of it, nor in a 0.8 x 0.8
    lane straight out of it toward the front (-Z);
  * TARPIT pieces <= TARPIT_MAX (0.8) tall (it lies on the track);
  * VENT keeps its middle (radius VENT_R about the centre) clear above RIM (the basalt column /
    Fire Mountain cone);
  * clipping: the share of the piece's vertices inside each stage's art is printed (`ART clip`)
    and must stay <= CLIP_MAX (pieces may wrap a post or hang on a wall, not sink into it).
Previews: build.py renders the piece on the tower's stage 0 (context: the stage-0 art in the
set's paint + the set's trim); setpiece() also renders it on stage 2 itself, to
previews/tower/<KEY>_s2.png and <KEY>_s2_top.png. Manifest meta: set, display, piece, towerKind.
"""

import importlib.util
import math
import sys
from pathlib import Path

TOWER = Path(__file__).resolve().parents[1]
ART = TOWER.parents[1]
BATCH = "11e2"
CAP = 800
RIM = 0.3
CLEAR = ((1.2, 1.2), (1.25, -1.25))  # flag pole, Rescue Beacon (Roblox x, z)
CLEAR_R = 0.3
MUZZLE_R = 0.45
TARPIT_MAX = 0.8
VENT_R = 1.1
CLIP_MAX = 0.35
TOWERS = ("SCOUT", "SNIPER", "GRENADIER", "CHILLER", "QUARTERMASTER", "HOSPITAL", "ARMORY", "COIL",
          "FALCON", "BALLISTA", "TARPIT", "RESIN", "RAPTOR", "TOTEM", "BLIMP", "METEOR", "VENT", "RANGER")


def load(path, name=None):
    """A module from a file under models/tower/ (e.g. "_kit.py", "variants/_sets.py")."""
    spec = importlib.util.spec_from_file_location(name or Path(path).stem, TOWER / path)
    mod = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(mod)
    return mod


def _roblox(o):
    """Roblox (x, y from the base, z) of every vertex of a finished piece."""
    return [(v.co.x, v.co.z + 2.5, -v.co.y) for v in o.data.vertices]


def _trim(lp, set_key):
    """The set's trim script's arguments to _sets.trim (design, colours, look), without building it."""
    mod = load(f"SET_{set_key}.py", f"_trim_{set_key}")
    got = {}

    def grab(lp_, key, display, design, colors, look, show):
        got.update(display=display, design=design, colors=colors, look=look)
        return {}

    mod.S.trim = grab
    mod.build(lp)
    return got


def _trees(obj_list):
    from mathutils.bvhtree import BVHTree

    return [BVHTree.FromPolygons([v.co.copy() for v in o.data.vertices], [p.vertices[:] for p in o.data.polygons])
            for o in obj_list]


def _inside(p, trees):
    """p inside any tree's mesh: its nearest face's normal points away from p."""
    from mathutils import Vector

    p = Vector(p)
    for tree in trees:
        loc, normal, _, dist = tree.find_nearest(p)
        if loc is not None and dist > 1e-4 and (p - loc).dot(normal) < 0:
            return True
    return False


def _check(lp, key, tower, pieces, stages):
    total = sum(lp.tris(o) for o in pieces)
    assert total <= CAP, f"{key}: {total} tris > the set-piece cap {CAP}"
    verts = [v for o in pieces for v in _roblox(o)]
    for x, y, z in verts:
        if y > RIM + 1e-3:
            for cx, cz in CLEAR:
                assert (x - cx) ** 2 + (z - cz) ** 2 > CLEAR_R ** 2, \
                    f"{key}: a vertex at ({x:.2f}, {y:.2f}, {z:.2f}) in the clear corner {cx, cz}"
            if tower == "VENT":
                assert x * x + z * z > VENT_R ** 2, f"{key}: a vertex at ({x:.2f}, {y:.2f}, {z:.2f}) in the Vent's middle"
        if tower == "TARPIT":
            assert y <= TARPIT_MAX + 1e-3, f"{key}: {y:.2f} high > {TARPIT_MAX} (Tar Pit lies on the track)"
    for s, model in enumerate(stages):
        for o in model["pieces"]:
            if model["roles"].get(o.name) != "muzzle":
                continue
            pts = _roblox(o)
            mx, my, mz = (sum(p[i] for p in pts) / len(pts) for i in range(3))
            for x, y, z in verts:
                d = math.dist((x, y, z), (mx, my, mz))
                assert d > MUZZLE_R, f"{key}: {d:.2f} from stage {s}'s muzzle"
                assert not (z < mz and abs(x - mx) < 0.4 and abs(y - my) < 0.4), \
                    f"{key}: ({x:.2f}, {y:.2f}, {z:.2f}) in front of stage {s}'s muzzle"
    blender = [tuple(v.co) for o in pieces for v in o.data.vertices]
    shares = []
    for model in stages:
        trees = _trees(model["pieces"])
        shares.append(sum(_inside(p, trees) for p in blender) / max(1, len(blender)))
    print(f"ART clip {key}: " + " ".join(f"s{s} {v:.0%}" for s, v in enumerate(shares)))
    worst = max(shares)
    assert worst <= CLIP_MAX, f"{key}: {worst:.0%} of the piece inside the tower's art > {CLIP_MAX:.0%}"
    return total


def _dress(lp, model, look):
    """Preview only: a tower stage in the set's paint (Skins.paintTower: body = colour, rest = accent)."""
    out = []
    for name, o in zip(sorted(model["groups"]), model["pieces"]):  # Kit.finish order; o.name may be "body.001"
        group = model["groups"][name]
        lp.paint(o, look[0] if group == "body" else look[1])
        lp.smooth(o)
        out.append(o)
    return out


def _trim_pieces(lp, K, trim):
    k = K.Kit(lp)
    trim["design"](k, K)
    pieces, _ = k.finish(target=100000)
    for name, o in zip(sorted(k.sets), pieces):  # Kit.finish order; o.name may be "leaf.001"
        lp.paint(o, trim["colors"].get(k.groups[name], (200, 200, 200)))
        lp.smooth(o)
    return pieces


def _render_stage2(lp, key, pieces, groups, colors, extra):
    import bpy

    sys.path.insert(0, str(ART))
    import build as B  # tower_ground / tower_frame / TOWER_TOP (build.py is importable: main is guarded)
    import render

    for o in pieces:
        lp.paint(o, colors.get(groups.get(o.name, o.name), (200, 200, 200)))
    lo, _ = lp.bounds(pieces + extra)
    ground = B.tower_ground((0, -2.5, 0))
    framed = pieces + extra + [ground]
    frame = B.tower_frame(pieces + extra)
    png = ART / "previews" / "tower" / f"{key}_s2.png"
    png.parent.mkdir(parents=True, exist_ok=True)
    render.render(png, framed + [frame])
    render.render(png.with_name(f"{key}_s2_top.png"), framed + [frame], B.TOWER_TOP)
    for o in [ground, frame]:
        bpy.data.objects.remove(o)


def setpiece(lp, set_key, tower, design, colors):
    """design(k, K) adds the piece's primitives; colors = {group: (r, g, b)} (authored)."""
    import bpy

    key = f"SET_{set_key}_{tower}"
    K = load("_kit.py", "_kit")
    k = K.Kit(lp)
    design(k, K)
    pieces, box = k.finish(target=100000)  # never decimated: _check holds the cap
    groups = dict(k.groups)
    trim = _trim(lp, set_key)
    D = load(f"_{tower.lower()}.py", f"_{tower.lower()}")
    stages = [D.build(lp, s) for s in range(3)]
    tris = _check(lp, key, tower, pieces, stages)
    for model in stages[:2]:
        for o in model["pieces"]:
            bpy.data.objects.remove(o)
    with_trim = tower != "TARPIT"  # the trim is never on Tar Pit (#456)
    trim_objs = _trim_pieces(lp, K, trim) if with_trim else []
    s2 = _dress(lp, stages[2], trim["look"])
    _render_stage2(lp, key, pieces, groups, colors, s2 + trim_objs)
    for o in s2:
        bpy.data.objects.remove(o)
    s0 = _dress(lp, D.build(lp, 0), trim["look"])
    print(f"ART set piece {key}: {tris} tris over {tower} (stages 0-2 checked)")
    return {
        "batch": BATCH,
        "budget": "tower",
        "tower": key,
        "stage": 0,
        "box": box,
        "pieces": pieces,
        "groups": groups,
        "roles": {},
        "colors": colors,
        "context": s0 + trim_objs,
        "meta": {"set": set_key, "display": trim["display"], "piece": True, "towerKind": tower, "cap": CAP},
    }
