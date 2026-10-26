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
    h = hashlib.sha256()
    for f in files:
        h.update(f.name.encode())
        h.update(f.read_bytes())
    return h.hexdigest()[:16]
