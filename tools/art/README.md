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

## Guns and kit (kinds `gun` and `kit`, PLAN 11c T151, batch `11c2`)

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
- **Runtime (T151 + T151b, `Shared/GunArt` + `Shared/Viewmodel`, #453):** Server/Hero dresses the gun
  Tool: the art (+ the attachments its stats show) welded to the Handle at identity, the Handle hidden;
  `accent` = the gun paint (class colour / weapon skin / cosmetic, animated sets via Looks.client), max
  mastery = `steel` + `brass` gold; Dual Pistols = a second PISTOL welded to the LeftHand's
  LeftGripAttachment. `Muzzle` / `Muzzle2` Attachments on the Handle; tracers leave from them (the
  double barrel alternates, the left gun from its own `muzzle`); no art = today's origin. Server/Kit
  throws `<HERO>_GRENADE` (tumbling) instead of the ball; Hero.client swings `<HERO>_MELEE` (Stock Swing
  swings the rifle art, butt first; `RIFLE_MELEE` without it). First person: `Viewmodel` = copies of the
  Tool's gun pieces + the worn body's arm pieces on the camera (left arm on two-handed guns / Dual
  Pistols), sway + recoil kick; the third-person gun hidden locally. Spec `tools/test/gunart.spec.luau`.

## Pets, eggs, incubator (kinds `pet` and `egg`, PLAN 11f T156, batch `11f`) — runtime: `Shared/PetLook` (#451)

```sh
tools/art/build.sh pet HONKER                 # FBX + 3/4 (Common), side, _rare, _legendary, _mythic previews
tools/art/build.sh egg INCUBATOR              # FBX + 3/4 + side (an egg in the nest, preview only)
tools/art/build.sh --sheet pet,egg 11f 11f_pets   # previews/sheet_11f_pets.png: a rarity row per pet, then 2 eggs a row
```

| Key | Name (Config) | Tris | Notes |
|---|---|---|---|
| `pet/HONKER` | Honker (baby Parasaurolophus) | 786 | glow = the tube crest + 3 back spots |
| `pet/FETCHER` | Fetcher (tiny Dimorphodon) | 786 | flies (`flies` meta): wings span ±1.7; glow = tail vane + a spot on each wing |
| `pet/FERN_MUNCHER` | Fern Muncher (baby longneck) | 786 | fern sprig in its mouth (group `leaf`); glow = back + neck spots |
| `pet/SHINY_SNATCHER` | Shiny Snatcher (baby Oviraptor) | 786 | hugs a coin (group `gold`, fixed); glow = casque + tail fan |
| `pet/FRILL_GUARD` | Frill Guard (baby Protoceratops) | 776 | frill (group `frill`); glow = the frill's rim spots + nose bump |
| `egg/MUD` | Mud Egg | 390 | `shell`, `mud`, `grass` |
| `egg/SPECKLED` | Speckled Egg | 390 | `shell`, `spot` |
| `egg/GOLDEN` | Golden Egg | 396 | `shell`, `band`, `glow` (3 amber gems, Neon) |
| `egg/INCUBATOR` | the Hatchery Hut's egg warmer | 1,098 | `wood dark straw metal shade brass glow` (bulb); budget `mid` |

Conventions (the contract for the runtime task):
- **One model per species, rarity at runtime.** Every pet has paint groups `body belly eye shine
  leaf accent glow` (+ `wing` / `gold` / `frill` per species). Suggested rule (what the previews show):
  `accent` (the bandana) = the rarity colour (`Server/Pets` `RARITY_COLOURS`) at every rarity, so it
  replaces today's Collar; `glow` (the species' markings) = its authored colour (a darker body tone,
  SmoothPlastic) at Common / Uncommon, the rarity colour SmoothPlastic at Rare / Epic, the rarity
  colour **Neon** at Legendary / Mythic (Mythic could add a small sparkle ParticleEmitter). The leaf
  tag (`leaf`, Round 21) stays green. Every other group keeps its authored colour.
  Previews `_rare` / `_legendary` / `_mythic` are preview-only recolours (`variants` in the model
  dict, rendered by build.py; Neon is shown as the colour lifted 15 % toward white).
