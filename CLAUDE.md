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
```

## Status

Phase 1 written and verified headlessly (map, enemies with splitting and the live cap, Scout
towers, 40-round wave runner, lives, HUD). Confirmed running in Studio 2026-09-28: enemies
follow the track and towers fire.

Next: phase 2 — `Economy` (cash + lives), the shop over validated RemoteEvents, and
ProximityPrompts on pads. Phase 2 must also delete the three free Scouts in
`Main.server.luau` (temporary test scaffolding): players start with an empty map and enough
cash for 2 Scouts or 1 mid-priced tower (Starting cash = 450).

## Open issues

- Spreadsheet assumes 14s walk time; real track is ~44s. Reconcile after measuring.
- Leak cost is effective HP (BTD6-style), so 40 starting lives is likely too few.
- Spreadsheet has no range multiplier, so "Range" paths don't increase range yet.
- Enemy names are Fortnite-flavoured placeholders; needs an original theme.
- Folder is still named `~/Fortnite`.
