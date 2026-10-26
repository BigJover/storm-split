"""Blender-side entry for one model (PLAN 11a T146). Run through tools/art/build.sh:

    blender --background --factory-startup --python-exit-code 1 --python tools/art/build.py -- dino HUSK

Loads tools/art/models/<kind>/<key>.py, whose build(lp) returns a model dict:
    batch   "11a"                       the approval batch (#438)
    budget  "small" | "mid" | ...       lowpoly.BUDGETS class (#433)
    box     ((x, y, z), (x, y, z))      Roblox-stud bounds about the gameplay part's centre
    pieces  [obj, ...]                  one object per paint group / role piece
    groups  {name: paint group}         pieces whose name isn't their group (e.g. head -> body)
    roles   {name: ArtRole}             e.g. {"head": "head"}
    colors  {group: (r, g, b)}          the authored colour per paint group (#439): the preview
                                        colour AND the runtime colour (manifest -> ArtIds ->
                                        ArtSlot; group "glow" renders Neon in game)
Then fits the pieces to box, smooths them, checks the budget (exit 1 on a miss), exports
out/<kind>/<key>.fbx, renders previews/<kind>/<key>.png and updates manifest.json (pieces with
their paint group / role, and colors = the authored colour of every group the pieces use).
"""

import importlib.util
import json
import sys
from pathlib import Path

ART = Path(__file__).resolve().parent
sys.path.insert(0, str(ART))

import lowpoly  # noqa: E402
import render  # noqa: E402
import srchash  # noqa: E402


def load(kind, key):
    path = ART / "models" / kind / f"{key}.py"
    spec = importlib.util.spec_from_file_location(f"art_{kind}_{key}", path)
    mod = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(mod)
    return mod


def rbx_bounds(objs):
    """Bounds of objs in Roblox axes: Blender (x, y, z) -> Roblox (x, z, -y)."""
    blo, bhi = lowpoly.bounds(objs)
    lo = (blo[0], blo[2], -bhi[1])
    hi = (bhi[0], bhi[2], -blo[1])
    return [round(float(v), 3) for v in lo], [round(float(v), 3) for v in hi]


def preview_pose(pieces, body, degrees=12):
    """Preview only (after the FBX export): swing the arms out from the shoulders into a
    relaxed A-pose so the sides of the torso read. The exported rest pose is arms down."""
    import math

    from mathutils import Matrix, Vector

    for o in pieces:
        part = o.name.split("__")[0]
        for side, sign in (("Left", -1), ("Right", 1)):
            if part.startswith(side) and ("Arm" in part or "Hand" in part):
                px, py, pz = body.JOINTS[f"{side}Shoulder"]
                pivot = Vector((px, -pz, py))  # Roblox -> Blender
                rot = Matrix.Rotation(math.radians(-degrees * sign), 4, "Y")  # hands outward
                o.matrix_world = Matrix.Translation(pivot) @ rot @ Matrix.Translation(-pivot)


def main_rig(kind, key, model):
    """A hunter hero body (#434): rigid R15 pieces `<R15Part>__<group>`, authored in studs about
    the HumanoidRootPart (no fit-to-box), budget checked, FBX at the rest pose, previews in a
    relaxed pose (3/4 front, side, 3/4 back) on a ground disc."""
    import importlib.util as iu

    spec = iu.spec_from_file_location("_body", ART / "models" / kind / "_body.py")
    body = iu.module_from_spec(spec)
    spec.loader.exec_module(body)

    pieces = model["pieces"]
    for o in pieces:
        part, _, group = o.name.partition("__")
        if part not in body.R15 or not group:
            print(f"ART FAIL {kind}/{key}: piece {o.name!r} is not <R15Part>__<group>")
            sys.exit(1)
        lowpoly.smooth(o)
        lowpoly.paint(o, model["colors"].get(group, (200, 200, 200)))

    counts = {o.name: lowpoly.tris(o) for o in pieces}
    total = sum(counts.values())
    budget = lowpoly.BUDGETS[model["budget"]]
    print(f"ART {kind}/{key}: {total} tris (budget {model['budget']} {budget}) in {len(pieces)} pieces")
    print("ART pieces " + " ".join(f"{n}={c}" for n, c in sorted(counts.items())))
    if total > budget:
        print(f"ART FAIL {kind}/{key}: {total} tris > {budget}")
        sys.exit(1)

    # per R15 part: the art's box vs the default part (#434: same envelope, roughly)
    parts = {}
    for part in body.PARTS:
        objs = [o for o in pieces if o.name.split("__")[0] == part]
        lo, hi = rbx_bounds(objs)
        centre, size = body.R15[part]
        parts[part] = {
            "r15": {"centre": list(centre), "size": list(size)},
            "box": [lo, hi],
            "groups": sorted(o.name.split("__")[1] for o in objs),
        }
        art = [h - l for l, h in zip(lo, hi)]
        off = max(abs((l + h) / 2 - c) for l, h, c in zip(lo, hi, centre))
        print(f"ART part {part:14s} art {art[0]:.2f}x{art[1]:.2f}x{art[2]:.2f} vs r15 "
              f"{size[0]}x{size[1]}x{size[2]}  centre off {off:.2f}")
    lo, hi = rbx_bounds(pieces)
    print(f"ART body box {lo} .. {hi} (height {hi[1] - lo[1]:.2f}, feet at {lo[1]})")

    fbx = ART / "out" / kind / f"{key}.fbx"
    png = ART / "previews" / kind / f"{key}.png"
    fbx.parent.mkdir(parents=True, exist_ok=True)
    png.parent.mkdir(parents=True, exist_ok=True)
    lowpoly.export_fbx(fbx, pieces)

    preview_pose(pieces, body)
    import bpy

    disc = lowpoly.ellipsoid("ground", (0, 0, body.GROUND - 0.02), (1.7, 1.7, 0.02), 32, 4)
    disc.color = (0.45, 0.47, 0.48, 1.0)
    render.render(png, pieces)
    render.render(png.with_name(f"{key}_side.png"), pieces, render.SIDE)
    render.render(png.with_name(f"{key}_back.png"), pieces, render.BACK)
    bpy.data.objects.remove(disc)

    groups = sorted({o.name.split("__")[1] for o in pieces})
    manifest_path = ART / "manifest.json"
    manifest = json.loads(manifest_path.read_text()) if manifest_path.exists() else {}
    manifest.setdefault("approved", [])
    entry = manifest.setdefault("models", {}).setdefault(f"{kind}/{key}", {})
    entry.update(
        {
            "batch": model["batch"],
            "budget": model["budget"],
            "rig": model["rig"],
            "tris": total,
            "hash": srchash.source_hash(kind, key),
            "box": [lo, hi],
            "colors": {g: [int(round(c)) for c in model["colors"][g]] for g in groups if g in model["colors"]},
            "parts": parts,
            "pieces": {
                o.name: {"part": o.name.split("__")[0], "group": o.name.split("__")[1], "role": None, "tris": counts[o.name]}
                for o in pieces
            },
        }
    )
    entry.setdefault("asset", None)
    entry.setdefault("uploadedHash", None)
    manifest_path.write_text(json.dumps(manifest, indent=2, sort_keys=True) + "\n")
    print(f"ART OK {kind}/{key} -> {fbx.relative_to(ART)} {png.relative_to(ART)}")


