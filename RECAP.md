# Recap for Jovan: Step 2 + polish (2026-09-30 → 10-01)

**Honest status:** everything below is statically checked and headless-tested (130 specs,
`audit.py --strict` 0, `threat.py` 0). **None of it has been playtested in Studio.** All
numbers are seeds in the spreadsheet. The full reasoning is in `DECISIONS.md` (#1–#51).

## What was built

**Step 2: the dinos fight back**
- Every dino bites. The mid and high tiers also throw things (Skull Toss, Spike Flick, Gravel
  Spray, Stone Drop, Horn Toss, Bone Spit). Throws are dodgeable: they don't home in, and a
  red-orange ring marks where each one lands.
- Hunters have 100 HP and heal 25 per round cleared. Death means a 3s respawn and nothing
  else. A private hit line shows what hit you ("Raptor · Slash −4").
- Towers have HP. At 0 a tower is **Trampled**: it tips over, goes dark and stops working.
  Anyone can repair it from the tower panel. A damaged tower sells for less.
- **Field Medic** hero (lever-action carbine; Triage Kit heals). **Field Hospital** tower:
  heals, revives, med kits, Rescue Beacon, Last Stand. **Armory** tower: resistance, thorns,
  Gunsmith buffs, Outfitter handling.

**Polish**
- Headless test harness, a spreadsheet ↔ design-doc audit and a threat model.
- Amber payout fixed: it now counts the players who took part, not the saves that loaded.
- Every tower and hero path was checked against UPGRADES.md / HEROES.md.
- Theme pass: Tranq looks and talks like sedation, not ice. Old ability names are fixed in
  the text. Every tower has its own silhouette.

## Playtest first

1. Easy, rounds 1–10: towers hugging the lane get bitten, and towers halfway between lanes
   don't.
2. Round 11+: a Pachy wave near lane-hugging towers. Can you dodge the rings?
3. **Round 31 on Easy:** boss throws can trample mid-gap towers. Is that too harsh? (#44)
4. Studio keys: **K** +1000 cash, **J** +100 Amber (no saving that session), **L**
   knocks half the HP off the nearest tower. Use L to test repair, the hospital's heal and
   revive, and Last Stand (it flashes green).
5. Field Medic Triage Kit, Armory resist, the Hospital's med kits and Rescue Beacon respawn.

## Ask Jovan (nothing here was changed without you)

- **Renames of your names (#27):**
  - Lives → Fence (the HUD says "Camp lives" for now, #22)
  - Pops → Trophies
  - Storm of Steel → Meteor Shower
  - Skybreaker → Extinction Round
  - Care Package → Chopper Drop
  - Command Center → Base Camp
  - Forward Base → Forward Camp
  - Siege / Anti-Materiel / Siege Gun → Trophy / Bone Breaker / Punt Gun
  - Tactical Spotter → Game Spotter
  - Big Game Hunter path Tactical → Stalker
  - Breacher / Street Sweeper → Point Blank / Thicket Sweeper
  - Role Ordnance → Close range
  - Quick Mark → Quick Dart
  - Hibernation → Deep Sleep
  - Crack Armor → Find the Gap

  **Done (Jovan, 2026-10-01):** Skybreaker → Extinction Round, Crack Armor → Find the Gap,
  Quick Mark → Quick Dart, Storm of Steel → Meteor Shower. The rest are still open.
- **Tier-5 glow (#33):** **Done (Jovan):** stays full Neon (#53).
- **Linebreaker "×2 damage" (#17):** ×2 over tier 3 (as it is, 6.41) or over tier 4 (8.84)?
- **Dragon's Breath ground patch (#37):** it's now 3 studs wide instead of 1. The ignite you
  tuned is unchanged.
- **Horn Toss boulder (#40):** it rolls along the ground but only hurts at the ring. If that
  feels unfair, make it a lob.

## Decisions you may want to overturn

- #3 / #42–43: attack numbers. The mid-tier throws were cut so mid-gap towers survive Easy.
- #5: projectiles never home in.
- #6: dinos hit the nearest target, players and towers alike, and never stop walking.
- #7: death costs nothing but the respawn wait.
- #8: tower HP values, +15% per tier bought.
- #10 / #35: repair costs 30% of what went in × the HP missing. Selling a damaged tower
  subtracts the repair price.
- #12: resistance doesn't stack and is capped at 60%.
- #19: the Amber payout counts the players who took part.
- #21: the tower state is called "Trampled", because "Knockout" is the Tranq's good effect.
- #39: a private hit-notice line for the hunter who was hit.
- #31: Eye in the Sky's aura is map-wide.
- #45: Last Stand saves one tower per round per hospital.
- #49: Hip Fire (now Runaway Lever) is rate ×1.6 in total, not ×1.92.
- #25 / #48 / #50: renames of names the loop coined: Muzzle, Belt Pouch, Triage Tent, Hand
  Loads, Master Gunsmith, Piercing Rounds, Recoil Pads, Rescue, Camp Rations, Smelling Salts,
  Pack Mules, Runaway Lever, Skull Toss, Horn Toss, Bone Spit.

**Also done:** T16d, the Jaw Lock strap is now (185,100,45) so it reads apart from every dino's
head and jaw (#51). The looks spec now fails on the old colour.

## Fixed after the recap (2026-10-01, from Jovan's playtest)

- Unlocks & Mastery stayed open after pressing Play; now every panel closes on match-state
  changes (`Shared/PanelRules`, with a spec). Hero upgrades can't be bought outside a match
  (they were carrying into the next one).
- Panels can't trap you any more: the row list scrolls inside a box capped at about half the
  screen, so the X is always visible; the panel narrows on small screens; the home screen
  scales to fit so Play is always reachable; non-host players get a free mouse on the home
  screen too.

---

# Round 2 recap for Jovan: balance pass + Hunt Board (2026-10-01)

**Honest status:** everything below is statically checked and headless-tested (214 specs,
`audit.py --strict` 0, `threat.py` 0, every `value.py` bar met). **None of it has been
playtested in Studio.** You asked for Studio testing by a Tester agent: the role and its
script are ready (`PLAN.md` T31), but Studio's MCP server shows no Studio yet. It needs one
switch from you (first item under "Ask Jovan"). All numbers are in the spreadsheet. The full
reasoning is in `DECISIONS.md` (#54–#96).

## What was built

**Balance pass (spreadsheet only; each change is backed by a model, `tools/value.py`)**
- **Supply Camp upgrades pay for themselves now.** Before, a Yield tier took 51 / 88 / 162 /
  233 / 99 rounds to earn back its price, and Airdrop 38 / 88 / 101 / 233 / 101. Now Yield
  takes about 9.7–9.9 rounds (Amber Vault 6.9) and Airdrop 8.0. How: the camp's upgrades
  cost less (1,600 / 2,560 / 4,096 / 6,554 / 10,486) and pay more (#56, #73).
- **The three difficulty cliffs are smoothed** by showing each new species a few rounds
  early (dino counts in rounds 7–12, 17–20 and 31–39; no cash change, #72):
  - Round 10 → 11: the DPS you need jumped ×4.84, now ×2.02 (kept on purpose as the "first
    armour and air" moment, #77).
  - Round 20 → 21: ×2.32, now under ×1.5. Round 30 → 31: ×2.81, now ×1.53.
  - Hardest round, cash you have against cash you need (1.0 = just enough): Normal solo
    0.66 → 0.78, Hard solo 0.48 → 0.59, Chaos with 4 hunters 0.34 → 0.43. Easy solo stays
    at 1.0 or better until round 32, then tightens to 0.86 before the finale.
  - Round 39 has 10 Triceratops, not 12, so the T-Rex round is the hardest one (#78). The
    last ten rounds have 11.6% less total dino HP than before.
- **Nothing else changed.** Difficulty cash, hero levels, repair cost and Amber prices stay
  (#58, #60, #61, #72). The Tranq and Concussion tiers that looked weak are control tiers;
  the model was taught that instead of buffing them (#74).

**Hunt Board (new screen on the home screen, key G)**
- **Daily Haul:** claim once a day: 5, 5, 10, 10, 15, 15, then a 40-Amber **Big Haul** (100
  a week), then it starts again. Missing a day pauses it and never resets it (#64).
- **Bounties:** 3 daily (10 + 15 + 20 Amber) and 3 weekly (40 + 60 + 80), earned in matches:
  take down dinos, reach a round, build, upgrade, repair, use your ability, clear a track.
  One free **Swap** a day and one a week. A finished bounty shows a short "Bounty ready"
  line in the match; you claim it on the board. Unclaimed ones are paid at the reset.
- **Logging in never beats playing:** the exporter refuses a sheet where a Haul day reaches
  the Easy clear reward, or the daily bounties together do (#71).
- **It can't trap you:** opens and closes with G, the home button and the X; only on the
  home screen; closes when Play is pressed; PLAY stays in reach; it scrolls, then shrinks,
  to fit a small window.

## Playtest first

1. Open Studio, press Play, press **G** on the home screen. Close it three ways: G, the
   X, the Hunt Board button.
2. Claim today's Haul. Your Amber should go up by 5. Swap one daily bounty.
3. Play a match on Easy and finish a bounty (building 6 towers is the easy one if you have
   Pitch Camp). Watch for the "Bounty ready" line, then claim it back on the home screen.
4. Rounds 10–12, 20–22 and 30–32 on Easy: do they still feel like walls, or like steps?
5. Build a Supply Camp and buy its first upgrades. Does it feel worth it by round 20?
6. Make the Studio window small with the board open. Can you still see the X and PLAY?
7. Round 1's list above still stands (dino attacks, repair, Medic, Hospital, Armory).

## Ask Jovan

**New in round 2**
- **Turn on Studio's MCP server** so the Tester agent can playtest for you: in Studio,
  Assistant Settings → Manage MCP Servers → "Enable Studio as MCP server".
- **Publish the place to Roblox** when you want progress to really save. Until then Amber,
  unlocks and the Hunt Board last only for the session (`SETUP.md`).
- **Unlocking everything in about a week (#81):** a player who logs in and finishes every
  bounty earns up to 595 Amber a week; all unlocks cost 725. Too fast?
- **Patch Job counts:** repair 2 trampled towers (daily) / 10 (weekly). No model can say
  how often towers get trampled; tell us if these are too many or too few (#80).
- **PLAY button size:** it's narrower (142 px, was 200) to fit the Hunt Board button in the
  same row (#89).
- **Amber balance on the board:** the board covers your Amber line while it's open; you
  see "+15 Amber" float up instead. Want the balance shown on the board? (#90)
- **Small windows and phones:** nobody has seen the board on one yet.
- **Starting cash per difficulty (#72):** Hard and Chaos are still tight at round 11 (0.59
  and 0.43). If they feel impossible, the clean fix is more starting cash on those levels.
  It needs a small code change, so we're asking first.
- **Empty mastery levels (#61):** levels 6–9, 11–14 and 16–19 give nothing. Small perks,
  cosmetics later, or a shorter ladder?
- **Hunt Board names:** Hunt Board, Daily Haul, Big Haul, Bounties, Swap, and the bounty
  titles (Compy Sweep, Raptor Cull, Deep Trail, Tyrant's End…). Say if any should change.

**Still open from round 1**
- The remaining renames (#27): Lives → Fence, Pops → Trophies, Care Package → Chopper Drop,
  Command Center → Base Camp, Forward Base → Forward Camp, Siege / Anti-Materiel / Siege Gun
  → Trophy / Bone Breaker / Punt Gun, Tactical Spotter → Game Spotter, Tactical → Stalker,
  Breacher / Street Sweeper → Point Blank / Thicket Sweeper, Ordnance → Close range,
  Hibernation → Deep Sleep.
- Linebreaker "×2 damage" (#17): ×2 over tier 3 or over tier 4?
- Dragon's Breath ground patch (#37): 3 studs wide instead of 1.
- Horn Toss boulder (#40): rolls along the ground but only hurts at the ring.
- Round-31 boss throws (#44): can trample mid-gap towers. Too harsh?
- A full lobby's heroes may carry rounds 1–10 without towers (#58). Watch for it in co-op.

## Decisions you may want to overturn

- #64: a missed day pauses the Daily Haul instead of resetting it.
- #66: boss bounties (Triceratops, T-Rex) count for every hunter in the match.
- #67: no paid Swaps.
- #68: resets at 00:00 UTC, weeklies on Monday; finished bounties are paid if unclaimed.
- #77: the round-11 jump (×2.02) is kept as a teaching moment.
- #80: "Clean Sweep" (clear any track) is a daily bounty, the one that needs a full clear.
- #85: Gear Check counts ability uses only while a round is running.
- #88: no tooltip on the Hunt Board button. #90: the board covers the mode, track and
  difficulty cards while it's open.
- #93 / #94: bounty text says "Take down", never "Pop"; the toast says "Bounty ready".

## What's next

1. **T31, the Studio playtest** by the Tester agent, as soon as the MCP switch is on. Its
   bugs get fixed before anything new.
2. Your answers to the lists above.
3. **Phase 7** (team battle, battle royale, buy-ins). Not started.

---

# Round 3 recap for Jovan: mastery ability perks + hero XP (2026-10-02)

**Your direction (2026-10-02):** "for hero ability we need the objectively stronger one at
level 15 and the less strong one at level 10 if they are the same pick one to make it edge
out the other so that it scales, with in mind that this is designed to be pvp as well so
nothing extremely strong just something that gives a somewhat fair advantage, xp from pops
is good just make sure it is small so that players dont just farm pops and have it only
count at the end enticing players to finish rounds/games saving is fine and we can deal with
that later when it is published"

**Honest status:** everything below is statically checked and headless-tested (245 specs,
`audit.py --strict` 0, `threat.py` 0, `value.py` no new findings: its three pacing notes
from round 2 remain). **None of it has been playtested in Studio.** The Tester still can't run: Studio's MCP server shows no Studio, and
Rojo has been disconnected in your Studio since the afternoon of 2026-10-01, so **your
Studio is still running the code from before round 2** until you reconnect it (three steps
under "Ask Jovan"). All numbers are in the spreadsheet. The reasoning is in `DECISIONS.md`
(#97–#117). Nothing here needs saving or publishing.

## What was built

**Mastery ability perks (mastery 10 and 15, every hero)**

| Hero | Mastery 10 (the lesser) | Mastery 15 (the stronger) |
|---|---|---|
| Tracker | **Sticky Dart**: Tracking Dart lasts 2s longer (8 → 10) | **Spare Dart**: also marks the nearest dino within 10 studs at 40% strength |
| Big Game Hunter | **Hunting Horn**: Rally Cry reaches 5 studs further (25 → 30) | **Long Rally**: Rally Cry lasts 3s longer (10 → 13) |
| Brush Beater | **Wide Flare**: Flare Strike reaches 1.5 studs further (10 → 11.5) | **Smoulder**: burning ground for 3s, 12% of the strike's damage each second |
| Field Medic | **Far Reach**: Triage Kit reaches 4 studs further (20 → 24) | **Stocked Kit**: Triage Kit heals 10 more HP (40 → 50) |

- **"Stronger at 15" is a rule, not an opinion.** The exporter scores each perk as a share
  of one cast of the ability (10 / 15: Tracker 25% / 40%, Big Game Hunter 20% / 30%, Brush
  Beater 15% / 36%, Field Medic 20% / 25%) and refuses a sheet where 15 isn't above 10 or
  any perk is above 40% (#99).
- **PvP-safe:** perks act on dinos and allies only. None stuns, slows or marks a hunter,
  none adds stun time, none raises gun damage. Each is a small edge on an ability with a
  35–45s cooldown.
- **Nothing was taken away:** mastery 10 still gives the free first upgrade and mastery 15
  the −30% cooldown (#98). The mastery screen shows each perk's name and what it does, and
  now says "Mastery perks boost your ability, never your gun's damage."
- **Marks no longer stack (#106).** The stronger mark wins; a weaker one changes neither its
  strength nor its time. Before, a tower's 3s mark could cut a dart short.

**Hero XP (your own level, per match)**
- **Clearing a round banks 100 XP** for every hunter. 500 XP is a level, so finishing rounds
  alone gives a level every 5 rounds, exactly as before.
- **Take-downs add a small bonus:** 0.25 XP per pop, a quarter of that for teammates' pops,
  **at most 15 a round**. It shows as pending during the round and is **banked only when the
  round is cleared**. Lose the round or leave, and it's gone. Farming pops can never add
  more than 15% (#100).
- **Never behind, never far ahead:** a hunter is never below the old every-5-rounds level and
  never more than one level above it. With the bonus capped every round you reach level 3
  after round 9 (not 10), level 5 after 18, level 9 after 35 (#101).
- **Fair in co-op:** teammates' pops count a little, so a Field Medic who pops nothing still
  earns the bonus; late joiners start on the round's level (#102).
- **Towers still level every 5 rounds** for the whole team. The tower panel now shows
  "Tower level N · +X% damage" (#112).
- **XP resets every match.** Nothing is saved (#103).
- **HUD:** "Lv N", an XP bar, "240 / 500 XP", and the pending bonus; a banner when you level
  ("Hunter level 3 — your shots hit 25% harder") and when towers do.
- **Models follow:** `value.py` and the hero-vs-tower guard now use the level a round is
  really fought at. Hero peak DPS at rounds 1 / 20 / 40, on the old curve [one level ahead]:
  Tracker 24 [30], 47 [59], 114 [143]; Big Game Hunter 16 [20], 31 [39], 76 [95]; Brush
  Beater 35 [43], 68 [84], 165 [206]; Field Medic 5 [6], 9 [12], 23 [29]. Best tower: 751.

## Playtest first

1. **Reconnect Rojo first** (see below), or you'll be testing old code.
2. Home screen → Unlocks & Mastery (M). Press **J** (free Amber, turns saving off), buy a
   hero's mastery to 15. Do rows 10 and 15 read clearly? Does anything get cut off?
3. Play that hero. Tracker: dart a dino in a pack; a second dino nearby should get a
   smaller mark, both for about 10s. Big Game Hunter: Rally Cry about 13s, wider ring. Brush
   Beater: the strike leaves fire for about 3s. Medic: a heal from 40 HP lands on 90.
4. Round 1: watch the XP row. The bonus should climb to 15 and stop; on the clear the bar
   jumps by 100 plus the bonus. Is the text big enough to read?
5. Lose a round on purpose with a bonus pending: it should not be banked.
6. Play to round 10: you should hit level 3 one round before the towers do. Does being a
   level ahead feel like a reward, or is it invisible?
7. Open a tower's panel after round 5: "Tower level 2 · +10% damage".
8. The round-1 and round-2 lists above still stand.

## Ask Jovan

**New in round 3**
- **Three steps so the Tester can playtest:** restart Studio; Assistant Settings → Manage
  MCP Servers → "Enable Studio as MCP server"; reconnect Rojo (`rojo serve`, then Connect in
  the Rojo plugin).
- **"Only count at the end":** we read it as the end of each **cleared round**, because
  levels have to rise during a match. Is that right, or did you mean the end of the game?
- **Competitive buy-in modes (phase 7):** should mastery perks (and the free first upgrade
  and cooldown) be switched off there, so money matches start even?
- **A hunter one level ahead edges past a maxed Longshot Perch** (206 vs 204 DPS, Brush
  Beater at the very end; #110). Your rule is "never the best tower" (751), which holds.
  OK, or should the lead be removed (one lever, `Hero level lead cap`)?
- **The take-down bonus is small on purpose (15 of 115).** Too small to notice? The levers
  are `Pop XP cap per round` and `XP per pop`.
- **Pending-bonus text size:** even shortened it may be small in the HUD row. Say if you
  want it on its own line.
- **Perk names:** Sticky Dart, Spare Dart, Hunting Horn, Long Rally, Wide Flare, Smoulder,
  Far Reach, Stocked Kit. Say if any should change.

**Still open from rounds 1 and 2:** everything under "Ask Jovan" in the two sections above,
most of all the empty mastery levels 6–9, 11–14 and 16–19 (#61), publishing the place, and
the renames (#27).

## Decisions you may want to overturn

- #98: the old mastery 10 and 15 rewards stay next to the new perks.
- #99: no perk may be worth more than 40% of one cast.
- #101: hunters can run at most one level ahead; towers stay on the every-5-rounds curve.
- #102: teammates' pops count at a quarter. #111: a leaver's pops leave the team count.
- #105: Smoulder deals damage, so the promise is now "never gun damage".
- #106: marks don't stack or extend each other; the stronger wins.
- #112: tower level lives in the tower panel, not on the HUD.
- #114 / #115: the final perk names; menus say "hero", matches say "hunter".

## What's next

1. **T31 + T38, the Studio playtest** by the Tester, as soon as Studio is restarted, the MCP
   switch is on and Rojo is reconnected. Its bugs get fixed before anything new.
2. Your answers to the lists above.
3. **Phase 7** (team battle, battle royale, buy-ins). Not started.

# Round 4 recap for Jovan: your answers, built (2026-10-02 → 10-06)

**Your direction (2026-10-02, full text in `DIRECTION.md` "Round-4 answers"):** XP "count at
the end" means a new **overall player level** ("the cap should be infinite for now", "i want a
level leader board", cosmetics and titles, nicer ones spaced out); a solo take-down XP boost
"but dont change it much or at all in multiplayer"; raw-damage towers should **"pierce
through" levels** with "one health pool which have thresholds"; "small perks" on the empty
mastery levels; "more cash for hard; chaos should be nearly impossible relying on player gun
skill"; renames "apply all but change trophies to bones"; Linebreaker ×2; a bigger PLAY; and
"we need more towers… 2x the cost but worth it (some that dont take damage)". Later the same
day you picked all four proposed towers and their tier 5s.

**Honest status:** everything below is statically checked and headless-tested (406 specs,
`audit.py --strict` 0, `threat.py` 0, `value.py` bars met; its findings are four accepted
ones: Big Bore T1, Concussive T5, Ballista Steel Head T1, Saw Tip T2). **None of it has been
playtested in Studio.** The Tester still can't run (Studio's MCP shows no Studio), and Rojo
has been disconnected in your Studio since 2026-10-01, so **Studio still runs pre-round-2
code**. Every number is in the spreadsheet; the reasoning is in `DECISIONS.md` #118–#206.

## What was built

**Quick fixes**
- **Renames applied** (#130): take-downs are **Bones** (leaderboard, "Most bones wins");
  Lives are the **Fence**; Siege → **Big Bore**, plus the rest of the round-1 list. "Trophies"
  is kept free for ranked.
- **Linebreaker** ×2 over Tungsten Core (Damage x 6.41 → 8.84, #131). **Dragon's Breath**
  patch stays 3 studs; Buckshot's new tier 6 (Wildfire Drum) makes it 4 (#132).
- **Hard starts with 850 cash** (Easy/Normal/Chaos 450, #143); Hard still stays below Normal
  every round.
- **UI:** PLAY 240 px with 28 px text; the Hunt Board on its own row; your Amber in the Hunt
  Board header; "+{N} bonus on round clear" on its own line (#138, #155, #157).
- **Softer boss throws on towers:** ×0.3 (hunters unchanged), so a boss's throws alone can't
  trample a mid-gap tower in rounds 31–39 (#154).

**One health pool + pierce-through** (#125–#129, #160–#166)
- Each dino has **one HP pool**; its sizes are thresholds on it. A hit can cross up to *b*
  thresholds: b = tier breaks + a bonus for tower level (only on raw-damage tiers) − the
  species' resist, from 1 to 4. **b = 1 is the old game**, so only raw-damage tiers change
  (Deadeye, Big Bore, Talons, the Ballista, Heart Shot and Thunder Slug).
- **Bosses** (Triceratops, T-Rex) show a thin pool bar with a notch per size.
- The models now count overkill honestly, and break numbers were set so they give back what
  that honesty costs and no more.

**Chaos = gun skill** (#137, #167): towers ×0.6, your gun ×1.5. Towers alone carry 28% of
what Chaos needs; skilled aim 86% to round 30 and 42% in rounds 31–40 ("nearly impossible").

**Heroes**
- **Small mastery perks** on 6–9, 11–14, 16–19 (#135, #175), none touching damage: **Long
  Arms** (pick-up reach +2/4/6), **First Aid** (round-clear heal +5/10/15), **Back in Action**
  (respawn 10/20/30% sooner), **Handyman** (repairs 5/10/15% cheaper).
- **Tier 6 on all twelve paths** (6,400 each; handling and fire modes, never more damage,
  #133–#134): Hot Swap, Heart Shot (scoped shots shrink a dino 2 sizes), Bounce Back, Big Five,
  Endless Belt, Dynamite Rounds, Thunder Slug (2 sizes), Wildfire Drum, Quad Barrel, Rapid
  Response, Bottomless Tube, Lights Out.

**Overall player level** (#118–#124, #177–#187)
- Saved and **uncapped**: each match adds the XP of the rounds you cleared plus a clear bonus
  (Easy 500 / Normal 1,000 / Hard 1,500 / Chaos 2,000), won or lost; leavers get nothing.
  Level n → n+1 costs 500 + 50(n−1), at most 10,000 (level 10 ≈ 6,300 XP, level 100 ≈ 292k).
- **Solo:** take-downs count ×2 toward it (up to 30 a round). Co-op and the in-match hunter
  level are unchanged.
- **Rewards, cosmetics and titles only:** a common cosmetic most levels 2–99 (name colour,
  gun tint, tracer, crosshair, tower flag, banner); a rare + a title every 10 levels to 100
  (hat, gun pattern, hit-marker, trail); legendary animated sets + titles at 150 and 200;
  then a title every 50 levels.
- **Profile screen (P, home screen):** level, XP bar, next rewards, equip rows (equipping is
  Lobby-only). Its **Leaderboard** tab shows the top 50 across servers once published; until
  then (or if the store fails) it falls back to **"This server"**. Your title and badge show
  on the player list.

**Four new towers, all on sale** (#146–#152, #188–#206; final names from the Dino agent)

| Tower | In-match / Amber | Tier 5s you picked | Notes |
|---|---|---|---|
| **Storm Coil** | 400 / 300 | Power Grid, Judgement Bolt, Lightning Rodeo | chain lightning; Power Grid grows with every Storm Coil you have, one alone is weaker |
| **Falcon Roost** | 400 / 200 | Eagle of the Peak, Murmuration, Hunting Party | birds fly out and back; can't be damaged |
| **Tar Pit** | 450 / 250 | Tar Lake, Eruption, Tar Totem | sits on the track; slows, and the smallest dinos sink after 1 s; can't be damaged |
| **Harpoon Ballista** | 500 / 300 | Skewer, Tow Line, Chain Harpoons | heaviest single hit, pierces through a line |

- **"Worth it", measured** (#193, #200): against M = 142, the median cost per damage of the
  released tier 5s in rounds 31–40, a tower that can be damaged must be ≤ 1.25 × M and one that
  can't between 1.25 × and 2 × M ("somewhat weaker"). Result: Power Grid 156, Skewer 142,
  Eagle of the Peak 186, Murmuration 266. All pass.
- To get there (#194–#195): Storm Coil Damage 4 → 6 and cost 550 → 400; Ballista rate 0.4 →
  0.5 and cost 600 → 500; Murmuration Damage x 3.1 → 4.4, Eagle 13.03 → 12.
- **Tar Pit is judged as a control tower** (#198, #201–#203): Eruption every 10 s, bubbling
  burn 80/s at tier 5, so one pit removes 49% of late ground HP (bar 50%). Dig Site pays
  2 / 6 / 6 cash per sunk dino plus a 10-cash chest, about 10 rounds to pay back, like Supply
  Camp.

## Playtest first

1. **Reconnect Rojo** (below), or you'll test old code.
2. Home: bigger PLAY, Hunt Board row with your Amber. P → Profile: level, rewards, equip a
   colour, Leaderboard tab says "This server".
3. Press **J**, unlock the four new towers. Place each; the Tar Pit goes only on the track.
   Bites and throws never hit a Falcon Roost or Tar Pit.
4. K for cash, upgrade each to a tier 5: Power Grid with 1 coil vs 3; Judgement Bolt on a
   boss; Skewer down a line; Eruption every ~10 s; small dinos sinking in the tar.
5. Linebreaker / Big Bore in round 16+: one shot should drop more than one size. A boss shows
   the notched bar.
6. Hard: 850 starting cash. Chaos: does your aim carry it? Rounds 31–40 should feel nearly
   impossible, not unfair.
7. Buy a hero path to tier 6; mastery 6–9 perks.
8. Finish a match: "+N player XP", your level carries to the next match.
9. The round 1–3 lists above still stand.

## Ask Jovan

**New in round 4**
- **Three steps so the Tester can playtest:** restart Studio; Assistant Settings → Manage MCP
  Servers → "Enable Studio as MCP server"; reconnect Rojo (`rojo serve`, then Connect).
- **The 4×-Amber batch:** `TOWERS_LATER.md` proposes Meteor Beacon, Amber Resin Cannon,
  Ranger Station and Spotter Blimp (400–600 Amber). Which ones, and which tier 5s?
- **"Murmuration" or "Sky Swarm"?** You picked Murmuration; the Dino agent says it's hard for
  kids to read or say. Kept unless you say otherwise.
- **Eruption is every 10 s, not the 8 s** in the proposal you picked from. At 8 s one Tar Pit
  would remove about two thirds of late-game ground HP, and it's a tower that can't be
  damaged, which you said should be "somewhat weaker". Still 2 sizes, bosses included.
- **Concussive T5 (Tectonic Slam) is weak** in the models (a known finding). Buff it, and how?
- **Dynamite Rounds** (Special Ammo tier 6, was Powder Tips): splash ×1.5 radius for 6,400.
  Does it feel worth it?
- **Chaos rounds 31–40:** is "skilled aim reaches 42% of what's needed" the right "nearly
  impossible"?
- **Tar Pit sinking:** the smallest dinos sink after 1 s (3 s couldn't happen in any pool).
  Too fast, too slow?

**Still open from rounds 1–3:** publishing the place (saving, the cross-server leaderboard),
40 starting lives (`CLAUDE.md` open issues), and the remaining items in the lists above.

## Decisions you may want to overturn

- #118 / #119: the player level is new and separate from the hunter level; a clear adds a
  bonus 10× the Amber clear reward.
- #121: the reward ladder (commons to 99, rares every 10, legendaries at 150 / 200).
- #124 / #177: the solo take-down boost is ×2, decided per round, player XP only.
- #126: pierce-through is capped at 4 sizes a hit; heroes get no level bonus.
- #133: tier 6 costs 6,400 and never adds damage.
- #137 / #167: Chaos towers ×0.6, gun ×1.5.
- #148 / #193 / #200: the "worth it" bars and M = 142 frozen for this batch.
- #150 / #201: Eruption every 10 s; tier-5 burn cut to 80/s.
- #195: Storm Coil and Ballista cost less in-match than their seeds (400, 500).
- #202 / #203: sink time 1 s; Dig Site pays about 10 rounds back.

## What's next

1. **T31 + T38 + T60 + T70, the Studio playtest** by the Tester, once Studio is restarted, the
   MCP switch is on and Rojo is reconnected. Its bugs get fixed before anything new.
2. Your answers to the lists above, including the 4×-Amber tower picks.
3. **Phase 7** (team battle, battle royale, buy-ins, ranked). Not started. Notes for it: mastery
   perks stay on in competitive modes, other perks may be buffed so money doesn't decide
   matches, and ranked uses a Clash Royale-style **Trophies** system.

---

# Phase 7 recap for Jovan: the battle modes (2026-10-06 → 10-08)

**Your words (2026-10-06):** "make sure everything is play tested and phase 7 is fully done",
then "go with the name changes" (Team Battle → **Camp Clash**, Battle Royale → **Bone Rush**)
and "begin phase 8 when all loose ends on phase 7 are done".

**Honest status:** built, 587 headless specs green (`check.sh`, exporter, `audit.py --strict`
0), and **played in Studio by the Tester** with one client and Studio-only stand-in camps.
Hunter-vs-hunter and anything needing a second real player is your 20-minute script below.
Saved stakes, saved Trophies and the world boards need the place published. Calls:
`DECISIONS.md` #208–#243.

## What was built

- **Camp Clash (team battle):** 2 or 3 camps (host picks), each on its own copy of the track,
  joined by an open crossing strip. You build only in your camp. Every camp gets the same dinos,
  and rounds move together. Shoot a rival camp's towers to **Trampled** (only they can repair).
  Your gun, towers and abilities only ever hurt your own camp's dinos. Camp Fence at 0 = out:
  towers gone, you spectate. Last camp standing wins; after round 40, **Final Stampede**
  repeats the last round harder until one falls.
- **Bone Rush (battle royale):** one camp each (2–10). Most **Bones** wins; the last one alive
  gets +10% Bones. Raiding pays by making rivals leak (no Bones for a knock-out).
- **Hunter vs hunter:** enemy hunters' shots hit at ×0.5, you respawn on your own camp with 3 s
  of **Camo Cover**. No friendly fire, no crowd control on hunters.
- **Casual / Ranked:** Casual pays Amber (Camp Clash win 50 / loss 5; Bone Rush 60/30/10/5).
  Ranked: everyone presses **Ready**, pays a 15 Amber **Entry fee** into the **Amber Hoard**
  (winners split it; Bone Rush 72/23/5), held in a saved escrow and refunded if the server
  dies. Unpublished, Ranked runs as **Practice Hunt** (session Amber, no Trophies).
- **Trophies and arenas:** ±30 in Camp Clash, by placement in Bone Rush; 8 arenas (Fern Gully
  → Rex Kingdom) with floors you can't drop below and a cosmetic on first reach. Trophy board
  (This server until published), Trophies on the player list and a Profile Trophies tab. A
  Ranked leaver loses Trophies as last place.
- **Screens:** battle cards and Hunt Options on the home screen, Ready + Entry fee confirm,
  camps board, kill feed, Inspect on enemy towers (read-only), spectate and Final Stampede
  banners, a results card (placements, Amber with Hoard share, ±Trophies, arena change).
- **Fairness:** heroes' mastery perks are held within 15% of each other (exporter bar); four
  perks were buffed to meet it, none nerfed.
- **Under the hood:** pure rules modules (`BattleRules`, `BattleFlow`, `Matchmaking`, `Sides`,
  `Stakes`, `Trophies`, `SpawnQueue`, `Ledger`, `RoundFlow`, `TrophyBoard`) with specs; co-op
  is "one camp" and its specs never changed.

## How it was verified

- **Headless:** 587 specs; exporter refuses bad buy-ins, splits, arena floors, PvP levers.
- **Studio, Tester Run 1** (round 4 build): 35 pass, 3 fail (F1–F3, fixed). Covered the
  rounds 1–4 playtest: towers, Tar Pit, boss bar, tier 6, player level, Profile.
- **Run 2:** 27 pass, 1 fail (F4: a round whose last dino breaks the Fence counted as a clear;
  fixed). First solo battles with stand-ins.
- **Run 3 (the T86 solo script):** 41 pass, 2 minor cosmetic fails (F5 banner over the
  results card, F6 spectate banner over the camps board; fixed in T86b). **Passed in Studio:**
  co-op regression; home cards, Casual/Ranked, Ready + Entry fee + Practice line; build
  refusals; stand-in tower to Trampled + kill line; Inspect; own shots never hurt own towers;
  spectate rules; Practice stake out and Hoard back, Trophies unchanged; Bone Rush 10 seats
  (peak 125 of 130 dinos, worst frame 8.37 ms), ranking by Bones; player list; no console errors.
- **Run 4 (T86b re-check of c559cdc):** all seven T86b checks PASS in Studio — no banner over the results card (F5), spectate banner bottom-centre with the camps board readable (F6), "Nth place" in both modes, battle results ~15 s, "Amber +33 (30 payout + 3 Amber Hoard)", "HUNT OPTIONS", co-op round-trip with 8 s results; console clean. One new minor finding, F7: the camp-out banner shows top-right over the XP bar instead of below the camps board (queued with Phase 8 batch 1). The Ranked Bone Rush check ran with 2 seats (the 3-seat run was Casual Hard).
- **Headless only:** the survivor bonus (not confirmed in Studio), your-chest-only, the F4
  exact case, Final Stampede (battles ended by round 9–11), everything multi-client.

## Your 20-minute script (Studio → Test → Clients and Servers)

1. **2 players.** Press J in each window. Host: Camp Clash, Casual, 2 camps, PLAY.
2. Walk to the other camp: shoot the other hunter (half damage, "Tranqed by…", respawn at
   their camp, Camo Cover countdown). Try to build/upgrade/sell their tower (refusal text).
3. Upgrade your teammate's tower (3 players, same camp): allowed.
4. Non-host presses **Ready** + confirms the Entry fee; PLAY lights at the minimum.
5. Mid-battle, start a 3rd client: it waits with "A hunt is on — you'll join the next one."
6. Ranked (Practice) match, then close one client mid-match: no Trophy change in Practice.
7. 3 players, 3 camps: are teams fair? How does raiding feel? Is the results card readable
   in 15 s? Try a small window: every panel keeps its X visible and its key closes it.

**After publishing (can't be tested now):** real Entry fees and escrow refunds after a
shutdown, saved Trophies and arenas, the world Trophy and level boards, 10 real players'
network load and hit fairness under real latency.

## Ask Jovan

- **Battle difficulty:** on Normal every camp's Fence goes 30 → 11 in round 8–9, so battles end
  by round 9–11 and Final Stampede never comes. Right for a short, sharp battle, or should
  battles get more Fence / fewer dinos?
- **Competitive edge (report only):** a maxed hunter vs mastery 0 on the same hero: Tracker
  57%, Big Game Hunter 84.9%, Brush Beater 82.8%, Field Medic 48.2% (watch line 10%). Ranked
  matches like with like, so we left it. Cap it?
- **The 4×-Amber towers:** your picks from `TOWERS_LATER.md` (first ask of phase 8).
- **Publish the place** (privately) so Ranked becomes real? And a lobby place with
  cross-server matchmaking after that?
- Still open: dino-sending between camps (default no), Trophy seasons (default none).

## Decisions you may want to overturn

- #211: raiding = shooting towers at ×0.35; Falcon Roost and Tar Pit can't be raided.
- #212: hunter vs hunter at ×0.5; abilities never touch hunters.
- #214: Bone Rush ends at ≤1 alive with +10% survivor bonus; knock-outs give no Bones.
- #216: Entry fee 15 flat; a leaver forfeits it.
- #218: Trophies ±30, arena floors, no seasons.
- #219 / #240: one-server matchmaking; the lobby place waits for publishing.
- #233: a Ranked leaver loses Trophies as last place.
- #235 / #243: the competitive edge is a report, not a cap.

## What's next

1. Your multi-client script above; any bug it finds gets fixed first.
2. **Phase 8 (proposed, `PLAN.md` top): "Ready to publish."** Batch 1 needs nothing from you:
   a publish checklist and multi-client guide, Studio-only cheats locked to Studio, save
   hardening, a battle-pacing report, the Concussive T5 buff, and a stand-in hunter so the
   Tester can test PvP alone. Then you publish privately and we smoke-test Ranked for real;
   then the lobby place; your tower picks become the content batch.

# Phase 8 recap for Jovan: ready to publish, batch 1 (2026-10-08)

**Your words (2026-10-06):** "begin phase 8 when all loose ends on phase 7 are done".

**Honest status:** batch 1 is built, 619 headless specs green (`check.sh`, exporter,
`audit.py --strict` 0), and **played in Studio by the Tester** (Run 5: 23 pass, 0 fail).
Everything that needs real servers is still untested because the place isn't published.
The rest of phase 8 waits on you. Calls: `DECISIONS.md` #244–#248.

## What was built

- **A publish checklist and a multi-player guide** (`SETUP.md`): how to run 2–3 test
  players on one Mac, and a ~15-minute private publish with the save stores named so none
  gets renamed by accident, plus how to roll back.
- **Cheats locked to Studio:** K/J/L, stand-in camps and every test option go through one
  gate (`Shared/StudioOnly`) that a live server refuses. A spec fails if a new Studio key
  skips it.
- **Safer saves:** every save goes through `Shared/SaveStore` (retries, backoff, no
  overwrite after a failed load), and a **session lock** stops two servers holding the same
  player, so nobody loses progress when they hop servers later (needed for a lobby place).
  Tested against a fake store that throttles and conflicts.
- **Battle pacing report** (`value.py --battle`) and the fix it found (below).
- **Tectonic Slam buff:** Concussive T5 damage ×24.76 → ×34 (stun, knockback and cost
  unchanged). It was the one tier that wasn't worth buying; now it is.
- **Studio test helpers:** a **stand-in hunter** on each stand-in camp (you can shoot it to
  check ×0.5, "Tranqed by…", respawn, Camo Cover alone), "Start at round N", and
  "Stand-ins hold" (stand-in camps never fall), so the Tester could reach Final Stampede.
  Stand-in towers pierce armour so they keep up. None of this exists on a live server.
- **F7:** the "Fence is down" banner sits below the camps board, off the XP bar.

## The battle-pacing finding

Battles on Normal ended by round 9–11 and nobody saw Final Stampede. The cause wasn't Fence
or dino count: **every battle round was cut off at 60 s, while a Normal round naturally
runs 90–119 s**, so every camp got two-thirds of the time to kill each wave. Rounds may now
run to **120 s** (the next round still starts 5 s after every camp clears, so fast camps
don't wait). Model: a typical camp now lasts to round 21 (2 camps) / 32 (3 camps, Bone
Rush); a competent one reaches round 40 and Final Stampede. Co-op is unchanged.
**The cost: a full battle can now run ~60–80 minutes.** Is that too long? (See asks.)

## How it was verified

- **Headless:** 619 specs (Studio gate, save store with fake throttles/conflicts, session
  lock, stand-in hunter damage); `value.py` shows Tectonic Slam no longer "dead".
- **Studio Run 4 (T86b re-check):** all 7 checks pass; one minor fail (F7), fixed in batch 1.
- **Studio Run 5 (batch 1): 23 pass, 0 fail.** Stand-in hunter ×0.5, kill line, respawn,
  Camo Cover; Final Stampede banner from round 38 with HP ×1.25 per repeat; rounds wait for
  every camp and a 115 s round isn't cut; Tectonic Slam buys and fires; Studio options on;
  saves offline and a clean stop mid-battle; co-op rounds 1–3 and pacing unchanged; no
  console errors.
- **Not yet checked:** "the match ends when a camp falls in overtime" (N7: with "Stand-ins
  hold" on, the held camps could never fall). A Builder is making the hold switchable
  mid-battle. **N7 result (Run 6, c2ec04d): PASS before overtime** — with 3 camps from round 38 and the hold on, the real camp fell, the held stand-ins were released and fell, and the match ended with the results card; switching the hold off mid-match also ended a 2-camp match. No script errors. A camp falling *during* Final Stampede itself is still unchecked (an agent can't build a defence that survives to round 41) — it's in your multi-client script.
- **Needs a live server:** K/J/L refused live, real saves, the session lock, escrow refunds.

## What needs you

1. **Your ~20-minute multi-player script** (Studio → Test → Clients and Servers): the steps
   are in the Phase 7 recap above ("Your 20-minute script"); `SETUP.md` "Testing with
   several players" shows how to start it.
2. **Publish privately** by `SETUP.md` "Publish checklist" (~15 min). That makes testable,
   for the first time: **real saves** (Amber kept after rejoining), **the session lock**,
   **world Trophy and level boards** across servers, and **Ranked** for real (Entry fee,
   Amber Hoard, saved Trophies, refund after a server shutdown). The checklist ends with
   that smoke test (PLAN T95).
3. **The 4×-Amber towers:** your picks in `TOWERS_LATER.md` "What Jovan needs to pick".
4. **Competitive edge** (report only): maxed vs mastery 0 on the same hero is Tracker 57%,
   Big Game Hunter 84.9%, Brush Beater 82.8%, Field Medic 48.2% over the 10% watch line.
   Leave it until real Ranked data, or cap it?
5. **Battle length:** ~60–80 min with 120 s rounds. Keep it, or shorten (lower round cap,
   or end battles before round 40)?

## What's next

1. N7 re-check, then your script; anything it finds gets fixed first.
2. After you publish: the published smoke test (T95), then **a lobby place with
   cross-server matchmaking** by Trophies (TeleportService + MemoryStore queue, T96; the
   session lock is already in for it).
3. Your tower picks become the content batch (T97); your battle-length answer becomes T98.
4. No Phase 9 proposed yet: the rest of phase 8 comes first.

# Phase 8 recap for Jovan: match length and joiners, batch 2 (2026-10-09 → 10-13)

**Your words (2026-10-09, short):** "15 min max for pvp modes that arent competitive then
30 min max with overtime included for competitive … tie breakers so you cant tie in comp …
co-op pve … 30-40min max … no mid round joining for comp … late joiners … some extra cash …
that strength difference is good … lets do the 4x picks after all of this is dealt with".

**Honest status:** built, 682 headless specs green, and **played in Studio by the Tester**
(Run 7: 27 pass, 1 major fail F8 → fixed; Run 7b: 9 pass, 0 fail). Real second players
joining late and full-length matches with real people still need you. Calls:
`DECISIONS.md` #249–#273.

## What was built

- **Shorter rounds, same fight.** Each round now has **fewer but tougher dinos** (same total
  HP, same cash, same Fence at stake), so it plays in about half the time and nothing about
  the balance moved.
- **How long each mode lasts (measured by the model, Normal):**
  - **Solo / co-op:** all 40 rounds in **~34 min** (your 30–40). No clock.
  - **Casual Camp Clash / Bone Rush:** plays every 3rd round (1, 4, 7 … 40), so round 40
    comes at **~12 min**; Camp Clash then goes into **Final Stampede until the 15:00 clock**;
    Bone Rush ends at round 40.
  - **Ranked:** every 2nd round (2, 4 … 40), round 40 at **~17.4 min**, then Final Stampede
    until the **30:00 clock** (overtime included).
  - Skipped rounds still pay the cash you'd have earned, so your camp isn't poorer.
  - "Time left m:ss" on the HUD, a "One minute left" banner, and "Time's up!" at the cap.
- **No ties, ever.** Camp Clash: still standing / fell later → more Fence → more Bones → more
  damage to your own dinos → faster round clears → a coin flip seeded by the match.
  Bone Rush: Bones → survived longer → Fence → damage → clear time → coin flip. The results
  say what decided it ("Decided by most Fence left").
- **Joiners.** Ranked: seats lock at the start, nobody joins mid-match. Casual battles: a late
  joiner is seated up to round 30 (Camp Clash → the camp with the fewest hunters; Bone Rush →
  a spare plot with the lowest standing Bones and the best standing Fence, so they can
  compete but never start ahead). Co-op keeps drop-in. Everyone who joins late gets
  **catch-up cash** (what they missed × 1.1), with a toast "+N cash for skipped rounds".
  Joiners are never staked or ranked.
- **Abilities recharge twice as fast** (and the Field Hospital heals twice as fast), so
  heroes still get to use them as often per round as before.
- **Fairer big lobbies:** each camp gets its own share of the 130-dino limit (13 each with
  10 players), so one empty plot can't slow everyone else down.
- **Fence drains at most 4 per second in battles**, so two camps that leak in the same moment
  no longer drop together; the one with more Fence lasts longer and wins the tie.
- **The strength gap stays**, on purpose (Ranked like Clash Royale's trophy road; quick play
  shows new players what a maxed hunter can do).

## How it was verified

- **Headless:** 682 specs (pace maths, round lists, skipped income, the clock with a fake
  timer, every tie-break step, joiner seating and cash, per-side cap, Fence drain).
- **Studio Run 7: 27 pass.** Paced co-op, casual round jumps with the supplies line, the
  clock and its banners, "Decided by …" (standing, Bones, damage, coin flip), late stand-ins
  in both modes (seated, cash, closed after round 30), Ranked seats lock and rounds 2, 4 ….
  One major fail (F8: 10-seat Bone Rush hit 130 dinos), which turned out to be every plot
  at its fair share; the Builder added proof and the Fence drain.
- **Studio Run 7b: 9 pass, 0 fail.** Own plot capped at 13 while others weren't delayed;
  drain ≤ 4/s; Fence settled before results; co-op leaks unchanged; joiner Fence = best
  standing; the joiner toast sits below the XP bar. One note (N15: a side that's out shows
  "out" in a log line instead of its peak): accepted, tidied with the next battle commit.

## What needs you

1. **A real late joiner** (Studio → Test → Clients and Servers, 2–3 players): start a casual
   battle, join with a second client around round 10–20. Do they land in the right camp with
   the cash toast, and does it feel fair? Try joining a Ranked match: they should wait.
2. **Final Stampede until the clock with real players.** The Tester can't build a defence
   that survives past round 40. Does a casual Camp Clash feel right at 15 min, and Ranked at
   30?
3. **Amber per hour about doubles** (Normal ~92 → ~175 an hour; unlocking everything ~19 h →
   ~10 h) because your per-clear rewards stayed the same and co-op got shorter. Fine, or
   lower the clear rewards?
4. **Your 4×-Amber towers:** the refreshed `TOWERS_LATER.md` (below).

## Decisions you may want to overturn

1. **#251 Battles skip rounds** (casual every 3rd, Ranked every 2nd) instead of ending early,
   so every battle still reaches round 40 and its bosses.
2. **#252 Bone Rush ends at round 40; only Camp Clash plays Final Stampede** until the clock.
3. **#253 The tie-break order** (Fence before Bones in Camp Clash; a seeded coin flip last).
4. **#258 Fewer, tougher dinos** rather than the same dinos arriving faster (keeps the server
   under the 130 limit with 10 players).
5. **#262 / #268 Late-joiner deal:** cash = starting cash + 1.1 × missed income; Bone Rush
   joiners start with the lowest Bones and the best Fence still standing.
6. **#259 Abilities recharge ×2** to make up for shorter rounds.

## 4×-Amber tower ideas (you asked)

`TOWERS_LATER.md` now has **7 concepts**, updated for one-health-pool breaks, per-side
battles/PvP, shorter matches and the 2× towers (no copies of Storm Coil, Falcon Roost, Tar
Pit or Harpoon Ballista). The original four are kept and fixed (Meteor Beacon, Amber Resin
Cannon, Ranger Station, Spotter Blimp) and three are new: **Raptor Pen** (tamed raptors hunt
your dinos), **Bone Totem** (charges from take-downs, then roars/buffs/pays) and **Volcano
Vent** (big eruptions that flood a stretch of track with lava). Each has three paths and
2–3 choices per tier 4 and tier 5. Pick 4 (our suggestion: Resin Cannon, Raptor Pen, Spotter
Blimp, Bone Totem) and the Dino agent names them.

## What's next

1. Your tower picks → T97 (built in the round-4 tower pattern, then a Tester run).
2. Your multi-client script (now with a late joiner) and a private publish (`SETUP.md`).
3. Then the lobby place with cross-server matchmaking (T96).

# Phase 9 recap for Jovan: the 4× towers and A/B/C upgrades (2026-10-13 → 10-20)

**Your words (2026-10-13):** "I like all of the towers suggesterd, i say we add them all price
seems about right for each, i do want multiple upgrade pathes so having a/b/c upgrade options
for each is ideal and all towers/weapons should have this a/b/c upgrade path up to tier 5,
lets have the extinction event be automatic … i like towers touching enemy hunters however
they shouldnt be useless against the dinos …"

**Honest status:** built and **released** (everything is in the shop), 845 headless specs
green, and **played in Studio by the Tester** in Runs 8, 9 and 10 (Runs 9 and 10 were cut
short by usage limits), plus the Run 10b re-check, which passed. How the builds *feel* and anything needing a
second real player still need you. Calls: `DECISIONS.md` #274–#362.

## What was built

- **The A/B/C pick.** At tier 4 and again at tier 5 of every path, the upgrade button opens
  three cards; you pick one. Tiers 1–3 are unchanged. Your tier-5 pick doesn't depend on your
  tier-4 pick (9 builds per path), and the three cards at a tier cost the same. Picks last
  for the match. Heroes get it too; a hero's tier 6 stays one capstone that works after any
  tier-5 pick, and hero options change how the gun handles, never its raw damage.
- **180 new options.** Option A is the old tier 4/5, unchanged. The Director designed B and C
  for every existing path: **132 tower options** (the 11 towers) and **48 hero options** (the
  4 heroes), named by the Dino agent. A checker in the balance model refuses any option that
  is useless or that everyone would always pick.
- **The seven 4× towers** (Amber to unlock / cash to build). The cash prices came down from
  the proposal because the balance model showed they'd have been 4–5× too weak for the money:
  - **Amber Resin Cannon** (500 / 800): resin slows dinos, entombs them in amber, fossils.
  - **Raptor Pen** (500 / 600): tame raptors run out down your track, bite fast, come back.
  - **Bone Totem** (450 / 600): your take-downs charge it; then it roars on its own, buffs your
    towers, or pays out cash.
  - **Spotter Blimp** (400 / 600): flies your track and can't be hurt: a door gun, a
    searchlight that helps your towers, or cargo drops that pay.
  - **Meteor Beacon** (600 / 600): a meteor every 8 s on the biggest bunch, burning craters.
  - **Volcano Vent** (600 / 600): placed beside the track; erupts and floods a stretch with
    lava that burns, shoves and crusts over.
  - **Ranger Station** (500 / 600): rangers walk out to posts you set on the track and shoot,
    lay traps or guard. You set posts in third person with the gun put away.
  All seven: 3,550 Amber.
- **Extinction Event is automatic.** The Meteor Beacon's top pick fires itself once a round:
  the moment a boss or a big bunch is in reach, otherwise on the last dinos of the round. It
  hits every dino for **×2.5** (your proposal said ×20, which scored ~10× everything else on
  its path; it's still the biggest hit in the game). Same rule everywhere: **no tower
  buttons** — "once a round" things fire themselves so you stay on your gun.
- **Raider options** (8 in all: Tranq, Armory, Storm Coil, Falcon, Tar Pit, Ballista, Resin,
  Raptor). In battles they mainly sting enemy hunters who walk into your side (slow up to
  30% for a moment, half damage, never a stun, never reveal anyone). They always do something
  real to dinos too, and in co-op they're still a fair pick on that alone.
- **Walkers.** Raptors and rangers are a new kind of unit with their own limit, separate from
  the 130-dino cap: 24 per side, but **9 per camp in a 10-camp Bone Rush** so the server holds
  up. The tower panel says when a pack is short because of the cap.
- **Co-op leak cap.** One normal dino getting through now costs at most a quarter of your
  starting Fence (Normal: 8 of 30), so a single leak no longer ends a run. Bosses still cost full.
  The build-phase HUD buttons also hide while you place a tower or set posts.
- **The boot crash (F11) and a new guard.** Run 10's first try found the server wouldn't
  start: the towers script had grown past Roblox's limit of 200 top-level names. Fixed, and
  the test run now compiles every script with the real Roblox compiler and fails early if a
  file gets close to that limit, so this can't sneak through again.

## How it was verified

- **Headless:** 845 specs (picks, every option's stats, the seven towers' rules, walkers and
  their cap, the leak cap, the compile guard) plus the balance model's option checks.
- **Studio Run 8: 18 pass, 1 minor fail** (F9: the pick header ran under Back → fixed).
- **Studio Run 9: 17 pass** on B/C cards for the 11 towers and 4 heroes, 1 partial, 1
  inconclusive; cut off near the end. F10 (a Studio-only test tool) fixed.
- **Studio Run 10: 13 pass** after the F11 fix: all seven placed, upgraded with A/B/C cards,
  stats match the cards, co-op Normal past round 20 with all seven at tier 5, Ranger posts,
  Trampled/Repair, walker cap. Cut off after step 15; it raised the leak note now fixed.
- Run 10b (c9f9c4f): boot, co-op leak cap (each non-boss leak cost exactly 8 on Normal: 30→22→14→6), battle drain 4.0/s, hidden hero/Unlocks buttons while placing and in posts mode, posts mode closing on a bite, the walker-cap line ("9 of 15 out · side's walker cap 24") and a co-op regression all PASS; a boss leak couldn't be reached in play (first boss is round 31) — a read-only probe confirms it still costs in full (48). No game errors.

## What I need from you

1. **Unlocking everything takes ~30 h on Normal** (5,325 Amber; the seven new towers are
   3,550 of it). OK, or should Bounties / Daily Haul pay more?
2. **Ranger posts are set in third person with the gun away.** OK?
3. **9 walkers per camp in a 10-camp Bone Rush** (24 elsewhere). OK once you've seen it?
4. **How the A/B/C builds feel** — agents can't judge feel. Try one 4× tower per session, and
   a couple of B/C picks on towers you know.
5. **Multi-client checks** the Tester can't do alone: Raider stings from a real second
   hunter's shots, and hero gun effects (the Tester can't equip the gun).
6. **Publishing is still pending** (`SETUP.md` checklist), then the lobby place.
7. **The brainstorm** (pets, hub, AFK farming, bigger Amber numbers) waits for your "go".

## Decisions you may want to overturn

1. **#317 Extinction Event ×2.5, not ×20.**
2. **#326 Raptors bite faster (2.3/s) instead of harder** (one big bite wasted damage).
3. **#331 Bone Totem charges from 3 Bones** (was 8: it barely fired).
4. **#357 Co-op leak cap** at a quarter of the starting Fence (bosses excluded).
5. **#337 / #339 / #340 4× cash prices cut to 600** (Meteor, Vent from 1,000; Ranger 900).
6. **#276 Tier-5 pick free of the tier-4 pick** (9 builds per path, not 3 locked lines).
7. **#287 Picks last one match** (never saved; you choose again each game).
8. **#320 Only two Raider options on the 4× towers** (Resin, Raptor), none on heroes (#301).

## What's next

1. Run 10b passed; nothing left open from it.
2. Your answers above, your multi-client test and a private publish.

# Phase 10 recap for Jovan: bodies, kit, the Outpost, training, pets, skins, store (2026-10-20 → 10-22)

**Your words (2026-10-20):** "maxing out is on a good pace i want it to take a while and give
impatient players something to use to get ahead with micro tranactions … weapon skins and
hunter skins and tower skins i want to implement simple stats so that players have a reason to
afk farm … add a melee for each hunter and a grenade … each hunter should have their own unique
health stat, speed stat … punching bag for melee treadmil for speed, potion crafting/or vitamin
making for health, then a grenade throwing range for grenade". Later the same day: training
online only, six pet rarities with Mythic, Amber ×1000, the proposed Robux prices.

**Honest status:** built, 967 headless specs green, and **played in Studio by the Tester** in
Runs 11–14 (Run 11 stalled after 8 rows; its rest was re-done in Run 12). Every fail found is
fixed except one narrow-window case (below). **Nothing you can buy with Robux works yet**: the
store opens only after you publish and fill in the product ids. Calls: `DECISIONS.md` #363–#420.

## What was built

- **Amber ×1000.** Every price and payout went up together: a Normal clear is now 100,000,
  unlocking everything is 5.3M. Amber shows short (12.5K, 1.2M) and rounds down, so it never
  shows more than you have. Old saves are converted once.
- **Hunter bodies.** Tracker 95 HP / speed 17, Big Game Hunter 110 / 15, Brush Beater
  115 / 15.5, Field Medic 100 / 16.5 (was 100 / 16 for all). A check keeps them within 15 %
  of each other overall.
- **Melee (V) and grenade (C), one each per hunter:**
  - Tracker: **Hunting Knife** (quick stabs) + **Stink Bomb** (a cloud; dinos in it take +20 %).
  - Big Game Hunter: **Stock Swing** (slow, heavy) + **Safari Grenade** (the big plain blast).
  - Brush Beater: **Brush Machete** (wide sweep, up to 3 dinos) + **Cherry Bomb** (slows 50 %).
  - Field Medic: **Splint Stick** (slows dinos) + **Dozy Cloud** (slows dinos, and hunters 30 %).
  One grenade charge, 20 s to recharge. Against hunters: half damage, never a stun or
  knockback. They also hit rival towers in battles, like the gun. They can't hurt flyers or
  armoured dinos, but their slows still land on armoured ground dinos. Gun + kit together stay
  well under the best tower (the kit peaks at 27 % of it).
- **Hunters' Outpost.** Between matches you walk around a camp (third person there only, no
  fighting) instead of a home screen; Play and the menus sit in a panel that's always
  reachable. 10 **Campsites**, one per player, each with 3 Display Towers, 3 decoration spots
  and a Hatchling Pen.
- **Training stations** (four stats, shared by all your hunters): Raptor Dummy → melee reach
  (up to +20 %), Raptor Chase → speed (+15 %), Herb Kitchen → health (+10 %), Coconut Toss →
  grenade range (+30 %). 10 levels each; level L takes 10·L minutes (about 9 h a stat, 37 h
  for all four). **Online only**, as you asked: full speed at the station, half speed anywhere
  else while you're in the game, nothing while logged off. **Finish now** costs 2,000 Amber
  per minute left (a whole level 10 = 200K). Same caps for everyone.
- **Eggs and pets** at the Hatchery Hut. Eggs: **Mud** 20K (5 min), **Speckled** 75K (30 min),
  **Golden** 200K (2 h). Odds always shown (Common / Uncommon / Rare / Epic / Legendary /
  Mythic): Mud 55/25/12/5/2.5/0.5, Speckled 40/30/17/8/4/1, Golden 20/30/25/14/9/2. **Warm it
  up** = 2,000 Amber per minute left. Fuse 3 identical pets into the next rarity (3 Legendary
  → Mythic). 60 pets max, one with you in matches; it dies and respawns with you and never
  touches enemy hunters. Rarity scales the effect ×1 up to ×2.25 (Mythic):
  - **Honker:** every 10 s honks at the nearest boss near you (else the biggest dino); your
    own hits on it do +5 % for 3 s (Mythic +11 %).
  - **Fetcher:** brings Airdrop chests to you from 4 studs (Mythic 9).
  - **Fern Muncher:** heals you 0.2 HP/s (Mythic 0.45).
  - **Shiny Snatcher:** +8 cash to your team each round cleared (Mythic 18).
  - **Frill Guard:** takes 40 % of the round's first dino bite (Mythic 90 %).
- **Skins and decorations** at the Counter (cosmetic only; towers and hunters stay readable):
  - Earned by level, never sold: Swamp Stalker (Tracker) 15, Safari Classic (Big Game Hunter)
    25, Bamboo Basher (Brush Beater) 35, Frontier Doc (Medic) 45, Walnut Classic (rifle) 55,
    Snakeskin Grip (revolver) 65.
  - Amber: more hunter skins 300K / 500K (Gold Rush Safari 900K); weapon skins 200K–400K
    (Engraved Gold 600K); tower sets Treehouse 400K, Stone Age 400K, Brass Gear 600K,
    Midnight 800K, Gold Rush 1.5M.
  - Campsite decorations: Fire Pit (level 5), Stepping Stones (12), Hunter's Flag (18, your
    flag colour), Wanted Poster 100K (your name, hardest difficulty cleared, best round),
    Hammock 150K, Rope Swing 200K, Dino Statue 500K.
- **The Robux store** (buys time, Amber and looks; never past a cap; never mid-match):
  Amber Sack R$49 (150K), Crate R$199 (700K), Wagon R$799 (3M); passes 2× Training R$299,
  Extra Training Spot R$199, Second Hatchery Hut R$199; Hatch now Speckled R$25, Golden R$79;
  Finish this level R$25; bundles (tower set + hunter skin + weapon skin) Treehouse, Stone
  Age, Brass Gear R$249, Midnight R$299, Gold Rush R$599. Each purchase is saved before it's
  granted, so nobody pays twice or gets it twice.
- **Clear of Roblox's own buttons.** No control sits under Roblox's top bar or the chat window
  any more (Runs 13–14 found both).

**Only works after you publish:** the store and every purchase, saving all of the above
between sessions, the pass checks, hiding paid random items for accounts Roblox restricts,
and the idle kick ending a training session.

## How it was verified

- **Headless:** 967 specs (Amber scaling and short numbers, bodies and the parity bar, kit hits
  and PvP rules, training accrual incl. "nothing for time away", egg odds and fusing, pet
  effects, skins and decorations, fake store receipts incl. duplicates and failed saves).
- **Studio Run 11: 8 pass** (Amber ×1000 and K/M, bodies, the Medic's kit); then it stalled.
- **Studio Run 12: 10 pass**, 3 fail + 3 blocked (all F12: the Outpost flag was lost on spawn
  → fixed), 1 partial, 1 not tested. Kit and tower raids passed.
- **Studio Run 13: 19 pass**, 2 fail (F13 top-bar clicks, F14 pet-down message → both
  fixed), 3 not tested. The Outpost, training and pets passed.
- **Studio Run 14: 17 pass**, 1 fail (F13b chat window → fixed, see narrow windows below), 1
  partial, 1 not tested (Honker bonus: dino HP couldn't be read), 1 inconclusive (pets vs a
  real enemy hunter). Skins and the closed store passed.
- **Run 15: 15 pass, 2 fail** (F15 decorations couldn't be placed — the server never routed the request; F13c the Menu/Hide toggle's top was under the chat input bar). Both fixed (39fe166, 91252ca), plus a spec that every client request is handled. **Run 15b: all re-checks pass** — buying, placing, swapping and removing decorations; free ones locked by level; decorations cosmetic only; the Wanted Poster's best-clear line; Menu/Hide clickable; the losing side sees "GAME OVER" and "Camp Clash — 2nd place". No game errors.

## What I need from you

1. **Publish privately and fill the store ids** (`SETUP.md`, "Open the Robux store"), then buy
   one cheap item (Finish this level, R$25) to see it arrive once.
2. **Try the feel:** each hunter's body and kit, a training session, an egg hatch, one skin.
3. **Egg timers keep running while you're offline** (training doesn't, as you asked). OK? (#396)
4. **Mud's "Hatch now" was dropped** (a 5-min egg; Warm it up costs 10K), and **Golden is
   R$79, not 99.** OK? (#413)
5. **Narrow windows:** under ~540 px wide, Start / H / M still sit partly under the chat
   window; only their right end clicks. Fine until a phone test after publishing? (#419)
6. **Multi-client:** kit and pets against a real second hunter (half damage, no stun, pets
   never touch you).
7. Anything else: pack sizes, bundle prices, no Robux-only skins (below).

## Decisions you may want to overturn

1. **#396 Egg timers run offline** (training is online only).
2. **#413 No Hatch now for Mud; Golden R$79.**
3. **#410 No Robux-only skins:** the premium sets are the dearest in Amber; bundles are the shortcut.
4. **#411 Amber pack sizes:** 150K / 700K / 3M (bigger packs give a bit more per Robux).
5. **#403 / #405 Finish now and Warm it up at 2,000 Amber a minute.**
6. **#374 / #379 Trained stats and pets work in Ranked too.**
7. **#367 No in-match melee/grenade upgrades;** the kit grows only through training.
8. **#407 Honker = a damage honk** (there are no hidden dinos to spot, so "spots camo" became this).

## What's next

1. Run 15/15b done; nothing left open from them.
2. Your answers above, a private publish with the store ids, then the published checks (T95)
   and the lobby place (T96).
