# Storm Split — Vision

What the game is growing into (user direction, 2026-09-28). `UPGRADES.md` covers the towers;
this covers scale, difficulty and modes. Build toward it; don't paint the code into a corner.

## Open and chaotic co-op

- **Up to ~10 players** in one match, all building and fighting on the same map. The more
  players, the more enemies — it should feel open and chaotic, not like a solo game with
  spectators.
- **Difficulty levels.** The current balance is **Easy** — the baseline. Harder levels scale
  enemy **density** (more enemies in the same time) and **troop difficulty** (tougher enemy
  tiers show up sooner), plus HP, speed, income and lives. Numbers live on the spreadsheet's
  `Difficulty` sheet.
- **Player-count scaling** on top of difficulty: every extra player adds enemy density, a bit
  of HP, and starting cash to the shared pot (spreadsheet `Tuning`, CO-OP).

## Future battle modes

**Team battle.** Two or three teams, each with its own side of the map and its own track.
Players can cross onto other sides, but can only build towers on their own team's side.
Teams attack each other's towers; the focus is surviving longer than the other teams.

**Battle royale.** Every player for themselves. Winner is whoever gets the most **pops**
(kills credited to their towers).

## What the code needs for those modes

Some of this is cheap now and expensive later, so it's built early:

| Need | Status |
|---|---|
| Every tower knows who built it (owner) | ✅ phase 3c |
| Pops credited per player (leaderboard) | ✅ phase 3c |
| Difficulty and player-count scaling | ✅ phase 3c |
| Towers with HP that can be damaged and destroyed | later (battle modes) |
| Cash per team / per player instead of one pot | later — `Economy` is the only cash owner, so this is one module's change |
| Map sides: build zones per team, several tracks | later — `Shared/Placement` already decides where building is allowed; zones become one more check |
| Network scale for 10 players (ARCHITECTURE.md §7): clients move enemy copies locally | measure first with Studio's multi-client test |
