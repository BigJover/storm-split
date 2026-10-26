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
- `write_ids.py` skips kind `hunter` (`PENDING_KINDS`) until the T150 runtime reads it.

**Unverified:** the `R15` layout is our reading of the default rig's attachments (Head centre
+1.5, shoulders ±1 / +0.763, hips ±0.5 / −1.0, …); the runtime task checks it against a live
character in Studio and fixes `_body.R15` / `JOINTS` only if a joint differs.

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
