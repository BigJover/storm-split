# Dino Hunters

(Repo and folder still say `storm-split` / `~/Fortnite`, the working name before the
dinosaur theme.)

Co-op (2–10 player) dinosaur-hunting tower defense for **Roblox**, built solo by Jovan as a first game. BTD6-style towers
with three upgrade paths, splitting enemies, and one original twist: the player's weapon *is*
the hero — each weapon type grants an ability and levels on an in-round track and a permanent
mastery track.

Originally designed for Fortnite/UEFN; moved to Roblox because UEFN is Windows-only. The game
design in the PDF still holds; its UEFN-specific sections don't. Old UEFN material is in
`archive/uefn/` — don't use it.

## Files

- `Storm-Split-Design-Doc.pdf` — the game design
- `Storm-Split-Balance.xlsx` — every number. Source of truth.
- `ARCHITECTURE.md` — code structure, ownership rules, phase plan. **Read before changing code.**
- `DIRECTION.md` — how Jovan decides: his taste and past calls. Read before any design call.
- `GAUNTLET.md` — the multi-agent build loop (Director, Builder, Dino agent) and its rules.
- `DECISIONS.md` — design calls made while Jovan was away, for his review.
- `UPGRADES.md` — the approved vision for every tower's paths, tier names and abilities.
  Build tower mechanics to match it.
- `HEROES.md` — the approved hero design: free pick, three upgrade paths per hero about how
  the gun handles and fires. More heroes will be added later.
- `VISION.md` — scale and modes: ~10-player chaotic co-op, difficulty levels, and future
  team-battle and battle-royale modes. Don't write code that blocks them.
- `SETUP.md` — Mac setup: Studio, Rokit, Rojo, MCP
- `src/` — Luau, synced into Studio by Rojo (`default.project.json`)
- `tools/export_constants.py` — spreadsheet → `src/shared/Config.luau`
- `tools/test/` — headless specs (`*.spec.luau`) and their Lune runner (`run.luau`)

## Rules

1. **Never hand-edit `src/shared/Config.luau`.** Change the spreadsheet and re-export.
2. **No gameplay numbers in behaviour code.** They belong in the spreadsheet. Visual-only
   values (colours, part sizes) are fine inline.
3. **Server authoritative.** Clients request; the server validates and acts. Never trust a
   price, damage value or result sent from a client.
4. **One mutator per piece of state** — see the ownership table in ARCHITECTURE.md §4.
   Only `Enemies` touches enemies. Only `Economy` touches cash.
5. **Nothing spawns enemies directly.** Everything goes through `Enemies.enqueue()` and the
   capped queue.

## Commands

```bash
rojo serve                              # live-sync src/ into Studio
python3 tools/export_constants.py       # after any spreadsheet change
tools/check.sh                          # static type-check of src/ (luau-lsp via Rokit)
tools/test.sh                           # headless specs in tools/test/ (Lune via Rokit) + audit
python3 tools/audit.py                  # spreadsheet vs UPGRADES/HEROES/DIRECTION/VISION + dead columns
```

On this Mac `/usr/bin/git` and `/usr/bin/python3` may fail on the Xcode licence; use
`/Library/Developer/CommandLineTools/usr/bin/` instead. No Excel licence: the user edits the
spreadsheet in Numbers and **Export To → Excel** (see SETUP.md). Claude can edit it with
openpyxl directly — the exporter always recalculates formulas itself (pycel, Excel rules),
so no Numbers step.
Verify every spreadsheet change by diffing `Config.luau`.

## Status

Phase 1 written and verified headlessly (map, enemies with splitting and the live cap, Scout
towers, 40-round wave runner, lives, HUD). Confirmed running in Studio 2026-09-28: enemies
follow the track and towers fire.

Phase 2: `Economy` (shared cash + lives), `Shop` (one validated RemoteFunction for
build/sell), build phase with a Start button. Buy/sell/income confirmed in Studio 2026-09-28.
The map starts empty; Starting cash (450) buys 2 Scouts or 1 mid-priced tower. Chiller and
Quartermaster are listed but not sold until their phase 5 behaviours exist.

Pads were dropped the same day at the user's request: towers go **anywhere off the track,
never overlapping**, placed with a ghost preview (`Shared/Placement` is the one rule, used by
the client ghost and enforced by the server). Confirmed in Studio 2026-09-28.

Phase 3 written 2026-09-28 and statically checked, not yet playtested: upgrade buttons in the
tower panel (crossover rule shared via `Shared/Upgrades`), cost added to the sell refund, tier
label, crown at tier 3 and glow at tier 5, and a `Range x` spreadsheet column so range paths
grow range.

Phase 3 playtested and confirmed 2026-09-28. Then the user asked for specialised, named
paths (attack speed, anti-armour, support…) instead of generic +% tracks: the approved design
is `UPGRADES.md`, tier names are in the spreadsheet (Tower Upgrades, column M) and shown in
the tower panel.

Phase 3b written 2026-09-28, not yet playtested: armour (no damage without a piercing
upgrade), boss flag, and the Scout/Sniper/Grenadier abilities — multi-shot, line pierce,
bonus vs armoured/bosses, mark, stun, knockback, burn patches, cluster bomblets, support
auras. Numbers are seeds in the spreadsheet; expect a tuning pass.

