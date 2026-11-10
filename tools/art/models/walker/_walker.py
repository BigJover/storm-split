"""Shared helpers for the walker models (PLAN 11d2): the tower-summoned units - Raptor Pen
raptors (RaptorLook), Ranger Station rangers + the Patrol Jeep (RangerLook) and the Blimp's
Paratroopers (TowerLook.buildRanger) - and the dino projectiles (kind `projectile`,
DinoLook.buildProjectile). Runs in Blender.

Everything is authored in ROBLOX studs and axes (Y up, the unit faces -Z, its left is -X)
about the look's PrimaryPart centre (the blocky `Body`, or the shot's `Shot`) at the look's
scale-1 size, exactly like the blocky parts in the .luau look. `Walk.finish` joins one piece
per paint group (plus role pieces), multiplies by the kind's scale (RaptorLook.KINDS /
RangerLook.KINDS: the look scales positions and sizes the same way), converts to Blender axes
and returns the art's real bounds as the model `box`, so build.py's fit-to-box is a no-op
(scale 1.00). It fails if the art leaves today's blocky look box (`look`, scaled) by more than
`slack` studs on any side: the art sits where the blocks are.

Primitives come from models/tower/_kit.py (rbox, cyl, rod, bar, ell, ring, ring_along);
srchash.py hashes that file for kinds walker / projectile, and this file for projectile.
"""

import importlib.util
import math
from pathlib import Path

from mathutils import Matrix, Vector

_spec = importlib.util.spec_from_file_location("_tower_kit", Path(__file__).parents[1] / "tower" / "_kit.py")
K = importlib.util.module_from_spec(_spec)
_spec.loader.exec_module(K)

rbox, cyl, rod, bar, ell, ring, ring_along = K.rbox, K.cyl, K.rod, K.bar, K.ell, K.ring, K.ring_along

CAMP = (13, 105, 172)  # preview only: the runtime paints group `camp` the camp's colour (BattleFlow.campColor)
LEATHER = (96, 64, 40)
BRASS = (214, 168, 70)
EYE = (28, 22, 20)


def mix(a, b, t):
    return tuple(round(x + (y - x) * t) for x, y in zip(a, b))


