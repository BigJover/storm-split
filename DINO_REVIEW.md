# Dino review — Step 2 plan + name sweep (Dino agent, 2026-09-30)

Scope: `PLAN.md` T5–T17, `DECISIONS.md` #2–#16, current names in `Config.luau`, player-facing
strings in `src/client` / `src/server`, `DinoLook` and `TowerLook`. Jovan approved the current
names, so this only flags clear misfits. Names are looked up by (tower/hero, path, tier), never by
name alone.

**Verdict:** the plan is on theme. Hunters, gear and dinos read clearly, and the attack names are
good. There are eight must-fix items. Two of them are real confusions that Step 2 itself creates:
"knocked out" now means two different things, and "Lives" now sits next to player health. The rest
are leftovers from the old storm/cold/Fortnite theme and three name collisions in the new trees.

---

## MUST-FIX

| # | What | Why | Replace with | Where |
|---|---|---|---|---|
| M1 | Tower knock-out wording: label **"KO"**, header **"Knocked out"** (DECISIONS #9, T9/T10) | It clashes with the Tranq Station's **Knockout** path and **Knockout Dart**, which knock out *dinos*. A player reading "Knockout" can't tell whether it's good or bad. | **"Trampled"**: label `TRAMPLED`, header "Trampled — repair it", refusal "Repair it first" (keep). The internal `knockedOut` flag and `KO` attribute stay as they are. | `TowerLook.setKnockedOut` label, `Shop.client` header, DECISIONS #9 text |
| M2 | HUD **"Lives {n}"** | Players now have 100 HP and respawn, and dying costs no lives. "Lives" will be read as *your* lives. | **"Fence {n}"**: dinos that reach the exit break through the camp fence. The Tuning label can stay. | `Hud.client.luau` lines 123, 125 |
| M3 | The Tranq Station still talks and looks like the old cold theme | The panel text says "freezes Xs every Ys", "freezes deal X damage", "freezes bosses", "chilled take +X% damage" and "chill strips armour". Tranq'd dinos also turn to **Ice** material. | Use sleep words: "knocks out Xs every Ys", "darts deal X damage", "knocks out bosses", "sedated dinos take +X% damage", "sedated dinos lose their armour". For the look, see V1 (no Ice). | `Shop.client.luau` ~385–403. `Enemies.luau:386` (visual). |
| M4 | Old ability names still in text | The Big Game Hunter's ability is now **Rally Cry**, but "no reloading in Overdrive" still shows, and HEROES.md still says Belt Fed "during Overdrive". The hero-levels paragraph says "Airburst" (now **Flare Strike**). Quick Mark says "shorter Mark cooldown" (now **Tracking Dart**). | "no reloading during Rally Cry", "Flare Strike", "shorter Tracking Dart cooldown" | `Shop.client.luau:510`, `HEROES.md` (fold into T6) |
| M5 | Mortar Pit › Cluster › T5 **Storm of Steel** | It's a literal "storm" leftover, and a WWI title besides. | **Meteor Shower** (bomblets raining down, and a nod to how the dinosaurs died out) | `Tower Upgrades` Name, Mortar Pit / Cluster / T5 + UPGRADES.md |
| M6 | Longshot Perch › Siege › T5 **Skybreaker** | It was named for the old flying zeppelin boss. Now it kills *ground* bosses (Triceratops, T-Rex), and "Sky" makes it sound like an anti-air upgrade. | **Extinction Round** | `Tower Upgrades` Name, Longshot Perch / Siege / T5 + UPGRADES.md |
| M7 | Name collisions and a mis-fit path name in the new trees | 1. Medic Pacifier T2 **Heavy Dose** = Tranq Station Sedate T2 **Heavy Dose**. 2. Armory Gunsmith T2 **Hot Loads** ≈ Big Game Hunter Special Ammo T4 **Hot Load**. 3. Armory Gunsmith T5 **Big Game Arsenal** would be the third "Big Game" name (the hero, Big Game Tranq). 4. The path name **Pacifier** reads as a baby's dummy. | 1. **Double Dose**. 2. **Hand Loads**. 3. **Master Gunsmith**. 4. **Muzzle** (it stops dinos biting, and it fits Jaw Lock). | DECISIONS #14/#16 → `Hero Upgrades` / `Tower Upgrades` Name when T14/T16 land |
| M8 | Projectile look (T12): "a coloured ball per species" | DECISIONS #5 promises a *readable landing zone*, but a ball alone doesn't show where it will land, so players can't dodge. | Add a flat warning ring on the ground at the landing point, sized to the impact radius (orange, Neon, 0.6 transparency), for the flight time. See V2 for the ball shapes. | `DinoAttacks` visual + `DinoLook` (visual only) |

---

## Plan theme verdict (the rest is fine)

**Attack names (DECISIONS #2):** Nip, Slash, Head-Butt, Tail Club, Spike Flick, Kick, Gravel
Spray, Stone Drop, Gore and Chomp are all good. Nice-to-haves:
- Pachy **Rock Fling**: it has no hands. Use **Skull Toss** (it flicks a rock off its dome).
- Trike **Boulder Kick**: this is the second "Kick" (Galli has one). Use **Horn Toss**, which uses its horns.
- T-Rex **Roar Blast**: "Blast" sounds like a ray gun, and a roar isn't a ball. Use **Bone Spit**. If
  the name stays, draw it as an expanding ring, not a ball.

**Field Medic:** Lever-Action Carbine, Triage Kit, Patch Up, Second Wind, Loading Gate, Jaw Lock
and Lullaby Rounds are all good. Nice-to-haves: **Wide Canvas** is vague → **Triage Tent**.
**Field Kit** is one "Field" too many (Field Medic, Field Hospital, Field Engineer) → **Belt Pouch**.

**Field Hospital:** the tower name is Jovan's own (VISION), so keep it. Nice-to-haves: the path
**Outreach** sounds corporate → **Rescue**. **Vitamins** sounds modern → **Camp Rations**. Everything
else (Clean Linens, Extra Cots, Stitch-Up, Night Shift, Miracle Ward, Stretcher Team, Signal Whistle,
Med Kits, Rescue Beacon, Bone Broth, Last Stand) is good.

**Armory:** Plating, Hide Padding, Thorn Plating, Bulwark, Match Grade, Steady Rests and Full Kit
are good. Nice-to-haves: there are three oil names (Medic **Oiled Lever**, Gunsmith **Oiled Actions**,
Outfitter **Gun Oil**), so change Gun Oil → **Recoil Pads** (it's a recoil tier). **AP Crates** is a
military acronym → **Piercing Rounds**.

**Knock-out look (DECISIONS #9):** the tilt, dark Slate and smoke are right. Only the label changes
(M1). See V3 for a cheap extra.

---

## Sweep of existing names — nice-to-have

These are only clear military/Fortnite/BTD leftovers. Everything not listed stays.

| Current | Where | Replace with | Why |
|---|---|---|---|
| Supply Camp › Airdrop › T3 **Care Package** | `Tower Upgrades` Name | **Chopper Drop** | A Fortnite/COD term. Chopper gives a Jurassic-expedition feel. |
| Supply Camp › Logistics › T5 **Command Center** | `Tower Upgrades` Name | **Base Camp** | A hunting expedition has a base camp, not a command center. |
| Supply Camp › Logistics › T4 **Forward Base** | `Tower Upgrades` Name | **Forward Camp** | It matches Base Camp. |
| Longshot Perch › Siege (path) / **Anti-Materiel** / **Siege Gun** | `Tower Upgrades` path id + Name | **Trophy** / **Bone Breaker** / **Punt Gun** | Hunters hunt trophies; a punt gun is a real, huge hunting gun. |
| Longshot Perch › Spotter › T4 **Tactical Spotter** | `Tower Upgrades` Name | **Game Spotter** | Drops the military word. |
| Big Game Hunter path **Tactical** | `Hero Upgrades` path id | **Stalker** | Same reason. |
| Brush Beater path **Breacher**; T5 **Street Sweeper** | `Hero Upgrades` | **Point Blank**; **Thicket Sweeper** | "Breacher" is SWAT and "Street Sweeper" is urban; he beats brush. |
| Brush Beater role **Ordnance** | `Heroes` Role | **Close range** | It's a shotgun, not artillery. |
| Tracker › Trick Shot › T4 **Quick Mark** | `Hero Upgrades` Name | **Quick Dart** | The ability is Tracking Dart now. |
| Tranq Station › Sedate › T5 **Hibernation** | `Tower Upgrades` Name | **Deep Sleep** | Hibernation is a cold/winter word; dinos don't hibernate. |
| Tranq Station › Weak Spot › T2 **Crack Armor** | `Tower Upgrades` Name | **Find the Gap** | It's nearly the same name as Mortar Pit's **Armor Crack**. |
| HUD **"Enemies {n}"**; "No enemy there to mark"; "sets enemies on fire"; "through N enemies" | `Hud.client:125`, `Hero.luau:575`, `Shop.client:494/518` | **"Dinos {n}"**; "No dino there to dart"; "sets dinos on fire"; "through N dinos" | Cheap, and the HUD line is always on screen. |
| Scoreboard **"Pops"**, Modes blurb "Most pops wins." | `Scoreboard.luau:22`, `Modes.luau:15` | **"Trophies"** / "Most trophies wins." | "Pops" is a BTD balloon word. Internal stat names can stay. |

---

## Visual notes (visual only, block-built, keep every tower inside the 3×3 footprint)

**Must-fix visuals** (they back up M3 and M8)
- **V1 Sedated dino:** drop `Enum.Material.Ice`. Add `DinoLook.setSedated(model, on)`: a small
  teal Neon dart (0.15×0.15×0.7) welded into the flank. When the dino is knocked out (frozen), add a
  "zzz" billboard. Jaw Lock (Medic): a dark strap part across the snout (a muzzle).
- **V2 Projectiles:** give each attack a shape, not just the species colour. Rock Fling, Stone Drop
  and Boulder Kick: a Slate ball in `Rock` material (the size scales with the impact radius). Spike
  Flick: a thin bone-white wedge. Gravel Spray: 3 small brown pebbles. T-Rex attack: a bone-white
  capsule. Always pair it with the M8 ground ring.

**Nice-to-have: TowerLook.** Every tower is the same 3×3×5 SmoothPlastic box today, so towers
only read by colour. Add one silhouette per key in `build` (anchored, CanCollide/Query off, like
Crown):
- **Hunting Blind:** a low box in Grass/Fabric with a dark viewing slit across the front and a leafy
  overhang slab on top.
- **Longshot Perch:** four thin Wood stilts with a platform and a small roof at about 8 studs (a
  tree stand).
- **Mortar Pit:** a low ring of 4 sandbag blocks (Fabric) around a short Metal tube angled 45°.
- **Tranq Station:** a teal barrel with a rack of 3 thin darts that have teal Neon tips.
- **Supply Camp:** 2–3 stacked Wood crates under an orange tarp slab, with a thin flag pole.
- **Field Hospital:** a white canvas tent (two wedge parts) with a green "+" (not a red cross,
  which is a protected emblem and would read as "damage").
- **Armory:** a dark Wood back wall with a gun rack (thin dark bars) and a grey Metal plate shield.
- **Tier stages:** swap the generic gold Crown (stage 1) for a mounted **trophy**: bone-white horns
  or a skull block. At stage 2, add a glowing amber accent instead of turning the whole body Neon.
- Use real materials (Wood, Fabric, Grass, Slate, Metal) instead of SmoothPlastic.

**Nice-to-have: DinoLook**
- **Gallimimus:** the `biped` head sits at body height while the Neck part sticks up past it
  (the top of the neck is ~1.3 studs above the head), so it reads as a stump. Put the Head on top
  of the neck, around offset (0, 1.9, -1.2).
- **Compy vs Raptor:** both are small bipeds in similar colours. Give the Raptor a darker back
  stripe and a small crest, so it reads as the tougher one from a distance.
- **T-Rex:** add a row of small white teeth along the Jaw. Pteranodon: move the Crest to the back
  of the head, pointing backward.
- **V3 Trampled tower:** besides the tilt and smoke, add 2–3 small Slate debris blocks at the base,
  so it reads as "smashed" and not just "off".

---

## Round 2 — review of f877eb0 (T7 wording + sedation looks) and 068da66 (T7b silhouettes)

**Landed well**
- All the cold, storm and Overdrive wording is gone from the player-facing text. The Tranq panel
  now reads as darts and sleep. "Dinos {n}" and "No dino there to dart" are good.
- **"Camp lives"** instead of my "Fence" works: it's clear, and it no longer reads as the player's
  own lives. Accepted.
- Ice is replaced by a teal Neon dart plus "zzz", and zzz shows only for Tranq knockouts (not for
  Concussion or Flare Strike stuns). That's exactly the right split.
- The tower silhouettes read as hunting gear: a camo hide, a tree stand, a sandbagged mortar, crates
  under a tarp. Real materials, and everything stays in the footprint.
- The DinoLook fixes are all correct: the Gallimimus head now sits on its neck; the Raptor stripe
  and crest sit on its body and head; the T-Rex teeth sit on top of the jutting jaw.

**Still open or new**

| # | Priority | Issue | Fix |
|---|---|---|---|
| R1 | **must-fix (when T9 lands)** | The Tranq panel now says "knocks out" and a sleeping dino is "knocked out", which makes M1 more urgent. The tower state can't also be "Knocked out" / "KO". | `TowerLook.setKnockedOut` label → `TRAMPLED`. `Shop.client` header → "Trampled — repair it". DECISIONS #9 wording. |
| R2 | must-fix (when T14/T15 land) | The Field Hospital and Armory still have no silhouette. | `TowerLook.SILHOUETTES`: HOSPITAL = a white canvas tent (two wedges) with a **green "+"** (not a red cross). ARMORY = a dark wood back wall, a gun rack of thin bars, a grey Metal plate. Add both to `COLORS`. |
| R3 | nice | Towers never rotate, so the Hunting Blind's slit, the Perch rail and barrel, and the Mortar tube all face world −Z, often away from the track. | `TowerLook` SCOUT: add slits on all four sides. SNIPER: a rail on all four sides and a shorter barrel pointing up at 30° (reads from any side). |
| R4 | nice | The stage-2 glow turns the *whole* silhouette Neon (glowing sandbags, glowing grass), which hides the shape you just added. | `TowerLook.setStage`: at stage 2, keep the materials and add a single amber Neon accent part instead (for example a band under the roof or top block). |
| R5 | nice | The stage-1 gold **Crown** is a generic 3×0.8×3 slab; on the Perch it sits on the roof like a lid. | `TowerLook.setStage`: a **trophy** instead: two bone-white horn blocks (0.3×0.3×1.2, angled ±30°) on a small dark-wood plaque on top. |
| R6 | nice | The sedation dart sits on the right flank only, so it's invisible from the left and hard to see from a tower-height, first-person view. | `DinoLook.setSedated`: put the dart in the **back** (offset `(0, body.Y/2, 0)`, tilted 30° toward the tail) so it shows from every side and from above. |
| R7 | nice | The "zzz" billboard has no distance cap; a knockout pulse on a crowded wave draws a lot of labels across the map. | `DinoLook.setAsleep`: `billboard.MaxDistance = 80` (same as the tier label). |
| R8 | nice | The Pteranodon crest moved back to z −0.9…+0.3, so it now sits mostly over the body and reads as a back fin. | `DinoLook` LLAMA Crest: offset `(0, 0.7, -0.9)`, size `(0.2, 0.3, 1.0)`, tilted up about 20°, so it starts at the back of the head. |
| R9 | nice | The Tranq Station darts stand upright with glowing tips on top, which can read as candles. | `TowerLook` CHILLER: add a small flat fletching block (0.35×0.25×0.05) at the bottom of each dart. |

Still open from round 1 (not taken, which is fine): the attack renames, the Medic/Armory name
collisions (M7, due with T14/T16), the projectile ground ring (M8, due with T12), Storm of Steel /
Skybreaker (M5/M6) and "Pops".

---

## Round 3 — review of f4e883e (player HP), 9ee8b73 (trampled towers), 558763b (repair)

**Reads well**
- M1 and R1 are done. **"TRAMPLED"** is on the tower, the panel header reads "Trampled — repair it · {tower}",
  and the locked upgrade rows say "Repair it first". Only internal keys still say KO, so there is no
  clash with the Tranq Station's "knocks out".
- The trampled look (15° tilt, dark Slate, debris at the base, ring hidden, red label) reads as
  "smashed", not "switched off". Restoring on repair also brings back the stage-2 glow.
- The player HP bar ("HP 72 / 100", bottom left, red flash on a hit) and the "Repair — {price}" row
  (with the Supply Camp discount shown) are plain words and clear. "Repair" is the right word; it
  doesn't collide with the Medic's *Patch Up*.

**Nice-to-have only (no must-fix this round)**

| # | Issue | Fix |
|---|---|---|
| T3-1 | The grey `TrampledSmoke` reads as a fire, but dinos stomped this tower; nothing burned it. | `TowerLook` (setKnockedOut): make the Smoke a dust cloud: `Color3.fromRGB(150, 125, 90)`, Opacity 0.2, RiseVelocity 1.5. |
| T3-2 | Every trampled tower tips the same way (a world-X tilt), so a row of them looks staged. | `TowerLook`: tilt about the X or Z axis chosen from the model's position (e.g. `(base.X + base.Z) % 4`), and keep the 15°. |
| T3-3 | Low health is **orange** on the player bar (`Hud` HP_LOW 230,170,60) but **red** on the tower bar (`TowerLook` HP_LOW 235,90,70). | Use one "low" colour in both. Orange is best: red already means "hit" (the flash) and "trampled". |
| T3-4 | The tower prompt's ActionText is the generic **"Manage"**. | `Shop.luau:71`: **"Upgrade"** (or "Upgrade / Repair" when damaged). It's plain words and what players come to do. |

---

## Round 4 — review of 17b0915 (T10c look tweaks) and 3d2cb33 (T11 bites)

**Reads well**
- All of R3–R9 landed as asked:
  - The Blind has slits on all four sides; the Perch has rails all round and a barrel angled up 30°.
  - The Tranq darts have fletching at the bottom, so they no longer look like candles.
  - The sedation dart is in the back, leaning toward the tail. zzz has MaxDistance 80.
  - The Pteranodon crest now starts at the back of the head and sweeps up.
- The bite rules feel right. The attack names match DECISIONS #2 on the sheet (Nip, Slash,
  Head-Butt, Tail Club, Kick, Gore, Chomp). The Pteranodon has no bite. A knocked-out (asleep)
  dino can't bite, which gives the Tranq Station a clear defensive job.

**Off / to fix**

| # | Priority | Issue | Fix |
|---|---|---|---|
| R4-1 | **must-fix** | The attack names are a dead column (the audit flags `meleeName`). The hunter never learns *what* bit them, so the per-species flavour is invisible. | `Hud.client`: when the local hunter is bitten, show a small popup by the HP bar: **"Raptor · Slash −4"** (1.2s, fades). The server sends species display + `meleeName` + damage with the damage (e.g. a `Hurt` RemoteEvent from `Health.damage`, or an attribute pair). Use the same line later for ranged hits ("Pteranodon · Stone Drop −8"). |
| R4-2 | nice | The bite flash is a plain red ball of the same size for every dino, so a Compy nip and a T-Rex chomp look the same. It reads as "hit", not "bite". | `DinoAttacks.bite` (visual only): two bone-white tooth bars (upper and lower, 1.6×0.25×0.3) that snap together over the target in 0.15s, scaled by `enemy.size/enemy.sizes` × a boss factor 2. Keep a faint red flash behind them. |
| R4-3 | nice | Tower bites show nothing on the tower itself, only the floating flash. | `TowerLook.setHealth` is already called on damage; add a 0.1s red tint of the silhouette parts (restore the colour via the existing `LookMaterial`/`UprightColor` pattern). |

---

## T12 guidance: ranged attacks at a glance

**Shared rules, all six attacks**
- **Warning ring (M8):** one flat Neon cylinder at the landing point, diameter = 2 × impact radius,
  0.1 studs tall. Use the **same orange for every attack** (255, 150, 40), so players learn
  "orange ring = move". Transparency goes from 0.75 at launch to 0.35 just before impact.
  Optionally, an inner disc grows from 0 to full size as a timer. Remove it on landing.
- **On landing:** a 0.3s puff in the projectile's colour (a Ball that grows to the impact radius
  and fades), plus 2–3 small debris chips for rock-type shots.
- The projectile is **species-coloured only where the attack is part of the dino** (spike, bone).
  Thrown debris is **earth-coloured** (Slate / Rock / Sand), so players read "what is coming" from
  the shape and "who threw it" from where it came from.
- Size follows the impact radius (about 0.35 × radius, capped at 3 studs) and scales with the
  dino's size, like the damage.

| Attack (dino) | Look |
|---|---|
| **Rock Fling** (Pachycephalosaurus) | One fist-sized Slate ball (Rock material, grey-brown 120,105,90) on a **high lob** (a clear arc, not a straight line). It spins as it flies. On landing: a grey dust puff and 2 chips. |
| **Spike Flick** (Ankylosaurus) | A thin bone-white wedge (0.3×0.3×1.4, colour 230,225,210, the Anky's own spike colour), **pointing along its flight**, on a flat, fast path. On landing: it sticks upright in the ground for the remaining 0.5s, then fades. No dust. |
| **Gravel Spray** (Gallimimus) | **3 small pebbles** (0.4 studs, Sand/brown 170,140,100) in a tight, slightly spread cluster on a low, fast path (it's kicked). The ring still shows one landing zone. On landing: a low, wide sand puff. |
| **Stone Drop** (Pteranodon) | A Slate stone that **falls straight down** from the flier's height to the ring. There's almost no sideways travel, so the ring is the whole warning. Make the ring show from launch and keep the stone bigger (≈1.2). On landing: a dust puff. |
| **Boulder Kick** (Triceratops) | A **big** boulder (≈2.5 studs, Rock material, dark 95,85,75) that **rolls along the ground** (a low bounce, spinning) toward the ring instead of flying. That makes it read as heavy, boss-grade and dodgeable. On landing: a big dust puff, 3 chips and a small camera-shake-free shockwave ring. |
| **Roar Blast** (T-Rex) | **Not a ball.** It's a flattened, translucent **sound-wave disc** (Neon, pale T-Rex green 170,210,140, 0.6 transparency) that **grows as it flies**, from 2 to the full impact diameter. Two or three thin rings trail behind it. On landing: a ring that expands outward and fades. If it's renamed **Bone Spit** (round 1), use a bone-white capsule instead. |

---

## Round 5 — review of 8a0e8b6 (T12 projectiles)

**Reads well**
- The round-1 renames were adopted on the sheet: **Skull Toss**, **Horn Toss** and **Bone Spit**. The
  six ranged names now all describe something a dino could physically do.
- The styles match the round-4 guidance:
  - The lobbed stone spins and arcs high.
  - The spike flies flat, points along its path and sticks in the ground.
  - Stone Drop falls straight down and accelerates.
  - Horn Toss rolls and bounces as a boulder.
  - Bone Spit is a bone capsule.
  - Debris is earth-coloured; only the dino's own spike or bone is bone-white.
- One shared ring that firms up as the shot comes in is the right single rule for players to learn.

**Off / to fix**

| # | Priority | Issue | Fix |
|---|---|---|---|
| R5-1 | **must-fix** | The warning colour (255,150,40) is nearly the **Supply Camp's** colour (230,150,50). Every Supply Camp draws a permanent Neon range disc in that colour (`TowerLook.setRing`, range 20 = a 40-stud orange disc at 0.85). The ground near a camp looks like a standing danger zone, and real warnings get lost on top of it. | `DinoLook.RING_COLOR` → a hot **red-orange (255, 70, 40)**. Red already means "hurt" in this game (bite flash, HP flash), so it fits. Keep the Supply Camp crate-orange. |
| R5-2 | nice | The ring is a filled disc, so overlapping Bone Spit discs (16 studs wide) merge into one blob, and the sense of "edge = safe line" is weak. | `DinoLook.buildWarningRing`: keep a faint fill (0.85) plus a bright 0.3-stud edge (a second, slightly larger cylinder only 0.12 tall, or 8 thin edge blocks). Fade only the fill. |
| R5-3 | nice | Gravel Spray pebbles are 0.4 / 0.35 studs flying at 70 studs/s (about 0.35s of flight), which is practically invisible. | `DinoLook.buildProjectile` gravel: pebbles 0.6 studs (× scale), and a thin sand trail (one 0.2×0.2×1.5 streak behind the cluster). The ring still does the warning. |
| R5-4 | nice | A throw has no wind-up, so hunters only see the ring, not *who* threw it. That undercuts "who threw it, from where it came" (round 4). | Visual only: when a ranged attack launches, flash the thrower's Head part bone-white for 0.15s (`DinoLook.flashHead(model)`) so the source is visible. |

---

## Round 6 — review of bacc207 (T13b projectile readability) and 75f7382 (T14 Armory)

**Reads well**
- R5-1 to R5-4 all landed:
  - The ring is red-orange (255,70,40) with a bright cream edge, so it can't be mistaken for the
    Supply Camp's range disc, and overlapping rings stay separate.
  - The pebbles are fist-sized.
  - The thrower's head flashes cream at launch, the same family as the ring's edge, so
    "flash → ring" reads as one warning.
- **The Armory** shows every rename from DECISIONS #25: Hide Padding, Iron Plates, *Thorn Plating*, Tempered Steel,
  *Bulwark* · Oiled Actions, Hand Loads, *Piercing Rounds*, Match Grade, *Master Gunsmith* · Wide
  Rack, Recoil Pads, *Ammo Crate*, Steady Rests, *Full Kit*. No collisions, and "Big Game" stays the
  hero's alone.
- The panel wording is plain and in hunter terms: "dinos that bite in range take 3 damage back",
  "towers and hunters in range take 15% less damage", "hunters in range: 25% less recoil".
- The silhouette (a plank floor, a dark back wall, a gun rack, an angled steel plate) reads as an
  outfitter's shed. Its plate-steel grey is distinct from every other tower.

**Off / to fix (nice-to-have only, no must-fix)**

| # | Issue | Fix |
|---|---|---|
| R6-1 | The four rack "guns" are bare vertical steel bars, which read as cell bars. | `TowerLook` ARMORY: give each gun a wooden stock (a 0.25×0.6×0.25 WOOD block at the bottom of each `Gun{i}`, y ≈ 1.25) and shorten the steel part to 1.5. That makes them rifles at a glance. |
| R6-2 | The Armory is grey-on-grey, so its trampled state (dark Slate 60,60,64) changes less than on other towers. | `TowerLook.setKnockedOut`: no colour change is needed; the tilt, debris and label already carry it. Optionally darken the trampled tint to (45,45,48) for every tower so the contrast holds on grey. |
| R6-3 | DECISIONS #16 still lists the pre-rename Armory names; #25 overrides them, but a reader of #16 alone sees Hot Loads / AP Crates / Big Game Arsenal / Gun Oil. | Director: add "(renamed in #25)" to row #16. That's a doc note only. |
| R6-4 | The Tranq Station's Sedate T5 is still **Hibernation**, a cold/winter word, and the old Chiller bullets in UPGRADES.md under the Tranq table (Permafrost, Flash Freeze, Shatter, Cold Front…) may still be there. | `Tower Upgrades` Name Tranq Station / Sedate / T5 → **Deep Sleep** (round-1 nice-to-have), and check that the T5 doc rewrite of those bullets landed. |

---

## Round 7 — review of a815665 (T15 Field Hospital)

**Reads well**
- The R2 ask landed: the tent is a cream canvas A-frame on a groundsheet with a wooden ridge pole and a **green Neon "+"** on both sides. There's no red cross anywhere. Next to the Armory's grey shed and the Supply Camp's orange crates, it reads at once as "camp medic tent".
- The med kits match the tent (cream box, green "+", a green "+30 HP" label). One rule for players to learn: green "+" = healing.
- The round-1 asks landed: **Outreach → Rescue**, **Vitamins → Camp Rations**. The Ward and Tonic tiers (Clean Linens, Extra Cots, Stitch-Up, Night Shift, Miracle Ward / Iron Tonic, Bone Broth, Last Stand) sound like a frontier field camp. "Big Game" and "Signal Tower" don't collide with "Signal Whistle".
- The panel uses the game's own words ("raises **trampled** towers", "med kits land nearby"), and the UPGRADES.md section matches Config.

**Off / to fix**

| # | Priority | Issue | Fix |
|---|---|---|---|
| R7-1 | **must-fix** | **Last Stand is invisible.** When it saves a tower, `Towers.damage` sets hp = 1 and skips even `flashHit` (it's the first branch of the if/elseif). Hunters see a tower that "should" be trampled shrug off a bite with no cue, so it looks like a bug, not the T5 they paid for. | `src/server/Towers.luau` `Towers.damage`, Last Stand branch: call a visual-only `TowerLook.flashSaved(tower.model)`, which flashes the saved tower's parts green (60,190,90, the hospital's "+") for 0.3s, plus a brief "+" billboard / "Last Stand!" label. Optionally pulse the hospital's own "+" so players see *who* saved it. |
| R7-2 | nice | **Rescue Beacon has no beacon.** A T5 hospital looks the same as a T0 one, and a respawning hunter appears beside a plain tent with no idea why. | `TowerLook` HOSPITAL (or a tier-5 Rescue add-on): a tall wooden pole beside the tent with a **green lantern** (Neon, 60,190,90) on top. That's the same green and still low-tech, and it marks the respawn spot from across the map. |
| R7-3 | nice | **Adrenaline** is a modern clinical word in a camp-remedy path (Camp Rations, Iron Tonic, Bone Broth). | `Tower Upgrades` Field Hospital / Tonic / T3 → **Smelling Salts** (it wakes towers up = +attack speed). Update UPGRADES.md line 84/88. |
| R7-4 | nice | **Supply Runs** echoes the **Supply Camp** tower, and its kits are already described as "like the Supply Camp's chests", so players may think it involves the camp. | Rescue / T4 → **Pack Mules** (more kits, heavier kits). Update UPGRADES.md. |
| R7-5 | nice | Panel wording: "heals x1.5 as fast" is awkward. "downed hunters come back here in 50% of the time" uses "downed", a term the game doesn't use elsewhere. | `src/client/Shop.client.luau` ~469: `heals {fmt(heal)}× faster`. ~486: `fallen hunters respawn at this tent in {pct}% of the usual time`. |

---

## Round 8 — review of dda81db (T16 Field Medic)

**Reads well**
- The M7 asks landed: **Double Dose** (no clash with the Tranq Station's Heavy Dose) and the **Muzzle** path. Every round-1 name is in (Lever-Action Carbine, Triage Kit, Belt Pouch, Triage Tent, Patch Up, Second Wind, Jaw Lock, Lullaby Rounds). There are no collisions with tower or hero names.
- HEROES.md and the panel are plain and in hunter terms: "heal yourself and hunters near you", "the heal also patches up towers", "hit dinos can't bite or shoot for 2s (bosses 1s)". Showing the boss time inline is a good habit.
- The strap is welded to the Jaw (or the Head), is Fabric, and is removed cleanly. "A muzzle on the snout" is the right single image for "can't bite".

**Off / to fix**

| # | Priority | Issue | Fix |
|---|---|---|---|
| R8-1 | **must-fix** | The strap (45,35,30) almost vanishes on the **T-Rex Jaw (55,75,45)**, the dino players most want to see muzzled, and on the darker heads. The lock reads only as "the dino stopped". | `src/shared/DinoLook.luau` `setMuzzled`: make `MUZZLE_COLOR` a **leather tan (165,115,65)** and add a small steel **buckle** part (0.35-stud cube, STEEL-grey Metal, welded on top of the strap). The tan contrasts with green, grey and blue hides, and the buckle shows up even on the orange Raptor. |
| R8-2 | nice | The panel line "hits slow dinos 20% for 1s" can be read as "it hits *slow* dinos". It also doesn't say that bosses ignore the slow (HEROES.md does). | `src/client/Shop.client.luau` (Field Medic block): change it to `` `dinos you hit are slowed {p}% for {s}s (not bosses)` ``. |
| R8-3 | nice | **Hip Fire** = full auto on a lever-action is the one modern-shooter term in the tree, and it's about stance, not the lever. | `Hero Upgrades` Field Medic / Lever Action / T5 → **Lever Storm** (or **Fanned Lever**), plus the HEROES.md table and line 115. |
| R8-4 | nice | **Lullaby Rounds** suggests sleep (the Tranq "zzz"), but its effect is the muzzle strap spreading. Players may look for a "zzz". | Keep the name, but when the lock spreads, give the strap a brief (0.3s) lighter flash or a tiny "zzz" billboard on the spread targets (`DinoLook.setMuzzled`, visual only), so the name and the look agree. |

---

## Round 9 — Hunt Board (T25–T29, DECISIONS #63–#70)

**1. Names: verdict**

| Name | Verdict | Note |
|---|---|---|
| **Hunt Board** | keep | It's the camp notice board where hunters pick up work. It doesn't collide with Trophies (#27), Base Camp or Supply Camp. |
| **Daily Haul** | keep | A hunter's haul is what they bring home. It fits a log-in reward and says "daily" plainly. |
| **Big Haul** (day 7) | keep | Clear, and it echoes Daily Haul. Don't use "Jackpot" or "Mega" (casino or brainrot tone). |
| **Bounties** | keep | It's the standard hunter word and young players know it. Label the sections **Daily Bounties** and **Weekly Bounties**. Don't show the easy/medium/hard slot names; the Amber value already says it. Don't rename the hard slot "Big Game" (it collides with the Big Game Hunter hero). |
| **Swap** | keep | Plain words beat theme for a button. Button text: `Swap (1 left)`. |
| **G key** | keep | It's free (#70). The mnemonic is weak, so print `[G]` on the home button and in its tooltip. |
| Toast "Bounty done: …" | nice-to-have | → **"Bounty bagged: Raptor Cull (+15 Amber)"**. "Bagged" is the hunter word for a finished kill and it's still short. |
| Reset payout notice | nice | → "Unclaimed bounties paid: +35 Amber", shown once as a line on the board, not as a pop-up. |

**2. Bounty titles** (`{n}` = the Builder's count; the title goes before the Text column's line)

| Title | Pool | Text |
|---|---|---|
| Compy Sweep | daily | Pop {n} Compies |
| Raptor Cull | daily | Pop {n} Raptors |
| Headbutt Hunt | daily | Pop {n} Pachycephalosaurs |
| Shell Cracker | daily | Pop {n} Ankylosaurs |
| Run Them Down | daily | Pop {n} Gallimimus |
| Clear Skies | daily | Pop {n} Pteranodons (Builder: confirm a free tower or Tracker can hit air before it goes in the pool, #66) |
| Busy Day / Stampede | daily / weekly | Pop {n} dinos of any kind |
| Deep Trail | daily / weekly | Reach round {n} (weekly: reach round 31 {n} times). Avoid "Last Stand", which is the Field Hospital T5. |
| Gear Check | daily / weekly | Use your ability {n} times |
| Pitch Camp | daily | Build {n} towers |
| Sharpen Up | daily | Upgrade towers {n} times |
| Patch Job | daily / weekly | Repair {n} trampled towers |
| Scavenger | daily | Collect {n} supply chests |
| Clean Sweep / Rough Country / Badlands | daily (hard) / weekly | Clear any track (weekly: {n} times) / clear on Normal or harder / clear on Hard or harder |
| Horn Breaker | weekly | Pop {n} Triceratops (every hunter in the match gets credit) |
| Tyrant's End | weekly | Pop a T-Rex (every hunter in the match gets credit) |

**3. Look: a camp notice board, uncluttered**
- **Frame:** one dark wood board (warm brown 70,50,35, a thin lighter rim) on the existing dark `BG`. Header: "HUNT BOARD" in the amber title colour (245,175,60) with the **X in the header bar, outside the scrolling area**. Under it, one dim line: `New bounties in 5h 12m`.
- **Bounty cards:** pinned paper notes (cream 235,225,200, dark text, one small tack at the top). Each card has a title, one text line, a thin progress bar (`12 / 40`) and an Amber chip on the right (`+15`). No species art beyond a small colour dot in the dino's `DinoLook` colour.
- **Claim states:** *in progress*: no Claim button, just the bar and a small `Swap (1 left)` text button (hidden once the bounty is done, claimed or out of swaps). *Done*: a solid amber **Claim** button (no pulsing or shaking). *In flight*: grey `…`, disabled. *Claimed*: the card dims and gets a tilted red-ink **BAGGED** stamp, with no buttons.
- **Daily Haul strip:** 7 small tiles in a row. Claimed days get a dino-footprint stamp; today gets an amber outline and **Claim**; future days are dim. Day 7 is about 1.5× wide, labelled **Big Haul** with an amber-chunk icon. One dim line underneath: "Missed days don't reset your Haul." On narrow windows the strip wraps to 4+3 instead of overflowing.
- **No-trap (DIRECTION):** only the bounty list scrolls (capped like the other panels); the X, the header and the Haul strip never scroll away. Don't add a full-screen dimmer that covers Play. A claim gives an inline `+15 Amber` float on the card, never a reward pop-up or confetti modal. The home button's claimable dot is a small amber dot, not a bouncing badge.

## Round 10 — Hunt Board as built (Daily Haul + Bounties)

Read: the `DailyHaul` and `Bounties` blocks in `src/shared/Config.luau`, `src/shared/HuntBoard.luau`, `src/client/HuntBoard.client.luau`, the home button in `Home.client.luau`, the toast in `Hud.client.luau`, `Bounties.doneText`, and the board's reply messages in `src/server/Progression.luau`. Read from code only; nothing was run in Studio.

**Verdict: it reads as a hunters' camp board, not a "daily quests" menu. One must-fix word, one must-fix title clash, the rest is polish.**

**What's right**
- **Names match Round 9 and all come from `Theme.luau`:** Hunt Board, Daily Haul, Big Haul, Daily Bounties, Weekly Bounties, Swap. Slot names (easy/medium/hard) are never shown.
- **All 24 bounty titles are Round 9's**, spelled as specified: Compy Sweep, Raptor Cull, Busy Day, Gear Check, Pitch Camp, Headbutt Hunt, Shell Cracker, Clear Skies, Deep Trail, Sharpen Up, Run Them Down, Patch Job, Clean Sweep, Stampede, Rough Country, Badlands, Horn Breaker, Tyrant's End. Scavenger isn't in the pool, which is fine. No "Last Stand", no "Big Game".
- **Currency is Amber everywhere**, always through `Theme.Currency` (toast, claim float, payout line). No "coins", "gems", "cores" or "quest" in any player-facing string.
- **No old-theme words on screen.** "StormSplitHome" (`HuntBoard.client.luau:231`) is an internal GUI name, which Theme.luau says stays.
- **The look is the spec:** wood 70,50,35 with a lighter rim, amber 245,175,60 title, cream 235,225,200 paper cards with a tack, red-ink **BAGGED** stamp, footprint stamp on claimed Haul days, amber chunk on Big Haul, the X in the header.
- **Plain, kid-readable wording:** `Claim`, `Swap (1 left)`, `12 / 40`, `+15`, "Day 1"–"Day 6", "Missed days don't reset your Haul.", "Unclaimed bounties paid: +35 Amber". Countdowns `3d 4h` / `5h 12m` / `12m` are the standard Roblox form and never read `0m`.

**Fixes**

1. **must-fix — "Pop" is balloon wording, and the Hunt Board is the only place in the game that uses it.** Round 9 wrote "Pop" itself; that was this reviewer's mistake, carried over from BTD. Dinos shrink and are taken down; nothing pops. In the Bounties sheet's Text column (exported to `src/shared/Config.luau`):
   - `Pop {n} Compies` → `Take down {n} Compies` (same for Raptors, Pachycephalosaurs, Ankylosaurs, Pteranodons, Gallimimus)
   - `Pop {n} dinos of any kind` → `Take down {n} dinos of any kind` (Busy Day, Stampede)
   - `Pop {n} Triceratops (team pops count)` → `Take down {n} Triceratops (your team's count too)`
   - `Pop a T-Rex (team pops count)` → `Take down a T-Rex (your team's counts too)`
   - Only the words change. The internal event keys `pop` / `popTotal` stay.
2. **must-fix — two cards on one board can share a title.** `D_DEEP_TRAIL_15` (medium) and `D_DEEP_TRAIL_25` (hard) are both "Deep Trail", as are `W_DEEP_TRAIL_2` (easy) and `W_DEEP_TRAIL_4` (hard). The toast "Bounty bagged: Deep Trail" then doesn't say which. Titles only:
   - `D_DEEP_TRAIL_25`: `Deep Trail` → `Deeper Trail`
   - `W_DEEP_TRAIL_2`: `Deep Trail` → `Long Trail`
   - `W_DEEP_TRAIL_4`: `Deep Trail` → `Longest Trail`
3. **nice-to-have — the toast promises Amber the hunter doesn't have yet.** `Bounties.luau:485`: `Bounty bagged: Raptor Cull (+15 Amber)` shows when the bounty is finished, but the Amber arrives on Claim, and the board's BAGGED stamp means claimed. → `Bounty ready: Raptor Cull (claim +15 Amber at the Hunt Board)`. This also revises Round 9's own wording. "Bagged" then means one thing: claimed.
4. **nice-to-have — the loading state is a lone "…".** `HuntBoard.client.luau:650` (`problem or HuntBoard.WAIT`): → `Checking the board…`. Keep `…` on the buttons.
5. **nice-to-have — the failed-load line is tech-speak.** `HuntBoard.luau:77`: `Couldn't reach the server` → `Couldn't load the Hunt Board. Close it and open it again.`
6. **nice-to-have — the two countdowns read the same.** `HuntBoard.resetLine` gives `New bounties in 5h 12m` both under the header (daily) and beside Weekly Bounties (weekly). → top line `New daily bounties in 5h 12m`; weekly side `New in 3d 4h`.
7. **nice-to-have — key hint style differs along the home row.** `Home.client.luau`: `Choose hero  (H)`, `Unlocks & Mastery  (M)`, then `Hunt Board [G]` (Round 9 asked for brackets without checking the neighbours). → `Hunt Board  (G)` in `HuntBoard.BUTTON`, to match.
8. **nice-to-have — server replies shown on the board's message line** (`src/server/Progression.luau`): `Already claimed today` → `Today's Haul is already claimed`; `Swapped` → `Bounty swapped`; `That bounty can't be claimed` → `That bounty isn't ready yet`; `The Hunt Board isn't available right now` → `The Hunt Board is closed right now`.
9. **nice-to-have — the "not saving" note is for the developer.** `HuntBoard.client.luau:642`: `Progress isn't saving: publish the place to Roblox to keep it (SETUP.md).` shows whenever `SaveStatus` is "offline". If that can ever happen in the published game, a player needs: `Progress isn't saving right now.` It's the same string as in Shop.client, so change both or neither.

Left alone on purpose: "Pachycephalosaurs" (long, but it's the species' in-game name), "Day 1"–"Day 6", `Claim`, `Swap (n left)`, the countdown format, every colour, and all numbers and rules.

## Round 11 — mastery perk names and XP wording (T37)

Read: `Config.MasteryPerks` and the `Mastery` `unlock` lines in `src/shared/Config.luau`, `perkLines` / `ownedPerkLine` and the Amber note in `src/client/Shop.client.luau`, the XP row and level banners in `src/client/Hud.client.luau`, against `HEROES.md` and `UPGRADES.md`. Read from code only; nothing was run. No numbers or rules change below.

**Verdict: five of eight perk names stay. Two names and three strings are must-fix; "XP" stays as plain "XP".**

**Perk names (final table)**

| Hunter | Mastery | Working name | Final name | Final text |
|---|---|---|---|---|
| Tracker | 10 | Lingering Dart | **Sticky Dart** | Tracking Dart lasts 2s longer |
| Tracker | 15 | Split Dart | **Spare Dart** | Tracking Dart also marks the nearest dino within 10 studs at 40% strength |
| Big Game Hunter | 10 | Carrying Voice | **Hunting Horn** | Rally Cry reaches 5 studs further |
| Big Game Hunter | 15 | Long Rally | Long Rally (keep) | Rally Cry lasts 3s longer |
| Brush Beater | 10 | Wide Flare | Wide Flare (keep) | Flare Strike reaches 1.5 studs further |
| Brush Beater | 15 | Smoulder | Smoulder (keep) | Flare Strike leaves burning ground for 3s (12% of the strike's damage each second) |
| Field Medic | 10 | Long Reach | **Far Reach** | Triage Kit reaches 4 studs further |
| Field Medic | 15 | Stocked Kit | Stocked Kit (keep) | Triage Kit heals 10 more HP |

Checked against every tier, perk and ability name in `HEROES.md`, `UPGRADES.md` and `Config.luau`: Sticky Dart, Spare Dart, Hunting Horn and Far Reach are unused. Rejected: Barbed Dart (Tranq Station already has "Barbed Darts"), Scorched Ground (too close to "Scorched Earth").

**Fixes**

1. **must-fix — `Split Dart` → `Spare Dart`.** "Split" is the old Storm Split word, and the theme's one hard rule is that nothing splits (dinos shrink). The dart doesn't split either: a second, weaker mark lands on a neighbour. "Spare" also says "the lesser one" without a number.
2. **must-fix — `Lingering Dart` → `Sticky Dart`.** Tranq Station's tier 3 is "Lingering Dose", another dart that lasts longer: two near-twin names for different things. "Sticky" is also a word a kid reads at once.
3. **must-fix — Wide Flare's text: `Flare Strike is 1.5 studs wider` → `Flare Strike reaches 1.5 studs further`.** The radius grows 1.5, so the strike is 3 studs wider across; "wider" reads as the wrong number. This also matches the wording of the other two radius perks.
4. **must-fix — `Level {N} perk` → `Mastery {N} perk`** (`Shop.client.luau`, `perkLines`). The HUD now shows "Lv N" and "Hunter level N" for the in-match level; a hunter at match level 10 will read "Level 10 perk" as theirs. The row already says "mastery 9 → 10", so the word is on screen. Same for the two `unlock` lines: `plus your hunter's level-10 ability perk` → `plus this hero's mastery-10 ability perk`; `plus your hunter's level-15 ability perk` → `plus this hero's mastery-15 ability perk` ("this hero's" is what the other unlock lines in the same list say).
5. **must-fix — tower banner: `Towers level {N} — +{P}%` → `Tower level {N} — towers hit {P}% harder`.** "+10%" of what isn't said; the hunter banner beside it says it in full, and the new tower-panel line says "Tower level", singular.
6. **nice-to-have — `Carrying Voice` → `Hunting Horn`.** "Carrying" is a grown-up idiom; a horn is hunting gear and says "heard further" on its own.
7. **nice-to-have — `Long Reach` → `Far Reach`.** The Medic's own Muzzle path has "Long Dose", and "Long Rally" is another perk in the same set.
8. **nice-to-have — Smoulder's text:** `(12% of the strike each second)` → `(12% of the strike's damage each second)`.
9. **nice-to-have — `+{N} on clear` → `+{N} bonus on round clear`.** "Clear" alone means a track clear elsewhere ("Clear a track to earn Amber"), and the bar gains the round's XP plus this number, so it is a bonus, not the whole gain. Fits the 420-wide row: `240 / 500 XP  ·  +12 bonus on round clear`.
10. **nice-to-have — `Mastery never makes your gun hit harder.` → `Mastery boosts your ability, never your gun's damage.`** Says what mastery does before what it doesn't; about the same length, so the 50-high row still fits.

**XP: keep plain "XP".** Every Roblox player knows it, it's two letters in a tight row, and Amber is the one themed currency: a second themed word (Trophies, Renown, Tracks) would need explaining and could be mistaken for something you spend.

Left alone on purpose: `Lv {N}`, `{shown} / {needed} XP`, `Hunter level {N} — your shots hit {P}% harder`, `Tower level {N} · +{X}% damage` (tower panel), `{ability} perks: {names}`, ` (owned)`, the British spelling of Smoulder (the game says "armour"), and all numbers.

## Round 12 — batches 1–2 as built (T45) and the four new towers' names (T62)

### T45 — renames, home, Hunt Board and HUD strings

Read: `git show` of befac6a, 61b77b4, 1b66379, dd94629; greps of `src/client`, the name/role/blurb/text fields of `src/shared/Config.luau`, `Theme.luau`, `HuntBoard.luau`, `HomeLayout.luau`, `Modes.luau`, `Scoreboard.luau`, `UPGRADES.md`, `HEROES.md`. Read from code only; nothing was run.

**Verdict: the renames are clean. One must-fix (a number that reads wrong), the rest is polish. No "Trophy" anywhere.**

**What's right**
- **Every #130 rename landed** in Config and docs: Fence (HUD), Bones (leaderboard), Chopper Drop, Base Camp, Forward Camp, Big Bore / Bone Breaker / Punt Gun, Game Spotter, Stalker, Point Blank / Thicket Sweeper, Close range, Deep Sleep (plus the earlier Meteor Shower, Extinction Round, Quick Dart, Find the Gap). **Zero leftovers** of Lives, Pops, Siege, Tactical, Command Center, Forward Base, Care Package, Anti-Materiel, Hibernation, Breacher, Street Sweeper, Ordnance, Cores or Trophy in any player-facing string. What's left is internal and stays: the `Lives`/`Cores` attributes, the `pop` bounty event key, code comments.
- **Bones next to Bone Breaker, Bone Broth and Bone Spit: no clash.** They sit on different screens (leaderboard count, tower panel, hero upgrade, dino attack), and nobody will mistake a leaderboard count for an upgrade. Keep all four.
- **Home and Hunt Board:** `PLAY`, `Choose hero  (H)`, `Unlocks & Mastery  (M)`, `Hunt Board  (G)` all use the same key-hint style. The Hunt Board balance reads `1,250 Amber` (with a thousands comma, through `Theme.Currency`), in amber on the wood header. Good.
- **HUD:** `Cash {cash}  ·  Fence {lives}  ·  Dinos {alive}` reads well; Fence needs no explaining once the first dino breaks through it.

**Fixes**

1. **must-fix — the XP line under-promises by 100.** `Hud.client.luau:229`: `+{pending} on round clear`. `HeroXpPending` is only the take-down bonus (`HeroXp.popXp`, ≤15, ≤30 solo), but the bar gains the round's 100 XP plus it on the clear. A hunter reads "+12", then sees the bar jump by 112. → `+{pending} bonus on round clear` (Round 11 fix 9, which was half-applied; it's still Jovan's line, on its own row as he asked).
2. **nice-to-have — `Modes.luau:15`: `Most bones wins.` → `Most Bones wins.`** It's the leaderboard column's name, so capitalise it like a name, the same as Amber.
3. **nice-to-have — put Fence and Bones in `Theme.luau`.** Its header says it holds the game's wording in one place, but these two are hard-coded: `Hud.client.luau:244/246` ("Fence"), `Scoreboard.luau:22` ("Bones"), `Modes.luau:15`. → `Theme.Fence = "Fence"`, `Theme.Bones = "Bones"`, used in all four.
4. **nice-to-have — the loss screen could name the fence.** `Hud.client.luau:238`: `Reached round {round} on {difficultyName}` → `The fence fell on round {round} ({difficultyName})`. It explains why it's over and ties back to the HUD word. Only if it fits the 18-size line.

Left alone on purpose: `VICTORY` / `GAME OVER`, `Lv {N}`, `{shown} / {needed} XP`, `Dinos {alive}`, `Close range` (hero role, matches Precision's style), every colour and number.

### T62 — the four new towers

Rules used: no name already in `Config.luau`, `UPGRADES.md`, `HEROES.md` or the proposals in `TOWERS_LATER.md` (all 60 checked by grep, zero hits); no "Trophy", no "split", no "pop"; words a 9-year-old reads at once; Jovan's twelve tier-5 picks keep their names (he picked them by name). *Italics* = grants an ability, as in UPGRADES.md.

**Tower display names: keep all four working names.** Storm Coil (Jovan says "storm coils" himself; lightning is weather, not the old Storm Split storm), Falcon Roost, Tar Pit, Harpoon Ballista: all plain, all say what the tower is.

**Storm Coil** — paths **Arc**, **Charge**, **Lightning Rod**

| Path | T1 | T2 | T3 | T4 | T5 |
|---|---|---|---|---|---|
| Arc (was Chain) | Copper Wire | Long Arc | *Fork Lightning* | *Jump Spark* | **Power Grid** |
| Charge | Battery Pack | Static Shock | *Thunderclap* | *High Voltage* | **Judgement Bolt** |
| Lightning Rod (was Storm) | Tall Mast | Charged Air | *Grounding Spike* | *Storm Warning* | **Lightning Rodeo** |

- Chain → **Arc**: the game already has Chain Shot, Chain Reaction, Chain Harpoons and the Ballista's rope path; one more "Chain" blurs them. Copper Coil → **Copper Wire** (it read as the tower's own name). Jumper → **Jump Spark** ("jumper" is a sweater to half the players).
- Capacitor → **Battery Pack**, Static Build-up → **Static Shock**: kid words, same meaning.
- Storm → **Lightning Rod**, so the tower isn't "Storm Coil, Storm path". The old T1 Lightning Rod moves up to path name; T1 becomes **Tall Mast**; Conductor → **Charged Air** ("conductor" reads as a train driver). Lightning Rod path → Lightning Rodeo is a pun on purpose.

**Falcon Roost** — paths **Talons**, **Flock**, **Falconer** (all kept)

| Path | T1 | T2 | T3 | T4 | T5 |
|---|---|---|---|---|---|
| Talons | Sharp Talons | Hooked Beak | *Power Dive* | *Iron Talons* | **Eagle of the Peak** |
| Flock | Second Pair | Quick Return | *Flock of Six* | *Wide Circle* | **Murmuration** |
| Falconer | Long Leash | Falcon Bells | *Hooded Scout* | *Lure* | **Hunting Party** |

- Falconry jargon out: Stoop Dive → **Power Dive**, Cast of Six → **Flock of Six**, Jesses → **Long Leash**, Bells → **Falcon Bells**.
- **Ask Jovan (one word):** "Murmuration" is the right word for a swirling flock but hard for a kid to read or say. Kept because he picked it; if he wants plainer: **Sky Swarm**.

**Tar Pit** — paths **Deep Tar**, **Bubbling**, **Dig Site**

| Path | T1 | T2 | T3 | T4 | T5 |
|---|---|---|---|---|---|
| Deep Tar | Thick Tar | Wide Pool | *Fast Sink* | *Clinging Tar* | **Tar Lake** |
| Bubbling | Warm Tar | Simmer | *Boiling Pit* | *Tar Fire* | **Eruption** |
| Dig Site (was Bone Yard) | Pick and Shovel | Fossil Hunter | *Lucky Finds* | *Tar Tracks* | **Tar Totem** |

- Bone Yard → **Dig Site**: Bones now means take-downs, and Bone Breaker / Bone Broth already exist; a cash path is a dig, not a graveyard.
- Sucking Mire → **Fast Sink** (says the effect). Pitch Fire → **Tar Fire** ("pitch" is a sports field to a kid). Sticky Trail → **Tar Tracks** (tar footprints; also avoids Sticky Dart).
- Amber Seep → **Lucky Finds**: must-fix in spirit. The chest pays **cash**, and "Amber" is the saved currency; a tier named Amber promises Amber.

**Harpoon Ballista** — paths **Spearhead**, **Reel**, **Volley**

| Path | T1 | T2 | T3 | T4 | T5 |
|---|---|---|---|---|---|
| Spearhead (was Barbed) | Steel Head | Saw Tip | *Crusher Bolt* | *Great Harpoon* | **Skewer** |
| Reel (was Chain Line) | Rope Line | Winch | *Pin Down* | *Reel In* | **Tow Line** |
| Volley | Twin Bolts | Fast Crank | *Spread Volley* | *Steam Crank* | **Chain Harpoons** |

- Barbed → **Spearhead** and Barbed Tip → **Saw Tip**: Tranq Station has Barbed Darts (Round 11 rejected "Barbed Dart" for the same reason).
- Bone Splitter → **Crusher Bolt**: "Bone Splitter" beside Longshot's Bone Breaker is a near-twin on the other pierce-through path, and "split" is the one word the theme bans.
- Whale Iron → **Great Harpoon** (whales in a dino game confuse; the T4 is the big harpoon).
- Chain Line → **Reel**: leaves Chain Harpoons as the only "chain" on this tower.
- Twin Bow → **Twin Bolts** (it's a ballista, not a bow). Auto-Crank → **Steam Crank** (Fast Crank / Auto-Crank were near-twins on one path).

**Kept as-is (good enough):** the four tower names; paths Charge, Talons, Flock, Falconer, Deep Tar, Bubbling, Volley; tiers Long Arc, Fork Lightning, Thunderclap, High Voltage, Grounding Spike, Storm Warning, Sharp Talons, Hooked Beak, Iron Talons, Second Pair, Quick Return, Wide Circle, Hooded Scout, Lure, Thick Tar, Wide Pool, Clinging Tar, Warm Tar, Simmer, Boiling Pit, Pick and Shovel, Fossil Hunter, Steel Head, Rope Line, Winch, Pin Down, Reel In, Fast Crank, Spread Volley, and all twelve tier 5s.

## Round 13 — hero tier 6s and small mastery perks (T54)

| Hero | Path | Tier 6 | Player text |
|---|---|---|---|
| Tracker | Gunslinger | *Hot Swap* | Your two guns take turns reloading, so you never stop shooting. Reloads faster. |
| Tracker | Marksman | *Heart Shot* | Scoped shots fly dead straight and shrink a dino 2 sizes. |
| Tracker | Trick Shot | ***Bounce Back*** (was Trick Reload) | Every dino a bounced shot takes down puts a bullet back in your gun. |
| Big Game Hunter | Stalker | ***Big Five*** (was Five-Round Burst) | Fires 5 shots per burst, tightly grouped. |
| Big Game Hunter | Heavy | *Endless Belt* | Once fully spun up, you never need to reload. |
| Big Game Hunter | Special Ammo | ***Dynamite Rounds*** (was Powder Tips) | Bigger blasts that break through armour. |
| Brush Beater | Slug | *Thunder Slug* | Slugs shrink a dino 2 sizes; dead straight while you stand still. |
| Brush Beater | Buckshot | *Wildfire Drum* | Wider fire on the ground and 50% more shells. |
| Brush Beater | Point Blank | *Quad Barrel* | Four blasts every trigger pull. Slower reload. |
| Field Medic | Triage | *Rapid Response* | Your Triage Kit holds 2 uses. |
| Field Medic | Lever Action | ***Bottomless Tube*** (was Tube Feed) | 50% more rounds and reloads twice as fast. |
| Field Medic | Muzzle | ***Lights Out*** (was Nightcap) | Jaw Lock lasts 4s and spreads to dinos 9 studs away. |

- **Must-fix:** Nightcap → **Lights Out** ("nightcap" is a bedtime drink; wrong for a kids' game). Powder Tips → **Dynamite Rounds** (a capstone can't sound weaker than its T5 Explosive Tips; also the third "Tips").
- **Nice-to-have:** Trick Reload → **Bounce Back** (says the effect); Five-Round Burst → **Big Five** (the famous hunters' "Big Five" + five shots); Tube Feed → **Bottomless Tube** (Tube Feed sounds like a T1).
- Thunder Slug kept, though Thunderclap/Thunderhead exist on towers. Apex and Meteor were taken.
- Small perks: Long Arms, Handyman kept. **Field Dressing → First Aid** (nice-to-have; "dressing" reads as salad). **Quick Recovery → Back in Action** (nice-to-have; fifth "Quick" name).
- **Must-fix wording:** HEROES.md line 66–67 says "per pop" twice → "per take-down". "Breaks 2 sizes" in player text → "shrinks a dino 2 sizes".
- All new names grep-clean against UPGRADES, TOWERS_NEXT, HEROES, Config.

## Round 14 — player-level rewards, titles, Profile and leaderboard (T59)

**Verdict:** the theme holds. The 89 commons use plain earthy colour words (Fern/Ochre/Ash/Moss/Bone…) across six kinds, which is right for levels 1–99. The rares are noticeably better (Bush Hat, Ironwood Stock, Crest Helm, Raptor Scale), and the sets at 150/200 sound legendary. No old-theme words were found. One reserved word and one tower-name clash have to change. Numbers are unchanged.

**Title ladder as I'd have it** (only the names move; the levels stay):

| Lv | Current | Proposed |
|---|---|---|
| 10 | Greenhorn | Greenhorn |
| 20 | Trailblazer | ***Trapper*** (swap with 30: trapping comes before blazing trails) |
| 30 | Trapper | ***Trailblazer*** |
| 40 | Ranger | Ranger |
| 50 | Trophy Hunter | ***Veteran Hunter*** |
| 60 | Warden | ***Game Warden*** |
| 70 | Pathfinder | Pathfinder |
| 80 | Raptor Bane | Raptor Bane |
| 90 | Rex Wrangler | Rex Wrangler |
| 100 | Apex Hunter | ***Master Hunter*** |
| 150 | Fossil Legend | Fossil Legend |
| 200 | Meteor Hunter | Meteor Hunter |
| 250+ | Elder Hunter {n} | Elder Hunter {n} |

- **Must-fix:** Trophy Hunter → **Veteran Hunter** ("Trophy" is reserved for ranked, DIRECTION.md). Tar Pit Set → **Volcano Set**, because Tar Pit is an approved tower (DECISIONS #152, T67). Volcano at 150 and Meteor at 200 also read as a rising "end of the dinosaurs" pair.
- **Nice-to-have:** Apex Hunter → **Master Hunter** (Apex Predator is already a Weak Spot T6 name; Round 13 avoided "Apex"). Warden → **Game Warden** (on its own, "Warden" reads as prison). Swap Trailblazer/Trapper. Star Marker → **Claw Marker** (stars aren't on theme). Fern Trail → **Footprint Trail** (a level-80 rare shouldn't share a word with ten commons).
- **Kept:** Meteor Set and Meteor Hunter. They share a word with the Meteor Shower perk, but the meteor is *the* dino-ending legend, so it's worth having.
- **Strings:** all fine and kid-readable: "Player level" (not "Lv N"), "Profile (P)", "PROFILE", "Leaderboard", "Next rewards", "Wear", "None", "N / M XP to level L", "Level 10 · Bush Hat (Hunting hat) · title Greenhorn", "Unlocks at player level N", "Equipped", "Taken off", "That doesn't go there", "World top 50", "This server", "Checking the board…", fallback "Hunter". The slot labels (Title, Name colour, Leaderboard banner, Gun tint, Gun pattern, Tracers, Crosshair, Tower flag, Hunting hat, Sprint trail, Animated set) are fine. "Unknown slot"/"Unknown item" are only OK if they never reach players. If they can, use "That doesn't go there" for both.
- I grepped every proposed name against UPGRADES, TOWERS_NEXT, HEROES and src. No hits apart from an internal "Footprint" instance in HuntBoard.client.luau, which players never see ("Big Game Hunter" was avoided because it's a hero name; "Stalker" because it's a hero path).
