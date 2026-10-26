"""Blender-side entry for one model (PLAN 11a T146). Run through tools/art/build.sh:

    blender --background --factory-startup --python-exit-code 1 --python tools/art/build.py -- dino HUSK

Loads tools/art/models/<kind>/<key>.py, whose build(lp) returns a model dict:
    batch   "11a"                       the approval batch (#438)
    budget  "small" | "mid" | ...       lowpoly.BUDGETS class (#433)
    box     ((x, y, z), (x, y, z))      Roblox-stud bounds about the gameplay part's centre
    pieces  [obj, ...]                  one object per paint group / role piece
    groups  {name: paint group}         pieces whose name isn't their group (e.g. head -> body)
    roles   {name: ArtRole}             e.g. {"head": "head"}
    colors  {group: (r, g, b)}          preview colours only
Then fits the pieces to box, smooths them, checks the budget (exit 1 on a miss), exports
out/<kind>/<key>.fbx, renders previews/<kind>/<key>.png and updates manifest.json.
"""

import importlib.util
import json
import sys
from pathlib import Path

ART = Path(__file__).resolve().parent
sys.path.insert(0, str(ART))

import lowpoly  # noqa: E402
import render  # noqa: E402


def load(kind, key):
    path = ART / "models" / kind / f"{key}.py"
    spec = importlib.util.spec_from_file_location(f"art_{kind}_{key}", path)
    mod = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(mod)
    return mod


def main(kind, key):
    lowpoly.reset_scene()
    model = load(kind, key).build(lowpoly)
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
            "hash": lowpoly.geometry_hash(pieces),
            "box": [list(lo), list(hi)],
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
