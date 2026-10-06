# Plan — Round 4: Jovan's answers (Director, 2026-10-02)

Scope (Jovan, 2026-10-02; his words in `DIRECTION.md` "Round-4 answers", `GAUNTLET.md`
"Round 4 scope"). Cheap, independent work first (renames, Linebreaker, UI, Hard cash, boss
throws), big systems after (one health pool + pierce-through with model updates, Chaos,
mastery small perks, hero tier 6, overall player level + cosmetics + titles + level
leaderboard). The next tower batch is **not built**: `TOWERS_NEXT.md` is a proposal for
Jovan to pick from. Design calls: `DECISIONS.md` #118–#142. **T31 + T38 (the Studio
playtest) stay open**; T60 adds round 4's steps. **Stop before phase 7** and append a
round-4 recap to `RECAP.md` (T61).

Round 1–3 rules hold (one task = one commit, pushed; `tools/check.sh`,
`export_constants.py`, `tools/test.sh` green; diff `Config.luau` after every sheet change
and account for every line; openpyxl only, assert a cell is empty or the one you mean before
writing; append rows/columns, never insert; "statically checked + headless tests, not
playtested"; 🦖 = Dino agent reviews; player-facing text says **take-downs**, never "pop").
For this round:

- **New Tuning levers go below row 95** (row 96 blank, then a header per block named in the
  task; assert each cell empty). New sheet columns go in the **first empty column** of that
  sheet (assert the header cell is empty), never between existing ones.
- Internal keys never change (`SCOUT`, `pops`, `QUARTERMASTER`…). Renames are display text
  and sheet `Name` cells only.
- **Fresh Builder per batch.** Batches, in order:

| Batch | Tasks | What |
|---|---|---|
| 1 | T40, T41, T42 | renames; Linebreaker ×2 over T4 + Dragon's Breath 3 studs confirmed; Hard starting cash |
| 2 | T43, T44 | home row (bigger PLAY), Amber on the Hunt Board, XP line; softer boss throws vs towers |
| — | T45 🦖 | review batches 1–2 |
| 3 | T46, T47, T48 | one health pool + pierce-through; models count overkill honestly; set the break seeds |
| — | T45b | Dino round 12 string fixes (after batch 3; small, own Builder or batch 4's first commit) |
| 4 | T49, T50, T51 | boss health bar with notches; Chaos = gun skill; mastery small perks |
| 5 | T52, T53 | hero tier 6 (12 tiers): sheet + mechanics; panel, crossover, models |
| — | T54 🦖 | tier-6 names, small-perk names, pierce-through and Chaos wording |
| 6 | T55, T56 | player level rule + levers; banking at match end, saving, solo take-down boost |
| 7 | T57, T58 | cosmetics + titles + Profile screen; level leaderboard + showing off |
| — | T59 🦖, T60 Tester | player-level names review; Studio steps (waits on Jovan's MCP switch) |
| — | T62 🦖 | naming pass for the four approved towers (before any build) |
| 8 | T63, T64 | shared tower groundwork (can't-be-damaged, on-track placement, sheet rows); Storm Coil |
| 9 | T65, T66 | Falcon Roost; Harpoon Ballista |
| 10 | T67, T68 | Tar Pit; unlock screen + balance pass for all four |
| — | T69 🦖, T70 Tester, T61 Director (last) | review of the towers; Studio steps; docs + recap |

**Batch 1 done (2026-10-02):** T40 befac6a, T41 61b77b4, T42 1b66379 (247 specs, audit 0,
threat 0). Follow-ups: Hard starting cash → **850** (#143; 810 if Hard ≥ Normal in rounds
1–15), one sheet cell for batch 2's Builder; Eye in the Sky's DEAD flag waits for T48
(#144); no Fence text on the result screen (#145).

**Batch 2 done (2026-10-02):** T42 follow-up 8f27f43 (Hard 850; Hard < Normal every round
1–15, closest round 11 0.66 vs 0.81; Hard solo floor 0.66 ≥ 0.65), T43 dd94629, T44 1caf71b
(lever 0.3: boss-only max r31–39 44.1 < 50; 0.4 → 58.9, 0.5 → 73.6) — #155, #156. T45 and
T62 reviewed (DINO_REVIEW Round 12): rulings #157–#159; string fixes → **T45b**.

## The design in one place

### One health pool and pierce-through (DECISIONS #125–#129)

**Pool.** A dino has **one HP pool** = its species' total HP (Scaled HP × round HP ×
difficulty, as today). Its sizes are **thresholds** on that pool, evenly spaced: with
`sizes` = s and share = pool ÷ s, the dino is size k while HP is in ((k−1)·share, k·share].
Crossing a threshold shrinks it one size and pays like today (cash + one Bone + bounty
counts unchanged), so **a dino still pays exactly what it pays today** however it dies.

**Breaks.** Each hit has **breaks** b ≥ 1 = the most thresholds it may cross. The hit's
damage (after mark and brittle, as today) lowers the pool, but never below
(k − b)·share, where k is the size when the hit lands; the rest of the damage is lost. If
k − b ≤ 0 and the damage reaches 0 HP, the dino dies. **With b = 1 this is exactly today's
rule** (overflow lost, the next size starts full), so every non-raw tower is unchanged.

b = min(`Max size breaks` 4, max(1, base + level bonus − resist)):

- **base** = the tier's `Size breaks` (new column on `Tower Upgrades` and `Hero Upgrades`,
  cumulative per tier like the others; blank = 1).
- **level bonus** = floor((tower level − 1) ÷ `Break level step` 3) — +1 at tower level 4
  (rounds 16–30), +2 at level 7 (rounds 31–40) — **only when base ≥ 2** (only raw-damage
  tiers grow with level). Heroes get no level bonus (hero levels already add 25% each).
- **resist** = the species' `Break resist` (new column on `Enemies`).

| Raw-damage tier (seed) | Size breaks |
|---|---|
| Longshot Perch · Deadeye T4 Tungsten Core / T5 Linebreaker | 2 / 3 |
| Longshot Perch · Big Bore (was Siege) T2 Bone Breaker / T4 Punt Gun / T5 Extinction Round | 2 / 3 / 4 |
| Hunting Blind · Hardliner T4 Railshot / T5 Hide Buster | 2 / 2 |
| Brush Beater · Slug T6 (new) / Tracker · Marksman T6 (new) | 2 / 2 |
| everything else | 1 |

| Species | Compy | Raptor | Pachy | Ankylosaurus | Gallimimus | Pteranodon | Triceratops | T-Rex |
|---|---|---|---|---|---|---|---|---|
| Sizes | 1 | 2 | 3 | 3 | 3 | 3 | 4 | 5 |
| Break resist | 0 | 0 | 0 | 1 | 0 | 0 | 1 | 2 |

Examples: Railshot in round 10 vs a Raptor → 2 (the whole dino, if the damage is there).
Linebreaker at tower level 4 vs Pachys → 3 + 1 = 4 → every dino in the line can drop all
three sizes. Extinction Round at level 7 vs the T-Rex → 4 + 2 − 2 = 4 (one shot can take
four of its five sizes); vs a Triceratops → min(4, 5) = 4. Heart Shot vs an Ankylosaurus
→ 2 − 1 = 1.

**What breaks 1, always:** splash and bomblets (every target), burn ticks and burning
ground (Napalm, Dragon's Breath, Smoulder, Incendiary), thorns, Barbed Darts and freeze
damage, ricochet and Chain Shot bounces, Flare Strike. **Line pierce** (Railshot, Deadeye,
Railslug): every dino in the line gets the shot's b. Marks and brittle raise the damage, not
b. A hunter's gun breaks 1 except the two tier-6 precision rounds above.

**Seen on screen:** dinos keep shrinking as today (one redress per hit, however many sizes
it dropped). Bosses (Triceratops, T-Rex) get a thin health bar over the head showing the
whole pool with a notch at every threshold (T49). Small dinos get no bar (clean UI).

**Models.** Today's models count every point of damage (no overkill), which flatters big
single hits. `value.py` gains an **overkill factor**: per species in a band's mix, a hit of
damage D lands min(D, b · share) where share is that species' size HP at the band's round
HP; direct damage is multiplied by the mix-weighted factor. `threat.py` is unchanged (it
assumes nobody kills anything) and says so. T48 then sets the break seeds so the raw-damage
paths get back what honest overkill takes away, not more.

### Overall player level (DECISIONS #118–#124)

Working name **player level** (on screen 🦖, never "Lv N", which is the in-match hunter
level).

- **Player XP from a match** = the hero XP you banked on every cleared round of that match
  (100 + the take-down bonus, as `Shared/HeroXp` banks it, counted before the level clamp)
  + a **clear bonus** if the track is cleared: Easy 500 / Normal 1,000 / Hard 1,500 /
  Chaos 2,000 (10× the Amber clear reward; new `Difficulty` column). It is **added when
  the match ends**, won or lost, for every hunter in the match at the end. Leaving early
  banks nothing (Jovan: count at the end, entice finishing).
- **Solo take-down boost** (DECISIONS #124): in a solo match the take-down part of Player
  XP is ×`Solo take-down XP x` 2 (so up to 30 a round, not 15). It does **not** touch the
  in-match hunter level (the models and the lead cap stay valid). Co-op is unchanged.
- **Curve, infinite:** level n → n+1 costs `Player XP base` 500 + `Player XP step` 50 ×
  (n−1), at most `Player XP per level max` 10,000 (from level 191). Total to reach level n
  = 500(n−1) + 25(n−1)(n−2) (until the cap): **L10 6,300 · L50 83,300 · L100 292,050 ·
  L150 625,800 · L200 ≈ 1.08 M**.
- **Pace:** a solo Easy full clear ≈ 4,000 + 1,200 + 500 = 5,700 XP (co-op ≈ 5,100). The
  first full clear reaches about level 9; level 100 ≈ 51 solo Easy clears; level 200 ≈ 190.
- **Rewards (cosmetics and titles only, never gameplay):**

| Levels | Reward | Count |
|---|---|---|
| 2–99, not a multiple of 10 | one **common** cosmetic each level, rotating: name colour, gun tint, tracer colour, crosshair colour, tower flag, leaderboard banner | 89 |
| 10, 20 … 100 | **rare**: a **title** + a nicer cosmetic (hunting hat, gun pattern/material, hit-marker, sprint trail) | 10 |
| 150, 200 | **legendary**: an animated set (e.g. fossil-bone tower trims, amber-glow gun, amber trail) + a title | 2 |
| 250, 300 … (forever) | a title every 50 levels | ∞ |

  The level badge frame changes by band (1–49, 50–99, 100–149, 150–199, 200+) for free.
  Gold stays mastery 20's alone. Unlocks are **derived from the level** (no inventory);
  only XP and what's equipped are saved.
- **Saving:** `Progression`'s existing path (offline status when unpublished; a failed load
  never overwrites a save; the Studio J key turns saving off).
- **Leaderboard:** top 50 by Player XP from an OrderedDataStore when published, cached and
  refreshed every 60 s; your own row always shown. Unpublished, Studio, or any DataStore
  failure → a "This server" board of the hunters present with one line: "The world board
  goes live when the game is published." It never errors, blocks or traps.

### Hero tier 6 (DECISIONS #133–#134)

Every hero path gets a **sixth tier** (12 tiers), handling and fire-mode, not raw damage.
Cost = `Hero upgrade base cost` 200 × growth 2^5 = **6,400** (the ladder continues).
Crossover rule unchanged in words: two paths at most, only one past tier 2; tier 6 needs
tier 5 on the same path. Max build **6/2/0** (6/3/0 at mastery 20). Working names, 🦖 in T54.

| Hero | Path | Tier 6 (working name): effect |
|---|---|---|
| Tracker | Gunslinger | *Hot Swap*: the two guns reload one at a time, so firing never stops; reload ×0.8 |
| Tracker | Marksman | *Heart Shot*: scoped shots have no spread and **break 2 sizes** (scoped only, #170) |
| Tracker | Trick Shot | *Bounce Back*: each ricochet take-down puts a round back in the cylinder; ricochets prefer dinos not yet hit |
| Big Game Hunter | Stalker (was Tactical) | *Big Five*: bursts of 5 with Precision Burst's grouping; recoil resets between bursts |
| Big Game Hunter | Heavy | *Endless Belt*: no reloading while fully spun up (Belt Fed's rule without Rally Cry) |
| Big Game Hunter | Special Ammo | *Dynamite Rounds*: Explosive Tips' splash radius ×1.5 (armour-pierce already from AP Rounds, #171) |
| Brush Beater | Slug | *Thunder Slug*: slugs **break 2 sizes**; no spread while standing still |
| Brush Beater | Buckshot | *Wildfire Drum*: Dragon's Breath's burning ground **4 studs** wide (from 3); the drum holds +50% shells |
| Brush Beater | Point Blank (was Breacher) | *Quad Barrel*: four blasts per trigger (from two); reload ×1.25 longer |
| Field Medic | Triage | *Rapid Response*: Triage Kit holds 2 charges |
| Field Medic | Lever Action | *Bottomless Tube*: magazine +50%, reload ×0.5 |
| Field Medic | Muzzle | *Lights Out*: Jaw Lock lasts 4s (from 3) and spreads within 9 studs (from 6); bosses still half |

### Mastery small perks (DECISIONS #135)

Same ladder for every hero (it applies while you play that hero); four non-damage lines, three
steps each. New `Mastery` columns; nothing touches damage, fire rate, reload, recoil,
spread, max HP or move speed.

| Line | Step 1 | Step 2 | Step 3 |
|---|---|---|---|
| Pick-up reach (chests, med kits) | 6: +2 studs | 11: +4 | 16: +6 |
| Round-clear heal (25 today) | 7: +5 | 12: +10 | 17: +15 |
| Respawn time (3s today) | 8: −10% | 13: −20% | 18: −30% |
| Repair cost (towers you repair) | 9: −5% | 14: −10% | 19: −15% |

### Difficulty (DECISIONS #136–#137)

- **Hard: more starting cash.** New `Difficulty` column `Starting cash`: Easy / Normal /
  Chaos 450, **Hard 650** (seed; T42 confirms it with the model). `Cash x` unchanged, so
  Hard still pays less per dino.
- **Chaos: gun skill.** New `Difficulty` columns `Tower damage x` (Chaos **0.6**, others 1)
  and `Hero damage x` (Chaos **1.5**, others 1). Towers alone can't hold Chaos; a hunter who
  hits their shots nearly can. The hero-vs-tower rule still holds in Chaos (top hero 206 ×
  1.5 = 309 < best tower 751 × 0.6 = 451). T50 tunes the two seeds to the model's bars.

---

## Batch 1 — cheap and independent

### T40. Renames (DECISIONS #130)
- **Do:** display text and sheet `Name` cells only. Lives → **Fence** (HUD, result screen,
  docs); leaderboard Pops → **Bones** (column header, "Most bones wins", docs; the text
  elsewhere still says take-downs); Care Package → **Chopper Drop**; Command Center →
  **Base Camp**; Forward Base → **Forward Camp**; Longshot path Siege → **Big Bore**,
  Anti-Materiel → **Bone Breaker**, Siege Gun → **Punt Gun**; Tactical Spotter → **Game
  Spotter**; Big Game Hunter path Tactical → **Stalker**; Brush Beater path Breacher →
  **Point Blank**, Street Sweeper → **Thicket Sweeper**; role Ordnance → **Close range**;
  Hibernation → **Deep Sleep**. Update UPGRADES.md, HEROES.md, VISION.md (battle royale:
  most Bones), Bounties/Hunt Board text that names any of these, and every player-facing
  string (grep `src/` for each old name, case-insensitive).
- **Accept:** `grep -ri` for each old name in `src/` and the three design docs returns only
  internal keys/comments you list in the commit message; `audit.py --strict` 0 (its
  name-collision check passes: no two tiers, perks or abilities share a name); Config diff =
  only `name`/label lines; 245+ specs green.

### T41. Linebreaker ×2 over tier 4; Dragon's Breath 3 studs confirmed (#131, #132)
- **Do:** Longshot Perch Deadeye T5 `Damage x` 6.41 → **8.84** (= 2 × Tungsten Core 4.42;
  assert the old value). `Burn patch min reach` stays **3** (Jovan approved #37). Add a spec
  that a Dragon's Breath ground patch is 3 studs wide.
- **Accept:** Config diff = one line; `value.py` re-run: report Linebreaker's peak and eDPS
  per band and confirm the hero-vs-tower guard still passes (the best tower may change);
  any new finding goes to the Director, not fixed.

### T42. Starting cash per difficulty (#136) — DONE (1b66379 + 8f27f43, Hard 850, #143/#156)
- **Do:** `Difficulty` first empty column header `Starting cash`: Easy 450, Normal 450,
  Hard **650**, Chaos 450. Exporter emits it per difficulty; the code that seeds the pot
  reads it instead of `Tuning` → `Starting cash` (keep the Tuning cell as the documented
  default the exporter checks Easy against; `Starting cash per extra player` unchanged).
  `value.py` pacing uses it.
- **Accept:** Config diff = the new field ×4; spec: Hard match starts with 650 (+200 per
  extra player). `value.py` report: Hard solo **floor over rounds 11–39 ≥ 0.65** (was
  0.59) **and Hard < Normal at every round 1–15** (harder stays harder). If 650 can't meet
  both, try 600 and 700 and report all three; the Director picks.

## Batch 2 — UI and boss throws

### T43. Home row, Amber on the Hunt Board, XP line (#138)
- **Do:** (1) Home screen: Hunt Board moves to **its own row above** the action row; the
  action row becomes Choose hero 200, Unlocks & Mastery 240, **PLAY 240 wide, 28 px text**
  (was 142 / 24 px), its colour kept. (2) Hunt Board header shows the Amber balance
  ("{N} Amber", live) beside the title; the "+15 Amber" float stays. (3) HUD: "+{N} on round
  clear" moves to **its own line** under the XP bar, same width as the bar, readable size.
- **Accept:** layout fits a 740 px column with no wrap at the smallest supported window
  (#96 rules); `panelrules.spec.luau` green; no new Modal/input sink; the no-trap rules hold
  (close with key and X). Commit message lists the measured or computed text sizes.

### T44. Softer boss throws vs towers (#138) — DONE (1caf71b, lever 0.3, #156)
- **Do:** Tuning block `BOSS THROWS`, lever `Boss ranged vs towers x` **0.5**: a Boss
  species' projectile damage to a **tower** is multiplied by it (hunters unchanged: they can
  dodge; Horn Toss's look and ring are unchanged, #40). `threat.py` reads it and now judges
  **rounds 31–39** with the 11–30 target (defended mid-gap < 50% of T0 max HP, every tower
  but the Perch); round 40 (T-Rex) stays report-only.
- **Accept:** `threat.py` 0 with 31–39 included. If 0.5 misses, step down by 0.1 to at
  least 0.3 and report; below that, stop and report. Spec: a boss projectile on a tower deals
  ×0.5, on a hunter ×1.
- **T44 (revised, #154 — replaces the two bullets above):** the first run showed that rounds
  31–39 miss the old target even with boss throws at 0 (other dinos alone: 47–65 against a
  Hunting Blind), so the target now measures **what Jovan asked about: the boss throws**.
  - `threat.py` splits each round's mid-gap defended damage into **boss** (Triceratops /
    T-Rex projectiles, × the lever) and **other**, rounds 31–39. **New target: boss-only
    defended damage per round < 50% of T0 max HP for every tower type except the Perch**
    (Hunting Blind 100 is the binding one: boss share < 50). Totals and "other" stay
    report-only for 31–40, as #44 had it. Rounds 11–30's target is unchanged.
  - `Boss ranged vs towers x` (Tuning, `BOSS THROWS`): the **highest of 0.5 / 0.4 / 0.3**
    that meets the new target; below 0.3, stop and report. No other cell changes.
  - **Accept:** `threat.py` 0 with the new target; its output lists, per round 31–39, boss /
    other / total for the Hunting Blind; spec: a boss projectile on a tower deals × the lever,
    on a hunter ×1; Config diff = one Tuning line.

### T45. 🦖 Dino review of batches 1–2 — DONE (DINO_REVIEW Round 12; #157–#158; fixes in T45b)
Bones beside Bone Breaker, Bone Broth and Bone Spit (clash?), Big Bore, Fence wording in the
HUD and result screen, the Hunt Board Amber line, the XP line. Must-fixes go to the Director.

### T45b. Dino round 12 string fixes (#157, #158) — runs after batch 3 (T46–T48)
Display text only; no sheet, Config, Enemies or Combat change. One commit.
- `src/shared/Theme.luau`: add fields `Fence = "Fence"` and `Bones = "Bones"` beside
  `Currency = "Amber"`, each with a short comment (#130).
- `src/client/Hud.client.luau` (line numbers as of 1caf71b; re-grep after batch 3):
  - ~229 `+{pending} on round clear` → **`+{pending} bonus on round clear`** (revises #117).
  - ~244 / ~246 `Fence {lives}` → `{Theme.Fence} {lives}` (same text on screen).
  - ~238 loss branch only: `Reached round {round} on {difficultyName}` → **`The fence fell on
    round {round} ({difficultyName})`**. First confirm a loss is reached only when the
    fence's lives hit 0 (grep where the match ends); if anything else can end a match as a
    loss, keep the old string and say so. The victory string is unchanged.
- `src/server/Scoreboard.luau:22` `value.Name = "Bones"` → `Theme.Bones` (require Theme from
  ReplicatedStorage the way other server modules do).
- `src/shared/Modes.luau:15` `Most bones wins.` → **`Most Bones wins.`**, built from `Theme.Bones`.
- **Accept:** `tools/check.sh`, `export_constants.py` (Config diff empty), `tools/test.sh`
  green; a grep of `src` for `"Fence`, `"Bones`, `Most bones` and `on round clear` shows only
  Theme.luau and the bonus line; the commit message gives the computed text size of the bonus
  line in the 420 px strip (#155) and of the loss line at size 18 in the results box, and
  whether either wraps or shrinks (the loss line must not wrap at the smallest window, #96; if
  it does, keep the old loss string). "Not playtested." The bonus line's measured size stays on
  T38's Tester step 3.

## Batch 3 — one health pool and pierce-through

### T46. Pool + breaks in play (#125–#127)
- **Sheet:** `Tower Upgrades` and `Hero Upgrades` first empty column `Size breaks` (seeds in
  the table above; blank = 1); `Enemies` first empty column `Break resist` (table above);
  Tuning block `PIERCE-THROUGH`: `Break level step` 3, `Max size breaks` 4. Exporter
  refuses a break below 1, a break on a tier whose path isn't listed in the design table
  (audit rule, so new ones are a Director call), or resist < 0.
- **New `Shared/SizeBreaks`** (pure): `breaks(base, towerLevel, resist, isHero)` and
  `apply(hp, share, sizes, amount, b)` → new hp, sizes dropped, dead.
- **`Enemies`:** the dino holds one pool (`hp` = pool, `share`); `size` = ceil(hp ÷ share).
  `Enemies.damage(enemy, amount, piercesArmor, breaks?)` (default 1) calls `apply`;
  `onKilled` fires **once per size dropped** (cash + Bone each), one `dress` per hit;
  `leakCost` unchanged in meaning. Callers: `Towers` passes the tier's breaks + tower
  level, per line-pierce target; `Hero` passes the hero tier's breaks; `Hazards`, splash,
  bomblets, bounces, thorns, Flare Strike pass nothing (1). Grep every reader of
  `enemy.hp`/`maxHp` (targeting "strongest", HP shares) and keep it correct.
- **Accept (headless, new `sizebreaks.spec.luau`):** b = 1 reproduces today's results on a
  table of cases (old rule written into the spec as the oracle); a 2-break hit with enough
  damage drops 2 sizes and pays 2 Bones + 2 × cash; a capped hit loses the rest; death only
  when allowed; resist and the cap; level bonus only when base ≥ 2; a dino's total cash and
  Bones are the same whatever kills it. All old specs green.

### T47. Models count overkill (#128)
- **Do:** `value.py` applies the overkill factor (design above) to direct damage, per
  species, using each tier's breaks at the band's tower level. Print, per tower path tier
  4–5 and per band, eDPS **before → after**. `threat.py`: one docstring line ("assumes no
  kills; pierce-through doesn't change it"). Report only: no number changes.
- **Accept:** spec or doctest for the factor (D ≤ share → 1; D = 3·share, b = 1 → 1/3;
  b = 3 → 1); the report pasted in the commit message for the Director.

### T48. Set the break seeds (#128)
- **Do (after the Director reads T47's report):** keep the seeds unless a bar below fails;
  adjust **breaks, never damage**, to meet them.
- **Bars:** each raw-damage tier's after-eDPS in bands 21–30 and 31–40 is within **−5% …
  +15%** of its before (zero-waste) number; `value.py` findings don't rise; #72's pacing
  floors hold; the hero-vs-tower guard passes; `threat.py` 0; findings no higher than the
  post-T41 baseline, and **Eye in the Sky's DEAD flag cleared or explained** (#144). Non-raw towers that lose more
  than 25% in a band are **reported, not changed** (the Director decides; Jovan's call if
  it's a big tower).
- **Accept:** Config diff = only `sizeBreaks`/`breakResist` lines; the final table in the
  commit message.

### T48 (revised). Set the break seeds against the honest model (#160–#163) — replaces T48 above
The −5% bar compared against the old zero-waste numbers, which the game never delivered
(b = 1 already loses overflow today). New baselines, all from `value.py` (overkill on, level
bonus inside the hit damage as T47 built it — #161):
**Z** = old zero-waste eDPS (T47's "before"); **B1** = honest eDPS with every break forced to 1
(today's real game; add a `--breaks1` flag); **S** = honest eDPS with the sheet's seeds.
- **Do:** keep the seeds (`Tower Upgrades` column `Size breaks`: Deadeye T4/T5 2/3, Big Bore
  T2/T4/T5 2/3/4, Hardliner T4/T5 2/2) unless a bar fails; then **raise breaks only**, +1 at a
  time, T5 before T4, never above `Max size breaks` 4; no damage, cost or resist changes.
  **One design-table addition:** Big Bore T1 Large Calibre `Size breaks` 2 (#162; add the row
  to the design table and the exporter's allowed list). If that makes Big Bore T2 DEAD or
  raises findings, set it back to blank and say so.
- **Bars, per raw tier (the 8 above + Big Bore T1) in bands 21–30 and 31–40** (T1: 11–20):
  1. **S ≥ 1.10 × B1** — pierce-through visibly adds to today's game.
  2. **S ≤ 1.15 × Z** — never more than the old flattering ceiling.
  3. **Raw is clearly better:** each raw T5 (Linebreaker, Extinction Round, Hide Buster) has S
     eDPS at or above the **median eDPS of all damage-path T5s** in that band (honest model).
  If a tier at breaks 4 still fails bar 1 or 3: **STOP, no commit, report** (that is the
  point where damage may change, Director's call). Bar 2 failing → lower that tier's breaks.
- **Also:** `value.py` findings ≤ **4** (the post-T47 set: Spotter T2, Spotter T4, Big Bore T1,
  Concussive T5 — #163; Big Bore T1 may clear, no new names); #72's pacing floors hold;
  hero-vs-tower guard passes; `threat.py` 0; audit strict 0; all specs green.
- **Accept:** Config diff = only `sizeBreaks` lines; commit message holds the table
  tier × band: Z, B1, S, S/B1, S/Z, the T5 median, and the findings list.

### T48 (final). Commit the seeds as they are (#164–#166) — replaces both T48s above
Checked by the Director against `value.py --breaks1` on 2026-10-02: with the bars below, the
**sheet's current seeds pass with zero changes**. No damage, cost, resist or break edits.
- **Sheet:** unchanged. Big Bore T1 `Size breaks` stays **blank** (#165).
- **Code:** finish the uncommitted `--breaks1` bar logic in `tools/value.py`:
  1. **Bar 1, only where overkill matters:** if Z/B1 ≥ 1.10, need S/B1 ≥ 1.10; else need
     S/Z ≥ 0.95 (breaks already recover it). Today: Hardliner T4, Big Bore T2, Big Bore T3 in
     r31–40 take the second branch (S/Z 1.00 / 1.00 / 0.99).
  2. **Bar 2:** S/Z ≤ 1.15 (unchanged; max today 1.00).
  3. **Bar 3, general raw T5s only:** Linebreaker and Hide Buster S ≥ the band's damage-path T5
     median (today 265/345 vs 196/289; 219/545 vs 196/289). **Extinction Round is a boss
     specialist: exempt from bar 3** (`BOSS_SPECIALIST` set, like `CONTROL_TIERS`); print its
     S, S/B1 and S/Z on a "boss specialist (report)" line, no gate.
  Exit 0 when all bars pass; the table keeps Z, B1, S, S/B1, S/Z and which branch of bar 1 ran.
- **Accept:** `value.py --breaks1` exits 0 on the current sheet; findings = exactly Spotter T2,
  Spotter T4, Big Bore T1, Concussive T5 (#163, #165); #72 pacing floors hold; hero guard
  passes; `threat.py` 0; audit strict 0; all specs green; no Config diff; commit message holds
  the table.

## Batch 4 — boss bar, Chaos, small perks

### T49. Boss health bar with notches (#129)
- **Do:** Triceratops and T-Rex only: a thin BillboardGui bar over the head, the whole pool,
  a notch at each threshold, drawn by `DinoLook` (visual-only values inline). No bar on other
  species. Updates on damage, hides at death.
- **Accept:** spec on the pure part (fill = hp ÷ pool; notch positions k ÷ sizes); no input
  capture; MaxDistance set so 10 players' worth of bars can't flood the screen.

### T50. Chaos = gun skill (#137)
- **Do:** `Difficulty` columns `Tower damage x` and `Hero damage x` (Chaos 0.6 / 1.5, others
  1 / 1); `TowerStats` and `HeroStats` apply them; the hero-vs-tower guard runs per
  difficulty. `value.py` adds a **Chaos skill report**: solo cash-to-required ratio with
  towers only, and with the hero's peak DPS × accuracy **0.5** (average) and **0.9**
  (skilled) added.
- **Bars:** towers only: floor over 11–39 **≤ 0.35**; average: below **0.7** before round 20;
  skilled: **≥ 0.85** through round 30 and a minimum over 31–40 **between 0.6 and 0.95**
  ("nearly impossible"). Tune within tower x 0.5–0.75 and hero x 1.25–1.75; if no pair meets
  all bars, report the closest and stop.
- **Accept:** Config diff = the new fields; guard passes on every difficulty; report in the
  commit message.

### T50 (final). Chaos levers at the seeds (#167–#169) — replaces T50 above
Checked by the Director against the Builder's 2026-10-02 Chaos run: the seeds pass these bars.
- **Levers:** `Difficulty` Chaos `Tower damage x` **0.6**, `Hero damage x` **1.5**; other
  difficulties 1 / 1. No tuning sweep.
- **Hero model:** keep "best hero's T5 peak at round level"; label it in the report as an
  **upper bound** (real heroes are weaker early, so Chaos is at least this hard).
- **Gated bars (exit 1 if broken):** towers only, lowest over 11–39 **≤ 0.35** (today 0.28);
  skilled aim (0.9), lowest through round 30 **≥ 0.85** (today 0.86); skilled, lowest over
  31–40 **≥ 0.40** (today 0.42; "nearly impossible"); guard holds on every difficulty
  (309 < 451).
- **Report only:** average aim (0.5) lowest over 1–19 (today 0.77) and the skilled minus
  average gap, printed beside each other.
- **Accept:** Config diff = the two new fields; report in the commit message; all specs, audit
  strict 0, threat 0.

### T51. Mastery small perks (#135)
- **Do:** `Mastery` first empty columns `Pick-up reach +`, `Heal per round +`, `Respawn x`,
  `Repair cost x` (cumulative per level, per the table; levels 1–5 blank/1). Wire: chests and
  med kits (`Airdrops`, hospital kits) use the reach; the round-clear heal, respawn time and
  repair price use the playing hero's mastery. Mastery screen: each level 6–9, 11–14, 16–19
  shows its perk in plain words (working names "Long Arms", "Field Dressing", "Quick
  Recovery", "Handyman" I–III; 🦖 T54).
- **Accept:** exporter refuses a perk column outside these four or non-monotone values;
  audit: no mastery column touches damage, fire rate, reload, recoil, spread, max HP or move
  speed; specs for each line at levels 5/6/11/16/19; the screen fits (no-trap rules).

## Batch 5 — hero tier 6

### T52. Twelve tier-6 rows + mechanics (#133–#134)
- **Do:** `Hero Upgrades`: append one tier-6 row per path (12), effect columns cumulative as
  today, `Size breaks` 2 on Marksman and Slug T6, a per-tier `Burn patch reach` (Buckshot T6
  = 4; others inherit 3). Cost formula extended to tier 6 (6,400). New mechanics: staggered
  dual reload (Hot Swap), ammo-on-ricochet-take-down (Trick Reload), burst count 5 + recoil
  reset (Five-Round Burst), no-reload-while-spun (Endless Belt), splash radius x + splash
  pierce (Powder Tips), still-spread 0 (Thunder Slug), drum +50% (Wildfire Drum), 4 blasts
  (Quad Barrel), 2 ability charges (Rapid Response), Jaw Lock 4s / 9 studs (Nightcap).
- **Accept:** per-hero specs that each tier 6 does what the table says; `audit.py` per-path
  check covers 6 tiers; Config diff accounted for.

### T53. Panel, crossover, models for 6 tiers (#133)
- **Do:** `Shared/Upgrades` crossover: tier 6 needs tier 5 on the same path; still one path
  past 2 (3 at mastery 20). Hero upgrade panel shows six tiers and fits every window (no-trap
  rules). Mastery discounts and the free first upgrade apply as today. `value.py` and the
  guard include tier 6; HEROES.md gains the column and the Rules line "six tiers".
- **Accept:** `upgrades.spec` for 6/2/0, 6/3/0 (mastery 20), refusing 6 without 5 and
  3/3/0; guard passes (hero at the highest level in play with tier 6 < best tower; if a tier 6
  breaks it, lower that tier's number, never a tower's); `value.py` findings don't rise.

### T53b. Heart Shot scoped-only + Dino round 13 names (#170, #174–#176) — after batch 6
Small run; touches no `Hud.client` (names reach the panel through Config). Overlap with the
batch-6 Builder: only `Main.server.luau` comments (l.273, l.428) — do T53b after batch 6 lands.
- **Heart Shot:** in `Hero` (the `breaks` line in the hit path, ~l.559) a Marksman T6 shot
  gets the gun's `Size breaks` only when fired scoped (the flag Heart Shot's no-spread rule
  reads); unscoped shots break 1. Thunder Slug unchanged (every slug).
- **Sheet `Hero Upgrades` col E (Name):** E67 `Bounce Back`, E68 `Big Five`, E70
  `Dynamite Rounds`, E75 `Bottomless Tube`, E76 `Lights Out`. E66 Heart Shot, E71 Thunder Slug
  unchanged.
- **Sheet `Mastery` col E:** E11/E16/E21 `First Aid I: heal 5 more HP when a round is cleared`
  / `First Aid II: heal 10 more HP when a round is cleared` / `First Aid III: heal 15 more HP
  when a round is cleared`; E12/E17/E22 `Back in Action I: respawn 10% sooner` / `Back in
  Action II: respawn 20% sooner` / `Back in Action III: respawn 30% sooner`. Long Arms and
  Handyman unchanged. Re-export `Config`.
- **Rename in comments and docs** (no logic keys use the names): `GunRules` l.14/15/81/89,
  `HeroStats` l.90/91, `export_constants.py` l.240/241, `Hero.luau` l.90/581/651,
  `Hero.client.luau` l.318, `Main.server.luau` l.273/428, `tiersix.spec.luau` test titles;
  `HEROES.md` path tables (l.106, 119, 121, 156, 157) and tier-6 lines (l.112, 126–127, 144),
  small perks (l.29–30); PLAN tier-6 table.
- **HEROES.md wording:** l.66–67 "per pop" → "per take-down" (both). Player-facing "break(s) 2
  sizes" → "shrink(s) a dino 2 sizes" (HEROES l.112 Heart Shot, l.144 Thunder Slug). Model and
  code text (PLAN, DECISIONS, `Size breaks`) keeps "breaks".
- **Accept:** spec: Heart Shot scoped vs a 3-size Pachy with enough damage drops 2 sizes,
  unscoped drops 1; Thunder Slug drops 2 either way. `grep -rn -E "Nightcap|Powder Tips|Trick
  Reload|Five-Round Burst|Tube Feed|Field Dressing|Quick Recovery" src tools HEROES.md
  UPGRADES.md` = 0; `grep -n "per pop" HEROES.md` = 0. Config diff = the 5 + 6 name strings
  only; all specs, audit strict 0, threat 0, guard passes.

### T54. 🦖 Dino review: tier-6 names, small-perk names, wording
The 12 tier-6 names and texts, the four small-perk lines, the boss bar look, any
pierce-through wording ("breaks 2 sizes"), the Chaos difficulty card text.

## Batch 6 — player level

### T55. `Shared/PlayerLevel` + levers (#118–#121)
- **Sheet:** Tuning block `PLAYER LEVEL`: `Player XP base` 500, `Player XP step` 50,
  `Player XP per level max` 10000, `Solo take-down XP x` 2; `Difficulty` column `Clear XP`
  (500 / 1000 / 1500 / 2000). Exporter checks Clear XP rises with difficulty.
- **New `Shared/PlayerLevel`** (pure): `level(xp)`, `xpFor(level)`, `progress(xp)`,
  `matchXp(bankedRoundXp, bankedTakedownXp, solo, cleared, difficulty)`,
  `rewardAt(level)` (reads the T57 sheet; until then returns the tier: common / rare /
  legendary / title / none per the table).
- **Accept (new `playerlevel.spec.luau`):** totals L10 6,300, L50 83,300, L100 292,050,
  L200 1,082,750 (cap from level 191); level is monotone and unbounded (level 10,000 computes); matchXp for a
  solo Easy clear of 40 rounds with capped take-downs = 5,700; co-op 5,100; a lost match
  gets no clear XP; rewardAt(10) rare, (37) common, (150) legendary, (250) title,
  (120) none.

### T56. Banking at match end, saving, solo boost (#119, #122, #124)
- **Do:** `Hero` records per hunter the round XP and take-down XP it banked this match
  (pre-clamp). At match end (`Main`, win or lose) `Progression.addPlayerXp(player, n)` for
  every hunter present; leavers get nothing. Solo = one hunter in the match at the end.
  `Profile` gains `playerXp` and `equipped` (title + one cosmetic per kind) with defaults and
  migration of old profiles; saved on the existing path (offline-safe). Result screen: "+N
  player XP" and a level-up line.
- **Accept:** specs: win/lose/leave cases, solo ×2 only on the take-down part, co-op
  unchanged, the in-match hunter level and `HeroXp` untouched (all heroxp specs green); an
  old profile loads with `playerXp` 0; a failed load never overwrites (existing spec still
  green).

## Batch 7 — rewards and showing off

### T57. Cosmetics, titles, Profile screen (#121, #123)
- **Sheet `Cosmetics`** (new): Level, Kind, Name, Rarity, Colour/Material/Pattern (data);
  rows for every reward level 2–200 and the title rule past 200; **names are working names**
  (🦖 T59). Kinds: name colour, gun tint, tracer colour, crosshair colour, tower flag,
  leaderboard banner (common); title, hunting hat, gun pattern/material, hit-marker, sprint
  trail (rare); animated sets (legendary). Exporter: one reward per listed level, no gold
  (mastery 20's), commons only at non-multiples of 10 below 100.
- **Profile screen** (home screen, new button on the Hunt Board row; key 🦖): level, XP bar,
  the next rewards, and equip slots per kind + title. No-trap rules; mouse freed; closes with
  key and X; closes on match-state change.
- **In play:** equipped cosmetics show on your gun, tracers, crosshair, hit-markers, hat,
  sprint trail, towers' flags and your leaderboard row (#181); **no gameplay effect** (no size or hitbox change, no extra
  visibility of anything).
- **Batch-6 follow-ups (#177–#179):**
  1. **Solo boost per round:** `bankRound` takes `solo` (one hunter present when the round
     is cleared) and applies `Solo take-down XP x` to that round's take-down part only;
     `matchAwards` no longer decides solo at match end.
  2. **`equipped` validated on load and on equip:** unknown ids, wrong kind, or level above the
     player's → dropped to default (no error); the server refuses such an equip.
  3. **Late save load:** XP awarded while the profile is still loading is held in server
     memory and added once the load succeeds (same session); a failed load drops it with one
     warning and never overwrites.
- **Accept:** specs for unlock-by-level and equip validation (server refuses equipping an
  item above your level); `panelrules.spec` green. Plus: a partner leaving after round 20 →
  only rounds 21+ get ×2; a hunter joining a solo run at round 30 → rounds 1–30 keep ×2 for
  the first hunter only; an old/bad `equipped` loads as {}; XP arriving before the load
  completes is banked once (not twice) after it; heroxp/playerlevel specs green.

### T58. Level leaderboard + showing off (#122)
- **Do:** `LevelBoard` service: OrderedDataStore (published) top 50 by Player XP, cached,
  refreshed every 60 s, pcall'd; fallback "This server" board + the one-line note. A
  "Leaderboard" tab on the Profile screen; your own row always. In-match leaderboard and the
  lobby show each hunter's player level badge and title.
- **Accept:** spec on the pure merge/sort/fallback; with DataStores unavailable (Studio) the
  tab shows the server board and logs one warning, no error loop; no request more than once
  a minute per server.

## Review, playtest, docs

### T58b. Batch-7 follow-ups (#181–#187) — after the Storm Coil Builder
- **Equip only in the Lobby:** the server refuses an equip request outside the Lobby state
  (matches the Lobby-only Profile screen); no client change needed beyond the refusal toast.
- **Leaderboard writes only on change:** `LevelBoard` writes a hunter's score only when their
  player XP changed since the last write (match end, leave), still ≤ once a minute per hunter
  and never in a loop; check `DataStoreService:GetRequestBudgetForRequestType` before each
  write and skip (retry next tick) when the budget is 0.
- **Cosmetics carry no gameplay:** hats and trails have `CanCollide`, `CanQuery`, `CanTouch`
  false and `Massless` true; no hitbox or targeting change.
- **Dino round 14 names (#186–#187), sheet `Cosmetics` col D:** D25 `Trapper` (lv 20), D36
  `Trailblazer` (lv 30), D58 `Veteran Hunter`, D69 `Game Warden`, D79 `Claw Marker`, D90
  `Footprint Trail`, D113 `Master Hunter`, D114 `Volcano Set`. Re-export Config. Title ladder
  after the change: Greenhorn 10, Trapper 20, Trailblazer 30, Ranger 40, Veteran Hunter 50,
  Game Warden 60, Pathfinder 70, Raptor Bane 80, Rex Wrangler 90, Master Hunter 100, Fossil
  Legend 150, Meteor Hunter 200, Elder Hunter {n} 250+.
- **Refusal text:** `Cosmetics.luau` reasons "Unknown slot"/"Unknown item" stay internal (logs,
  specs); the player only ever sees "You can't equip that." (and "Equip in the lobby." for the
  Lobby-only refusal).
- **Accept:** specs: equip in Lobby yes / in Playing no; no write when XP unchanged; a zero
  budget skips without error; a hat part is non-colliding and non-queryable; the toast never
  shows an "Unknown" string. `grep -rn -E "Trophy Hunter|Tar Pit Set|Apex Hunter|Star
  Marker|Fern Trail" src tools` = 0; Config diff = the 8 names. All specs green.

### T59. 🦖 Dino review: player level
The player-level label (must differ from "Lv N"), the titles, the cosmetic names (all
working names from T57), the Profile screen and leaderboard wording.

### T60. Tester: round-4 steps (run with T31 + T38 when Studio's MCP switch is on)
1. Home: PLAY 240 px, Hunt Board on its own row; Hunt Board shows Amber; Profile opens and
   closes with key and X.
2. Easy, K for cash: Linebreaker on a Pachy line; in round 16+ one shot drops more than one
   size (console: sizes dropped per hit); a Mortar never drops more than one.
3. Round 31 (start-round constant): a boss throw on a tower deals half; on the hunter, full.
   Triceratops shows the notched bar.
4. Hard: starts at 650. Chaos: towers hit softer, gun harder (console values).
5. Buy a hero path to tier 6 (J then K); Wildfire Drum's patch is 4 studs; the panel fits.
6. Mastery 6/7/8/9 (J): pick-up reach, heal on clear, respawn, repair price change.
7. Finish or lose a short match: "+N player XP" on the result screen; the level persists to
   the next match in the session; the leaderboard tab shows the server board and the note.
8. Leave mid-match from a second client: no player XP for the leaver.
Report each step pass / fail / not testable with console output and screenshots.

## The approved tower batch (TOWERS_NEXT.md "Jovan's picks"; DECISIONS #146–#152)

Needs T46–T48 (pierce-through) and T49 (the boss bar isn't needed, but `Enemies` must be
stable). Numbers are seeds on the sheet; the tier 1–3 tiers are as in `TOWERS_NEXT.md`, the
tier 4s and 5s are the picks table. Unlock Amber: Storm Coil 300, Falcon Roost 200, Tar Pit
250, Harpoon Ballista 300; in-match cost 550 / 400 / 450 / 600.

### T62. 🦖 Naming pass for the four towers (before any build) — DONE (Round 12; #159; names in TOWERS_NEXT.md "Final names")
Tower names, path names, all 60 tier names, ability texts. Must avoid every existing name
(the audit's collision check) and "Trophy" (reserved for ranked, #130/#139). The Director
logs the final names; the Builders use them from T63.

### T63. Groundwork: sheet rows, can't-be-damaged, on-track placement (#148, #152)
- **Sheet:** append 4 `Towers` rows (new keys, e.g. `COIL`, `FALCON`, `TARPIT`, `BALLISTA`)
  and 60 `Tower Upgrades` rows; a `Towers` column `Untouchable` (Yes for Falcon Roost, Tar
  Pit); Tuning blocks `STORM COIL`, `FALCON ROOST`, `TAR PIT`, `HARPOON BALLISTA` for
  ability levers (Power Grid per-coil range 0.15 / damage 0.25 / base 0.5 / cap 6 / every 6s;
  Eruption every 10s, sizes 2; Judgement Bolt every 10s ×8; Tow Line every 15s, 10 studs).
- **Code:** untouchable towers have no HP, are never targeted by bites or projectiles, can't
  be repaired, and are skipped by Armory/Hospital auras. `Shared/Placement`: a tower flagged
  `On track` must be placed on the track (not off it), never overlapping another pit; the
  ghost shows it. The four towers are **not sold** until their behaviour task lands.
- **Accept:** exporter/audit clean (UPGRADES.md gains the four sections from TOWERS_NEXT);
  placement spec (pit on track yes, off track no, overlapping no; other towers unchanged);
  combat spec (an untouchable tower takes 0 and is never chosen as a target).

### T64. Storm Coil (#151)
Arc path: arcs (nearest within reach, falloff 80%, breaks 1); Fork Lightning; Jump Spark; **Power
Grid** (n = standing Storm Coils, ≤ 6; range × (1 + 0.15(n−1)), damage × (0.5 + 0.25n);
one shared strike every 6s); Thunderclap; High Voltage; **Judgement Bolt** (biggest dino,
×8, breaks 3, boss stun 0.5s); Tall Mast; Charged Air; Grounding Spike; Storm Warning; **Lightning
Rodeo** (towers in range: each shot arcs once to one more dino at 50%). Accept: specs per
tier; Power Grid numbers at n = 1, 2, 6, 8 (= 6); `value.py` reads the new mechanics.

### T65. Falcon Roost
Birds fly out (travel time), dive, return; untouchable; Power Dive breaks 2, Iron Talons 3;
**Eagle of the Peak** (one eagle, ×6, stun 0.5s, breaks 3); **Murmuration** (12 birds,
continuous pecks in range); Lure; **Hunting Party** (+15% attack speed to towers in range
while a bird dives). Accept: specs; the 0.8× eDPS-per-cash bar (#148) in `value.py`.
Seeds confirmed (#191): Falcon Roost Damage 3, rate 1.33/s, 400 cash, 40 m range; T68 tunes.

### T66. Harpoon Ballista
Heavy bolts (breaks per tier: Crusher Bolt 2, Great Harpoon 3); **Skewer** (line through every
dino, each breaks 3); Pin Down; Reel In; **Tow Line** (boss pulled 10 studs every 15s,
uses `Enemies.knockback`'s rules for bosses as an explicit exception); Spread Volley;
Steam Crank; **Chain Harpoons** (bolt pairs hit everything on the segment between them).
Accept: specs; knockback of bosses only through Tow Line.
Seeds confirmed (#191): Ballista Damage 12 (the heaviest single hit; Longshot 9), rate
0.4/s, 600 cash, 24 m; T68 tunes.

### T67. Tar Pit (#150, #152)
On-track pool; slow; last-size sinking (not bosses or Pteranodons); Clinging Tar; **Tar
Lake** (×3 length); Boiling Pit (burn ticks break 1); Tar Fire; **Eruption** (every 10s
every dino in the pool drops 2 sizes outright, bosses included, resist ignored, each size
pays); Dig Site cash tiers (Lucky Finds); Tar Tracks; **Tar Totem** (towers in range +15% vs slowed).
Overlap is checked on the **pool** (its current length), not the footprint; if a later
Tar Lake upgrade makes pools touch, a dino in two pools gets the strongest one only (no
stacking slow, burn or Eruption). Accept: specs (Eruption on a 5-size T-Rex → 3; a sunk dino
pays like a kill; two touching pools never stack); untouchable.

### T68 (final). Release, cost and balance pass for all four (#192–#199) — replaces T68 text
Director's figures are from `value.py` on 2026-10-06 (T5 cost-per-eDPS, "c/e", r31–40). The
**released** damage-path T5s give c/e 41/110/115/119/165/185/268/294 → **median M = 142**.
1. **Medians count released towers only** (`value.py`: a `Towers` row not yet sold is left out
   of every median and of `--breaks1`'s T5 median). Do this first; re-read M and the T1–T5
   marginal medians from that run and use them below.
2. **Bars (T5, r31–40):** damageable new tower — its best T5 c/e **≤ 1.25 × M** (≈ 178;
   "worth it"). Untouchable — every damage T5 c/e **between 1.25 × M and 2 × M** (≈ 178–284;
   "somewhat weaker", not useless). Other tiers of new towers: no DEAD flag except the two
   accepted below. Revises #148 to T5 only.
3. **Storm Coil:** `Towers!D15` Damage 4 → **6**, `Towers!C15` cost 550 → **400** (all tier
   costs follow C15). Expected: Power Grid c/e 314 → ~157; Jump Spark / High Voltage marginal
   ~1.4× the T4 median (from 2.7×).
4. **Harpoon Ballista:** `Towers!E18` rate 0.4 → **0.5**, `Towers!C18` cost 600 → **500**
   (exactly ×1.5 eDPS-per-cash). Expected: Skewer c/e 213 → 142, Chain Harpoons 273 → 182;
   Crusher Bolt 2.6× → 1.7×, Great Harpoon 2.5× → 1.7×, Spread Volley 2.7× → 1.8×, Steam Crank
   2.3× → 1.5×. Skewer's `Rate x` 1.15 (H159) stays.
5. **Falcon Roost:** Flock T5 `Damage x` (`Tower Upgrades!G134`) 3.1 → **4.4** (Murmuration
   c/e 372 → ~262); Talons T5 `Damage x` (G129) 13.03 → **12.0** (Eagle of the Peak c/e 178 →
   ~185, inside the window).
6. **Tar Pit is judged as a control tower, not by eDPS (#198):** add `TARPIT` to
   `SUPPORT_TOWERS` in `value.py` (out of the medians, no DEAD/untouchable bars; Simmer and
   Boiling Pit DEAD flags go away with it). Its value line prints, per path in r31–40: Deep
   Tar share of ground dinos slowed and time added; Bubbling share of ground HP removed
   (burn + Eruption) per pit; Dig Site cash per round and payback rounds (like Supply Camp's
   Yield line). **One gated bar:** one Eruption pit removes **≤ 50%** of r31–40 ground HP
   (today ~63%). Lever: Tuning `Eruption interval` 10 → **13 s**; if still over, +1 s at a
   time up to 15 s; at 15 s report and pass (no stop). Sizes stay 2 (#150). No other Tar Pit
   number changes; `Towers!C17` stays 450.
7. **If a bar still fails after 3–6 (guaranteed exit):** cost is exactly linear (every tier
   cost follows the row's C), so set C = C × (target c/e ÷ measured c/e), rounded to 25, with
   target 160 (damageable) or 230 (untouchable). Floors: Storm Coil 350, Ballista 450, Falcon
   300; ceilings 600 (Tar Pit is not in step 7). If a floor is reached and a damageable bar still fails,
   raise that row's base Damage (D) by 1 and repeat (Storm Coil ≤ 8, Ballista ≤ 15). A DEAD
   flag on Ballista T3–T4 or Volley T3–T4 left after this is treated the same way (cost
   first); Storm Coil's two must clear.
8. **Release:** all four sold; Unlocks screen under Towers with Amber 300/200/250/300.
- **Also bars:** no DOMINANT finding; hero-vs-tower guard passes on every difficulty;
  `threat.py` 0; #72 pacing floors hold; `--breaks1` exits 0 with the released-only median;
  Chaos bars (T50) pass; findings = Big Bore T1, Concussive T5, **Ballista Steel Head T1, Saw
  Tip T2** (accepted, #194) and nothing else new (Tar Pit is out of the DEAD rule, #198).
- **Accept:** Config diff = the cells above (and any step-7 cells, listed); never an existing
  tower's number; commit message: table of every new-tower T5 (eDPS r21–30/31–40, c/e, ×M) and
  each step-7 adjustment.
- **T58 follow-up:** `LevelBoard` seeds a hunter's "last written" XP from the value read at
  join (profile load), so an unchanged hunter's first write of the session is skipped.

### T69. 🦖 Review of the four built towers (looks, wording, ability texts)

### T70. Tester: new-tower steps (with T31/T38/T60)
1. J unlocks all; place each tower; Tar Pit only places on the track.
2. Bites and throws never hit a Falcon Roost or Tar Pit; no repair button on them.
3. Storm Coil: arcs visible; Power Grid with 1 coil vs 3 coils (console damage/range).
4. Judgement Bolt on a boss drops up to 3 sizes; Skewer through a line drops each up to 3.
5. Eruption: dinos in the pool drop 2 sizes every ~10s; a T-Rex too.
6. Tow Line drags a boss back; Murmuration and Eagle of the Peak animate; Hunting Party and
   Tar Totem buffs show on towers in range.

### T61. Docs and round-4 recap (Director) — runs last, after T70
Update `CLAUDE.md` status, `ARCHITECTURE.md` phase table, `VISION.md` (player level,
cosmetics, ranked trophies note for phase 7), and append "Round 4 recap" to `RECAP.md`:
what changed, what to playtest first, the Ask-Jovan list (including the `TOWERS_NEXT.md`
picks), decisions he may want to overturn. Honest status: "statically checked + headless,
not playtested" unless T60 ran. Stop before phase 7.

**Phase 7 notes (not this round, #139):** mastery perks stay on in competitive modes; other
perks may be buffed so money doesn't decide matches; ranked uses a **Clash Royale-style
trophy system** (Trophies are reserved for it; take-downs are Bones).

---

# Plan — Round 3: mastery ability perks + hero XP (Director, 2026-10-02)

Scope (Jovan, 2026-10-02, `GAUNTLET.md` "Round 3 scope"): the two leftovers of Phase 6.
(1) Mastery levels 10 and 15 carry an **ability perk** per hunter, the level-15 one
objectively stronger, both modest and PvP-safe. (2) **Hero XP**: pops give a little XP that
is only banked when the round is cleared. Saving and publishing are deferred: nothing here
may need a DataStore. **Stop before phase 7** and append a round-3 recap to `RECAP.md`.
Design calls: `DECISIONS.md` #97–#117. **Status (2026-10-02): T32–T37 and T39 done and signed
off; T36c (one HUD string) is done (bebb40c); T31 + T38 (the Studio playtest) are still open.**

The round-1 and round-2 rules hold (one task = one commit; `tools/check.sh`,
`export_constants.py`, `tools/test.sh` green; diff `Config.luau` after every sheet change;
openpyxl only, assert a cell before writing it; append, never insert; "statically checked +
headless tests, not playtested"; 🦖 = Dino agent reviews). For this round:

- New Tuning levers go **below row 85** (row 86 blank, then the headers named below; assert
  each cell is empty first).
- Player-facing text never says "pop" (#93): it says **take-downs**. Code and sheet keys may.
- Builder run 1 = T32–T33. Builder run 2 = T34–T36. Then T37 🦖, T38 (Tester), T39 (docs).

## The design in one place

### Mastery ability perks (DECISIONS #97–#99)

A hunter with mastery 10+ has the level-10 perk; with 15+ has both. The names in this table
and in T32–T33b are the **working names**. Final names (🦖 Round 11, #114–#115): Tracker
Sticky Dart / Spare Dart, Big Game Hunter Hunting Horn / Long Rally, Brush Beater Wide Flare
/ Smoulder, Field Medic Far Reach / Stocked Kit.

| Hunter (ability) | Level 10 perk | Level 15 perk | Worth % (10 / 15) |
|---|---|---|---|
| Tracker (Tracking Dart: +50% for 8s) | **Lingering Dart**: the mark lasts **+2s** (8 → 10) | **Split Dart**: also marks the **1** nearest other dino within **10** studs of the target, at **0.4×** strength (+20%), same time | 25 / 40 |
| Big Game Hunter (Rally Cry: 10s, towers within 25 studs +40%) | **Carrying Voice**: radius **+5** studs (25 → 30) | **Long Rally**: lasts **+3s** (10 → 13), for the hunter and the towers | 20 / 30 |
| Brush Beater (Flare Strike: 30 damage, 2s stun, radius 10) | **Wide Flare**: radius **+1.5** studs (10 → 11.5) | **Smoulder**: leaves burning ground on the strike for **3s**, each second dealing **12%** of the strike's damage (36% in all) | 15 / 36 |
| Field Medic (Triage Kit: 40 HP within 20 studs) | **Long Reach**: radius **+4** studs (20 → 24) | **Stocked Kit** (was "Full Kit", #104): heals **+10** HP (40 → 50) | 20 / 25 |

- Perk values are **added to the hero's base ability value, before path multipliers** (Full
  Kit + Clean Bandages = 50 × 1.25; Long Reach + Triage Tent = 24 × 1.5).
- **Worth %** = 100 × (seconds added ÷ base seconds + radius added ÷ base radius + power
  added ÷ base power + extra marks × extra-mark strength) + burn % per second × burn seconds.
  The exporter computes it and fails unless, per hunter, **level 15 > level 10** and both are
  **≤ `Mastery perk worth cap` (40)**.
- **PvP reasoning:** every perk acts on dinos or on allies; none stuns, slows, knocks or
  marks a hunter; none adds stun time (the exporter rejects `Ability seconds +` on an
  AIRBURST row); none raises gun damage. Each is worth at most 40% of one cast of an ability
  on a 35–45s cooldown: a few percent of a team's damage or healing, an edge and never a
  fight-winner. If a battle mode ever lets abilities touch other hunters, that mode needs
  its own numbers (phase 7).
- **Existing rewards stay alongside:** level 10 keeps the free first upgrade, level 15 keeps
  cooldown −30%. #61's question (12 empty levels: 6–9, 11–14, 16–19) is unchanged and still
  Jovan's.

### Hero XP (DECISIONS #100–#103)

1. Clearing a round banks **Round XP** (100 = `XP per level` 500 ÷ `Rounds per level` 5) for
   every hunter in the match, plus **pop XP**: `XP per pop` 0.25 × (your pops + `Team pop
   share` 0.25 × your teammates' pops), rounded down, at most `Pop XP cap per round` **15**.
   "Pops" are the leaderboard's Pops (your gun, your towers, your fire).
2. Pop XP earned during a round is **pending**: it banks only when the round is cleared. A
   lost round (the match ends) or leaving mid-round drops it.
3. Hero level = 1 + floor(XP ÷ 500), held between the **round level** (1 + rounds cleared ÷ 5,
   the old curve: the floor) and round level + `Hero level lead cap` **1** (the ceiling).
   Late joiners and re-joiners start with the floor's XP. **Towers stay on the round level.**
   XP is **per match**: it resets every match and nothing is saved.

With the seeds a hunter who caps pop XP every round gains 115 a round: level 3 after round 9
(not 10), level 5 after 18 (not 20), level 9 after 35 (never in play before). Never more than
one level ahead; a hunter with no pops is exactly on the old curve.

---

## Part G — Mastery ability perks (Builder run 1)

### T32. Sheet, exporter and audit for perks and XP levers
- **Sheet — new sheet `Mastery Perks`** (title A1, note A2, header row 4, data rows 5–12):
  A `Hero key`, B `Mastery level`, C `Name`, D `Text`, E `Ability seconds +`,
  F `Ability radius +`, G `Ability power +`, H `Extra marks`, I `Extra mark power x`,
  J `Extra mark reach`, K `Strike burn % per s`, L `Strike burn (s)`. Blank = 0.

  | Row | A | B | C | Effect cells |
  |---|---|---|---|---|
  | 5 | PISTOL | 10 | Lingering Dart | E = 2 |
  | 6 | PISTOL | 15 | Split Dart | H = 1, I = 0.4, J = 10 |
  | 7 | RIFLE | 10 | Carrying Voice | F = 5 |
  | 8 | RIFLE | 15 | Long Rally | E = 3 |
  | 9 | SHOTGUN | 10 | Wide Flare | F = 1.5 |
  | 10 | SHOTGUN | 15 | Smoulder | K = 12, L = 3 |
  | 11 | MEDIC | 10 | Long Reach | F = 4 |
  | 12 | MEDIC | 15 | Full Kit | G = 10 |

  `Text` (D) is one plain sentence per perk, e.g. "Tracking Dart lasts 2s longer", "Tracking
  Dart also marks the nearest dino within 10 studs at 40% strength", "Rally Cry reaches 5
  studs further", "Rally Cry lasts 3s longer", "Flare Strike is 1.5 studs wider", "Flare
  Strike leaves burning ground for 3s (12% of the strike each second)", "Triage Kit reaches
  4 studs further", "Triage Kit heals 10 more HP".
- **Sheet — `Mastery`:** E14 → "Start every match with your first upgrade free, plus your
  hunter's level-10 ability perk"; E19 → "Ability cooldown -30%, plus your hunter's level-15
  ability perk" (assert both still hold the "coming later" text). A2 → "… never gun damage
  multipliers." Columns F–I unchanged.
- **Sheet — `Tuning`** (rows 86+; assert empty): header `HERO XP`; `XP per level` 500;
  `XP per pop` 0.25; `Pop XP cap per round` 15; `Team pop share` 0.25; `Hero level lead cap`
  1; blank; header `MASTERY PERKS`; `Mastery perk worth cap` 40.
- **Exporter:** reads `Mastery Perks` by header; emits `Config.MasteryPerks[heroKey] =
  { { level, name, text, <effect fields, zeros included> }, … }` sorted by level, and the six
  Tuning levers. Fails when: a hero key isn't on `Heroes`; a level isn't 1–20 or repeats for
  a hero; a hero on `Heroes` has no level-10 or no level-15 row; worth(15) ≤ worth(10); any
  worth > the cap; an AIRBURST row has `Ability seconds +`; a non-HEAL row has `Ability
  power +`; `Extra marks` on a non-MARK row or burn cells on a non-AIRBURST row; `XP per
  level` isn't a whole multiple of `Rounds per level`; any XP lever is negative; or a hunter
  at the pop-XP cap every round would be more than `Hero level lead cap` levels above the
  round level after any round 1…last (so the clamp is a safety net, not the rule).
- **Audit (`tools/audit.py`):** every number in a perk's `Text` equals one of that row's
  effect cells (`Extra mark power x` as a percentage); no `Text` contains "pop"; each perk
  name appears in `HEROES.md` "Mastery" (after T39; a note until then, not `--strict` fail);
  no perk column is all-blank (dead column).
- **Accept:** exporter clean; Config diff = the `MasteryPerks` block, six Tuning lines and
  two Mastery `unlock` strings, nothing else; a spec in `heroes.spec.luau` checks every hero
  has perks at 10 and 15; the exporter's own failure cases shown once each in the commit
  message (run on a temp copy of the sheet, never the real one); audit `--strict` 0.

### T33. Perks in play + the mastery screen
- **Pure rule:** `HeroStats.compute(heroKey, tiers, gear, masteryLevel?)` merges every perk
  with `level ≤ masteryLevel` into the hero's **base** ability values before path multipliers,
  and returns the new fields `markExtra`, `markExtraPowerMult`, `markExtraReach`,
  `strikeBurnPercent`, `strikeBurnSeconds`. `nil`/0 mastery = today's stats exactly. The
  client passes its `Mastery_{heroKey}` attribute, the server `Progression.masteryLevel`, so
  both agree. `Hero.masteryChanged` recomputes stats.
- **Server (`Hero.luau` ability):** MARK — after marking the target, mark the `markExtra`
  nearest other live dinos within `markExtraReach` studs of it at `abilityPower ×
  markExtraPowerMult` for the same seconds; never weaken a dino's stronger mark (check
  `Enemies.mark`; if it overwrites, keep the stronger inside `Enemies`, the only mutator).
  OVERDRIVE and HEAL — nothing new: they read the merged seconds, radius and heal. AIRBURST —
  after the strike lands, if `strikeBurnPercent > 0`, `Hazards.burn` at the strike's centre
  and radius for `strikeBurnSeconds`, DPS = the strike's damage (level-scaled) ×
  `strikeBurnPercent` ÷ 100, armour-piercing like the strike, credited to the hunter. No
  literals in code.
- **UI (`Shop.client` Unlocks & Mastery):** the level-10 and level-15 rows of a hero show
  the perk's name and `Text` from `Config.MasteryPerks` (owned perks marked as owned); the
  hero-upgrades panel (U) shows owned perks in one line under the ability. Text shrinks or
  wraps to fit, never clips (#96); the panel still obeys `Shared/PanelRules`.
- **Accept (headless, `heroes.spec.luau`):** for each hero, stats at mastery 0 / 9 equal
  today's; at 10 only the level-10 lever moves, by the sheet value; at 15 both; Full Kit and
  Long Reach multiply through Clean Bandages / Triage Tent as stated above; the Rally Cry
  radius used by `Hero.towerRateBoost` is the merged one (assert through the stats). The mark
  spread and the burn call are server-only: statically checked, listed for T38.

**T32 (9f85187) and T33 (2fdd30d): reviewed 2026-10-02, accepted with the fixes in T33b**
(DECISIONS #104–#108). Statically checked + 223 headless specs, not playtested.

### T33b. Perk follow-ups (after T34–T36 are committed: one Builder edits code at a time)
- **Name (#104):** `Mastery Perks` C12 `Full Kit` (assert) → **`Stocked Kit`**; `Text`
  unchanged. Audit: a finding when a perk `Name` equals any tier name on `Tower Upgrades` or
  `Hero Upgrades`, or any hero's ability name (case-insensitive). The spec or audit run
  shows the check failing on "Full Kit" once (temp copy), in the commit message.
- **Wording (#105):** `Shop.client` "Mastery never adds damage." → **"Mastery never makes
  your gun hit harder."** `HEROES.md` "Mastery": "Never damage." → **"Never gun damage:
  perks change abilities only."** `Mastery!A2` must read "… never gun damage multipliers."
  (fix if T32 left it). `HeroStats.luau` line 18's "Never damage" is about Armory gear:
  leave it.
- **Marks (#106):** `Combat.mergeMark` — while a mark is running, a **weaker** new mark
  changes nothing (not the strength, not the time); an **equal** one keeps the strength and
  the longer of the two times; a **stronger** one replaces both, as now. Specs in
  `combat.spec.luau`: (50, 2s) + (20, 3s) → (50, 2s); (50, 2s) + (50, 3s) → (50, 3s);
  (50, 5s) + (50, 3s) → (50, 5s); (20, 5s) + (50, 3s) → (50, 3s); expired + anything → the
  new mark. Update the header comments in `Combat` and `Enemies`.
- **Accept:** Config diff = one `name` line; `tools/check.sh`, exporter, `tools/test.sh`
  green; audit `--strict` 0; the three strings grep clean ("never adds damage" has no hit
  in `src/` or `HEROES.md`).

## Part H — Hero XP (Builder run 2)

### T34. XP rule (pure) and server wiring
- **New `Shared/HeroXp`** (pure, Config only): `roundXp()`, `roundLevel(roundsCleared)`
  (replaces `levelAfter` in Main), `popXp(ownPops, teamPops)` (teamPops includes own),
  `floorXp(roundsCleared)`, `bank(xp, ownPops, teamPops, roundsClearedAfter)` → new XP
  (never below the floor, never at or above the XP of round level + lead cap + 1), and
  `level(xp, roundsCleared)` (clamped).
- **Server:** `Hero` is the only mutator of a hunter's XP, pending pops and level. Main's pop
  hook calls `Hero.addPop(player)` beside `Scoreboard.addPop` (every credited pop, shrinks
  included). On `onRoundEnd`, `Hero.roundCleared(index)` banks for every hunter present,
  clears pending and republishes; Main keeps `Towers.setLevel(HeroXp.roundLevel(index))` and
  the `Level` attribute (now "tower level"). A hunter who joins or re-joins mid-match starts
  at `floorXp(rounds cleared)` with no pending; `Hero.resetMatch` zeroes XP and pending. A
  lost match banks nothing. `Hero.setLevel` goes away (or only seeds the floor for the
  Studio start-round constant). Attributes for the HUD: `HeroLevel`, `HeroXp`,
  `HeroXpPending` (the pop XP this round so far, already capped). No DataStore, no Profile
  field.
- **Accept (headless, new `heroxp.spec.luau`):** no pops → after r rounds the level equals
  the old `1 + floor(r/5)` for r = 0…40; capped pops every round → level 3 after 9, 5 after
  18, 9 after 35, and never > round level + 1; `popXp(0, 400)` (a Medic in a busy lobby) = 15
  and `popXp(0, 0)` = 0; `popXp` rounds down and caps; a joiner at round 23 gets floor XP
  2,300 → level 5; a huge pending value can't pass the ceiling; nothing in the module reads
  a clock or a player. `tools/check.sh` clean.

### T35. HUD: level, XP readout, banner
- **Do (`Hud.client`):** the existing "Lv" readout becomes **"Lv N"** with a thin XP bar and
  "240 / 500 XP" beside it, and "+12 on clear" while there is pending pop XP (wording 🦖).
  It is a HUD label: not a panel, takes no input, never captures or frees the mouse, sits
  inside the screen at any window size (scale or shrink, #96 rules) and hides with the rest
  of the HUD outside a match. The level banner fires when **your** `HeroLevel` rises
  ("Hunter level N — your shots hit 25% harder", percentage from Config) and, when the tower
  level rises, adds or shows the tower line ("Towers level N — +10%"); one banner, at most
  two lines, never stacked. The leaderboard keeps showing each hunter's own level if it does
  today.
- **Accept:** the bar's numbers come from a pure helper (`HeroXp.progress(xp, roundsCleared)`
  → shown XP, needed XP, level) with a spec (level-up edge, clamp edge, pending shown but not
  counted); `panelrules.spec.luau` still green; no new ScreenGui with `Modal` or input sink
  (grep in the commit message); strings contain no "pop".

### T36. Models and guards follow the new levels
- **Do:** `tools/value.py` hero lines print each checkpoint at the **floor** level and at
  **floor + lead cap**, and say which is which; tower lines stay on the round level. The
  exporter's hero-vs-tower guard compares the highest hero level in play (round level of the
  last round + lead cap) against the best tower at the round level of the last round.
  `threat.py` doesn't read levels: confirm and say so.
- **Accept:** `value.py` and `threat.py` exit 0 with no new finding; the guard passes and its
  numbers (hero, best tower) are quoted in the commit message; if the ceiling hero now beats
  a tower it didn't before (#58: Longshot Perch ~223), list it for the Director, change no
  number.

**T34 (18074b1), T35 (40a34ee), T36 (7996f48): reviewed 2026-10-02, accepted with T36b**
(DECISIONS #109–#113). 241 specs, audit strict 0, threat 0; not playtested. `DEAD_PENDING`
is empty (#108 met).

### T36b. XP follow-ups (after T33b is committed)
- **Model checkpoints (#109):** `tools/value.py` hero lines keep rounds 1 / 20 / 40 but take
  the level **in play during that round**, computed, not typed: floor = 1 +
  floor((round − 1) ÷ `Rounds per level`) → L1 / L4 / L8, ceiling = floor + `Hero level lead
  cap` → L2 / L5 / L9; towers at the floor. Remove the literal `(5, 20, 1), (9, 40, 3)`
  levels and the closing "(L5 and L9 are …)" line. An assert in `value.py` (or a spec) that
  its round-40 hero ceiling and tower floor are the same levels the exporter's guard uses.
  **Report only:** quote the hero block before and after; new findings go to the Director,
  no number changes.
- **Tower level readout (#112):** the tower panel shows one line, **"Tower level N · +X%
  damage"** (X = round((1 + `Tower damage per level`)^(N − 1) × 100 − 100), from Config; N
  from the `Level` attribute), hidden at level 1. Nothing returns to the HUD status line.
  The text comes from a pure helper with a spec (level 1 → no line; level 3 → "+21%"); the
  panel still fits (PanelRules spec green, text shrinks rather than clips). 🦖 words it.
- **Leavers (#111):** a spec or comment-backed test that when a hunter leaves mid-round the
  team count drops by their pops and nobody's pending XP rises; no behaviour change.
- **🦖 Round 11 wording (DECISIONS #114–#115; names and strings only, no numbers).** Assert
  each cell or string holds the old text first.
  - `Mastery Perks` names: C5 `Lingering Dart` → **`Sticky Dart`**; C6 `Split Dart` →
    **`Spare Dart`**; C7 `Carrying Voice` → **`Hunting Horn`**; C11 `Long Reach` →
    **`Far Reach`**. C8 Long Rally, C9 Wide Flare, C10 Smoulder, C12 Stocked Kit stay.
  - `Mastery Perks` text: D9 → **`Flare Strike reaches 1.5 studs further`**; D10 →
    **`Flare Strike leaves burning ground for 3s (12% of the strike's damage each second)`**.
  - `Mastery` E14 → **`Start every match with your first upgrade free, plus this hero's
    mastery-10 ability perk`**; E19 → **`Ability cooldown -30%, plus this hero's mastery-15
    ability perk`**.
  - `Shop.client` `perkLines`: `Level {perk.level} perk` → **`Mastery {perk.level} perk`**.
    The Amber note: `Mastery never makes your gun hit harder.` → **`Mastery perks boost your
    ability, never your gun's damage.`**
  - `Hud.client`: `+{pending} on clear` → **`+{pending} bonus on round clear`** (the row
    must still fit: shrink the text, never clip); `Towers level {level} — +{percent}%` →
    **`Tower level {level} — towers hit {percent}% harder`**.
  - Unchanged on purpose: "XP", `Lv {N}`, `Hunter level {N} — your shots hit {P}% harder`,
    the tower-panel line above, ` (owned)`. In menus the class is a "hero" ("Choose your
    hero", "this hero's …"); "hunter" is the player in a match. Don't change either.
  - Checks: the audit's perk-name collision check and number-in-text check stay 0; grep
    shows no `Split Dart`, `Lingering Dart`, `Carrying Voice`, `Long Reach`, `Level {perk`,
    `on clear\`` (without "round") or `Towers level` in `src/` or the sheet's exported
    Config; specs that quote the old names or strings are updated, not deleted.
- **Accept:** `check.sh`, exporter, `test.sh` green; audit strict 0; `value.py` / `threat.py`
  exit 0; Config diff = four perk `name` lines, two perk `text` lines and two Mastery
  `unlock` lines, nothing else.

**T36b (b4e6ccb, eb5778b): signed off 2026-10-02** (DECISIONS #116). 245 specs, audit strict
0, threat 0, `value.py` no new findings (its three round-2 pacing notes remain); Config diff
exactly the eight lines. Not playtested.

### T36c. Shorter pending-XP text (one string; DECISIONS #117)
- `Hud.client`: `+{pending} bonus on round clear` → **`+{pending} on round clear`** (assert
  the old string). Nothing else changes; the row still shrinks rather than clips.
- **Accept:** `check.sh` and `test.sh` green; the Builder's estimate of the text size in the
  420 px row, before and after, in the commit message; specs quoting the old string updated.

## Part I — Review, playtest, docs

### T37. 🦖 Dino review: perk names and XP wording
- The eight perk names and `Text` lines (working names above; watch collisions with tier
  names such as Second Wind, Steady Hands, Long Dose — scope by sheet, as always), the HUD
  strings ("on clear", "Hunter level", "Towers level"), the two Mastery `unlock` lines.
  Output: `DINO_REVIEW.md` Round 11. The Director accepts or rewords (DECISIONS), the Builder
  applies sheet/text changes in one commit. No number changes.

### T38. Tester: round-3 steps (run with T31 when Studio's MCP switch is on)
- T31 stays open and unchanged. Added steps, same rules (saving off with J first):
  1. J, buy Tracker mastery to 15 in Unlocks & Mastery: rows 10 and 15 show the perk name and
     text, nothing clipped at 800×600; X and M both close the panel.
  2. Tracking Dart on a dino in a pack: a second dino nearby shows a mark; the marks end
     after ~10s. Rally Cry: disc looks wider than at mastery 0 (read the radius attribute or
     stat if exposed), lasts ~13s. Flare Strike: burning ground stays ~3s. Triage Kit from
     40 HP: heals to 90 (50 HP), where mastery 0 heals to 80.
  3. Round 1: the XP readout shows "Lv 1", "0 / 500 XP" and a pending "+N on round clear"
     (T36c; "+N bonus on round clear" before it) rising with take-downs, capped at 15; on
     clear the bar gains 100 + N; pending returns to 0. Read the label's `TextBounds` / font
     size at 1280×720 and 800×600 and report the pixel height (#117).
  4. K cash, clear to round 9 with capped pops: banner "Hunter level 3 — your shots hit 25%
     harder" after round 9; "Tower level 3 — towers hit 10% harder" only after round 10. Open
     a tower's panel after round 5: it shows "Tower level 2 · +10% damage"; in round 1 it
     shows no such line.
  5. Lose a round on purpose: result screen appears, no XP banked from that round (read
     `HeroXp` before/after); back in the lobby and in the next match the level is 1, XP 0.
  6. The XP readout never blocks a click on Start, the shop or the hotbar at 800×600.
  7. Mastery screen wording: rows read "Mastery 10 perk · Sticky Dart" and "Mastery 15 perk ·
     Spare Dart" (owned ones say "(owned)"); the note reads "Mastery perks boost your
     ability, never your gun's damage."; U shows one "Tracking Dart perks: …" line.
  8. Marks (#106): with a Longshot Perch that marks (or Tracer Rounds) hitting a darted dino,
     the dart's mark still ends ~10s after the dart, not later and not sooner.
- **Before any of it:** Studio must be running the current code. Rojo has been disconnected
  in Jovan's Studio since the afternoon of 2026-10-01, so until he reconnects it Studio holds
  **pre-round-2 code**. The Tester first checks that `ReplicatedStorage.Shared.HeroXp` exists
  and that `RoundsCleared` is an attribute; if not, it writes "Studio is not synced (Rojo
  disconnected)" in `PLAYTEST.md` and stops.
- Report pass / fail / not testable per step in `PLAYTEST.md`; feel and balance stay Jovan's.

### T39. Docs and round-3 recap — **done 2026-10-02** (Director; "Studio testing pending")
- `HEROES.md` "Mastery" (perk table, existing rewards kept) and "Hero levels" (the XP rule
  replaces "Now / Planned"); `DIRECTION.md` line "Levels (+25% hero / +10% tower every 5
  rounds)" reworded to the floor/lead rule if the audit allows (keep the numbers it checks);
  `ARCHITECTURE.md` (ownership: `Hero` owns XP and hero level, `Shared/HeroXp`, tower level
  from Main); `CLAUDE.md` status; `GAUNTLET.md` status line; `RECAP.md` "Round 3": what
  changed, what to try first, what was and wasn't verified, and the questions for Jovan
  (#61 empty levels; whether competitive buy-in modes should switch mastery perks off;
  whether "count at the end" should later also mean a match-clear bonus once saving exists).
- **Accept:** audit `--strict` 0; spec count and tool results quoted; nothing called
  playtested unless T38 ran.

**Stop here. Phase 7 is not started.**

---

# Plan — Round 2: balance pass + daily log-in rewards and bounties (Director, 2026-10-01)

Scope (Jovan, 2026-10-01, `GAUNTLET.md` "Round 2 scope"): (1) a balance pass across the whole
game, justified by headless models because there's no playtest data yet; (2) daily log-in
rewards plus daily and weekly challenges, for retention. **Stop before phase 7** and append a
round-2 recap to `RECAP.md`. Design calls: `DECISIONS.md` #54–#96.
**Status (2026-10-01): T18–T30 done and signed off; T31 (Studio playtest) is open.** Round 1's plan is kept
below as history.

The round-1 rules still hold (one task = one commit, push after verifying; `tools/check.sh`,
`export_constants.py` and `tools/test.sh` green; diff `Config.luau` after every sheet change
and account for each changed line; openpyxl only, assert a cell before writing it; append
rows/columns, never insert; scope every lookup by (tower/hero, path, tier); "statically
checked + headless tests, not playtested"). Plus, for this round:

- **Models read the spreadsheet through the exporter** (`export_constants.read_data` /
  `recalculated`), never `Config.luau`, and never write Config (import, don't run `main`).
  Model output stays short: ≤ ~120 lines by default, `--full` for everything.
- **A number changes only if a model shows why** (DECISIONS #54). Each balance commit message
  quotes the model line before and after.
- New Tuning levers go **below row 76** (row 77 blank, then a `REWARDS` header).
- 🦖 = the Dino agent reviews names, looks and wording before the Director signs off.

---

## Part C — Balance models (report only, no number changes)

### T18. Value model: towers, heroes, economy tiers
- **Goal:** one table that shows dead and dominant tiers using what the game really does,
  not the sheet's formula DPS (today all three paths of a tower show near-identical
  `Resulting DPS`, because the multipliers were set to track 1.9^tier; pierce, armour,
  splash, bosses, burn and auras are invisible to it).
- **Files:** new `tools/value.py`; `tools/test.sh` runs it after `threat.py` (report only:
  exit 0 unless it crashes).
- **Do:** a reference wave mix per band (rounds 1–10, 11–20, 21–30, 31–40) from the Rounds
  sheet: share of EHP that is armoured, flying, boss. For each tower × path × tier: cumulative
  cash, **effective DPS** in each band (Damage x × Rate x × Shots × Line hits / Targets x
  stand-in; 0 vs armour without Pierces armour/Strips armour, Armoured x, Boss x; 0 vs air if
  it can't hit air; + Burn DPS × uptime; + bomblets; Mark/Brittle as +% on the tower's own
  damage; aura towers credited with aura % × the DPS of **3 neighbour T2 Hunting Blinds**, a
  stated assumption), cost per effective DPS, and marginal cash per marginal eDPS. Support and
  control paths (Lookout, Sedate, Armory, Field Hospital, Supply Camp) are listed with their
  own value line (aura %, slow %, resist %, heal, payback) and are **not** judged on DPS.
  Flags: **dead tier** = marginal cash/eDPS > 2× the median of all damage paths at that tier
  in the band it's typically bought (T1–2: 11–20, T3: 21–30, T4–5: 31–40); **dominant tower**
  = cost/eDPS < 0.5× the median at every tier in every band. **Economy payback**: for every
  Supply Camp tier, rounds to repay its upgrade cost from its extra income (Yield) or chest
  cash (Airdrop, assuming every chest is collected); Logistics: cash spent needed to repay
  the discount. **Heroes:** each hero's best path DPS at levels 1/5/9 vs Required DPS of that
  round and vs every tower's T5 leveled DPS, and the cash its upgrades cost per DPS.
- **Accept:** runs in < 15 s; flags print in a "Findings" block at the end; numbers spot-
  checked by hand for one tower per kind (Blind, Perch, Mortar, Tranq) in the commit message;
  no sheet or Config change.

### T19. Pacing model: difficulty × players, repair, Amber
- **Goal:** see whether Normal/Hard/Chaos and co-op are affordable, what repairs cost against
  income, and how long Amber takes.
- **Files:** `tools/value.py` (new sections, `--pacing`), or `tools/pacing.py` if cleaner.
- **Do:** (a) the Balance Check's affordability ratio recomputed for every difficulty
  (HP x, count x, speed x, promote chance, Cash x) at 1, 4 and 10 players (Tuning CO-OP), with
  the minimum over rounds 11–35 and the TIGHT rounds listed; (b) the repair price of a
  fully trampled tower at its typical tier for the round (T2 at 15, T3 at 25, T4 at 35)
  against that round's income; (c) Amber: clears to unlock every hero and tower per
  difficulty, mastery cost per level with a "gives a reward?" column, hours per clear from
  the Rounds sheet's round lengths, and (once T25 exists) the same with the daily/weekly
  maximum added.
- **Accept:** as T18; the Balance Check sheet's Easy-solo values are reproduced exactly
  (assert in the script).

## Part D — Balance changes (each one model-justified; Director reviews the model output first)

### T20. Supply Camp tiers pay for themselves (cells fixed, DECISIONS #56/#73)
- **Why (value.py):** payback today — Yield 51/88/162/233/99 rounds, Airdrop 38/88/101/233/101;
  the base camp is 6.7.
- **Sheet (exact cells):**
  - `Towers!S4` = "Upgrade cost growth" (new column, assert empty), `Towers!S9` = **1.6**.
  - `Tower Upgrades!E65:E79` (the 15 Supply Camp rows; assert each still reads
    `=ROUND('Towers'!$C$9*POWER('Tuning'!$B$12,Dnn),0)`) →
    `=ROUND('Towers'!$C$9*POWER('Towers'!$S$9,Dnn),0)`. Costs become 1,600 / 2,560 / 4,096 /
    6,554 / 10,486. No other tower's formula changes.
  - Yield rows 65–69, column **Income x** (AN): 1.3/1.7/2.2/3/4 → **2.1 / 3.85 / 6.6 / 11.1 /
    17.9**. Amber Vault's interest (5%, cap 500) unchanged.
  - Airdrop rows 70–74, column **Chest cash** (AR): 60/60/120/120/250 → **200 / 260 / 515 /
    615 / 790**. Chest counts unchanged. Logistics rows unchanged.
  - If the exporter's Towers reader breaks on column S, make it read by header; Config gains
    nothing new (costs are already exported per tier).
- **Accept:** `value.py` payback: Yield ≈ 9.7 / 9.8 / 9.9 / 9.7 / ≤ 7 rounds, Airdrop 8.0 each;
  no ECONOMY finding left; only Supply Camp cost / income / chest lines change in Config;
  Balance Check unchanged; `UPGRADES.md` Supply Camp numbers updated; audit 0.

### T21. Smooth the round-11, round-21 and round-31 cliffs (cells fixed, DECISIONS #57/#72)
- **Why (value.py --pacing):** Required DPS R20→21 17.1→39.7 (×2.32), R30→31 76.3→214.2
  (×2.81); Easy solo affordability 0.97 at 21 and 0.71 at 31; every harder level's trough is
  round 11.
- **Sheet:** `Rounds` counts only (row = round + 4; D Pachy, E Ankylosaurus, F Gallimimus,
  G Pteranodon, H Triceratops). Assert the old value, write the new one; nothing else moves.

  | Round | Pachy D | Anky E | Galli F | Ptera G | Trike H |
  |---|---|---|---|---|---|
  | 7 | 0→2 | | | | |
  | 8 | 0→4 | | | | |
  | 9 | 0→6 | | | 0→1 | |
  | 10 | 0→9 | 0→2 | | 0→2 | |
  | 11 | 16→14 | 8→6 | | | |
  | 12 | 17→16 | 8→7 | | | |
  | 17 | | 11→13 | 0→2 | | |
  | 18 | | 11→15 | 0→4 | | |
  | 19 | | 12→17 | 0→6 | | |
  | 20 | | 12→19 | 0→8 | | |
  | 31 | | 31→26 | 31→16 | 18→13 | 8→1 |
  | 32 | | 31→28 | 31→19 | 18→15 | 8→2 |
  | 33 | | 31→29 | 31→21 | 18→17 | 8→4 |
  | 34 | | 31→30 | 31→24 | | 8→5 |
  | 35 | | | 31→27 | | 8→6 |
  | 37 | | | | | 8→9 |
  | 38 | | | | | 8→10 |
  | 39 | | | | | 8→12 |

  No Triceratops before round 31: one at round 29/30 breaks the #42 threat target (62.3 ≥ 50).
- **Expected (Director's dry run on a scratch copy):** no Required-DPS step > 1.5× except
  round 31 at 1.53× (was 2.81×); Easy solo affordability r11 1.22, r21 1.16, r31 1.18, r32
  1.07, r33 0.95, r35 0.90, r36–39 0.86, r40 0.81; Normal solo min 0.81 (r11), Hard solo 0.59
  (r11), Chaos ×4 0.43 (r11); rounds 31–40 total EHP 289,569 vs 323,127 (−10.4%);
  `threat.py` 0 misses.
- **Accept (bars, #72):** Easy solo ≥ 1.0 in rounds 11–32 and ≥ 0.85 in 33–39; no step
  > 1.6×; finale EHP within ±12%; Normal solo ≥ 0.75, Hard solo ≥ 0.55, Chaos ×4 ≥ 0.40 over
  rounds 11–39; `threat.py` green; the Config diff touches only the Rounds block. Update the
  bars inside `value.py` to these (same commit) so its Findings match. If the Builder's run
  differs from "Expected" by more than 0.02 anywhere, stop and report instead of retuning.

### T22. Difficulty cash: no change (DECISIONS #72)
- Cash x stays 1 / 0.9 / 0.8 / 0.75. Nothing to build beyond the bars updated in T21; this
  task is closed by that commit. The round-11 trough on Hard/Chaos goes on the playtest list
  with the option of per-difficulty starting cash (ask Jovan).

### T23. "Dead" Tranq and Concussion tiers: fix the model, not the numbers (DECISIONS #74)
- **Verdict:** Tranq Knockout T1–T5, Tranq Weak Spot T3–T5 and Perch Concussion Round are
  control/support the model can't see, not dead tiers. **No spreadsheet cell changes.**
- **Files:** `tools/value.py` only.
- **Do:** (1) Tranq Station **Knockout** joins the "control: not judged" list; print its
  value line instead: knockout seconds per cycle (Freeze (s) / Freeze every (s)) as "% of
  the time dinos in range are stopped", and whether it holds bosses. (2) **Weak Spot** is
  judged as support: credit Brittle % (and Aura rate % / Aura damage %) on the same **3
  neighbour T2 Hunting Blinds** used for auras, plus its own darts; strips-armour noted.
  (3) **Concussion Round** (Siege T3): print "stun N s on hit" beside the tier and exclude
  that one tier from the dead flag (the path's T4–T5 are still judged).
- **Accept:** `value.py` Findings no longer list those tiers; every other number in its
  output is unchanged (diff of the output in the commit message); no Config change.

### T24. Threat report for the boss rounds (#44, report only)
- **Files:** `tools/threat.py`: print rounds 31–40 mid-gap defended damage per tower type,
  also with the Armory's top resist (45%) applied. **No target, no failure** (#44 stays a
  playtest item).
- **Accept:** output shows rounds 31–40 before/after T21 in the commit message; test.sh green.

### T24b. Round 39 below the finale; round-11 step named in the model (DECISIONS #77–#79)
- **Sheet:** `Rounds!H43` (round 39, Triceratops) **12 → 10** (assert 12). Nothing else.
- **Files:** `tools/value.py`: the step check runs from round 2; the bar stays 1.6× for
  rounds 12–40, and **round 11 is a named exception with its own bar of ≤ 2.1×** ("first
  armour and air wave", today ×2.02), printed in the output, so a regression is still
  caught. The damage medians keep excluding the control/support paths (as f26a78a does);
  add a one-line comment citing #79. No other model change.
- **Accept:** `threat.py` report: round 39 mid-gap worst case ≤ round 40's (expected ≈ 212
  vs 215.8); finale EHP within ±12% of the pre-T21 323,127 (expected ≈ −11.6%); Normal solo
  minimum over rounds 11–39 ≥ 0.75 (expected up from 0.77 at r39); no new value.py finding;
  the Config diff is the one round-39 line; test.sh green. If any expected number is off by
  more than 0.02 (or 2 damage), stop and report.

## Part E — Daily Haul and Bounties (log-in rewards + challenges)

Design: DECISIONS #63–#71 and #75–#76. The Dino agent's Round 9 kept all six names: the
screen is the **Hunt Board**; the log-in calendar is the **Daily Haul** (day 7 = **Big
Haul**); challenges are **Bounties**; a reroll is a **Swap**.

**Round 9 rulings — all accepted; they override the task text below where they differ:**
- **T25:** the Bounties sheet gets a **Title** column before Text. Titles: Compy Sweep,
  Raptor Cull, Headbutt Hunt, Shell Cracker, Run Them Down, Clear Skies (Pteranodons), Busy
  Day (daily pop-any) / Stampede (weekly pop-any), Deep Trail (reach round; weekly: reach
  round 31 {n} times), Gear Check (ability), Pitch Camp (build), Sharpen Up (upgrade), Patch
  Job (repair trampled towers), Scavenger (chests), Clean Sweep (clear any track; weekly:
  {n} times), Rough Country (clear Normal or harder), Badlands (clear Hard or harder), Horn
  Breaker (Triceratops), Tyrant's End (T-Rex). Text lines as in `DINO_REVIEW.md` Round 9.
  **Clear Skies stays in the pool:** the free Hunting Blind, Longshot Perch and the Tracker
  all have Hits air = Yes (Towers / Heroes sheets). The exporter fails if a `pop` bounty
  targets a flying species and no free tower or hero hits air. "Repair" means a
  **trampled** tower (#75). Slot (easy/medium/hard) stays a sheet column but is never shown.
- **T25 pool, final (Count · Amber; the Builder makes no sizing calls, #75).** Daily easy
  (10): Compy Sweep 150, Raptor Cull 100, Busy Day 300, Gear Check 5, Pitch Camp 6. Daily
  medium (15): Headbutt Hunt 60, Shell Cracker 40, Clear Skies 30, Deep Trail round 15,
  Sharpen Up 10. Daily hard (20): Run Them Down 25, Deep Trail round 25, Patch Job 2, Clean
  Sweep 1. Weekly easy (40): Stampede 1,500, Gear Check 30, Deep Trail round 31 × 2. Weekly
  medium (60): Clean Sweep 3, Rough Country 1, Horn Breaker 10, Patch Job 10. Weekly hard
  (80): Badlands 1, Tyrant's End 1, Deep Trail round 31 × 4. **Scavenger (chests) is
  dropped** and the `chest` event with it: chests need the Supply Camp, a 150-Amber unlock
  (#66). If the model check (doable in one solo Easy match to round 25 / ≤ 5 matches) fails
  for a row, halve that row's Count and say so in the commit; nothing else is tunable.
- **T26/T27:** `refresh` returns the reset payout; Progression publishes it once so the board
  can show one dim line, "Unclaimed bounties paid: +35 Amber" (never a pop-up).
- **T28:** the toast reads **"Bounty bagged: Raptor Cull (+15 Amber)"** (title, not text).
- **T29:** the home button reads **"Hunt Board [G]"** (and its tooltip), with a small amber
  dot when something is claimable (no bouncing). Sections are titled **Daily Bounties** and
  **Weekly Bounties**. Look: one dark wood board (70,50,35, thin lighter rim) on the
  existing `BG`; header "HUNT BOARD" in the amber title colour (245,175,60) with the X in
  the header bar, outside the scrolling area; a dim "New bounties in 5h 12m" line. Cards
  are cream paper notes (235,225,200, dark text, one tack): title, one text line, a thin
  progress bar with `12 / 40`, an Amber chip `+15`, and a small dot in the dino's
  `DinoLook` colour. States: in progress = bar plus a text button `Swap (1 left)` (hidden
  when done, claimed or out of swaps); done = a solid amber **Claim** button (no pulsing);
  in flight = grey `…`, disabled; claimed = dimmed card with a tilted red **BAGGED** stamp.
  Daily Haul strip: 7 tiles, claimed days get a footprint stamp, today an amber outline and
  **Claim**, future days dim, day 7 about 1.5× wide and labelled **Big Haul**; under it
  "Missed days don't reset your Haul."; on narrow windows it wraps 4 + 3. Only the bounty
  list scrolls; the header, X and Haul strip never scroll away. No full-screen dimmer over
  Play; a claim shows an inline `+15 Amber` float on the card, never a reward pop-up.

### T25. Sheets, levers and exporter — 🦖 (names and bounty text)
- **Sheet:** new sheet **Daily Haul**: Day 1–7, Amber **5, 5, 10, 10, 15, 15, 40**, Note.
  New sheet **Bounties**: Id, Pool (daily/weekly), Slot (easy/medium/hard), Event
  (pop / popTotal / clear / reachRound / ability / build / upgrade / repair / chest), Target
  (species key, difficulty key or blank), Count, Amber, Text (with `{n}`). Tuning levers
  (rows 78+, under a `REWARDS` header): Daily bounties 3, Weekly bounties 3, Daily swaps 1,
  Weekly swaps 1, Haul resets after missed days 0 (0 = never), Daily reset hour UTC 0,
  Weekly reset day 1 (Monday). Reward seeds: daily easy/medium/hard **10/15/20**; weekly
  **40/60/80**. Pool seeds (Builder sizes counts so the T25 check below passes):
  - daily: pop N Compies / Raptors / Pachys / Ankylosaurs / Gallimimus / Pteranodons; pop N
    dinos; reach round 15 / 25; use your ability N times; build N towers; upgrade N times;
    repair N towers; collect N supply chests; clear any track (hard slot).
  - weekly: clear N tracks; clear Normal or harder; clear Hard or harder; pop N dinos; pop N
    Triceratops; pop a T-Rex; reach round 31 N times; use your ability N times; repair N.
  - at least slot-count + 2 entries per (pool, slot), so a swap always has a choice.
- **Exporter:** `Config.DailyHaul`, `Config.Bounties`, levers in `Config.Tuning`. Validation
  (fails the export): each Haul day < Easy clear reward; Haul week total ≤ 2× Easy clear;
  the daily slots' Amber sum < Easy clear; each weekly < Chaos clear and their sum ≤ Chaos
  clear; Event and Target valid; ids unique; enough entries per slot. **Model check**
  (`value.py`): every daily is doable in one solo Easy match reaching round 25 (species
  counts from the Rounds sheet), every weekly in ≤ 5 such matches or clears.
- **Accept:** export clean; new Config blocks only (diff); `audit.py --strict` 0 (allowlist
  the Text column as display text); T19's Amber table now shows the with-bounties pace.

### T26. `Shared/Bounties` — pure rules + spec
- **Files:** new `src/shared/Bounties.luau`, `tools/test/bounties.spec.luau`.
- **Do:** UTC day index (`floor((t - resetHour*3600)/86400)`) and Monday-based week index;
  `fresh(now, rng)`; `refresh(state, now, rng)` (new day: roll dailies, reset daily swaps;
  new week: roll weeklies; completed-but-unclaimed bounties are paid out on reset, returned
  as an amount); Haul: `canClaimHaul`, `claimHaul` (once per UTC day; advances day 1→7 then
  loops; missed days pause it unless the lever says reset); `roll` (one per slot, no
  duplicates, never the one just swapped out); `swap` (unfinished and unclaimed only, within
  the swap allowance); `progress(state, event, target, amount, context)`; `claim`;
  `sanitize(raw)` (nil, garbage, unknown ids, wrong types → a valid state; unknown ids
  dropped and refilled).
- **Accept:** specs cover: old profile without the field; garbage field; day boundary at
  00:00 UTC; Sunday 23:59 → Monday 00:00 rolls weeklies; double claim refused; swap on a
  done bounty refused; swap limit; unclaimed payout on reset; Haul loop after day 7; missed
  day pauses. All existing specs still green.

### T27. Progression: save, load, claim and swap (final; uses the T26 API as built)
- **Files:** `src/server/Progression.luau` (sole owner of the saved profile), its remote.
  Plus two text cells on the Bounties sheet (#82): Horn Breaker Text → "Pop {n} Triceratops
  (team pops count)", Tyrant's End Text → "Pop a T-Rex (team pops count)" (assert the old
  text; the Config diff is those two `text` lines).
- **Do:** profile field `rewards`, written by `save` and read through
  `Bounties.sanitize(raw.rewards, os.time(), rng)` (rng = one `Random.new()` per server; a
  missing or broken field becomes `Bounties.fresh`, so old saves load cleanly). Call
  `Bounties.refresh(state, os.time(), rng)` on load, before every claim/swap, and at match
  end; add the Amber it returns to `cores` and remember it as `lastResetPayout` (published
  once, cleared when the board is next opened). Remote actions, validated server-side and
  **Lobby only** (like unlocks): `claimHaul` (`Bounties.claimHaul`), `claimBounty(id)`
  (`Bounties.claim`), `swapBounty(id)` (`Bounties.swap`); Amber is added only from the
  module's return values; save right after each success. Publish the state to the owner
  only: a `getRewards` action on the same RemoteFunction returning the entries (id,
  progress, claimed), Haul day and claimed-today, swaps left, seconds to daily/weekly reset
  and `lastResetPayout`, plus a player attribute `RewardsClaimable` (bool, from
  `Bounties.claimable`) and `RewardsVersion` (a counter bumped on every change, so the client
  knows to re-ask). Studio J sessions keep not saving.
- **Accept:** check.sh and specs green; a spec for the load path through `sanitize` with a
  round-1 profile (`{cores, owned, mastery, highestRound}` only); grep shows no Amber number
  in the code; export clean after the two text cells.

### T28. Bounty progress from match events (final)
- **Files:** `Progression` (one entry point), `Main` (wiring), `Scoreboard`/`Towers`/`Hero`/
  `Hazards` (the onPop hook gains the species key), `Shop` (build, upgrade, repair), `Hero`
  (ability used), `Waves` or `Main` (round started), `Progression.endMatch` (clear). No
  `Airdrops` hook (the chest event was dropped, #75).
- **Do:** `Progression.bountyEvent(player, event, target, amount, context)` calls
  `Bounties.progress` and, for each id it returns, fires the private toast "Bounty bagged:
  <Title> (+N Amber)" and republishes. It ignores calls unless State is Building or Playing.
  Call sites, exactly:
  - `pop`: on every pop (not a shrink), for **every hunter in the match**, target = species
    key, `context.credited = true` for the hunter Scoreboard credits and `false` for the
    rest (the module then counts it for them only if the species is a boss). This one event
    also feeds the pop-any bounties (Busy Day, Stampede); there is no separate `popTotal`
    call.
  - `reachRound`: once per round, when the round starts, amount = the round number, for
    every hunter in the match.
  - `clear`: at match end on a clear, target = the difficulty key, for every hunter still
    in the server.
  - `ability`: when the server accepts an ability use. `build`: a tower placed. `upgrade`:
    an upgrade bought (a teammate's tower counts for the buyer). `repair`: only when the
    repaired tower was **trampled** (KO before the repair), for the hunter who paid.
- **Accept:** a spec or audit check proves each of `Bounties.EVENTS` has a call site;
  specs green; no cash or Amber changes outside claims; the Scoreboard's pop counts are
  unchanged.

### T28b. Gear Check counts only during a round (small server fix, DECISIONS #85)
- **Files:** `src/server/Progression.luau` (or `Shared/Profile`), spec.
- **Rule:** the `ability` event advances bounties **only while State is `Playing`**; every
  other event keeps counting in Building and Playing as now. Nothing else changes (build,
  sell-and-rebuild and upgrade loops are accepted: they cost cash).
- **Accept:** a spec: `ability` in Building gives no progress, in Playing it does; `build`
  in Building still counts; specs and audit green. Run after T29's Builder is done if the
  files overlap.

### T29. Hunt Board screen on the home screen — 🦖 (wording, look)
- **Files:** `src/client/Home.client.luau` (or a new `HuntBoard.client.luau`),
  `src/shared/PanelRules.luau` + spec.
- **Do:** a Hunt Board button on the home screen with a dot when something is claimable;
  key **G** toggles it. Sections: Daily Haul (7 tiles, today highlighted, Claim), Daily
  Bounties (3 rows: text, progress bar, Amber, Claim or Swap), Weekly Bounties (3 rows),
  "New bounties in 5h 12m" (UTC). Buttons disable while a request is in flight.
- **No-trap checklist (DIRECTION):** fits any window size with the X always visible (rows
  scroll inside a box capped like the existing panels; the panel narrows on small
  screens); frees the mouse while open; closes with G and with the X; PanelRules mode
  `huntBoard` is allowed only in Lobby and closes on every state change (Play pressed,
  match start); Play stays reachable for every player while it's open; every player can
  open it, not just the host.
- **Data (final):** read state with the `getRewards` action; re-ask when the player's
  `RewardsVersion` attribute changes and when the board opens; the dot follows
  `RewardsClaimable`; count the reset timer down locally from the seconds returned. Card
  text = the sheet's Text with `{n}` filled in; the Amber chip and Title come from
  `Config.Bounties`. Haul amounts come from `Config.DailyHaul`. Show `lastResetPayout` as
  the one dim line when it's above 0. The look and wording are in "Round 9 rulings" above.
- **Accept:** panelrules spec covers `huntBoard`; check.sh green; screenshots not possible:
  "statically checked, not playtested".
- **Signed off (Director, de6a828, DECISIONS #87–#90):** every no-trap item checked in the
  code; 213 specs, audit strict 0; not playtested. No tooltip (#88); four-button action row
  (#89); the board covers the mode/track/difficulty cards while open (#90). Two small text
  follow-ups are T29b.

### T29b. Hunt Board wording follow-ups (text only; DECISIONS #91–#94) — 🦖 Round 10
- **Files:** the Bounties sheet (Title / Text cells, openpyxl, then re-export and diff
  `Config.luau`: only the lines below may change), `src/shared/HuntBoard.luau`,
  `src/shared/Bounties.luau` (`doneText`), `src/client/HuntBoard.client.luau`,
  `src/client/Shop.client.luau` and `src/server/Progression.luau` (strings only),
  the comment in `Hud.client.luau`, specs. No layout, rule or number change. Event keys
  `pop` / `popTotal` and the "Pops" leaderstat (#27, Jovan's list) stay.
- **Sheet, Text (#93):** every `Pop {n} X` → `Take down {n} X` (Compies, Raptors,
  Pachycephalosaurs, Ankylosaurs, Pteranodons, Gallimimus; both `dinos of any kind` rows);
  `Pop {n} Triceratops (team pops count)` → `Take down {n} Triceratops (team take-downs count)`;
  `Pop a T-Rex (team pops count)` → `Take down a T-Rex (team take-downs count)`.
- **Sheet, Title (#93):** `D_DEEP_TRAIL_25` → `Deeper Trail`; `W_DEEP_TRAIL_2` → `Long Trail`;
  `W_DEEP_TRAIL_4` → `Longest Trail` (`D_DEEP_TRAIL_15` stays `Deep Trail`).
- **Toast (#94):** `Bounties.doneText` → `Bounty ready: Raptor Cull (claim +15 Amber at the Hunt Board)`.
- **Board strings (#94):** loading line (not the buttons) `…` → `Checking the board…`;
  `HuntBoard.UNREACHABLE` → `Couldn't reach the Hunt Board. Try again in a moment.`; the line
  under the header → `New daily bounties in 5h 12m`; the line beside Weekly Bounties →
  `New in 3d 4h`.
- **Server replies (#94):** `Already claimed today` → `Today's Haul is already claimed`;
  `Swapped` → `Bounty swapped`; `The Hunt Board isn't available right now` (both places) →
  `The Hunt Board is closed right now`. `That bounty can't be claimed` stays.
- **Not-saving note (#94):** in `HuntBoard.client` and `Shop.client`, →
  `Progress isn't saving right now.`; the "publish the place (SETUP.md)" hint becomes one
  server `warn` per session if Progression doesn't already print one.
- **Haul note (#91):** `HuntBoard.haulNote(resetAfter: number?)` (default: the
  `HaulResetsAfterMissedDays` lever, like `Bounties.nextHaulDay`) never returns nil:
  0 → "Missed days don't reset your Haul."; 1 → "Miss a day and your Haul starts over.";
  n > 1 → "Miss {n} days in a row and your Haul starts over."
- **Key hint (#92):** `HuntBoard.BUTTON` = "Hunt Board  (G)" (two spaces, round brackets,
  like "Choose hero  (H)"). This overrides "Hunt Board [G]" in the Round 9 rulings above.
- **Signed off (Director, b8af6b1, DECISIONS #96):** all strings as written; 214 specs.
- **Accept:** specs for the three note cases (0, 1, 3), the button text, both countdown
  lines, the toast and the unreachable line; a spec (or exporter check) that no two bounties
  in one pool share a Title; `grep -n '"Pop \|pops count' src/shared/Config.luau` finds
  nothing; the Config diff is only those Text / Title lines; the longest card text
  (`Take down {n} Triceratops (team take-downs count)`) and the toast wrap or fit without
  clipping (say how); `tools/test.sh` and `check.sh` green, audit strict 0; "statically
  checked, not playtested".

## Part F — Studio playtest and wrap-up

### T31. Studio playtest by the Tester (Jovan, 2026-10-01; DECISIONS #95) — runs before T30
- **Who / how:** the Tester (`GAUNTLET.md`), through `tools/studio/mcp.py` (`tools`, then
  `call <tool> '<json>'`; every call needs the `studio_id` from `list_roblox_studios`).
  Runs after T29b is committed. If no Studio is listed (Jovan hasn't enabled "Enable Studio
  as MCP server"), write that in `PLAYTEST.md` and stop: T30 then says "Studio testing
  unavailable".
- **Must not:** edit game code, the spreadsheet or any doc but `PLAYTEST.md`; publish or
  save the place; change the place outside play mode (no edit-mode `execute_luau` that
  writes, no moving or deleting instances); wipe or write DataStores; leave play mode
  running (always `start_stop_play` stop at the end, also after a failure). In play mode
  `execute_luau` is for **reading** state (attributes, GUI positions and sizes); drive the
  game with keys and the mouse like a player, plus the Studio keys K (cash), J (Amber +
  unlocks, turns saving off for the session) and L (halve the nearest tower's HP).
  **Before any claim, swap or unlock:** read the player's `SaveStatus`; if it is `saved`,
  press J first; if it still says `saved`, skip those steps and report it.
- **Output:** `PLAYTEST.md`: one row per step: PASS / FAIL / NOT TESTABLE, what was seen,
  and the evidence (console lines; screenshots in `playtest/`, named by step). After every
  step check `get_console_output`: any error or warning from our scripts is a FAIL for
  that step. Bugs go to the Director, who queues fixes for the Builder. Feel questions
  (is round 11/21/31 too hard, is PLAY too small) are **not** judged: list them for Jovan.
- **Script, in priority order** (solo, Easy, first track unless said):
  1. **Boot.** Start play. *Pass:* home screen shows, no console errors, mouse free, Play
     starts Building, Start begins round 1, dinos walk and towers fire.
  2. **Hunt Board.** In the Lobby: G opens, G closes; the home button opens and closes; the
     X closes. Open it and press H, then M: the board gives way, nothing overlaps. Open it
     and press Play: it closes. In Building and Playing, G does nothing. *Pass:* all of
     that; 7 Haul tiles, 3 daily and 3 weekly cards, both countdowns; PLAY is visible and
     clickable while the board is open.
  3. **Claim and swap.** Claim today's Haul: the tile gets its stamp, the Amber line on the
     home screen rises by the tile's amount, the dot on the button follows. Swap one daily:
     the card changes, the button goes away at 0 left. Claim again / swap again: refused with
     a plain line, no error. *Pass:* amounts match `Config.DailyHaul`; no double pay.
  4. **Bounty progress.** Play a match that advances a rolled bounty (Pitch Camp, Sharpen
     Up, Busy Day or a species one; K for cash). *Pass:* the toast shows once when one
     finishes; back in the Lobby the card shows the progress or Claim; Claim pays the chip's
     amount and stamps BAGGED. Gear Check: the ability in Building adds nothing (#85).
  5. **Dino attacks and hunter HP.** Stand near the trail from round ~5. *Pass:* dinos bite
     when close; mid/high tiers throw with a warning ring that can be walked out of; HP
     drops on a hit and comes back +25 when a round ends (cap 100); what happens at 0 HP
     matches `VISION.md`; no errors.
  6. **Trample and repair.** L twice on a tower (or let dinos do it). *Pass:* at 0 HP it
     reads Trampled and stops firing; the tower panel offers Repair with a price; paying
     takes that cash and the tower fires again; it can't be upgraded while trampled if the
     docs say so.
  7. **Field Medic, Field Hospital, Armory.** J for unlocks, then pick the Medic (H) and
     build both towers. *Pass:* each does what `HEROES.md` / `UPGRADES.md` say (heals
     hunters / repairs or heals in range / damage resist), visible in HP numbers read
     before and after; no errors.
  8. **Supply Camp.** Build one, buy Yield tier 1 and Airdrop tier 1 (K). *Pass:* round
     income rises by the sheet's amount at round end; a chest drops, can be picked up and
     pays the sheet's cash.
  9. **No-trap sweep, every panel** (B list, placing, tower panel, H, U, M, Hunt Board,
     result screen): opens with its key, closes with the same key and its X, mouse free
     while open, closes on the state changes `Shared/PanelRules` says. Read each open
     panel's close button `AbsolutePosition` / `AbsoluteSize` against the viewport: *Pass*
     = fully inside. **Small windows:** only if the tools can change the viewport size;
     otherwise NOT TESTABLE, for Jovan (try ~800×450 and a phone emulator).
  10. **A full match end.** Lose on purpose (no towers): result screen, Amber as the rules
      say (solo loss 0), back to the Lobby, the Hunt Board still opens.
- **Accept:** `PLAYTEST.md` covers every step with evidence or NOT TESTABLE and why; play
  mode stopped; nothing but `PLAYTEST.md` and `playtest/` changed (`git status`).

**T31 status (2026-10-01): OPEN, not run.** `tools/studio/mcp.py call list_roblox_studios`
returns no Studio: Jovan has to turn on Assistant Settings → Manage MCP Servers → "Enable
Studio as MCP server". Run T31 as soon as a Studio is listed; its bugs become new tasks.

### T30. Docs and round-2 recap — **done 2026-10-01**, noting "Studio testing pending" (DECISIONS #96)
- `VISION.md` (Amber: Daily Haul and Bounties, the "log-ins never beat playing" bars),
  `ARCHITECTURE.md` (layout: `Shared/Bounties`; §4: Progression owns the rewards state),
  `CLAUDE.md` status, `UPGRADES.md` if T20/T23 changed what a tier does.
- The Director appends the round-2 recap to `RECAP.md`: what changed (with model before/
  after), what to playtest first, and the ask-Jovan list (DECISIONS #58, #60, #61, #62, #64,
  the 🦖 names).

**Stop here. Phase 7 is out of scope.**

---

# Round 1 (history) — Step 2 + wide polish (Director, 2026-09-30)

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
- **Goal:** DECISIONS #38 and #39.
- **Files:** `TowerLook.setKnockedOut`: the smoke becomes dust (RGB 150,125,90, Opacity 0.2,
  RiseVelocity 1.5), and the tilt axis is picked from the base position (still 15°). `Hud` and
  `TowerLook` share one orange low-HP colour (e.g. export `LOW_HP_COLOR` from TowerLook, or a
  tiny shared visual constant). `Shop.decorate`: prompt ActionText "Upgrade", or
  "Upgrade / Repair" while hp < maxHp (it updates when HP changes; Towers already publishes
  HP). **Private hit notice (DECISIONS #39, replaces the #36 allowlist):** `Health.damage`
  takes an optional `{species, attack}` source and sends it to that player only (a
  RemoteEvent to that client, or a player attribute). `Hud` shows one line beside the HP
  bar, e.g. "Raptor · Slash −4", faded after 1.5s. A new hit replaces the line, and a repeat of
  the same attack adds up. `DinoAttacks` passes the display name and meleeName/rangedName. No
  text for tower hits or for other players. Bite visual: a small snapping-teeth pair of blocks
  in the species colour instead of the red ball (Effects/DinoLook, visual only). A bitten
  tower's silhouette flashes red for about 0.15s (TowerLook, restoring materials and colours;
  skip if trampled).
- **Accept:** looks spec updated (dust colour, tilt differs for two positions, one low colour);
  audit --strict clean with meleeName/rangedName now read by code; a spec (pure helper) for
  notice text and merging; check clean.

### T13. Threat estimate — does a sensible defence survive Easy?
- **Files:** new `tools/threat.py` (run by `tools/test.sh`, report only): from Track geometry and
  the Rounds/Enemies sheets, it estimates the bite and projectile damage per round to a tower 1
  stud off the lane, at the midpoint between lanes (15 studs), and at an inside corner, on Easy.
  It assumes a dino at full size for its first lane, halving after. It prints the per-round
  totals and the rounds where a mid-gap tower of each type would be KO'd.
- **Target (DECISIONS #42):** bites never reach a mid-gap tower (already met). Add a
  **defended** column to the report = the worst case × 0.5 (a named constant in threat.py with a
  comment citing #42). Rounds 11–30, mid-gap, defended ranged damage per round < 50% of **that
  tower's own** T0 Max HP for the Hunting Blind (50), Mortar Pit (75), Tranq Station (60) and
  Supply Camp (100). The Longshot Perch is checked at a back-line spot (≥ 25 studs from every
  lane, e.g. (−105, 0)) and must take 0. Hug and corner spots are reported, with no target.
- **Spreadsheet (Enemies, assert old values first):** Skull Toss damage 5→3, every 5→8;
  Spike Flick 6→4, 5→8; Gravel Spray 8→5, 4→6.5; Stone Drop 8→5, 4→6.5. Change nothing else.
- **If it still misses,** in this order, re-running after each step: (1) Gravel Spray reach
  25→20; (2) +1s on the cooldown of whichever species dominates the failing rounds. Don't
  touch bites, bosses, Max HP or the targets. Log the final numbers in a DECISIONS row.
- **Accept:** the report is in the commit message; the Config diff is accounted for.

### T13b. Projectile readability (visual only) — 🦖
- **Goal:** DECISIONS #41.
- **Files:** `DinoLook`: warning ring colour (255,70,40), plus a bright thin edge ring; bigger
  Gravel Spray pebbles (still ≤ 3 studs in total); a short head flash on the thrower at launch
  (`DinoAttacks` calls a `DinoLook` helper, restoring the colour afterwards).
- **Accept:** projectiles/looks specs updated (ring colour differs from every
  `TowerLook.COLORS` entry by a clear margin, edge present, pebble size, head restored);
  check clean.

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

### T16b. Round-6 touch-ups (small) — 🦖
- **Goal:** DECISIONS #45–#47. Start it only after T16 is committed.
- **Files:** In `TowerLook` ARMORY, each `Gun{i}` gets a wooden stock (a 0.25×0.6×0.25 Wood
  block at its base, y ≈ 1.25), and its steel part is shortened to 1.5. In
  `TowerLook.setKnockedOut`, the trampled tint goes from (60,60,64) to (45,45,48) for every
  tower. In the `Airdrops` med kit touch, ignore a hunter at full HP, so the kit stays for
  someone who's hurt. Spreadsheet: set the `Tower Upgrades` title cell to "7 towers x 3 paths
  x 5 tiers". Assert it still holds the "5 towers" text before writing it.
- **Round 7 (DECISIONS #48):** **must-fix R7-1:** `TowerLook.flashSaved(model)` flashes the
  saved tower green (60,190,90) for 0.3s and shows a brief "Last Stand!" label. Call it from
  the Last Stand branch of `Towers.damage`, and pulse the saving hospital's "+". R7-2: a pole
  with a green Neon lantern on any hospital whose stats have rescueRespawnMult > 0. R7-3/R7-4:
  in `Tower Upgrades`, scoped to (Field Hospital, Tonic, T3) and (Field Hospital, Rescue, T4),
  rename Adrenaline → Smelling Salts and Supply Runs → Pack Mules. Assert the old names first,
  and update UPGRADES.md. R7-5: in `Shop.client`, "heals N× faster" and "fallen hunters
  respawn at this tent in N% of the usual time". With the renames, the Config diff should be
  exactly those 2 name lines.
- **Accept:** the looks spec covers the stocks, the tint, flashSaved (it restores the
  colours) and the lantern. A towers spec shows that a Last Stand save calls the flash. A spec (or a pure helper) shows
  that a full-HP hunter doesn't take a kit. Exporter clean; check clean.

### T16c. Round-8 Medic touch-ups (small) — 🦖
- **Goal:** DECISIONS #50. Start it after T16b is committed.
- **Files:**
  - `DinoLook.setMuzzled`: the strap is (165,115,65) with a 0.35-stud steel-grey Metal buckle
    welded on top. Add a 0.3s lighter flash of the strap, used when Lullaby Rounds spreads the
    lock (`Hero` calls it for the spread targets). No "zzz".
  - `Shop.client` Field Medic slow line: "dinos you hit are slowed N% for Ns (not bosses)".
  - `Hero Upgrades`, scoped to (Field Medic, Lever Action, T5): rename Hip Fire → Runaway
    Lever. Assert the old name first. Update the HEROES.md table and its description line.
- **Accept:** the looks spec covers the strap colour (clearly different from every dino's
  head and jaw colour), the buckle and the flash restore. The Config diff is exactly the 1
  name line. Exporter, audit and check clean.

### T16d. Jaw Lock strap colour (one line) — 🦖
- **Goal:** DECISIONS #51. In `DinoLook`, the strap colour goes from (165,115,65) to
  (185,100,45). In the looks spec, raise the strap's distance threshold from 20 to 40 against
  every dino head and jaw colour.
- **Accept:** looks spec green; check clean.

### T17. Docs and recap
- `CLAUDE.md` status (Step 2 and polish: statically checked and headless-tested, not
  playtested), `ARCHITECTURE.md` (layout, §4 ownership: Health, DinoAttacks, tower HP in
  Towers; the phase table row "Step 2"), `VISION.md` ("Towers with HP" ✅; Step 2 no longer
  "planned"), `UPGRADES.md`/`HEROES.md` status keys. 🦖 final wording pass. The recap
  includes the DECISIONS #27 "ask Jovan" rename list, so he can approve it in one go.
- The Director writes the recap for Jovan: what changed, what to try in Studio first (L
  key, a round-11 Pachy wave near lane-hugging towers, repair, Medic heal, Armory resist),
  and which numbers are seeds. Playtest watch items: boss throws from round 31 (#44), the
  Horn Toss boulder look (#40), the R4 glow question (#33), and the #27 rename list.

**Stop here. Phase 7 (team battle, battle royale, buy-ins, per-team cash) is out of scope.**