def main(kind, key):
    lowpoly.reset_scene()
    model = load(kind, key).build(lowpoly)
    if model.get("rig") == "r15":
        return main_rig(kind, key, model)
    pieces = model["pieces"]
    lo, hi = model["box"]
    # Roblox box -> Blender box: x stays, Roblox z flips into Blender y, Roblox y is Blender z
    blo = (lo[0], -hi[2], lo[1])
    bhi = (hi[0], -lo[2], hi[1])
    scale = lowpoly.fit_to_box(pieces, blo, bhi)
    for o in pieces:
        lowpoly.smooth(o)
        group = model.get("groups", {}).get(o.name, o.name)
        lowpoly.paint(o, model["colors"].get(group, (200, 200, 200)))

    groups = sorted({model.get("groups", {}).get(o.name, o.name) for o in pieces})
    colors = {g: [int(round(c)) for c in model["colors"][g]] for g in groups if g in model.get("colors", {})}

    counts = {o.name: lowpoly.tris(o) for o in pieces}
    total = sum(counts.values())
    budget = lowpoly.BUDGETS[model["budget"]]
    print(f"ART {kind}/{key}: {total} tris (budget {model['budget']} {budget}) {counts}")
    print(f"ART fit scale x{scale[0]:.2f} y{scale[1]:.2f} z{scale[2]:.2f}")
    if total > budget:
        print(f"ART FAIL {kind}/{key}: {total} tris > {budget}")
        sys.exit(1)

    fbx = ART / "out" / kind / f"{key}.fbx"
    png = ART / "previews" / kind / f"{key}.png"
    fbx.parent.mkdir(parents=True, exist_ok=True)
    png.parent.mkdir(parents=True, exist_ok=True)
    lowpoly.export_fbx(fbx, pieces)
    render.render(png, pieces)
    render.render(png.with_name(f"{key}_side.png"), pieces, render.SIDE)

    manifest_path = ART / "manifest.json"
    manifest = json.loads(manifest_path.read_text()) if manifest_path.exists() else {}
    manifest.setdefault("approved", [])
    models = manifest.setdefault("models", {})
    entry = models.setdefault(f"{kind}/{key}", {})
    entry.update(
        {
            "batch": model["batch"],
            "budget": model["budget"],
            "tris": total,
            "hash": srchash.source_hash(kind, key),  # #440: repeatable, unlike the geometry
            "box": [list(lo), list(hi)],
            "colors": colors,
            "pieces": {
                o.name: {
                    "group": model.get("groups", {}).get(o.name, o.name),
                    "role": model.get("roles", {}).get(o.name),
                    "tris": counts[o.name],
                }
                for o in pieces
            },
        }
    )
    entry.setdefault("asset", None)  # set by upload.py
    entry.setdefault("uploadedHash", None)
    manifest_path.write_text(json.dumps(manifest, indent=2, sort_keys=True) + "\n")
    print(f"ART OK {kind}/{key} -> {fbx.relative_to(ART)} {png.relative_to(ART)}")


if __name__ == "__main__":
    argv = sys.argv[sys.argv.index("--") + 1:] if "--" in sys.argv else []
    if len(argv) == 3 and argv[0] == "--sheet":  # --sheet <kind> <batch>: contact sheet
        kind, batch = argv[1], argv[2]
        manifest = json.loads((ART / "manifest.json").read_text())
        keys = sorted(k for k, m in manifest["models"].items() if m["batch"] == batch and k.startswith(kind + "/"))
        pngs = [ART / "previews" / f"{k}.png" for k in keys]
        out = ART / "previews" / f"sheet_{batch}_{kind}.png"
        render.contact_sheet(out, pngs)
        print(f"ART OK sheet {out.relative_to(ART)} ({len(pngs)} models)")
    elif len(argv) == 2:
        main(*argv)
    else:
        print("usage: build.py -- <kind> <key> | -- --sheet <kind> <batch>")
        sys.exit(2)
