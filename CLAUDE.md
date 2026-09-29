# Storm Split

Co-op (2–4 player) tower defense for **Roblox**, built solo by Jovan as a first game. BTD6-style towers
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
- `UPGRADES.md` — the approved vision for every tower's paths, tier names and abilities.
  Build tower mechanics to match it.
- `SETUP.md` — Mac setup: Studio, Rokit, Rojo, MCP
- `src/` — Luau, synced into Studio by Rojo (`default.project.json`)
- `tools/export_constants.py` — spreadsheet → `src/shared/Config.luau`

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
```

On this Mac `/usr/bin/git` and `/usr/bin/python3` may fail on the Xcode licence; use
`/Library/Developer/CommandLineTools/usr/bin/` instead. No Excel licence: the user edits the
spreadsheet in Numbers and **Export To → Excel** (see SETUP.md). Claude can edit it with
openpyxl directly — the exporter recalculates formulas itself (pycel), so no Numbers step.
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

Next: playtest 3b, then phase 4 — the player character as the hero with its own upgrade
track, weapons and abilities (separate from tower paths). Build each mechanic where it
fits, keeping to the vision in `UPGRADES.md`.

## Open issues

- "14s walk time" in the spreadsheet's round length: measured 2026-09-28, rounds end ~14s
  after the last spawn when nothing leaks, so it holds as *clear time*; the full ~44s walk only
  matters for leaks. Relabel the note at Rounds!A48 next time the sheet is edited.
- Leak cost is effective HP (BTD6-style), so 40 starting lives is likely too few.
- Scout Range path has range *and* its old damage/rate boosts — likely too strong; trim.
- Enemy names are Fortnite-flavoured placeholders; needs an original theme.
- Folder is still named `~/Fortnite`.