Phase 3b playtested 2026-09-28: cash flow good, "a little easy". The user set the scale
vision (`VISION.md`), and phase 3c was written the same day, not yet playtested:
difficulty levels on a new `Difficulty` sheet (Easy = the current baseline, Normal, Hard,
Chaos — HP, density, speed, promotion to tougher tiers, cash, lives), per-player scaling
(`Tuning`, CO-OP), tower owners, a Pops leaderboard, and owner-only selling.

Phase 3c playtested 2026-09-28 ("difficulty works"). Phase 4 written the same day, not
yet playtested: the player is the hero (design doc §02). Three weapon types (Precision,
Sustained, Ordnance), five named tiers each, bought with team cash under the tower crossover
rule; weapons are hotbar Tools; shots are validated and aimed server-side; abilities from
tier 2 — Mark, Overdrive, Airburst. Weapon reach/armour/air/splash and ability strength
are new Weapons-sheet columns.

Gunplay pass (user request): holding a weapon = first person with a crosshair (spread per
shot, hit/kill marker); panels or unarmed = third person with a free mouse; V toggles.
Shots send the camera ray and the server hits the in-range enemy nearest that ray, so
flying enemies are hittable.

Balance watch (design doc): the player must never out-damage their own towers — test round
25 with no towers bought.

Phase 4 v1 and first-person gunplay confirmed in Studio 2026-09-29 ("working perfectly").
The user then redesigned the hero (`HEROES.md`), written the same day, not yet playtested:
picking a hero is free (switch until Start, upgrades refunded); Pistol / Assault Rifle /
Shotgun each have three named upgrade paths about handling and fire modes, not damage;
magazines + reload, server-side recoil, semi/auto/burst, dual guns, pellets vs slug (damage
per shot is conserved across pellets), pierce, ricochet, burn/splash/knockback/mark rounds,
scope, Spin-Up, Belt Fed. Spreadsheet: `Heroes` and `Hero Upgrades` replace `Weapons`.

Hero redesign playtested and confirmed 2026-09-29. Then split hero select (H, by Start —
heroes only, closes on pick) from hero upgrades (U, bottom right) at the user's request:
choosing a hero must not show upgrades.

Phase 5 written 2026-09-29, not yet playtested: Chiller and Quartermaster are for sale.
Chiller chills enemies in range (slow, brittle damage amp, armour strip with Shatter,
lingering with Permafrost) and Freeze pulses hard stops; Quartermaster pays round income
(Yield, Storm Bank interest), drops chests players collect (Airdrop), and discounts upgrades
/ raises refunds for towers in range (Logistics). Also fixed: burning patches dealt no damage
since the hero redesign (Hazards.step was never called).

Camera rule (user, 2026-09-29, for PvP fairness): first person for everyone, always; third
person only while placing a tower, then snap back (gun re-equipped). Menus free the mouse via
Modal buttons instead of switching view. The V toggle was removed.

Phase 5 playtested 2026-09-29 (Chiller slow buffed; Dragon's Breath ignite reworked twice:
now a fire that passes to split children and ticks 35% of the shot). Studio-only K = +1000
cash for testing.

Levels (confirmed in Studio 2026-09-29): heroes +25% and towers +10% damage per
level, one level per 5 rounds cleared, banner + "Lv" on the HUD. Planned: hero XP from pops
drives levels instead (HEROES.md) — levels are already per player.

Phase 6 written 2026-09-29, not yet playtested: `Progression` saves Storm Cores, mastery
per hero and highest round (DataStore; session-only + "offline" status when unpublished, and
a failed load never overwrites a save); mastery badge on the leaderboard. Reworked the same
day to the user's Cores economy (`VISION.md`): solo pays only for a clear (Easy 50 / Normal
100 / Hard 150 / Chaos 200), multiplayer losses pay 5, winners the clear reward; everyone
starts with Pistol + Scout/Sniper/Grenadier; Rifle/Shotgun 75, Chiller 100, Quartermaster
150 Cores; you can only place towers you own but can upgrade anyone's. Competitive buy-ins
(10-20, pot split 72/23/5 in battle royale) come with the battle modes. Level 10/15 ability variants deferred (user choice).
Studio keys: K cash, J cores + unlocks (disables saving for that session).

Home screen (user request, confirmed in Studio 2026-09-29): `Main` is now a match
loop — Lobby (home screen, no characters, host picks mode/track/difficulty, Play) → Building
→ Playing → result screen with Cores earned → board reset → Lobby. Unlocks, mastery and hero
picks survive the reset. Team Battle / Battle Royale show as coming soon.

Theme (2026-09-29): **Dino Hunters** — step 1 (reskin) written, not yet playtested: every
tier is its own dinosaur species that **shrinks** one size per emptied HP share instead of
splitting (total HP per species = the old split-chain HP, so balance is unchanged; bosses now
walk). Blocky dino models (`Shared/DinoLook`), hunting names for towers/heroes/abilities,
Amber currency, dirt-trail map. Title and currency live in `Shared/Theme`; internal keys
unchanged. Step 2 (planned, `VISION.md`): dinos bite and shoot towers/players, 100 player
HP (+25 per round), tower HP with knock-out + repair, Field Medic hero, Field Hospital and
Armory towers.

Next: playtest the reskin, then step 2.

## Open issues

- Leak cost is effective HP (BTD6-style), so 40 starting lives is likely too few.
- Scout Range path has range *and* its old damage/rate boosts — likely too strong; trim.
- Folder is still named `~/Fortnite`.
