# Plan — Step 2 + wide polish (Director, 2026-09-30)

Scope (Jovan, 2026-09-30): Step 2 "the dinos fight back" (`VISION.md`), plus a wide polish
pass that proves Amber pays out correctly and that every tower and every upgrade path does
what `UPGRADES.md` / `HEROES.md` say. **Stop before phase 7** (battle modes, buy-ins, per-team
cash); then the Director writes the recap.

Design calls behind this plan are in `DECISIONS.md` #2–#19. Numbers quoted here are seeds for
the spreadsheet, never for code.

## Rules for every task

- One task = one commit (push after it's verified). Don't start the next task until the
  current one is committed.
- Verify: `tools/check.sh` clean; `python3 tools/export_constants.py` clean; `tools/test.sh`
  green (from T1 on); after any spreadsheet change, diff `Config.luau` and account for every
  changed line in the commit message.
- Spreadsheet: openpyxl only. Before writing a cell, assert it's empty or holds the value
  you mean to replace. **Append rows and columns; never insert rows in the middle.**
  openpyxl doesn't rewrite formulas, and `Tuning!$B$nn` / `Towers!$C$11` are referenced by
  absolute address. New Tuning levers go below row 65.
- Studio isn't available: report "statically checked + headless tests, not playtested".
- **Tier names repeat across trees** (e.g. "Ricochet" is both Tracker Trick Shot T3 and
  Longshot Perch Deadeye T3; "Extended Mag", "Long Barrel" and "Quick Hands"-style names can
  collide). Every lookup (by script, grep or eye) must be scoped to the right sheet
  (`Tower Upgrades` vs `Hero Upgrades`) or Config block (`Towers` vs `Heroes`) and keyed by
  (tower/hero, path, tier), never by name alone. Don't filter out values equal to 1 when
  dumping cells: 1 is a meaningful value (bounces, pellets, burn DPS).
- 🦖 = the Dino agent reviews this task (names, looks, wording) before the Director signs
  it off.

---

## Part A — test harness and the polish audit

### T1. Headless test harness (Lune)
- **Goal:** run pure Luau modules outside Studio.
- **Do:** `rokit add lune-org/lune` (commit `rokit.toml`). Add `tools/test/run.luau`: for
  each `*.spec.luau` it loads `src/` modules through `@lune/luau` `load()`. It injects a `script`
  shim whose `.Parent.X` resolves to sibling files, plus a `require` that follows it, and
  `Vector3` / `Vector2` / `CFrame` / `Color3` from `@lune/roblox`. Add `tools/test.sh`
  (runs every spec and exits non-zero on failure). First spec: `Upgrades.check` truth table
  (maxed, third path, crossover at cap 2 and 3, the tier 2/2 edge cases).
- **Fallback** if Lune can't be installed (no network): the `luau` CLI with the same shim,
  and say so in the commit.
- **Accept:** `tools/test.sh` runs and passes; one deliberately broken assertion makes it fail
  (check that, then revert it).

### T2. Pure tower rules out of `Towers` (refactor, no behaviour change)
- **Goal:** make tower stats and prices testable.
- **Files:** new `src/shared/TowerStats.luau` (`compute(def, pathTiers)`, moved verbatim
  from `Towers.computeStats`, plus the MULTIPLIERS/HIGHEST/FLAGS lists). New
  `src/shared/Pricing.luau`: `upgradeCost(step, discountPercent)`,
  `sellRefund(spent, auraRefund)`. `Towers` and `Shop` call them.
- **Accept:** check clean. The spec proves `compute` gives the Config row's numbers for all 75
  tiers, and that a crossover of two paths multiplies ×-columns, takes the highest amount and ORs
  flags. Pricing spec: Bulk Order 5% / Command Center 20% discounts, and refunds of 0.7,
  Recycler 0.9 and Command Center 1.0. Nothing else in the game changes (the diff is a move, not
  a rewrite).

### T3. Amber payout: prove it, fix the player count
- **Goal:** the casual rules in `VISION.md` "Amber economy" hold.
- **Files:** `Progression.luau` gets a pure `Progression.casualPayout(cleared, players,
  difficultyKey)` (or `src/shared/Payouts.luau` if it needs to be requirable without
  DataStore). `Main` passes the number of players who took part and are still in the
  server (`joinedThisMatch` ∩ present) (DECISIONS #19).
- **Spec:** solo clear Easy 50 / Normal 100 / Hard 150 / Chaos 200; solo loss 0;
  multiplayer loss 5 (Tuning); multiplayer clear = that difficulty's clear reward; unknown
  difficulty on a clear = 0.
- **Code audit (read and note in the commit):** `endMatch` runs exactly once per match
  (both `Victory` and `GameOver`, including when everyone leaves); the payout reaches
  `LastPayout` and the result screen; the J Studio grant never saves; unlock and mastery
  buys deduct exactly the Config price, refuse while `Playing`, can't go negative, and
  persist through `save`; the unlock ladder in Config equals DIRECTION.md (Tracker, Hunting
  Blind, Longshot Perch and Mortar Pit free; Big Game Hunter 75, Brush Beater 75, Tranq
  Station 100, Supply Camp 150).
- **Accept:** spec green; any mismatch found is fixed in this commit and listed.

### T4. Config ↔ design-doc audit script
- **Goal:** catch drift between the approved docs, the spreadsheet and the code, every time.
- **Files:** new `tools/audit.py` (run by `tools/test.sh`). It reads the exporter's data (import
  `export_constants` and don't parse Luau). Checks:
  1. Every tier name in the `UPGRADES.md` / `HEROES.md` path tables equals the spreadsheet Name
     (tower, path, tier).
  2. Unlock costs equal the DIRECTION.md ladder (extended by DECISIONS #13/#15/#16 once
     those rows exist).
  3. **Dead columns:** every Config field that is non-zero on some tier is referenced by
     name in some `src/**/*.luau` file other than Config (no mechanic silently unbuilt).
  4. Every species in `VISION.md`'s table exists with that display name.
- **Accept:** the script runs and prints a findings list. Findings are fixed in T5/T6 (not
  here), except pure typos.

### T5. Every tower path does what `UPGRADES.md` says — 🦖 (doc wording)
- **Goal:** a claims spec per tower tier, then fixes.
- **Files:** `tools/test/towers.spec.luau` encodes each bullet in `UPGRADES.md` as a
  `TowerStats.compute` assertion. Examples: Armor Breaker pierces; Hollow Points armoured ×2;
  Railshot line 3; Hide Buster armoured ×4 and boss ×4; Flare Gun aura +10% rate; Signal Tower
  +20% damage and pierce aura; Double Tap 2 shots; Lead Rain has the highest shots×rate of any
  tower tier; Full Metal Jacket 2 / Through-and-Through 3 and pierce / Linebreaker 10 and
  damage ≥ 2× Ricochet (T3); Marked Target mark 25; Eye in the Sky mark 60 and aura rate 15;
  Anti-Materiel boss ×3; Concussion stun; Skybreaker boss ×10 and stuns bosses; Napalm burn;
  Scorched Earth longer and bigger burn; Cluster Shell 3 bomblets; Chain Reaction 2 generations;
  Shockwave knockback; Armor Crack pierce and armoured ×2; Stun Grenade stun; Tectonic Slam
  stun 1s; Tranq slow ladder and Knockout freeze; Weak Spot brittle/strip/auras; Supply Camp
  income, interest, chests and discounts.
  Then **trace each mechanic in code** (`Towers.fire/hit/bomblets/addBurn/stepChill`,
  `refreshAuras`, `roundIncome`, `airdrops`, `Airdrops`, `Shop` discount/refund) and write
  down any path where the number exists but the behaviour doesn't happen.
- **Linebreaker:** don't change it. The spec asserts line 10 and Damage x ≥ 2× Ricochet
  (tier 3). Whether "×2" should mean ×2 over Tungsten Core is flagged for Jovan (DECISIONS
  #17).
- **Known fixes to make:** `UPGRADES.md`
  Tranq Station bullets still use the old Chiller names (Permafrost, Flash Freeze, Shatter,
  Cold Front…), so rewrite them with the tier names in the table. "Armored Husks" → "armoured
  dinos (Ankylosaurus)". Header "unlock 100 Storm Cores" → Amber.
- **Accept:** spec green; every fix listed in the commit; Config diff accounted for; the
  exporter's hero-vs-tower check still passes.

### T6. Every hero path does what `HEROES.md` says — 🦖 (doc wording)
- **Goal:** the same as T5, for `HeroStats.compute`.
- **Spec:** Quick Draw/Hair Trigger rate; Dual Pistols guns 2 and doubled magazine; Akimbo
  Frenzy auto; Scope flag and range; Hollow Tips pierce; Deadshot marked ×3; Ricochet
  bounces ≥ 1; Quick Mark cooldown; Chain Shot bounces 4; Burst Fire burst 3; Belt Fed;
  Bipod still recoil; Spin-Up; Tracer mark; Incendiary Burn DPS > 0; AP pierce;
  Explosive Tips splash; Slug Rounds = 1 pellet and pierce 2; Rifled Barrel hits air;
  Sabot pierce; Railslug pierce 6; Dragon's Breath ignite 0.35; Street Sweeper auto;
  Double Barrel 2 shots; Kickback knockback; Frag splash. Also: `shotDamage` is conserved
  across pellet counts; when two paths set pellets or fire mode, the most-upgraded path
  wins and ties go to the earlier path.
  Then trace `Hero.trigger/impact/ricochet/ability` for each.
- **This is a verification spec, not a fix list.** The coordinator confirmed that Config
  already has Ricochet bounces 1, Incendiary burn DPS 1 and slug pellets 1 (DECISIONS #18 is
  retracted). Fix only what the spec or the code trace actually shows failing. Docs: `HEROES.md` still says
  "Storm Cores", and Dragon's Breath still talks about "split children / Brute / Husks", so
  reword both for Amber and shrinking. Also (DECISIONS #24): Belt Fed "during Overdrive" →
  "during Rally Cry", "Airburst" → "Flare Strike", and "Mark cooldown" → "Tracking Dart
  cooldown". These are wording changes only; no tier names change.
- **Accept:** spec green; Config diff accounted for; the exporter's hero-vs-tower check passes.

### T7. Polish sweep of leftovers found by T4–T6
- Anything the audit listed that isn't a single-tier fix: dead columns and missing
  behaviour. It also covers stale "Storm Split"/"Cores" wording in player-facing strings
  (`Main` header, prints, panel text) — player-visible text only; internal keys stay. Relabel
  the note at `Rounds!A48` (CLAUDE.md open issue). 🦖 for wording.
- **Theme fixes from the Dino review (DECISIONS #22–#24):** HUD "Lives {n}" → "Camp lives
  {n}". "Enemies {n}" → "Dinos {n}". Player-facing "enemy/enemies" → "dino/dinos"
  (`Hero.luau` "No dino there to dart"; `Shop.client` "sets dinos on fire", "through N
  dinos"). Tranq Station panel text uses sedation words ("knocks out Xs every Ys", "darts deal
  X damage", "knocks out bosses", "sedated dinos take +X%", "sedated dinos lose their armour").
  `Shop.client` "Overdrive" → "Rally Cry". Replace the Ice look (`Enemies` step) with
  `DinoLook.setSedated(model, on)`: a teal dart in the flank. Add a "zzz" billboard while a dino
  is stunned by a Tranq Station freeze pulse. **Do not rename any tier, path, hero, tower or
  "Pops".** Those wait for Jovan (#27).
- **Dead columns (DECISIONS #28):** in `tools/audit.py`, Tuning fields that sheet formulas
  read become an "ok sheet-only" note, not a finding. Add a commented allowlist with two
  entries: `Tuning.StartingLives` (superseded by Difficulty) and `Enemies.cashValue`
  (display; the code derives the same value). Relabel the StartingLives note in the sheet
  (assert the old text first) and drop it from the exporter's `needed` list. Delete no
  cell and wire no column in.
- **Accept:** `tools/audit.py --strict` prints no findings; check and tests green; grep shows no
  player-facing "Overdrive", "Airburst", "freez", "chill" or "enemies" strings (internal
  names excepted).

### T7b. Tower and dino silhouettes (visual only) — 🦖
- **Goal:** towers read by shape, not just colour (DECISIONS #26).
- **Files:** `TowerLook.build`: one block silhouette per key, in real materials, inside the
  3×3 footprint (anchored, CanCollide/CanQuery off), per `DINO_REVIEW.md` "TowerLook". The
  keys are Hunting Blind, Longshot Perch, Mortar Pit, Tranq Station and Supply Camp; the
  HOSPITAL and ARMORY looks come with T14/T15, and the Field Hospital gets a green "+", never a
  red cross. **The crown at stage 1 and the glow at stage 2 stay**; a trophy accent may be
  added next to them. Placement ghost still works (it uses the same `build`). `DinoLook`:
  Gallimimus head on top of its neck, a Raptor back stripe and crest, T-Rex teeth, the
  Pteranodon crest pointing backward.
- **Accept:** check clean; no change to `Placement`/`Track.TowerRadius`; the prompt and range
  ring still attach to the body part that `Shop.decorate` uses.

---

## Part B — Step 2: the dinos fight back

### T8. Shared combat rules + player health
- **Goal:** players have 100 HP, heal 25 per round cleared, and resistance math exists.
- **Spreadsheet (Tuning, new rows below 65, section PLAYER HEALTH / COMBAT):** Player max
  health 100; Heal per round 25; Spawn protection (s) 3; Max resist % 60; Max projectiles
  80; Tower HP per tier 0.15; Repair cost 0.3. Add them to the exporter's `needed` list.
- **Files:** new `src/shared/Combat.luau` (pure): `attackDamage(base, size, sizes,
  difficultyMult)`, `combineResist(list)` (strongest wins, capped),
  `towerMaxHp(def, pathTiers, auraHpPercent)`, `repairCost(spent, hp, maxHp,
  discount)`. New `src/server/Health.luau`, the **only mutator of player HP**:
  `damage(player, amount)` applies resist through a hook, then `Humanoid:TakeDamage` (which
  respects ForceField); `heal(player, amount)`; `healAll(amount)`. Add an empty `Health` script
  in `src/starter/StarterCharacterScripts` (add the Rojo mapping) to remove Roblox regen.
  `Main`: MaxHealth on spawn, ForceField for Spawn protection, `Health.healAll(HealPerRound)` in
  `onRoundEnd`. `Hud`: an HP bar (bottom left) with a red flash on damage.
- **Accept:** Combat spec (size scaling, resist cap, repair cost at 0/50/100% HP, max HP
  at 0/3/7 tiers). ARCHITECTURE §4 gains "Player HP → Health".

### T9. Tower health and knock-out
- **Spreadsheet:** `Towers` column P **Max HP** (100/80/150/120/200). The exporter reads it as
  `maxHp` and validates > 0.
- **Files:** `Towers`: `hp`/`maxHp` on the tower; `Towers.damage(tower, amount, source)`
  (resist applied; `source` kept for future PvP); `Towers.heal`; KO at 0 → `knockedOut`.
  KO skips fire, chill, auras (`refreshAuras` on KO and revive), income and chests;
  `Towers.targets()` returns standing towers only. Upgrades raise hp by the max HP gained.
  `TowerLook.setKnockedOut(model, on)` (tilt, Slate, smoke, 2–3 Slate debris blocks, ring
  hidden, label **TRAMPLED**; DECISIONS #21. Player-facing text says "Trampled", never
  "knocked out" or "KO") and
  `TowerLook.setHealth(model, frac)` (billboard bar, hidden at full). `Shop.decorate`
  publishes `HP`/`MaxHP`/`KO` attributes. Studio-only **L** key (DECISIONS #11).
- **Accept:** check clean; spec on `TowerStats`/`Combat` for max HP; code trace that a KO'd
  Supply Camp pays nothing, a KO'd Signal Tower's aura disappears and comes back on revive.

### T10. Repair from the tower panel
- **Files:** `Shop`: action `"repair"` (proximity-checked; anyone can repair; price from
  `Combat.repairCost` using `spent[tower]` and the Logistics discount; pays first, then
  `Towers.repair`); refuses upgrading a KO'd tower with "Repair it first". Repair cost is
  **not** added to `spent` (a repair doesn't raise the sell refund). `Shop.client`: HP line
  and a "Repair — $X" row when damaged; red "Trampled — repair it" header when KO'd; the upgrade rows
  greyed with the reason.
- **Accept:** check clean; Pricing/Combat spec for repair; code trace of every refusal.

### T10b. Readable hero burn patch (small)
- **Goal:** Incendiary's burning ground is visible (DECISIONS #32).
- **Spreadsheet:** a new Tuning row below the last one: **Burn patch min reach** = 3
  (studs). Add it to the exporter's `needed` list.
- **Files:** `Hazards.burn`: `reach = math.max(reach, Config.Tuning.BurnPatchMinReach)`
  instead of the literal 1. No other change.
- **Accept:** Config diff is the one new Tuning line; the heroes spec still passes; a new
  assertion that Incendiary's patch reach is ≥ 3; check clean. No playtest claim.

### T10c. Readability touch-ups (visual only) — 🦖
- **Goal:** DECISIONS #33 (Dino review round 2: R3, R6–R9).
- **Files:** `TowerLook`: the Hunting Blind gets viewing slits on all four sides; the Longshot
  Perch gets a rail on all four sides and a shorter barrel angled up 30°; the Tranq Station
  darts get a flat fletching block at the bottom. `DinoLook`: `setSedated` puts the dart in the
  back (top of the body, tilted toward the tail); `setAsleep` sets billboard MaxDistance 80;
  the Pteranodon crest sits at offset (0, 0.7, -0.9), size (0.2, 0.3, 1.0), tilted up about 20°.
  **Don't touch the crown or the stage-2 glow** (R5 rejected; R4 waits for Jovan).
- **Accept:** the looks spec is extended (footprint, anchoring, dart present from the top,
  MaxDistance) and green; check clean. No playtest claim.

### T11. Dino bites — 🦖
- **Spreadsheet:** `Enemies` columns O–R: Melee name, Melee damage, Melee every (s), Melee
  reach (studs) with DECISIONS #3 values (melee names from #2: Nip, Slash, Head-Butt, Tail
  Club, Kick, Gore, Chomp). `Difficulty` column J **Dino damage x** (1 /
  1.25 / 1.6 / 2.2). Exporter: read, validate (damage > 0 ⇒ every and reach > 0).
- **Files:** new `src/server/DinoAttacks.luau` (reads `Enemies.getLive()`, keeps its own
  per-enemy timers keyed by id; never mutates enemies). Each frame in `Playing`: for each
  dino whose melee is ready, not stunned and not disarmed, bite the nearest target
  (standing tower or living in-match player) within reach (horizontal), for damage ×
  size/sizes × Dino damage x. The random initial phase and slow-stretched cooldown follow
  DECISIONS #6. `Enemies` gains `isStunned`, `disarm(enemy, seconds, affectsBosses)` and
  `isDisarmed` (it owns that state). Bite visual: a short red flash at the target
  (Effects). Wired in `Main`'s Heartbeat after `Towers.step`.
- **Accept:** check clean; spec for target choice (nearest, ignores KO/dead) using a pure
  `Combat.pickTarget(point, candidates, reach)`.

### T11b. Damaged towers sell for less (tiny)
- **Goal:** DECISIONS #35: repairing is never worse than selling and rebuying.
- **Files:** `Pricing.sellRefund(spent, auraRefund, repairPrice)` returns
  `max(0, floor(spent × rate) − repairPrice)`, where `repairPrice` is `Combat.repairCost` for the
  tower's current HP (0 at full). `Shop.sell` and the `Shop.client` sell row pass it. The panel's
  sell text shows the reduced refund.
- **Accept:** a pricing spec shows, for refund rates 0.7, 0.9 and 1.0, that (spent − refund)
  ≥ the repair price for a trampled tower and for a half-damaged one, and that a full-HP refund is
  unchanged; check clean; no spreadsheet change.

### T12. Dino ranged attacks (projectiles) — 🦖
- **Spreadsheet:** `Enemies` columns S–X: Ranged name, Ranged damage, Ranged every (s),
  Ranged reach, Projectile speed, Impact radius (DECISIONS #3). Ranged names per #25: Skull
  Toss, Spike Flick, Gravel Spray, Stone Drop, Horn Toss, Bone Spit. Validate damage > 0 ⇒
  others > 0.
- **Files:** `DinoAttacks`: projectiles as data `{from, to, speed, damage, radius, t}`,
  stepped each frame. They land at the launch-time target point and damage every player and
  standing tower within radius (DECISIONS #5), capped at Max projectiles. Visual (DECISIONS #26):
  a **ground warning ring** at the landing point for the whole flight, sized to the impact
  radius (orange Neon, 0.6 transparency). The projectile shape comes from `DinoLook` per attack
  (visual only): Skull Toss / Stone Drop / Horn Toss are a Slate ball in Rock material; Spike
  Flick is a bone-white wedge; Gravel Spray is 3 brown pebbles; Bone Spit is a bone-white
  capsule. Moved by the server or tweened.
  Cleared on board reset.
- **Accept:** check clean; spec for `Combat.landingHits` (inside/outside radius, KO'd
  towers skipped); a note estimating how many projectiles fly in round 40 against the cap.

### T12b. Round-3 touch-ups (visual/wording only) — 🦖
- **Goal:** DECISIONS #36 and #38.
- **Files:** `TowerLook.setKnockedOut`: the smoke becomes dust (RGB 150,125,90, Opacity 0.2,
  RiseVelocity 1.5), and the tilt axis is picked from the base position (still 15°). `Hud` and
  `TowerLook` share one orange low-HP colour (e.g. export `LOW_HP_COLOR` from TowerLook, or a
  tiny shared visual constant). `Shop.decorate`: prompt ActionText "Upgrade", or
  "Upgrade / Repair" while hp < maxHp (it updates when HP changes; Towers already publishes
  HP). `tools/audit.py` allowlist: `Enemies.meleeName` and `Enemies.rangedName` (display text
  kept for later).
- **Accept:** looks spec updated (dust colour, tilt differs for two positions, one low colour);
  audit --strict clean apart from anything T12 still owes; check clean.

### T13. Threat estimate — does a sensible defence survive Easy?
- **Files:** new `tools/threat.py` (run by `tools/test.sh`, report only): from Track geometry and
  the Rounds/Enemies sheets, it estimates the bite and projectile damage per round to a tower 1
  stud off the lane, at the midpoint between lanes (15 studs), and at an inside corner, on Easy.
  It assumes a dino at full size for its first lane, halving after. It prints the per-round
  totals and the rounds where a mid-gap tower of each type would be KO'd.
- **Target:** on Easy, a mid-gap tower is never knocked out by bites, and ranged damage
  per round stays below ~50% of a T0 tower's max HP until round 30. Tune the Enemies attack
  cells (not code) until it does, and log the final numbers as DECISIONS rows.
- **Accept:** the report is in the commit message; the Config diff is accounted for.

### T14. Armory — 🦖
- **Spreadsheet:** `Towers` rows for Field Hospital and Armory come in this task and T15.
  **Move `Cost per DPS` (A11:D11, `C11 = C5/G5`) from row 11 down to row 13 first**, and
  rewrite the 40 `Balance Check` formulas D5:D44 that reference `'Towers'!$C$11` to `$C$13`.
  This was verified: those 40 are the only references to Towers rows 10–13 in the workbook.
  Re-assert that before writing. New Towers columns Q **Heal /s**, R **Resist %**. Armory row 11: 600,
  range 15, hits air No, HP 250, resist 15, unlock 150, key ARMORY. `Tower Upgrades`: 15 rows
  appended with cost formulas copied from the Supply Camp pattern (pointing at
  `'Towers'!$C$11`) and names per DECISIONS #16 as renamed by #25 (Hand Loads, Piercing Rounds, Master
  Gunsmith, Recoil Pads). Silhouette: dark Wood back wall, gun rack, Metal plate. New columns: Resist %, Thorns damage, Stuns
  biters (s), Hunter recoil x, Hunter reload x, Hunter spread x, Hunter fire rate %; Gunsmith
  uses the existing aura columns. Add ARMORY to `ShopRules.Unreleased` until this task lands,
  then remove it.
- **Files:** `TowerStats` (new fields), `Towers` (resist aura on towers; `Towers.resistAt(position)`
  for `Health`; thorns and biter-stun via a `DinoAttacks` hook → `Enemies.damage`/`stun`,
  credited to the owner), `Hero` + `HeroStats` (Outfitter buffs published as player
  attributes so the client fire loop agrees), `TowerLook` (model), `Shop.client`
  (`describeAbilities` in plain words), `UPGRADES.md` section.
- **Accept:** exporter clean; audit clean (names, unlock ladder, no dead columns); spec per
  tier claim; check clean.

### T15. Field Hospital — 🦖
- **Spreadsheet:** Towers row 10: 450, range 15, HP 150, heal 3, unlock 100, key HOSPITAL.
  15 Tower Upgrades rows (DECISIONS #15, renamed by #25: path **Rescue**, Camp
  Rations). Silhouette: white canvas tent with a green "+". New columns: Heal x, Revives, Revive speed x, Med
  kits, Med kit heal, Rescue beacon, Aura HP %, Last stand.
- **Files:** `Towers` (heal standing towers and players in range each frame via
  `Towers.heal`/`Health.heal`; revive; the Aura HP % feeds `Combat.towerMaxHp`; Last Stand
  once per round), `Airdrops` (a heal kit kind next to the cash chest), `Main` (Rescue
  Beacon respawn point and half respawn time), `TowerLook`, `Shop.client`, `UPGRADES.md`.
- **Accept:** as T14.

### T16. Field Medic hero — 🦖
- **Spreadsheet:** `Heroes` row 8 MEDIC (DECISIONS #13); ability kind HEAL. 15 `Hero
  Upgrades` rows (DECISIONS #14, renamed by #25: path **Muzzle**, Double Dose, Belt
  Pouch, Triage Tent). The Jaw Lock look is a snout strap (`DinoLook`). New columns: Heal x, Heal radius x, Heal repairs towers,
  Guard %, Guard (s), Slow on hit %, Slow on hit (s), Jaw lock (s), Jaw lock spread
  (studs). Exporter: accept HEAL; the hero-vs-tower check still passes.
- **Files:** `HeroStats` (new fields), `Hero` (HEAL ability: `Health.heal` in radius;
  Patch Up → `Towers.heal`; Second Wind guard → a resist source for `Health` and `Towers`;
  on-hit slow via `Enemies.chill`; Jaw Lock via `Enemies.disarm`, half for bosses), `Hero`
  tool/gun colour, `Shop.client` (hero select lists 4; plain-words descriptions),
  `HEROES.md` section.
- **Accept:** exporter clean; audit clean; HeroStats spec per tier claim; check clean.

### T17. Docs and recap
- `CLAUDE.md` status (Step 2 and polish: statically checked and headless-tested, not
  playtested), `ARCHITECTURE.md` (layout, §4 ownership: Health, DinoAttacks, tower HP in
  Towers; the phase table row "Step 2"), `VISION.md` ("Towers with HP" ✅; Step 2 no longer
  "planned"), `UPGRADES.md`/`HEROES.md` status keys. 🦖 final wording pass. The recap
  includes the DECISIONS #27 "ask Jovan" rename list, so he can approve it in one go.
- The Director writes the recap for Jovan: what changed, what to try in Studio first (L
  key, a round-11 Pachy wave near lane-hugging towers, repair, Medic heal, Armory resist),
  and which numbers are seeds.

**Stop here. Phase 7 (team battle, battle royale, buy-ins, per-team cash) is out of scope.**
