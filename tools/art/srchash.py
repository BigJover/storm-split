"""The change hash for one model (#440): a hash of the scripts that build it - the model's own
file, its kind's shared helpers (models/<kind>/_*.py) and lowpoly.py. Blender's mesh
simplification isn't repeatable run to run, so a geometry hash changed on every plain rebuild;
this one only changes when the code that makes the model changes. upload.py compares it."""

import hashlib
from pathlib import Path

ART = Path(__file__).resolve().parent


def source_hash(kind, key):
    files = [ART / "models" / kind / f"{key}.py", ART / "lowpoly.py"]
    files += sorted((ART / "models" / kind).glob("_*.py"))
    if kind == "kit":  # kit props are built with the gun helpers (models/gun/_gun.py)
        files += sorted((ART / "models" / "gun").glob("_gun.py"))
    if kind in ("walker", "projectile"):  # walkers / dino shots: models/walker/_walker.py on tower/_kit.py
        files += [ART / "models" / "tower" / "_kit.py"]
        if kind == "projectile":
            files += sorted((ART / "models" / "walker").glob("_*.py"))
    # Skin variants (11e): a variant script names the other files it builds from on a line
    # `# art-sources: PISTOL.py variants/_skins.py` (paths under models/<kind>/), so editing
    # a variant helper re-hashes only the variants; approved base models have no such line.
    text = files[0].read_text()
    for line in text.splitlines():
        if line.startswith("# art-sources:"):
            files += [ART / "models" / kind / p for p in line.split(":", 1)[1].split()]
    h = hashlib.sha256()
    for f in files:
        h.update(f.name.encode())
        h.update(f.read_bytes())
    return h.hexdigest()[:16]
