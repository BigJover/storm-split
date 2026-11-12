"""Hunter skin variants (PLAN 11e T155, DECISIONS #436): a premium hunter skin is its own body,
template `hunter/<SKIN KEY>` (Shared/HunterBody wears it instead of the class body).

A variant is the approved class body (models/hunter/<HERO>.py, untouched) built again with:
  * `drop`   pieces of the base taken off, as (R15 part, paint group, n) = the n-th `body.add`
             call for that part + group in the base script (0-based). The base scripts are
             approved and frozen (#442), so these indices stay put; a base edit means
             re-checking its variants (their source hash covers the base file, srchash.py).
  * `extra(body, lp)` the variant's own pieces, added with `body.add` in the same Roblox frame
             (_body.py: studs about the HumanoidRootPart, front -Z), inside the #434 envelope
             (hit parts never change; the art only dresses them).
  * `colors` the variant's authored colour per paint group, merged over the base's. A variant
             carries its own colours in game (HunterBody: no shirt / pants recolour).
`Body.finish` then decimates the big smooth pieces evenly so the whole body stays under the
hero budget (6,000, #433).

Variant scripts name their sources on an `# art-sources:` line so srchash.py re-hashes them
when the base or this helper changes (and the approved bases keep their own hash).
"""

import importlib.util
from pathlib import Path

import bpy

HUNTER = Path(__file__).resolve().parents[1]
BATCH = "11e"


def _load(key):
    spec = importlib.util.spec_from_file_location(f"hunter_{key}", HUNTER / f"{key}.py")
    mod = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(mod)
    return mod


def body_module():
    """models/hunter/_body.py (its primitives: rbox, cyl, ell, capsule, cone, SIDES ...)."""
    return _load("_body")


def variant(lp, hero, skin, display, drop=(), extra=None, colors=None, target=5300, keep=200):
    base = _load(hero)
    Body = base.B.Body
    dropped = set(drop)

    class Variant(Body):
        def __init__(self, lp_):
            super().__init__(lp_)
            self.calls = {}

        def add(self, part, group, *objs):
            n = self.calls.get((part, group), 0)
            self.calls[(part, group)] = n + 1
            if (part, group, n) in dropped:
                dropped.discard((part, group, n))
                for o in objs:  # off the scene too (previews render the whole scene)
                    mesh = o.data
                    bpy.data.objects.remove(o)
                    bpy.data.meshes.remove(mesh)
                return
            super().add(part, group, *objs)

        def finish(self, target_=5300, keep_=260):
            if extra:
                extra(self, lp, base.B)
            assert not dropped, f"{skin}: drop indices not found in {hero}: {sorted(dropped)}"
            return super().finish(target, keep)  # variant's own target / keep

    base.B.Body = Variant
    model = base.build(lp)
    model["colors"] = {**model["colors"], **(colors or {})}
    model["batch"] = BATCH
    model["meta"] = {"skin": skin, "hero": hero, "display": display, "base": f"hunter/{hero}"}
    return model
