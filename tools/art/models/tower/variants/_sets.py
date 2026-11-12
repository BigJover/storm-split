"""Tower-set trims (PLAN 11e T155): each tower set (Skins kind "tower": Treehouse, Stone Age, Brass
Gear, Midnight, Gold Rush) gets ONE add-on model, `tower/SET_<SKIN KEY>`, that the runtime adds
over ANY tower's art while that set is worn (TowerLook, #456). 5 trims instead of 18 towers x 3
stages x 5 sets = 270 re-skinned models; the set's two colours + material still repaint the
tower's own art as today (Skins.paintTower), the trim keeps its authored colours.

The trim lives on the edge of the 3 x 3 footprint and stays LOW, so the tower's silhouette, range
ring, crown / glow, HP bar and owner flag are untouched (#381):
  * a rim round the footprint's edge, <= RIM_MAX (0.3) high (Totem's charge ring sits at 0.35;
    Tar Pit lies on the track, art <= 0.8);
  * corner pieces only at the LEFT corners (front-left and back-left, x < -0.3), <= CORNER_MAX
    (1.1) high: the back-right corner is the owner flag's (x 1.2, z 1.2) and the front-right the
    Field Hospital's Rescue Beacon (x 1.25, z -1.25); both stay clear (checked at build);
  * <= CAP (300) tris, so the biggest tower stage (2,698) plus its trim stays <= 3,000 (#433).
Authored like every tower (_kit.py: studs from the base, front -Z; the art origin = the Body's
centre). Previews show the trim on one tower painted in the set (preview-only `context`: the
tower's stage-0 art with group `body` in the set's colour and every other group its accent, the
paintTower rule).
"""

import importlib.util
from pathlib import Path

TOWER = Path(__file__).resolve().parents[1]
BATCH = "11e"
CAP = 300
RIM_MAX = 0.3
CORNER_MAX = 1.1
CLEAR = ((1.2, 1.2), (1.25, -1.25))  # flag pole, Rescue Beacon (Roblox x, z)


def _load(name):
    spec = importlib.util.spec_from_file_location(name, TOWER / f"{name}.py")
    mod = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(mod)
    return mod


def kit_module():
    return _load("_kit")


def rim(k, K, group, h=0.2, w=0.16, bevel=0.0):
    """Four bars round the footprint's edge, outer face on the Body's side (+-1.5)."""
    e = 1.5 - w / 2
    k.add(group,
          K.bar((-1.5, h / 2, -e), (1.5, h / 2, -e), w, h, bevel),
          K.bar((-1.5, h / 2, e), (1.5, h / 2, e), w, h, bevel),
          K.bar((-e, h / 2, -1.5 + w), (-e, h / 2, 1.5 - w), w, h, bevel),
          K.bar((e, h / 2, -1.5 + w), (e, h / 2, 1.5 - w), w, h, bevel))


def _check(lp, key, pieces):
    total = sum(lp.tris(o) for o in pieces)
    assert total <= CAP, f"{key}: {total} tris > the trim cap {CAP}"
    for o in pieces:
        for v in o.data.vertices:
            x, z, y = v.co.x, -v.co.y, v.co.z + 2.5  # Blender -> Roblox, y from the base
            if y > RIM_MAX + 1e-3:
                assert x < -0.3 + 1e-3, f"{key} {o.name}: a raised piece at x {x:.2f} (only the left corners rise)"
                assert y <= CORNER_MAX + 1e-3, f"{key} {o.name}: {y:.2f} high > {CORNER_MAX}"
            for cx, cz in CLEAR:
                assert (x - cx) ** 2 + (z - cz) ** 2 > 0.2 ** 2 or y <= RIM_MAX + 1e-3, f"{key} {o.name}: in the clear corner {cx, cz}"
    return total


def trim(lp, key, display, design, colors, look, show):
    """design(k, K) adds the trim's pieces; look = (colour, accent) of the set (Skins sheet);
    show = the tower shown under it in the previews (its stage-0 art, painted in the set)."""
    K = kit_module()
    k = K.Kit(lp)
    design(k, K)
    pieces, box = k.finish(target=100000)  # never decimated: _check holds the cap
    tris = _check(lp, key, pieces)
    base = _load(f"_{show.lower()}").build(lp, 0)
    context = []
    for o in base["pieces"]:  # preview-only: the tower in the set's paint (Skins.paintTower)
        group = base["groups"].get(o.name, o.name)
        lp.paint(o, look[0] if group == "body" else look[1])
        context.append(o)
    print(f"ART set trim {key}: {tris} tris over {show} (preview)")
    return {
        "batch": BATCH,
        "budget": "tower",
        "tower": f"SET_{key}",
        "stage": 0,
        "box": box,
        "pieces": pieces,
        "groups": dict(k.groups),
        "roles": {},
        "colors": colors,
        "context": context,
        "meta": {"set": key, "display": display, "trim": True, "preview": show, "cap": CAP},
    }
