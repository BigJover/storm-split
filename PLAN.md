# Plan — Round 2: balance pass + daily log-in rewards and bounties (Director, 2026-10-01)

Scope (Jovan, 2026-10-01, `GAUNTLET.md` "Round 2 scope"): (1) a balance pass across the whole
game, justified by headless models because there's no playtest data yet; (2) daily log-in
rewards plus daily and weekly challenges, for retention. **Stop before phase 7** and append a
round-2 recap to `RECAP.md`. Design calls: `DECISIONS.md` #54–#83. Round 1's plan is kept
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

## Part F — Wrap-up

### T30. Docs and round-2 recap
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