class Walk:
    """Collects primitives per piece; finish() joins, scales, converts and checks."""

    def __init__(self, lp, look, scale=1.0, slack=0.12):
        self.lp, self.look, self.scale, self.slack = lp, look, scale, slack
        self.sets, self.groups, self.roles = {}, {}, {}

    def add(self, group, *objs, piece=None, role=None):
        name = piece or group
        self.sets.setdefault(name, []).extend(objs)
        self.groups[name] = group
        if role:
            self.roles[name] = role

    def skin(self, name, points, edges, radii, target, subdiv=1):
        """A smooth skin-modifier body from a Roblox-axes skeleton, decimated to `target` tris."""
        return self.lp.decimate_to(self.lp.skin(name, [Vector(p) for p in points], edges, radii, subdiv), target)

    def cone(self, base, tip, radius, segments=5):
        self.lp_n = getattr(self, "lp_n", 0) + 1
        return self.lp.cone(f"cone{self.lp_n}", Vector(base), Vector(tip), radius, segments)

    def frame(self, objs, pad):
        """Two loose vertices `pad` x the largest extent outside objs' bounds: build.py renders
        `context` pieces in the preview only, so the 3/4 view doesn't crop a hat or a tail."""
        import bpy

        lo, hi = self.lp.bounds(objs)
        d = max(hi - lo) * pad
        mesh = bpy.data.meshes.new("frame")
        mesh.from_pydata([tuple(lo - d), tuple(hi + d)], [], [])
        obj = bpy.data.objects.new("frame", mesh)
        bpy.context.scene.collection.objects.link(obj)
        return obj

    def finish(self, target, keep=120):
        lp, out = self.lp, []
        m = K.to_blender_matrix() @ Matrix.Scale(self.scale, 4)
        for name, objs in sorted(self.sets.items()):
            piece = lp.join(name, objs)
            piece.data.transform(m)
            piece.data.update()
            lp.triangulate(piece)
            out.append(piece)
        total = sum(lp.tris(o) for o in out)
        if total > target:  # last resort: decimate the big pieces evenly, details stay crisp
            small = sum(lp.tris(o) for o in out if lp.tris(o) <= keep)
            ratio = (target - small) / (total - small)
            for o in out:
                n = lp.tris(o)
                if n > keep:
                    lp.decimate_to(o, max(keep, int(n * ratio)))
            for _ in range(3):  # collapse-decimate overshoots a little: take the rest off the biggest piece
                over = sum(lp.tris(o) for o in out) - target
                if over <= 0:
                    break
                big = max(out, key=lp.tris)
                lp.decimate_to(big, lp.tris(big) - over - 4)
        blo, bhi = lp.bounds(out)
        lo = (float(blo[0]), float(blo[2]), float(-bhi[1]))
        hi = (float(bhi[0]), float(bhi[2]), float(-blo[1]))
        llo = [v * self.scale for v in self.look[0]]
        lhi = [v * self.scale for v in self.look[1]]
        s = self.slack * self.scale
        for i, axis in enumerate("xyz"):
            assert lo[i] >= llo[i] - s and hi[i] <= lhi[i] + s, (
                f"{axis} {lo[i]:.2f}..{hi[i]:.2f} leaves the look box {llo[i]:.2f}..{lhi[i]:.2f}")
        print(f"ART look box {[round(v, 3) for v in llo]} .. {[round(v, 3) for v in lhi]}")
        return out, (lo, hi)

    def model(self, budget, colors, meta, target, batch="11d2", pad=0.1):
        pieces, box = self.finish(target)
        meta = dict(meta)
        meta["lookBox"] = [[round(v * self.scale, 3) for v in self.look[0]],
                           [round(v * self.scale, 3) for v in self.look[1]]]
        meta["scale"] = self.scale
        return {
            "batch": batch,
            "budget": budget,
            "box": box,
            "pieces": pieces,
            "context": [self.frame(pieces, pad)],  # preview only: room round the model (renders nothing)
            "groups": dict(self.groups),
            "roles": dict(self.roles),
            "colors": colors,
            "meta": meta,
        }


# ------------------------------------------------------------------ Raptor Pen raptors

# RaptorLook at scale 1 about the Body's centre: Body 0.9 x 0.8 x 1.8, Head 0.6 x 0.55 x 1 at
# (0, 0.6, -1.3), Tail 1.8 long at z 1.6 tilted 10 deg, legs to y -1.2, claw to ~-1.3.
RAPTOR_LOOK = ((-0.45, -1.3, -1.8), (0.45, 0.875, 2.5))

HIDE = (150, 120, 70)  # RaptorLook HIDE
BELLY = (215, 195, 150)
CLAW = (235, 230, 215)


