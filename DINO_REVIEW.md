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
