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
| `lowpoly.py` | bpy helpers: skin skeletons, ellipsoids, cones, decimate-to-target, fit-to-box, smooth + weighted normals, budgets (#433), geometry hash, FBX export |
| `render.py` | 512 px Workbench 3/4 preview (studio light, grey background, ortho camera framed on bounds); contact sheet |
| `build.py` / `build.sh` | headless entry; Blender log in `$ART_LOG` (default `$TMPDIR/dinohunters-art.log`), 300 s timeout |
| `models/<kind>/<key>.py` | one script per model: `build(lp)` returns batch, budget class, Roblox box, pieces, colours per paint group (authored = preview and in-game colour, #439) |
| `manifest.json` | per model: batch, tris, geometry hash, box, pieces (paint group, ArtRole), colors (authored RGB per paint group, carried into `ArtIds`), asset id, uploaded hash; `approved` = batches Jovan approved |
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
The geometry hash is over geometry, not the file bytes (FBX embeds a timestamp). **Caveat (found
2026-10-26):** it is *not* reproducible across Blender processes today — collapse-decimate and some
mesh conversions give slightly different vertices / loop order run to run (even with `-t 1` and a
fixed `PYTHONHASHSEED`), so a rebuild changes the hash although nothing was edited. Don't treat a
hash change on a plain rebuild as a geometry change; restore the committed hash if only colours or
metadata changed.

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
