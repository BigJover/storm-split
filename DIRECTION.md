# How Jovan decides — a digest for the agents

Everything here comes from Jovan's own decisions while building the game (Sept 2026). When
a question isn't answered by `VISION.md`, `UPGRADES.md` or `HEROES.md`, decide the way these
point, then log it in `DECISIONS.md`.

## What the game is

- **Dino Hunters**: co-op (up to ~10 players) dinosaur-hunting tower defense on Roblox,
  BTD6-inspired but original. "As open and chaotic as possible." Future PvP modes (team
  battle, battle royale) must not be blocked by today's code.
- Players are **hunters**; enemies are **dinosaurs**; towers, weapons and abilities are
  **hunting gear**. Each tier is its own species; dinos **shrink** (one enemy, smaller,
  weaker) rather than split. Currency: **Amber**.

## Design taste

- **Specialised, named upgrades**, BTD6-style — never a boring "+30%". Each path has a
  role (attack speed, anti-armour, support, control, economy); tiers have names.
- **Hero upgrades are about handling** (reload, recoil, fire modes, special rounds), not
  raw damage. Power growth comes from levels.
- **Towers and heroes must both stay useful.** A hero must never out-damage the best tower
  (the exporter checks). Levels (+25% hero / +10% tower every 5 rounds) keep pace with HP.
- **Clean, uncluttered UI.** Separate screens for separate jobs (hero select vs upgrades;
  unlocks split into Heroes and Towers). Show prices, discounts and what an upgrade does in
  plain words.
- **PvP fairness:** first person for everyone, always; third person only while placing a
  tower. The mouse cursor must be visible whenever it's free.
- **Everyone starts fair:** no free starting towers beyond the free roster; heroes picked
  for free once owned; you can only place towers you own but may upgrade a teammate's.
- **Numbers belong in the spreadsheet**, never in code. Visual-only values may live in code.
- Effects he's tuned by feel: Chiller/Tranq slow buffed (base 40%); Dragon's Breath is a
  small one-tick burn (35% of the shot), not an automatic kill. Expect him to prefer
  "small, readable effect" over "big automatic effect".

## Economy (his numbers)

- Casual: solo pays only on a track clear (Easy 50 / Normal 100 / Hard 150 / Chaos 200
  Amber); multiplayer losers 5, winners the clear reward. Competitive (phase 7): 10–20
  Amber buy-in pot, battle royale split 72/23/5 rounded down.
- Unlocks: Tracker + Hunting Blind / Longshot Perch / Mortar Pit free; Big Game Hunter 75,
  Brush Beater 75, Tranq Station 100, Supply Camp 150.

## How he works

- He tests in Studio and reports briefly ("works", "perfect", "X is off"). He wants short
  recaps: what changed, what to try.
- He likes being asked before big design changes, and approves quickly. When he's away
  (the gauntlet loop), decide in line with this file and log it instead.
- He wants every verified step committed and pushed.
- Be honest about what was and wasn't verified. Never claim something works in Studio
  unless it was run there.
