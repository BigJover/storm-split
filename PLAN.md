# Plan — Phase 9: the 4× towers and A/B/C upgrades (Director, 2026-10-13)

Jovan's answer to T97 (verbatim in `DIRECTION.md` "The 4× towers and A/B/C upgrades"): all 7
`TOWERS_LATER.md` towers at the proposed prices; **an in-game A/B/C pick at tiers 4 and 5 of
every path** — the 11 built towers, the 7 new ones and all 12 hero paths (hero tier 6 stays
one capstone); Extinction Event automatic; Raider options in, always with a dino effect.
Calls: `DECISIONS.md` #274–#287. **Phase 9, not a Phase 8 batch (#274).** Phase 7/8 rules
hold (one task = one commit, pushed; check/export/test green; Config diff after every sheet
change, every changed line accounted for; openpyxl, assert each cell old-value-or-empty;
append rows, never insert; pure rules first; co-op specs re-run every task; no publish, no
DataStore writes from an agent). N15 rides any `Battle` commit (#272).

**Status (2026-10-13): planned. Next: batch 9a (T110 + T111).**
**Status (2026-10-13, later): 9a + 9b done (c1a7c5a, 0f82bb7, 929b66a, cd6a413, cd749d2; 706 specs); Tester Run 8 running. 9c designed below (#290). Next: 🦖 names 9c → Builder T114 + T115.**
**Status (2026-10-13, Director): 9d + 9e designed below (#292–#297; 96 options, metrics, 6 new mechanics). Next after 9c: 🦖 names 9d → T116–T118, then 9e → T119–T120.**
**Status (2026-10-13, Director): 9f designed below (#298–#302; 48 hero options, per-path metrics, 1 new mechanic). Next after 9e: 🦖 names 9f → T121–T122.**
**Status (2026-10-14, Director): 9g–9j designed below (#312–#320): the seven 4× towers, Round-19 names, rows + options + metrics + mechanics, released per pair (T124b / T126b / T128b / T130b). Next after 9f: T123.** **Update (2026-10-14): 9g built; next = T124c (finishes T124b, #325–#328), then Tester Run 9g.** **Update (2026-10-15): T124c steps 1–4 in (03c9634), release held on King of the Pack bar 3; next = T124d (#329–#330, King Rate x 1.25 + frozen bar-3 median + release), then Tester Run 9g.**

## Size of the job
| | Slots (T4+T5) | Options to build | New options to design |
|---|---|---|---|
| 11 built towers × 3 paths | 66 | 198 (66 A exist) | **132** B/C (Director, 9c–9e) |
| 4 heroes × 3 paths | 24 | 72 (24 A exist) | **48** B/C — **designed** (9f, #298–#302) |
| 7 new towers × 3 paths | 42 | 126 | 20 T4 "C" — **done** in `TOWERS_LATER.md` (#285) |
| **Total** | 132 | **396** (306 new rows) | **all 180 designed** (9c–9f) |

## The A/B/C system (9a–9b)
- **Sheet (#275).** `Tower Upgrades` and `Hero Upgrades`: new `Option` column (blank at
  tiers 1–3 and hero T6; `A`/`B`/`C` at tiers 4 and 5) and `Blurb` (card line ≤ 60 chars).
  Tiers 1–3 rows stay cumulative. A T4 / T5 / hero-T6 row holds only **its own step**.
  The exporter has a column registry (`mult` / `add` / `max` / `flag` / `set`) and
  **precomposes** cumulative builds: `t4[o]` (3 per path), `t5[o4..o5]` (9 per path),
  hero `t6[o4..o5]` (9). Runtime keeps reading one cumulative row. Existing T4/T5 rows
  become option A by converting them to steps (A4 = T4 ⊖ T3, A5 = T5 ⊖ T4; hero T6 = T6 ⊖ T5).
  New rows (B/C, new towers) are **appended** at the bottom; the exporter groups by
  (tower, path, tier, option), not by row order (confirm the key columns exist; add them if not).
- **Rules (#276–#278).** T5 pick independent of T4 (9 builds/path); same price for every
  option at a tier; a pick is final until the tower is sold; refund unchanged; crossover
  rule unchanged (counts tiers). Heroes: free switch + full refund until Start; T6 needs
  T5 on its path (any letter) and must work after every T5.
- **State (#287).** `tower.pathTiers` unchanged; new `tower.pathPicks[path]` = "", "B", "BA".
  Replicated as a tower attribute (panel, tier label "4B · 5A", spectators, late joiners).
  Hero picks live in `Hero` state. Match-only; nothing saved. Stand-ins/scripted builds = A.
- **Remotes.** Shop/Hero upgrade request gains `option` ("A"/"B"/"C"); the server refuses a
  missing option at T4/T5, any option at T1–3/T6, an unknown letter, or a letter whose row
  doesn't exist (until B/C land, only A is offered or accepted).
- **Panel (#279).** Pure `Shared/OptionPick` layout used by the tower panel and hero U panel:
  3 cards (name, Blurb, price shown once), tap a card then "Buy B — 2,400" to confirm; blocked
  / can't-afford reasons as today; Back + X in the header outside the scroll; cards scroll
  first then scale; stack vertically below the width threshold; every state change closes it.
- **Models (#280).** `value.py --options`: per slot, each option's worth (eDPS/cash; support,
  economy, control metrics as today) within **0.8–1.25× of the slot median**; all 9 builds
  per path under the existing caps (#193/#200; untouchables 1.25–2 × M; Tar Pit = control);
  heroes 0.8–1.25× of the slot median on `hero_dps`/handling, per-hero parity of best builds
  ≤ 1.15 (#235). Raider options (#284): dino part alone ≥ 0.8× the slot median.
  The exporter enforces the bars from 9b on, for slots that have B/C.
- **Audit.** Doc option tables (`| Path | Tier | A | B | C |` under each tower/hero in
  `UPGRADES.md` / `HEROES.md`) match the sheet names, letters and Blurbs; a slot with B but
  not C is a finding; `--strict` demands full A/B/C everywhere from 9k.

## Content rules for B/C (#281, #284)
Keep the path's focus; B/C differ in *how* (target, timing, area, control, support), not just
numbers; reuse built mechanics first, ≤ 3 new mechanics per tower; no tower buttons — "once a
round" fires itself (#283); 2× towers use their unpicked `TOWERS_NEXT.md` ideas first; heroes
only handling / fire mode / special rounds, never raw gun damage; ≤ 1 Raider option per tower,
with the #284 limits (×0.5, Camo Cover, no reveal, no stun/hard stop on hunters, slows ≤ 30%
≤ 3 s, own side only). The Director writes each batch's designs as a table here **before**
its Builder starts; 🦖 names them; the Builder copies them into `UPGRADES.md`/`HEROES.md`.

## Batches (fresh Builder each; Tester steps at the end of each)

**9a — the system, option A only (no number changes).**
- **T110 data + exporter + audit:** `Option`/`Blurb` columns, step conversion of every
  existing T4/T5 (and hero T6) row to option A, column registry, precomposition,
  `Config` shape `tiers[1..3]`, `t4`, `t5`, hero `t6`. Accept: Config diff shows only the
  shape change + Blurbs; a spec asserts every precomposed `(A,A)` build == the old cumulative
  T5 (and hero T6) values; audit reads the option tables; 682 specs green.
- **T111 rules + server:** `Shared/Upgrades.stepFor(def, tiers, picks, path, option)`; Shop and
  Hero take `option`; `pathPicks` + attribute; `TowerStats`/`HeroStats` read the composed row;
  sell/refund, Supply Camp discount, mastery free upgrade, hero switch-refund unchanged.
  Accept: specs for every refusal case; a match bought to 5A plays exactly as before
  (same damage numbers in a fixed-seed spec).

**9b — the pick panel and the models.**
- **T112 `Shared/OptionPick` + tower/hero panels** (#279). Accept: layout specs at 3 window
  sizes (phone-ish, small, full); no-trap checks; with only A present the pick shows one card.
- **T113 `value.py --options` + exporter bars + Raider floor** (#280, #284). Accept: report
  runs on option-A-only data (each slot median = A, so bars pass); a fixture with a dead
  option and a must-pick option both fail.
- **Tester Run 8:** buy a Hunting Blind to 4A then 5A through the pick cards; confirm label
  "4A · 5A", sell refund, a T3→T4 pick at a small window (cards stack, X works), hero U panel
  pick + switch-refund before Start; a co-op round and a Camp Clash round with picked towers.

**9c — B/C for the starters** (Hunting Blind, Longshot Perch, Mortar Pit: 9 paths, **36 options**).
**DESIGNED (Director, 2026-10-13, #290) — enter as written** (🦖 names first; working names
here). Append one `Tower Upgrades` row per option at the bottom: Tower / Path / Path focus /
Tier copied from that slot's A row; `Upgrade cost` `=E<A row>`, `Cumulative cost`
`=F<A row>` (same price, #277); `Damage x`, `Rate x`, `Targets x`, `Range x` = 1 unless
listed; every other cell blank unless listed; `PvP effect` blank (no Raider option in 9c).
Checked on a sheet copy: `python3 tools/value.py --options copy.xlsx` gives **no OPTIONS or
WORTH finding** for these three towers (all 27 starter T5 cells, all 9 builds per path).
Model blind spots (credited at 0 by `tower_worth`, so these options carry damage to clear the
bar; re-check feel in the Tester run, tune in 9k): stun, knockback, Strips armour, Boss mark %.
New wirings on these towers (the Builder makes each column work for a tower that didn't use
it; keep it generic in `TowerStats`/`Towers`): **Strips armour** on a hit (Blind, Perch,
Mortar — today a Tranq zone effect; on a hit = that dino loses armour for 3 s, `Strip (s)`
Tuning row seed 3), **Boss mark %** (Falcon's Hooded Scout aura) on Blind/Perch, **Knockback**
on Perch shots, **Stun / Knockback / Burn** carried by Mortar bomblets. "Amounts take the
higher" (#275) is why T5 line-hit options are tuned against their T4 siblings.

**Hunting Blind**

| Path | Tier | Opt | Name (working) | Blurb (card) | Cells (own step; unset = 1 / blank) |
|---|---|---|---|---|---|
| Lookout | 4 | B | Signal Mirror | Towers in range fire 18% faster | Damage x 1.15, Aura rate % 18 |
| Lookout | 4 | C | Spotter's Call | Its target takes +15% from every tower | Damage x 1.2, Range x 1.1, Mark % 15 |
| Lookout | 5 | B | Beacon Fire | Towers in range fire 35% faster | Damage x 1.4, Range x 1.15, Aura rate % 35 |
| Lookout | 5 | C | Trophy Spotter | Bosses in range take +40% from everything | Damage x 1.55, Range x 1.1, Boss mark % 40 |
| Trigger Happy | 4 | B | Belt Feed | Never stops to reload: fires 45% faster | Damage x 1.05, Rate x 1.45 |
| Trigger Happy | 4 | C | Long Burst | Fires faster from further away | Damage x 1.2, Rate x 1.55, Range x 1.25 |
| Trigger Happy | 5 | B | Bullet Storm | Lighter bullets go through 4 dinos | Damage x 0.8, Rate x 1, Line hits 4 |
| Trigger Happy | 5 | C | Shredder | The hail of bullets strips armour | Damage x 1.7, Rate x 1.35, Strips armour Yes |
| Hardliner | 4 | B | Cracking Shot | Goes through 2 dinos and strips their armour | Damage x 2.7, Line hits 2, Strips armour Yes |
| Hardliner | 4 | C | Heavy Slug | Goes through 2 dinos, shrinking each 3 sizes | Damage x 2.6, Line hits 2, Size breaks 3 |
| Hardliner | 5 | B | Jolt Rounds | Hits jolt dinos still for a moment | Damage x 4.6, Armoured x 2, Stun (s) 0.3 |
| Hardliner | 5 | C | Rail Lance | Each bullet goes through 6 dinos | Damage x 1.5, Armoured x 1.5, Line hits 6 |

**Longshot Perch**

| Path | Tier | Opt | Name (working) | Blurb (card) | Cells (own step; unset = 1 / blank) |
|---|---|---|---|---|---|
| Deadeye | 4 | B | Wind Shear | Shots shove the whole line 3 studs back | Damage x 1.45, Targets x 1.2, Line hits 5, Knockback (studs) 3 |
| Deadeye | 4 | C | Fast Bolt | Fires much faster through 5 dinos | Damage x 1.1, Rate x 1.45, Line hits 5 |
| Deadeye | 5 | B | Piercing Gale | Fast shots through 8 dinos | Damage x 1.55, Rate x 1.6, Targets x 1.2, Line hits 8 |
| Deadeye | 5 | C | Shatterline | Every dino in the line loses its armour | Damage x 2.4, Targets x 1.2, Line hits 8, Strips armour Yes |
| Spotter | 4 | B | Painted Target | Bosses in range take +25% too | Damage x 1.3, Rate x 1.3, Mark % 30, Boss mark % 25 |
| Spotter | 4 | C | Quick Spot | Fires much faster, marks more often | Damage x 1.2, Rate x 1.65 |
| Spotter | 5 | B | Spotter Network | Towers in range hit 15% harder | Damage x 1.3, Rate x 1.35, Mark % 45, Aura damage % 15 |
| Spotter | 5 | C | Kill Order | Every boss in range takes +40% | Damage x 1.35, Rate x 1.4, Mark % 50, Boss mark % 40 |
| Big Bore | 4 | B | Elephant Gun | Twice the damage against bosses | Damage x 1.7, Boss x 2 |
| Big Bore | 4 | C | Knockdown Round | Knocks the hit dino 4 studs back | Damage x 2.8, Knockback (studs) 4, Size breaks 3 |
| Big Bore | 5 | B | Bone Splitter | Each shot shrinks a dino 5 sizes | Damage x 1.9, Boss x 1.6, Size breaks 5 |
| Big Bore | 5 | C | Hammer Shot | Stuns 1.2 s and knocks 6 studs back | Damage x 2.3, Stun (s) 1.2, Knockback (studs) 6 |

**Mortar Pit**

| Path | Tier | Opt | Name (working) | Blurb (card) | Cells (own step; unset = 1 / blank) |
|---|---|---|---|---|---|
| Blast | 4 | B | Big Shell | Much bigger blasts | Damage x 1.3, Targets x 1.4, Splash x 1.3 |
| Blast | 4 | C | White Phosphorus | A short, very hot burning patch | Damage x 1.4, Targets x 1.3, Burn DPS 3, Burn (s) 2 |
| Blast | 5 | B | Blast Furnace | Huge blasts that hit harder | Damage x 1.5, Targets x 1.4, Splash x 1.3 |
| Blast | 5 | C | Inferno Shell | Patches burn twice as hot | Damage x 1.45, Targets x 1.3, Burn DPS 6, Burn (s) 4 |
| Cluster | 4 | B | Fire Bomblets | Bomblets leave small fires | Damage x 1.4, Targets x 1.3, Burn DPS 2, Burn (s) 2 |
| Cluster | 4 | C | Wide Scatter | Bomblets spread over a wider area | Damage x 1.3, Targets x 1.45, Splash x 1.3 |
| Cluster | 5 | B | Firecracker Rain | Bomblets burst a third time | Damage x 1.4, Targets x 1.35, Bomblet generations 3 |
| Cluster | 5 | C | Thumper Shells | Bomblets knock small dinos back | Damage x 1.45, Targets x 1.3, Knockback (studs) 2, Stun (s) 0.2 |
| Concussive | 4 | B | Aftershock | Stuns hit dinos for half a second | Damage x 1.8, Stun (s) 0.5 |
| Concussive | 4 | C | Armour Splitter | Hit dinos lose their armour | Damage x 1.8, Armoured x 1.5, Strips armour Yes |
| Concussive | 5 | B | Seismic Charge | Throws dinos 10 studs back | Damage x 2.4, Knockback (studs) 10 |
| Concussive | 5 | C | Rockfall | A short stun that holds bosses too | Damage x 2.3, Stun (s) 0.5, Stuns bosses Yes |

- **T114** (Blind + Perch rows, wirings, specs: each option's composed stats; a strip / boss
  mark / knockback spec) · **T115** (Mortar rows + bomblet effects, `UPGRADES.md` option
  tables, audit clean, `--options` clean). Tester: one B and one C per tower in a match; each
  card text matches what happens; a stripped Ankylosaurus takes damage from a non-piercing
  tower; Seismic Charge never moves a boss; Rockfall stuns a boss 0.5 s.
- **T115b — 9c review fixes (#303–#307; ONE Builder commit after 9d's running task; assert
  each old value first; the 2 tolerated `audit --strict` findings must be gone after it):**
  1. Hunting Blind Lookout 5C `Name` "Trophy Spotter" → **"Alpha Spotter"** (Blurb unchanged).
  2. Hunting Blind Lookout **T2** `Name` "Long Barrel" → **"Spyglass"** (Brush Beater Slug 4A
     keeps "Long Barrel"); update `UPGRADES.md`.
  3. Hunting Blind Trigger Happy 5C Shredder: `Pierces armour` = Yes; `Damage x` 1.7 → **1.5**
     (the pierce now credits the armoured share); Blurb "Bullets punch through armour and
     strip it". `--options` must stay clean (if not, step Damage x by 0.05 toward the median).
  4. **Bomblet fires cap:** new Tuning row `Bomblet fires per shell` seed **6** (append): a
     shell lights at most 6 burn patches (first generation first, then the next); the rest of
     its bomblets still hit. `value.py` credits bomblet burn as min(fires per shell, cap) ×
     Burn DPS × Burn s (today 0). `--options` clean for Cluster after it.
  5. **Strip on bosses: half time** (Strip (s) × 0.5, as Jaw Lock), in the generic strip rule;
     spec: a boss stripped 1.5 s, a non-boss 3 s.
  Specs + Config diff accounted for; audit `--strict` 0; Tester: none (rides 9d's Tester run:
  Shredder damages an Ankylosaurus; a Firecracker Rain shell shows ≤ 6 fires).
  6. (9d, #308) Armory Outfitter 4B `Name` "Speed Loader" → **"Loading Bench"** (Tracker Trick
     Shot T1 keeps "Speed Loader"); update `UPGRADES.md`.
  7. (#309) **Bounty cash scales with the difficulty's cash multiplier**, exactly as Tar Pit sink
     cash does (same helper in `Economy`); spec: Hard pays the scaled bounty.
  8. (#310) Studio-only **`standinpick <tower> <path> <letters>`** (behind `Shared/StudioOnly`):
     sets a stand-in camp tower's picks (e.g. a stand-in Tranq Station "BC"), so the Tester can
     be the raider; spec: refused on a live server.

**9d — B/C for Tranq Station, Supply Camp, Field Hospital, Armory** (12 paths, **48 options**).
**DESIGNED (Director, 2026-10-13, #292–#295) — enter as written** (🦖 names first; working
names here). Row recipe exactly as 9c (append; Tower / Path / Path focus / Tier from the
slot's A row; `Upgrade cost` `=E<A row>`, `Cumulative cost` `=F<A row>`; `Damage x`,
`Rate x`, `Targets x`, `Range x` = 1 unless listed; every other cell blank unless listed).
Raider rows: `PvP effect` = `yes` (one per tower, #284). Steps combine as the column
registry says (x columns multiply, amounts take the higher), so a T5 cell lower than its T4
sibling's does nothing after that T4 — the numbers below are tuned for all 9 builds.

**Worth metrics for these paths (#292; #289 — they replace today's `tower_worth` branches
for these towers; r31–40 mix, `boss` = the band's boss HP share, dwell 2 s):**
| Path | Metric (one build) |
|---|---|
| Tranq Sedate | Slow % × (1 + Slow linger ÷ 2) × Range x × (1 + boss if Slows bosses) |
| Tranq Knockout | Freeze (s) ÷ Freeze every (s) × Range x × (1 + boss if Freeze holds bosses) |
| Tranq Weak Spot | eDPS + brittle aura credit, with **Boss mark % × boss** added to Aura damage % |
| Supply Yield | 150 × Income x + Interest cap (if Interest %) + Bounty cash × 30 (in-range take-downs a round, r31–40: a quarter of the round's dinos) |
| Supply Airdrop / Logistics | today's branches (chests × chest cash + income; discount + 100 × refund over base + aura rate) |
| Hospital Ward | Heal/s × Range x × (1 + 0.5 × Revive speed x if Revives) |
| Hospital Rescue | (Med kits × Med kit heal + 1) × Range x × (2 − respawn x) |
| Hospital Tonic | Aura HP % + Aura rate % + 10 if Last stand + Biter slow % × Biter slow (s) ÷ 4 |
| Armory Plating | Resist % + Thorns damage + 20 × Stuns biters (s) |
| Armory Gunsmith | today's aura credit |
| Armory Outfitter | today's formula, but reading the hunter reload/spread/recoil multipliers from the **composed build** (today they read 1, so B/C tie) |
A Raider option's worth is the same metric with the Raider columns ignored (its dino part).
Checked on a sheet copy with these metrics (Director scratch, `value.py` internals): every
one of the 12 paths' 4 slots (T4, T5 after A/B/C) has every option within 0.8–1.25× of its
median and both Raider options ≥ 0.8× the others' median. Today's `value.py --options`
(old metrics) flags 16 of them — that's the metric gap, not the designs: **the metric change
goes in the same commit as each tower's rows** (the exporter enforces the bars).

**New mechanics (9d; keep generic, 9e/9g reuse them):**
1. **Raider sting** (`Raider slow %`, `Raider slow (s)`, `Raider damage`; new Tuning row
   `Raider sting cooldown (s)` seed 3): battles only, own side only. When an enemy hunter
   damages a tower on this tower's side while inside this tower's range, this tower stings
   them: Raider damage × 0.5 (the PvP rule) and a slow of Raider slow % for Raider slow (s);
   at most once per cooldown per hunter, never through Camo Cover, never a stun or a reveal;
   slows ≤ 30 % and ≤ 3 s (exporter check). Co-op: does nothing (the option's dino part
   carries it). Used by Sleeper Darts, Barbed Wire; 9e: Rod Strike, Guard Falcons, Bog
   Boots, Snag Line.
2. **Biter slow** (`Biter slow %`, `Biter slow (s)`): a dino that bites a tower in range is
   slowed (not bosses). Same mechanic as #284's Raider Glue bonus (9g reuses it).
3. **Bounty cash** (`Bounty cash`): the Supply Camp's owner gets this much cash for every dino
   taken down inside its range (by anyone on its side; sinks count, shrinks don't), through
   `Economy`. Bounty cash amounts take the higher (no stacking across camps: the strongest
   camp covering the take-down pays).
Wirings (existing columns on a tower that didn't use them): Tranq `Aura rate %` at T4/T5 and
`Boss mark %` (Weak Spot); Supply `Aura rate %` + `Sell refund` together (Depot); Hospital
`Revive speed x` at T4. Auras don't stack (strongest wins), as today.

**Tranq Station**

| Path | Tier | Opt | Name (working) | Blurb (card) | Cells (own step; unset = 1 / blank) |
|---|---|---|---|---|---|
| Sedate | 4 | B | Drowsy Trail | Dinos stay slowed 4 s after they leave | Damage x 1.3, Rate x 1.15132, Slow % 65, Slow linger (s) 4 |
| Sedate | 4 | C | Sleeper Darts | Also slows raiders who shoot your towers | Damage x 1.3, Rate x 1.15132, Slow % 72, Raider slow % 30, Raider slow (s) 2, **PvP effect yes** |
| Sedate | 5 | B | Fog Bank | A huge sleepy cloud slows a much wider ring | Damage x 1.2972, Rate x 1.14857, Slow % 80, Range x 1.6, Slow linger (s) 3 |
| Sedate | 5 | C | Long Nap | Dinos stay slowed 7 s after they leave | Damage x 1.2972, Rate x 1.14857, Slow % 80, Slow linger (s) 7 |
| Knockout | 4 | B | Long Sleep | Knockouts hold dinos 1.8 s instead of 1 | Damage x 1.34959, Rate x 1.42308, Freeze (s) 1.8, Freeze damage 3 |
| Knockout | 4 | C | Knockout Ring | Knocks out dinos in a much wider ring | Damage x 1.34959, Rate x 1.42308, Range x 1.3, Freeze every (s) 6, Freeze damage 3 |
| Knockout | 5 | B | Snooze Alarm | Knocks out every dino in range every 4 s | Damage x 1.3494, Rate x 1.41769, Freeze every (s) 4, Freeze (s) 2, Freeze damage 5 |
| Knockout | 5 | C | Sleep Wave | A giant knockout ring | Damage x 1.3494, Rate x 1.41769, Range x 1.6, Freeze (s) 2, Freeze damage 5 |
| Weak Spot | 4 | B | Pack Instinct | Towers in range fire 20% faster | Damage x 1.9, Aura rate % 20, Brittle % 40 |
| Weak Spot | 4 | C | Big Game Weakness | Bosses in range take +40% from everything | Damage x 1.9, Boss mark % 40, Brittle % 40 |
| Weak Spot | 5 | B | Feeding Frenzy | Towers in range fire 35% faster | Damage x 1.9, Aura rate % 35, Brittle % 60 |
| Weak Spot | 5 | C | Killing Ground | Bosses in range take +75% from everything | Damage x 1.9, Boss mark % 75, Brittle % 60 |

**Supply Camp**

| Path | Tier | Opt | Name (working) | Blurb (card) | Cells (own step; unset = 1 / blank) |
|---|---|---|---|---|---|
| Yield | 4 | B | Savings Jar | Less income, but 3% interest on banked cash | Income x 1.45, Interest % 3, Interest cap 250 |
| Yield | 4 | C | Bounty Board | +8 cash for each dino taken down in its range | Income x 1.3, Bounty cash 8 |
| Yield | 5 | B | Gold Reserve | Big interest: 8% on banked cash | Income x 1.3, Interest % 8, Interest cap 1000 |
| Yield | 5 | C | Bounty Hall | +25 cash for each dino taken down in its range | Income x 1.3, Bounty cash 25 |
| Airdrop | 4 | B | Heavy Crates | Two crates a round, worth more each | Chest cash 790 |
| Airdrop | 4 | C | Extra Drop | Four crates a round | Chests 4 |
| Airdrop | 5 | B | Supply Fleet | Five crates a round | Chests 5, Chest cash 790 |
| Airdrop | 5 | C | Gold Crates | Four crates a round, worth 900 each | Chests 4, Chest cash 900 |
| Logistics | 4 | B | Bulk Buyer | Upgrades in range cost 18% less | Upgrade discount % 18 |
| Logistics | 4 | C | Scrap Dealer | Towers in range sell for 97% | Sell refund 0.97 |
| Logistics | 5 | B | Wholesale | Upgrades in range cost 32% less | Upgrade discount % 32 |
| Logistics | 5 | C | Depot | Towers in range fire 20% faster, cost 15% less | Aura rate % 20, Upgrade discount % 15, Sell refund 0.95 |

**Field Hospital**

| Path | Tier | Opt | Name (working) | Blurb (card) | Cells (own step; unset = 1 / blank) |
|---|---|---|---|---|---|
| Ward | 4 | B | Quick Stitch | Trampled towers stand up twice as fast | Revive speed x 1 |
| Ward | 4 | C | Big Tent | Heals towers in a wider ring | Range x 1.25 |
| Ward | 5 | B | Field Ward | Heals a huge ring of towers | Heal x 1.2, Range x 1.4 |
| Ward | 5 | C | Rapid Recovery | Trampled towers jump back up 4x as fast | Heal x 1.25, Revive speed x 2 |
| Rescue | 4 | B | Long Whistle | Kits reach hunters in a much wider ring | Range x 1.3, Med kits 3 |
| Rescue | 4 | C | Kit Bags | Four med kits land each round | Med kits 4 |
| Rescue | 5 | B | Pack Train | Five med kits a round, 50 each | Range x 1.15, Med kits 5, Med kit heal 50 |
| Rescue | 5 | C | Medevac | Downed hunters come back 3x as fast | Range x 1.15, Med kit heal 45, Rescue beacon (respawn x) 0.35 |
| Tonic | 4 | B | Hot Coffee | Towers in range fire 18% faster | Aura rate % 18, Aura HP % 25 |
| Tonic | 4 | C | Bitter Tonic | Dinos that bite towers in range get slowed | Aura HP % 25, Biter slow % 25, Biter slow (s) 2 |
| Tonic | 5 | B | Adrenaline | Towers in range fire 30% faster | Aura rate % 30, Aura HP % 40 |
| Tonic | 5 | C | Bitter Brew | Biters slowed 30% for 3 s; towers +45% HP | Aura HP % 45, Biter slow % 30, Biter slow (s) 3 |

**Armory**

| Path | Tier | Opt | Name (working) | Blurb (card) | Cells (own step; unset = 1 / blank) |
|---|---|---|---|---|---|
| Plating | 4 | B | Spiked Walls | Dinos that bite take 10 damage back | Resist % 30, Thorns damage 10 |
| Plating | 4 | C | Barbed Wire | Stings and slows raiders who shoot towers here | Resist % 32, Raider slow % 20, Raider slow (s) 2, Raider damage 10, **PvP effect yes** |
| Plating | 5 | B | Iron Fortress | Towers in range take 55% less damage | Resist % 55 |
| Plating | 5 | C | Spike Fortress | Biters take 18 damage back | Resist % 40, Thorns damage 18 |
| Gunsmith | 4 | B | Rapid Feed | Towers in range fire 20% faster | Aura rate % 20, Aura damage % 15 |
| Gunsmith | 4 | C | Heavy Loads | Towers in range hit 30% harder | Aura rate % 5, Aura damage % 30 |
| Gunsmith | 5 | B | Machine Shop | Towers in range fire 30% faster | Aura rate % 30, Aura damage % 25 |
| Gunsmith | 5 | C | Magnum Loads | Towers in range hit 40% harder | Aura rate % 15, Aura damage % 40 |
| Outfitter | 4 | B | Speed Loader | Hunters in range reload 30% faster | Hunter reload x 0.7 |
| Outfitter | 4 | C | Gun Braces | Hunters in range have 30% less recoil | Hunter recoil x 0.7 |
| Outfitter | 5 | B | Gun Oil | Wider ring; hunters in it reload 20% faster | Hunter reload x 0.8, Range x 1.15385 |
| Outfitter | 5 | C | Steady Aim | Wider ring; hunters in it aim 20% tighter | Hunter spread x 0.8, Range x 1.15385 |

- **T116** Tranq + Supply rows, Raider sting, Bounty cash, their `tower_worth` metrics;
  specs: each option's composed stats, a sting spec (×0.5, cooldown, Camo Cover, own side,
  co-op no-op), a bounty spec (strongest camp pays once). **T117** Hospital + Armory rows,
  Biter slow, their metrics (incl. Outfitter reading the composed build). **T118** `UPGRADES.md`
  option tables for the 4 towers, audit clean, `value.py --options` clean, Config diff
  accounted for. Tester: one B and one C per tower in a match; Bounty Board pays +8 per
  take-down in range (cash log); Heavy Crates drop 2 crates; Bitter Tonic slows a biting
  dino; auras don't stack across options (a 5B Gunsmith + a 5C Gunsmith on one tower: the
  stronger of each aura only); Sleeper Darts / Barbed Wire sting the stand-in hunter at ×0.5
  in a Camp Clash round and do nothing through Camo Cover. **Rewritten (#310): stand-ins never
  shoot, so the Tester is the raider** — `standinpick` a stand-in Tranq Station to 4C and an
  Armory to 4C, walk into range, shoot a stand-in tower: the Tester's hunter is stung (×0.5
  damage, slowed ≤ 30 % ≤ 3 s, once per 3 s), not stung during Camo Cover after a respawn.

**9e — B/C for the 2× batch** (Storm Coil, Falcon Roost, Tar Pit, Harpoon Ballista: 12 paths,
**48 options**; A = Jovan's own T4/T5 picks, unchanged). **DESIGNED (Director, 2026-10-13,
#296–#297) — enter as written** (🦖 names first). Same row recipe as 9c/9d. Built from the
unpicked `TOWERS_NEXT.md` ideas first: Storm Front, Supercell, Superconductor, Lightning
Shield; Raking Strike, Harpy Strike, Sky Hunters; La Brea, Ever-Burn, Preserved Specimens; Serrated, Leviathan Bolt, Heartseeker, Tether, Anchor Line,
Fire Bolts, Siege Battery. (Left out, each a new system: Carry Off, Thunderhead, Clothesline,
Fossil Trap, Rain of Spears, Asphalt (a button), Spotter's Eye (reveal-like).)

**Worth metrics (#296):** damage paths = eDPS + aura credit as today, plus **Field strike**
credit (20 dinos × the coil's damage × Field strike x ÷ every × the share it can hurt:
plain + boss + flying, + armoured if it pierces). Lightning Rod = eDPS + aura + 20 ÷
Grounding every (s). Falcon Falconer = eDPS + aura with Boss mark % × boss share added to
Aura damage % (as Tranq Weak Spot). Tar Pit: Deep Tar = today's slow-seconds × (1 + sinks ÷
ground dinos), Bubbling / Dig Site today's. **Ballista Reel = hold-seconds per second:**
rate × max(1, Line hits) × (min(shot gap, Stun s) + Knockback ÷ 8 studs/s) × (1 − boss) +
rate × Slow % × min(shot gap, Slow linger) × boss (if Slows bosses) + Tow Line 10 ÷ 8 ÷ 15 ×
boss (today Reel scores eDPS only, so its options all tie). Worth caps unchanged (#193/#200).
Checked on a sheet copy with these metrics: all 48 slots inside 0.8–1.25× of the median,
the four Raider options ≥ 0.8× the others; best builds: Coil 131, Ballista 133 (≤ 1.25 × M =
178); Falcon builds 181–276 (untouchable band 178–284). Today's `--options` flags 4 (Coil
Arc: Field strike unmodelled; Falcon Falconer: boss mark) — the metric change goes in the
same commit as the rows. Model blind spots (carry damage, feel-check in the Tester run, 9k):
stun, chain stun, Static %, mark on Ballista/Falcon dives, Strips armour on tar.

**New mechanics (9e, ≤ 3 per tower):**
1. **Field strike** (`Field strike every (s)`, `Field strike x`; Storm Coil Storm Front):
   every N s the coil strikes **every dino on its side's field** for x × its damage (air
   too; armour only if it pierces; breaks 1, area). Fires itself (#283); several Storm Front
   coils each fire their own. Jovan's "reaching all dinos on the field at once".
2. **Chain effects** (flag; Supercell, Superconductor): the strike's slow and stun land on
   every dino in the chain, not just the first; an arc's stun is capped at the new Tuning
   row `Chain stun cap (s)` seed 0.3 (the first target keeps its full stun); never bosses
   unless the build stuns bosses.
3. **Targets biggest** (flag; Ballista Heartseeker): aims at the biggest dino in range (the
   Judgement Bolt pick, made generic) instead of the furthest along.
Plus Raider sting (9d) on Rod Strike, Guard Falcons, Bog Boots, Snag Line. Wirings: Falcon
dives take `Targets x` (a dive also hits the nearest other dino), `Line hits`, `Size
breaks`, `Boss x`, `Armoured x`, `Mark %`; Ballista bolts take `Mark %`, `Boss x`, `Slow %` /
`Slow linger` / `Slows bosses`, `Burn DPS` / `Burn (s)`; Tar Pit `Strips armour` (9c's
generic strip) and `Sink seconds` at T5; Coil `Size breaks` per strike and `Aura rate %` at
T4/T5. Note on Bog Boots: its `Range x` 1.5 multiplies with Tar Lake (×3 → 81 studs): fine
by the pool-overlap rule (#189), playtest watch.

**Storm Coil**

| Path | Tier | Opt | Name (working) | Blurb (card) | Cells (own step; unset = 1 / blank) |
|---|---|---|---|---|---|
| Arc | 4 | B | Branching Bolt | Every arc forks three ways | Damage x 1.15, Arc forks 3 |
| Arc | 4 | C | Chain Surge | Three more arcs on every strike | Damage x 1.4, Arcs 9 |
| Arc | 5 | B | Storm Front | Every 8 s a strike hits every dino on the field | Damage x 1.45, Field strike every (s) 8, Field strike x 0.5 |
| Arc | 5 | C | Supercell | A 14-arc chain that slows every dino it hits | Damage x 1.5, Arcs 14, Slow % 20, Slow linger (s) 1, Chain effects Yes |
| Charge | 4 | B | Overcharge | Stuns its first target for 0.8 s | Damage x 1.35, Pierces armour Yes, Stun (s) 0.8 |
| Charge | 4 | C | Static Storm | Struck dinos take +30% from the next strike | Damage x 1.3, Pierces armour Yes, Static % 30 |
| Charge | 5 | B | Superconductor | Every dino in the chain is stunned for a moment | Damage x 1.85, Pierces armour Yes, Chain effects Yes |
| Charge | 5 | C | Thunderstrike | Huge strikes that break 2 sizes | Damage x 2, Pierces armour Yes, Size breaks 2 |
| Lightning Rod | 4 | B | Ground Wire | Strikes down a dino throw every 2 s | Damage x 1.3, Grounding every (s) 2 |
| Lightning Rod | 4 | C | Rod Strike | Zaps raiders; towers in range fire 15% faster | Damage x 1.3, Aura rate % 15, Raider slow % 20, Raider slow (s) 1, Raider damage 8, **PvP effect yes** |
| Lightning Rod | 5 | B | Lightning Shield | Strikes down a throw at a tower every second | Damage x 1.3, Grounding every (s) 1, Aura damage % 10 |
| Lightning Rod | 5 | C | Thunder Drums | Towers in range fire 25% faster | Damage x 1.3, Aura rate % 25 |

**Falcon Roost**

| Path | Tier | Opt | Name (working) | Blurb (card) | Cells (own step; unset = 1 / blank) |
|---|---|---|---|---|---|
| Talons | 4 | B | Raking Strike | Each dive also slashes the dino beside it | Damage x 1.2, Targets x 2, Pierces armour Yes |
| Talons | 4 | C | Stoop Strike | The first dive on a dino hits 6x | Damage x 1.35, First dive x 6, Pierces armour Yes |
| Talons | 5 | B | Harpy Strike | Dives break 4 sizes and hit bosses 2x | Damage x 2.1, Size breaks 4, Boss x 2 |
| Talons | 5 | C | Hide Ripper | Talons shred armoured dinos | Damage x 3.2, Armoured x 2.5 |
| Flock | 4 | B | Swift Wings | Birds fly back much faster | Damage x 1.85, Rate x 1.6 |
| Flock | 4 | C | Second Flock | Seven bigger birds hunt at once | Damage x 2.7, Birds 7 |
| Flock | 5 | B | Sky Hunters | Twelve birds hunt twice as far out | Damage x 3.3, Range x 2, Birds 12 |
| Flock | 5 | C | Strafing Run | Each dive cuts through 3 dinos in a line | Damage x 1.05, Line hits 3 |
| Falconer | 4 | B | Loud Bells | Struck dinos take +25% from every tower | Damage x 1.3, Mark % 25 |
| Falconer | 4 | C | Guard Falcons | Birds dive at raiders; bosses take +40% | Damage x 1.3, Boss mark % 40, Raider slow % 20, Raider slow (s) 1, Raider damage 6, **PvP effect yes** |
| Falconer | 5 | B | Royal Hood | Bosses in range take +60% from everything | Damage x 1.3, Boss mark % 60 |
| Falconer | 5 | C | Bell Chorus | Struck dinos take +40% from every tower | Damage x 1.3, Mark % 40 |

**Tar Pit**

| Path | Tier | Opt | Name (working) | Blurb (card) | Cells (own step; unset = 1 / blank) |
|---|---|---|---|---|---|
| Deep Tar | 4 | B | Thick Mire | Thicker tar: dinos wade much slower | Slow % 55 |
| Deep Tar | 4 | C | Bog Boots | A longer pool that also slows raiders | Range x 1.5, Slow % 45, Raider slow % 30, Raider slow (s) 2, **PvP effect yes** |
| Deep Tar | 5 | B | La Brea | Smallest dinos sink at once; the rest crawl | Sink seconds 0.05, Slow % 62, Range x 1.15, Slow linger (s) 3 |
| Deep Tar | 5 | C | Black Glue | Dinos stay slowed 5 s after they climb out | Slow % 50, Slow linger (s) 5 |
| Bubbling | 4 | B | Boiling Splash | A bigger pool of boiling tar | Range x 1.3 |
| Bubbling | 4 | C | Pitch Coat | Sticky tar strips armour; dinos leave burning | Strips armour Yes, Burn DPS 85, Burn (s) 1 |
| Bubbling | 5 | B | Ever-Burn | Dinos keep burning 2.75 s after they leave | Burn (s) 2.75 |
| Bubbling | 5 | C | Tar Inferno | The tar boils 50% hotter | Burn DPS 120 |
| Dig Site | 4 | B | Bone Yard | Every sunk dino pays more cash | Sink cash 28, Sink chest cash 36 |
| Dig Site | 4 | C | Fossil Finder | Bigger chests where dinos go under | Sink cash 15, Sink chest cash 55 |
| Dig Site | 5 | B | Preserved Specimens | Every sunk dino pays 36 cash | Sink cash 36, Sink chest cash 40 |
| Dig Site | 5 | C | Amber Seep | Chests where dinos sink are worth 60 | Sink cash 25, Sink chest cash 60 |

**Harpoon Ballista**

| Path | Tier | Opt | Name (working) | Blurb (card) | Cells (own step; unset = 1 / blank) |
|---|---|---|---|---|---|
| Spearhead | 4 | B | Serrated Head | Hit dinos take +20% from every tower | Damage x 1.7, Pierces armour Yes, Mark % 20 |
| Spearhead | 4 | C | Whale Lance | Bolts hit bosses 40% harder | Damage x 1.6, Pierces armour Yes, Boss x 1.4 |
| Spearhead | 5 | B | Leviathan Bolt | Bolts break 4 sizes and hit bosses 3x | Damage x 2.5, Rate x 1.4, Size breaks 4, Boss x 3 |
| Spearhead | 5 | C | Heartseeker | Always aims for the biggest dino in range | Damage x 3, Rate x 2.1, Size breaks 3, Targets biggest Yes |
| Reel | 4 | B | Tether | Pinned dinos stay held 2 s | Damage x 1.3, Stun (s) 2 |
| Reel | 4 | C | Snag Line | Harpoons raiders too; holds dinos 1.75 s | Damage x 1.3, Stun (s) 1.75, Raider slow % 30, Raider slow (s) 3, Raider damage 12, **PvP effect yes** |
| Reel | 5 | B | Anchor Line | Bolts slow bosses too: 30% for 2 s | Damage x 1.3, Slow % 30, Slow linger (s) 2, Slows bosses Yes |
| Reel | 5 | C | Winch Haul | Drags hit dinos 7.5 studs back | Damage x 1.3, Knockback (studs) 7.5 |
| Volley | 4 | B | Wide Volley | Five bolts per volley | Damage x 1.15, Shots 5 |
| Volley | 4 | C | Fire Bolts | Bolts set dinos on fire | Rate x 1.6, Burn DPS 6, Burn (s) 3 |
| Volley | 5 | B | Siege Battery | Six bolts per volley | Damage x 2.4, Shots 6 |
| Volley | 5 | C | Firestorm Volley | Faster volleys of burning bolts | Damage x 2, Rate x 1.8, Burn DPS 12, Burn (s) 3 |

- **T119** Coil + Falcon rows, Field strike, Chain effects, their metrics; specs: composed
  stats; a Storm Front spec (every dino on the side's field, air hit, armour skipped without
  pierce); a chain-stun-cap spec; a Raking Strike spec (two dinos per dive). **T120** Tar Pit
  + Ballista rows, Targets biggest, the Reel metric; specs: Heartseeker picks the biggest;
  Anchor Line slows a boss; La Brea sinks a last-size dino at once. Each task: `UPGRADES.md`
  option tables, audit clean, `--options` clean, Config diff accounted for. Tester: one B and
  one C per tower; Storm Front visibly hits dinos outside the coil's range every 8 s;
  Superconductor stuns the chain briefly, never a boss; Heartseeker shoots the biggest dino;
  Bog Boots / Snag Line / Guard Falcons / Rod Strike sting the stand-in at ×0.5 in Camp Clash,
  never through Camo Cover, and still do their dino part in co-op.
- **T120b — Bog Boots sting reach (#321; one small Builder commit after T115b + 9f's running
  task; assert each old value / empty first):** new Tuning row (append) `Pool sting reach
  (studs)` seed **12**. For an on-track tower (Tar Pit), the Raider sting's "inside this
  tower's range" becomes "within Pool sting reach of the nearest point of its pool" (the pool's
  current length, Tar Lake included), not the pool's whole length along the track; every
  off-track Raider tower keeps its range. Specs: a raider 10 studs beside a Tar Lake pool is
  stung, one 20 studs away but within 81 studs along the track is not; co-op unchanged. Config
  diff = the one row. Tester: rides 9g's run (Bog Boots stings only near the tar).
  Also in T120b (#322–#323): (a) Brush Beater Buckshot 5B Flame Choke `Blurb` → **"Dragon's
  Breath bursts for 90% of a shot"** (the cell 0.9 stays; `HEROES.md` too). (b) **Twin Slug
  (Slug 5C) uses 1 round per pump** (2 slugs from one shell, as the 9f design and the #298
  metric say); Double Barrel keeps 2 rounds per pump. Spec: a Twin Slug pump spends 1 round and
  fires 2 slugs. `--options` must stay clean (if not: Twin Slug `Magazine x` 1.5 → 1.3).

**9f — B/C for the heroes** (4 heroes × 3 paths: **48 options**, handling only; no Raider
options, #301). **DESIGNED (Director, 2026-10-13, #298–#302) — enter as written** (🦖 names
first; working names here). Append one `Hero Upgrades` row per option at the bottom: Hero /
Path / Focus / Tier copied from that slot's A row; `Cost` `=F<A row>` (same price, #277);
`Option`, `Name`, `Blurb`; the cells listed; **every other cell blank** (blank = no change,
per the sheet's header note). No `Damage x` anywhere (DIRECTION: never raw gun damage). No
hero T6 *cell* changes: every T6 works after any T5 as built (#300); four T6 descriptions are
reworded in `HEROES.md` only.

**Worth metric (#298; replaces `hero_dps` in `value.py --options` for heroes — bars and the
#288 T6 parity — in the same commit as each hero's rows).** Composed build, r31–40 HP shares
(armoured 0.116, flying 0.07, boss 0.428):
- **Gun paths (10):** worth = (DPS × Hit + Burn) × Targets × Hurt × Reach × Amp × Hold ×
  Breaks, × (1 + Dart uptime) for the Tracker.
  - rounds/s = rate × Fire rate x × guns × spin × (Big Game Hunter: 1 + 0.4 × Rally uptime);
    spin = 1 + (Spin-up x − 1) × e ÷ (e + 1), e = seconds to empty the magazine at full spin
    (10 with Endless Belt). **Burst count does not multiply rounds** (it's rounds per click;
    today's `hero_dps` counts it twice and under-rates burst builds).
  - DPS = damage × Pellets(base) × Shots per trigger × rounds/s × f; f = empty ÷ (empty +
    reload) (Hot Swap: today's share rule; Belt Fed: f = 1 during Rally uptime; Endless Belt:
    f = 1). Dart uptime = 8 ÷ (45 × Ability cooldown x); Rally uptime = 10 ÷ (45 × cd x).
  - Hit = max(0.4, 1 − 0.3 × √(spread × recoil)); spread = Spread x × (0.5 + 0.5 × Still
    spread x) × (scoped: 0.5 + 0.5 × Scoped spread x); recoil = Recoil x × (0.5 + 0.5 × Still
    recoil x) × (0.7 with Burst recoil reset).
  - Burn = Burn DPS × Burn (s) + Ignite tick × DPS × 0.6 (about one fresh dino a second).
  - Targets = (1 + 0.5 × (Pierce − 1)) × (1 + 0.5 × Bounces) × (1 + 0.12 × Splash m).
  - Hurt = 1 − armoured (unless it pierces armour) − flying (unless it hits air).
  - Reach = Range x ^ 0.3. Amp = (1 + Mark % ÷ 100) × (1 + (Marked damage x − 1) × marked
    share), marked share = Dart uptime + 0.3 if its hits mark.
  - Hold = 1 + hits/s ÷ burst count × Knockback ÷ 8 studs/s × (1 − boss); hits/s = rounds/s ×
    f × Hit. Breaks = 1 + 0.2 × (Size breaks − 1).
- **Field Medic Triage:** casts/min (60 ÷ (35 × cd x)) × [(40 × Heal x + Heal regen HP/s ×
  Heal regen s) × (1.5 if it repairs towers) + Guard % × Guard s × 10 HP/s] × Heal radius x ×
  (1.1 with 2 charges). Heal per minute × radius, with Second Wind's resist as HP saved.
- **Field Medic Muzzle:** lock-seconds + slow-seconds per minute = 60 × (L + S); L = hits/s ×
  k ÷ (1 + hits/s × k ÷ 6) with k = Jaw lock s × (1 + 0.15 × Jaw lock spread studs) × (1 −
  boss ÷ 2) (bosses locked half; ~6 dinos in reach caps it); S = hits/s × Slow % × Slow s ×
  (1 − boss). Spread counted, so Lullaby / Lights Out / Strap Toss score.
- Bars (#280, #288): each option 0.8–1.25× its slot median (T4; T5 after each T4); the 9 T6
  builds per path within 1.15×.

**Checked (Director scratch `h9f_fast.py` on a sheet copy, these metrics):** all 48 slots
(12 paths × T4 + T5 after A/B/C) inside **0.87–1.22×**; T6 builds per path within **1.04–1.14×**
(Stalker 1.04 … Point Blank 1.14). Peak-DPS guard (exporter, hero vs best tower): the
highest new peak is 47 (Point Blank Slam Fire + Quad Barrel; Slug Express Slug 46) vs today's 34.6;
the Chaos ceiling is 66.7, so it passes — a 9k watch line. Today's `--options` on `hero_dps`
would flag the burn / mark / ability / lock options (scored 0): that's the metric gap.

**New mechanic (9f, one):** **Heal regen** (`Heal regen HP/s`, `Heal regen (s)`; two new
columns appended after `Blurb`, registry kind `max`): everything the Triage Kit heals (hunters
and, with Patch Up, standing towers) regains HP/s for the time; flat, no hero levels; doesn't
stack (strongest wins; a recast refreshes it); own team only. **Wirings to verify** (columns
that exist but a path hasn't used): burst fire with dual guns (Twin Burst: each click = 3
rounds alternating guns; Hot Swap still staggers); full-auto with Shots per trigger 2 (Slam
Fire; Quad Barrel then 4 per pull); Shots per trigger on slugs (Twin Slug: 2 slugs, each pierces
4, one round per pump as Double Barrel); Hits air on Point Blank; Mark % on Tracker and Stalker
hits; Range x on Special Ammo; Ability cooldown x on Rally Cry (War Drum); Burn on Special Ammo
T4 and Buckshot T4 (the existing burning-ground cells). **PvP (#301):** hero shots on a hunter
stay damage-only (× 0.5, Camo Cover): no slow, lock, mark, knockback or burn on hunters.

**T6 wording after any T5 (#300; `HEROES.md` only, no cells):** Big Five "bursts of 5; recoil
resets between bursts" (drop "with Precision Burst's grouping"); Endless Belt "once fully spun
up (2 s of holding), no reloading" (every Heavy T5 spins up: A 2.5, B 1.6, C 2.3); Dynamite
Rounds "the blast grows to 6 m and pierces armour" (every Special Ammo T5 has a blast: A 4 m,
B/C 3 m); Wildfire Drum "holds +50% shells"; Lights Out "Jaw Lock lasts at least 4 s and
spreads within 9 studs".

**Tracker**

| Path | Tier | Opt | Name (working) | Blurb (card) | Cells (own step; blank = no change) |
|---|---|---|---|---|---|
| Gunslinger | 4 | B | Deep Cylinders | Both guns hold 50% more and fire 15% faster | Fire rate x 1.15, Magazine x 1.5 |
| Gunslinger | 4 | C | Crossdraw | Reload 35% faster, fire 15% faster | Fire rate x 1.15, Reload x 0.65 |
| Gunslinger | 5 | B | Twin Burst | Each click fires a 3-round burst, 30% faster | Fire rate x 1.3, Fire mode `burst`, Burst count 3, Magazine x 1.3 |
| Gunslinger | 5 | C | Steady Pair | Half the kick, tighter aim, 10% faster | Fire rate x 1.1, Recoil x 0.5, Spread x 0.8 |
| Marksman | 4 | B | Quick Cock | Fire 20% faster, scope and all | Fire rate x 1.2 |
| Marksman | 4 | C | Breath Control | Half the kick; the scope reaches 35% further | Range x 1.35, Recoil x 0.5 |
| Marksman | 5 | B | Quick Scope | Fire 70% faster with 30% less kick | Fire rate x 1.7, Recoil x 0.7 |
| Marksman | 5 | C | Hunter's Mark | Hits mark dinos: +35% from everything | Mark % 35, Spread x 0.8 |
| Trick Shot | 4 | B | Bank Shot | Ricochets bounce twice | Bounces 2 |
| Trick Shot | 4 | C | Quick Fingers | Reload 30% faster, fire a bit faster | Fire rate x 1.07, Reload x 0.7 |
| Trick Shot | 5 | B | Pinball | 3 bounces, a bigger cylinder, faster shots | Fire rate x 1.17, Bounces 3, Magazine x 1.5 |
| Trick Shot | 5 | C | Dart Storm | 3 bounces, faster shots, Tracking Dart sooner | Fire rate x 1.15, Ability cooldown x 0.75, Bounces 3 |

**Big Game Hunter**

| Path | Tier | Opt | Name (working) | Blurb (card) | Cells (own step; blank = no change) |
|---|---|---|---|---|---|
| Stalker | 4 | B | Snap Bursts | Bursts come 20% faster | Fire rate x 1.2 |
| Stalker | 4 | C | Quick Mag | Reload 25% faster | Reload x 0.75 |
| Stalker | 5 | B | Marking Burst | 4-round bursts that mark: +25% from everything | Fire rate x 1.1, Burst count 4, Mark % 25, Magazine x 1.3 |
| Stalker | 5 | C | Rapid Volley | Bursts 35% faster, half the kick, bigger mag | Fire rate x 1.35, Recoil x 0.5, Magazine x 1.5 |
| Heavy | 4 | B | Steady Sling | 35% less kick, moving or not | Recoil x 0.65 |
| Heavy | 4 | C | Quick Belt | Belt changes 30% faster; 20% less kick | Recoil x 0.8, Reload x 0.7 |
| Heavy | 5 | B | Hot Barrel | 50% faster at once, spins up to +60% more | Fire rate x 1.5, Spin-up x 1.6, Magazine x 1.3 |
| Heavy | 5 | C | War Drum | Rally Cry twice as often; spins up to +130% | Spin-up x 2.3, Ability cooldown x 0.5 |
| Special Ammo | 4 | B | Phosphor Rounds | Fires burn 10% hotter and 50% longer | Burn DPS 1.1, Burn (s) 3 |
| Special Ammo | 4 | C | Bright Tracers | Hits mark dinos: +30% from everything | Mark % 30 |
| Special Ammo | 5 | B | Fire Tips | Small blasts; dinos burn 25% longer | Splash radius (m) 3, Burn (s) 2.5 |
| Special Ammo | 5 | C | Flat Tips | Small blasts; rounds fly 25% further | Splash radius (m) 3, Range x 1.25 |

**Brush Beater**

| Path | Tier | Opt | Name (working) | Blurb (card) | Cells (own step; blank = no change) |
|---|---|---|---|---|---|
| Slug | 4 | B | Quick Pump | Pump 25% faster | Fire rate x 1.25 |
| Slug | 4 | C | Side Saddle | Holds 50% more slugs, loads 20% faster | Reload x 0.8, Magazine x 1.5 |
| Slug | 5 | B | Express Slug | Slugs through 6, 60% faster, bigger tube | Fire rate x 1.6, Magazine x 1.5, Pierce 6 |
| Slug | 5 | C | Twin Slug | Two slugs per pump, each through 4 | Shots per trigger 2, Pierce 4, Magazine x 1.5 |
| Buckshot | 4 | B | Hot Shells | Fires burn more than twice as hot | Burn DPS 2.3, Burn (s) 3 |
| Buckshot | 4 | C | Shell Belt | Pump 50% faster; holds 50% more | Fire rate x 1.5, Magazine x 1.5 |
| Buckshot | 5 | B | Flame Choke | Dragon's Breath bursts for 70% of a shot | Ignite tick (x shot) 0.9, Fire rate x 1.2 |
| Buckshot | 5 | C | Pump Storm | Pump 50% faster, bigger tube | Fire rate x 1.5, Magazine x 1.5 |
| Point Blank | 4 | B | Quick Breech | Reload 35% faster, fire 20% faster | Fire rate x 1.2, Reload x 0.65 |
| Point Blank | 4 | C | Bird Shot | Blasts hit flying dinos; fire 15% faster | Fire rate x 1.15, Hits air Yes |
| Point Blank | 5 | B | Breech Loader | 45% faster, bigger tube, quick reload | Fire rate x 1.45, Reload x 0.6, Magazine x 1.5 |
| Point Blank | 5 | C | Slam Fire | Hold to keep both barrels firing, 70% faster | Fire rate x 1.7, Fire mode `auto` |

**Field Medic**

| Path | Tier | Opt | Name (working) | Blurb (card) | Cells (own step; blank = no change) |
|---|---|---|---|---|---|
| Triage | 4 | B | Thick Gauze | Triage Kit heals 55% more | Heal x 1.55 |
| Triage | 4 | C | Quick Kit | Triage Kit is ready a third sooner | Ability cooldown x 0.67 |
| Triage | 5 | B | Mending Salve | Everything healed regains 2 HP/s for 8 s | Heal regen HP/s 2, Heal regen (s) 8 |
| Triage | 5 | C | Field Surgeon | Triage Kit is ready 22% sooner | Ability cooldown x 0.78 |
| Lever Action | 4 | B | Long Tube | Holds 80% more rounds | Magazine x 1.8 |
| Lever Action | 4 | C | Snap Lever | Cycles 14% faster | Fire rate x 1.14 |
| Lever Action | 5 | B | Triple Cycle | 3-round bursts, cycling 33% faster | Burst count 3, Fire rate x 1.33 |
| Lever Action | 5 | C | Steady Lever | 10% faster, half the kick, tighter aim | Fire rate x 1.1, Recoil x 0.5, Spread x 0.6 |
| Muzzle | 4 | B | Quick Dose | Fire 12% faster; jaws locked 2.6 s | Jaw lock (s) 2.6, Fire rate x 1.12 |
| Muzzle | 4 | C | Strap Toss | Lock jumps 2 studs; hits slow dinos 40% | Slow on hit % 40, Jaw lock spread (studs) 2 |
| Muzzle | 5 | B | Heavy Lids | Locked jaws stay shut 4.2 s | Jaw lock (s) 4.2 |
| Muzzle | 5 | C | Drowsy Cloud | Lock spreads 4 studs; hits slow 40% for 2 s | Slow on hit % 40, Slow on hit (s) 2, Jaw lock spread (studs) 4 |

- **T121** Tracker + Big Game Hunter rows; the #298 metric in `value.py` (gun paths) + exporter
  bars on it; specs: each option's composed stats; all 9 (o4, o5) + T6 builds compose (Big
  Five after 5B/5C bursts 5; Endless Belt after 5B/5C stops reloading once spun up); Twin Burst
  fires 3 per click with two guns. **T122** Brush Beater + Field Medic rows, Heal regen, the
  Triage and Muzzle metrics; specs: Twin Slug 2 slugs × pierce 4 per round; Slam Fire auto
  with 2 blasts; Bird Shot hits a flyer; Mending Salve regen (strongest wins, towers too,
  no stacking); Dynamite after 5B/5C = 6 m. Each task: `HEROES.md` option tables + the T6
  rewording, audit clean (names unique), `--options` clean, Config diff accounted for.
  Tester: one B and one C per hero in first person (cards match what happens), a T6 after a
  B or C T5 on each hero, Practice Hunt duel with the stand-in still fair (damage only).

**🦖 naming point:** the 7 tower names (and look notes) once before 9g, then each batch's
option names (all 126 working names in `TOWERS_LATER.md` are drafts).

### 9g–9j — the seven 4× towers: common groundwork (DESIGNED, Director 2026-10-14, #312–#320)
Names = `DINO_REVIEW.md` Round 19 (final; the 🦖 pass for 9g–9j is done). Designs = the approved
`TOWERS_LATER.md` effects; numbers below are **seeds the batch's release task tunes** (as T68).
Every rule of 9c–9f holds (append only; assert each cell empty or the old value; Config diff
accounted for; pure rules first; one task = one commit, pushed; co-op specs re-run).
1. **Towers rows (append after Harpoon Ballista):** keys `RESIN`, `RAPTOR` (9g), `BLIMP`, `TOTEM`
   (9h), `METEOR`, `VENT` (9i), `RANGER` (9j); the cells in each tower's "Towers row" line;
   `Base DPS` `=D×E×F` like row 15. New `Towers` column after `Chains`: **`Near track (studs)`**
   (Vent only; `Shared/Placement`: such a tower must have a track point within that distance).
2. **Tower Upgrades rows:** per path 3 tier rows (Option blank, cumulative as today) + the A
   rows (T4, T5; own step, #275) with the Coil-row formulas (`Upgrade cost`
   `=ROUND('Towers'!$C$<row>*POWER('Tuning'!$B$12,D<n>),0)`, `Cumulative cost`
   `='Towers'!$C$<row>+E<n>` at T1 then `=F<prev>+E<n>`; `Resulting DPS` / `Cost per DPS` as
   the Coil rows) + the B/C rows (`=E<A row>`, `=F<A row>`). `Damage x`/`Rate x`/`Targets x`/
   `Range x` = 1 unless listed; every other cell blank unless listed. Options of a slot share
   the path focus. A T5 row's own step must work after any T4 (#276; checked per slot below).
3. **New columns:** appended after the last `Tower Upgrades` header (today `Targets biggest`,
   CU), each in the exporter's column registry with the kind given in its tower's "New
   columns" line (`mult` / `add` / `max` / `flag` / `set`), audit allowed list, and a spec.
   Base levers go in a new Tuning block per tower (append after the last Tuning row; assert
   empty), plus one shared block **`4× TOWERS`** (9g): `Boss hard stop x` 0.5, `Small size` 2,
   `Wall min bunch` 6, `Wall reach (studs)` 10, `Take-down mark radius` 6, `Round seconds
   (model)` 50.
4. **Shared rules (9g builds them generic; later batches reuse):**
   - **Auto trigger** (`Shared/AutoFire`, pure; #283 made generic): every "once per round
     played" effect fires itself the first moment a boss or `Wall min bunch` dinos are inside
     its area, else when that round's last dino has spawned (on the densest bunch / its area
     then); never on an empty track; per tower, per side; resets each round played. Users:
     Resin Wall, Raptor Charge, Raptor Swarm, Bombing Run, Comet Tail, Extinction Event,
     Supervolcano, Obsidian Wall, Master Trapper.
   - **Hard stops** (entomb, walls, nets, freeze craters, Frozen Fire): a dino can't move,
     bite or throw; it still takes damage. **Bosses: duration × `Boss hard stop x`** unless the
     option says otherwise. Hard stops don't stack: the longer remaining wins.
   - **"Small dinos"** = not a boss, at its last `Small size` sizes. **Whole track / your side**
     = the own side's track only (BattleRules); nothing reaches another camp.
   - **Take-down mark** (`Take-down mark %`): when this tower (or its walkers) takes a dino
     down, dinos within `Take-down mark radius` are marked (Mark duration 3 s; marks don't
     stack, stronger wins).
   - **Hunter damage auras** (`Hunter damage %`): own side's hunters in range deal +x% **to
     dinos only** — never to hunters or towers in PvP (#301's spirit, #319).
5. **Unreleased until its batch's release task** (`ShopRules.Unreleased`, as T63): placeable
   only through the Studio J unlock + K cash path once the release task lands; `value.py`
   leaves them out of every median. **New set `ROUND9_BATCH`** (the seven keys): never part of
   M; **M stays 142** (frozen, #200).
6. **Release rule: per pair (#312).** Each batch ends with a release + balance task (like T68):
   both towers sold, Amber unlock live, Tester buys them in that batch's run. 9k re-checks all
   seven together. **Bars (per tower):** damage paths — best damage T5 c/e (r31–40) **≤ 1.25 ×
   M (178)** and every damage T5 ≤ 2 × M (284); the Blimp (untouchable) — every damage T5 in
   **1.25–2 × M**; no DOMINANT finding (marginal < 0.5 × the tier median); **"matters by round
   20"**: the tower's best T2 c/e (r11–20, damage path, or its control/economy line for Resin)
   ≤ 1.5 × the released T2 median; control/support/economy paths — out of the medians, judged
   by their metric line and the option bars. **Guaranteed exit (as T68 step 7):** if a damage
   bar fails, C = C × (target ÷ measured), rounded to 25, target 150 (damageable) / 230 (Blimp);
   floors 600 / ceilings 1,200 cash; at a floor, base Damage +1 and repeat (≤ +3) — **for walker
   towers (Raptor, Paratroopers, rangers) and any tower where +1 Damage trips a break bar: base
   Fire rate × (measured ÷ target) instead, to 0.05, ≤ ×1.6 (#326)**. Amber
   prices never move (Jovan approved them).
7. **Option bars (#280, #284):** each slot's options within 0.8–1.25× of the slot median on the
   path metric (T4; T5 after each T4), all 9 builds under the bars above. Director's checks
   below are arithmetic on the stated metric (the mechanics don't exist yet); the Builder
   confirms in `value.py --options`. **Exit:** if a slot fails, step the option's **lever**
   (marked ⚙ in its cells) 10% toward the median, at most 3 steps, then report it to the
   Director (no other cell moves).
8. **Exchange rates for mixed metrics (#313; stated assumptions in `value.py`, 9k revisits):**
   1 hold-second per second (a non-boss dino stopped) = **120 eDPS** (≈ the r31–40 team damage
   one held dino takes a second); a slow of S % for t s = S/100 × t hold-seconds; knockback k
   studs = k ÷ 8 hold-seconds; +x % damage taken by a dino for t s = x/100 × 120 × t;
   **1 eDPS = 14 cash a round** (M ÷ 10 rounds); hunter damage +x % = x/100 × 30 eDPS per
   hunter in range (1 assumed). Stand-ins: dinos in a tower's range 4, on the side's track 10,
   in a bunch 6; a fighting walker's uptime 0.7.
9. **Studio test aids** (`Shared/StudioOnly`, refused live, spec each): **`firenow <tower>`**
   — the nearest tower of that key fires its once-a-round / timed effect now (ignores
   AutoFire and timers); **`charge <n>`** — sets the nearest Bone Totem's charge; **`fossils
   <n>`** — sets the nearest Resin Cannon's match fossil count; **`walkers`** — prints every
   walker (tower, state, HP, target) to Output. `standinpick` (#310) works on every new key.
10. **Tester (every 9g–9j batch, after its release task):** buy (K), unlock (J), place, upgrade
    each path to a T4 and a T5 pick once (two B and two C at least per tower), Trampled + repair
    (not the Blimp), a co-op round and a Camp Clash round (own dinos only, nothing crosses
    camps); every `firenow` effect seen once; Raider options: the Tester raids a `standinpick`
    stand-in and is stung at ×0.5, not through Camo Cover; the same option in co-op still does
    its dino part. Card text matches what happens.

**9g — Amber Resin Cannon + Raptor Pen** (T123 Resin, T124 Walker + Raptor, T124b release).

#### Amber Resin Cannon (`RESIN`) — a control tower (Tar Pit-like judging, #314)
**Towers row:** Cost 800 · Damage 2 · Fire rate 1 · Targets 1 · Range 18 · Hits air No ·
Income 0 · Splash 0 · Slow % 0 · Unlock 500 · Key `RESIN` · Max HP 150 · Heal/Resist 0 ·
Untouchable/On track/Chains blank · note "Resin globs: slows, entombs (hard stop), fossils.
TOWERS_LATER.md." `value.py`: `RESIN` in `SUPPORT_TOWERS` (out of the medians, like `TARPIT`).
**Tuning block `AMBER RESIN CANNON`:** Resin hits to entomb 6 · Entomb base (s) 0.8 · Resin
hit slow % 20 · Resin hit slow (s) 1 · Boss entomb every (s) 10 · Spread reach (studs) 6 ·
Sticky bed reach (studs) 6 · Fossil Fuel cap % 30.
**Mechanics (pure `Shared/Resin`):**
1. **Entomb.** Each hit slows the dino (Resin hit slow % for Resin hit slow s) and adds 1
   resin. It is entombed when resin ≥ max(1, ceil(Resin hits to entomb × `Entomb hits x` ×
   its HP-left share)) — "the more HP is gone, the faster it sets" — for `Entomb (s)` (blank =
   Entomb base), a hard stop; resin resets. Bosses: at most once per Boss entomb every (s) per
   boss, × Boss hard stop x (`Boss entomb (s)` overrides: that length, full). Ground only.
   `Entomb amp %`: an entombed dino takes +x % from everything. `Entomb spread` n: the
   entomb also takes the n nearest dinos within Spread reach (same length). `Entomb slow %`:
   dinos within Sticky bed reach of an entombed dino are slowed x %. `Entomb all every (s)`:
   on that timer every dino in range is entombed (`Entomb (s)`; bosses × Boss hard stop x).
   `Send back (studs)`: an entombed non-boss is moved that far back up the track (the
   knockback rule).
2. **Fossils.** A dino entombed at or below `Fossil below %` of its HP (not bosses) is a
   **fossil**: taken down at once, every remaining size pays its normal cash and counts as a
   pop for the cannon's owner (Bones as usual), plus `Sink cash` (per fossil; reuses the Tar
   Pit column, scaled by the difficulty cash multiplier #309) and a `Sink chest cash` chest
   (Tar Pit's chest drop). The cannon counts its fossils this match. `Fossil rate %`: each
   fossil gives towers in range +x % attack speed for the rest of the round (cap Fossil Fuel
   cap %). `Bounty fossils x`: a fossil counts that many take-downs for the owner's Bounties.
   `Heart every (fossils)` n: every n-th fossil this match entombs every dino on the side for
   1 s (bosses × Boss hard stop x).
3. **Seal (towers).** `Seal (s)`: when a tower in range would be Trampled it is instead left at
   1 HP and sealed (no damage) for that long — once a round per cannon, or once per `Seal every
   (s)` per tower if set. `Seal heal %`: the tower heals that share of its max HP when the seal
   breaks. Plus existing columns: `Aura HP %`, `Resist %`, `Thorns damage`, `Biter slow %/(s)`,
   Raider sting (9d), `Grounding every (s)` (Storm Coil's rule: catches one throw at a tower in
   range per interval) with `Reflect damage` (the caught throw hits its thrower for that,
   × tower level), and **Track wall** (`Wall (s)`; AutoFire; a wall at the furthest-along track
   point in range: every dino reaching it stops until it breaks after Wall (s); bosses pass
   after Wall (s) × Boss hard stop x).
**New columns (kind):** Entomb (s) max · Entomb hits x mult · Entomb amp % max · Entomb spread
max · Entomb slow % max · Entomb all every (s) min-positive (a shorter timer wins; blank = off)
· Boss entomb (s) max · Send back (studs) max · Fossil below % max · Fossil rate % max ·
Bounty fossils x max · Heart every (fossils) min-positive · Seal (s) max · Seal every (s)
min-positive · Seal heal % max · Reflect damage max · Wall (s) max. (`min-positive` is a new
registry kind: the smaller non-blank value wins.)

| Path | Tier | Opt | Name | Blurb (card) | Cells (T1–3 cumulative; T4/T5 own step) |
|---|---|---|---|---|---|
| Entomb | 1 | | Thick Resin | — | Damage x 1.4, Rate x 1.2, Entomb hits x 0.85 |
| Entomb | 2 | | Quick Set | — | Damage x 2, Rate x 1.45, Entomb hits x 0.7 |
| Entomb | 3 | | Amber Tomb | — | Damage x 3, Rate x 1.8, Entomb hits x 0.5, Entomb (s) 2 |
| Entomb | 4 | A | Hardened Amber | Stuck dinos take +30% from everything | Damage x 1.6, Entomb amp % 30 ⚙ |
| Entomb | 4 | B | Spreading Amber | The amber jumps to the next dino | Damage x 1.5, Entomb spread 1 (⚙ Rate x) |
| Entomb | 4 | C | Sticky Bed | Dinos walking past a stuck one slow 30% | Damage x 1.6, Entomb slow % 30 ⚙ |
| Entomb | 5 | A | Amber Age | Every 12 s, everything in range is stuck | Damage x 1.8, Entomb all every (s) 12 ⚙ |
| Entomb | 5 | B | Living Amber | Traps a boss 3 s; others stay stuck longer | Damage x 1.8, Rate x 1.15, Entomb (s) 2.5 ⚙, Boss entomb (s) 3 |
| Entomb | 5 | C | Time Capsule | Stuck dinos are sent 12 studs back | Damage x 1.8, Send back (studs) 12 ⚙ |
| Fossilize | 1 | | Collector's Eye | — | Damage x 1.3, Range x 1.15, Fossil below % 10, Sink cash 4 |
| Fossilize | 2 | | Rare Find | — | Damage x 1.8, Rate x 1.3, Range x 1.15, Fossil below % 12, Sink cash 10 |
| Fossilize | 3 | | Fossil Record | — | Damage x 2.6, Rate x 1.5, Range x 1.15, Entomb hits x 0.7, Fossil below % 20, Sink cash 16 |
| Fossilize | 4 | A | Museum Piece | Fossils pay double cash | Sink cash 32 ⚙ |
| Fossilize | 4 | B | Dig Crew | A fossil drops a cash chest | Sink chest cash 25 ⚙ |
| Fossilize | 4 | C | Bone Dust | Fossils mark nearby dinos +15% | Take-down mark % 15 (⚙ Rate x) |
| Fossilize | 5 | A | Fossil Fuel | Each fossil speeds up nearby towers | Fossil below % 25, Fossil rate % 5 ⚙ |
| Fossilize | 5 | B | Prize Fossils | More fossils; each counts double for bounties | Fossil below % 30 ⚙, Bounty fossils x 2 |
| Fossilize | 5 | C | Amber Heart | Every 15th fossil freezes your whole side 1 s | Heart every (fossils) 15 ⚙ |
| Resin Shell | 1 | | Coat of Resin | — | Aura HP % 15 |
| Resin Shell | 2 | | Sticky Armour | — | Aura HP % 15, Resist % 20 |
| Resin Shell | 3 | | Amber Shield | — | Aura HP % 15, Resist % 20, Seal (s) 3 |
| Resin Shell | 4 | A | Self-Sealing | Sealed towers heal 30% when the shell breaks | Seal heal % 30 ⚙ |
| Resin Shell | 4 | B | Raider Glue | Raiders and biters near your towers slow down | Biter slow % 25 ⚙, Biter slow (s) 2, Raider slow % 20, Raider slow (s) 2, **PvP effect yes** |
| Resin Shell | 4 | C | Sticky Thorns | Biters get slowed and take 5 damage | Thorns damage 5 ⚙, Biter slow % 15, Biter slow (s) 1.5 |
| Resin Shell | 5 | A | Amber Fortress | Nearby towers can't be knocked out (20 s each) | Seal every (s) 20 ⚙ |
| Resin Shell | 5 | B | Resin Wall | Once a round, an amber wall holds every dino 3 s | Wall (s) 3 ⚙ |
| Resin Shell | 5 | C | Amber Mirror | Throws at your towers bounce back | Grounding every (s) 1, Reflect damage 60 ⚙ |

Round-19 card lines changed for numbers only (🦖 text kept): Amber Age "every 12 s"
(seed 20 s scored 0.6× its slot), Sticky Thorns "5 damage", Amber Heart "every 15th" (10th
scored 1.4×), Amber Fortress "(20 s each)".
**Worth metrics (#314):** **Entomb** = 120 × H + eDPS + amp, H = hold-seconds/s: E = rate ÷
max(1, 6 × hits x × 0.6) × (1 + 0.5 × spread) entombs/s; H = E × Entomb s × (1 − boss) +
min(E, 1/10) × (Boss entomb s or Entomb s × 0.5) × boss + 4 × Entomb s × (1 − boss/2) ÷ Entomb
all every + E × Send back ÷ 8 × (1 − boss) + 1.5 × Entomb slow %/100 × E × Entomb s + min(1,
rate) × 0.2; amp = Entomb amp %/100 × 120 × (the entomb part of H). **Fossilize** = cash a round:
F × (Sink cash + 0.8 × Sink chest cash) + 14 × (mark credit 1.5 dinos × 3 s × Take-down mark %
× 120 ÷ 50 per fossil + Fossil Fuel aura credit at the round-average stack + Heart: 10 dinos ×
1 s × 120 ÷ 50 per trigger), F = E × 50 × min(1, 2 × Fossil below %/100) fossils a round;
Bounty fossils score 0 (meta only). **Resin Shell** = points (Armory/Tonic style, #292): Aura
HP % + Resist % + 2 × Thorns + Biter slow % × s ÷ 4 + 10 × Seal s × seals a round (1; Fortress
3) + Seal heal % ÷ 2 + 20 × Wall s + Reflect damage ÷ 3 ÷ Grounding every + 20 ÷ Grounding
every. Raider Glue scored without its Raider columns (#284).
**Director check (these metrics):** Entomb T4 A/B/C 210/235/275 (0.89–1.17×); T5 after A4
291/300/313, after B4 298/336/390, after C4 337/391/378 (all 0.89–1.16×). Fossilize T4
384/432/464, T5 after A4 572/576/608, B4 632/648/656, C4 672/697/688 (0.89–1.07×). Resin
Shell T4 80/77.5/80.6; T5 after A4 140/140/120 (0.86–1.0×); Raider Glue's dino part 0.97×.
**Release line (#314; like Tar Pit #198):** `value.py` prints per path, r21–30 and r31–40:
entombs and hold-seconds a round, fossils and fossil cash a round, payback rounds per
Fossilize tier (**bar: T1–T3 each pays back in 8–15 rounds**, #203's rule; lever `Sink cash`
of that tier), and the Resin Shell points. **Round-20 bar:** the Entomb T2 cannon holds ≥ 10
hold-seconds a round in r11–20 (lever: Tuning `Entomb base (s)`, +0.1 at a time, ≤ 1.2).
**Studio aids:** `fossils <n>`, `firenow RESIN` (Amber Age / Resin Wall now).
**T123 (Builder):** `Shared/Resin` + `Shared/AutoFire` + the `4× TOWERS` Tuning block (pure,
specs: entomb threshold at 100 %/50 %/10 % HP; boss cooldown + half time; Living Amber full 3 s;
spread; Sticky Bed; Send back never moves a boss; fossil pays every size + Sink cash scaled
(Hard); Heart every 15th; seal at 1 HP once a round / Fortress per tower 20 s; wall holds and
releases bosses at half; AutoFire's three triggers + never empty) → sheet rows + columns +
registry kinds → `Towers` behaviour, look (amber cannon; entombed dino glows orange; fossil
turns to stone and crumbles), unreleased → value.py metrics + release line. Accept: specs,
audit clean, Config diff accounted for, `--options` clean for `RESIN`.

#### The walker module (`Shared/Walker`, pure; 9g builds it, Paratroopers 9h and rangers 9j reuse it, #315)
A walker is an NPC unit on its own side's track, owned by one tower. Server module **`Walkers`**
owns walker state (ARCHITECTURE §4: add the row); damage to dinos goes through `Enemies`
(rule 4), bites on walkers are decided by `Walker` + `Combat`'s dino-attack rules.
- **Data:** per-kind base in the tower's Tuning block (HP, speed studs/s, reach, retreat HP
  share, respawn s, home heal HP/s, leash x); per-build columns `Walkers` (max) · `Walker HP x`
  (mult) · `Walker speed x` (mult) · `Walker resist %` (max) · `Walker respawn x` (mult) ·
  `Hold (s)` (max) · `Boss hold (s)` (max) · flags `Flanking`, `Targets first`, `Hits air`
  (generic: the tower can hit flyers), `Heals between rounds`, `Dodge`. Bite / shot = the
  tower's composed Damage, every 1 ÷ rate s, with its Size breaks, Pierces armour, Mark %,
  Boss x, Slow % / linger (the generic hit rules). Walker HP = base × Walker HP x × (1 + Tower
  HP per tier × tiers bought), as towers.
- **States:** `home` (at the tower; heals home heal/s; leaves when HP ≥ 80 % and a target is
  in range) → `out` (runs along the track from the track point nearest home toward its target)
  → `fight` (in reach: the first contact is a **pounce**: × `First dive x` on the first pounce
  after leaving home, and a hard stop of `Hold (s)` on non-bosses, `Boss hold (s)` once per
  boss; then bites/shots every 1 ÷ rate s; follows the target) → `back` (target gone, target
  beyond range × leash x, or HP ≤ retreat share; runs home at speed × 1.5) → `home`. **`down`**
  at 0 HP: vanishes, back at home after respawn s × Walker respawn x. `post` (9j rangers: stand
  at a set track point, shoot in range, never chase). Targeting: dinos on its side within the
  tower's range, ground only unless `Hits air`; default nearest to home; `Targets first` =
  furthest along; `Flanking` = no two walkers of a tower on one dino while another is free.
- **Dinos fight back:** a dino with a walker on it bites the walker (its melee damage × size
  share × difficulty, as vs a tower, × (1 − Walker resist %)) instead of a tower; it keeps
  walking unless held (the walker follows). **Trample:** a walker in the path of a dino with ≥
  `Trample size` sizes left (not the one it fights) takes Trample share × its max HP, once per
  dino. `Dodge`: ignores one bite per Dodge every (s) and never takes trample from small dinos.
- **Limits:** `Walker cap per side` (4× TOWERS block, seed 24) — walkers past the cap aren't
  spawned (Swarm raptors last); hunters can't hit walkers and walkers never touch hunters
  (Raider Hounds use the generic Raider sting; the run at the hunter is visual only); walkers
  never leave their side's track or block hunters; a Trampled home tower keeps its walkers
  out but sends none until repaired; selling removes them.
- **Model (`value.py`, #314):** walker eDPS = Walkers × uptime (0.7 × Walker speed x^0.3; 0.8
  with Heals between rounds or Walker respawn x < 1; 0.85 with Dodge) × the honest-hits bite
  DPS (+ first pounce: (First dive x − 1) ÷ 6 bites per pounce). Holds count 0 on damage paths
  (blind spot, like stun, 9c) and as hold-seconds on the Trainer path.
- **Specs:** the state machine (each transition), leash, retreat + heal + respawn, Flanking,
  Targets first, bite-back with resist, trample (and Dodge), boss hold once per boss, cap,
  never off its side, a sold tower clears its walkers.

#### Raptor Pen (`RAPTOR`) — damage (Pack, Alpha) + support (Trainer)
**Towers row:** Cost 850 · Damage 10 (per bite) · Fire rate 1.5 (bites/s per raptor) · Targets 1 ·
Range 22 (the hunting ground) · Hits air No · Unlock 500 · Key `RAPTOR` · Max HP 150 · note
"Tamed raptors sprint out, pounce, bite and come back; they can be bitten. TOWERS_LATER.md."
1 raptor at tier 0.
**Tuning block `RAPTOR PEN`:** Raptor HP 60 · Raptor speed 30 · Raptor reach 4 · Pounce hold (s)
0.5 (the `Hold (s)` when blank) · Retreat HP share 0.3 · Raptor respawn (s) 8 · Pen heal (HP/s)
15 · Leash x 1.5 · Trample size 3 · Trample share 0.25 · Dodge every (s) 3 · Swarm raptors 10 ·
Swarm share 0.4 · Swarm (s) 15 · Charge knockback (studs) 6 · Guard reach (studs) 10 · Roar
reach (studs) 10 · Hungry Alpha cap % 50.
**Raptor-only rules:** `Alpha` (flag): one big raptor (look; Walkers stays 1). `Swarm` (flag;
AutoFire): Swarm raptors small raptors (Swarm share × HP and bite) pour out and hunt anywhere
on the side's track for Swarm s, then vanish. `Charge` (flag; AutoFire): every standing raptor
runs the whole side's track at ×2 speed from the exit end back, biting each dino it passes
once and knocking small dinos back Charge knockback studs (not bosses), then returns. `Guard`
(flag): each raptor is posted beside a tower in range (most damaged first); a dino within
Guard reach that bites or throws at that tower is attacked, then the raptor returns to its
post. `Stun roar every (s)` (min-positive): the alpha roars; small dinos within Roar reach are
stunned `Stun (s)`. `Take-down stack %` (max): each take-down by this tower's walkers adds x %
damage for the round (cap Hungry Alpha cap %). `Avenger x` (max): with no raider stung in the
last 3 s, raptors target the last dino that damaged a tower in range, bites × x. `Dive aura
rate %` (Falcon's column) = towers in range attack faster while a raptor is in `fight`.
`Hunter damage %` while ≥ 3 raptors are out (common rule 4).
**New columns (kind):** Walkers max · Walker HP x mult · Walker speed x mult · Walker resist %
max · Walker respawn x mult · Hold (s) max · Boss hold (s) max · Flanking flag · Targets first
flag · Hits air flag · Heals between rounds flag · Dodge flag · Alpha flag · Swarm flag ·
Charge flag · Guard flag · Stun roar every (s) min-positive · Take-down stack % max · Avenger
x max · Hunter damage % max.

| Path | Tier | Opt | Name | Blurb (card) | Cells (T1–3 cumulative; T4/T5 own step) |
|---|---|---|---|---|---|
| Pack | 1 | | Second Raptor | — | Walkers 2 |
| Pack | 2 | | Quick Whistle | — | Walkers 2, Damage x 1.4, Walker speed x 1.3, Walker respawn x 0.7 |
| Pack | 3 | | Pack of Five | — | Walkers 5, Damage x 1.4, Walker speed x 1.3, Walker respawn x 0.7 |
| Pack | 4 | A | Hide Rippers | Raptors bite through armour | Damage x 1.75 ⚙, Pierces armour Yes |
| Pack | 4 | B | Flanking | Each raptor picks a different dino | Damage x 1.85 ⚙, Flanking Yes |
| Pack | 4 | C | Ambush | Each raptor's first pounce hits double | Damage x 1.75 ⚙, First dive x 2 |
| Pack | 5 | A | Raptor Swarm | 10 small raptors flood the track once a round | Damage x 1.7 ⚙, Swarm Yes |
| Pack | 5 | B | Clever Girls | Raptors dodge bites and never get trampled | Damage x 1.75 ⚙, Dodge Yes |
| Pack | 5 | C | Sky Leap | Raptors jump at low flyers | Damage x 1.95 ⚙, Hits air Yes |
| Alpha | 1 | | Sharp Claws | — | Damage x 1.9 |
| Alpha | 2 | | Thick Hide | — | Damage x 3.6, Walker HP x 1.6, Walker resist % 25 |
| Alpha | 3 | | Alpha Raptor | — | Damage x 7, Walker HP x 3, Walker resist % 25, Size breaks 2, Hold (s) 1, Alpha Yes |
| Alpha | 4 | A | Sickle Claw | ×3 on its target, breaks 3 | Damage x 1.8 ⚙, Size breaks 3 |
| Alpha | 4 | B | Boss Hunter | Can hold a boss for a moment | Damage x 1.6 ⚙, Boss x 1.6, Boss hold (s) 0.5 |
| Alpha | 4 | C | Scent Trail | Its target is marked +15% | Damage x 1.7 ⚙, Mark % 15 |
| Alpha | 5 | A | King of the Pack | A giant raptor, half damage taken | Damage x 1.9 ⚙, Size breaks 4, Walker resist % 50, Walker HP x 1.5 |
| Alpha | 5 | B | Rex Tamer | A tamed T. rex whose roar stuns | Damage x 2 ⚙, Walker HP x 1.4, Stun roar every (s) 15, Stun (s) 1 |
| Alpha | 5 | C | Hungry Alpha | Stronger with every take-down | Damage x 1.75 ⚙, Take-down stack % 10 |
| Trainer | 1 | | Tracking Nose | — | Damage x 1.3, Range x 1.15, Targets first Yes |
| Trainer | 2 | | Herding Call | — | Damage x 1.6, Range x 1.15, Targets first Yes, Slow % 20, Slow linger (s) 1 |
| Trainer | 3 | | Pack Howl | — | Walkers 2, Damage x 2.2, Range x 1.15, Targets first Yes, Slow % 20, Slow linger (s) 1, Dive aura rate % 15 |
| Trainer | 4 | A | Treat Bag | Raptors heal and return faster | Damage x 1.4 ⚙, Heals between rounds Yes, Walker respawn x 0.5 |
| Trainer | 4 | B | Guard Raptors | A raptor guards each tower | Damage x 1.3 ⚙, Guard Yes |
| Trainer | 4 | C | Whistle Drill | Raptors run 30% faster | Damage x 1.3, Walker speed x 1.3, Dive aura rate % 20 ⚙ |
| Trainer | 5 | A | Raptor Charge | Every raptor charges the track once a round | Damage x 1.5 ⚙, Charge Yes |
| Trainer | 5 | B | Pack Bond | Hunters nearby +20% with 3+ raptors out | Damage x 1.1 ⚙, Walkers 3, Hunter damage % 20 |
| Trainer | 5 | C | Raider Hounds | Raptors chase raiders (or the dino that hurt a tower) | Damage x 1.5, Avenger x 2 ⚙, Size breaks 2, Raider damage 10, Raider slow % 20, Raider slow (s) 1, **PvP effect yes** |

Card line changed for a number: Sickle Claw's "×3 on its target" is Damage x 1.8 over Alpha
Raptor (the alpha has one target; 🦖 may reword to "much harder bites, breaks 3").
**Worth metrics (#314):** **Pack, Alpha** = walker eDPS (above) + aura; Swarm adds Swarm
raptors × Swarm share × one raptor's DPS × Swarm s ÷ 50; Hungry Alpha × (1 + cap ÷ 200); Rex
roar and holds 0 (blind spots, they carry damage). **Trainer** = walker eDPS + aura credit
(Dive aura rate % × 0.7 uptime) + 120 × H (H = Walkers × uptime × Slow %/100 + Charge: 6
dinos × Charge knockback ÷ 8 ÷ 50) + 0.2 × own eDPS for Guard + Hunter damage credit × 0.6 (3+
out share) + Avenger: own eDPS × 0.3 × (Avenger x − 1). Raider Hounds scored without its
Raider columns.
**Director check:** Pack T4 (bite-multiplier equivalents) 1.98/1.85/2.04, T5 2.1/2.12/2.1;
Alpha T4 1.98/2.01/1.96, T5 ~2.2/2.0/2.19 (all inside 0.9–1.1×). Trainer T4 78/72/72.5; T5
after A4 107/125/113 (0.95–1.1×); Raider Hounds' dino part 1.0×.
**Seeds vs bars:** T0 r31–40 c/e ≈ 37 like Mortar Pit; the Pack/Alpha T5 cumulative eDPS gain
≈ ×28 (Mortar Blast's), so best T5 c/e ≈ 150 expected; T124b tunes by the exit rule.
**Studio aids:** `walkers`, `firenow RAPTOR` (Raptor Swarm / Raptor Charge now).
**T124 (Builder):** `Shared/Walker` + server `Walkers` + the `RAPTOR PEN` block (pure first, the
specs above + Swarm / Charge / Guard / roar / stack / Avenger specs, Pack Bond only with 3+
out and only vs dinos) → rows + columns → `Towers` behaviour, raptor look (🦖: tamed raptors
with a collar and stripe in the camp colour; Rex Tamer = a small tamed T. rex) → value.py
walker model + metrics. Accept: specs, audit clean, Config diff accounted for, `--options`
clean for `RAPTOR`; perf: 10 players × a Raptor Swarm each stays under the walker cap.
**T124b — 9g release + balance (#312):** both towers sold; bars of common rule 6 (Raptor: damage
bars + round-20; Resin: its release line, Fossil payback, round-20 hold); exit rules; commit
message = a table of every new T5 (c/e, × M) and each tuned cell. **Then Tester Run 9g**
(common rule 10, plus: a dino entombed at low HP becomes a fossil and pays; Amber Shield seals
a tower at 1 HP once a round; Resin Wall fires itself on a bunch; a raptor bitten to low HP runs
home and heals; Raptor Swarm fires itself; Raider Glue and Raider Hounds sting the Tester at
×0.5 with no sting through Camo Cover, and in co-op Glue slows a biter and Hounds hunt the
dino that bit a tower).
**T124c — finishes T124b (Director 2026-10-14, #325–#328; ONE Builder commit, then Tester Run
9g).** Checked on a copy (`value.py`, `--options`, `--breaks1`: all exit 0, no Raptor DEAD).
1. **Raptor lever = bite rate, not Damage (#325, #326).** `Towers!D20` (Damage) 11 → **10**
   (assert 11; Damage 11 failed break bar 1 on Alpha Raptor T3, S/B1 1.09); `Towers!E20` (Fire
   rate) 1.5 → **2.3** (assert 1.5); `C20` stays 600. Result: Pack T5 c/e 147–184, Alpha T5
   168–230 (best 147 ≤ 177; worst 230 ≤ 284); best T2 (Pack Quick Whistle) 331 ≤ 386; King of
   the Pack bar 3 S 295 ≥ 291; options clean. Pack/Alpha stay damage paths on eDPS; holds and
   bite-soaking stay uncredited (playtest watches below).
2. **Museum Piece (#327):** `Tower Upgrades!CD310` (Sink cash) 32 → **150** (assert 32); card
   "Fossils pay 50% more cash". Slot T4 A 1,786 / B 1,429 / C 1,460 (A 1.22×); T5 after A4
   2,288 / 2,679 / 2,052 (0.90–1.17×). Fossilize T1–T3 (50/100/100) untouched.
3. **Clever Girls (#328):** the rule changes, not the card: `Dodge` = ignores one bite per
   Dodge every (s) **and is never trampled by any dino** (bosses too). Fix `Shared/Walker` +
   its spec (a 3-size dino passes a Dodge raptor: no trample). No cell moves.
4. **Docs:** `UPGRADES.md` Raptor Pen line: "600 cash, 10 per bite, 2.3 bites a second";
   Museum Piece card; this section's Towers row seeds → 600 / 10 / 2.3.
5. **Release:** remove `RESIN` and `RAPTOR` from `ShopRules.Unreleased` (and value.py's
   unreleased set); Amber unlock 500 live; `ROUND9_BATCH` stays out of M (142). Export,
   Config diff = the 3 cells + the two keys sold; `tools/test.sh` green. Commit message: the
   T5 table above (c/e, × M) + each tuned cell.
6. **Tester Run 9g** as T124b, plus watches (report, not bars): a pounced dino visibly stops
   (0.5 s; alpha 1 s); dinos bite raptors instead of the pen's neighbours; a Clever Girls
   raptor in a big dino's path is not trampled; a Museum Piece fossil pays 150 Sink cash.
**T124d — unblocks T124c step 5 (Director 2026-10-15, #329–#330; ONE Builder commit = T124c
step 5 + these, then step 6).** T124c steps 1–4 stand (03c9634). Checked on a copy with RESIN
and RAPTOR released: `--breaks1` (with step 2) exit 0, `--options` 0, `value.py` 0, no new DEAD.
1. **King of the Pack stays gated by bar 3 (#329); lever = bite rate.** `Tower Upgrades!H338`
   (Rate x, row M338 "King of the Pack") 1 → **1.25** (assert 1; assert `BJ338` Size breaks 4
   unchanged, it's at `MaxSizeBreaks`). r21–30 S 151 → **188** ≥ 182; r31–40 368 ≥ 291. King c/e
   230 → 184 (1.30× M); best Raptor T5 Raptor Swarm 155 ≤ 177; Alpha T5 slots 5A 368/308/341,
   5B 439/369/405, 5C 395/328/368 (options clean). Not Damage x: r21–30 S is capped at 4 × B1.
2. **Bar 3 median frozen like M (#330).** `tools/value.py` `breaks_report`: the `medians`
   filter becomes `t == 5 and not r["support"] and r["released"] and k not in ROUND9_BATCH`;
   header line notes "(4× batch out, #330)". Expect "T5 median: r21-30 182, r31-40 291" with
   the towers released. (Without it the median chases King and at 1.3 fails Harpoon Skewer.)
3. **Release = T124c step 5** unchanged. Config diff = T124c's cells already in + `H338` (King
   rate x 1.25) + the two keys sold. Commit message adds the King row (c/e 184, 1.30× M; bar 3
   S 188 / 368) and the re-measured Alpha T5 range. `tools/test.sh` green; `--breaks1` 0 released.
4. **Docs:** none; the card ("A giant raptor, half damage taken") and `UPGRADES.md` stay
   (Rate x is a hidden number, like Sickle Claw's Damage x, #318).

**9h — Spotter Blimp + Bone Totem** (T125 Blimp, T126 Totem, T126b release).

#### Spotter Blimp (`BLIMP`) — untouchable; damage (Door Gun), support (Searchlight), drops (Cargo)
**Towers row:** Cost 750 · Damage 3 · Fire rate 2 · Targets 1 · Range 14 (the gun's reach below
the blimp) · Hits air Yes · Unlock 400 · Key `BLIMP` · Max HP 0 · **Untouchable Yes** · note
"Its mooring mast is placed like any tower; the blimp flies your track there and back. Can't be
damaged (#148)." Untouchable rules as T63 (no HP, never targeted, never repaired, skipped by
Armory/Hospital auras). Mast placement: normal off-track rules.
**Tuning block `SPOTTER BLIMP`:** Blimp speed (studs/s) 40 (a lap ≈ 30 s on the 610-stud track) ·
Paratrooper HP 80 · Paratrooper damage 8 · Paratrooper rate 1 · Paratrooper reach 14 ·
Paratrooper speed 14 · Hook max sizes 2 (Sky Hook takes only dinos at ≤ 2 sizes left).
**Mechanics (pure `Shared/Blimp`):**
1. **Flight.** The blimp flies along its side's track from the spawn end to the exit end and
   back (a **lap**), `Blimp speed` × `Blimp speed x`, 30 studs up; everything it does is
   centred on the track point below it (range = a circle there). Several blimps fly
   independently. Hits flyers. Model: coverage = min(1, 10 × 2 × Range ÷ track length).
2. **Lap drops.** Cargo uses Supply Camp's crate rules (`Chests`, `Chest cash`; a crate lands
   on the ground below the blimp and lasts Chest lifetime): `Chests` = crates a round (Air
   Drop timing), or one every lap with `Lap chests`. `Med kits` / `Med kit heal` (Hospital
   Rescue's kits) drop one per lap below it. `Lap repairs` n: each lap repairs up to n
   Trampled towers within range of its path (free, as a full repair). `Crate heal %`: a crate
   heals the tower nearest where it lands by that share of max HP. `Paratroopers` n: once per
   round played (round start, after 10 s), n walkers (ranger look, kind `PARATROOPER`, the
   9g walker in `fight` mode with their Tuning stats, hunting dinos within Paratrooper reach of
   where they land, ground only) drop below the blimp and stay until the round ends.
   `Airlift` (flag): the first tower on its side Trampled each round is lifted and set back
   down repaired after 3 s (automatic, #283; no "you choose" button, #318).
3. **Light.** `Brittle %` (Tranq's column; dinos in range take +x %) is the searchlight under
   the blimp. `Aura range %` (new): towers in range +x % range. `Throw miss %` (new): dinos in
   range miss x % of their throws (a missed throw lands short). `Targets biggest` (9e): the
   light (and gun) centre on the biggest dino on the side instead of below the blimp, moving at
   Blimp speed. `Aura reach x` (new): the blimp's aura damage reaches towers within Range × x
   of its point. `Dino outlines` (flag): own-side hunters see every dino on their side through
   walls (a client highlight; **never players**, never another side's dinos).
4. **Gun extras.** Mortar's `Bomblets` (rockets), `Mark %`, `Size breaks`, `Line hits`
   (Strafing Run = a line along the track). `Bombing run` (flag; AutoFire): once per round
   played, every dino on the side's track takes `Field strike x` × the gun's damage (9e Field
   strike rules: air too, armour only if it pierces, breaks 1). `Hook every (s)`: every N s
   the smallest non-boss dino in range with ≤ Hook max sizes left is lifted off the track (a
   take-down: each size pays, pops to the owner).
**New columns (kind):** Blimp speed x mult · Lap chests flag · Lap repairs max · Crate heal % max
· Paratroopers max · Airlift flag · Aura range % max · Throw miss % max · Aura reach x max ·
Dino outlines flag · Bombing run flag · Hook every (s) min-positive. (Reused: Shots, Line
hits, Bomblets, Mark %, Size breaks, Pierces armour, Brittle %, Targets biggest, Field strike
x, Chests, Chest cash, Med kits, Med kit heal, Hunter reload x, Aura damage %.)

| Path | Tier | Opt | Name | Blurb (card) | Cells (T1–3 cumulative; T4/T5 own step) |
|---|---|---|---|---|---|
| Door Gun | 1 | | Belt Gun | — | Damage x 1.5, Rate x 1.2 |
| Door Gun | 2 | | Twin Mount | — | Damage x 1.5, Rate x 1.2, Shots 2 |
| Door Gun | 3 | | Strafing Run | — | Damage x 2.6, Rate x 1.2, Shots 2, Line hits 3 |
| Door Gun | 4 | A | Heavy Mount | Shoots through armour, breaks 2 | Damage x 1.7 ⚙, Pierces armour Yes, Size breaks 2 |
| Door Gun | 4 | B | Rocket Pods | Rockets that splash | Damage x 1.3 ⚙, Bomblets 3 |
| Door Gun | 4 | C | Tracer Belt | Hit dinos are marked +15% | Damage x 1.75 ⚙, Mark % 15 |
| Door Gun | 5 | A | Gunship | Faster, four guns and rockets | Damage x 1.05 ⚙, Shots 4, Bomblets 2, Blimp speed x 1.5 |
| Door Gun | 5 | B | Bombing Run | Bombs the whole track once a round | Damage x 1.6, Bombing run Yes, Field strike x 12 ⚙ |
| Door Gun | 5 | C | Sky Hook | Snatches the smallest dino every 5 s | Damage x 1.7 ⚙, Hook every (s) 5 |
| Searchlight | 1 | | Spotlight | — | Brittle % 10 |
| Searchlight | 2 | | Wide Beam | — | Brittle % 10, Range x 1.3 |
| Searchlight | 3 | | Night Hunt | — | Brittle % 10, Range x 1.3, Aura range % 15 |
| Searchlight | 4 | A | Floodlights | Lights a much wider circle | Range x 1.6 ⚙ |
| Searchlight | 4 | B | Tracking Beam | The light follows the biggest dino | Targets biggest Yes, Brittle % 20 ⚙ |
| Searchlight | 4 | C | Blinding Glare | Dinos in the light miss throws | Throw miss % 25, Brittle % 15 ⚙ |
| Searchlight | 5 | A | All-Seeing Eye | Every dino under the blimp marked +30% | Brittle % 30 ⚙ |
| Searchlight | 5 | B | Lighthouse | Towers near its path +10% damage | Aura damage % 10 ⚙, Aura reach x 2 |
| Searchlight | 5 | C | Spotter's Map | See every dino through walls | Dino outlines Yes, Brittle % 20 ⚙ |
| Cargo | 1 | | Supply Crates | — | Chests 1, Chest cash 60 |
| Cargo | 2 | | Ammo Drop | — | Chests 1, Chest cash 60, Hunter reload x 0.8 |
| Cargo | 3 | | Med Drop | — | Chests 1, Chest cash 60, Hunter reload x 0.8, Med kits 1, Med kit heal 40 |
| Cargo | 4 | A | Heavy Cargo | Bigger crates | Chest cash 150 ⚙ |
| Cargo | 4 | B | Rebuild Kits | Fixes a Trampled tower each lap | Lap repairs 1 ⚙ |
| Cargo | 4 | C | Spare Parts | A crate heals the closest tower | Chest cash 90, Crate heal % 20 ⚙ |
| Cargo | 5 | A | Cargo Run | A big crate every lap | Lap chests Yes, Chest cash 300 ⚙ |
| Cargo | 5 | B | Paratroopers | Drops 2 rangers a round | Paratroopers 2 ⚙ |
| Cargo | 5 | C | Airlift | Fixes the first Trampled tower each round | Airlift Yes ⚙ (Chest cash) |

Card lines changed: Gunship "four guns" (Shots 4: two twin mounts); Lighthouse "towers near
its path" (Round-19 "all your towers … while it passes" — a whole-side aura from one tower broke
the aura rules); Airlift (no "somewhere you choose": a button, #283/#318). 🦖 may reword.
**Worth metrics (#314):** **Door Gun** = eDPS × coverage + Bombing run (Field strike x ×
damage × 10 dinos ÷ 50) + Sky Hook (one small dino's HP — the band's average last-two-sizes
HP — ÷ Hook every) + aura; untouchable band 1.25–2 × M on every T5 build. **Searchlight** =
120 × lit × Brittle %/100 (lit = 10 × coverage; with Targets biggest: 1 + boss) + aura_credit
(Aura range % counted as rate % ÷ 2; Aura damage % on 3 × Aura reach x neighbours × coverage)
+ 0.5 × Throw miss % + Dino outlines 0 (meta-ish; it carries Brittle). **Cargo** = cash a
round: crates × Chest cash × 0.8 (laps a round = 50 ÷ lap s) + Lap repairs × laps × 0.3 ×
0.3 × 6,000 (a Trampled tower below 30 % of laps; repair = 0.3 × an average 6,000 tower) +
Crate heal % × 150 HP × crates × 2 cash/HP + 14 × (Hunter reload credit: 30 × (1/x − 1) × 0.3
+ Paratroopers' walker eDPS × 0.8) + med kits × heal × 0.5 + Airlift 0.2 × 0.3 × 6,000 × 2.
**Director check (rough, these metrics):** Door Gun T4 1.92/1.95/2.01×, T5 ~2.1/2.05/~2.0
(Sky Hook's credit is the Builder's number; lever Damage x). Searchlight T4 ×1.6/×1.7/×1.6 of
T3's light credit. Cargo T5 after A4 408/480/480 (0.85–1.0×). Tight spots the Builder must
confirm: Sky Hook, Paratroopers, Airlift (all ⚙).
**Studio aids:** `firenow BLIMP` (Bombing Run / Paratroopers / Airlift now), `walkers`.
**T125 (Builder):** `Shared/Blimp` (pure: lap position over time, coverage circle, crate/kit/
repair drops per lap, Tracking Beam point, hook choice, AutoFire bombing, Airlift once a round)
+ `SPOTTER BLIMP` block → rows + columns → behaviour (blimp model 30 studs up, door gunner,
searchlight cone; mast footprint) + Paratroopers via `Walker` → value.py. Accept: specs (lap
timing, a dino under the blimp is hit and one far away isn't, untouchable, Dino outlines shows
own-side dinos only and never a player), audit, Config diff, `--options` clean for `BLIMP`.

#### Bone Totem (`TOTEM`) — charge from Bones: damage (Roar), buffs (Ancestors), cash (Bone Pile)
**Towers row:** Cost 800 · Damage 60 (per roar hit) · Fire rate 0 · Targets 1 · Range 24 · Hits
air Yes · Unlock 450 · Key `TOTEM` · Max HP 200 · note "Bones taken near it charge it; full =
Spirit Roar (area, breaks 2). Never adds Bones to any score. TOWERS_LATER.md."
**Tuning block `BONE TOTEM`:** Totem charge (Bones) 8 · Roar breaks 2 · Fear knockback (studs) 8
· Shatter strip (s) 4 · Skull x 0.6 · Spirit hunters 3 · Spirit hunter damage 10 · Spirit
hunter rate 2 · Spirit (s) 6 · Full buff (s) 6 · Finisher % 25 · Treasure cash 1,500.
**Mechanics (pure `Shared/Totem`):**
1. **Charge.** Every pop (a dino losing a size) inside the totem's range on its side, made by
   anyone on its side (towers, walkers, hunters), adds 1 × `Charge x` (hunter pops × `Hunter
   charge x`; a boss's pop adds Totem charge × `Boss charge %` / 100 instead, if set). **Pops
   made by any Bone Totem's roar, skulls or spirit hunters never charge a totem** (no loop).
   Full = Totem charge × `Charge needed x`; on full the path's effect fires and the charge
   restarts (overflow kept). Charge carries over between rounds (battles too); reset at match
   start. **It only reads pops:** Bones, Bone Rush score, Ranked results, Hunt Board counts
   are untouched (`Bounty charge x` only changes the owner's Bounties progress); no Amber.
2. **On full:** Roar path and Ancestors — the **Spirit Roar** (every dino in range takes
   Damage × Damage x, breaks Roar breaks or `Size breaks`, armour only with Pierces armour;
   `Roar echoes` 1 = a second roar 1 s later; `Roar whole track` = every dino on the side;
   `Skulls` n = instead n skulls each hit a different dino anywhere on the side for Skull x ×
   damage, breaks 1; `Knockback (studs)` on small dinos (not bosses); `Strips armour` for
   Shatter strip s) — plus Ancestors' `Full guard (s)` (towers in range take no damage that
   long), `Hunter damage %` and `Spirit hunters` (Tuning count, 6 s, fire at dinos in range)
   for Full buff s / Spirit s. Bone Pile from T3 — **no roar**; pays `Full cash` to the side
   (+ `Payday cash` × hunters on the side; `Treasure` flag: the first full of the match also
   drops a Treasure cash chest).
3. **Continuous:** `Charge aura damage %` (towers in range + x % × charge share; Old Bones),
   `Aura HP %`, `Aura range %` (9h), `Hunter ability cooldown x` (new; own hunters in range),
   `Side aura half` (flag; Totem Pole: its auras reach every tower on the side at half
   strength), `Bone cash` (cash to the side per pop in range), `Bank cash per charge` (at each
   round end, × the charge held), `Finisher %` (flag `Finishing roar`: a boss in range
   dropping below 25 % HP triggers one free roar at it, once per boss; doesn't use charge).
**New columns (kind):** Charge x mult · Hunter charge x max · Boss charge % max · Bounty charge x
max · Charge needed x mult · Roar echoes max · Roar whole track flag · Skulls max · Full guard
(s) max · Spirit hunters flag · Full cash max · Payday cash max · Treasure flag · Charge aura
damage % max · Hunter ability cooldown x mult · Side aura half flag · Bone cash max · Bank cash
per charge max · Finishing roar flag. (Reused: Knockback, Strips armour, Size breaks, Pierces
armour, Aura HP %, Aura range %, Hunter damage %.)

| Path | Tier | Opt | Name | Blurb (card) | Cells (T1–3 cumulative; T4/T5 own step) |
|---|---|---|---|---|---|
| Roar | 1 | | Louder Roar | — | Damage x 1.6 |
| Roar | 2 | | Quick Charge | — | Damage x 2.2, Charge needed x 0.8 |
| Roar | 3 | | Thunder Roar | — | Damage x 4.2, Charge needed x 0.8, Size breaks 3, Pierces armour Yes |
| Roar | 4 | A | Echo Roar | The roar hits twice | Damage x 1 ⚙, Roar echoes 1 |
| Roar | 4 | B | Fear | The roar scares small dinos 8 studs back | Damage x 1.85 ⚙, Knockback (studs) 8 |
| Roar | 4 | C | Shatter Roar | The roar strips armour for 4 s | Damage x 1.8 ⚙, Strips armour Yes |
| Roar | 5 | A | Ancient Roar | The roar reaches your whole track | Damage x 0.8 ⚙, Roar whole track Yes |
| Roar | 5 | B | Skull Storm | 8 flying skulls hunt dinos | Damage x 1.6 ⚙, Skulls 8 |
| Roar | 5 | C | Finishing Roar | A free roar at a weak boss | Damage x 1.8 ⚙, Finishing roar Yes |
| Ancestors | 1 | | Old Bones | — | Charge aura damage % 20 |
| Ancestors | 2 | | Shared Charge | — | Charge aura damage % 20, Hunter charge x 2 |
| Ancestors | 3 | | Spirit Guard | — | Charge aura damage % 20, Hunter charge x 2, Full guard (s) 4 |
| Ancestors | 4 | A | War Paint | Hunters nearby +15% for 6 s when full | Hunter damage % 15 ⚙ |
| Ancestors | 4 | B | Bone Armour | Nearby towers get 20% more HP | Aura HP % 20 ⚙ |
| Ancestors | 4 | C | Ancestor's Eye | Nearby towers see 10% further | Aura range % 10 ⚙ |
| Ancestors | 5 | A | Spirit Hunters | 3 ghost hunters fire for 6 s when full | Spirit hunters Yes ⚙ (Tuning Spirit hunter damage) |
| Ancestors | 5 | B | Totem Pole | Buffs reach every tower, half strength | Side aura half Yes, Charge aura damage % 30 ⚙ |
| Ancestors | 5 | C | Elder Wisdom | Hero abilities nearby recharge 25% faster | Hunter ability cooldown x 0.75 ⚙ |
| Bone Pile | 1 | | Bone Collector | — | Bone cash 6 |
| Bone Pile | 2 | | Trade Post | — | Bone cash 14 |
| Bone Pile | 3 | | Bone Market | — | Bone cash 14, Full cash 400 |
| Bone Pile | 4 | A | Rare Bones | Bosses fill half the charge | Boss charge % 50 ⚙ |
| Bone Pile | 4 | B | Bone Bank | Leftover charge pays at round end | Bank cash per charge 25 ⚙ |
| Bone Pile | 4 | C | Bone Bonus | Each full charge pays 40% more | Full cash 560 ⚙ |
| Bone Pile | 5 | A | Camp Payday | Every hunter in your camp gets paid | Payday cash 30 ⚙ |
| Bone Pile | 5 | B | Bounty Wall | Bones nearby charge 25% faster and count +25% for bounties | Charge x 1.25 ⚙, Bounty charge x 1.25 |
| Bone Pile | 5 | C | Ancient Treasure | One big treasure chest a match | Treasure Yes ⚙ (Tuning Treasure cash) |

Seeds moved from the proposal (fewer, tougher dinos, #273): charge 8 Bones (not ~20: a 24-stud
totem sees ~18 pops a round in r31–40), Bone cash 6/14 (not 1), Full cash 400 (not 150), Bone
Bonus = +40 % of a full charge, not +40 cash. Card lines changed for that: Bone Bonus, Bounty
Wall (gains an in-match part, #318), War Paint "for 6 s".
**Worth metrics (#314):** fills/s = pops in range/s ÷ (Totem charge × Charge needed x) × Charge x
(× 1.3 with Hunter charge x 2: hunters make ~30 % of pops; Boss charge: + 0.5 fill per boss
round); pops in range a round = the band's pops × 2.5 × Range ÷ track length (stated; a
winding track). **Roar** = fills/s × honest hits on 4 dinos (10 whole track; Skulls × Skull x
dino-hits; × 2 with an echo) + Finisher: one roar per boss round ÷ 50 + aura; Fear/Shatter
carry damage (blind spots). **Ancestors** = aura credit (Charge aura damage % × 0.5 average
charge; × 3 side neighbours at half with Side aura half) + hunter credit (Hunter damage % × 30
× Full buff s × fills/s) + Spirit hunters (3 × 10 × 2 × 6 s × fills/s) + Elder Wisdom (30 ×
(1/x − 1) × 0.3) + points ÷ 2 for Aura HP % and Full guard s × 10 × fills a round. **Bone
Pile** = cash a round (Bone cash × pops in range + Full cash × fills + Payday × 2 hunters ×
fills + Bank × average charge 4 + Treasure × 0.8 ÷ 15 rounds); **bar: T1–T3 each pays back in
8–15 rounds** (#203; levers Bone cash, Full cash).
**Director check (rough):** Roar T4 2.0/1.85/1.8× of T3 (blind spots carried), T5 2.0/1.9/≈1.9
(Finisher's credit is the Builder's number). Bone Pile T5 after A4 575/519/505 (0.97–1.1×).
Ancestors: the Builder's numbers (four unlike credits) — ⚙ levers listed.
**Round-20 bar:** the Roar T2 totem's c/e in r11–20 ≤ 1.5 × the released T2 median (lever:
Tuning `Totem charge`, −1 at a time, ≥ 5).
**Studio aids:** `charge <n>`, `firenow TOTEM` (fills it now).
**T126 (Builder):** `Shared/Totem` (pure: charge from in-range pops by side, hunter ×2, boss
share, no self-charge from any totem's pops, overflow, carry-over, reset at match start, the
on-full effects per path, finisher once per boss, bank at round end; **specs that Bones / Bone
Rush score / Ranked / Hunt Board numbers are identical with and without a totem**) + `BONE
TOTEM` block → rows + columns → behaviour (skull totem; charge glow ring; roar shockwave; ghost
hunters) → value.py. Accept as T125.
**T126b — 9h release + balance (#312):** as T124b (Blimp untouchable band; Totem damage bars,
round-20 bar, Bone Pile payback). **Tester Run 9h:** common rule 10, plus: the blimp's crate
lands below it each lap (Cargo Run), Paratroopers drop and fight, a Trampled tower is lifted
and fixed (Airlift); a full totem roars, Bone Market pays instead, `charge` + kills near it fill
it, the Bones column is the same as a match without a totem.

**9i — Meteor Beacon + Volcano Vent** (T127 Meteor, T128 Vent, T128b release). Meteor = strikes
on the densest bunch anywhere on your side; Vent = owns one stretch (#282).

#### Meteor Beacon (`METEOR`) — damage (Impact, Sky Rocks), crater control (Aftermath)
**Towers row:** Cost 1000 · Damage 40 (per meteor) · Fire rate 0.0833 (one per 12 s) · Targets 5
(average caught; the densest bunch) · Range 999 (your side's whole track) · Hits air No ·
Splash radius 8 · Unlock 600 · Key `METEOR` · Max HP 150 · note "Calls a meteor on the
biggest bunch of dinos on your side: area hit + burning crater. Ground only."
**Tuning block `METEOR BEACON`:** Bunch radius (studs) 8 · Strike warning (s) 1 · Crater radius 6 ·
Crater (s) 5 · Crater burn DPS 10 · Small meteor x 0.6 · Small splash x 0.7 · **Extinction min
bunch 6** (the #283 row) · Extinction x 2.5 · Extinction breaks 4 · Starfall meteors 20 ·
Fire line gap (studs) 30 · Streak length (studs) 10.
**Mechanics (pure `Shared/Meteor`):**
1. **Densest bunch.** Aim = the point on the side's track (ground dinos) with the most dinos
   within Bunch radius (a boss counts 3; ties → furthest along); after Strike warning s (a red
   ring) every ground dino within Splash radius takes the hit, breaks 1; dinos within 2 studs
   of the centre break `Size breaks` (pierce-through). `Meteors` n: each strike is n small
   meteors (Small meteor x damage, Small splash x radius) on the n densest points, over 2 s;
   `Scatter` = the n points are the densest of n equal track segments; `Meteor every (s)`
   adds one small meteor on that timer; `Starfall every (s)` replaces the normal strike with
   Starfall meteors small meteors on the densest points across the side.
2. **Craters.** Each (big) meteor leaves a crater (Crater radius) for `Crater (s)` (blank =
   Tuning): dinos in it burn `Burn DPS` (blank = Crater burn DPS) × the tower level; `Strips
   armour` there (Glass Crater); `Crater amp %` (a dino that crosses takes +x % for 3 s);
   `Throw miss %` / `Bite miss %` (dinos in it miss that share); `Knockback (studs)` at impact
   (not bosses); `Crater freeze (s)` (a dino entering is hard-stopped once per crater; no burn
   if the row's Burn DPS is 0); `Fire line` (craters ≤ Fire line gap apart along the track join
   into one burning strip while both last); `Burn streak` (each small meteor leaves a Streak
   length burning strip for 3 s).
3. **Big moments (AutoFire):** `Extinction` (flag) — once per round played a giant meteor:
   every dino on the side takes Extinction x × the meteor's damage (breaks 1), the densest
   bunch's dinos break Extinction breaks; trigger = a boss or Extinction min bunch dinos in the
   bunch, else the last spawn. `Bombing run` + `Field strike x` (9h) = Comet Tail. `Side slow %`
   / `Side slow (s)` (new): after each meteor every dino on the side is slowed. `Biggest
   breaks +` (new): the biggest dino a meteor hits breaks that many extra sizes.
**New columns (kind):** Meteors max · Scatter flag · Meteor every (s) min-positive · Starfall
every (s) min-positive · Crater (s) max · Crater amp % max · Bite miss % max · Crater freeze
(s) max · Fire line flag · Burn streak flag · Extinction flag · Side slow % max · Side slow (s)
max · Biggest breaks + max. (Reused: Size breaks, Boss x, Pierces armour, Burn DPS, Strips
armour, Knockback, Throw miss % (9h), Hits air (9g), Bombing run, Field strike x (9h).)

| Path | Tier | Opt | Name | Blurb (card) | Cells (T1–3 cumulative; T4/T5 own step) |
|---|---|---|---|---|---|
| Impact | 1 | | Heavier Rock | — | Damage x 1.7 |
| Impact | 2 | | Iron Core | — | Damage x 3.3 |
| Impact | 3 | | Ground Zero | — | Damage x 6, Size breaks 2 |
| Impact | 4 | A | Planet Killer | Centre breaks 3, ×2 on bosses | Damage x 1.3 ⚙, Size breaks 3, Boss x 2 |
| Impact | 4 | B | Plate Cracker | Meteors cut through armour | Damage x 1.7 ⚙, Pierces armour Yes |
| Impact | 4 | C | Quick Call | A meteor every 8 s | Damage x 1.25 ⚙, Rate x 1.5 |
| Impact | 5 | A | **Extinction Event** | One giant meteor a round, fires itself | Damage x 1 , Extinction Yes (⚙ Tuning Extinction x) |
| Impact | 5 | B | Dino Killer | Breaks the biggest dino it hits 2 extra sizes | Damage x 1.9 ⚙, Biggest breaks + 2 |
| Impact | 5 | C | Impact Winter | Every dino on your side slowed after each hit | Damage x 1.9 ⚙, Side slow % 30, Side slow (s) 3 |
| Sky Rocks | 1 | | Rock Chunks | — | Damage x 1.4, Meteors 2 |
| Sky Rocks | 2 | | Twin Fall | — | Damage x 2.1, Meteors 3 |
| Sky Rocks | 3 | | Fireball Flurry | — | Damage x 2.6, Meteors 5 |
| Sky Rocks | 4 | A | Endless Rain | A small meteor every 4 s | Damage x 1.25 ⚙, Meteor every (s) 4 |
| Sky Rocks | 4 | B | Scatter Field | Meteors land all along the track | Damage x 1.5 ⚙, Scatter Yes |
| Sky Rocks | 4 | C | Cinder Trail | Small meteors leave a burning streak | Damage x 1.6 ⚙, Burn streak Yes, Burn DPS 20 |
| Sky Rocks | 5 | A | Starfall | 20 meteors across your side every 15 s | Damage x 0.65 ⚙, Starfall every (s) 15 |
| Sky Rocks | 5 | B | Comet Tail | A comet sweeps the whole track once a round | Damage x 1.7, Bombing run Yes, Field strike x 6 ⚙ |
| Sky Rocks | 5 | C | Shooting Stars | Meteors can hit flyers | Damage x 1.95 ⚙, Hits air Yes |
| Aftermath | 1 | | Hot Crater | — | Damage x 1.3, Burn DPS 20 |
| Aftermath | 2 | | Ash Cloud | — | Damage x 1.6, Burn DPS 20, Throw miss % 30, Bite miss % 30 |
| Aftermath | 3 | | Shockwave Ring | — | Damage x 2.4, Burn DPS 30, Throw miss % 30, Bite miss % 30, Knockback (studs) 6 |
| Aftermath | 4 | A | Long Burn | Craters last 8 s, hotter | Crater (s) 8, Burn DPS 45 ⚙ |
| Aftermath | 4 | B | Glass Crater | Craters strip armour | Strips armour Yes, Burn DPS 40 ⚙ |
| Aftermath | 4 | C | Scorch Marks | Dinos crossing a crater take +15% | Crater amp % 15, Burn DPS 40 ⚙ |
| Aftermath | 5 | A | Fire Line | Craters join into one burning strip | Fire line Yes, Burn DPS 60 ⚙ |
| Aftermath | 5 | B | Blinding Dust | Dinos in the ash can't bite or throw | Throw miss % 100, Bite miss % 100, Burn DPS 55 ⚙ |
| Aftermath | 5 | C | New Ice Age | Craters freeze dinos solid for 2 s | Crater freeze (s) 2, Damage x 1.6 ⚙ |

Changed from the proposal: Extinction ×20 → **×2.5** (×20 on every dino scored ~10× the whole
path; ×2.5 makes the T5 ≈ 2× T4 like its siblings — still the biggest single hit in the game);
card "one giant meteor a round, fires itself" kept. Plate Cracker cuts armour on the whole
meteor (a centre-only pierce has no model and reads the same); Long Burn "hotter";
Starfall replaces the 12 s strike (added on top it scored 4×).
**Worth metrics (#314):** **Impact, Sky Rocks** = eDPS (meteors × hits, honest; Extinction:
10 dinos × Extinction x × damage + bunch breaks, once per 50 s; Bombing run as 9h; Meteor every
and Starfall per s; Burn streak = Burn DPS × 3 s × 1 dino per small meteor; Side slow and Biggest
breaks carry damage, blind spots). **Aftermath** = control path (`SUPPORT_PATHS`; option bars
only): eDPS (meteor + crater burn × crater s × 3 crossing dinos ÷ every; × 2 with Fire line) +
120 × H (knockback 6/8 × 5 dinos; Crater freeze s × 3 crossing dinos; per strike) + 0.5 ×
(Throw miss % + Bite miss %) + amp credit (Crater amp % × 120 × 3 s × 3 dinos per strike).
**Director check (rough):** Impact T4 1.95/1.92/1.88× T3, T5 2.2/≈2.1/1.9 (Extinction's
×2.5 is the lever); Sky Rocks T4 2.0/1.95/≈2.0, T5 2.1/≈2.0/2.1; Aftermath: Builder's number
(⚙ Burn DPS per option). **Expected:** best T5 c/e (Extinction or Starfall) ≈ 140–170.
**Studio aids:** `firenow METEOR` (a strike now; Extinction Event / Comet Tail now, ignoring
the trigger).
**T127 (Builder):** `Shared/Meteor` (pure: densest point with boss weight and ties; n-meteor
points; scatter segments; crater lifetimes, joins, amp, freeze once per crater; Extinction
via AutoFire incl. "never on an empty track"; side slow; biggest breaks) + `METEOR BEACON`
block → rows + columns → behaviour (radio mast, red flare, warning ring, falling rock, crater
glow / ice / ash) → value.py. Accept: specs (a 6-dino bunch beats 2 single dinos; a boss counts
3; ground only unless Shooting Stars; Extinction fires on a boss, else at the last spawn, once
per round played, own side only), audit, Config diff, `--options` clean.

#### Volcano Vent (`VENT`) — damage (Magma, Pressure), control (Obsidian)
**Towers row:** Cost 1000 · Damage 30 (eruption hit) · Fire rate 0.05 (one per 20 s) · Targets 4
· Range 20 · Hits air No · Unlock 600 · Key `VENT` · Max HP 200 · **Near track (studs) 8**
(new Towers column; the vent must be placed within 8 studs of the track) · note "Erupts every
20 s: lava floods its stretch of track for 6 s; dinos burn and are shoved aside."
**Tuning block `VOLCANO VENT`:** Flow length (studs) 24 · Flow (s) 6 · Flow burn DPS 8 · Flow shove
(studs/s) 3 · Shove max (studs) 4 · Geyser x 0.3 · Crust (s) 6 · Crust slow % 30 · Lava bomb x
0.5 · Lava bombs 6 · Extra vent x 0.5 · Supervolcano (s) 4 · Ash (s) 5.
**Mechanics (pure `Shared/Vent`):**
1. **Eruption + flow.** The stretch = `Flow length` × `Flow length x` of track centred on the
   track point nearest the vent. Each eruption hits Targets dinos on the stretch for Damage
   (breaks 1) and lays a **lava flow** for `Flow (s)` (blank = Tuning): dinos in it burn Flow
   burn DPS × Damage x × tower level (`Burn breaks`: ticks break 1, Tar Pit's Boiling Pit
   rule) and are **shoved** sideways Flow shove studs/s up to Shove max (not a slow); after the
   flow they walk back to the path (extra time = offset ÷ speed). Bosses aren't shoved.
   Overlapping flows of two vents: strongest only (Tar Pit #189 rule).
2. **Extras:** `Geyser every (s)` (between eruptions a burst hits the stretch for Geyser x ×
   damage); `Extra vents` n (n small vents in a ring erupt in turn between the main eruptions,
   each Extra vent x size); `Lava bombs` (flag: each eruption also throws Lava bombs bombs at
   the biggest dinos in range, Lava bomb x damage, `Size breaks`); `Boss erupt` (flag: erupts
   at once when a boss enters range, once per boss); `Side throw miss %` (new: each eruption,
   every dino on the side misses that share of throws for Ash s); `Supervolcano` (flag;
   AutoFire): once per round played every dino on the side is in a lava flow for Supervolcano s.
   `Slow %` = Rumble (dinos in range while no flow is down). `Knockback (studs)` at the
   eruption (small dinos).
3. **Crust (Obsidian):** after each flow its stretch is **crust** for `Crust (s)`: dinos on it
   slowed `Crust slow %` (Tuning; T1 turns it on: `Crust` flag), `Strips armour` there,
   `Crust DPS` (new; × tower level), `Throw miss %` on it, `Maze (studs)` (new: a dino crossing
   it walks that much further, a detour drawn on the crust), `Freeze flow (s)` (new: when the
   flow ends every dino on it is hard-stopped that long, once per flow). `Wall (s)` (9g Track
   wall, AutoFire) = Obsidian Wall at the stretch's far end. `Aura range %` (9h) and `Throw
   resist %` (new: towers in range take x % less from throws).
**New columns (kind):** Flow (s) max · Flow length x mult · Burn breaks flag · Geyser every (s)
min-positive · Extra vents max · Lava bombs flag · Boss erupt flag · Side throw miss % max ·
Supervolcano flag · Crust flag · Crust DPS max · Maze (studs) max · Freeze flow (s) max · Throw
resist % max. (Reused: Slow %, Knockback, Strips armour, Throw miss %, Wall (s), Aura range %,
Hits air, Pierces armour, Size breaks, Targets x.)

| Path | Tier | Opt | Name | Blurb (card) | Cells (T1–3 cumulative; T4/T5 own step) |
|---|---|---|---|---|---|
| Magma | 1 | | Hot Rock | — | Damage x 1.6 |
| Magma | 2 | | Searing Flow | — | Damage x 3 |
| Magma | 3 | | Lava Lake | — | Damage x 5.4, Flow (s) 10, Burn breaks Yes |
| Magma | 4 | A | White Hot | Lava melts armour | Damage x 1.75 ⚙, Pierces armour Yes |
| Magma | 4 | B | Rivers of Fire | The lava runs 20 studs further | Damage x 1.4 ⚙, Flow length x 1.8 |
| Magma | 4 | C | Ember Rain | Embers hit low flyers | Damage x 1.85 ⚙, Hits air Yes |
| Magma | 5 | A | Supervolcano | Floods the whole track once a round | Damage x 1.5 ⚙, Supervolcano Yes |
| Magma | 5 | B | Lava Bombs | Throws 6 lava bombs at big dinos | Damage x 1.25 ⚙, Lava bombs Yes, Size breaks 2 |
| Magma | 5 | C | Fire Mountain | Eruptions twice as big | Damage x 1 ⚙, Flow length x 2, Targets x 2 |
| Pressure | 1 | | Shorter Fuse | — | Damage x 1.2, Rate x 1.33 |
| Pressure | 2 | | Twin Vents | — | Damage x 1.5, Rate x 2 |
| Pressure | 3 | | Geyser | — | Damage x 2.5, Rate x 2, Geyser every (s) 5 |
| Pressure | 4 | A | Steam Burst | Eruptions knock small dinos back | Damage x 1.75 ⚙, Knockback (studs) 6 |
| Pressure | 4 | B | Rumble | Dinos nearby stumble: −20% speed | Damage x 1.75 ⚙, Slow % 20 |
| Pressure | 4 | C | Pressure Valve | Erupts early when a boss comes | Damage x 1.85 ⚙, Boss erupt Yes |
| Pressure | 5 | A | Ring of Fire | 3 small vents erupt in turn | Damage x 1.2 ⚙, Extra vents 3 |
| Pressure | 5 | B | Old Faithful | Erupts every 4 s, smaller | Damage x 0.8 ⚙, Rate x 2.5 |
| Pressure | 5 | C | Ash Blanket | Ash makes dinos miss 30% of throws | Damage x 1.9 ⚙, Side throw miss % 30 |
| Obsidian | 1 | | Cooling Crust | — | Crust Yes |
| Obsidian | 2 | | Sharp Glass | — | Crust Yes, Strips armour Yes |
| Obsidian | 3 | | Obsidian Wall | — | Crust Yes, Strips armour Yes, Wall (s) 2 |
| Obsidian | 4 | A | Jagged Crust | The crust cuts dinos | Crust DPS 25 ⚙ |
| Obsidian | 4 | B | Black Glass | Nearby towers see 15% further | Aura range % 15 ⚙ |
| Obsidian | 4 | C | Heat Shimmer | Dinos on the crust can't throw | Throw miss % 100, Crust DPS 10 ⚙ |
| Obsidian | 5 | A | Glass Maze | The crust makes dinos walk 12 studs further | Maze (studs) 12 ⚙ |
| Obsidian | 5 | B | Obsidian Armour | Nearby towers take 30% less from throws | Throw resist % 30, Crust DPS 15 ⚙ |
| Obsidian | 5 | C | Frozen Fire | The whole flow hardens: 2 s stop | Freeze flow (s) 2 ⚙ |

Changed: Old Faithful "every 4 s" (Pressure T3 already erupts every 10 s); Heat Shimmer and
Obsidian Armour carry a little crust damage so their dino part clears the bar.
**Worth metrics (#314):** **Magma, Pressure** = eDPS: per eruption (Targets hits + flow burn:
Flow burn × Damage x × 2 dinos in the flow × Flow s × Flow length x + geyser/extra vents/lava
bombs) ÷ every + Supervolcano (10 dinos × burn × Supervolcano s ÷ 50) + Boss erupt (one extra
eruption per boss round ÷ 50); shove, Rumble slow, knockback, ash carry damage (blind spots).
**Obsidian** = control path (option bars only): 120 × H (crust: 2 dinos × Crust slow % ×
Crust s per eruption; Maze ÷ 8 per crossing dino (2 per flow); Freeze flow s × 2 dinos per
eruption; Wall s × 6 dinos per round) + Crust DPS × 2 dinos × Crust s per eruption + aura
credit (Aura range % as rate ÷ 2) + 0.5 × Throw miss % + 0.3 × Throw resist % (points as eq).
**Director check (rough):** Magma T4 1.98/≈1.9/1.98, T5 ≈2.0/≈1.9/2.0; Pressure T4 1.75 +
blind spots ×3 (equal by construction), T5 2.1/2.0/1.9; Obsidian: the Builder's number.
**Studio aids:** `firenow VENT` (an eruption now; Supervolcano now).
**T128 (Builder):** `Shared/Vent` (pure: stretch from the nearest track point, flow timing,
shove + rejoin, crust after flow, maze detour, freeze at flow end once, overlap strongest-only,
boss erupt once per boss, AutoFire Supervolcano) + `Near track` placement rule in
`Shared/Placement` (+ ghost) + `VOLCANO VENT` block → rows + columns → behaviour (smoking
crack, lava flow decal, crust, cone for Fire Mountain) → value.py. Accept as T127 + a placement
spec (8 studs from the track yes, 12 no).
**T128b — 9i release + balance (#312):** as T124b (both damage towers: best T5 ≤ 1.25 × M,
round-20 bar). **Tester Run 9i:** common rule 10, plus: a meteor lands on the biggest bunch
after its warning ring; Extinction Event fires itself once a round (and on a boss); lava floods
the stretch and shoves dinos; crust slows; Frozen Fire stops the flow's dinos 2 s (a boss 1 s).

**9j — Ranger Station** (alone: the heaviest; T129 rules + sheet + tower, T130 posts UI +
value.py, T130b release). TOWERS_LATER's "5 at Ranger Corps" → "5 at Ranger Troop" (Round 19).

#### Ranger Station (`RANGER`) — damage (Riflemen), traps (Trackers), tougher rangers (Wardens)
**Towers row:** Cost 900 · Damage 8 (per ranger shot) · Fire rate 1.2 · Targets 1 · Range 30 (how
far from the cabin a post may be) · Hits air No · Unlock 500 · Key `RANGER` · Max HP 200 (the
cabin) · note "Trains rangers who stand at posts on the track and shoot; bitten too much, they
go back to the cabin to patch up."
**Tuning block `RANGER STATION`:** Ranger HP 100 · Ranger speed 16 · Ranger reach 14 · Retreat HP
share 0.3 · Ranger respawn (s) 10 · Cabin heal (HP/s) 20 · Leash x 1 · Max posts 3 · Trap every
(s) 8 · Trap slow % 40 · Trap slow (s) 2 · Trap reach (studs) 3 · Trap line traps 6 · Heavy x 3 ·
Legend x 3 · Legend HP x 3 · Legend dart every (s) 12 · Legend dart mark % 25 · Legend dart (s)
8 · Jeep speed 20 · Ranger guard reach (studs) 10.
**Mechanics (pure `Shared/Ranger`, on `Shared/Walker`'s `post` state):**
1. **Posts.** A station has up to Max posts **posts** (track points within its Range). Each
   ranger walks from the cabin to its post (rangers share posts round-robin; Ranger Troop's 5
   stand in formation on 3), shoots dinos within Ranger reach (ground only unless `Hits air`;
   furthest along first), never chases. Dinos walking past bite it (the walker bite-back
   rule; no trample at a post — they bite instead); at Retreat HP share it walks home, heals,
   returns; at 0 HP `down` for Ranger respawn × `Walker respawn x`. `Walker regen` (new): HP/s
   at the post.
2. **Squad options:** `Heavy ranger` (flag): the first ranger shoots × Heavy x, breaks 3.
   `Legend` (flag): one ranger is the Legend (× Legend x damage, × Legend HP x HP, its own
   Tracking Dart every Legend dart s: its target marked Legend dart mark % for Legend dart s,
   Tracker dart rules). `Jeep` (flag): the squad rides a jeep that drives the side's track
   there and back at Jeep speed (shooting in reach as it passes; dinos can't bite a moving
   jeep; posts unused).
3. **Traps** (`Trap` flag from Trackers T1): each post has a trap at its track point: the
   first ground dino within Trap reach every `Trap every (s)` (blank = Tuning) is slowed Trap
   slow % for Trap slow s, plus `Trap stun (s)` (new; hard stop, not bosses), `Knockback`
   (not bosses). `Trap line` (flag; at each round played's start): Trap line traps one-shot
   traps spread evenly along the side's track, same effect. `Decoy (s)` (new): a dino entering
   a ranger's reach stops that long, once per dino per post. `Boss hold (s)` (9g): the first
   boss within a ranger's reach is netted (hard stop, full length) once per boss.
   `Take-down mark %` (9g) on ranger take-downs.
4. **Wardens:** `Walker HP x`, `Walker resist %`, `Heals between rounds`, `Walker respawn x`
   (9g); `Post aura` (new flag: the station's `Aura HP %` applies to towers within Ranger guard reach
   of a post); `Boss round guard` (new flag: while a boss is alive on the side, rangers can't
   drop below 1 HP); `Guard` (9g: rangers stand beside towers within Range instead of posts and
   take the bites aimed at them); `Rescue beacon (respawn x)` (Hospital's column): own side's
   hunters respawn at the cabin in that × the time (battles: own camp only).
**New columns (kind):** Walker regen max · Heavy ranger flag · Legend flag · Jeep flag · Trap
flag · Trap every (s) min-positive · Trap stun (s) max · Trap line flag · Decoy (s) max · Post
aura flag · Boss round guard flag. (Reused: Walkers, Walker HP x / resist % / respawn x, Heals
between rounds, Guard, Boss hold (s), Hits air, Take-down mark %, Knockback, Pierces armour,
Size breaks, Aura HP %, Rescue beacon (respawn x).)

| Path | Tier | Opt | Name | Blurb (card) | Cells (T1–3 cumulative; T4/T5 own step) |
|---|---|---|---|---|---|
| Riflemen | 1 | | Recruit | — | Walkers 2 |
| Riflemen | 2 | | Sharpshooter | — | Walkers 2, Damage x 1.8, Range x 1.2 |
| Riflemen | 3 | | Squad | — | Walkers 3, Damage x 2.8, Range x 1.2 |
| Riflemen | 4 | A | Elite Squad | Rangers shoot through armour | Damage x 1.75 ⚙, Pierces armour Yes |
| Riflemen | 4 | B | Heavy Rifle | One ranger gets a heavy rifle: ×3, breaks 3 | Damage x 1.1 ⚙, Heavy ranger Yes |
| Riflemen | 4 | C | Flare Rounds | Rangers can hit low flyers | Damage x 1.9 ⚙, Hits air Yes |
| Riflemen | 5 | A | **Ranger Troop** | 5 rangers in formation | Damage x 1.2 ⚙, Walkers 5 |
| Riflemen | 5 | B | Legend Ranger | One hero-strong ranger with its own dart | Damage x 1.2 ⚙, Legend Yes |
| Riflemen | 5 | C | Patrol Jeep | Rangers drive the track, firing | Damage x 1.4 ⚙, Jeep Yes |
| Trackers | 1 | | Snare Kit | — | Trap Yes |
| Trackers | 2 | | Bait | — | Trap Yes, Trap every (s) 5, Damage x 1.3 |
| Trackers | 3 | | Snap Traps | — | Trap Yes, Trap every (s) 5, Damage x 1.6, Trap stun (s) 0.6, Walkers 2 |
| Trackers | 4 | A | Pit Traps | Traps hold a dino 1.5 s | Trap stun (s) 1.5 ⚙ |
| Trackers | 4 | B | Decoy Calls | Dinos stop to fight rangers | Decoy (s) 1 ⚙ |
| Trackers | 4 | C | Tripwire | Traps knock dinos 4 studs back | Knockback (studs) 4 ⚙ |
| Trackers | 5 | A | Master Trapper | Traps along your whole track each round | Trap line Yes ⚙ (Tuning Trap line traps) |
| Trackers | 5 | B | Net Launchers | Rangers net a boss for 2 s | Boss hold (s) 2, Damage x 1.3 ⚙ |
| Trackers | 5 | C | Head Ranger | Ranger take-downs mark nearby dinos +20% | Take-down mark % 20, Damage x 1.2 ⚙ |
| Wardens | 1 | | Leather Coats | — | Damage x 1.3, Walker HP x 1.5 |
| Wardens | 2 | | Medic Bag | — | Walkers 2, Damage x 1.5, Walker HP x 1.5, Walker regen 5 |
| Wardens | 3 | | Shield Wall | — | Walkers 2, Damage x 2, Walker HP x 1.5, Walker regen 5, Walker resist % 40 |
| Wardens | 4 | A | Field Rations | Rangers heal fully between rounds | Heals between rounds Yes, Walker HP x 1.3 ⚙ |
| Wardens | 4 | B | Rally Point | Rangers come back 2× faster | Walker respawn x 0.5 ⚙ |
| Wardens | 4 | C | Sandbags | Towers near a post get 10% more HP | Post aura Yes, Aura HP % 10 ⚙ |
| Wardens | 5 | A | Hold the Line | Rangers can't fall while a boss is out | Boss round guard Yes ⚙ (Damage x) |
| Wardens | 5 | B | Bodyguards | Rangers take bites for towers | Guard Yes ⚙ (Walker HP x) |
| Wardens | 5 | C | Hunter's Lodge | Hunters come back twice as fast | Rescue beacon (respawn x) 0.5 ⚙ |

Changed: Heavy Rifle is one heavy ranger **in** the squad (a "one ranger" T4 broke every T5
that adds rangers, #276); Pit Traps 1.5 s (Snap Traps holds 0.6 s first); Hold the Line "while
a boss is out" (a "boss round" isn't a game state).
**Worth metrics (#314):** **Riflemen** = walker eDPS (uptime at a post 0.7; Jeep: coverage ×
1.3, no bite downtime) + Heavy (one ranger × Heavy x, breaks 3) + Legend (× Legend x + dart: 25
% mark × 8 s ÷ 12 s on its target × 120 / its own share) + aura. **Trackers** = control (option
bars only): squad eDPS + 120 × H, H per post per s = (Trap slow % /100 × Trap slow s + Trap stun
s + Knockback ÷ 8) ÷ Trap every + Decoy s × 2 dinos per post per 10 s + Trap line: 6 × effect
÷ 50 + net: Boss hold s × 1 boss round ÷ 50 (bosses full) + mark credit (Take-down mark % ×
120 × 3 s × 1.5 dinos per ranger take-down). **Wardens** = squad eDPS × uptime (0.7; + 0.1
with Heals between rounds; respawn x 0.5 → + 0.08; Boss round guard → + 0.08) + 0.5 × points
(Aura HP % × posts; Guard: rangers × Walker HP x × 100 HP ÷ 100 soaked; Hunter's Lodge 20 × (2
− respawn x)).
**Director check (rough):** Riflemen T4 1.98/1.85/2.04, T5 2.0/2.0/≈2.1 (Jeep's coverage is the
Builder's number). Trackers / Wardens: the Builder's numbers (⚙ levers listed).
**Studio aids:** `walkers`, `firenow RANGER` (Trap line now; the Legend's dart now).
**T129 (Builder):** `Shared/Ranger` on `Shared/Walker` (`post` state, round-robin posts,
formation, Heavy/Legend/Jeep, traps per post, trap line at round start, decoy once per dino per
post, boss net once per boss, boss-out guard, guard by towers, cabin respawn for own hunters
only) + `RANGER STATION` block → rows + columns → behaviour + look (cabin; rangers in khaki with
the camp colour; jeep). Default posts = the nearest track points (so it works before T130).
**T130 (Builder):** posts UI — after placing a station, a post ghost on the track within Range
(up to Max posts, one per ranger); "Move posts" in the tower panel (Back + X, no trap, #279);
server validates (on the track, within Range, not on a Tar Pit pool); stand-ins use default
posts; value.py metrics. Accept: specs + layout spec at 3 window sizes.
**T130b — 9j release + balance (#312):** as T124b. **Tester Run 9j:** common rule 10, plus: place
posts and move one; a ranger bitten low walks home, heals and returns; traps slow/stun the first
dino; Net Launchers nets a boss once; Patrol Jeep drives the track; Hunter's Lodge halves the
Tester's respawn in co-op and only for its own camp in Camp Clash.

**Every new-tower batch, Tester:** common rule 10 above (the Tester is the raider, #310).
**Every new-tower task, docs:** the Builder adds the tower's `UPGRADES.md` section (paths, tier
names, the A/B/C table with Blurbs) in the same commit as its rows, so the audit's option-table
check covers it; `ARCHITECTURE.md` §4 gains `Walkers` (T124).

**9k — balance pass.** `value.py --options` + `--battle`, `threat.py`, per-hero parity;
`audit.py --strict` with full A/B/C everywhere; co-op ~34 min and battle clocks unchanged
(a new tower must matter by round ~20; the seven re-checked together on the 9g–9j bars, the
#313 exchange rates and stand-ins reviewed against Runs 9g–9j; walker count at 10 players).
**T131** tune, **T132** fixes from Run 9. Tester Run 9:
a full co-op match on Normal with new towers + a casual Camp Clash with stand-ins.

**9l — docs + recap.** **T133** `UPGRADES.md` / `HEROES.md` option tables complete, Mechanics
table, `ARCHITECTURE.md` (Upgrades/OptionPick, sheet columns, phase table), `CLAUDE.md` status,
`VISION.md` if needed; Director writes `RECAP.md` "Phase 9" (what to playtest first, what
needs Jovan: multi-client Raider tests, feel of 9 builds per path).

---

# Plan — Phase 8 batch 2: match length and joiners (Director, 2026-10-09)

Jovan answered ask 3 and more on 2026-10-09 (verbatim in `DIRECTION.md` "Match length,
joiners, strength gap"). Design calls: `DECISIONS.md` #249–#257. **This batch replaces T98
and comes before T97 (the 4×-Amber picks).** Phase 7/8 rules hold (one task = one commit,
pushed; check/export/test green; Config diff after any sheet change; openpyxl, assert each
old value or empty cell first; append Tuning rows, never insert; pure rules first; co-op
specs re-run every task; no publish, no DataStore writes from an agent).

**Status (2026-10-09): 2a + 2b done (29720d9, 4548d14, e9aab47, 76d1e04 T103, 717942e T104; 662 specs; review #263–#264). Next: T105 done (e7f8cb1), T106 done (Dino Round 18), T103b running → T106b → Tester Run 7 (the Run 6 steps below; joiner step via `latestandin`).**
**Status (2026-10-12): Run 7 done (27 pass, F8 major, N13, N14). Rulings #266–#270. Next: T103c + T105b (one Builder commit, below) → Tester Run 7b → batch 2 signed off → T97.**
**Status (2026-10-13): BATCH 2 DONE and signed off (#271). T103c + T105b at 3664152 (682 specs); Run 7b 9 pass / 0 fail. N15 (log wording) accepted, rides the next `Battle` commit (#272). Recap: `RECAP.md` "Phase 8 batch 2". Next: T97 — Jovan picks from the refreshed `TOWERS_LATER.md` (#273), then 🦖 names.**

## Target timelines (model: `Round pace` 0.4, 30 s build, 5 s breaks; Normal)
| Mode | Rounds played | Round 40 reached at | After round 40 | Hard cap |
|---|---|---|---|---|
| Solo / co-op PvE | all 40 | ~33.6 min (30.1 min of rounds) | victory | none in game; **model bar ≤ 35 min** (Jovan's 30–40) |
| Casual Camp Clash | 1, 4, 7 … 40 (14) | ~12 min | Final Stampede (~3 repeats) | **15:00 clock** → tie-break |
| Casual Bone Rush | 1, 4, 7 … 40 (14) | ~12 min | match ends | 15:00 clock (backstop) |
| Ranked Camp Clash | 2, 4 … 40 (20) | ~17.5 min | Final Stampede (~13 repeats fit, HP ×18) | **30:00 clock** → tie-break |
| Ranked Bone Rush | 2, 4 … 40 (20) | ~17.5 min | match ends | 30:00 clock (backstop) |

How (#250–#252): every played round is co-op's round, time-compressed: spawn gap × pace,
dino HP × `(pace·S + W) / (S + W)` (S = enemies × spawn gap, W = 14 ÷ difficulty speed),
kill cash from the **unpaced** HP. Required DPS and cash per round are unchanged, so the
Balance Check, affordability and the T91b battle bars stay true. Battles skip rounds by a
step and pay each skipped round's expected income at the next played round's start, so
cumulative cash at round R matches co-op's. Lockstep cap `B143` 120 → 60.

## Tie-break chain (#253; every queue; no result is ever a tie)
- **Camp Clash** (fell in the same step, or standing at the clock): standing/fell later →
  more Fence left → more Bones (camp) → more damage dealt to own dinos (capped at each
  dino's HP) → lower total round-clear time → coin flip seeded by matchId.
- **Bone Rush:** final Bones → survived longer → more Fence → more damage dealt → lower
  total round-clear time → seeded coin flip (replaces "order given").
- Results line names the deciding step. At the clock: the match ends at once; everyone still
  standing is ranked by the chain. Stakes' tie-split path becomes unreachable (keep, spec it).

## Joiners (#254)
- **Ranked:** seats lock when Building starts; joiners wait (existing waiting banner);
  leavers aren't refilled. Never staked/ranked/escrowed late.
- **Casual battles:** seated until the end of round 30 (`Late join last round`). Camp
  Clash → the standing camp with fewest hunters (then lower Fence, then lower side). Bone
  Rush → a spare plot (`Bone Rush spare plots` 2, within 10), full Fence, Bones = the lowest
  Bones among players still standing.
- **Co-op:** drop-in stays (Main `PlayerAdded` → `joinMatch`), but the flat 200 becomes the
  catch-up when larger.
- **Catch-up cash** = `Late join cash x` 1.1 × the expected income of one more hunter for
  every round played before the join (difficulty, side scale, pace; the same function as
  skipped-round income). Dino scale grows from the next round, never mid-round.

## Strength gap (#255): intended. No parity change; the edge stays a value.py watch line (#235).

## New Tuning rows (append from row 172; assert each A/B empty; B143 assert 120)
| Row | Name | Seed | Note |
|---|---|---|---|
| 143 | Battle round time | 120 → **60** | ≥ longest paced Normal round (56 s) |
| 172 | Round pace | 0.4 | spawn gap × and HP pace factor, every mode |
| 173 | Track walk seconds | 14 | the Rounds sheet's "+14"; pace formula + models |
| 174 | Casual round step | 3 | rounds 1, 4 … 40 |
| 175 | Ranked round step | 2 | rounds 2, 4 … 40 |
| 176 | Casual match cap | 900 | seconds from Building |
| 177 | Ranked match cap | 1800 | includes Final Stampede |
| 178 | Clock warning | 60 | seconds before the cap |
| 179 | Late join cash x | 1.1 | × one hunter's missed expected income |
| 180 | Late join last round | 30 | casual battles |
| 181 | Bone Rush spare plots | 2 | within Battle max players |
| 182 | Co-op length max | 2100 | model bar only (value.py/audit), not a game clock |

## Builder batches
| Batch | Tasks | Needs Jovan? |
|---|---|---|
| 2a | T100 `Shared/Pace` (pure), T101 sheet + exporter/audit + models, T102 tie-break chain (pure) | No |
| 2b | T103 pace + round lists in play, T104 match clock + tie-break wiring + N7 | No |
| 2c | T105 joiners, T106 🦖 strings review + fixes; Tester Run 6 | Multi-client join only |

### T100 — `Shared/Pace` (pure, headless specs)
`hpX(round, difficulty)`, `spawnGap(round)`, `playedRounds(modeKey, competitive)` (co-op =
1..40; battles = first..40 by step, first = 40 − step·⌊39/step⌋), `isPlayed(round, …)`,
`expectedIncome(round, hunters, difficulty)` (kill cash from unpaced EHP × side scale +
round bonus × cash mult; same maths as value.py's income), `skippedIncome(fromRound,
toRound, …)`, `catchUpCash(roundReached, …)` (× `Late join cash x`, ≥ `StartingCashPerExtraPlayer`),
`matchCap(modeKey, competitive)` (nil for co-op), `clockWarning(elapsed, cap)`.
- **Accept:** specs: hpX(r) × paced length = unpaced EHP ÷ unpaced length × paced length
  (required DPS equal to 1e-9) for all 40 rounds × 4 difficulties; casual list = 14 rounds
  ending 40, Ranked = 20 ending 40, co-op = 40; Σ played income + Σ skipped income = co-op
  cumulative income to round 40; catchUpCash monotonic in round, 0 joiner bonus at round 1
  except the floor; matchCap nil for co-op.

### T101 — Sheet + exporter/audit + models (Builder; openpyxl)
Rows above (assert empty / B143 = 120). Exporter checks: 0 < pace ≤ 1; steps ≥ 1 and the
list ends at 40; casual cap ≤ 900; Ranked cap ≤ 1800; warning < both caps; late-join round
< 40; spare plots ≥ 0; B143 ≥ the longest paced round on Normal and Chaos.
**value.py:** `--pacing` adds paced minutes per difficulty with breaks and fails if Normal
solo > `Co-op length max`; affordability columns must be unchanged (diff before/after);
Amber/h line becomes a watch line (#256); hero/ability lines use paced round lengths.
`--battle` per mode uses its played-round list + skipped income: prints round-40 time,
Stampede repeats that fit before the cap, and keeps the T91b bars (typical: 2 camps fall ≥
20, 3 camps / Bone Rush ≥ 30; competent reaches 40) per queue; a peak-live-dinos estimate per
mode at max players vs `MaxConcurrentEnemies` (report; a fail goes to the Director).
`--edge` parity bar re-run with paced cooldown uses. **threat.py** re-run with paced lengths.
- **Accept:** check/export/test green; Config diff = rows 143, 172–182 only; value.py
  prints co-op Normal ≤ 35 min, casual round 40 ≤ 12.5 min, Ranked ≤ 18 min; affordability
  unchanged; any failing parity/threat/live-cap bar is **reported, not fixed** (Director
  picks buff cells, #250).

### T102 — Tie-break chain (pure; `BattleRules`)
`teamResult` gains per-side `fence`, `damage`, `clearTime` and a `seed`; `royaleResult`
gains `damage`, `clearTime`, `seed`; new `atClock(...)` ends with everyone standing ranked by
the chain; every result returns `decidedBy` (key for the results line). `tie` is always false.
- **Accept:** specs for each step of both chains deciding alone; same inputs + same seed =
  same result; random fuzz (1,000 cases) never returns a tie; co-op specs unchanged.

### Batch 2a review — amendments for 2b/2c (#258–#262)
1. **Live cap (#258): pace by fewer, tougher dinos, not denser spawns.** Spawn gaps stay as
   the sheet has them. Each species' count × `Round pace` (round half up, min 1 if it was ≥ 1;
   bosses keep their count); battles also × new lever **`Battle crowd x` 0.75** (Tuning row
   183, assert empty). Each dino's HP × (unpaced round EHP × hpX) ÷ (paced round EHP before
   the HP factor), so the round's EHP and required DPS are unchanged; kill cash per dino × the
   same count ratio, so cash per round is unchanged. `MaxConcurrentEnemies` stays 130.
   - T103 accept adds: value.py peak live at max players ≤ 130 in co-op, Camp Clash and Bone
     Rush (targets ≈ co-op 113, Camp Clash ~99, Bone Rush ~128); co-op 33.6 / casual 12.1 /
     Ranked 17.4 min timelines within ±1 min; T91b bars met; round EHP spec exact per round.
   - If Bone Rush is still > 130: Director picks `Battle crowd x` (report, don't guess).
2. **Ability tempo (#259): new lever `Ability tempo` 2.0** (row 184): hero ability cooldowns
   ÷ tempo (on top of `abilityCooldownMult`) and the Field Hospital's heal rate × tempo; the
   Triage Kit follows its cooldown. Tower timers (Eruption, Tow Line, Power Grid, Judgement
   Bolt) are DPS already: unchanged. Exporter: 1 ≤ tempo ≤ 1 ÷ pace. Accept: value.py
   Tracking Dart uses at r20 ≥ 2.3 (was 2.6), Triage ≥ 120 HP/round (was 137), Hospital heal
   per round within ±15% of unpaced; parity bar (#235) and threat.py re-run green; the
   competitive edge stays a watch line.
3. **B143 60 before pace is wired (#260):** fine; T103 is next and nobody playtests between.
4. **Seed (#261):** T104 always passes `matchId` as the seed plus per-side fence, damage and
   clearTime; `BattleRules` errors on a nil seed (spec). Until then no Studio run.
5. **Late-joiner start cash (#262, revises #254):** a joiner brings what they'd have brought at
   round 1 **plus** catch-up: own plot (Bone Rush) = the 1-hunter starting cash
   (`BattleFlow.startingCash`) + 1.1 × missed income; a camp/co-op joiner =
   `StartingCashPerExtraPlayer` 200 + 1.1 × missed income (no longer a floor). T105 changes
   `Pace.catchUpCash` + its spec.

### T103 — Pace and round lists in play (server: Waves/Enemies/Battle)
Spawn gap × pace and HP × hpX in co-op and battles; kill cash from unpaced HP; battles run
`playedRounds` and pay `skippedIncome` at each played round's start (feed line "+N supplies
for rounds X–Y"); HUD shows the real round number ("Round 22 / 40"); hero levels/XP follow the
real round; "Start at round N" (Studio) snaps to the next played round.
- **Accept:** headless specs for the battle round driver with a fake clock (played rounds,
  skipped income paid once, B143 60); co-op round-1 spawn timing spec updated to the paced
  gap; kill cash per dino unchanged (spec).

### T104 — Match clock, tie-break wiring, N7
Clock from Building (`matchCap`), HUD clock, warning banner at cap − 60 s, end at the cap via
`atClock`; per-side damage (capped) and clear-time counters feed T102; results show
`decidedBy`. N7: "Stand-ins hold" can be released mid-battle (Studio-only).
- **Accept:** specs: cap 900/1800 picked by queue, none in co-op; a clock end settles stakes,
  Trophies and payouts exactly like a normal end (no tie path); Studio-only options refused
  when `isStudio = false`.

### T105 — Joiners
Ranked: keep the lock + waiting banner (spec). Casual: seat via a pure
`BattleFlow.lateSeat(...)` (fewest hunters → lower Fence → lower side; Bone Rush spare plot +
Bones floor; closed after round 30); catch-up cash on seat; dino scale from the next round.
Co-op: catch-up replaces the flat 200 when larger. Late joiners never staked/ranked.
Studio-only "Late stand-in joins now" host option so one MCP client can test the path.
- **Accept:** pure specs for lateSeat and the Bones floor; Ranked join refused after
  Building; a late joiner's profile never gets an escrow; co-op specs green.

### T103b (#264) — Bone Rush live-cap margin (one cell; after T105)
`Battle crowd x` 0.75 → **0.7** (assert 0.75). Accept: Config diff = that line; value.py peaks
at max players Bone Rush ≤ 122, Camp Clash ≤ 92; timelines ±0.2 min; T91b bars and
affordability unchanged.

### T106 🦖 — Dino review of new strings, then fixes
Every batch-2 string (T103/T104 list in #263: supplies lines, "Round 22 / 40", "Final Stampede N", "Clock m:ss", "One minute left on the clock!", "Time's up!", "Last camp standing", the six "Decided by …" lines, plus T105's), clock label, last-minute banner, "Decided by …" lines (six per mode), coin-flip wording,
supplies feed line, late-join toast ("Joined Red Camp at round 17: +N cash to catch up"),
Ranked waiting text. Player text says **Bones**/take-downs.

### T106b (#265) — Dino Round 18 string fixes (one small Builder commit, before Tester Run 7)
Exact strings (display only; keys unchanged):
- `BattleFlow.luau:124` "+N supplies for rounds X–Y" → **"+N cash for skipped rounds X–Y"**;
  single round → **"+N cash for skipped round X"**.
- `PanelRules.luau:188` → **"Decided by a coin flip"**.
- `PanelRules.luau:183` → **"Decided by most Fence left"**.
- `Hud.luau:386` "Clock 14:00" → **"Time left 14:00"** (format "Time left m:ss").
- `BattleFlow.luau:327` literal "Bones" → `{Theme.Bones}`-driven text.
- **Accept:** specs/strings updated; check/export/test green; no Config diff.

### T103c + T105b (#266–#269) — Run 7 fixes (ONE Builder commit), then Tester Run 7b — DONE (3664152; Run 7b 9/9 pass, 3d27f32)
**T103c (F8 proof, N13 drain):**
1. Spec (`SpawnQueue`): 10 sides, cap 130, side 1 at 13 live with 50 queued; every other
   side with 1 queued takes it at once; side 1 takes nothing; total never > 130. Same with
   `setSeated(10)` of 12 sides.
2. `Enemies`: each dino model gets attribute `Side` (number) at spawn. Battle's "Round N over"
   log adds per-side peaks (`peak by side 13/12/…`, share 13) and also prints at the match
   end when a match ends mid-round.
3. `tools/value.py` live-cap section: a per-side line, keeps-up peak per side vs
   `floor(130 / seats)` (Bone Rush 10 seats: ~12.1 vs 13), `ok`/`MISS`.
4. New Tuning row 185 `Battle Fence drain` = 4 (assert A185/B185 empty; append, export,
   exporter guard 1 ≤ x ≤ 40). Pure rule (e.g. `BattleRules.drain(pending, fence, rate, dt)`
   → loss, pending) + per-side pending in Battle: a leak adds `Battle.leakCost(...)` to
   pending; each Heartbeat Fence −= min(pending, 4 × dt); side out → pending 0; flush all
   pending before every match-end ranking (clock, round 40, last camp standing, Final
   Stampede end). Battles only; co-op leak path untouched. Stand-ins hold still caps at 1.
- **Accept:** check/export/test green; Config diff = row 185 only; specs: two sides each get
  60 pending at t=0 with Fence 40 and 10 → fall at 2.5 s and 10 s (1st = later); total
  loss = sum of leaks exactly; out side's pending cleared; clock flush ranks after the
  loss; co-op leak specs unchanged.

**T105b (joiner Fence, N14):**
5. `BattleFlow.lateSeat` (Bone Rush spare plot): Fence = min(full, highest Fence among
   players still standing). Camp Clash unchanged.
6. `Hud.client.luau` `feedList.Position` `UDim2.new(1, -16, 0, 64)` → `UDim2.new(1, -16, 0, 88)`.
- **Accept:** lateSeat specs (standing Fences 40/22/9 → 40; 22/9 → 22); Studio probe at
  1280×720 and 1920×1080: BattleFeed's AbsolutePosition/Size box doesn't intersect the XP
  row's, nor any other top-right HUD element.

**Tester Run 7b (short):** (a) Bone Rush casual, Seats 10, stand-ins, Start at round 13
(stand-ins hold it), own plot undefended: every 1 s log `Enemies` children by `Side` and
each side's queue; pass = own side ≤ 13, every other side's spawn times match its paced gap
(±0.5 s, no waits), total ≤ 130; then rerun R7-25 (round 37) and report per-side peaks
(130 total there is OK if every side is at its share). (b) Start at round 31 Bone Rush: falls
spread over seconds (log fall times), results line; Fence HUD drains, no jump. (c) Late
stand-in into Bone Rush: its Fence = best standing Fence; toast no longer over the XP text
(screenshot). (d) Co-op Normal round 1–2 leaks cost as before. (e) Console clean.

### Tester Run 6 (after 2c)
Studio, stand-ins: (1) co-op Normal solo rounds 1–3 with a timer: paced spawn gaps, kill
cash unchanged, no new errors; (2) casual Camp Clash with "Start at round 37" + "Stand-ins
hold": rounds jump 37 → 40, supplies line, Final Stampede, released hold → ends, results
"Decided by …"; (3) casual clock: Start at round 40 + hold, let the 15:00 clock run out
(or a Studio-only short-cap option if T104 adds one), warning banner at 14:00, clock end
ranks by Fence; (4) Bone Rush step list and the end at 40; (5) "Late stand-in joins now"
in casual (seated, catch-up cash toast) and refused in Ranked/Practice; (6) No-trap rule
on the new banners. **Needs Jovan:** a real second client joining late (Clients and
Servers), a full-length timed match of each mode for feel, Ranked stakes/Trophies on the
published place (T95).

# Plan — Phase 8: ready to publish (Director, 2026-10-08) — batch 1 DONE; the rest needs Jovan

Jovan (2026-10-06): **"begin phase 8 when all loose ends on phase 7 are done"**. Phase 7's
loose ends: T86b re-check (Tester Run 4, running), then only the items that need Jovan
(Clients and Servers script) or a published place remain (`RECAP.md` "Phase 7"). The rounds
1–4 Studio playtest (T31/T38/T60/T70) was covered by PLAYTEST Runs 1–2 and its fails (F1–F4)
are fixed. Design calls: `DECISIONS.md` #237–#243.

**Status (2026-10-08, batch 1 done): T88–T93 + T91b + F7 built (87cf75c, 6209a88, b76c179,
8e07fdf, 72495d3, e2ba805, 60accd3, b1a090c; 619 specs). Studio: Run 4 (T86b) and Run 5
(23 pass, 0 fail). Open for agents: N7 (Studio-only: "Stand-ins hold" can be released
mid-battle, so a held battle can end; Builder now). Recap: `RECAP.md` "Phase 8" (T99 done,
#246–#248). Everything else needs Jovan: asks 1–4 below, plus the battle length (ask 3 now
reads: "rounds are 120 s and a full battle ~60–80 min: too long?"). Earlier: proposed.**
**Update 2026-10-09: ask 3 answered → "Phase 8 batch 2 — match length and joiners"
(T100–T106) at the top of this file runs next, then T97 (ask 1, #257). The publish batch
below (T94/T95) keeps its own number and waits on Jovan as before.**

## Ask Jovan first (Phase 8 can't finish without these)
1. **The 4×-Amber towers (`TOWERS_LATER.md` "What Jovan needs to pick"):** (a) which of
   Meteor Beacon / Amber Resin Cannon / Ranger Station / Spotter Blimp, and is 400–600 Amber
   right; (b) one option per tier-4 and tier-5 slot; (c) Extinction Event button or automatic;
   (d) Amber Rush in or out; (e) Ranger Station worth its cost or swap for a simpler tower.
2. **Publish the place (privately is fine)?** Saving, Ranked stakes, saved Trophies and both
   world boards only work published. Batch 2 is a checklist he follows (~15 min).
3. **ANSWERED 2026-10-09 (#249): casual ≤ 15 min, Ranked ≤ 30 min with overtime, co-op ≤
   30–40 min, no ties in Ranked, late-joiner rules → "Phase 8 batch 2" at the top; T98 is
   replaced by it.** Was: **Battle length (revised by T91b, #245):** the cause was the 60 s round cap (Normal rounds
   run 90–119 s), not Fence or density. Rounds are now 120 s: a typical camp lasts to round
   21 (2 camps) / 32 (3 camps, Bone Rush), a competent one sees Final Stampede, and a full
   battle runs ~60–80 min. Too long? (Levers if so: a lower round cap, or a shorter battle
   that ends earlier than round 40.)
4. **A lobby place with cross-server matchmaking** (#219 kept it out of phase 7): build it
   after publishing (batch 3), or stay one-server for now?

## Scope options
| Option | What | For | Against |
|---|---|---|---|
| **A — Ready to publish (recommended)** | Publish checklist + live-only hardening (DataStore, escrow, boards), multi-client test support, battle pacing + open balance items; then a private publish and a published smoke test; the lobby place after that; the 4×-Amber towers as the content batch once he picks | Ranked, stakes, Trophies and the world boards are built but can't be real until published. Most of batch 1 needs no Jovan | Little new to play until the towers land |
| B — Content first | The 4×-Amber towers now, publishing later | New toys | Blocked on his picks today; adds more untestable-unpublished surface |
| C — Full online in one go | Publish + lobby place + Teleport/MemoryStore matchmaking by Trophies + analytics | The "real game" end state | Biggest, and the lobby can't be tested before a publish; VISION never mentions monetisation or analytics, so those stay out |

**Recommendation: A.** It turns phase 7 from "Practice Hunt only" into real Ranked, matches
DIRECTION ("tested in Studio whenever possible", "honest about what was verified"), and every
batch-1 task is testable now. Monetisation and analytics are not in VISION: out of scope
unless Jovan asks.

## Batches (option A)
| Batch | Tasks | Needs Jovan? |
|---|---|---|
| 1 | **DONE.** T88, T89, T90, T91, T93, T92 (final), T91b (6209a88, b76c179, 8e07fdf, 72495d3, e2ba805, 60accd3, b1a090c; F7 87cf75c; 619 specs); Tester Run 5 23 pass / 0 fail. Open: N7 (Studio test aid, Builder) | No |
| 2 | T94 Jovan's private publish, T95 published smoke (saves, Ranked stake/escrow/refund, Trophies, world boards, 2 real clients) | Yes (ask 2) |
| 3 | T96 lobby place + TeleportService + MemoryStore queue by Trophies (reuses `Shared/Matchmaking`) | Yes (ask 4, after batch 2) |
| content | T97 the 4×-Amber towers, in the round-4 tower pattern | Yes (ask 1) |
| — | T98 battle difficulty change, if ask 3 says so | Yes (ask 3) |
| — | T99 Director: phase 8 docs + recap — **DONE** (batch 1 part; `RECAP.md` "Phase 8") | No |

Round 1–4 and phase 7 rules hold (one task = one commit, pushed; check/export/test green;
Config diff after any sheet change; openpyxl, assert cells; co-op must not change; pure
rules first; never publish or write DataStores from an agent).

### T88 — Docs: multi-client testing + publish checklist (Builder, `SETUP.md`) — DONE (6209a88)
- **Multi-client** (left over from T85, #241): Studio → Test → Clients and Servers, 2 or 3
  players; which window is the host; that J (no saving) is per client; where Output for the
  server vs each client is; how to end the session. Link the T86 script in `RECAP.md`.
- **Publish checklist:** File → Publish to Roblox (private); Game Settings → Security →
  "Enable Studio Access to API Services"; keep the experience private until the smoke test;
  what each `SaveStatus` value means; the DataStore names in use (list them from
  `Progression`, `LevelBoard`, `TrophyBoard`) so he never renames one by accident; how to
  roll back (Version History).
- **Accept:** every DataStore name in the list matches a `grep` of `src/server`; no code change.

### T89 — Studio-only gating audit (Builder) — DONE (b76c179)
- Every Studio-only path is behind `RunService:IsStudio()` on the **server**: K/J/L keys,
  stand-in sides, the Studio Lobby remotes (`standins`, etc.), the J "no saving" switch.
  Move any check into one pure helper (e.g. `Shared/StudioOnly.allowed(isStudio, feature)`)
  that the server calls.
- **Accept:** a spec lists each Studio-only feature and asserts it's refused when
  `isStudio = false`; a grep-based spec fails if a new Studio key handler skips the helper;
  co-op specs unchanged; Tester: K/J/L and stand-ins still work in Studio.

### T90 — DataStore hardening, specs with a fake store (Builder) — DONE (8e07fdf)
- A fake DataStore in `tools/test/` (throttle errors, `UpdateAsync` conflicts, a failing
  `GetAsync`). Specs for: a failed load never overwrites; saves retry with backoff inside the
  budget; Ranked escrow is refunded on BindToClose and on a later load; a leaver's forfeit and
  last-place Trophies land in one save; the Trophy and level boards stay in their write
  budget at 10 players. Fix only what a spec proves wrong (report each fix).
- **Session lock** (needed before batch 3, when a player can hop servers): a profile loaded
  on server B while server A still holds it must not lose A's last save. Spec the rule in
  `Shared/Profile`; wire it in `Progression`.
- **Accept:** specs green; `Progression` is still the only profile writer; no DataStore is
  touched in Studio (`SaveStatus` offline as today).

### T91 — Battle pacing report (Builder, `tools/threat.py` / `value.py`; no sheet change) — DONE (72495d3)
- Model a battle side on Normal at `Battle side density` 0.6 and 2/3/10 sides: the round
  where an average camp's Fence falls with a typical build, and how far that is from round
  40 / Final Stampede. Compare Run 3's observed round 8–9 spike (Fence 30 → 11).
- **Accept:** the report prints per mode; the Director turns it into ask 3's options (e.g.
  a `Battle starting lives` lever, or density) with numbers. Nothing changes until Jovan answers.

### T92 — Concussive T5 (Tectonic Slam) buff (Director's cell, Builder applies) — superseded by T92 (final)
- value.py's standing finding (Round 4 recap). Buff only, never a nerf (#235's rule): the
  Director picks one cell so Tectonic Slam meets the T5 "worth it" bar; assert the old value.
- **Accept:** value.py finding gone; Config diff = that cell; `audit.py --strict` 0.

### T93 — Stand-in hunter for solo PvP tests (Builder, Studio-only) — DONE (e2ba805)
- With stand-ins on, each stand-in camp also gets a **stand-in hunter**: a dummy character
  on its plot (100 HP, never shoots, never saved/paid/ranked), so one Tester client can check
  hunter-vs-hunter ×`PvP hunter damage`, "Tranqed by <name>!", respawn on its own camp and the
  Camo Cover countdown. Gated by T89's helper.
- **Accept:** specs for the dummy's damage via `BattleRules.pvpDamage`; Tester Run 5 checks
  it; co-op and real-player PvP paths unchanged.

### T92 (final, #244) — Tectonic Slam: one cell (Builder applies; assert the old value) — DONE (60accd3)
- **`Tower Upgrades!G49` (Mortar Pit · Concussive · T5 Tectonic Slam, Damage x): 24.76 → 34.**
  Nothing else: stun stays `U49` 1 s, `V49` (stuns bosses) stays blank, knockback `W49` 6,
  cost formulas untouched. Director's trial on a copy of the sheet: eDPS r31–40 232 → 292,
  c/e 268 → 213, marginal 454 → **258 (1.5× the T5 median 174)**; DEAD flag gone; the T5
  median doesn't move. (30 → 1.8×, too close to the 2× DEAD line; 38 → 1.3×, more than needed.)
- **Accept:** Config diff = that one value; `value.py` shows Tectonic Slam without DEAD and
  no new finding; `audit.py --strict` 0; exporter green. **If value.py's marginal differs
  from 258 ± 10, stop and report.** UPGRADES.md: update a Tectonic Slam damage line only if
  it states the multiplier.

### T91b (#245) — Battle pacing: let rounds breathe (Builder; one cell + Studio test aids) — DONE (b1a090c; "match ends when a camp falls in overtime" waits on N7)
**Finding (T91, Director's trials on the model):** the battle killer is the lockstep cap, not
armour or Fence size. Normal's natural round runs 90–119 s; `Battle round time` 60 cuts every
camp to ~2/3 of the time, so EHP outruns DPS by round 11. Trials (model "typical" build, which
is conservative: co-op solo Normal also falls at 21 in it):
| change | 2 camps ×1 | 2 camps ×5 | 3 camps / Bone Rush | 1.5× typical (competent) |
|---|---|---|---|---|
| today (60 s) | 11 | 11 | 17 | 18–20 |
| armour leak ×0.25 / Fence 100 / cash 1200 / no promotion | 11–12 | 11 | 17–18 | — |
| **round time 120 s** | **21** | **21** | **32** | **40 → Final Stampede** |
1. **`Tuning!B143` Battle round time: 60 → 120** (assert 60). Lockstep still starts the next
   round 5 s after every live camp clears, so quick camps don't wait; 120 only stops a
   struggling camp from being buried. Update the C143 note: "…(≥ the longest Normal round, 119 s)".
2. **Studio stand-in camps' fixed towers pierce armour** (Studio-only via `Shared/StudioOnly`,
   no sheet value: a flag on the stand-in tower set). Test fidelity only; never in real play.
3. **Studio-only host options for testing late rounds** (behind `StudioOnly`, hidden unless
   `IsStudio()`): "Start at round N" (battles and co-op) and "Stand-ins hold" (a stand-in
   camp's Fence never drops below 1), so the Tester can reach round 40 and Final Stampede.
- **Accept:** Config diff = B143 only; `value.py --battle` prints, for Normal with 1 hunter:
  2 camps ≥ round 20, 3 camps and Bone Rush ≥ 30, and a new "competent (1.5× typical)" column
  reaching round 40 in every mode (add that column); co-op specs and co-op pacing unchanged
  (B143 is battles only); specs that both Studio options are refused when `isStudio = false`.
  Tester Run 5 adds: a Camp Clash with "Start at round 38" + "Stand-ins hold" → Final Stampede
  banner, HP step ×1.25 per repeat, and the match ends when a camp falls.
- **Target (for Jovan to confirm, ask 3):** a competent 1-hunter camp reaches round 25+ and a
  strong one sees Final Stampede. Cost: a full battle can now run ~60–80 min. Unchanged on
  purpose: armour leak cost, promotion, Fence, starting cash (the trials show they barely move it).

### Tester Run 5 (after batch 1) — DONE (304822e: 23 pass, 0 fail; N7 → Builder)
Co-op smoke (rounds 1–3); K/J/L + stand-ins still work; shoot a stand-in hunter (×0.5, kill
line, respawn, Camo Cover); Concussive T5 in play; no new console errors.

### T94 — Private publish (Jovan, following T88) — NEEDS JOVAN (`SETUP.md` "Publish checklist")
### T95 — Published smoke (Jovan; Tester reads Output if the MCP can reach it)
Saves load and save; Ranked with 2 real clients: Entry fee taken, Amber Hoard paid,
Trophies saved; shut the server mid-match → refund on next join; both world boards show
rows; a leaver loses Trophies. **Accept:** each line pass/fail in `PLAYTEST.md`.

### T96 — Lobby place + matchmaking (needs ask 4 and batch 2)
Design first (Director, DECISIONS): lobby place, MemoryStore queue by mode and Trophies,
TeleportService to a reserved match server, `Shared/Matchmaking` reused, session lock (T90)
required. Testable only published.

### T97 — The 4×-Amber towers (needs ask 1) — NEXT (2026-10-13): proposal refreshed with 7 concepts (#273); waiting on Jovan's picks
Same pattern as round 4's T62–T69: names (🦖), sheet rows, pure rules module per tower, server
behaviour, panel, value.py bars, Tester steps.

### T98 — Battle difficulty/length — REPLACED by Phase 8 batch 2 (DONE, #249, #271) · T99 — Phase 8 docs + recap (Director) — DONE for batch 1

# Plan — Phase 7: the battle modes (Director, 2026-10-06)

Scope (Jovan, 2026-10-06): **"make sure everything is play tested and phase 7 is fully
done"**. Phase 7 = Team Battle, Battle Royale, competitive buy-ins/pots and ranked
Trophies (`VISION.md` "Future battle modes", "Amber economy"; `DIRECTION.md`). Design calls:
`DECISIONS.md` #208–#226. **Playtesting rounds 1–4 runs separately** (T31/T38/T60/T70 +
PLAYTEST.md re-run; blocked right now on Jovan reconnecting Rojo). It does not block the
phase-7 Builder batches. Each phase-7 batch still ends with its own Tester step, and phase 7
is not "fully done" until those steps and Jovan's multi-player steps (T86) have run.

**Status (2026-10-08, final): Phase 7 built. T71–T84b, T86b (c559cdc) done; T85 + T87 written by the Director (#237–#243). Tester Runs 1–3 done (T31/T38/T60/T70 covered by Runs 1–2); Run 4 re-checks T86b. Left: Jovan's Clients and Servers script (T86) and the after-publishing list → Phase 8 (top of this file).** Earlier: **T84/T84b done (bf6d09b, 207513e); Tester Run 3 41 pass / 2 minor fail; Dino Round 17. Next: T86b (fixes, #236), then T85 + T87 (Director). Earlier: T84 stopped on its bars as designed; #235 makes the edge report-only and T84b buffs four perks. Next: T84 (rerun, revised) + T84b in one Builder run. Earlier: batch 5 signed off (8a42872, 2d96e1f, b314bcb, 9b430d7, 9c0b421, afe0dd1; 579 specs; #234). Next: T84 (Builder), then T85 + T86. Earlier: batch 4 signed off (34d3606 F4, 57c89cf T79b, d9c938b T80, 946bcd6 T81; 559 specs; #233). Next: batch 5 = T82, T83 with #233's fixes. Earlier: batch 3 signed off (45f5cb2, 8d4673e, bcdfe9f; 520 specs; T79 review = #232). No Builder while the Tester's Run 2 is live. Next: batch 4 = T79b, T80, T81. Earlier: batch 2 signed off (T75 0ab8f14, T76 9b356fa; 491 specs; #231). T77–T78 final with #231's additions. Earlier: batch 1 signed off (T73 62608e6, T71 86c94bf, T72 4b2a3bc; 467 specs; #227–#228). T75–T76 final as written. Queued: T78 amendments below.**

Round 1–4 rules hold (one task = one commit, pushed; `tools/check.sh`, `export_constants.py`,
`tools/test.sh` green; diff `Config.luau` after every sheet change; openpyxl only, assert a
cell is empty first; append, never insert; internal keys never change; "statically checked +
headless, not playtested" until the Tester runs it; player text says **Bones**/take-downs).
For phase 7:
- **New Tuning levers go below row 140** (row 140 blank, row 141 the header `BATTLE MODES`;
  the last used row today is 139). Assert each cell is empty. New sheets are appended at the
  end of the workbook.
- **Co-op must not change.** Co-op is "one side, every player on it". Every batch re-runs the
  co-op specs and a co-op Studio smoke run (rounds 1–3).
- **Pure rules first.** Every rule a server module applies (sides, damage permission,
  elimination, placement, payouts, trophies) lives in a `Shared/` module with a headless
  spec. The server only calls it.
- **Fresh Builder per batch.**

## The design (decided; the reasons are in DECISIONS #208–#226)

**Common to both battle modes**
- **Sides.** A side is a build plot with its own track, Fence (lives), cash pot and dinos.
  Co-op = 1 side. Team Battle = 2 or 3 sides (host picks; 3 needs at least 3 players).
  Battle Royale = one side per player (2–10).
- **Map.** Each side gets a copy of the Serpentine track. The copies sit in a row (2 or 3
  sides) or a 2-row grid (Royale), joined by a 40-stud open **crossing strip** with no
  track. Hunters walk anywhere. They build only inside their own side's build zone:
  `Shared/Placement` adds a zone check, used by the ghost (red outside your zone) and
  enforced by the server.
- **Dinos.** Every side runs the same seeded rounds, so every side faces the same dinos.
  Each side is scaled by its own player count (the CO-OP levers). Royale and 3-side Team use
  a per-side density lever (`Battle side density`), so 10 tracks stay under the live enemy
  cap. Leaks hurt only that side's Fence. **No dino-sending in v1** (ask-Jovan #1).
- **Rounds move in lockstep.** Round N+1 starts for every living side when they have all
  cleared round N, or `Battle round time` seconds after round N started, whichever comes
  first. Dinos left over stay on the track. There is no Start button per side: one 30 s build
  phase (`Battle build time`), then the rounds run.
- **"Destroy enemy towers" = hunters' guns.** A hunter's shots damage an enemy side's towers
  (× `PvP tower damage`, seed 0.35). At 0 HP the tower is Trampled (knocked out) exactly as
  with dinos, and only its own side can repair it. Falcon Roost and Tar Pit stay undamageable
  ("somewhat weaker" is their price). **Towers never shoot hunters.** Dinos bite anyone in
  reach, invaders included.
- **Hunter vs hunter.** Enemy hunters can shoot each other (× `PvP hunter damage`, seed 0.5;
  100 HP; respawn on your own side after Respawn time, with `Spawn shield` 3 s of no damage).
  Abilities (Tracking Dart, Rally Cry, Flare Strike, the Medic's heal) and all mastery perks
  affect dinos and your own team only, so there is **no crowd control on hunters**.
- **No friendly fire.** A shot never damages your own side's towers or hunters. You can't
  sell, upgrade or repair an enemy tower. You can still upgrade a teammate's tower.
- **A side is out** when its Fence hits 0: its towers are removed, its dinos despawn, and
  its hunters become spectators (they can walk but deal no damage and can't build). The
  results order is the elimination order.
- **First person always** (existing camera rule). Difficulty: the host picks it in casual.
  In competitive it is fixed to **Normal**.

**Team Battle.** The last side standing wins. Teams are balanced by count (sizes differ by at
most 1), then snake-drafted by Trophies in competitive. After round 40, **Overtime**: the
final round repeats, each time with dino HP × `Overtime HP step` (seed 1.25), until one side
falls. If the last sides fall in the same step, the side with more Bones wins (then it's a
tie: the pot is split across the tied sides).

**Battle Royale.** Every player for themselves on their own plot, crossing and raiding
allowed. **Most Bones wins** (take-downs, as today). An eliminated player's Bones freeze. The
match ends when at most one player is left alive, or at round 40. The last one alive gets
`Survivor bonus` (seed +10%) Bones. Placement is by Bones; ties go to whoever survived longer,
then to whoever has more Fence. Knocking out a tower gives no Bones (`Raid bones` = 0): raiding
pays off by making rivals leak.

**Queues, buy-in and pot** (one server; the host picks mode + Casual/Competitive)
- **Casual battle payouts** (levers): Team win 50 each, loss 5; Royale 1st 60 / 2nd 30 /
  3rd 10 / the rest 5. No buy-in.
- **Competitive = ranked.** One queue; Trophies change only in competitive. Everyone who
  wants in presses **Ready** on the home screen and confirms the stake. Minimum: Team 2
  players (1v1 allowed), Royale 3. Buy-in is `Competitive buy-in`, seed **15** (the exporter
  holds it to 10–20).
- **Pot flow (`Shared/Stakes` pure, `Progression` applies):** the stake is taken when
  Building starts. It is written to the profile as an **escrow** `{matchId, amount}` and saved
  at once. At the end the result is settled and the escrow cleared in the same save. Team:
  the pot is split equally among the winning side's hunters still present, each share rounded
  down. Royale: 72% / 23% / 5% of the pot, each rounded down. If fewer than 3 finished, the
  unused shares go to 1st. Leftover coins are a sink. **Winners also get the casual payout**,
  so competitive always pays more than casual (exporter check). A leaver forfeits their stake
  to the pot and gets nothing. If the server shuts down (BindToClose), or a later load finds an
  escrow that was never settled, the stake is refunded.
- **Failed load / offline:** a player whose profile didn't load (`SaveStatus` offline)
  **can't stake** and is told why. They may still play casual. **Unpublished** (Studio:
  everyone offline) competitive runs as **Practice**: session-only Amber is staked and paid
  by the same rules, Trophies don't change, and the results say "Practice".

**Ranked Trophies** (`Shared/Trophies` pure; the new `Arenas` sheet)
- Everyone starts at 0. Team win +30, loss −30 (levers). Royale: by placement, scaled to the
  lobby size: the top third gains (1st +30 … ), the middle gets 0, the bottom third loses
  (last −20). Trophies never drop below the floor of the arena you've reached
  (Clash Royale-style gates), and never below 0.
- **Arenas:** 8 tiers on the `Arenas` sheet (floor trophies 0 / 300 / 600 / 1000 / 1500 /
  2000 / 3000 / 4000; names by the Dino agent, T74). Reaching an arena for the first time
  unlocks one cosmetic or title (cosmetic only, never power). No seasons in v1.
- **Display:** the Trophies count + arena badge on the leaderboard, the Profile screen
  (Trophies tab) and the home screen. The results screen shows ±Trophies and any arena
  change. A **Trophy leaderboard** (top 50) works the same way as the level board:
  cross-server when published, "This server" unpublished.

**Matchmaking.** It happens inside one server: whoever is in the server and presses Ready.
**A separate lobby place with Teleport/MemoryStore queues is out of scope.** TeleportService
doesn't work unpublished, so it can't be built or tested honestly now; it's logged for
publishing. `Shared/Matchmaking` (pure) assigns sides and snake-drafts by Trophies, so a lobby
place can reuse it later.

**PvP parity (mastery perks stay on).** "Other perks buffed so money advantage isn't too big"
becomes two exporter/`value.py` bars. (1) **Edge bar:** a mastery-20 hunter with every small
perk is worth at most `Competitive edge max` (seed 10%) more than a mastery-0 hunter on the
same hero. (2) **Parity bar:** at mastery 10, 15 and 20, every hero's perks are worth within
±`Perk parity band` (seed 15%) of each other. When a bar fails, the weaker perks are
**buffed, never nerfed** (Director picks the cells, as in T51). Unlocks are not loaned in
competitive: you play what you own (the audience is maxed players, and Trophies match like
with like).

**No-trap rule for every new screen** (DIRECTION): the Ready/stake confirm, the battle
options on the home screen, the Tab scoreboard, the spectate banner, the results screen and
the Profile Trophies tab. Each one fits any window (scroll/scale), keeps its X visible, frees
the mouse, closes with its key and its X, and closes on state change unless `PanelRules`
allows it. **Ready is each player's own button**, reachable by every player, not just the
host.

## Batches

| Batch | Tasks | What |
|---|---|---|
| 1 | T71, T72, T73 | pure rules: battle rules + matchmaking; stakes + trophies; sheet levers + `Arenas` + exporter/audit checks |
| — | T74 🦖 | names: mode cards, side names/colours, arenas, Trophies wording, spectate/raid/overtime text |
| 2 | T75, T76 | map sides + build zones + per-side tracks and waves; per-side Economy + Shop ownership rules |
| 3 | T77, T78 | match flow (teams, lockstep, elimination, overtime, Royale end, Studio stand-in sides); PvP damage |
| — | T79 🦖 + Director | review batches 2–3 (in-match text, raid feel vs DIRECTION) |
| 4 | T80, T81 | Progression: escrow, pot, offline/Practice, trophies saved; Trophy board + arena rewards |
| 5 | T82, T83 | home screen battle options + Ready/stake; HUD, scoreboard, spectate, results, Profile Trophies |
| 6 | T84, T85 | PvP parity bars (`value.py` + exporter) and any buffs; docs + recap |
| — | T86 | Tester sweep of phase 7 + Jovan's multi-player script |

### Testing in Studio: what one MCP client can and can't do

The Tester drives **one** Studio client through `tools/studio/mcp.py`. Before batch 3, the
Tester runs `tools` once and records whether the MCP can start a **Clients and Servers**
session (several players). Assume it can't. T77 therefore adds **Studio-only stand-in sides**:
with `RunService:IsStudio()` and the host's lobby toggle "Fill with stand-ins", each empty
side or Royale seat is a stand-in. It has no player, but it has a track, a Fence, dinos and a
fixed set of pre-placed towers (owner id negative, never saved, never paid, never given
Trophies). With stand-ins, one client can test placement zones, raiding (shooting enemy
towers to a knock-out), leaks → elimination → win, lockstep rounds, overtime, Royale ranking,
pot math in Practice, the results screen, and the 10-side enemy-cap load.
**Not testable solo:** hunter-vs-hunter hits, spawn shield, teammate upgrades, the Ready
button for non-hosts, team balance. These go to **Jovan's local Clients and Servers test**
(2–3 windows on his Mac, no real players needed; script in T86). **Needs real players or a
published place:** DataStore stakes/escrow/refunds and saved Trophies, the cross-server
Trophy board, 10-player network load and hit fairness under real latency, and PvP feel and
balance.

### T71 — `Shared/BattleRules` + `Shared/Matchmaking` (pure)
- `Modes` gets `sides` rules: COOP 1; TEAM 2|3 (3 needs ≥3 players); ROYALE = player count
  (2–10). TEAM and ROYALE stay `available = false` until T82.
- `BattleRules`: `canDamage(attackerSide, targetSide, targetKind)` (no friendly fire; towers
  never target hunters; undamageable towers immune); `nextRoundDue(sidesCleared, elapsed)`
  (lockstep); `sideOut(fence)`; `teamResult(eliminationOrder, bones)`
  (last standing, overtime tie → Bones → tie); `royaleResult(players)` (Bones; tie → survived
  longer → Fence; survivor bonus; ends at ≤1 alive or round 40); `overtimeHpMult(n)`.
- `Matchmaking.assign(players, sides, trophies?)`: sizes differ ≤1; snake draft by Trophies
  when given; deterministic.
- **Accept:** specs cover every rule above, including the 1-alive Royale end, the
  simultaneous-fall tie, and 7 players → 3 sides of 3/2/2. Co-op specs unchanged. No numbers
  in code (levers come from T73's Config keys; seeds go in the sheet).

### T72 — `Shared/Stakes` + `Shared/Trophies` (pure)
- `Stakes`: `canStake(profileLoaded, published, amber, buyIn)` → ok / reason
  (offline, can't afford, Practice); `pot(stakes)`; `teamSplit(pot, winners)`;
  `royaleSplit(pot, placements)` (72/23/5 floor; fewer than 3 → unused to 1st);
  `casualBattle(mode, placement, n)`; `settle(...)` = casual + share; leaver forfeits;
  `refund(escrow)`.
- `Trophies`: `delta(mode, placement, n)`; `apply(trophies, delta, arenas)` (arena floor,
  never < 0); `arenaOf(trophies)`; `newArenas(old, new)`.
- **Accept:** specs: pot 4×15 → team 2 winners 30 each; Royale 3×15 = 45 → 32/10/2
  (floors); 2 finishers; leaver; refund; offline refused; Practice flag; arena floor holds a
  loss; no negative trophies; competitive winner > casual winner at minimum lobby.

### T73 — Sheet + exporter/audit
- `Tuning` rows 141+ (`BATTLE MODES`): Battle build time 30, Battle round time 60, Battle
  side density 0.6, PvP tower damage 0.35, PvP hunter damage 0.5, Spawn shield 3, Overtime HP
  step 1.25, Survivor bonus 0.10, Raid bones 0, Competitive buy-in 15, casual battle payouts
  (team win 50/loss 5, royale 60/30/10/5), Royale split 72/23/5, Trophies team ±30, Royale
  trophy table, Competitive edge max 0.10, Perk parity band 0.15, Team/Royale min players 2/3.
- New sheet `Arenas` (appended): Key, Name (placeholder until T74), Floor, Reward (cosmetic id
  or blank).
- Exporter refuses: buy-in outside 10–20; splits ≠ 100; arena floors not ascending from 0;
  PvP mults outside (0, 1]; competitive winner ≤ casual winner at min players; arena reward
  that isn't a cosmetic/title. `audit.py` checks the VISION numbers (72/23/5, 10–20).
- **Accept:** Config diff = only the new keys; `audit.py --strict` 0; each refusal has a spec
  or a negative test run.

### T74 🦖 — names
**Done (DINO_REVIEW Round 16; Director picks #229). Strings by batch:**
- **Mode names (Jovan, 2026-10-06, #230): Team Battle → "Camp Clash", Battle Royale → "Bone Rush".** Internal keys stay `TEAM` / `ROYALE`. Exact strings: `Modes.luau` `TEAM.display = "Camp Clash"`, `ROYALE.display = "Bone Rush"` (blurbs: "Two or three camps, each defending its own side." / `Every hunter for themselves. Most {Theme.Bones} wins.`); the home cards, the HUD side banner and the results title read `Modes[...].display`, never a literal (T82/T83). Results titles: **"Camp Clash — Your camp wins the hunt!"** / **"Bone Rush — Top Hunter!"**. Docs (T85): VISION/ARCHITECTURE/CLAUDE say "Camp Clash (team battle)" / "Bone Rush (battle royale)". Queue toggle labels **Casual / Ranked** (internal key stays competitive). Practice → **"Practice Hunt"**; buy-in → **"Entry fee"**; pot → **"Amber Hoard"**; spawn shield → **"Camo Cover"**; overtime → **"Final Stampede"**.
- **T77/T78 (batch 3):** Team sides **Red Camp / Blue Camp / Green Camp**; Royale sides **"<Name>'s Camp"** (10 colours, visual-only in code); side out: **"<Camp>'s Fence is down! They're out."**; hunter down: **"Tranqed by <name>!"**; tower raid kill feed reuses **Trampled**: "<name> trampled <Camp>'s <tower>".
- **T81 (batch 4):** `Arenas!B2:B9` (assert each cell still holds T73's placeholder): Fern Gully 0, Raptor Ridge 300, Muddy Springs 600, Horn Canyon 1000, Volcano Rim 1500, Sky Cliffs 2000, Misty Jungle 3000, Rex Kingdom 4000.
- **T82/T83 (batch 5):** the labels above, plus results lines **"Your camp wins the hunt!"** (Team) / **"Top Hunter!"** (Royale 1st). Mode blurbs unchanged (Modes.luau).

### T75 — Map sides
- `Track` gains a side layout: offsets per side for 1 / 2 / 3 / up to 10 sides, a crossing
  strip, a build-zone rect per side, a spawn per side. `MapBuilder` builds N copies.
  `Enemies` and `Waves` run one path and one queue per side through `Enemies.enqueue(side, …)`
  (still the only spawner; the live cap is shared and split by `Battle side density`).
  `Placement.check` gains the zone check (on-track rule unchanged; Tar Pit only on its own
  side's track).
- **Accept:** specs: zones never overlap and never touch another side's track; a ghost
  outside your zone is refused by the same rule on client and server. Co-op builds exactly
  today's map (same waypoints, same specs). Tester: co-op smoke (rounds 1–3, place every
  owned tower, Tar Pit on track).

### T76 — Per-side Economy + Shop rules
- `Economy` keyed by side (cash + Fence); co-op = side 1 with today's API kept as wrappers.
  `Shop`: build only in own zone with own side's cash; upgrade own side's towers (teammates'
  too); never sell/upgrade/repair an enemy's. The HUD reads your side's cash/Fence attributes.
- **Accept:** specs for each Shop refusal; `Economy` is still the only cash mutator
  (ARCHITECTURE §4 updated); co-op smoke unchanged.

### T77 — Battle match flow (server)
- **#231 additions:** round income (base + Supply Camps) and heals are paid per living side to that side's pot. **Airdrop chests drop on every living side's own plot, one each; only that side's hunters can pick one up, and it pays that side.** Enemy hunters can't see a pickup prompt on it.
- `Main` runs TEAM/ROYALE: assign sides (`Matchmaking`), spawn per side, one build phase,
  lockstep rounds (`BattleRules.nextRoundDue`), per-side round income and heals, elimination
  (towers removed, dinos despawned, players spectate), overtime, Royale end + survivor bonus,
  results attributes (placement, Bones, side). Leavers mid-match: their towers stay with the
  side; a Royale leaver's side is out.
- **Studio-only stand-in sides** (lobby toggle, host, `IsStudio()` only), as described above.
- **Accept:** specs for the flow helpers; Tester (solo, stand-ins): TEAM 2 sides → refused
  build across the strip; shoot a stand-in tower to a knock-out; the stand-in leaks out →
  Victory; ROYALE with 3 stand-ins → placements by Bones; the 10-side Royale console line
  shows the peak enemies under the cap and the script cost (record it).

### T78 — PvP damage
- **#231 additions:** (1) `canDamage` covers **every source**: tower shots, splash, bomblets, burning ground, Tar Pit, Storm Coil chains, Falcon, Ballista, abilities (Flare Strike stun, Tracking Dart, Rally Cry) and hero shots. Each one affects **only its own side's dinos**. Towers *target* only their own side's dinos (a targeting filter, not just damage), so they never waste shots across the strip. Specs per source family. (2) Refusal strings (exact): "That's another camp's zone. Build inside your own camp." / "You can't upgrade another camp's tower." / "You can't repair another camp's tower." / "You can't sell another camp's tower." / "Not enough cash in your camp." (3) **Tower panel on an enemy tower is read-only**: name, tier, "<Camp>'s tower", HP bar; no upgrade/repair/sell buttons (the server refusal stays). Passes the no-trap rule.
- **From batch-1 review (#228), first commits of T78:** `BattleRules.canDamage` refuses a hunter hitting **another side's dinos** (dinos are only hurt by their own side's hunters/towers, so no Bone-stealing); every enemy carries its `side` from T75's `Enemies.enqueue(side, …)`. Exporter: `PvP hunter damage` allowed in **[0, 1]** (0 = hunter-vs-hunter off), `PvP tower damage` stays (0, 1]; spec both.
- Shots (server-validated, as today) can hit an enemy side's towers and enemy hunters per
  `BattleRules.canDamage` × the PvP levers. Spawn shield; respawn on own side; abilities
  dinos/own team only; a kill-feed line "<a> knocked out <b>'s <tower>".
- **Accept:** specs: own tower/teammate never damaged; immune towers immune; damage =
  shot × lever; shielded hunter takes 0. Tester solo: own towers take no damage from own
  shots; stand-in towers do. Hunter-vs-hunter → T86 (Jovan).

### T79 🦖 + Director review of batches 2–3
**Done (#232).** Accepted as built: battle flow, PvP damage, per-side payouts, the names.

### T79b — Review fixes (first commit of batch 4)
- **Strip refusal:** off every camp's zone (the crossing strip) say **"You can only build inside your own camp."**; keep "That's another camp's zone…" for a rival's zone. Spec both.
- **Round break:** new lever `Battle round break` = **5** s (Tuning, next empty row after T73's block; assert empty). Lockstep waits that long after the last living side clears. Spec in `BattleFlow`.
- **Stand-ins score Bones** from their own towers' take-downs, credited to the seat (never saved, paid or ranked), so Bone Rush ranking is testable solo.
- **Enemy towers show no "Upgrade" prompt** (client hides the prompt when the tower's side ≠ yours; the server refusal stays).
- **Mid-battle joiners** stay on the home screen with a banner "A hunt is on — you'll join the next one." (no-trap: fits, mouse free, closes on state change); they're never seated, staked, paid or ranked. Co-op drop-in unchanged.
- **Accept:** specs; co-op specs unchanged; Config diff = one key.

### T80 — Progression: stakes, Practice, Trophies saved
- **Final (#232):** `Server/Battle` calls Progression at the end: casual battles pay `Stakes.casualBattle`; Ranked settles with `Stakes.settle` (escrow cleared in the same save); player XP (cleared rounds; a win counts as a Normal clear) and bounties (#222); stand-ins and mid-battle joiners never touch Progression. The Ready/stake *server* path lands here (remote `Lobby:FireServer("ready", bool)`, validated by `Stakes.canStake`); its UI is T82.
- Profile gains `trophies`, `bestArena`, `escrow` (sanitized; old saves load as 0/nil).
  Stakes taken at Building, escrow saved at once; settle + clear in one save; BindToClose and
  load-time refunds; offline can't stake; unpublished → Practice. Bounties count battle
  matches as matches; player XP as in co-op (cleared rounds; the win counts as a Normal clear).
- **Accept:** specs on `Profile.sanitize` for the new fields and the refund-on-load; a
  failed load still never overwrites. Tester (offline): Practice stake leaves session Amber
  and comes back by the split; Trophies unchanged; turn saving off with J first.

### T81 — Trophy board + arena rewards
- **Final (#232):** also writes the arena names into `Arenas!B2:B9` (PLAN T74) and the Trophies + arena badge on the in-game leaderboard; reward cells stay blank unless a cosmetic id exists (exporter checks).
- `Server/TrophyBoard` on the `LevelBoard` pattern (OrderedDataStore when published, "This
  server" otherwise); arena rewards join `Cosmetics` (unlock on first reach).
- **Accept:** spec for the fallback; Tester: Profile shows the This-server board.

### T82 — Home screen battle options + Ready
- **#233, first commit (server):** a **Ranked leaver loses Trophies** as if they placed last (Camp Clash: the loss delta; Bone Rush: last place in that lobby size), applied and saved when they leave (PlayerRemoving, same save as the forfeited escrow); never in Practice. Spec.
- **Ready refusal strings** (`ReadyRefused` reason → text; `{fee}` = `Competitive buy-in`, `{cur}` = Theme.Currency): `offline` → "Your save didn't load, so you can't pay the Entry fee. Casual is still open." · `cantAfford` → "You need {fee} {cur} for the Entry fee." · `loading` → "Your save is still loading. Try again in a moment." · `practice` (not a refusal, an info line under Ready) → "Practice Hunt: session Amber only. Trophies won't change." · any other key → "You can't ready up right now."
- TEAM/ROYALE cards available; host: Casual/Competitive, 2/3 sides, stand-ins (Studio).
  Every player: Ready + stake confirm (shows buy-in, balance, Practice/offline reason), who's
  ready, min-players line; PLAY is enabled when the minimum is met.
- **Accept:** no-trap checks (two window sizes, X + key, mouse free, closes on state change);
  Tester solo as host. Non-host Ready → T86.

### T83 — In-match + results UI
- **#233 first:** (a) enemy towers get an **"Inspect"** prompt (ActionText "Inspect") that opens T78's read-only panel; own-camp towers keep "Upgrade". (b) **Player list = 4 stats:** Bones, Level, Trophies ("<n> · <Arena>"), Title. The **Mastery** column leaves the player list (it stays on the Mastery screen, Profile and the hero card). Spec the column order.
- Side banner/colour, own cash/Fence, sides alive, Tab scoreboard by side (Bones), spectate
  banner, overtime banner; results: placement, pot shares, ±Trophies, arena change, Practice
  tag; Profile Trophies tab (arena ladder, current arena, board).
- **Accept:** `PanelRules` updated with spec; no-trap sweep for each screen; Tester solo
  with stand-ins (TEAM win, TEAM loss, ROYALE).

### T84 — PvP parity: perk-parity bar + edge report (revised, #235)
- **Parity bar (exporter-enforced):** the max ÷ min of the heroes' #99 worth % ≤ 1 + `PerkParityBand` (1.15) at **mastery 10** (the L10 perk) and at **mastery 15+** (L10 + L15 summed; 20 adds no ability perk). Negative test.
- **Edge = report only, never a bar.** value.py prints per hero: the free first upgrade (cash ÷ Normal starting cash), the cooldown −30% and the perks as ability gain, each small perk, and a **duel edge** (what touches hunter-vs-hunter fights: the round-clear heal in HP and the respawn time in s; perks never touch hunters, #212). It flags any total over `CompetitiveEdgeMax` as a **watch line** for the recap. That lever stays as the watch threshold. The exporter doesn't enforce it.
- **Definitions:** "ability share" is the ability's share of that hero's *own effect*: for damage abilities (Tracking Dart, Flare Strike) it's the damage share; for **Rally Cry** it's the tower DPS it adds (towers in radius × boost × uptime, from value.py's existing tower model); for **Triage Kit** it's HP restored per round, reported in HP, not as a damage %. **Pick-up reach** (base 0) is reported in studs, not as a % of base.
- **Accept:** the parity bar passes after T84b; the edge report prints every component; `audit.py --strict` 0.

### T84b — Parity buffs (Director's cells; `Mastery Perks` sheet; assert each old value first)
| Cell | Old → new | Text cell (D) new |
|---|---|---|
| F7 (RIFLE 10 radius) | 5 → **6** | "Rally Cry reaches 6 studs further" |
| E8 (RIFLE 15 seconds) | 3 → **3.5** | "Rally Cry lasts 3.5s longer" |
| F9 (SHOTGUN 10 radius) | 1.5 → **2.5** | "Flare Strike reaches 2.5 studs further" |
| F11 (MEDIC 10 radius) | 4 → **5** | "Triage Kit reaches 5 studs further" |
| G12 (MEDIC 15 power) | 10 → **14** | "Triage Kit heals 14 more HP" |
Expected worth % (bases 8 s / 25 / 10 / 20 radius, 10 s Rally, 40 HP heal): M10 = 25 / 24 / 25 / 25 → 1.04; summed = 65 / 59 / 61 / 60 → 1.10; each L15 > its L10; all ≤ 40 cap. Tracker unchanged (the top). **If the exporter's numbers differ from these, stop and report**, with no other cells changed. HEROES.md "Mastery" table and the perk names' text updated to match. Config diff = these 5 values + 5 texts.

### T85 — Docs + recap — DONE (Director, 2026-10-08; `RECAP.md` "Phase 7"; SETUP.md multi-client moved to Phase 8 T88, #241)
- **#234:** a short 🦖 pass on batch 5's invented strings, folded in here (Dino agent lists any must-fix; the Builder applies it in this task). Already decided: Bone Rush placements below 1st read **"Bone Rush — Nth place"** (not "Nth Hunter").
`VISION.md` (modes built), `ARCHITECTURE.md` (phase 7 row, ownership: per-side Economy,
Stakes/Trophies, stand-ins), `CLAUDE.md` status, `GAUNTLET.md` status, `RECAP.md` "Phase 7":
what changed, what was tested where, and Jovan's script (T86). Update `SETUP.md` multi-client.

### T86 — Tester sweep + Jovan's multi-player script (final, #234) — Tester part DONE (PLAYTEST Run 3: 41 pass, F5/F6 fixed in T86b); Jovan's part OPEN
**Tester (one MCP client, J first so nothing saves; report in `PLAYTEST.md` Run 3, pass/fail/not-testable + screenshots):**
1. Co-op regression: Easy rounds 1–3, placement, an upgrade mid-round (F3), a Fence break on the last dino = loss (F4).
2. Home screen: the Camp Clash and Bone Rush cards; Casual/Ranked, sides 2/3, stand-ins toggle; Ready shows the Practice line; PLAY enables at the minimum; every panel passes no-trap at 707×620 and a small window (X visible, key closes, mouse free).
3. Camp Clash 2 camps + stand-ins (Casual): no Start, 30 s build; the build refusals on the strip and in the rival zone (exact strings); lockstep + 5 s break; shoot a stand-in tower to Trampled (kill-feed line); Inspect opens the read-only panel; own towers take no damage from own shots; towers ignore the rival track; your chest only; camps board + status line; the stand-in falls → results (title, placements, Amber, player XP).
4. Camp Clash 3 camps, Ranked (Practice): stake leaves session Amber, the Amber Hoard share comes back; Trophies unchanged; results show the Practice Hunt line.
5. Bone Rush with 3 and with 9 stand-ins: ranking by Bones (stand-ins score), the survivor bonus, the end at ≤1 alive, "Bone Rush — Nth place"; at 10 seats record the peak enemies vs the cap and the script cost from the console.
6. Lose a camp on purpose: spectate banner; can't build/hero/upgrade; Inspect works. Final Stampede: reach overtime only if practical (else not testable, note it).
7. Profile Trophies tab: arena ladder, This-server board; the player list shows Bones, Level, Trophies, Title.
**Jovan (Studio → Test → Clients and Servers, 2 then 3 players; ~20 min):** hunter vs hunter (×0.5, respawn on your camp, Camo Cover countdown), teammate upgrade allowed, the enemy-tower refusals, the non-host Ready + stake, join mid-battle → waiting banner, a Ranked leaver → last-place Trophies (Practice: none), 3-camp balance, how raiding feels.
**After publishing (listed in the recap, not testable now):** DataStore stakes, escrow refunds after a shutdown, saved Trophies, the cross-server Trophy board, 10 real players' load and hit fairness.

### T86b — Run 3 + Dino 17 fixes (#236; one Builder commit each or one together)
1. **F5:** while the results card is open (state Victory/GameOver), every HUD banner and feed line is hidden (camp-out, spectate, Final Stampede, kill feed); none may overlap the results card. Spec in `PanelRules` (or the HUD layout module): banners hidden in results states.
2. **F6:** the spectate banner "Your Fence is down — you're watching now." moves to bottom-centre, above the hotbar, never over the camps board. The camp-out banner stays top-centre and is laid out below the camps board's bottom edge.
3. **Dino must-fix:** `PanelRules.luau:239` → `"{display} — {ordinal} place"` for every mode below 1st (drop the ROYALE branch). 1st keeps "Your camp wins the hunt!" / "Top Hunter!".
4. **Dino nice-to-have (accepted):** `HomeLayout.luau:98` "BATTLE OPTIONS" → **"HUNT OPTIONS"**.
5. **Results time:** new lever `Battle results time` = **15** s (Tuning, next empty row after row 170; assert empty). Battles use it; co-op keeps `ResultsTime`.
6. **Amber line:** the results card says **"Amber +{total} ({payout} payout + {share} Amber Hoard)"** when there's a share, and "Amber +{payout}" otherwise. Never a separate "+share" that reads as extra.
7. **Practice with stand-ins:** stand-ins hold their placements in the Hoard split. Their shares go to the sink, so a last-place tester gets only last place's share. Real hunters-only splits (#233) are unchanged for real matches. Spec.
**Accept:** specs for 1, 3, 5, 6 (string builder), 7; Config diff = one key; co-op specs unchanged. Tester re-check: F5, F6, the place line, the Amber line (one solo Bone Rush + one Camp Clash with stand-ins).

### T87 — Phase 8: to define — DONE (Director, 2026-10-08): proposal at the top of this file (#238–#240)
Jovan (2026-10-06): "begin phase 8 when all loose ends on phase 7 are done". Loose ends = T86 run, the rounds 1–4 playtest (T31/T38/T60/T70 + PLAYTEST re-run), every Tester failure fixed. Then the Director proposes a Phase 8 scope with a recommendation, for Jovan to pick from. Candidates: (a) the 4×-Amber tower batch (`TOWERS_LATER.md`, awaiting his picks); (b) **publishing readiness**: DataStore saves live, stakes/escrow and Trophies on real servers, cross-server boards, 10-player network load (ARCHITECTURE §7); (c) a lobby place + Teleport/MemoryStore matchmaking by Trophies (#219, needs (b)); (d) balance follow-ups from the playtests (e.g. Concussive T5 buff, the open issues in CLAUDE.md); (e) more tracks (VISION "each track is its own level"). Director's leaning, to confirm then: (b) → (c) first, since phase 7's ranked mode only becomes real once published, with (a) as the content batch alongside. Add phase 8 to the ARCHITECTURE phase table in that step.

# Plan — Round 4: Jovan's answers (Director, 2026-10-02)

Scope (Jovan, 2026-10-02; his words in `DIRECTION.md` "Round-4 answers", `GAUNTLET.md`
"Round 4 scope"). Cheap, independent work first (renames, Linebreaker, UI, Hard cash, boss
throws), big systems after (one health pool + pierce-through with model updates, Chaos,
mastery small perks, hero tier 6, overall player level + cosmetics + titles + level
leaderboard). The next tower batch is **not built**: `TOWERS_NEXT.md` is a proposal for
Jovan to pick from. Design calls: `DECISIONS.md` #118–#142. **T31 + T38 (the Studio
playtest) stay open**; T60 adds round 4's steps. **Stop before phase 7** and append a
round-4 recap to `RECAP.md` (T61).

**Update (2026-10-08): T31 + T38 + T60 + T70 run as PLAYTEST Runs 1–2 (35 + 27 pass; F1–F4 fixed in e9b0d00 / 34d3606). Closed (#237).**

**Status (2026-10-06): round 4 done — T40–T59, T62–T69 and T68b built and signed off, T61
written (`RECAP.md` "Round 4", #206). 406 specs, all checks green; not playtested. OPEN: T31 +
T38 + T60 + T70 (Tester) — Studio's MCP still reports no Studio; Jovan must restart Studio,
turn on "Enable Studio as MCP server" and reconnect Rojo. Phase 7 not started.**

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
| — | T69 🦖 (done), T68b (done) | review of the towers; Tar Pit fixes + review strings (one Builder run) |
| — | T61 Director (done) | docs + recap; T60/T70 Tester stay open until Jovan flips Studio's MCP switch |

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

### T60. Tester: round-4 steps (run with T31 + T38 when Studio's MCP switch is on) — OPEN
1. Home: PLAY 240 px, Hunt Board on its own row; Hunt Board shows Amber; Profile opens and
   closes with key and X.
2. Easy, K for cash: Linebreaker on a Pachy line; in round 16+ one shot drops more than one
   size (console: sizes dropped per hit); a Mortar never drops more than one.
3. Round 31 (start-round constant): a boss throw on a tower deals half; on the hunter, full.
   Triceratops shows the notched bar.
4. Hard: starts at 850 (#143). Chaos: towers hit softer, gun harder (console values).
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

**T68 done (2026-10-06): b3f04d7 + 921cab2** (405 specs green; Power Grid 156, Skewer 142,
Eagle of the Peak 186, Murmuration 266 vs M = 142, frozen as the round-4 bar, #200). Two Tar
Pit problems left → T68b.

### T68b. Tar Pit fixes + Dino round 15 strings (#201–#204) — DONE (5929270; #206)
Director's figures are from `value.py`'s own `tar_removed` with these cells patched in
(2026-10-06, r31–40, Easy solo traffic).
1. **Sinking reachable (#202):** `Tuning!B132` Tar sink seconds 3 → **1.0**; Fast Sink
   `Tower Upgrades!CC142` 1.5 → **0.5**. Expected: base pit holds a speed-1 dino 1.14 s
   (speed-1 and armoured smallest dinos sink; the 1.2/1.4 ones don't); Dig Site path **56
   sinks/round**; Deep Tar T1 72, T2–T5 98.
2. **Eruption gate (#201):** `Tuning!B130` Eruption every 15 → **10** s (back to #150);
   Bubbling T5 `Burn DPS` `Tower Upgrades!X149` 150 → **80** (= Tar Fire's X148). Expected:
   Bubbling T3 21%, T4 40%, **T5 49% ≤ 50%: met**. If the line prints > 50%, raise B130 by
   1 s at a time up to 13 s (47% at 13, checked); `value.py`'s gate cap stays 15.
3. **Dig Site pay (#203):** `Sink cash` CD150 10 → **2**, CD151 25 → **6**, CD152 25 → **6**;
   `Sink chest cash` CE152 40 → **10**. Expected line: T1 +112/round = 9.3r; T2 +335 = 10.6r;
   T3 +894 = 9.8r. **Bar: each of T1–T3 pays back in 8–15 rounds** — make `value.py` print a
   finding if not (like the Eruption gate), and if a figure misses, move only that tier's CD/CE
   by whole cash until it passes.
4. **Strings (Dino round 15, #204):** `Tower Upgrades!C125:C129` "raw damage, pierce-through"
   → **"raw damage, pierces armour"**; `Towers!B16` → **"Birds of prey: huge range, can't be
   damaged"**; `Shop.client.luau` (hand-written): line ~533 "last-size dinos sink in {n}s" →
   **"the smallest dinos sink in {n}s"**; ~484 Judgement Bolt "shrinks it up to" → **"drops it
   up to"**; ~477 "the more Storm Coils stand" → **"the more Storm Coils you have"**; ~446
   "bomblets split again" → **"bomblets burst again"**. Any shop/ability text that states the
   old Tar Pit numbers (3 s, 150/s, every 15 s) reads from Config, not a literal — check.
5. **Docs:** `TOWERS_NEXT.md` Tar Pit seeds (3 s / 1.5 s / Eruption every 8–10 s) get a
   one-line "as built (T68b)" note with the new numbers; `UPGRADES.md` if it states them.
- **Also bars:** everything T68 listed stays green (405+ specs, audit 0, `threat.py` 0, #72
  pacing floors, `--breaks1` 0, Chaos bars, findings = the four accepted ones and nothing
  new); M still 142; Bubbling T5 > T4 in HP removed.
- **Accept:** Config diff = exactly the cells above (B130, B132, CC142, X149, CD150–152,
  CE152, C125–C129, Towers B16, plus any step-2/3 fallback cells, listed) + the four
  Shop.client strings; a spec that a speed-1 smallest dino sinks in a base pit and a
  speed-1.4 one doesn't; commit message prints the Tar Pit value lines before → after.

### T69. 🦖 Review of the four built towers — DONE (DINO_REVIEW round 15; #204; fixes in T68b)

### T70. Tester: new-tower steps (with T31/T38/T60) — OPEN, waits on Jovan's Studio MCP switch
1. J unlocks all; place each tower; Tar Pit only places on the track.
2. Bites and throws never hit a Falcon Roost or Tar Pit; no repair button on them.
3. Storm Coil: arcs visible; Power Grid with 1 coil vs 3 coils (console damage/range).
4. Judgement Bolt on a boss drops up to 3 sizes; Skewer through a line drops each up to 3.
5. Eruption: dinos in the pool drop 2 sizes every ~10s; a T-Rex too.
6. Tow Line drags a boss back; Murmuration and Eagle of the Peak animate; Hunting Party and
   Tar Totem buffs show on towers in range.
7. Tar Pit (no upgrades): a smallest-size normal-speed dino sinks after ~1s in the pool and
   pays a kill; a fast one walks through; never a boss or Pteranodon. Dig Site T1: +2 cash per
   sink (console); Lucky Finds drops a chest.

### T61. Docs and round-4 recap (Director) — DONE 2026-10-06 (#206); T60/T70 still open
Update `CLAUDE.md` status, `ARCHITECTURE.md` phase table, `VISION.md` (player level,
cosmetics, ranked trophies note for phase 7), and append "Round 4 recap" to `RECAP.md`:
what changed, what to playtest first, the Ask-Jovan list (including the `TOWERS_NEXT.md`
picks), decisions he may want to overturn. Honest status: "statically checked + headless,
not playtested" unless T60 ran. Stop before phase 7.
Round-4 recap must also carry: the four towers' final in-match cost/Amber and the T68/T68b
balance table (M = 142 frozen, #200; Tar Pit sink 1 s, Eruption 10 s, burn 80, Dig Site
cash, #201–#203); T60 + T70 + T31 + T38 as **Jovan's first playtest script, still open**
(Studio's MCP switch); overturnable calls #195, #200–#203 (e.g. a sink time of 1 s,
Dig Site paying ~10 rounds back). Also `CLAUDE.md`'s "Next" line names the switch + Rojo reconnect.

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
