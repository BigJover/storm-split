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

## Theme: Dino Hunters (user, 2026-09-29)

The game is **Dino Hunters**. Enemies are dinosaurs; the player is a dinosaur hunter; towers,
weapons and abilities are hunting gear. The permanent currency is **Amber** (was Storm
Cores). Chosen from the user's research on Roblox metas (brainrot rejected as played out;
germs, weather, slime, asteroids, candy considered).

**Each tier is its own species**, and a dino doesn't turn into a different enemy when hit:
it **shrinks one size** (same species, lower stats) until it's gone at its smallest size.

| Tier | Species | Notes |
|---|---|---|
| 1 | Compy | tiny, one size |
| 2 | Raptor | |
| 3 | Pachycephalosaurus | |
| 4 | Ankylosaurus | armoured |
| 5 | Gallimimus | fast |
| air | Pteranodon | flying |
| boss | Triceratops | ground boss |
| boss | T-Rex | ground boss (the finale) |

Towers: Hunting Blind (Scout), Longshot Perch (Sniper), Mortar Pit (Grenadier), Tranq
Station (Chiller; slow = tranquilizer darts), Supply Camp (Quartermaster). Heroes: Tracker
(pistol), Big Game Hunter (rifle), Brush Beater (shotgun). Abilities: Tracking Dart (was
Mark), Rally Cry (Overdrive), Flare Strike (Airburst).

**Build order (user):** step 1 reskin — names, colours, dino shapes, the shrink rule, balance
kept. Step 2 combat — below.

### Step 2: the dinos fight back (built 2026-10-01, headless-tested, not yet playtested; see `RECAP.md`)

- Dinos **bite** towers and players within reach as they walk the track. **Mid and high
  tiers also have ranged / projectile attacks**; the higher the tier, the deadlier. Smaller
  sizes hit softer.
- **Players have 100 health** and heal a flat **25** for every round cleared. Death =
  respawn after Respawn time.
- **Towers have health.** At 0 a tower is **knocked out until repaired**: it stops working
  but keeps its upgrades. Players repair towers from the tower's upgrade menu, for cash.
- More ways to heal and protect: a new **healer hero class** (Field Medic, with a healing
  ability), a new **healing tower** (Field Hospital), and a new **support tower** (Armory)
  that gives towers and players in its radius damage resistance.

## Amber economy (user, 2026-09-29; was "Storm Cores")

Cores are the permanent currency: they buy tower and hero unlocks and hero mastery.
Mastery 10 and 15 give small ability perks, sized to stay fair in the battle modes
(`HEROES.md` "Mastery"); hero XP is per match and never saved.

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

**Daily Haul and Bounties (round 2, 2026-10-01; built, headless-tested, not yet playtested).**
They live on the **Hunt Board** (G, home screen only). All numbers are on the `Daily Haul`
and `Bounties` sheets and the REWARDS levers on `Tuning`.
- **Daily Haul** (the log-in reward): one claim per UTC day, 5 / 5 / 10 / 10 / 15 / 15 / 40
  Amber over seven days (100 a week), then it loops. A missed day pauses it; it never resets.
- **Bounties** (earned by playing matches): 3 daily (10 + 15 + 20 = 45 Amber) and 3 weekly
  (40 + 60 + 80 = 180 Amber). One free Swap per day and per week. A finished bounty is
  claimed on the Hunt Board; one left unclaimed is paid at the reset.
- **Logging in never beats playing.** The exporter refuses a sheet that breaks any of these:
  each Haul day is below the Easy clear reward; the Haul week is at most 2× the Easy clear;
  the daily bounties together are below the Easy clear; each weekly is below the Chaos
  clear and the weeklies together are at most the Chaos clear (DECISIONS #71).
- A perfect week adds up to 595 Amber (Haul 100 + dailies 315 + weeklies 180), of which
  only the Haul's 100 comes from logging in (DECISIONS #81).

## What the code needs for those modes

Some of this is cheap now and expensive later, so it's built early:

| Need | Status |
|---|---|
| Every tower knows who built it (owner) | ✅ phase 3c |
| Pops credited per player (leaderboard) | ✅ phase 3c |
| Difficulty and player-count scaling | ✅ phase 3c |
| Towers with HP that can be damaged and destroyed | ✅ Step 2 (dinos trample them and players repair them; players damaging towers comes with the battle modes) |
| Cash per team / per player instead of one pot | later — `Economy` is the only cash owner, so this is one module's change |
| Map sides: build zones per team, several tracks | later — `Shared/Placement` already decides where building is allowed; zones become one more check |
| Network scale for 10 players (ARCHITECTURE.md §7): clients move enemy copies locally | measure first with Studio's multi-client test |