- **Pivot = the ground.** Pets are authored about the ground under the pet's middle (feet at y 0,
  front −Z), eggs about their base (resting point), the incubator about the ground under its tub.
  Today's blocky pet pivots on its Body's centre (`FOLLOW` y −1.6 below the HumanoidRootPart, so it
  floats ~0.7 studs); with art, follow at the HRP's ground (y −3 for the default rig, i.e. FOLLOW
  y −3.0) so the feet touch the floor; the Fetcher keeps its +3.5 hover on top. Pet sizes match
  today's looks (Honker 1.1 × 2.1 × 2.4, Fetcher 3.4 × 1.5 × 2.6 with wings, Fern Muncher 1.1 ×
  2.3 × 3.0, Shiny Snatcher 1.0 × 2.1 × 1.9, Frill Guard 1.3 × 1.8 × 2.6; manifest `box`). Art is
  visual only: no collisions, no queries (pets can't be targeted), no shadows, like today.
- **Eggs** are 1.0 × 1.4 (`_egg.EGG_W/EGG_H`). Nothing draws eggs today (the Hatchery Hut panel is
  2D); the runtime can show the warming egg in an incubator: egg origin at the incubator's
  `eggSeat` (manifest meta, (0, 0.88, 0) above its origin) sinks it into the straw. Light the
  incubator's `glow` bulb only while an egg is warming.
- **Incubator** = one per warming slot (1, or 2 with the "Second Hatchery Hut" pass), 2.3 wide,
  3.35 tall, placed inside / beside the Hatchery Hut block (`Server/Outpost`, 10 × 7 × 8).
- Helpers: `models/pet/_pet.py` and `models/egg/_egg.py` (both author in Roblox axes and return the
  art's real bounds as `box`, so fit-to-box is a no-op; both check their own caps: pets 800, eggs
  400, incubator 1,500). Egg patterns use a fixed R2 layout (no RNG). Manifest meta: pets `pet`,
  `display`, `species`, `origin`, `views`, `rarityGroups` (+ `flies`); eggs `egg`, `display`,
  `origin`, `cap`; the incubator `eggSeat`, `lamp`, `front`.
- **Runtime (#451, `Shared/PetLook`, spec `tools/test/petart.spec.luau`):** the rule above as written
  (accent = rarity colour; glow authored / rarity / rarity + Neon; Mythic sparkle, Rate 4); the
  invisible Body is the pivot on the ground; follow height = the hunter's HipHeight + half the root
  (3 on the default rig); pen pets stand on the HatchlingPen part's top; blocky = today exactly.
  Incubators: client-only, the local player's own slots beside the hut door (`INCUBATOR_SPOTS`
  (∓4.4, 0, −8) from the hut's floor spot), egg at `EGG_SEAT`, bulb Neon only while warming.

## Outpost props (kind `prop`, PLAN 11f T156, batch `11f`) — runtime: `Shared/PropArt` (#455)

```sh
tools/art/build.sh prop HATCHERY_HUT              # FBX + 3/4 + side previews + manifest
tools/art/build.sh --sheet prop 11f 11f_props     # previews/sheet_11f_props.png: 3/4 + side of each, 2 a row
```

Every blocky Hunters' Outpost build (Server/Outpost, Shared/Decor) as a model; nothing in `src/`
changed. Helper `models/prop/_camp.py` (the tower `_kit` primitives, copied so a tower edit doesn't
re-hash every prop, + `plank_floor`, `flame`, `face`, `Camp.model(batch, colors, cap, footprint)`:
fails over its tri cap or outside its footprint; preview-only ground + framing as `context`).

**Origin = the prop's ANCHOR on the ground (y 0), not a part centre**: the CFrame the blocky code builds
from. Place the model so its origin sits on the anchor (fit-to-box is a no-op, scale 1.00).

| Key | Replaces (anchor) | Tris | Notes |
|---|---|---|---|
| `STATION_REACH` | Raptor Dummy: Post, Body, Head, Padding (`buildStation` `base`) | 2,212 | raptor faces +Z as the blocks |
| `STATION_SPEED` | Raptor Chase: Lane 4×14, Raptor, Key (`base`) | 2,292 | wind-up raptor at z 6.5, key +X |
| `STATION_HEALTH` | Herb Kitchen: Table, Legs, Pot, Ferns (`base`) | 2,428 | table top y 3.25 at z −4; drying rack behind (−Z) |
| `STATION_THROW` | Coconut Toss: Line, Coconut (`base`) | 1,244 | the throwing end only |
| `THROW_TARGET` | Coconut Toss: each Target (`base` × (−3,0,−10) / (0,0,−16) / (3,0,−22)) | 1,184 | one model placed 3×; board centre y 2, faces +Z, painted both sides |
| `CAMPFIRE` | CampFire Neon ball (`CENTRE + (0,0,12)`) | 1,556 | hang the PointLight + Outpost sign on piece `glow` |
| `FENCE_POST` | FencePost ×48 (post foot) | 328 | |
| `FENCE_RAIL` | Rail ×48 (span middle, y 0; span along the Rail's X) | 288 | 15.25 long, rails at y 3.5 + 1.8; the invisible Fence walls stay |
| `HATCHERY_HUT` | HatcheryHut + HutRoof (`CENTRE + HATCHERY_HUT`) | 2,224 | door −Z (toward the camp centre) |
| `SHOP_STALL` | ShopCounter (`CENTRE + SHOP`) | 2,264 | counter 8×3×2.5 as today, awning, customers at −Z |
| `HATCHLING_PEN` | HatchlingPen + 4 PenPosts (`facing * (−6, 0, 5)`, Campsite frame) | 1,344 | floor top y 0.3 (pets stand at x −2.2/0/2.2), gate −Z |
| `DECOR_FIRE_PIT` … `DECOR_DINO_STATUE` | the 7 `Shared/Decor` models (the decoration spot `at`) | 504–944 | inside `Decor.SIZE` each, ≤ 1,200 |
| `CAMPSITE_TENT` | *optional, new* (proposed Campsite frame (−6, 0, −5)) | 948 | |
| `CAMPSITE_MARKER` | *optional, new* signpost for the Campsite name (proposed (0, 0, −10)) | 388 | |
| `HUNT_BOARD` | *optional, new* camp notice board (proposed `CENTRE + (0,0,−2)`, facing +Z) | 580 | |
| `DISPLAY_PEDESTAL` | *optional, new* deck under a Display Tower (DECO_SPOT) | 528 | the tower would sit 0.3 higher |

Runtime contract (for the runtime task, after Jovan approves):
- **Interaction stays where it is.** There are no ProximityPrompts in the Outpost today: stations, the
  Hatchery Hut and the shop are distance checks on `Shared/Outpost` centres (`STATION_RADIUS`,
  `HUT_RADIUS`, `SHOP_RADIUS`); the art keeps those centres and changes none of them. Keep the
  station sand **Pad** (attribute `Station`, the sign's adornee), the Campsite **Ground**, the
  **HatchlingPen** part (pets + owner sign anchor), **HatcheryHut** and **ShopCounter** as today's parts
  (Transparency 1 where the art replaces them) so collision, attributes and BillboardGuis are unchanged;
  the art is visual (CanCollide/CanQuery/CanTouch false), like towers.
- **Sign faces** = pieces named `face` (group `face`, thin boxes): put the SurfaceGui on the piece,
  Face = **Front** (−Z of the piece = the prop's front): `DECOR_WANTED_POSTER` (Front **and** Back:
  Decor's poster text, CanvasSize 230×220, centre (0, 2.3, 0)), `HATCHERY_HUT` (4×1 over the door),
  `SHOP_STALL` (5×1.1 on the awning), and the optional `CAMPSITE_MARKER`, `HUNT_BOARD`, `DISPLAY_PEDESTAL`.
  Manifest `faces` lists them.
- **Decoration colours:** on the `DECOR_*` models group `body` = the Skins look colour and `accent` =
  its accent, in the look's material (what `Decor.build` does with c / a); `cloth` (Hunter's Flag) =
  the worn Tower flag colour, else the accent; the rest keeps its authored colour. The Fire Pit's flames
  are `accent` (as Decor's Flame) round a small `glow` core.
- Group `glow` = Neon (fires, lit windows, lanterns); everything else SmoothPlastic, authored colours.
- Manifest `meta`: `prop` (`station` / `decor` / `camp`), `station` / `decor` key, `replaces`, `cap`,
  `origin`, `faces`, `optional`. Budget classes `big` (2,500), `mid` (decorations, capped 1,200 by
  `_camp`), `small`.
- **Runtime (#455, `Shared/PropArt`, spec `tools/test/propart.spec.luau`):** `Server/Outpost` registers
  every prop (key, anchor, replaced blocks) and dresses them at boot, again when art arrives or `ArtOff`
  flips; replaced blocks keep everything and only go Transparency 1 (old value in `ArtHidden`,
  restored exactly by `undress`). Anchors: stations = `base`; targets `base * ((i−2)·3, 0, z)`; fence
  posts `lookAt(edge, centre)` at y 0, rails `lookAt(mid, centre)` at y 0; camp fire `CENTRE + (0,
  FLOOR_TOP, 12)` (its PointLight + sign stay on the hidden ball); hut / shop on their floor spots;
  pen + tent + signpost on the Campsite ground's top (`FLOOR_TOP + 0.2`) at (−6, 5) / (−6, −5) /
  (0, −10); Hunt Board `CENTRE + (0, FLOOR_TOP, −2)` turned to face +Z; decorations at Decor's `at`
  (`Decor.dressArt`); the pedestal under each Display Tower (`Wardrobe`, tower lifted 0.3, plaque =
  the tower's name). Signs on `face`: Hatchery Hut, Shop, Campsite *n*, Hunt Board ("press G"), the
  tower name, and the Wanted Poster's own two SurfaceGuis (moved off the hidden Board). Optional props
  are art-only and walk-through (no new collision).

## Walkers and dino projectiles (kinds `walker` and `projectile`, PLAN 11d2)

```sh
tools/art/build.sh walker RAPTOR                              # FBX + 3/4 + side previews + manifest
tools/art/build.sh projectile ROLL
tools/art/build.sh --sheet walker,projectile 11d2 11d2_walkers  # previews/sheet_11d2_walkers.png
```

| Key | Today's look | Tris | Notes |
|---|---|---|---|
| `walker/RAPTOR` | `RaptorLook.build("raptor")` | 895 | the pack raptor |
| `walker/RAPTOR_ALPHA` | `"alpha"` (×1.6) | 1,345 | darker hide, dark scutes, feather crest, studded collar, saddlebags, camp pennant |
| `walker/RAPTOR_REX` | `"rex"` (×1.9) | 1,400 | Rex Tamer's tamed T. rex: bridle round the snout, studded collar, saddle |
| `walker/RAPTOR_SWARM` | `"swarm"` (×0.6) | 700 | juvenile, lighter; collar + bandana knot, no saddle |
| `walker/RANGER` / `_HEAVY` / `_LEGEND` | `RangerLook.build(kind)` (×1 / 1.1 / 1.35) | 1,144 / 1,318 / 1,394 | heavy: jacketed barrel, ammo belt + pack; legend: long coat, bandolier, feather, star |
| `walker/PATROL_JEEP` | `RangerLook.buildJeep` | 2,200 | |
| `walker/PARATROOPER` | `TowerLook.buildRanger` | 1,246 | |
| `walker/PARATROOPER_CHUTE` | — (no drop today) | 492 | additive canopy in the trooper's frame |
| `projectile/LOB SPIKE GRAVEL DROP ROLL CAPSULE` | `DinoLook.buildProjectile` by `PROJECTILE_STYLE` | 112–300 | |

Conventions (the contract for the runtime task):
- **Origin = the look's PrimaryPart centre** (`Body` for walkers, `Shot` for projectiles), front −Z,
  at the look's own scale: RaptorLook / RangerLook multiply positions and sizes by `KINDS[kind]`, and so
  does the art (`meta.scale`), so each variant is its own model at its final size — weld at identity to
  the Body (or make the art the PrimaryPart) and `Walkers.place`'s `PivotTo` works unchanged.
  `models/walker/_walker.py` `Walk.finish` fails a build that leaves today's blocky box (`meta.lookBox`,
  + 0.12 × scale slack), and returns the real bounds as `box` (fit-to-box scale 1.00).
- **Walkers are ghosts** like today: Anchored, CanCollide / CanTouch / CanQuery false, CastShadow false
  (24 a side).
- **Paint group `camp`** = the camp colour (`campColour(tower)` = `BattleFlow.campColor(side)`): the
  raptors' collar / saddle blanket / tail band / pennant, the rangers' hat band + scarf (+ legend
  feather), the jeep's hood stripe / waist band / jerrycan, the paratrooper's scarf and the canopy's
  alternate gores. The authored `camp` colour (blue) is preview only; the runtime must paint `camp`
  with the camp colour. Every other group keeps its authored colour (RaptorLook HIDE / REX_HIDE,
  RangerLook KHAKI / DARK_KHAKI, TowerLook SAND / LEAF ...).
- **Roles:** `head` (ArtRole head) on every raptor and figure (raptor: the head piece, group body;
  figures: group skin) for a hit flash; `muzzle` (ArtRole muzzle; its centre = the barrel tip) on the
  three rangers and the paratrooper — today's ranger / para shots have no muzzle, so this is new.
  The jeep's searchlight is piece `spotlight` (group lamp, no role).
- **Projectiles** are authored at `buildProjectile`'s `s = 1` minimum size (LOB 0.8 ball, SPIKE
  0.3 × 0.3 × 1.4, GRAVEL Shot 0.75 + pebbles at today's offsets, DROP 1.2, ROLL 2.5, CAPSULE 1.6 × 0.64
  along Z): the runtime scales the art to the live `Shot` size (`model:ScaleTo(shot.Size.Y / authored)`;
  `Height` attribute unchanged). SPIKE and CAPSULE lie along Z like today's pivot (spike point −Z).
  `_shot.CAP` = 300 tris each.
- `srchash.py` hashes `tower/_kit.py` (the primitives) for both kinds and `walker/_*.py` for
  `projectile`. Manifest `meta`: `walker`, `look`, `kind`, `display`, `lookBox`, `scale` (projectiles:
  `projectile` = the style). Previews pad the frame (preview-only `context`) so hats and tails aren't cropped.
- **Runtime (built, #454):** `Shared/WalkerArt` dresses RaptorLook / RangerLook / the jeep /
  `TowerLook.buildRanger` (Body hidden, kept as PrimaryPart; `camp` = the camp colour via
  `ArtSlot` option `override`; pivot (scale − 1) × 1.2 below the Body); ranger / paratrooper
  tracers leave from `muzzle`; `PARATROOPER_CHUTE` rides a 1.5 s visual drop (Server/Walkers);
  rangers sit on the jeep art's seat tops (`WalkerArt.seat`). Projectiles: `DinoLook.dressShot`
  scales the art by `shot.Size.Y / SHOT_ART_HEIGHT[style]`. Spec `tools/test/walkerart.spec.luau`.

## Skin variants (kinds `hunter`, `gun`, `tower`, PLAN 11e T155, batch `11e`, #456)

```sh
tools/art/build.sh hunter GOLD_RUSH_SAFARI         # a hunter skin variant (3 previews, like the class bodies)
tools/art/build.sh gun SHOTGUN_CROC_HIDE           # a weapon skin variant (3/4 + side)
tools/art/build.sh tower SET_MIDNIGHT              # a tower-set trim (3/4, side, _top), shown on one tower in the set
tools/art/build.sh --pngs <name> <columns> <png,...>   # an explicit sheet layout -> previews/sheet_<name>.png
```

Premium skins get a mesh variant; level-ladder and 300K non-bundle skins stay recolours (#456).
Sheets (base vs variant side by side): `sheet_11e_hunter_skins.png` (base 3/4 | variant 3/4, side,
back), `sheet_11e_gun_skins.png` (base 3/4 | variant 3/4 | base side | variant side),
`sheet_11e_tower_skins.png` (base tower `_top` | the set on it: top, 3/4, side).

| Skin (Skins key) | Kind / runtime key | Tris | What changes |
|---|---|---|---|
| Night Prowler | `hunter/NIGHT_PROWLER` (Tracker) | 5,764 | hood + drape, mask, monocular, cloak, throwing knives |
| Jungle Ghost | `hunter/JUNGLE_GHOST` (Tracker) | 5,766 | leaf ghillie hood, shoulder leaves, vine, face paint |
| Gold Rush Safari | `hunter/GOLD_RUSH_SAFARI` (Big Game Hunter) | 5,666 | gold helmet + plume, fringed epaulettes, medals, sash, cuffs |
| Croc Hide Crusher | `hunter/CROC_HIDE_CRUSHER` (Brush Beater) | 5,936 | croc-skull cap + teeth, scutes, shoulder spikes, tooth necklace |
| Mountain Rescue | `hunter/MOUNTAIN_RESCUE` (Field Medic) | 5,572 | helmet + headlamp, rope coil, bedroll, reflective bands |
| Lifeline | `hunter/LIFELINE` (Field Medic) | 5,802 | headset + mic, glasses, shoulder guard, heartbeat line, antenna |
| Silver Spur | `gun/PISTOL_SILVER_SPUR` | 816 | nickel frame, pearl grips, spur rowels, engraved bands |
| Engraved Gold | `gun/RIFLE_ENGRAVED_GOLD` | 820 | gold side plates, inlays, knob, second band; no sling |
| Bamboo Boomstick | `gun/SHOTGUN_BAMBOO_BOOMSTICK` | 832 | lashed bamboo stock + pump, twine |
| Croc Hide | `gun/SHOTGUN_CROC_HIDE` | 856 | croc hide on stock + pump, scutes, tooth charm; no side saddle |
| Brass Saddle | `gun/MEDIC_BRASS_SADDLE` | 1,196 | brass plate + bands, double saddle ring, laced cheek piece + tacks |
| Lifesaver | `gun/MEDIC_LIFESAVER` | 1,160 | orange / white wraps, white cross, life-ring charm |
| Treehouse / Stone Age / Brass Gear / Midnight / Gold Rush | `tower/SET_<KEY>` (any tower) | 264–296 | footprint edge + left-corner pieces (see the scripts) |

Recolour only: Swamp Stalker, Safari Classic, Safari Chief, Bamboo Basher, Swamp Smasher, Frontier Doc
(hunter: `shirt` = colour, `pants` = accent on the class body); Snakeskin Grip, Walnut Classic (gun:
`accent` = the skin's colour).

Conventions (how the runtime maps them):
- **Hunter** (`models/hunter/variants/_skins.py`): the approved class body (`<HERO>.py`, untouched) is
  built again with `drop` = (R15 part, group, n-th `body.add` call) taken off, `extra` pieces added
  and `colors` merged; same `<R15Part>__<group>` pieces, same envelope (#434), so `HunterBody` wears
  `hunter/<SKIN KEY>` exactly like a class body, in its authored colours (no shirt / pants recolour;
  `skin` still = the avatar's skin). Manifest meta: `skin`, `hero`, `display`, `base`.
- **Gun** (`models/gun/variants/_skins.py`): the approved gun's `gun(g)` (untouched) with `drop` /
  `move` (to another group) / `extra` primitives; grip (0, 0, 0) and the `muzzle` piece unchanged.
  Cap = 1,200 − every attachment of that gun (they can all show): PISTOL 880, RIFLE 864, SHOTGUN
  868, MEDIC 1,200. `accent` = the pieces that take the skin's colour + material (GunArt.paint);
  `steel` / `brass` still go gold at max mastery. Runtime: `GunArt.gunKey(hero, Paint.skin)` wears
  `gun/<HERO>_<SKIN KEY>` when loaded (both hands for Dual Pistols), attachments on top; no base gun
  art = the blocky Handle.
- **Tower sets** (`models/tower/variants/_sets.py`): one trim per set, `tower/SET_<SKIN KEY>`, in the
  Body frame (origin = the Body's centre, like every tower), checked at build: <= 300 tris, a rim
  <= 0.3 high round the footprint, raised pieces only on the left corners (x < −0.3) <= 1.1 high, the
  flag corner (1.2, 1.2) and the Rescue Beacon (1.25, −1.25) clear. Manifest `tower` = `SET_<KEY>`,
  meta `set`, `trim`, `preview` (the tower drawn under it, preview only). Runtime:
  `TowerLook.applySkin(model, look, setKey)` dresses it over the art after the set's paint (authored
  colours, attribute `SetTrim`), again after each stage re-dress; never on the blocky look or Tar
  Pit; the crown ignores it.
- `srchash.py`: a variant script's `# art-sources:` line adds its base / helper files to its hash
  (the helpers live in `variants/`, outside the kind's `_*.py` glob, so approved models keep their
  hash).

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