def raptor(lp, variant):
    """variant: raptor (the pack), alpha (Alpha Raptor, 1.6) or swarm (Raptor Swarm, 0.6).
    A tamed raptor: rounder friendlier head than the enemy BRUTE, duller olive hide, and gear -
    camp-colour collar + saddle blanket + tail band, a leather halter and girth, a brass tag."""
    scale = {"raptor": 1.0, "alpha": 1.6, "swarm": 0.6}[variant]
    w = Walk(lp, RAPTOR_LOOK, scale)
    alpha, swarm = variant == "alpha", variant == "swarm"

    # body skeleton: hip, mid, chest, neck (up to the head), tail (straight, a little raised)
    pts = [(0, 0.02, 0.45), (0, 0.05, -0.1), (0, 0.0, -0.55), (0, 0.22, -0.88), (0, 0.42, -1.08),
           (0, 0.14, 1.2), (0, 0.26, 1.9), (0, 0.36, 2.47)]
    rad = [0.4, 0.4, 0.34, 0.22, 0.17, 0.24, 0.13, 0.035]
    edges = [(0, 1), (1, 2), (2, 3), (3, 4), (0, 5), (5, 6), (6, 7)]
    claws = []
    for s in (-1, 1):
        x = 0.27 * s
        i = len(pts)  # thigh, knee (forward), ankle (back, raised), ball of the foot
        pts += [(x, -0.12, 0.35), (x, -0.56, 0.02), (x, -0.98, 0.38), (x, -1.13, 0.12)]
        rad += [0.26, 0.13, 0.09, 0.085]
        edges += [(0, i), (i, i + 1), (i + 1, i + 2), (i + 2, i + 3)]
        for dx in (-0.06, 0.06):  # two toes on the ground (in the skin), claws forward
            t = len(pts)
            pts.append((x + dx, -1.16, -0.04))
            rad.append(0.045)
            edges.append((i + 3, t))
            claws.append(w.cone((x + dx, -1.17, -0.06), (x + dx, -1.2, -0.17), 0.03, 4))
        claws.append(w.cone((x - 0.08 * s, -1.08, 0.14), (x - 0.08 * s, -1.0, 0.02), 0.04, 4))  # sickle, held up
        if not swarm:
            j = len(pts)  # small folded arms
            pts += [(0.2 * s, -0.12, -0.6), (0.28 * s, -0.32, -0.45), (0.24 * s, -0.4, -0.78)]
            rad += [0.09, 0.065, 0.05]
            edges += [(2, j), (j, j + 1), (j + 1, j + 2)]
            claws.append(w.cone((0.24 * s, -0.42, -0.8), (0.24 * s, -0.52, -0.9), 0.035, 4))
    body = w.skin("body", pts, edges, rad, {"raptor": 430, "alpha": 600, "swarm": 330}[variant])
    # a rounder, shorter-snouted head than the enemy BRUTE (friendly), its back inside the neck
    head = w.skin("head", [(0, 0.5, -1.06), (0, 0.64, -1.32), (0, 0.57, -1.6), (0, 0.52, -1.76),
                           (0, 0.44, -1.25), (0, 0.42, -1.66)],
                  [(0, 1), (1, 2), (2, 3), (0, 4), (4, 5)], [0.17, 0.22, 0.15, 0.085, 0.13, 0.065],
                  100 if swarm else 150)
    w.add("body", body)
    w.add("body", head, piece="head", role="head")
    w.add("belly", ell((0, -0.2, -0.1), (0.3, 0.22, 0.6), 8, 4))
    w.add("eye", *[ell((0.165 * s, 0.7, -1.36), (0.075, 0.075, 0.07), 5, 3) for s in (-1, 1)])
    w.add("claw", *claws)

    # tamed gear: camp collar (+ brass tag), tail band; leather halter over the snout
    w.add("camp", ring_along((0, 0.32, -0.96), (0, 0.62, -1.12), 0.2, 0.05, 10, 3))
    w.add("brass", ell((0, 0.2, -1.12), (0.06, 0.07, 0.03), 5, 3))
    w.add("camp", ring_along((0, 0.24, 1.75), (0, 0.27, 2.0), 0.15, 0.04, 6, 3))
    w.add("leather", ring_along((0, 0.56, -1.5), (0, 0.55, -1.8), 0.17, 0.025, 8, 3))
    if swarm:  # a small pack runner: a camp bandana knot on the collar
        w.add("camp", ell((0, 0.27, -1.18), (0.09, 0.08, 0.06), 5, 3))
    else:
        # saddle blanket (camp) + leather saddle with pommel and cantle, a girth strap round the belly
        w.add("camp", ell((0, 0.3, 0.0), (0.43, 0.17, 0.4), 10, 4))
        w.add("leather", rbox((0, 0.5, 0.0), (0.34, 0.12, 0.46), bevel=0.05, taper=(0.85, 0.9)))
        w.add("leather", rbox((0, 0.6, -0.2), (0.16, 0.14, 0.08), bevel=0))
        w.add("leather", rbox((0, 0.59, 0.21), (0.3, 0.1, 0.07), bevel=0))
        w.add("leather", *[bar((0.3 * s, 0.38, 0.0), (0.38 * s, -0.12, 0.0), 0.07, 0.025, bevel=0, up=(s, 0, 0))
                           for s in (-1, 1)])  # girth straps down the flanks
        # reins from the halter to the pommel
        w.add("leather", *[rod(p, q, 0.018, 4) for s in (-1, 1) for p, q in (((0.17 * s, 0.56, -1.5), (0.12 * s, 0.5, -0.98)),
                                                                             ((0.12 * s, 0.5, -0.98), (0.07 * s, 0.62, -0.22)))])
    if alpha:
        # the pack leader: feather crest, dark back stripes, brass studs on the collar, a camp pennant
        w.add("accent", *[w.cone((0, 0.82 - 0.07 * k, -1.36 + 0.11 * k), (0, 0.97 - 0.08 * k, -1.24 + 0.14 * k), 0.06, 4)
                          for k in range(3)])
        w.add("accent", *[ell((0, y + r * 0.78, z), (r * 0.88, 0.09, 0.1), 8, 3)
                          for z, y, r in ((-0.3, 0.03, 0.4), (0.15, 0.04, 0.4), (0.9, 0.09, 0.3), (1.3, 0.15, 0.22),
                                          (1.65, 0.21, 0.17), (2.0, 0.27, 0.11))])
        w.add("brass", *[ell((0.19 * s, 0.4, -1.0), (0.04, 0.04, 0.04), 5, 3) for s in (-1, 1)])
        w.add("leather", rbox((0.27 * 1, 0.25, 0.18), (0.12, 0.2, 0.26), bevel=0.04))  # saddlebags
        w.add("leather", rbox((-0.27, 0.25, 0.18), (0.12, 0.2, 0.26), bevel=0.04))
        w.add("wood", rod((0, 0.5, 0.3), (0, 0.86, 0.36), 0.015, 5))
        w.add("camp", rbox((0, 0.78, 0.44), (0.02, 0.12, 0.17), bevel=0.0))
    colors = {
        "body": (118, 98, 62) if alpha else mix(HIDE, (190, 165, 110), 0.25) if swarm else HIDE,
        "belly": BELLY, "eye": EYE, "claw": CLAW, "camp": CAMP, "leather": LEATHER, "brass": BRASS,
        "accent": (58, 42, 28), "wood": (122, 88, 56),
    }
    name = {"raptor": "Raptor", "alpha": "Alpha Raptor", "swarm": "Swarm Raptor"}[variant]
    budget = "small" if swarm else "mid"
    target = {"raptor": 900, "alpha": 1350, "swarm": 700}[variant]
    return w.model(budget, colors, {"walker": "raptor", "look": "RaptorLook", "kind": variant, "display": name}, target)


