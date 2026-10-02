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
- **No pop-up may ever trap a player** (Jovan, 2026-10-01, after one did). Every panel or
  screen must: fit on any window size with its close control always visible (scroll, scale
  or shrink, never overflow); free the mouse while it's open; close with the key that opened
  it and with an on-screen X; and close on every match-state change except the ones
  `Shared/PanelRules` allows. Anything a player must click (Play, Start) must stay reachable
  for every player who needs it, not just the host.
- **Everyone starts fair:** no free starting towers beyond the free roster; heroes picked
  for free once owned; you can only place towers you own but may upgrade a teammate's.
- **Numbers belong in the spreadsheet**, never in code. Visual-only values may live in code.
- Effects he's tuned by feel: Chiller/Tranq slow buffed (base 40%); Dragon's Breath is a
  small one-tick burn (35% of the shot), not an automatic kill. Expect him to prefer
  "small, readable effect" over "big automatic effect".

## Mastery perks and hero XP (Jovan, 2026-10-02)

- **Mastery ability perks scale up:** the objectively stronger perk sits at level 15, the
  lesser one at level 10. If two are equal, make one edge out the other.
- **Designed for PvP too:** "nothing extremely strong, just something that gives a somewhat
  fair advantage". An edge, never a fight-winner; no hard crowd control on hunters.
- **Hero XP from pops is good, but small**, so nobody farms pops, and it **only counts at
  the end**: XP is banked when a round is finished, to entice players to finish rounds and
  games.
- **Saving and publishing can wait** until the game is published. Don't build for it now.

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
- He wants builds **tested in Roblox Studio whenever that's possible** (2026-10-01), by a
  Tester agent through Studio's MCP server (`GAUNTLET.md`). Headless specs don't replace it.
- Be honest about what was and wasn't verified. Never claim something works in Studio
  unless it was run there.
