#!/usr/bin/env python3
"""Regenerate src/shared/ArtIds.luau (PLAN 11a T147, DECISIONS #422/#423). Never hand-edit
that file: this is its only writer.

Sources, merged per kind/key:
  * tools/art/manifest.json  models[<kind>/<key>].asset   -> model = <asset id>   (upload.py)
  * tools/art/manifest.json  models[<kind>/<key>].colors  -> colors = { [group]: Color3 }
                             (the authored colour per paint group, build.py; DECISIONS #439)
  * tools/art/harvest.json   {kind: {key: {group: {mesh, size: [x, y, z]}}}}       (Studio import)

    python3 tools/art/write_ids.py           # write the file
    python3 tools/art/write_ids.py --check   # exit 1 if the file is out of date
"""

import json
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
ART = ROOT / "tools" / "art"
OUT = ROOT / "src" / "shared" / "ArtIds.luau"
KINDS = ("dino", "tower")
# Built and previewed, but no runtime reader yet: hunter hero bodies (T150) reach ArtIds with
# the T150 runtime task (Bodies / Wardrobe), after Jovan approves the 11c previews.
PENDING_KINDS = ("hunter",)

HEADER = """--!strict
--[[
	GENERATED — DO NOT EDIT. tools/art writes this file (upload.py after an Open Cloud
	upload, or write_ids.py after a Studio-import harvest; PLAN 11a T147, DECISIONS #422/#423).

	The art asset ids per kind and key (DinoLook / TowerLook keys):
	  { [kind]: { [key]: { model: number?, parts: { [group]: { mesh: string, size: Vector3 } }?,
	    colors: { [group]: Color3 }? } } }
	A blank or missing model id means that look builds as its blocky fallback (#425).
	colors = the authored colour per paint group (#439); ArtSlot paints the art with them
	(a group without one takes the look's colours).
	Asset ids are not secrets (#431).
]]

export type Entry = {
	model: number?,
	parts: { [string]: { mesh: string, size: Vector3 } }?,
	colors: { [string]: Color3 }?,
}

"""


def _num(x):
    return repr(round(float(x), 4)).removesuffix(".0")


def collect(manifest, harvest):
    ids = {kind: {} for kind in KINDS}
    for name, entry in manifest.get("models", {}).items():
        kind, key = name.split("/", 1)
        if kind in PENDING_KINDS:
            continue
        if entry.get("asset"):
            ids.setdefault(kind, {}).setdefault(key, {})["model"] = int(entry["asset"])
        if entry.get("colors"):
            ids.setdefault(kind, {}).setdefault(key, {})["colors"] = entry["colors"]
    for kind, keys in harvest.items():
        for key, groups in keys.items():
            ids.setdefault(kind, {}).setdefault(key, {})["parts"] = groups
    return ids


def render(ids):
    lines = [HEADER.rstrip("\n"), "", "local ArtIds: { [string]: { [string]: Entry } } = {"]
    for kind in sorted(ids, key=lambda k: (k not in KINDS, KINDS.index(k) if k in KINDS else 0, k)):
        keys = ids[kind]
        if not keys:
            lines.append(f"\t{kind} = {{}},")
            continue
        lines.append(f"\t{kind} = {{")
        for key in sorted(keys):
            entry = keys[key]
            fields = []
            if "model" in entry:
                fields.append(f"model = {entry['model']}")
            if "parts" in entry:
                parts = ", ".join(
                    f"{g} = {{ mesh = {json.dumps(p['mesh'])}, size = Vector3.new({', '.join(_num(v) for v in p['size'])}) }}"
                    for g, p in sorted(entry["parts"].items())
                )
                fields.append(f"parts = {{ {parts} }}")
            if "colors" in entry:
                colors = ", ".join(
                    f"{g} = Color3.fromRGB({', '.join(str(int(v)) for v in rgb)})" for g, rgb in sorted(entry["colors"].items())
                )
                fields.append(f"colors = {{ {colors} }}")
            lines.append(f"\t\t{key} = {{ {', '.join(fields)} }},")
        lines.append("\t},")
    lines += ["}", "", "return ArtIds", ""]
    return "\n".join(lines)


def build():
    manifest_path, harvest_path = ART / "manifest.json", ART / "harvest.json"
    manifest = json.loads(manifest_path.read_text()) if manifest_path.exists() else {}
    harvest = json.loads(harvest_path.read_text()) if harvest_path.exists() else {}
    return render(collect(manifest, harvest))


def main(argv):
    text = build()
    if "--check" in argv:
        ok = OUT.read_text() == text
        print("ArtIds.luau up to date" if ok else "ArtIds.luau is stale: run tools/art/write_ids.py")
        return 0 if ok else 1
    OUT.write_text(text)
    print(f"wrote {OUT.relative_to(ROOT)}")
    return 0


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))