# ------------------------------------------------------------------ Ranger Station rangers

# RangerLook at scale 1 about the Body's centre: Body 0.9 x 1.1 x 0.5, Head 0.55 at y 0.85, Hat
# 0.95 wide at y 1.15 (+ band to 1.3), boots to y -1.5, rifle at (0.4, 0.15, -0.6) 1.3 long
# (heavy: 1.8 long, 0.2 thick), legend's coat to y -0.8.
RANGER_LOOK = ((-0.475, -1.5, -1.25), (0.475, 1.3, 0.475))
HEAVY_LOOK = ((-0.475, -1.5, -1.5), (0.5, 1.3, 0.475))

KHAKI = (176, 160, 110)  # RangerLook KHAKI
DARK_KHAKI = (120, 105, 70)
SKIN = (225, 185, 150)
GUN = (55, 50, 45)
BOOT = (70, 50, 35)
WOOD = (122, 88, 56)


def ranger(lp, kind):
    """kind: ranger, heavy (Heavy Rifle: a long thick barrel, ammo belt, 1.1) or legend
    (Legend Ranger: a long coat, bandolier, feather, 1.35). A small chunky figure in the hunters'
    style - rounded block torso, capsule limbs, big head - holding the rifle at the hip, -Z."""
    scale = {"ranger": 1.0, "heavy": 1.1, "legend": 1.35}[kind]
    heavy, legend = kind == "heavy", kind == "legend"
    w = Walk(lp, HEAVY_LOOK if heavy else RANGER_LOOK, scale)
    # torso, belt, legs, boots
    w.add("shirt", rbox((0, 0.0, 0), (0.78 if heavy else 0.72, 1.04, 0.46), bevel=0.14, segments=1))
    w.add("leather", rbox((0, -0.45, 0), (0.8 if heavy else 0.74, 0.12, 0.5), bevel=0.04))
    w.add("brass", rbox((0, -0.45, -0.255), (0.1, 0.08, 0.02), bevel=0.01))
    for s in (-1, 1):
        w.add("pants", rbox((0.2 * s, -0.9, 0), (0.32, 0.76, 0.36), bevel=0.1))
        w.add("boot", rbox((0.2 * s, -1.38, -0.05), (0.34, 0.24, 0.46), bevel=0.08))
    # arms (sleeves = shirt, hands = skin): right on the grip, left under the fore-end
    for sh, el, ha in (((0.41, 0.34, 0), (0.46, 0.0, 0.06), (0.4, 0.06, -0.2)),
                       ((-0.41, 0.34, 0), (-0.34, 0.02, -0.32), (0.3, 0.14, -0.7))):
        w.add("shirt", ell(sh, (0.14, 0.14, 0.14), 6, 4))
        w.add("shirt", rod(sh, el, 0.12, 6, top=0.85))
        w.add("shirt", rod(el, ha, 0.1, 6, top=0.85))
        w.add("skin", ell(ha, (0.1, 0.1, 0.1), 6, 4))
    # head, eyes, nose, neck
    w.add("skin", ell((0, 0.82, 0), (0.28, 0.27, 0.26), 10, 6), piece="head", role="head")
    w.add("skin", cyl((0, 0.58, 0), 0.12, 0.14, 8, bevel=0))
    w.add("skin", ell((0, 0.78, -0.26), (0.05, 0.05, 0.04), 5, 3))
    w.add("eye", *[ell((0.1 * s, 0.86, -0.235), (0.035, 0.05, 0.02), 5, 3) for s in (-1, 1)])
    # campaign hat: brim, pinched crown, camp band
    w.add("hat", cyl((0, 1.07, 0), 0.47, 0.05, 14, bevel=0))
    w.add("hat", cyl((0, 1.18, 0), 0.25, 0.2, 10, top=0.78, bevel=0))
    w.add("camp", ring((0, 1.12, 0), 0.25, 0.035, 10, 3))
    # scarf (camp): a ring round the neck + the knot at the front
    w.add("camp", ring((0, 0.53, 0), 0.21, 0.06, 8, 3))
    w.add("camp", rbox((0, 0.44, -0.25), (0.16, 0.16, 0.07), bevel=0, rot=(0, 0, 45)))
    # rifle along -Z at x 0.4: stock, receiver, fore-end, barrel, muzzle ring (role muzzle)
    x, y = 0.42, 0.14
    tip = -1.47 if heavy else -1.22
    w.add("wood", rbox((x, y - 0.03, 0.02), (0.08, 0.14, 0.34), bevel=0.03, rot=(-8, 0, 0)))
    w.add("gun", rbox((x, y, -0.3), (0.09, 0.12, 0.32), bevel=0.02))
    if heavy:  # Heavy Rifle: a thick barrel with a cooling jacket, a drum magazine
        w.add("gun", rod((x, y + 0.01, -0.45), (x, y + 0.01, -1.1), 0.085, 8))  # cooling jacket
        w.add("gun", rod((x, y + 0.01, -1.1), (x, y + 0.01, tip + 0.02), 0.045, 6))
        w.add("dark", *[rod((x, y + 0.01, z), (x, y + 0.01, z - 0.04), 0.095, 8) for z in (-0.6, -0.85)])
        w.add("gun", cyl((x, y - 0.14, -0.38), 0.12, 0.1, 10, rot=(0, 0, 90), bevel=0.02))
        w.add("brass", bar((-0.34, 0.42, -0.26), (0.34, -0.32, -0.27), 0.13, 0.04))  # ammo belt
        w.add("pack", rbox((0, 0.05, 0.3), (0.56, 0.6, 0.2), bevel=0.06))  # ammo pack on the back
    else:
        w.add("wood", rbox((x, y - 0.02, -0.65), (0.08, 0.07, 0.42), bevel=0.02))
        w.add("gun", rod((x, y + 0.02, -0.5), (x, y + 0.02, tip + 0.02), 0.03, 6))
    w.add("gun", ring_along((x, y + 0.01 if heavy else y + 0.02, tip), (x, y + 0.01 if heavy else y + 0.02, tip - 1),
                            0.05 if heavy else 0.035, 0.02, 6, 3), piece="muzzle", role="muzzle")
    if kind == "ranger":  # canteen on the left hip
        w.add("gun", cyl((-0.26, -0.5, 0.29), 0.1, 0.2, 8, rot=(90, 0, 0), bevel=0))
    if legend:  # the long coat (split at the back), bandolier, hat feather, sheriff-style star
        w.add("coat", rbox((0, -0.55, 0.02), (0.88, 0.75, 0.5), bevel=0.1, taper=(0.93, 0.92), rot=(0, 0, 0)))
        w.add("coat", *[rbox((0.16 * s, -0.25, -0.24), (0.18, 0.5, 0.04), bevel=0.02, rot=(0, 0, -12 * s)) for s in (-1, 1)])
        w.add("leather", bar((-0.34, 0.45, -0.26), (0.34, -0.32, -0.27), 0.13, 0.04))
        w.add("brass", *[ell((-0.34 + 0.68 * t, 0.45 - 0.77 * t, -0.29), (0.025, 0.05, 0.02), 4, 3)
                         for t in (0.15, 0.3, 0.45, 0.6, 0.75)])
        w.add("brass", ell((-0.22, 0.25, -0.24), (0.07, 0.07, 0.02), 6, 3))
        w.add("camp", w.cone((0.2, 1.15, 0.12), (0.36, 1.32, 0.3), 0.04, 4))
    colors = {"shirt": KHAKI, "pants": DARK_KHAKI, "hat": DARK_KHAKI, "skin": SKIN, "eye": EYE, "camp": CAMP,
              "leather": LEATHER, "boot": BOOT, "gun": GUN, "wood": WOOD, "brass": BRASS,
              "pack": DARK_KHAKI, "dark": (35, 32, 30), "coat": (98, 72, 46)}
    name = {"ranger": "Ranger", "heavy": "Heavy Rifle Ranger", "legend": "Legend Ranger"}[kind]
    return w.model("mid", colors, {"walker": "ranger", "look": "RangerLook", "kind": kind, "display": name},
                   1400 if legend else 1320 if heavy else 1150)


