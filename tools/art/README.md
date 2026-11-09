# tools/art — Blender-scripted models (Phase 11, PLAN 11a)

```sh
tools/art/build.sh dino HUSK            # FBX + preview + manifest entry (exit 1 on error / over budget)
tools/art/build.sh --sheet dino 11a     # contact sheet of a batch's previews, for Jovan (#438)
python3 tools/art/upload.py --dry-run   # what would be uploaded; no network
python3 tools/art/upload.py             # upload approved, changed models (needs the key, #437)
python3 tools/art/write_ids.py [--check] # regenerate src/shared/ArtIds.luau
```

| File | Role |
|---|---|
| `lowpoly.py` | bpy helpers: skin skeletons, ellipsoids, cones, decimate-to-target, fit-to-box, smooth + weighted normals, budgets (#433), FBX export |
| `render.py` | 512 px Workbench 3/4 preview (studio light, grey background, ortho camera framed on bounds); contact sheet |
| `build.py` / `build.sh` | headless entry; Blender log in `$ART_LOG` (default `$TMPDIR/dinohunters-art.log`), 300 s timeout |
| `models/<kind>/<key>.py` | one script per model: `build(lp)` returns batch, budget class, Roblox box, pieces, colours per paint group (authored = preview and in-game colour, #439) |
| `manifest.json` | per model: batch, tris, source hash (#440), box, pieces (paint group, ArtRole), colors (authored RGB per paint group, carried into `ArtIds`), asset id, uploaded hash; `approved` = batches Jovan approved |
| `out/` | exported FBX (git-ignored, rebuilt) |
| `previews/` | committed PNGs |

**Conventions.** 1 Blender unit = 1 stud. Scripts give points in Roblox studs through `lp.rbx(x, y, z)`
(Blender x, y, z = Roblox x, −z, y). The origin is the gameplay part's centre (a dino's Root); the build
scales the pieces per axis onto the blocky look's bounds (`box`), so the art sits where today's
hitbox and blocks are. One object per paint group (`body belly accent dark eye glow`) plus role pieces
(`head`: paint group body, ArtRole head — recorded in the manifest, since FBX can't carry attributes).
**Colours are authored per model (#439, dino colour by tier):** `colors` in the model script is the
preview colour and, via `manifest.json` → `write_ids.py` → `ArtIds` `colors`, the in-game colour —
`ArtSlot` paints each piece its group's authored colour, falling back to the look's colours for a
group without one; group `glow` is Neon in game, everything else SmoothPlastic.
The manifest `hash` is a **source hash** (`srchash.py`, #440): the model's script, its kind's
shared `_*.py` helpers and `lowpoly.py`. Blender's collapse-decimate isn't reproducible run to run,
so a geometry hash changed on every plain rebuild; the source hash only changes when the code that
makes the model changes, and `upload.py` re-uploads exactly those (a shared-helper edit marks every
model of that kind, the safe side).

## Hunter hero bodies (kind `hunter`, PLAN 11c T150, #434)

```sh
tools/art/build.sh hunter PISTOL        # FBX + 3 previews (3/4 front, side, 3/4 back) + manifest
tools/art/build.sh --sheet hunter 11c   # contact sheet
```

Keys are the `HunterStats` keys: `PISTOL` Tracker, `RIFLE` Big Game Hunter, `SHOTGUN` Brush Beater,
`MEDIC` Field Medic. Budget class `hero` (≤ 6,000 tris, #433). A model returns `"rig": "r15"` and
`build.py` takes the rig path (`main_rig`):

- **Pieces are named `<R15Part>__<group>`**, e.g. `Head__skin`, `UpperTorso__accent`,
  `LeftLowerLeg__dark`. The part is one of the 15 R15 part names; the group is the paint group.
  Each piece is one MeshPart; the runtime welds every `<Part>__*` piece to that R15 part and
  paints it `colors[group]`. One piece per (part, group) keeps it to ~30–35 MeshParts a body.
  Groups used: `skin hair eye shirt pants gear gear2 accent light dark` plus a few per class
  (`sock`, `pad`, `glove`, `metal`); the class colour from `Server/Hero` `HERO_COLORS` is `accent`
  (Tracker red, Big Game Hunter yellow) or `gear` (Brush Beater orange vest, Field Medic green).
- **No fit-to-box.** `models/hunter/_body.py` authors in Roblox studs about the HumanoidRootPart's
  centre (ground y −3.0) on the default R15 block rig at scale 1 (`R15` part centres/sizes,
  `JOINTS` pivots). The rest pose is exported (arms straight down); previews only swing the arms
  12° out from the shoulders (`preview_pose`). Limbs are capsules, so joints read as ball joints
  when the rig bends.
- **Manifest** (per hunter): `rig`, `parts[<R15Part>]` = `r15` (default centre + size), `box`
  (the art's bounds, Roblox axes) and `groups`; `pieces[<name>]` = part, group, tris. The build
  prints art box vs default size per part. Hit parts never change (#434): the art is visual only.
- `_body.finish` decimates big smooth pieces (> 260 tris) evenly when a body is over 5,300, so
  small details stay crisp.
- **Runtime (T150, `Shared/HunterBody`, #446):** `write_ids.py` writes each hunter's colours to `ArtIds`
  (blank id until upload). With the template loaded, Server/Wardrobe hides the avatar's visuals (R15
  parts, face, accessories; sizes, collision and the Humanoid untouched), clones each `<Part>__<group>`
  piece and welds it to that R15 part with C0 = the part's rest CFrame (from the live Motor6D C0/C1)
  inverted × the piece's authored CFrame; `skin` = the avatar's BodyColors (class tone fallback).
  Hunter skins: template `hunter/<skin key>` if loaded, else `shirt`/`pants` recoloured.
  Stand-in dummies wear the Tracker body welded to their Body. Spec `tools/test/bodies.spec.luau`.
- **Piece info in `ArtIds` (#445):** an uploaded FBX carries no attributes, so `write_ids.py` also
  writes `pieces = { name = { group, role } }` for every dino/tower piece whose name isn't its paint
  group or that has an ArtRole (`head`, `jaw`, `muzzle`, `lamp`); `ArtSlot` reads it.

**Checked in Studio (2026-11-09, #448):** `_body.R15` / `JOINTS` match the classic default R15 block rig
(`CreateHumanoidModelFromDescription`, BodyTypeScale 0, ProportionScale 0, HipHeight 2) after fixing the
Head, lower arm, hand, lower leg, wrist and ankle values (0.01–0.09 studs). Live avatars use Roblox's
upgraded joints (AnimationConstraints, no Motor6Ds); `HunterBody` reads either.

## Towers (kind `tower`, PLAN 11d T152-T154, batch `11d`)

```sh
tools/art/build.sh tower SCOUT_S1      # FBX + 3 previews (3/4, side, `_top` = the game camera's high angle)
tools/art/build.sh --sheet tower 11d   # contact sheet, one row per tower (its 3 stages)
```

One model per TowerLook model-swap stage (`setStage`): `<KEY>` = stage 0 (tiers 0-2), `<KEY>_S1` =
stage 1 (a path at tier 3, the crown), `<KEY>_S2` = stage 2 (tier 5, the glow); higher stages add
gear, stage 2 adds brass. The manifest entry carries `tower` (the TowerLook key) and `stage`.
Budget class `tower` (<= 3,000 tris, #433; `_kit.Kit.finish` aims under 2,700).
- `models/tower/_kit.py`: rounded camp-gear primitives (rbox, cyl, rod, bar, ring, sandbag, pillow,
  crate) **authored in Roblox studs from the tower's base (y 0), front = -Z**, like TowerLook's
  silhouette blocks; `finish` lowers by the Body's half height (art origin = Body centre) and fails
  if anything leaves the 3 x 5 x 3 Body. It returns the art's real bounds as `box`, so fit-to-box
  is a no-op (scale 1.00). Each tower's design is `models/tower/_<tower>.py` `build(lp, stage)`;
  `<KEY>.py` / `<KEY>_S1.py` / `<KEY>_S2.py` are three-line wrappers (the source hash covers every
  `_*.py`, so a helper edit marks every tower).
- Paint groups are per tower (`body` = the TowerLook colour, `wood dark metal brass rope sand
  canvas ...`, `glow` = Neon); all colours authored.
- Anchors: piece `muzzle` (ArtRole `muzzle`, the firing point: its centre) on the towers that shoot
  (Scout, Sniper, Grenadier, Chiller). The crown needs none (TowerLook puts it on `LookTop` = the
  art's top). Every model keeps the back-right corner (x 1.2, z 1.2, the owner flag's pole) low and
  clear; Hospital also keeps the front-right (x 1.25, z -1.25, the Rescue Beacon).
- **T153 / T154 (the other 11 towers):** `COIL FALCON BALLISTA TARPIT` (Round 4) and `RESIN RAPTOR
  TOTEM BLIMP METEOR VENT RANGER` (4x), 3 stages each, all on the 3 x 5 x 3 Body (every tower's
  Body is `BODY_SIZE`). Muzzles on `COIL` (the spark ball's cap), `BALLISTA`, `RESIN` and
  `BLIMP_AIR` (the door gun). `TARPIT` stays under ~0.8 studs (it lies on the track). `TOTEM`'s
  base stays under 0.35 (setCharge's ring). `VENT`'s Fire Mountain cone (setVentCone, 2.2 wide,
  up to y 2.8) still covers the art's middle when on.
- **`BLIMP_AIR`** (+`_S1`/`_S2`, manifest `tower` = `BLIMP_AIR`) is the flying blimp
  (`TowerLook.buildBlimp`), not a Body look: its script widens its own `_kit` instance's bounds
  (x +-9.6, z +-3.5, height 9) and authors with the envelope's centre at y 4.5, so the art origin
  = the `Envelope` PrimaryPart, nose +X. Pieces sit where buildBlimp's Gondola / Gun / Lamp are;
  piece `lamp` (ArtRole `lamp`) is the searchlight, for the beam.
- Not modelled (walkers, built by Server/Towers): raptors (`RaptorLook`), rangers / heavy / legend
  and the Patrol Jeep (`RangerLook`), Paratroopers (`TowerLook.buildRanger`).
- Sheets: `--sheet tower 11d <suffix> <TOWER,...>` makes `sheet_11d_tower_<suffix>.png` with a row
  per listed tower in that order: `a` would be the T152 seven (`sheet_11d_tower.png` is that
  sheet, made before the filter existed; an unfiltered `--sheet tower 11d` now takes all 19 rows: 7 + 4 + 7 + BLIMP_AIR),
  `b` = `COIL,FALCON,BALLISTA,TARPIT`, `c` = `RESIN,RAPTOR,TOTEM,BLIMP,BLIMP_AIR,METEOR,VENT,RANGER`.
- **Runtime (11d, #447):** `TowerLook.build` dresses `KEY`; `setStage` re-dresses as `KEY_S1` (tier 3) /
  `KEY_S2` (tier 5), keeping the highest loaded stage below a missing one; no `KEY` art = blocky at every
  stage. With art the crown is a small gold marker on the art's top and stage 2 never turns art Neon;
  `TowerLook.muzzle` = the `muzzle` piece centre (Towers' firing point, Coil's lightning); `pulseCross`
  pulses the Hospital's `glow` pieces; `buildBlimp` / `setBlimpStage` dress `BLIMP_AIR` (+ stages) and the
  beam leaves from the `lamp` piece. Specs in `tools/test/artslot.spec.luau`.

## Guns and kit (kinds `gun` and `kit`, PLAN 11c T151, batch `11c2`) — models only, runtime not built

```sh
tools/art/build.sh gun RIFLE                      # FBX + 3/4 + side previews + manifest
tools/art/build.sh kit SHOTGUN_GRENADE
tools/art/build.sh --sheet gun,kit 11c2 11c_guns  # previews/sheet_11c_guns.png: 3/4 + side of each, 2 models a row
```

| Key | Display name (Config) | Tris | Notes |
|---|---|---|---|
| `gun/PISTOL` | Tracker — Revolver | 844 | Dual Pistols (`guns` ≥ 2) = a second PISTOL in the left hand, no extra model |
| `gun/PISTOL_SCOPE` | Scope (Marksman T3) | 320 | attachment; shows when `HeroStats.scope` |
| `gun/RIFLE` | Big Game Hunter — Hunting Rifle | 864 | sling on the right, class badge on the butt's left |
| `gun/RIFLE_BELT` | Belt Fed (Heavy T3) | 336 | attachment: drum under the fore-end + brass belt on the left; `beltFed` |
| `gun/SHOTGUN` | Brush Beater — Shotgun | 836 | side saddle of class-orange shells (left) |
| `gun/SHOTGUN_DOUBLE` | Double Barrel (Point Blank T3) | 188 | attachment: second barrel on the left + piece `muzzle2`; `shotsPerTrigger` ≥ 2 |
| `gun/SHOTGUN_DRUM` | Thicket Sweeper (Buckshot T5) | 144 | attachment: drum under the receiver; `fireMode == "auto"` |
| `gun/MEDIC` | Field Medic — Lever-Action Carbine | 972 | no variants (no Medic path changes the gun's look) |
| `kit/<HERO>_MELEE` | Hunting Knife / Stock Swing / Brush Machete / Splint Stick | 244–348 | |
| `kit/<HERO>_GRENADE` | Stink Bomb / Safari Grenade / Cherry Bomb / Dozy Cloud | 328–560 | Cherry Bomb's lit fuse tip is group `glow` (Neon) |

Conventions (the contract for the runtime task):
- **Grip origin.** Guns and melee are authored in Roblox studs about **today's Tool Handle origin**
  (`Server/Hero` `syncTool`: a 0.4×0.5×2 Part held with the default `Tool.Grip`, so its centre sits on
  the RightHand's `RightGripAttachment`). The hand closes round (0, 0, 0); barrel / blade point
  **−Z** (the Handle's LookVector), **+Y** up, +X the gun's right. Weld the art to the Handle at
  identity (or make the art's root the Handle) and the holding stays exactly as today.
- **Muzzle.** Piece `muzzle` (ArtRole `muzzle`) is a ring at the barrel's tip; its centre = the
  firing point (manifest `muzzle`): PISTOL (0, 0.25, −0.85), RIFLE (0, 0.25, −1.73), SHOTGUN
  (0, 0.25, −1.51), MEDIC (0, 0.25, −1.43). **Today there is no Muzzle attachment**: tracers leave
  from `handle.Position` (the grip) ± `DUAL_GUN_OFFSET` sideways, so a `Muzzle` attachment at the
  `muzzle` centre moves the tracer start forward to the real tip (0.85–1.7 studs).
  `SHOTGUN_DOUBLE` adds `muzzle2` (ArtRole `muzzle2`, the left barrel) for alternating, if wanted.
- **Size.** The art is the real size, not fitted to the old box: guns are 0.2–0.5 wide, the
  revolver 1.1 long, the long guns 2.5–2.8 (stock behind the hand to z ≈ +1.0, the old Handle
  reached +1.0 too). Grenades are about today's 0.9 ball (0.65–0.9 across); kit origin = the
  ball's centre, upright.
- **Attachments** (`<GUN>_<VARIANT>`) are authored in the gun's own frame and are purely additive:
  weld at identity on top of the base gun when the stat in manifest `shows` is on. Every gun plus
  any one attachment is ≤ 1,200 tris (`_gun.GUN_CAP`, checked at build); SHOTGUN + both
  attachments (possible at mastery 20's 6/3) = 1,168. Previews draw an attachment on its base gun
  (preview-only `context` pieces in build.py; only the attachment is exported).
- **Paint groups:** `wood steel brass leather dark cloth glass cork body` authored; `accent` =
  the class colour (`HERO_COLORS`: the revolver's grip medallion, the rifle's butt badge, the
  shotgun's shells, the carbine's green cross; the kit's band / label / wrap). Suggested runtime
  rule: a weapon skin or a cosmetic tint recolours `accent` (and maybe `wood`), mastery gold paints
  `steel` + `brass` gold; the rest keeps its authored colour. Kit props: blade pieces are named
  `blade` (group `steel`).
- **Manifest extras** (`meta`): guns `gun`, `grip`, `muzzle`, `dual` (PISTOL); attachments
  `attach` (base key) and `shows` (the stat); kit `hero`, `prop` (`melee` / `grenade`), `display`,
  `grip` or `centre`. Budget classes: guns `gun` (1,200), kit `small` (800; `_prop.CAP` holds 600).
- **Helpers:** `models/gun/_gun.py` (primitives incl. `slab` profiles and `strap`s, `Gun` envelope +
  tri checks); `models/kit/_prop.py` builds on it, so `srchash.py` hashes `gun/_gun.py` for kind
  `kit` too. Kit previews pad the frame a little (`build.pad_frame`) so squat grenades aren't cropped.
- **Not done (runtime task):** `write_ids.py` `KINDS` doesn't list `gun` / `kit` yet; running it
  will add them to `ArtIds` (colours + `pieces` roles) — do it with the runtime commit
  (`write_ids.py --check` reports the difference until then). Nothing is uploaded or approved.

## What is verified vs assumed (2026-10-26)

Verified here: Blender 5.2.3 headless runs these scripts; the FBX is written with +Y up / −Z forward,
baked transforms, triangles, normals and smoothing groups; budgets fail the build; previews render;
`write_ids.py` reproduces the current `ArtIds.luau` byte-for-byte; `upload.py` exits 0 with
"no key yet — previews only", refuses a config folder that isn't mode 700, and never prints the key.

**Assumed, not yet checked against Roblox** (verify on the first approved upload and log in #422):
- Endpoint `POST https://apis.roblox.com/assets/v1/assets`, header `x-api-key`, multipart fields
  `request` (JSON: `assetType: "Model"`, `displayName`, `description`,
  `creationContext.creator.userId`) and `fileContent` (FBX, `Content-Type: model/fbx`).
- The response is an Operation (`operationId` / `path`, `done`); polling
  `GET /assets/v1/operations/{id}` ends with `response.assetId`.
- A changed model becomes a new version via `PATCH /assets/v1/assets/{assetId}` (same multipart),
  keeping its id.
- Roblox reads the FBX at 1 unit = 1 stud with these axes (Studio's 3D Importer lets you pick the
  unit; Open Cloud may not — if the model arrives scaled, fix the export scale in `lowpoly.export_fbx`).
- `InsertService:LoadAsset` returns the uploaded Model with one MeshPart per object, named after it.
- Moderation delay (minutes to hours).
