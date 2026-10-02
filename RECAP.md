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