# RaptorLook "rex" (Rex Tamer, scale 1.9) at scale 1: Head 1 x 0.9 x 1.3 at (0, 0.75, -1.3), tiny
# arms at (+-0.35, 0.05, -0.75); body, tail and legs as the raptor's.
REX_LOOK = ((-0.5, -1.3, -1.95), (0.5, 1.2, 2.5))
REX_HIDE = (110, 120, 75)  # RaptorLook REX_HIDE


def rex(lp):
    """Rex Tamer's small tamed T. rex: heavy head and jaw, tiny arms, thick legs and tail; tamed
    with a studded camp collar, a leather bridle round the snout + reins, a saddle on a camp
    blanket and a camp tail band."""
    w = Walk(lp, REX_LOOK, 1.9)
    pts = [(0, 0.1, 0.4), (0, 0.12, -0.1), (0, 0.12, -0.55), (0, 0.36, -0.85), (0, 0.58, -1.0),
           (0, 0.2, 1.2), (0, 0.3, 1.9), (0, 0.36, 2.47)]
    rad = [0.45, 0.46, 0.4, 0.3, 0.26, 0.3, 0.16, 0.04]
    edges = [(0, 1), (1, 2), (2, 3), (3, 4), (0, 5), (5, 6), (6, 7)]
    claws = []
    for s in (-1, 1):
        x = 0.31 * s
        i = len(pts)
        pts += [(x, -0.1, 0.35), (x, -0.56, 0.04), (x, -0.98, 0.36), (x, -1.12, 0.12)]
        rad += [0.32, 0.17, 0.12, 0.11]
        edges += [(0, i), (i, i + 1), (i + 1, i + 2), (i + 2, i + 3)]
        for dx in (-0.08, 0.0, 0.08):
            t = len(pts)
            pts.append((x + dx, -1.16, -0.06))
            rad.append(0.05)
            edges.append((i + 3, t))
            claws.append(w.cone((x + dx, -1.17, -0.08), (x + dx, -1.2, -0.18), 0.035, 4))
        j = len(pts)  # the famous tiny arms
        pts += [(0.27 * s, -0.02, -0.6), (0.35 * s, -0.12, -0.8)]
        rad += [0.07, 0.05]
        edges += [(2, j), (j, j + 1)]
        claws.append(w.cone((0.35 * s, -0.14, -0.83), (0.35 * s, -0.22, -0.9), 0.025, 4))
    w.add("body", w.skin("body", pts, edges, rad, 520))
    head = w.skin("head", [(0, 0.6, -1.08), (0, 0.82, -1.33), (0, 0.74, -1.7), (0, 0.68, -1.88),
                           (0, 0.5, -1.2), (0, 0.46, -1.8)],
                  [(0, 1), (1, 2), (2, 3), (0, 4), (4, 5)], [0.24, 0.31, 0.22, 0.13, 0.2, 0.1], 200)
    w.add("body", head, piece="head", role="head")
    w.add("belly", ell((0, -0.14, -0.1), (0.36, 0.22, 0.6), 8, 4))
    w.add("eye", *[ell((0.27 * s, 0.94, -1.32), (0.07, 0.075, 0.07), 5, 3) for s in (-1, 1)])
    w.add("accent", *[bar((0.17 * s, 1.07, -1.42), (0.22 * s, 1.0, -1.18), 0.1, 0.05, bevel=0) for s in (-1, 1)])  # brows
    teeth = [w.cone((0.13 * s, 0.6, z), (0.13 * s, 0.52, z), 0.025, 3) for s in (-1, 1) for z in (-1.5, -1.65, -1.8)]
    w.add("claw", *(claws + teeth))
    # tamed gear
    w.add("camp", ring_along((0, 0.4, -0.86), (0, 0.66, -1.02), 0.31, 0.06, 12, 3))
    w.add("brass", *[ell(p, (0.045, 0.045, 0.045), 5, 3)  # studs round the collar's front half
                     for p in ((0.35, 0.4, -0.86), (-0.35, 0.4, -0.86), (0.25, 0.28, -1.06), (-0.25, 0.28, -1.06),
                               (0, 0.22, -1.16))])
    w.add("leather", ring_along((0, 0.72, -1.6), (0, 0.7, -1.9), 0.23, 0.035, 10, 3))
    w.add("brass", *[ell((0.24 * s, 0.68, -1.6), (0.035, 0.05, 0.05), 5, 3) for s in (-1, 1)])
    w.add("leather", *[rod(p, q, 0.022, 4) for s in (-1, 1) for p, q in (
        ((0.24 * s, 0.68, -1.6), (0.2 * s, 0.6, -1.0)), ((0.2 * s, 0.6, -1.0), (0.08 * s, 0.72, -0.24)))])
    w.add("camp", ell((0, 0.38, 0.0), (0.5, 0.2, 0.46), 10, 4))
    w.add("leather", rbox((0, 0.62, 0.0), (0.4, 0.14, 0.52), bevel=0.05, taper=(0.85, 0.9)))
    w.add("leather", rbox((0, 0.73, -0.22), (0.18, 0.16, 0.09), bevel=0))
    w.add("leather", rbox((0, 0.72, 0.24), (0.34, 0.12, 0.08), bevel=0))
    w.add("camp", ring_along((0, 0.25, 1.6), (0, 0.29, 2.0), 0.21, 0.045, 8, 3))
    colors = {"body": REX_HIDE, "belly": mix(REX_HIDE, BELLY, 0.65), "eye": EYE, "claw": CLAW, "camp": CAMP,
              "leather": LEATHER, "brass": BRASS, "accent": mix(REX_HIDE, (40, 40, 25), 0.5)}
    return w.model("mid", colors, {"walker": "raptor", "look": "RaptorLook", "kind": "rex", "display": "Tamed Rex"}, 1450)
