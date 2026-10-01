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

  My lean: yes to Skybreaker, Crack Armor, Quick Mark and Storm of Steel.
- **Tier-5 glow (#33):** keep the whole tower going Neon (it hides the new silhouettes), or a
  single amber accent?
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
