"""Weapon skin variants (PLAN 11e T155): a premium weapon skin is its own gun model,
`gun/<HERO>_<SKIN KEY>` (Shared/GunArt wears it in place of `gun/<HERO>` when it's loaded; the
hero's attachments still go on top, unchanged).

A variant is the approved gun (models/gun/_<hero>.py `gun(g)`, untouched) built again with:
  * `drop`  base primitives taken off, as (piece, n) = the n-th object added to that piece in
            the base's `gun(g)` (0-based; the bases are approved and frozen, #449);
  * `move`  base primitives moved to another paint group, as (piece, n, new group);
  * `extra(g, G, D)` the variant's own primitives (G = _gun.py helpers, D = the base module),
            in the same frame: grip at (0, 0, 0), barrel -Z. The `muzzle` piece is never
            touched, so tracers leave from the same point;
  * `colors` merged over the base's. `accent` stays the group the runtime paints with the
            skin's colour + material (GunArt.paint), so each variant puts the skin's main colour
            on its `accent` pieces; `steel` / `brass` still turn gold at max mastery.
Cap: the variant plus EVERY attachment of its gun (they can show together) stays within the
1,200 gun budget (#433), read from the manifest's attachment entries.
"""

import importlib.util
import json
from pathlib import Path

import bpy

GUN = Path(__file__).resolve().parents[1]
MANIFEST = GUN.parents[1] / "manifest.json"  # tools/art/manifest.json
BATCH = "11e"


def _load(name):
    spec = importlib.util.spec_from_file_location(name, GUN / f"{name}.py")
    mod = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(mod)
    return mod


def attachment_tris(hero):
    models = json.loads(MANIFEST.read_text())["models"]
    return sum(m["tris"] for m in models.values() if m.get("attach") == hero)


def variant(lp, hero, skin, display, drop=(), move=(), extra=None, colors=None):
    D = _load(f"_{hero.lower()}")
    G = D.G
    attach = attachment_tris(hero)
    g = G.Gun(lp, D.ENVELOPE, G.GUN_CAP - attach)
    D.gun(g)
    taken = {}
    for piece, n, group in move:
        obj = g.sets[piece][n]
        taken.setdefault(piece, set()).add(n)
        g.add(group, obj)
    for piece, n in drop:
        obj = g.sets[piece][n]
        taken.setdefault(piece, set()).add(n)
        mesh = obj.data
        bpy.data.objects.remove(obj)
        bpy.data.meshes.remove(mesh)
    for piece, ns in taken.items():
        g.sets[piece] = [o for i, o in enumerate(g.sets[piece]) if i not in ns]
        if not g.sets[piece]:
            del g.sets[piece]
            g.groups.pop(piece, None)
    if extra:
        extra(g, G, D)
    print(f"ART variant cap {G.GUN_CAP - attach} (attachments {attach})")
    meta = {"gun": hero, "skin": skin, "display": display, "base": f"gun/{hero}",
            "grip": [0, 0, 0], "muzzle": [0, D.BORE, D.TIP - 0.01]}
    return g.model(BATCH, "gun", {**D.COLORS, **(colors or {})}, meta)
