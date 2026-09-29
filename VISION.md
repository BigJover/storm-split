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

## Theme (tentative, user, 2026-09-29)

The current names are Fortnite-flavoured placeholders and need replacing. Brainrot was
considered and rejected (the meta is played out on Roblox). **Front-runner: "Germ War"** —
enemies are germs, viruses and cells that divide when hit (the split mechanic as mitosis);
towers are immune cells and medicine; heroes are tiny scientists. The user is researching
current and upcoming Roblox metas and may replace it. Nothing is renamed until the theme
is final. Other options considered: weather (storm cells split), slime lab, asteroid
defence, candy.

## Storm Cores economy (user, 2026-09-29)

Cores are the permanent currency: they buy tower and hero unlocks and hero mastery.

**Casual modes (no buy-in, only pay out):**
- Solo: pays only for **clearing a track** — Easy 50, Normal 100, Hard 150, Chaos 200. Each
  track is its own level with its own rewards.
- Multiplayer: losers get a flat **5**; winners get more (co-op: the clear reward above).
- Casual battle royale: 1st gets a lot, 2nd a decent amount, 3rd slightly more than
  participation (numbers TBD).

**Competitive modes (stakes):** every player pays a **10–20 Core buy-in** into a pot.
- Team modes: the pot is split among the winning team.
- Battle royale: 1st gets **72%**, 2nd **23%**, 3rd **5%** of the pot, each rounded down.
- Competitive always pays more than the casual version.

**Unlocks (Cores):** everyone starts with the Pistol hero and the Scout, Sniper and
Grenadier towers. Other heroes and towers — Chiller, Quartermaster and everything added
later — are bought with Cores. You can only place towers you own, but you can pay to
upgrade a teammate's tower of a type you don't own.

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
